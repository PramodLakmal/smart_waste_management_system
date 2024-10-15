import 'package:cloud_firestore/cloud_firestore.dart';

class Bin {
  String binId;  // Firestore document ID
  String userId;  // ID of the user who added the bin
  String type;  // e.g., "Electrical Waste", "Plastic Waste", "Organic Waste"
  String nickname;  // Bin nickname
  String description;  // Bin description (optional)
  double weight;  // Weight of the bin in kg
  String? imageUrl;  // URL for the bin image (nullable)
  double filledPercentage;  // Percentage of the bin that's filled (default 0)
  DateTime createdAt;  // Timestamp for when the bin was created
  bool isConfirmed;  // Admin confirmation status (default false)
  bool collectionRequestSent;  // Collection request status (default false)

  Bin({
    required this.binId,
    required this.userId,
    required this.type,
    required this.nickname,
    required this.description,
    required this.weight,
    this.imageUrl,
    required this.filledPercentage,
    required this.createdAt,
    required this.isConfirmed,
    required this.collectionRequestSent,
  });

  // Convert a Bin to a map to send it to Firestore
  Map<String, dynamic> toMap() {
    return {
      'binId': binId,
      'userId': userId,
      'type': type,
      'nickname': nickname,
      'description': description,
      'weight': weight,
      'imageUrl': imageUrl,
      'filledPercentage': filledPercentage,
      'createdAt': Timestamp.fromDate(createdAt),  // Firestore compatible timestamp
      'confirmed': isConfirmed,
      'collectionRequestSent': collectionRequestSent,
    };
  }

  // Create a Bin object from a Firestore document
  factory Bin.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Bin(
      binId: data['binId'],
      userId: data['userId'],
      type: data['type'],
      nickname: data['nickname'],
      description: data['description'],
      weight: (data['weight'] as num).toDouble(),  // Ensures double type
      imageUrl: data['imageUrl'],
      filledPercentage: (data['filledPercentage'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isConfirmed: data['confirmed'] as bool,
      collectionRequestSent: data['collectionRequestSent'] as bool,
    );
  }
}
