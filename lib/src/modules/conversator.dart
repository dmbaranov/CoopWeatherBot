import 'dart:convert';
import 'package:http/http.dart';

final String _converstorApiURL = 'https://api.openai.com/v1/chat/completions';
final String _conversatorModel = 'gpt-3.5-turbo-0301';

class Conversator {
  final String conversatorApiKey;
  final String _apiBaseUrl = _converstorApiURL;
  final String _model = _conversatorModel;

  Conversator(this.conversatorApiKey);

  Future<String> getConversationReply(String question) async {
    var response = await _getConversatorResponse(question);
    var questionReply = response['choices']?[0]?['message']?['content'] ?? 'No response';

    return questionReply;
  }

  Future<Map<String, dynamic>> _getConversatorResponse(String question) async {
    var headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $conversatorApiKey'};
    var body = {
      'model': _model,
      'messages': [
        {'role': 'user', 'content': question}
      ]
    };

    var response = await post(Uri.parse(_apiBaseUrl), headers: headers, body: json.encode(body), encoding: Encoding.getByName('utf-8'));

    return json.decode(utf8.decode(response.bodyBytes));
  }
}
