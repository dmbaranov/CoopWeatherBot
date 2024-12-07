const memberUpdatedQueue = 'member-updated';

class MemberUpdatedQueueEvent {
  final bool deleted;

  MemberUpdatedQueueEvent.fromJson(Map<dynamic, dynamic> json) : deleted = json['deleted'];
}
