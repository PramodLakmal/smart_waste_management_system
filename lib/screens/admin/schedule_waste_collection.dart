import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_waste_management_system/screens/admin/create_schedule.dart';
import 'package:smart_waste_management_system/screens/admin/schedule_details.dart'; // Correct import

import '../../models/schedule_model.dart';

class WasteCollectionSchedule extends StatefulWidget {
  @override
  _WasteCollectionScheduleState createState() => _WasteCollectionScheduleState();
}

class _WasteCollectionScheduleState extends State<WasteCollectionSchedule> {
  int selectedYear = DateTime.now().year;
  String selectedMonth = DateFormat('MMMM').format(DateTime.now());
  bool isMonthView = true;

  // Group schedules by month
  Map<String, List<Schedule>> groupSchedulesByMonth(List<Schedule> schedules) {
    Map<String, List<Schedule>> grouped = {};
    for (var schedule in schedules) {
      String month = DateFormat('MMMM').format(schedule.startTime);
      if (!grouped.containsKey(month)) {
        grouped[month] = [];
      }
      grouped[month]!.add(schedule);
    }
    return grouped;
  }

  // Calculate duration between start and end time
  String getDuration(Schedule schedule) {
    Duration duration = schedule.endTime.difference(schedule.startTime);
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''}';
    } else {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Waste Collecting Schedule'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {},
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: CircleAvatar(
              backgroundColor: Colors.purple[100],
              child: Text('A'),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schedules')
                  .orderBy('startTime')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                List<Schedule> schedules = snapshot.data!.docs
                    .map((doc) => Schedule.fromFirestore(doc))
                    .toList();

                Map<String, List<Schedule>> groupedSchedules = 
                    groupSchedulesByMonth(schedules);

                return ListView(
                  padding: EdgeInsets.all(16),
                  children: _buildScheduleList(groupedSchedules),
                );
              },
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.purple,
      //   child: Icon(Icons.add),
      //   onPressed: () {
      //     // Navigate to create schedule page
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => CreateSchedulePage()),
      //     );
      //   },
      // ),
    );
  }

 Widget _buildHeader() {
  return Container(
    padding: EdgeInsets.all(16),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              selectedYear.toString(),
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(width: 8),
            TextButton(
              child: Text(selectedMonth),
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple,
              ),
              onPressed: () {
                // Show month selector
              },
            ),
            Spacer(), // This will push the button to the right
            ElevatedButton(
              onPressed: () {
                // Navigate to create schedule page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateSchedulePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 49, 136, 207),
              ),
              child: Text('Create'), // Display "Create" text
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            ChoiceChip(
              label: Text('Week'),
              selected: !isMonthView,
              onSelected: (selected) {
                setState(() => isMonthView = !selected);
              },
            ),
            SizedBox(width: 8),
            ChoiceChip(
              label: Text('Month'),
              selected: isMonthView,
              onSelected: (selected) {
                setState(() => isMonthView = selected);
              },
            ),
          ],
        ),
      ],
    ),
  );
}


  List<Widget> _buildScheduleList(Map<String, List<Schedule>> groupedSchedules) {
    List<Widget> widgets = [];

    groupedSchedules.forEach((month, schedules) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    month.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${schedules.length} Schedules',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  return _buildScheduleCard(schedule);
                },
              ),
            ],
          ),
        ),
      );
    });

    return widgets;
  }

  Widget _buildScheduleCard(Schedule schedule) {
    Color borderColor = schedule.status == 'completed' ? Colors.green : Colors.orange;

    return GestureDetector(
      onTap: () {
        // Navigate to the ScheduleDetailsPage with the selected schedule
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleDetailsPage(schedule: schedule), // Correct page
          ),
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: borderColor,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        schedule.collectionZone,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.share, size: 16, color: Colors.grey),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      getDuration(schedule),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.local_shipping, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      schedule.vehicleNumber,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        schedule.wasteCollector,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
