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
import '../core/database.dart' as _i5;
import '../core/repositories/bot_user_repository.dart' as _i11;
import '../core/repositories/chat_repository.dart' as _i6;
import '../core/repositories/check_reminder_repository.dart' as _i8;
import '../core/repositories/command_statistics_repository.dart' as _i12;
import '../core/repositories/conversator_chat_repository.dart' as _i14;
import '../core/repositories/conversator_user_repository.dart' as _i9;
import '../core/repositories/news_repository.dart' as _i7;
import '../core/repositories/reputation_repository.dart' as _i10;
import '../core/repositories/weather_repository.dart' as _i13;
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
    gh.singleton<_i5.Database>(() => _i5.Database(
          gh<_i3.Config>(),
          gh<_i4.Logger>(),
        ));
    gh.singleton<_i6.ChatRepository>(
        () => _i6.ChatRepository(db: gh<_i5.Database>()));
    gh.singleton<_i7.NewsRepository>(
        () => _i7.NewsRepository(db: gh<_i5.Database>()));
    gh.singleton<_i8.CheckReminderRepository>(
        () => _i8.CheckReminderRepository(db: gh<_i5.Database>()));
    gh.singleton<_i9.ConversatorUserRepository>(
        () => _i9.ConversatorUserRepository(db: gh<_i5.Database>()));
    gh.singleton<_i10.ReputationRepository>(
        () => _i10.ReputationRepository(db: gh<_i5.Database>()));
    gh.singleton<_i11.BotUserRepository>(
        () => _i11.BotUserRepository(db: gh<_i5.Database>()));
    gh.singleton<_i12.CommandStatisticsRepository>(
        () => _i12.CommandStatisticsRepository(db: gh<_i5.Database>()));
    gh.singleton<_i13.WeatherRepository>(
        () => _i13.WeatherRepository(db: gh<_i5.Database>()));
    gh.singleton<_i14.ConversatorChatRepository>(
        () => _i14.ConversatorChatRepository(db: gh<_i5.Database>()));
    return this;
  }
}

class _$LoggerModule extends _i4.LoggerModule {}
