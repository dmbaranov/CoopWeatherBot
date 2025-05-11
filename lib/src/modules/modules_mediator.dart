class ModulesMediator {
  final Map<Type, Object> _modules = {};

  void registerModule(Object module) {
    _modules[module.runtimeType] = module;
  }

  T get<T extends Object>() {
    var module = _modules[T];

    if (module == null) {
      throw Exception('Module of type $T not found');
    }

    return module as T;
  }
}
