import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamgrid/pages/Auth/auth_service.dart';
import 'package:teamgrid/routes/app_rouutes.dart';

class EmployeeDashboardPage extends StatefulWidget {
  const EmployeeDashboardPage({super.key});

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  String userName = 'Employee';

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    if (_currentUserId.isEmpty) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists && mounted) {
        var data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userName = data['name'] ?? 'Employee';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => userName = "Error Loading Name");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Workspace Saya",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Text(
              "Hi, $userName Sekarang ${DateFormat.yMMMMd().format(DateTime.now())}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('team_members')
                  .where('employee_id', isEqualTo: _currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                var myTasks = snapshot.data!.docs;

                int activeProjects = myTasks.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  DateTime? end = (data['end_date'] as Timestamp?)?.toDate();
                  return end != null && end.isAfter(DateTime.now());
                }).length;

                int totalLoad = 0;
                for (var doc in myTasks) {
                  totalLoad += (doc['workload'] ?? 0) as int;
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        "Proyek Aktif",
                        "$activeProjects",
                        Icons.folder_open,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        "Total Load",
                        "$totalLoad%",
                        totalLoad > 100 ? Icons.warning : Icons.speed,
                        totalLoad > 100 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 25),
            const Text(
              "Tugas & Proyek Anda",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('team_members')
                  .where('employee_id', isEqualTo: _currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                var tasks = snapshot.data!.docs;
                tasks.sort((a, b) {
                  DateTime d1 = (a['end_date'] as Timestamp).toDate();
                  DateTime d2 = (b['end_date'] as Timestamp).toDate();
                  return d1.compareTo(d2);
                });

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var doc = tasks[index];
                    var data = doc.data() as Map<String, dynamic>;

                    String projectName =
                        data['project_name'] ?? 'Unnamed Project';
                    String role = data['project_role'] ?? 'Member';
                    int workload = data['workload'] ?? 0;

                    DateTime startDate = (data['start_date'] as Timestamp)
                        .toDate();
                    DateTime endDate = (data['end_date'] as Timestamp).toDate();

                    String status = "Upcoming";
                    Color statusColor = Colors.grey;
                    DateTime now = DateTime.now();

                    if (now.isAfter(startDate) && now.isBefore(endDate)) {
                      status = "In Progress";
                      statusColor = Colors.blue;
                    } else if (now.isAfter(endDate)) {
                      status = "Overdue";
                      statusColor = Colors.red;
                    }

                    int daysLeft = endDate.difference(now).inDays;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border(
                          left: BorderSide(color: statusColor, width: 4),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                if (daysLeft >= 0 && daysLeft < 5)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$daysLeft Hari Lagi",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              projectName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Role: $role",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Beban Kerja",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            "$workload%",
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: workload / 100,
                                          minHeight: 6,
                                          backgroundColor: Colors.grey.shade100,
                                          color: workload > 100
                                              ? Colors.red
                                              : Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Fitur Laporan Harian (Segera Hadir)",
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Lapor"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(color: Colors.grey.shade100),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${DateFormat('d MMM').format(startDate)} - ${DateFormat('d MMM yyyy').format(endDate)}",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.coffee, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              "Luar biasa! Tidak ada tugas aktif.",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
