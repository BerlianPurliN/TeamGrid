import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BenchListPage extends StatefulWidget {
  const BenchListPage({super.key});

  @override
  State<BenchListPage> createState() => _BenchListPageState();
}

class _BenchListPageState extends State<BenchListPage> {
  String? _selectedRole;
  DateTimeRange? _selectedDateRange;

  bool _isLoading = false;
  List<Map<String, dynamic>> _benchList = [];

  final List<String> _roles = ['Backend', 'Frontend', 'UI/UX'];

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 30)),
    );
    _fetchBenchList();
  }

  Future<void> _fetchBenchList() async {
    setState(() => _isLoading = true);

    try {
      Query userQuery = FirebaseFirestore.instance
          .collection('users')
          .where('status', isEqualTo: 'Active')
          .where('role', isEqualTo: 'Employee');

      if (_selectedRole != null) {
        userQuery = userQuery.where('position', isEqualTo: _selectedRole);
      }

      var userSnapshot = await userQuery.get();

      var employees = userSnapshot.docs.where((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return data['role'] != 'Admin';
      }).toList();

      var taskSnapshot = await FirebaseFirestore.instance
          .collectionGroup('team_members')
          .get();

      List<Map<String, dynamic>> calculatedBench = [];

      for (var empDoc in employees) {
        var empData = empDoc.data() as Map<String, dynamic>;
        String empId = empDoc.id;

        var myTasks = taskSnapshot.docs
            .where((t) => t['employee_id'] == empId)
            .toList();

        int totalWorkloadInPeriod = 0;

        for (var taskDoc in myTasks) {
          var task = taskDoc.data();
          if (task['start_date'] == null || task['end_date'] == null) continue;

          DateTime taskStart = (task['start_date'] as Timestamp).toDate();
          DateTime taskEnd = (task['end_date'] as Timestamp).toDate();

          DateTime filterStart = _selectedDateRange!.start;
          DateTime filterEnd = _selectedDateRange!.end;

          bool isOverlap =
              taskStart.isBefore(filterEnd) && taskEnd.isAfter(filterStart);

          if (isOverlap) {
            totalWorkloadInPeriod += (task['workload'] ?? 100) as int;
          }
        }

        int availability = 100 - totalWorkloadInPeriod;

        if (availability > 0) {
          calculatedBench.add({
            'id': empId,
            'name': empData['name'],
            'position': empData['position'] ?? 'Staff',
            'availability': availability,
            'current_load': totalWorkloadInPeriod,
            'phone': empData['phone'] ?? '-',
            'email': empData['email'] ?? '-',
          });
        }
      }

      calculatedBench.sort(
        (a, b) => b['availability'].compareTo(a['availability']),
      );

      setState(() {
        _benchList = calculatedBench;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cari Talent (Bench)"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Filter Kebutuhan",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            hint: const Text("Semua Role"),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text("Semua Role"),
                              ),
                              ..._roles.map(
                                (r) =>
                                    DropdownMenuItem(value: r, child: Text(r)),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedRole = val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: () async {
                          DateTimeRange? picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                            initialDateRange: _selectedDateRange,
                          );
                          if (picked != null) {
                            setState(() => _selectedDateRange = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${DateFormat('d MMM').format(_selectedDateRange!.start)} - ${DateFormat('d MMM').format(_selectedDateRange!.end)}",
                                style: const TextStyle(fontSize: 13),
                              ),
                              const Icon(
                                Icons.calendar_month,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text("Cari yang Kosong"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _fetchBenchList,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _benchList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Tidak ada developer yang kosong\nuntuk periode & role ini.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _benchList.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      var talent = _benchList[index];
                      int availability = talent['availability'];
                      bool isFullFree = availability == 100;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFullFree
                                ? Colors.green.shade200
                                : Colors.orange.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade100,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: isFullFree
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              child: Icon(
                                Icons.person,
                                color: isFullFree
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    talent['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    talent['position'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: isFullFree
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isFullFree
                                            ? "Siap Deploy (100% Free)"
                                            : "Partial ($availability% Free)",
                                        style: TextStyle(
                                          color: isFullFree
                                              ? Colors.green[700]
                                              : Colors.orange[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade50,
                                foregroundColor: Colors.blue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Email ${talent['name']} disalin!",
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Kontak"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
