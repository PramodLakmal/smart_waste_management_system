import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'route_monitoring_screen.dart';

class ScheduleListScreen extends StatefulWidget {
  @override
  _ScheduleListScreenState createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  String? selectedVehicleNumber; // Holds the selected vehicle number
  Map<String, dynamic>? selectedSchedule; // Holds the selected schedule details

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Normal Schedule List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('schedules').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var schedules = snapshot.data!.docs;

          return ListView.builder(
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              var schedule = schedules[index].data() as Map<String, dynamic>;
              var vehicleNumber = schedule['vehicleNumber'];
              var wasteCollector = schedule['wasteCollector'];
              var city = schedule['city'];

              return ListTile(
                title: Text('$city Route'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vehicle Number: $vehicleNumber'),
                    Text('Waste Collector: $wasteCollector'),
                  ],
                ),
                leading: Radio(
                  value: vehicleNumber,
                  groupValue: selectedVehicleNumber,
                  onChanged: (value) {
                    setState(() {
                      selectedVehicleNumber = value.toString();
                      selectedSchedule = schedule; // Store the selected schedule
                    });
                  },
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: selectedVehicleNumber == null
                  ? null
                  : () {
                      // Navigate to BinIdsScreen with the binIds for the selected waste collector
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BinIdsScreen(
                            binIds: selectedSchedule!['binIds'], // Pass only the bin IDs
                            wasteCollector: selectedSchedule!['wasteCollector'], // Pass the waste collector
                          ),
                        ),
                      );
                    },
              child: Text('Start Now'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Implement view summary report functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text('View Summary Report'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Implement view special schedule functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text('View Special Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
