import 'dart:async';
import 'dart:convert';
import '../../core/storage/exception/already_exists_exception.dart';
import '../../core/storage/exception/conditional_update_failed_exception.dart';
import 'package:redis/redis.dart';
import 'package:mutex/mutex.dart';

import '../../core/logger/logger.dart';
import '../../core/config/env_config.dart';
import '../../core/storage/storage.dart';
import '../../core/entity/entity.dart';

Mutex mutex = Mutex();

class Redis implements Storage {
  Redis._(Logger logger) : _logger = logger;

  static Future<Redis> init({required Logger logger}) async {
    if (_instance == null) {
      final redis = Redis._(logger);
      await redis.connect();
      _instance = redis;
    }
    return _instance!;
  }

  final Logger _logger;
  static Redis? _instance;
  Command? _command;

  @override
  Future<Redis> connect() async {
    _command = await RedisConnection().connect(
      getEnv('STORAGE_ENDPOINT'),
      6379,
    );

    return this;
  }

  @override
  Future<T> create<T extends Entity>(T object) async {
    _command ??= (await connect())._command;
    final key = "${object.getEntityName()}#${object.getId()}";

    _logger.info('Acquire lock...');
    await mutex.acquire();
    if (await _doesKeyExist(key)) {
      mutex.release();
      throw AlreadyExists();
    }

    await _command!.send_object(['SET', key, JsonEncoder().convert(object)]);
    if (object.ttl != null) {
      await _setExpiry(_command!, key, object.ttl!);
    }

    _logger.info('Release lock...');
    mutex.release();
    return object;
  }

  @override
  Future<T> update<T extends Entity>(T object) async {
    _command ??= (await connect())._command;
    final key = "${object.getEntityName()}#${object.getId()}";
    await _command?.send_object(['SET', key, JsonEncoder().convert(object)]);
    if (object.ttl != null) {
      await _setExpiry(_command!, key, object.ttl!);
    }
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
    _command ??= (await connect())._command;
    await mutex.acquire();

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
  }

  @override
  Future<void> delete(String entityName, String id) async {
    _command ??= (await connect())._command;
    await _command?.send_object(['DEL', "$entityName#$id"]);
  }

  @override
  Future<T?> findOneById<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  ) async {
    _command ??= (await connect())._command;
    final result = await _command?.send_object(['GET', "$entityName#$id"]);

    if (result == null) return null;
    return fromJson(JsonDecoder().convert(result));
  }

  @override
  Future<List<String>> findAllById(String entityName, String id) async {
    _command ??= (await connect())._command;
    final result = await _command?.send_object(['SMEMBERS', "$entityName#$id"]);
    return result.toList().cast<String>();
  }

  @override
  Future<int> count(String entityName) async {
    // TODO: iterate if count > 500
    _command ??= (await connect())._command;
    var response = await _command?.send_object([
      'SCAN',
      '0',
      'MATCH',
      '$entityName*',
      'COUNT',
      '500',
    ]);

    return (response[1] as List<dynamic>).length;
  }

  @override
  Future<List<T>> listAll<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  ) async {
    _command ??= (await connect())._command;
    final members = await findAllById(entityName, id);

    final results = <T>[];
    for (final member in members) {
      final result = await findOneById<T>(entityName, member, fromJson);
      if (result != null) results.add(result);
    }
    return results;
  }

  @override
  Future<T> add<T extends Entity>(String listName, T object) async {
    _command ??= (await connect())._command;
    await _command?.send_object([
      'SET',
      '${object.getEntityName()}#${object.getId()}',
      JsonEncoder().convert(object),
    ]);

    await _command?.send_object([
      'SADD',
      "$listName#${object.getListId()}",
      object.getId(),
    ]);
    return object;
  }

  @override
  Future<dynamic> deleteFromlist(
    String listName,
    String listId,
    String entityName,
    String id,
  ) async {
    _command ??= (await connect())._command;
    await delete(entityName, id);
    return _command?.send_object(['SREM', '$listName#$listId', id]);
  }

  Future<bool> _doesKeyExist(String key) async {
    _command ??= (await connect())._command;
    final result = await _command?.send_object(['EXISTS', key]);
    return result == 1;
  }

  Future<void> _setExpiry(Command command, String key, DateTime ttl) async {
    await command.send_object([
      'EXPIRE',
      key,
      ttl.difference(DateTime.now().toUtc()).inSeconds,
    ]);
  }
}
