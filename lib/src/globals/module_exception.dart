class ModuleException implements Exception {
  final String cause;

  ModuleException(this.cause);

  @override
  String toString() {
    return cause;
  }
}
