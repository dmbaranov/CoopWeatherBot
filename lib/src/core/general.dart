import 'dart:convert';
import 'package:http/http.dart' as http;
import './chat.dart';

class General {
  final Chat chat;
  final String repositoryUrl;
  final String _baseGithubApiUrl = 'https://api.github.com';

  General({required this.chat, required this.repositoryUrl});

  String healthCheck(String chatId) {
    return chat.getText(chatId, 'general.bot_is_alive');
  }

  Future<String> getLastCommitMessage() async {
    var commitApiUrl = '$_baseGithubApiUrl/repos$repositoryUrl/commits';
    var response = await http.get(Uri.parse(commitApiUrl));
    var responseJson = jsonDecode(response.body);
    var updateMessage = responseJson[0]['commit']['message'];

    return updateMessage;
  }
}
