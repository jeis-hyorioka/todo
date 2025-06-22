import 'package:cloud_firestore/cloud_firestore.dart';

class TodoList {
  final String id;
  final String name;
  final List<String> members;

  TodoList({required this.id, required this.name, required this.members});

  factory TodoList.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TodoList(
      id: doc.id,
      name: data['name'] ?? '',
      members: List<String>.from(data['members'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'members': members,
    };
  }
}
