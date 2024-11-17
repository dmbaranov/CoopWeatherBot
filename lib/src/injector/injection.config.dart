// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../core/access.dart' as _i19;
import '../core/config.dart' as _i4;
import '../core/database.dart' as _i7;
import '../core/event_bus.dart' as _i3;
import '../core/messaging.dart' as _i5;
import '../core/repositories/bot_user_repository.dart' as _i13;
import '../core/repositories/chat_repository.dart' as _i8;
import '../core/repositories/check_reminder_repository.dart' as _i10;
import '../core/repositories/command_statistics_repository.dart' as _i14;
import '../core/repositories/conversator_chat_repository.dart' as _i16;
import '../core/repositories/conversator_user_repository.dart' as _i11;
import '../core/repositories/hero_stats_repository.dart' as _i17;
import '../core/repositories/news_repository.dart' as _i9;
import '../core/repositories/reputation_repository.dart' as _i12;
import '../core/repositories/weather_repository.dart' as _i15;
import '../core/swearwords.dart' as _i18;
import '../utils/logger.dart' as _i6;

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
    gh.singleton<_i5.Messaging>(() => _i5.Messaging()..initialize());
    gh.factory<_i6.Logger>(
      () => loggerModule.devLogger,
      registerFor: {_dev},
    );
    gh.factory<_i6.Logger>(
      () => loggerModule.prodLogger,
      registerFor: {_prod},
    );
    gh.singleton<_i7.Database>(() => _i7.Database(
          gh<_i4.Config>(),
          gh<_i6.Logger>(),
        ));
    gh.singleton<_i8.ChatRepository>(
        () => _i8.ChatRepository(db: gh<_i7.Database>()));
    gh.singleton<_i9.NewsRepository>(
        () => _i9.NewsRepository(db: gh<_i7.Database>()));
    gh.singleton<_i10.CheckReminderRepository>(
        () => _i10.CheckReminderRepository(db: gh<_i7.Database>()));
    gh.singleton<_i11.ConversatorUserRepository>(
        () => _i11.ConversatorUserRepository(db: gh<_i7.Database>()));
    gh.singleton<_i12.ReputationRepository>(
        () => _i12.ReputationRepository(db: gh<_i7.Database>()));
    gh.singleton<_i13.BotUserRepository>(
        () => _i13.BotUserRepository(db: gh<_i7.Database>()));
    gh.singleton<_i14.CommandStatisticsRepository>(
        () => _i14.CommandStatisticsRepository(db: gh<_i7.Database>()));
    gh.singleton<_i15.WeatherRepository>(
        () => _i15.WeatherRepository(db: gh<_i7.Database>()));
    gh.singleton<_i16.ConversatorChatRepository>(
        () => _i16.ConversatorChatRepository(db: gh<_i7.Database>()));
    gh.singleton<_i17.HeroStatsRepository>(
        () => _i17.HeroStatsRepository(db: gh<_i7.Database>()));
    gh.singleton<_i18.Swearwords>(() => _i18.Swearwords()..initialize());
    gh.singleton<_i19.Access>(() => _i19.Access());
    return this;
  }
}

class _$LoggerModule extends _i6.LoggerModule {}
