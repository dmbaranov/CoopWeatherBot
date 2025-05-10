import 'dart:async';
import 'package:dart_amqp/dart_amqp.dart';
import 'package:injectable/injectable.dart';
import 'package:weather/src/core/config.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/utils/logger.dart';

@singleton
class MessagingClient {
  final Config _config;
  late Channel _channel;

  MessagingClient(this._config);

  @PostConstruct()
  void initialize() async {
    var client = Client(settings: ConnectionSettings(host: _config.messagingHost, port: _config.messagingPort));
    _channel = await client.channel();
  }

  Future<Consumer> getQueueConsumer(String queueName) async {
    var queue = await _channel.queue(queueName);
    var consumer = await queue.consume();

    return consumer;
  }
}

class MessagingQueue<T> {
  final MessagingClient _client;
  final Logger _logger;
  final Config _config;

  MessagingQueue()
      : _client = getIt<MessagingClient>(),
        _logger = getIt<Logger>(),
        _config = getIt<Config>();

  Future<Stream<T>> createStream(String queueName, T Function(Map<dynamic, dynamic>) mapper) async {
    var streamController = StreamController<T>.broadcast();
    var queueNameWithPlatform = "${_config.chatPlatform.value}.$queueName";
    var queueConsumer = await _client.getQueueConsumer(queueNameWithPlatform);

    queueConsumer.listen((event) {
      try {
        var mappedEvent = mapper(event.payloadAsJson);

        streamController.sink.add(mappedEvent);
      } catch (e) {
        _logger.e("Could not convert $queueName queue message: $e");
      }
    });

    return streamController.stream;
  }
}
