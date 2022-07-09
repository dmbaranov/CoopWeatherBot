import 'dart:convert';
import 'dart:io' as io;
import 'package:crypto/crypto.dart';

class Stone {
  final Map<String, dynamic> data;
  int timestamp;
  String stoneHash = '';
  String prevStoneHash = '';

  Stone({this.data}) {
    timestamp = DateTime
        .now()
        .millisecondsSinceEpoch;
  }

  Stone.fromJson(Map<String, dynamic> json)
      : data = json['data'],
        timestamp = json['timestamp'],
        stoneHash = json['stoneHash'],
        prevStoneHash = json['prevStoneHash'];

  Map<String, dynamic> toJson() =>
      {
        'timestamp': timestamp,
        'stoneHash': stoneHash,
        'prevStoneHash': prevStoneHash,
        'data': data
      };

  String generateOwnHash() {
    var bytes = utf8.encode(prevStoneHash + timestamp.toString() + jsonEncode(data));

    stoneHash = sha256.convert(bytes).toString();

    return stoneHash;
  }

  void setPrevStoneHash(String hash) {
    prevStoneHash = hash;
  }
}

class StoneCave {
  final String cavepath;
  List<Stone> cave;
  bool caveValid; // TODO: disable any operations if cave is invalid

  StoneCave({this.cavepath});

  Future<bool> initialize() async {
    var rawStoredData = await io.File(cavepath).readAsString();
    var storedStones = json.decode(rawStoredData);

    cave = [];

    await Future.forEach(storedStones, (stone) async {
      await addStone(Stone.fromJson(stone));
    });

    caveValid = checkCaveIntegrity();

    return caveValid;
  }

  Future<bool> addStone(Stone stone) async {
    var previousStoneHash = cave.isEmpty ? '0' : cave.last.stoneHash;
    stone.setPrevStoneHash(previousStoneHash);
    stone.generateOwnHash();
    cave.add(stone);

    var caveValid = checkCaveIntegrity();

    if (caveValid) {
      var caveFile = io.File(cavepath);

      await caveFile.writeAsString(json.encode(cave));

      return true;
    } else {
      print('Cave integrity is invalid, removing last stone');

      cave.removeLast();

      return false;
    }
  }

  bool checkCaveIntegrity() {
    if (cave.length != 2) return true;

    for (var i = 1; i < cave.length; i++) {
      var currentStone = cave[i];
      var previousStone = cave[i - 1];

      if (currentStone.stoneHash != currentStone.generateOwnHash()) return false;
      if (currentStone.prevStoneHash != previousStone.stoneHash) return false;
    }

    return true;
  }

  Stone getLastStone() {
    return cave.last;
  }
}
