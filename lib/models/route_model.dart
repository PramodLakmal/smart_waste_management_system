import 'package:cloud_firestore/cloud_firestore.dart';

class RouteModel {
  String id;
  String routeName;
  String driverName;
  String vehicleNumber;

  var driverId;

  RouteModel({this.id = '', required this.routeName, required this.driverName, required this.vehicleNumber});

  Map<String, dynamic> toMap() {
    return {
      'routeName': routeName,
      'driverName': driverName,
      'vehicleNumber': vehicleNumber,
    };
  }

  factory RouteModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return RouteModel(
      id: doc.id,
      routeName: data['routeName'] ?? '',
      driverName: data['driverName'] ?? '',
      vehicleNumber: data['vehicleNumber'] ?? '',
    );
  }
}
