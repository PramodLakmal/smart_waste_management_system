// services/route_service.dart
import 'package:smart_waste_management_system/models/route_model.dart';

class RouteService {
  final List<RouteModel> _routes = []; // In-memory storage for routes (for demonstration)

  Future<List<RouteModel>> getAllRoutes() async {
    // Simulate a network delay
    await Future.delayed(Duration(seconds: 2));
    return _routes; // Return the current list of routes
  }

  Future<void> addRoute(RouteModel route) async {
    // Simulate a network delay
    await Future.delayed(Duration(seconds: 1));
    
    // Add the new route to the list
    _routes.add(route); // In-memory addition, replace with actual DB logic
  }
}
