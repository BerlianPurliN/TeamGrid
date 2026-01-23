import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gantt/flutter_gantt.dart';
import 'package:teamgrid/routes/app_rouutes.dart';

class ResourceMonitorProjectsPage extends StatefulWidget {
  const ResourceMonitorProjectsPage({super.key});

  @override
  State<ResourceMonitorProjectsPage> createState() =>
      _ResourceMonitorProjectsPageState();
}

class _ResourceMonitorProjectsPageState
    extends State<ResourceMonitorProjectsPage> {
  late GanttController _ganttController;

  @override
  void initState() {
    super.initState();
    _ganttController = GanttController(
      startDate: DateTime.now().subtract(const Duration(days: 3)),
      daysViews: 15,
    );
  }

  @override
  void dispose() {
    _ganttController.dispose();
    super.dispose();
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
        title: const Text("Monitoring Projects"),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: "Jump to Today",
            onPressed: () => _jumpToDate(DateTime.now()),
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert),
            tooltip: "Switch to Employees",
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              AppRoutes.manageResourcesEmployees,
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('projects').snapshots(),
        builder: (context, projectSnapshot) {
          if (!projectSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var projectDocs = projectSnapshot.data!.docs;
          if (projectDocs.isEmpty) {
            return const Center(child: Text("Belum ada data proyek"));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('status', isEqualTo: 'Active')
                .snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              Set<String> validEmployeeIds = userSnapshot.data!.docs
                  .where(
                    (doc) =>
                        (doc.data() as Map<String, dynamic>)['role'] != 'Admin',
                  )
                  .map((doc) => doc.id)
                  .toSet();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collectionGroup('team_members')
                    .snapshots(),
                builder: (context, teamSnapshot) {
                  if (!teamSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<GanttActivity> ganttActivities = [];

                  for (var projDoc in projectDocs) {
                    var projData = projDoc.data() as Map<String, dynamic>;
                    String projectId = projDoc.id;
                    String projectName =
                        projData['project_name'] ?? 'Unnamed Project';

                    var projectTasks = teamSnapshot.data!.docs.where((taskDoc) {
                      bool isSameProject =
                          taskDoc.reference.parent.parent?.id == projectId;

                      if (!isSameProject) return false;

                      var tData = taskDoc.data() as Map<String, dynamic>;
                      return validEmployeeIds.contains(tData['employee_id']);
                    }).toList();

                    List<GanttActivity> childActivities = [];

                    for (var taskDoc in projectTasks) {
                      var data = taskDoc.data() as Map<String, dynamic>;

                      if (data['start_date'] == null ||
                          data['end_date'] == null)
                        continue;

                      DateTime start = (data['start_date'] as Timestamp)
                          .toDate();
                      DateTime end = (data['end_date'] as Timestamp).toDate();

                      String empName = data['name'] ?? 'Unknown';
                      String role = data['project_role'] ?? 'Member';
                      int workload = data['workload'] ?? 100;

                      Color taskColor = Colors.blue;
                      if (workload >= 80) taskColor = Colors.orange;
                      if (workload > 100) taskColor = Colors.red;

                      childActivities.add(
                        GanttActivity(
                          key: taskDoc.id,
                          start: start,
                          end: end,
                          title: "$empName: $role ($workload%)",
                          color: taskColor,
                        ),
                      );
                    }

                    DateTime parentStart;
                    DateTime parentEnd;

                    if (childActivities.isNotEmpty) {
                      parentStart = childActivities
                          .map((e) => e.start)
                          .reduce((a, b) => a.isBefore(b) ? a : b);
                      parentEnd = childActivities
                          .map((e) => e.end)
                          .reduce((a, b) => a.isAfter(b) ? a : b);
                    } else {
                      if (projData['start_date'] != null &&
                          projData['deadline'] != null) {
                        parentStart = (projData['start_date'] as Timestamp)
                            .toDate();
                        parentEnd = (projData['deadline'] as Timestamp)
                            .toDate();
                      } else {
                        parentStart = DateTime.now();
                        parentEnd = DateTime.now().add(
                          const Duration(days: 30),
                        );
                      }
                    }

                    ganttActivities.add(
                      GanttActivity(
                        key: "prj_$projectId",
                        title: projectName,
                        start: parentStart,
                        end: parentEnd,
                        color: Colors.grey.shade500,
                        children: childActivities,
                      ),
                    );
                  }

                  if (ganttActivities.isEmpty) {
                    return const Center(child: Text("Data proyek kosong"));
                  }

                  return Gantt(
                    key: ValueKey(_ganttController),
                    controller: _ganttController,
                    activities: ganttActivities,
                    theme: GanttTheme(
                      todayBackgroundColor: const Color.fromARGB(
                        255,
                        0,
                        128,
                        255,
                      ),
                      todayTextColor: Colors.white,
                      cellHeight: 32.0,
                      rowPadding: 8,
                      headerHeight: 40,
                    ),
                  );
                },
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
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.manageProjects),
            backgroundColor: Colors.lightBlue,
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
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
