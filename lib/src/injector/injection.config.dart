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
import '../core/repositories/bot_user_repository_inj.dart' as _i6;
import '../core/repositories/chat_repository_inj.dart' as _i7;
import '../core/repositories/check_reminder_repository_inj.dart' as _i8;
import '../core/repositories/command_statistics_repository_inj.dart' as _i9;
import '../core/repositories/conversator_chat_repository_inj.dart' as _i11;
import '../core/repositories/conversator_user_repository_inj.dart' as _i10;
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
    gh.singleton<_i6.BotUserRepositoryInj>(
        () => _i6.BotUserRepositoryInj(db: gh<_i5.DatabaseInj>()));
    gh.singleton<_i7.ChatRepositoryInj>(
        () => _i7.ChatRepositoryInj(db: gh<_i5.DatabaseInj>()));
    gh.singleton<_i8.CheckReminderRepositoryInj>(
        () => _i8.CheckReminderRepositoryInj(db: gh<_i5.DatabaseInj>()));
    gh.singleton<_i9.CommandStatisticsRepositoryInj>(
        () => _i9.CommandStatisticsRepositoryInj(db: gh<_i5.DatabaseInj>()));
    gh.singleton<_i10.ConversatorUserRepositoryInj>(
        () => _i10.ConversatorUserRepositoryInj(db: gh<_i5.DatabaseInj>()));
    gh.singleton<_i11.ConversatorChatRepositoryInj>(
        () => _i11.ConversatorChatRepositoryInj(db: gh<_i5.DatabaseInj>()));
    return this;
  }
}

class _$LoggerModule extends _i4.LoggerModule {}
