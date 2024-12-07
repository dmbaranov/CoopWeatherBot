import 'dart:async';
import 'package:dart_amqp/dart_amqp.dart';
import 'package:injectable/injectable.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/utils/logger.dart';

@singleton
class MessagingClient {
  late Channel _channel;

  @PostConstruct()
  void initialize() async {
    var client = Client();
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

  MessagingQueue()
      : _client = getIt<MessagingClient>(),
        _logger = getIt<Logger>();

  Future<Stream<T>> createStream(String queueName, T Function(Map<dynamic, dynamic>) mapper) async {
    var streamController = StreamController<T>.broadcast();
    var queueConsumer = await _client.getQueueConsumer(queueName);

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
