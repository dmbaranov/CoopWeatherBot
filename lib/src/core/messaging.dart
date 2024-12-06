import 'dart:async';
import 'package:dart_amqp/dart_amqp.dart';
import 'package:injectable/injectable.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/utils/logger.dart';

@singleton
class Messaging {
  late Channel _channel;

  @PostConstruct()
  void initialize() async {
    var client = Client();
    _channel = await client.channel();
  }

  Future<Consumer> subscribeToQueue(String queueName) async {
    var queue = await _channel.queue(queueName);
    var consumer = await queue.consume();

    return consumer;
  }
}

class MessagingQueue<T> {
  final Messaging _messaging;
  final Logger _logger;

  MessagingQueue()
      : _messaging = getIt<Messaging>(),
        _logger = getIt<Logger>();

  Future<Stream<T>> createStream(String queueName, T Function(Map<dynamic, dynamic>) mapper) async {
    var streamController = StreamController<T>.broadcast();
    var queue = await _messaging.subscribeToQueue(queueName);

    queue.listen((event) {
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
