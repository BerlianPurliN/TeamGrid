import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gantt/flutter_gantt.dart';
import 'package:teamgrid/routes/app_rouutes.dart';

class ResourceMonitorEmployeesPage extends StatefulWidget {
  const ResourceMonitorEmployeesPage({super.key});

  @override
  State<ResourceMonitorEmployeesPage> createState() =>
      _ResourceMonitorEmployeesPageState();
}

class _ResourceMonitorEmployeesPageState
    extends State<ResourceMonitorEmployeesPage> {
  late GanttController _ganttController;

  @override
  void dispose() {
    _ganttController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _ganttController = GanttController(
      startDate: DateTime.now().subtract(const Duration(days: 3)),
      daysViews: 15,
    );
  }

  void _jumpToDate(DateTime date) {
    setState(() {
      _ganttController.dispose();
      _ganttController = GanttController(
        startDate: date.subtract(const Duration(days: 3)),
        daysViews: 15,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Monitoring Employees"),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: "Jump to Today",
            onPressed: () => _jumpToDate(DateTime.now()),
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert),
            tooltip: "Switch to Projects",
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              AppRoutes.manageResourcesProjects,
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('status', isEqualTo: 'Active')
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var employees = userSnapshot.data!.docs;
          if (employees.isEmpty)
            return const Center(child: Text("Tidak ada karyawan aktif"));

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup('team_members')
                .snapshots(),
            builder: (context, taskSnapshot) {
              if (!taskSnapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              List<GanttActivity> ganttActivities = [];

              for (var employeeDoc in employees) {
                var empData = employeeDoc.data() as Map<String, dynamic>;

                if (empData['role'] == 'Admin') continue;

                String empId = employeeDoc.id;
                String empName = empData['name'] ?? 'Unknown';

                var employeeTasks = taskSnapshot.data!.docs.where((taskDoc) {
                  var taskData = taskDoc.data() as Map<String, dynamic>;
                  return taskData['employee_id'] == empId;
                }).toList();

                List<GanttActivity> childActivities = [];

                for (var taskDoc in employeeTasks) {
                  var task = taskDoc.data() as Map<String, dynamic>;
                  String taskId = taskDoc.id;

                  if (task['start_date'] == null || task['end_date'] == null)
                    continue;

                  DateTime start = (task['start_date'] as Timestamp).toDate();
                  DateTime end = (task['end_date'] as Timestamp).toDate();
                  int workload = task['workload'] ?? 100;
                  String projectName =
                      task['project_name'] ?? 'Unknown Project';

                  Color taskColor = Colors.blue;
                  if (workload >= 80) taskColor = Colors.orange;
                  if (workload > 100) taskColor = Colors.red;

                  childActivities.add(
                    GanttActivity(
                      key: taskId,
                      start: start,
                      end: end,
                      title: "$projectName ($workload%)",
                      color: taskColor,
                    ),
                  );
                }

                if (childActivities.isEmpty) continue;

                DateTime parentStart = childActivities
                    .map((e) => e.start)
                    .reduce((a, b) => a.isBefore(b) ? a : b);

                DateTime parentEnd = childActivities
                    .map((e) => e.end)
                    .reduce((a, b) => a.isAfter(b) ? a : b);

                parentStart = parentStart.subtract(const Duration(days: 0));
                parentEnd = parentEnd.add(const Duration(days: 0));

                ganttActivities.add(
                  GanttActivity(
                    key: empId,
                    title: empName,
                    start: parentStart,
                    end: parentEnd,
                    color: Colors.grey.shade500,
                    children: childActivities,
                  ),
                );
              }

              if (ganttActivities.isEmpty) {
                return const Center(child: Text("Belum ada alokasi tugas"));
              }

              return Gantt(
                key: ValueKey(_ganttController),
                controller: _ganttController,
                activities: ganttActivities,
                theme: GanttTheme(
                  todayBackgroundColor: const Color.fromARGB(255, 0, 128, 255),
                  todayTextColor: Colors.white,
                  cellHeight: 32.0,
                  rowPadding: 8,
                  headerHeight: 40,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btn-1",
            onPressed: () => Navigator.pushNamed(context, AppRoutes.manageProjects),
            backgroundColor: Colors.lightBlue,
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: "btn-2",
            onPressed: () => Navigator.pushNamed(context, AppRoutes.benchList),
            label: const Text("Who Is Free Now?"),
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
            extendedPadding: const EdgeInsets.symmetric(horizontal: 15),
          ),
        ],
      ),
    );
  }
}
