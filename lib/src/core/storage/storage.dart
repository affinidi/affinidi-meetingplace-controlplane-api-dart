import 'dart:async';
import '../entity/entity.dart';

typedef EntityFromJson<T> = T Function(Map<String, dynamic> json);

abstract interface class Storage {
  Future<Storage> connect();

  Future<T> create<T extends Entity>(T object);

  Future<T> update<T extends Entity>(T object);

  Future<T?> updateWithCondition<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson, {
    required T Function(T entity) updateFn,
    required bool Function(T entity) conditionFn,
  });

  Future<T> add<T extends Entity>(String listName, T object);

  Future<void> delete(String entityName, String id);

  Future<T?> findOneById<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  );

  Future<List<T>> findAllById<T>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  );

  Future<int> count(String entityName);

  Future<List<T>> listAll<T extends Entity>(
    String entityName,
    String id,
    EntityFromJson<T> fromJson,
  );

  Future<void> deleteFromlist(
    String listName,
    String listId,
    String entityName,
    String id,
  );
}
