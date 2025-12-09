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

Mutex mutex = Mutex();

class DynamoDBStorage implements Storage {
  DynamoDBStorage._({
    required String region,
    required AwsClientCredentials credentials,
    required Logger logger,
  }) : _credentials = credentials,
       _logger = logger {
    _client = aws.DynamoDB(region: region, credentials: credentials);
  }

  static Future<DynamoDBStorage> init({required Logger logger}) async {
    final creds = await AwsCredentialsManager.getCredentials();

    final manager = DynamoDBStorage._(
      region: getEnv('AWS_REGION'),
      credentials: creds,
      logger: logger,
    );
    return manager;
  }

  late aws.DynamoDB _client;
  aws.AwsClientCredentials _credentials;

  final Logger _logger;
  String? _tableName;

  @override
  Future<DynamoDBStorage> connect() async {
    return this;
  }

  Future<void> _addListItem(String entityName, String id) {
    final pk = _getPrimaryKey(entityName);
    final sk = _getSecondaryKey(id);
    return _createItem(pk: pk, sk: sk);
  }

  Future<void> _createItem({
    required String pk,
    required String sk,
    Map<String, dynamic>? data,
    DateTime? ttl,
  }) async {
    _logger.info('Acquire lock...');
    await mutex.acquire();

    try {
      // Check if item already exists
      final existingItem = await _client!.getItem(
        tableName: _tableName!,
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
      };

      if (data != null) {
        item['data'] = aws.AttributeValue(m: _toAttributeMap(data));
      }

      if (ttl != null) {
        item['ttl'] = aws.AttributeValue(
          n: (ttl.millisecondsSinceEpoch ~/ 1000).toString(),
        );
      }

      await _client!.putItem(tableName: _tableName!, item: item);

      _logger.info('Release lock...');
      mutex.release();
    } catch (e) {
      mutex.release();
      rethrow;
    }
  }

  @override
  Future<T> create<T extends Entity>(T object) async {
    await _getClient();
    final pk = _getPrimaryKey(object.getEntityName());
    final sk = _getSecondaryKey(object.getId());
    await _createItem(pk: pk, sk: sk, data: object.toJson(), ttl: object.ttl);
    return object;
  }

  @override
  Future<T> update<T extends Entity>(T object) async {
    final client = await _getClient();
    final pk = _getPrimaryKey(object.getEntityName());
    final sk = _getSecondaryKey(object.getId());

    final item = <String, aws.AttributeValue>{
      'PK': aws.AttributeValue(s: pk),
      'SK': aws.AttributeValue(s: sk),
      'data': aws.AttributeValue(m: _toAttributeMap(object.toJson())),
    };

    if (object.ttl != null) {
      item['ttl'] = aws.AttributeValue(
        n: (object.ttl!.millisecondsSinceEpoch ~/ 1000).toString(),
      );
    }

    await client.putItem(tableName: _tableName!, item: item);
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
      mutex.release();
      rethrow;
    }
  }

  @override
  Future<void> delete(String entityName, String id) async {
    await _getClient();
    final pk = _getPrimaryKey(entityName);
    final sk = _getSecondaryKey(id);

    await _client!.deleteItem(
      tableName: _tableName!,
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
    final pk = _getPrimaryKey(entityName);
    final sk = _getSecondaryKey(id);

    final result = await _client!.getItem(
      tableName: _tableName!,
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
  Future<List<String>> findAllById(String entityName, String id) async {
    await _getClient();
    final pk = _getPrimaryKey(entityName);

    // Query all items with this PK (all entities of this type for the tenant)
    final result = await _client!.query(
      tableName: _tableName!,
      keyConditionExpression: 'PK = :pk',
      expressionAttributeValues: {':pk': aws.AttributeValue(s: pk)},
      projectionExpression: 'SK',
    );

    if (result.items == null) return [];

    return result.items!
        .map((item) => item['SK']?.s)
        .where((id) => id != null)
        .cast<String>()
        .toList();
  }

  @override
  Future<int> count(String entityName) async {
    await _getClient();
    final pk = _getPrimaryKey(entityName);

    final result = await _client!.query(
      tableName: _tableName!,
      keyConditionExpression: 'PK = :pk',
      expressionAttributeValues: {':pk': aws.AttributeValue(s: pk)},
      select: aws.Select.count,
    );

    return result.count ?? 0;
  }

  @override
  Future<List<T>> listAll<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  ) async {
    await _getClient();
    final members = await findAllById(entityName, id);

    // TODO: optimize by just getting all by id
    final results = <T>[];
    for (final member in members) {
      final result = await findOneById<T>(entityName, member, fromJson);
      if (result != null) results.add(result);
    }
    return results;
  }

  @override
  Future<T> add<T extends Entity>(String listName, T object) async {
    await create(object);
    await _addListItem(listName, object.getId());
    return object;
  }

  @override
  Future<dynamic> deleteFromlist(
    String listName,
    String listId,
    String entityName,
    String id,
  ) async {
    await delete(entityName, id);
  }

  String _getPrimaryKey(String entityName) {
    return "${getEnv('TENANT_ID')}#$entityName";
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
    // Fallback to string representation
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

  /// Convert AttributeValue back to dynamic value
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
