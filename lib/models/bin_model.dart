import 'package:cloud_firestore/cloud_firestore.dart';

class Bin {
  String id;
  String type;  // e.g., "Electrical", "Plastic", "Organic"
  String nickname;
  double weight;
  String imageUrl;  // Firebase Storage URL for bin image
  double filledPercentage;
  String description;
  bool isConfirmed;  // Admin confirmation status
  String userId;  // ID of the user who added the bin

  Bin({
    required this.id,
    required this.type,
    required this.nickname,
    required this.weight,
    required this.imageUrl,
    required this.filledPercentage,
    required this.description,
    required this.isConfirmed,
    required this.userId,
  });

  // Convert a Bin to a map to send it to Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'nickname': nickname,
      'weight': weight,
      'imageUrl': imageUrl,
      'filledPercentage': filledPercentage,
      'description': description,
      'isConfirmed': isConfirmed,
      'userId': userId,
    };
  }

  // Create a Bin object from a Firestore document
  factory Bin.fromDocument(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Bin(
      id: doc.id,
      type: data['type'],
      nickname: data['nickname'],
      weight: data['weight'],
      imageUrl: data['imageUrl'],
      filledPercentage: data['filledPercentage'],
      description: data['description'],
      isConfirmed: data['isConfirmed'],
      userId: data['userId'],
    );
  }
}
