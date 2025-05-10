// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../core/access.dart' as _i328;
import '../core/chat_config.dart' as _i570;
import '../core/config.dart' as _i861;
import '../core/database.dart' as _i163;
import '../core/event_bus.dart' as _i400;
import '../core/messaging.dart' as _i676;
import '../core/repositories/bot_user_repository.dart' as _i912;
import '../core/repositories/chat_config_repository.dart' as _i41;
import '../core/repositories/chat_repository.dart' as _i407;
import '../core/repositories/check_reminder_repository.dart' as _i504;
import '../core/repositories/command_statistics_repository.dart' as _i24;
import '../core/repositories/conversator_chat_repository.dart' as _i1039;
import '../core/repositories/conversator_user_repository.dart' as _i734;
import '../core/repositories/hero_stats_repository.dart' as _i964;
import '../core/repositories/news_repository.dart' as _i786;
import '../core/repositories/reputation_repository.dart' as _i754;
import '../core/repositories/weather_repository.dart' as _i665;
import '../core/swearwords.dart' as _i320;
import '../utils/logger.dart' as _i221;

const String _dev = 'dev';
const String _prod = 'prod';

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final loggerModule = _$LoggerModule();
    gh.singleton<_i400.EventBus>(() => _i400.EventBus());
    gh.singleton<_i861.Config>(() => _i861.Config()..initialize());
    gh.factory<_i221.Logger>(
      () => loggerModule.devLogger,
      registerFor: {_dev},
    );
    gh.singleton<_i320.Swearwords>(
        () => _i320.Swearwords(gh<_i221.Logger>())..initialize());
    gh.factory<_i221.Logger>(
      () => loggerModule.prodLogger,
      registerFor: {_prod},
    );
    gh.singleton<_i163.Database>(() => _i163.Database(
          gh<_i861.Config>(),
          gh<_i221.Logger>(),
        ));
    gh.singleton<_i676.MessagingClient>(
        () => _i676.MessagingClient(gh<_i861.Config>())..initialize());
    gh.singleton<_i407.ChatRepository>(
        () => _i407.ChatRepository(db: gh<_i163.Database>()));
    gh.singleton<_i786.NewsRepository>(
        () => _i786.NewsRepository(db: gh<_i163.Database>()));
    gh.singleton<_i504.CheckReminderRepository>(
        () => _i504.CheckReminderRepository(db: gh<_i163.Database>()));
    gh.singleton<_i734.ConversatorUserRepository>(
        () => _i734.ConversatorUserRepository(db: gh<_i163.Database>()));
    gh.singleton<_i754.ReputationRepository>(
        () => _i754.ReputationRepository(db: gh<_i163.Database>()));
    gh.singleton<_i912.BotUserRepository>(
        () => _i912.BotUserRepository(db: gh<_i163.Database>()));
    gh.singleton<_i24.CommandStatisticsRepository>(
        () => _i24.CommandStatisticsRepository(db: gh<_i163.Database>()));
    gh.singleton<_i41.ChatConfigRepository>(
        () => _i41.ChatConfigRepository(db: gh<_i163.Database>()));
    gh.singleton<_i665.WeatherRepository>(
        () => _i665.WeatherRepository(db: gh<_i163.Database>()));
    gh.singleton<_i1039.ConversatorChatRepository>(
        () => _i1039.ConversatorChatRepository(db: gh<_i163.Database>()));
    gh.singleton<_i964.HeroStatsRepository>(
        () => _i964.HeroStatsRepository(db: gh<_i163.Database>()));
    gh.singleton<_i328.Access>(() => _i328.Access(
          gh<_i861.Config>(),
          gh<_i912.BotUserRepository>(),
          gh<_i400.EventBus>(),
          gh<_i221.Logger>(),
        ));
    gh.singleton<_i570.ChatConfig>(
        () => _i570.ChatConfig(gh<_i41.ChatConfigRepository>())..initialize());
    return this;
  }
}

class _$LoggerModule extends _i221.LoggerModule {}
