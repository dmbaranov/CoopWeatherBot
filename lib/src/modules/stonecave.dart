import 'dart:convert';
import 'dart:io' as io;
import 'package:crypto/crypto.dart';

class Stone {
  final Map<String, dynamic> data;
  late int timestamp;
  String stoneHash = '';
  String prevStoneHash = '';

  Stone({required this.data}) {
    timestamp = DateTime.now().millisecondsSinceEpoch;
  }

  Stone.fromJson(Map<String, dynamic> json)
      : data = json['data'],
        timestamp = json['timestamp'],
        stoneHash = json['stoneHash'],
        prevStoneHash = json['prevStoneHash'];

  Map<String, dynamic> toJson() => {'timestamp': timestamp, 'stoneHash': stoneHash, 'prevStoneHash': prevStoneHash, 'data': data};

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

  StoneCave({required this.cavepath});

  Future<bool> initialize() async {
    var caveValid = await checkCaveIntegrity();

    return caveValid;
  }

  Future<List<Stone>> getCave() async {
    var rawCaveData = await io.File(cavepath).readAsString();
    var stones = json.decode(rawCaveData);
    List<Stone> cave = [];

    await Future.forEach(stones, (stone) async {
      cave.add(Stone.fromJson(stone as Map<String, dynamic>));
    });

    return cave;
  }

  Future<bool> addStone(Stone stone) async {
    var cave = await getCave();
    var previousStoneHash = cave.isEmpty ? '0' : cave.last.stoneHash;
    stone.setPrevStoneHash(previousStoneHash);
    stone.generateOwnHash();
    cave.add(stone);

    var caveValid = await checkCaveIntegrity();

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

  Future<bool> checkCaveIntegrity() async {
    var cave = await getCave();

    if (cave.isEmpty) return true;

    for (var i = 1; i < cave.length; i++) {
      var currentStone = cave[i];
      var previousStone = cave[i - 1];

      if (currentStone.stoneHash != currentStone.generateOwnHash()) return false;
      if (currentStone.prevStoneHash != previousStone.stoneHash) return false;
    }

    return true;
  }

  Future<Stone?> getLastStone() async {
    var cave = await getCave();
    return cave.isEmpty ? null : cave.last;
  }
}
