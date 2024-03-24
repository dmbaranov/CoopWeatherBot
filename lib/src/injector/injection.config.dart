// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../core/config.dart' as _i3;
import '../core/database_inj.dart' as _i5;
import '../utils/logger.dart' as _i4;

const String _dev = 'dev';
const String _prod = 'prod';

extension GetItInjectableX on _i1.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i1.GetIt init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final loggerModule = _$LoggerModule();
    gh.singleton<_i3.Config>(() => _i3.Config()..initialize());
    gh.factory<_i4.Logger>(
      () => loggerModule.devLogger,
      registerFor: {_dev},
    );
    gh.factory<_i4.Logger>(
      () => loggerModule.prodLogger,
      registerFor: {_prod},
    );
    gh.singleton<_i5.DatabaseInj>(() => _i5.DatabaseInj(
          gh<_i3.Config>(),
          gh<_i4.Logger>(),
        ));
    return this;
  }
}

class _$LoggerModule extends _i4.LoggerModule {}
