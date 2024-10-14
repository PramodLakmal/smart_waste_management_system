import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_waste_management_system/screens/admin/create_schedule.dart';
import 'package:smart_waste_management_system/screens/admin/schedule_details.dart';
import 'package:smart_waste_management_system/screens/admin/special_requests_for_scheduling.dart';
import 'package:smart_waste_management_system/screens/home_screen.dart';
import 'special_waste_collection_schedule.dart';
import '../../models/schedule_model.dart';

class WasteCollectionSchedule extends StatefulWidget {
  @override
  _WasteCollectionScheduleState createState() =>
      _WasteCollectionScheduleState();
}

class _WasteCollectionScheduleState extends State<WasteCollectionSchedule> {
  int selectedYear = DateTime.now().year;
  String selectedMonth = DateFormat('MMMM').format(DateTime.now());
  bool isMonthView = true;

  Map<String, List<Schedule>> groupSchedulesByMonth(
      List<Schedule> schedules) {
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
      backgroundColor: Colors.green[20],
      appBar: AppBar(
        title: Text('Waste Collection Schedule',
            style: TextStyle(
                color: const Color.fromARGB(221, 255, 255, 255), fontWeight: FontWeight.bold)
                ),
        backgroundColor: Colors.green[800],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          IconButton(icon: Icon(Icons.notifications_none), onPressed: () {}),
          IconButton(icon: Icon(Icons.filter_list), onPressed: () {}),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: CircleAvatar(
              backgroundColor: Colors.green[700],
              child: Text('A', style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0))),
            ),
          ),
        ],
      ),
      drawer: Sidebar(),
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
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.red)));
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateSchedulePage()),
          );
        },
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Create Schedule',
          style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.green[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                selectedYear.toString(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              TextButton.icon(
                icon: Icon(Icons.arrow_drop_down, color: Colors.green[700]),
                label: Text(selectedMonth,
                    style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold)),
                onPressed: () {
                  // Show month selector
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildViewToggleButton('Week', !isMonthView),
              SizedBox(width: 16),
              _buildViewToggleButton('Month', isMonthView),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(String label, bool isSelected) {
    return ElevatedButton(
      onPressed: () {
        setState(() => isMonthView = label == 'Month');
      },
      child: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        backgroundColor: isSelected ? Colors.green[700] : Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  List<Widget> _buildScheduleList(
      Map<String, List<Schedule>> groupedSchedules) {
    List<Widget> widgets = [];

    groupedSchedules.forEach((month, schedules) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    month.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green[700],
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${schedules.length} Schedules',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
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
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
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
    Color borderColor =
        schedule.status == 'completed' ? Colors.green : Colors.orange;
    Color backgroundColor = schedule.status == 'completed'
        ? Colors.green[50]!
        : Colors.orange[50]!;

    int requestCount = schedule.userIds.length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleDetailsPage(schedule: schedule),
          ),
        );
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 2),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
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
                        schedule.city,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.share, size: 18, color: Colors.green),
                  ],
                ),
                SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, getDuration(schedule)),
                SizedBox(height: 4),
                _buildInfoRow(Icons.person_outline, schedule.wasteCollector),
                SizedBox(height: 4),
                _buildInfoRow(
                    Icons.group, '$requestCount request${requestCount == 1 ? '' : 's'}'),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    schedule.status == 'completed'
                        ? 'COMPLETED'
                        : 'IN PROGRESS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: borderColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Sidebar widget
class Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color:Color(0xFF4CAF50),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          'S',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Scheduling',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            Icons.home,
            'Home',
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            ),
          ),
          _buildDrawerItem(
            context,
            Icons.schedule,
            'Waste Collection Schedule',
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WasteCollectionSchedule()),
            ),
            isSelected: true,
          ),
          _buildDrawerItem(
            context,
            Icons.list_alt,
            'Special Requests',
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SpecialRequestsForSchedulingScreen(),
              ),
            ),
          ),
          _buildDrawerItem(
            context,
            Icons.calendar_today,
            'Special Schedules',
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SpecialWasteCollectionSchedule(),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isSelected = false,
    bool showTrailing = true,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Color(0xFF4CAF50) : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.green[600] : Colors.grey[900],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: showTrailing ? Icon(Icons.chevron_right) : null,
      selected: isSelected,
      selectedTileColor: Colors.blue[50],
      onTap: onTap,
    );
  }
}