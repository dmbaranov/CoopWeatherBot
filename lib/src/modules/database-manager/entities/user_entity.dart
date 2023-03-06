import 'package:postgres/postgres.dart';
import 'entity.dart';

class UserEntity extends Entity {
  UserEntity({required super.dbConnection}) : super(entityName: 'user');

  getAllUsers() async {
    var users = await executeQuery(queriesMap['get_all_users']);

    print(users);
  }
}
