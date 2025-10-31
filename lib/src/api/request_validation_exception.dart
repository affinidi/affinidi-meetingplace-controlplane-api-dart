import 'dart:convert';

import 'package:lucid_validation/lucid_validation.dart';

class RequestValidationException implements Exception {
  factory RequestValidationException.fromValidationResult(
      ValidationResult result) {
    final fieldErrors = result.exceptions.map((ex) {
      return {'message': ex.message, 'field': ex.key};
    }).toList();

    return RequestValidationException(validationErrors: fieldErrors);
  }

  RequestValidationException({required this.validationErrors});

  final List<Map<String, dynamic>> validationErrors;

  @override
  toString() => jsonEncode(validationErrors);
}
