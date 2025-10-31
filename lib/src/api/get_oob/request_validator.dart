import 'package:lucid_validation/lucid_validation.dart';

class GetOobRequestValidator extends LucidValidator {
  GetOobRequestValidator() {
    ruleFor((request) => request['oobId'] as String?, key: 'oobId')
        .notEmptyOrNull();
  }
}
