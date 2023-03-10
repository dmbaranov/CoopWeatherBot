import 'entity.dart';

class ChatEntity extends Entity {
  ChatEntity({required super.dbConnection}) : super(entityName: 'chat');

  Future<int?> createChat({required String id, required String name}) {
    return executeTransaction(queriesMap['create_chat'], {'id': id, 'name': name});
  }
}
