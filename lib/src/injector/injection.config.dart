// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../core/access.dart' as _i16;
import '../core/config.dart' as _i4;
import '../core/database.dart' as _i6;
import '../core/event_bus.dart' as _i3;
import '../core/repositories/bot_user_repository.dart' as _i12;
import '../core/repositories/chat_repository.dart' as _i7;
import '../core/repositories/check_reminder_repository.dart' as _i9;
import '../core/repositories/command_statistics_repository.dart' as _i13;
import '../core/repositories/conversator_chat_repository.dart' as _i15;
import '../core/repositories/conversator_user_repository.dart' as _i10;
import '../core/repositories/news_repository.dart' as _i8;
import '../core/repositories/reputation_repository.dart' as _i11;
import '../core/repositories/weather_repository.dart' as _i14;
import '../utils/logger.dart' as _i5;

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
    gh.singleton<_i3.EventBus>(() => _i3.EventBus());
    gh.singleton<_i4.Config>(() => _i4.Config()..initialize());
    gh.factory<_i5.Logger>(
      () => loggerModule.devLogger,
      registerFor: {_dev},
    );
    gh.factory<_i5.Logger>(
      () => loggerModule.prodLogger,
      registerFor: {_prod},
    );
    gh.singleton<_i6.Database>(() => _i6.Database(
          gh<_i4.Config>(),
          gh<_i5.Logger>(),
        ));
    gh.singleton<_i7.ChatRepository>(
        () => _i7.ChatRepository(db: gh<_i6.Database>()));
    gh.singleton<_i8.NewsRepository>(
        () => _i8.NewsRepository(db: gh<_i6.Database>()));
    gh.singleton<_i9.CheckReminderRepository>(
        () => _i9.CheckReminderRepository(db: gh<_i6.Database>()));
    gh.singleton<_i10.ConversatorUserRepository>(
        () => _i10.ConversatorUserRepository(db: gh<_i6.Database>()));
    gh.singleton<_i11.ReputationRepository>(
        () => _i11.ReputationRepository(db: gh<_i6.Database>()));
    gh.singleton<_i12.BotUserRepository>(
        () => _i12.BotUserRepository(db: gh<_i6.Database>()));
    gh.singleton<_i13.CommandStatisticsRepository>(
        () => _i13.CommandStatisticsRepository(db: gh<_i6.Database>()));
    gh.singleton<_i14.WeatherRepository>(
        () => _i14.WeatherRepository(db: gh<_i6.Database>()));
    gh.singleton<_i15.ConversatorChatRepository>(
        () => _i15.ConversatorChatRepository(db: gh<_i6.Database>()));
    gh.singleton<_i16.Access>(() => _i16.Access());
    return this;
  }
}

class _$LoggerModule extends _i5.LoggerModule {}
