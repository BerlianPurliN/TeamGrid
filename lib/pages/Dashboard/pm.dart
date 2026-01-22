import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_gantt/flutter_gantt.dart';
import 'package:teamgrid/pages/Auth/auth_service.dart';
import 'package:teamgrid/routes/app_rouutes.dart';

class PmDashboardPage extends StatefulWidget {
  const PmDashboardPage({super.key});

  @override
  State<PmDashboardPage> createState() => _PmDashboardPageState();
}

class _PmDashboardPageState extends State<PmDashboardPage> {
  int touchedIndex = -1;

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
    final authService = AuthService();
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "PM Workspace",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            Text(
              "Hi, PM! Today is ${DateFormat.yMMMMd().format(DateTime.now())}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ],
        ),

        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),

          const SizedBox(width: 10),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Status Distribusi Proyek",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  _buildPieChartSection(),
                ],
              ),
            ),

            const Divider(thickness: 5, color: Colors.white),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Timeline Proyek",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.today, color: Colors.black),
                    tooltip: "Jump to Today",
                    onPressed: () => _jumpToDate(DateTime.now()),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 500,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('projects')
                    .snapshots(),
                builder: (context, projectSnapshot) {
                  if (!projectSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var projectDocs = projectSnapshot.data!.docs;
                  if (projectDocs.isEmpty) {
                    return const Center(
                      child: Text("Belum ada proyek berstatus Ongoing"),
                    );
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
                                (doc.data() as Map<String, dynamic>)['role'] !=
                                'Admin',
                          )
                          .map((doc) => doc.id)
                          .toSet();

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collectionGroup('team_members')
                            .snapshots(),
                        builder: (context, teamSnapshot) {
                          if (!teamSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          List<GanttActivity> ganttActivities = [];

                          for (var projDoc in projectDocs) {
                            var projData =
                                projDoc.data() as Map<String, dynamic>;
                            String projectId = projDoc.id;
                            String projectName =
                                projData['project_name'] ?? 'Unnamed Project';

                            var projectTasks = teamSnapshot.data!.docs.where((
                              taskDoc,
                            ) {
                              bool isSameProject =
                                  taskDoc.reference.parent.parent?.id ==
                                  projectId;
                              if (!isSameProject) return false;

                              var tData =
                                  taskDoc.data() as Map<String, dynamic>;
                              return validEmployeeIds.contains(
                                tData['employee_id'],
                              );
                            }).toList();

                            List<GanttActivity> childActivities = [];

                            for (var taskDoc in projectTasks) {
                              var data = taskDoc.data() as Map<String, dynamic>;

                              if (data['start_date'] == null ||
                                  data['end_date'] == null)
                                continue;

                              DateTime start = (data['start_date'] as Timestamp)
                                  .toDate();
                              DateTime end = (data['end_date'] as Timestamp)
                                  .toDate();

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

                              parentStart = parentStart.subtract(
                                const Duration(days: 1),
                              );
                              parentEnd = parentEnd.add(
                                const Duration(days: 1),
                              );
                            } else {
                              if (projData['start_date'] != null &&
                                  projData['deadline'] != null) {
                                parentStart =
                                    (projData['start_date'] as Timestamp)
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
                                color: Colors.grey.shade400,
                                children: childActivities,
                              ),
                            );
                          }

                          if (ganttActivities.isEmpty) {
                            return const Center(
                              child: Text("Data alokasi tim kosong"),
                            );
                          }

                          return Gantt(
                            key: ValueKey(_ganttController),
                            controller: _ganttController,
                            activities: ganttActivities,
                            theme: GanttTheme(
                              todayBackgroundColor: Colors.blue,
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
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.manageProjects),
            backgroundColor: Colors.blue,
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.benchList),
            label: const Text("Who Is Free Now?"),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            extendedPadding: const EdgeInsets.symmetric(horizontal: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .where(
            'status',
            whereIn: ['On-going', 'Pipeline', 'Maintenance', 'Done'],
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );

        var docs = snapshot.data!.docs;
        int ongoing = docs.where((d) => d['status'] == 'On-going').length;
        int pipeline = docs.where((d) => d['status'] == 'Pipeline').length;
        int maintenance = docs
            .where((d) => d['status'] == 'Maintenance')
            .length;
        int done = docs.where((d) => d['status'] == 'Done').length;
        int total = ongoing + pipeline + maintenance + done;

        if (total == 0) {
          return Container(
            height: 150,
            alignment: Alignment.center,
            child: Text(
              "Belum ada data proyek",
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: _generateSections(
                        ongoing,
                        pipeline,
                        maintenance,
                        done,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem("On-going", ongoing, Colors.blue, total),
                      const SizedBox(height: 10),
                      _buildLegendItem(
                        "Pipeline",
                        pipeline,
                        Colors.orange,
                        total,
                      ),
                      const SizedBox(height: 10),
                      _buildLegendItem(
                        "Maintenance",
                        maintenance,
                        Colors.green,
                        total,
                      ),
                      const SizedBox(height: 10),
                      _buildLegendItem("Done", done, Colors.grey, total),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _generateSections(
    int ongoing,
    int pipeline,
    int maintenance,
    int done,
  ) {
    return List.generate(4, (i) {
      final isTouched = i == touchedIndex;
      final double fontSize = isTouched ? 18.0 : 14.0;
      final double radius = isTouched ? 60.0 : 50.0;

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Colors.blue,
            value: ongoing.toDouble(),
            title: ongoing > 0 ? '$ongoing' : '',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        case 1:
          return PieChartSectionData(
            color: Colors.orange,
            value: pipeline.toDouble(),
            title: pipeline > 0 ? '$pipeline' : '',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        case 2:
          return PieChartSectionData(
            color: Colors.green,
            value: maintenance.toDouble(),
            title: maintenance > 0 ? '$maintenance' : '',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        case 3:
          return PieChartSectionData(
            color: Colors.grey,
            value: done.toDouble(),
            title: done > 0 ? '$done' : '',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        default:
          throw Error();
      }
    });
  }

  Widget _buildLegendItem(String title, int value, Color color, int total) {
    int percentage = total == 0 ? 0 : ((value / total) * 100).round();
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                "$value ($percentage%)",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
