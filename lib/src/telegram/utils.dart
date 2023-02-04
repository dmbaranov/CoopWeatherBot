import 'package:teledart/model.dart';

String getOneParameterFromMessage(TeleDartMessage message) {
  var options = message.text?.split(' ');

  if (options == null || options.length != 2) return '';

  return options[1];
}
