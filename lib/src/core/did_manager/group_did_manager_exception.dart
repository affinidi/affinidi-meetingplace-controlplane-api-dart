class GroupDidManagerException implements Exception {
  GroupDidManagerException({
    required this.message,
    required this.code,
    this.originalException,
  });

  final String message;
  final String code;
  final Object? originalException;
}
