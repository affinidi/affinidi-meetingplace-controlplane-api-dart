enum ChallengePurpose {
  authenticate('authenticate'),
  matrixToken('matrix_token');

  const ChallengePurpose(this.value);

  final String value;

  static ChallengePurpose? fromValue(String value) {
    for (final p in ChallengePurpose.values) {
      if (p.value == value) return p;
    }
    return null;
  }
}
