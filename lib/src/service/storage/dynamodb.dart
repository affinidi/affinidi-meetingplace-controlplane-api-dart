import 'dart:async';
import 'package:shared_aws_api/shared.dart';

import '../../core/storage/exception/already_exists_exception.dart';
import '../../core/storage/exception/conditional_update_failed_exception.dart';
import 'package:aws_dynamodb_api/dynamodb-2012-08-10.dart' as aws;
import 'package:mutex/mutex.dart';

import '../../core/logger/logger.dart';
import '../../core/config/env_config.dart';
import '../../core/storage/storage.dart';
import '../../core/entity/entity.dart';
import '../credentials_manager/aws_credentials_manager.dart';

class DynamoDBStorage implements Storage {
  DynamoDBStorage._({
    required String region,
    required String tableName,
    required AwsClientCredentials credentials,
    required Logger logger,
  }) : _tableName = tableName,
       _credentials = credentials,
       _logger = logger {
    _client = aws.DynamoDB(region: region, credentials: credentials);
  }

  final String _tableName;
  final Mutex mutex = Mutex();
  final Logger _logger;

  late aws.DynamoDB _client;

  aws.AwsClientCredentials _credentials;

  static Future<DynamoDBStorage> init({required Logger logger}) async {
    final creds = await AwsCredentialsManager.getCredentials();

    final manager = DynamoDBStorage._(
      region: getEnv('AWS_REGION'),
      tableName: getEnv('DDB_TABLE_NAME'),
      credentials: creds,
      logger: logger,
    );

    return manager;
  }

  @override
  Future<DynamoDBStorage> connect() async {
    await _getClient();
    return this;
  }

  Future<void> _addListItem<T extends Entity>(String listName, T object) {
    final listId =
        object.getListId() ?? (throw Exception('List ID is missing'));

    final pk = _getPrimaryKey(listName, listId);
    final sk = _getSecondaryKey(object.getId());
    return _createItem(
      pk: pk,
      sk: sk,
      entityName: listName,
      data: object.toJson(),
    );
  }

  Future<void> _createItem({
    required String pk,
    required String sk,
    required String entityName,
    Map<String, dynamic>? data,
    DateTime? ttl,
  }) async {
    _logger.info('Acquire lock...');
    await mutex.acquire();

    try {
      // Check if item already exists
      final existingItem = await _client.getItem(
        tableName: _tableName,
        key: {
          'PK': aws.AttributeValue(s: pk),
          'SK': aws.AttributeValue(s: sk),
        },
      );

      if (existingItem.item != null && existingItem.item!.isNotEmpty) {
        mutex.release();
        throw AlreadyExists();
      }

      // Create the item
      final item = <String, aws.AttributeValue>{
        'PK': aws.AttributeValue(s: pk),
        'SK': aws.AttributeValue(s: sk),
        'entityName': aws.AttributeValue(s: entityName),
      };

      if (data != null) {
        item['data'] = aws.AttributeValue(m: _toAttributeMap(data));
      }

      if (ttl != null) {
        item['ttl'] = aws.AttributeValue(
          n: (ttl.millisecondsSinceEpoch ~/ 1000).toString(),
        );
      }

      await _client.putItem(tableName: _tableName, item: item);

      _logger.info('Release lock...');
      mutex.release();
    } catch (e) {
      if (mutex.isLocked) mutex.release();
      rethrow;
    }
  }

  @override
  Future<T> create<T extends Entity>(T object) async {
    await _getClient();
    final pk = _getPrimaryKey(object.getEntityName(), object.getId());
    final sk = _getSecondaryKey(object.getId());
    await _createItem(
      pk: pk,
      sk: sk,
      entityName: object.getEntityName(),
      data: object.toJson(),
      ttl: object.ttl,
    );
    return object;
  }

  @override
  Future<T> update<T extends Entity>(T object) async {
    final client = await _getClient();
    final pk = _getPrimaryKey(object.getEntityName(), object.getId());
    final sk = _getSecondaryKey(object.getId());

    final item = <String, aws.AttributeValue>{
      'PK': aws.AttributeValue(s: pk),
      'SK': aws.AttributeValue(s: sk),
      'entityName': aws.AttributeValue(s: object.getEntityName()),
      'data': aws.AttributeValue(m: _toAttributeMap(object.toJson())),
    };

    if (object.ttl != null) {
      item['ttl'] = aws.AttributeValue(
        n: (object.ttl!.millisecondsSinceEpoch ~/ 1000).toString(),
      );
    }

    await client.putItem(tableName: _tableName, item: item);
    return object;
  }

  @override
  Future<T?> updateWithCondition<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson, {
    required T Function(T entity) updateFn,
    required bool Function(T entity) conditionFn,
  }) async {
    await _getClient();
    await mutex.acquire();

    try {
      T? entity = await findOneById(entityName, id, fromJson);
      if (entity == null) {
        mutex.release();
        return null;
      }

      if (!conditionFn(entity)) {
        mutex.release();
        throw ConditionalUpdateFailed();
      }

      T updatedEntity = await update(updateFn(entity));
      mutex.release();
      return updatedEntity;
    } catch (e) {
      if (mutex.isLocked) mutex.release();
      rethrow;
    }
  }

  @override
  Future<void> delete(String entityName, String id) async {
    await _getClient();
    final pk = _getPrimaryKey(entityName, id);
    final sk = _getSecondaryKey(id);

    await _client.deleteItem(
      tableName: _tableName,
      key: {
        'PK': aws.AttributeValue(s: pk),
        'SK': aws.AttributeValue(s: sk),
      },
    );
  }

  @override
  Future<T?> findOneById<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  ) async {
    await _getClient();
    final pk = _getPrimaryKey(entityName, id);
    final sk = _getSecondaryKey(id);

    final result = await _client.getItem(
      tableName: _tableName,
      key: {
        'PK': aws.AttributeValue(s: pk),
        'SK': aws.AttributeValue(s: sk),
      },
    );

    if (result.item == null || result.item!.isEmpty) {
      return null;
    }

    final dataMap = result.item!['data']?.m;
    if (dataMap == null) return null;

    return fromJson(_fromAttributeMap(dataMap));
  }

  @override
  Future<List<T>> findAllById<T>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  ) async {
    await _getClient();
    final pk = _getPrimaryKey(entityName, id);

    final result = await _client.query(
      tableName: _tableName,
      keyConditionExpression: 'PK = :pk',
      expressionAttributeValues: {':pk': aws.AttributeValue(s: pk)},
      consistentRead: true,
    );

    if (result.items == null) return [];
    return result.items!
        .map((item) {
          final dataMap = item['data']?.m;
          if (dataMap == null) return null;

          return fromJson(_fromAttributeMap(dataMap));
        })
        .toList()
        .cast<T>();
  }

  @override
  Future<int> count(String entityName) async {
    await _getClient();

    final result = await _client.query(
      tableName: _tableName,
      indexName: 'EntityName',
      keyConditionExpression: 'entityName = :entityName',
      expressionAttributeValues: {
        ':entityName': aws.AttributeValue(s: entityName),
      },
      select: aws.Select.count,
    );

    return result.count ?? 0;
  }

  @override
  Future<T> add<T extends Entity>(String listName, T object) async {
    await _addListItem(listName, object);
    return object;
  }

  @override
  Future<void> deleteFromlist(
    String listName,
    String listId,
    String entityName,
    String id,
  ) async {
    await Future.wait([
      delete(entityName, id),
      _deleteListItem(listName: listName, listId: listId, entityId: id),
    ]);
  }

  Future<void> _deleteListItem({
    required String listName,
    required String listId,
    required String entityId,
  }) async {
    await _getClient();
    final pk = _getPrimaryKey(listName, listId);
    final sk = _getSecondaryKey(entityId);

    await _client.deleteItem(
      tableName: _tableName,
      key: {
        'PK': aws.AttributeValue(s: pk),
        'SK': aws.AttributeValue(s: sk),
      },
    );
  }

  String _getPrimaryKey(String entityName, String id) {
    return "$entityName#$id";
  }

  String _getSecondaryKey(String id) {
    return id;
  }

  Map<String, aws.AttributeValue> _toAttributeMap(Map<String, dynamic> json) {
    final result = <String, aws.AttributeValue>{};
    json.forEach((key, value) {
      result[key] = _toAttributeValue(value);
    });
    return result;
  }

  /// Convert a dynamic value to AttributeValue
  aws.AttributeValue _toAttributeValue(dynamic value) {
    if (value == null) {
      return aws.AttributeValue(nullValue: true);
    } else if (value is String) {
      return aws.AttributeValue(s: value);
    } else if (value is num) {
      return aws.AttributeValue(n: value.toString());
    } else if (value is bool) {
      return aws.AttributeValue(boolValue: value);
    } else if (value is List) {
      return aws.AttributeValue(
        l: value.map((e) => _toAttributeValue(e)).toList(),
      );
    } else if (value is Map) {
      return aws.AttributeValue(
        m: _toAttributeMap(value.cast<String, dynamic>()),
      );
    }

    return aws.AttributeValue(s: value.toString());
  }

  Map<String, dynamic> _fromAttributeMap(
    Map<String, aws.AttributeValue> attributeMap,
  ) {
    final result = <String, dynamic>{};
    attributeMap.forEach((key, value) {
      result[key] = _fromAttributeValue(value);
    });
    return result;
  }

  dynamic _fromAttributeValue(aws.AttributeValue value) {
    if (value.s != null) return value.s;
    if (value.n != null) return num.tryParse(value.n!) ?? value.n;
    if (value.boolValue != null) return value.boolValue;
    if (value.nullValue == true) return null;
    if (value.l != null) {
      return value.l!.map((e) => _fromAttributeValue(e)).toList();
    }
    if (value.m != null) {
      return _fromAttributeMap(value.m!);
    }
    if (value.ss != null) return value.ss;
    if (value.ns != null) return value.ns;
    if (value.bs != null) return value.bs;
    return null;
  }

  Future<aws.DynamoDB> _getClient() async {
    final refreshedCredentials =
        await AwsCredentialsManager.refreshCredentialsIfNeeded(_credentials);

    if (refreshedCredentials != null) {
      _credentials = refreshedCredentials;
      _client = aws.DynamoDB(
        region: getEnv('AWS_REGION'),
        credentials: refreshedCredentials,
      );
    }
    return _client;
  }
}
