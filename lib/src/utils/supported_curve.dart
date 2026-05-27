enum SupportedCurve {
  p256('P-256'),
  ed25519('Ed25519');

  const SupportedCurve(this.value);

  final String value;
}
