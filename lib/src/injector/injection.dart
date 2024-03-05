import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(preferRelativeImports: true)
void setupInjection(bool isProd) => getIt.init(environment: isProd ? Environment.prod : Environment.dev);
