import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UtilizationReportPage extends StatefulWidget {
  const UtilizationReportPage({super.key});

  @override
  State<UtilizationReportPage> createState() => _UtilizationReportPageState();
}

class _UtilizationReportPageState extends State<UtilizationReportPage> {
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;

  Map<String, double> _roleUtilization = {};
  Map<String, int> _roleHeadcount = {};
  String _busiestTeam = "-";
  String _idlestTeam = "-";

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);

    try {
      DateTime startOfMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month,
        1,
      );
      DateTime endOfMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
        23,
        59,
        59,
      );

      var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('status', isEqualTo: 'Active')
          .where('role', isNotEqualTo: 'PM')
          .get();

      List<QueryDocumentSnapshot> employees = userSnapshot.docs.where((doc) {
        return (doc.data() as Map<String, dynamic>)['role'] != 'Admin';
      }).toList();

      var taskSnapshot = await FirebaseFirestore.instance
          .collectionGroup('team_members')
          .get();

      Map<String, List<int>> tempRoleLoads = {};
      for (var empDoc in employees) {
        var empData = empDoc.data() as Map<String, dynamic>;
        String empId = empDoc.id;
        String position = empData['position'] ?? 'Unassigned';

        int userTotalLoad = 0;

        var myTasks = taskSnapshot.docs
            .where((t) => t['employee_id'] == empId)
            .toList();

        for (var taskDoc in myTasks) {
          var task = taskDoc.data();
          if (task['start_date'] == null || task['end_date'] == null) continue;

          DateTime start = (task['start_date'] as Timestamp).toDate();
          DateTime end = (task['end_date'] as Timestamp).toDate();

          bool isActiveInMonth =
              start.isBefore(endOfMonth) && end.isAfter(startOfMonth);

          if (isActiveInMonth) {
            userTotalLoad += (task['workload'] ?? 100) as int;
          }
        }

        if (!tempRoleLoads.containsKey(position)) {
          tempRoleLoads[position] = [];
        }
        tempRoleLoads[position]!.add(userTotalLoad);
      }

      Map<String, double> finalUtilization = {};
      Map<String, int> finalHeadcount = {};
      String maxTeam = "-";
      double maxVal = -1;
      String minTeam = "-";
      double minVal = 9999;

      tempRoleLoads.forEach((role, loads) {
        double avg = loads.isEmpty
            ? 0
            : loads.reduce((a, b) => a + b) / loads.length;
        finalUtilization[role] = avg;
        finalHeadcount[role] = loads.length;

        if (avg > maxVal) {
          maxVal = avg;
          maxTeam = role;
        }
        if (avg < minVal) {
          minVal = avg;
          minTeam = role;
        }
      });

      setState(() {
        _roleUtilization = finalUtilization;
        _roleHeadcount = finalHeadcount;
        _busiestTeam = maxTeam == "-"
            ? "None"
            : "$maxTeam (${maxVal.toStringAsFixed(0)}%)";
        _idlestTeam = minTeam == "-"
            ? "None"
            : "$minTeam (${minVal.toStringAsFixed(0)}%)";
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Color _getStatusColor(double percentage) {
    if (percentage < 50) return Colors.green;
    if (percentage < 90) return Colors.blue;
    if (percentage <= 110) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Laporan Okupansi Tim"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: Text(DateFormat('MMMM yyyy').format(_selectedMonth)),
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                helpText: "Pilih Bulan Laporan",
              );
              if (picked != null) {
                setState(() {
                  _selectedMonth = picked;
                });
                _generateReport();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInsightCard(
                          "Paling Sibuk",
                          _busiestTeam,
                          Icons.local_fire_department,
                          Colors.red.shade50,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInsightCard(
                          "Paling Luang",
                          _idlestTeam,
                          Icons.pool,
                          Colors.green.shade50,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "Detail Utilitas per Divisi",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  if (_roleUtilization.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("Belum ada data tim."),
                      ),
                    )
                  else
                    ..._roleUtilization.entries.map((entry) {
                      String role = entry.key;
                      double percentage = entry.value;
                      int count = _roleHeadcount[role] ?? 0;
                      Color color = _getStatusColor(percentage);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      role,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "$count Orang",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "${percentage.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Visual Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey.shade200,
                                color: color,
                                minHeight: 12,
                              ),
                            ),

                            const SizedBox(height: 8),
                            Text(
                              _getRecommendation(percentage),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildInsightCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getRecommendation(double percentage) {
    if (percentage < 30)
      return "⚠️ Sangat sepi. Pertimbangkan cari proyek baru atau kurangi tim.";
    if (percentage < 70)
      return "✅ Aman. Kapasitas masih tersedia untuk proyek tambahan.";
    if (percentage <= 95) return "🔥 Produktif. Tim bekerja optimal.";
    return "🚨 OVERLOAD! Tahan penjualan atau rekrut anggota baru segera.";
  }
}
