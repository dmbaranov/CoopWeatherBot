import 'package:dart_amqp/dart_amqp.dart';
import 'package:injectable/injectable.dart';

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
