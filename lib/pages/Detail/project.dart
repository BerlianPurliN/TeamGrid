import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProjectDetailPage extends StatefulWidget {
  final Map<String, dynamic> projectData;
  final String projectId;

  const ProjectDetailPage({
    super.key,
    required this.projectData,
    required this.projectId,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  void _checkRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (mounted) {
        setState(() => userRole = doc.data()?['role']);
      }
    }
  }

  void _showAddMemberForm() {
    String? selectedEmployeeId;
    String selectedEmployeeName = '';
    String selectedEmployeeRole = '';

    final roleInProjectController = TextEditingController();
    final workloadController = TextEditingController(text: '100');

    DateTime? startDate = widget.projectData['start_date'] != null
        ? (widget.projectData['start_date'] as Timestamp).toDate()
        : DateTime.now();

    DateTime? endDate = widget.projectData['deadline'] != null
        ? (widget.projectData['deadline'] as Timestamp).toDate()
        : DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> _saveData(int workload) async {
            await FirebaseFirestore.instance
                .collection('projects')
                .doc(widget.projectId)
                .collection('team_members')
                .add({
                  'employee_id': selectedEmployeeId,
                  'name': selectedEmployeeName,
                  'project_name': widget.projectData['project_name'],
                  'original_position': selectedEmployeeRole,
                  'project_role': roleInProjectController.text,
                  'workload': workload,
                  'start_date': startDate,
                  'end_date': endDate,
                  'assigned_at': FieldValue.serverTimestamp(),
                });

            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Berhasil dialokasikan!")),
              );
            }
          }

          Future<void> validateAndSave() async {
            if (selectedEmployeeId == null ||
                roleInProjectController.text.isEmpty ||
                workloadController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Mohon lengkapi semua data")),
              );
              return;
            }

            int newWorkload = int.parse(workloadController.text);

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (c) => const Center(child: CircularProgressIndicator()),
            );

            try {
              var querySnapshot = await FirebaseFirestore.instance
                  .collectionGroup('team_members')
                  .where('employee_id', isEqualTo: selectedEmployeeId)
                  .get();

              int currentTotalLoad = 0;

              for (var doc in querySnapshot.docs) {
                var data = doc.data();

                if (data['end_date'] == null || data['start_date'] == null)
                  continue;

                DateTime existingStart = (data['start_date'] as Timestamp)
                    .toDate();
                DateTime existingEnd = (data['end_date'] as Timestamp).toDate();

                bool isOverlap =
                    startDate!.isBefore(
                      existingEnd.add(const Duration(days: 1)),
                    ) &&
                    endDate!.isAfter(
                      existingStart.subtract(const Duration(days: 1)),
                    );

                if (isOverlap) {
                  int load = data['workload'] ?? 100;
                  currentTotalLoad += load;
                }
              }

              Navigator.pop(context);

              int potentialTotalLoad = currentTotalLoad + newWorkload;

              if (potentialTotalLoad > 100) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text(
                      "Peringatan: Overload!",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      "$selectedEmployeeName saat ini memiliki beban $currentTotalLoad% di periode tanggal ini.\n\n"
                      "Jika ditambah $newWorkload%, total menjadi $potentialTotalLoad%.\n\n"
                      "Tetap lanjutkan?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _saveData(newWorkload);
                        },
                        child: const Text("Paksa Simpan"),
                      ),
                    ],
                  ),
                );
              } else {
                _saveData(newWorkload);
              }
            } catch (e) {
              print("Error checking workload: $e");
              Navigator.pop(context);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Alokasikan Tim",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // DROPDOWN PILIH KARYAWAN (Ambil dari Firestore)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('status', isEqualTo: 'Active')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const LinearProgressIndicator();

                      List<DropdownMenuItem<String>> items = [];
                      for (var doc in snapshot.data!.docs) {
                        var data = doc.data() as Map<String, dynamic>;

                        items.add(
                          DropdownMenuItem(
                            value: doc.id,
                            child: Text(
                              "${data['name']} (${data['position']})",
                            ),
                            onTap: () {
                              selectedEmployeeName = data['name'];
                              selectedEmployeeRole = data['position'];
                            },
                          ),
                        );
                      }

                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Pilih Karyawan",
                        ),
                        items: items,
                        onChanged: (val) {
                          setModalState(() => selectedEmployeeId = val);
                        },
                      );
                    },
                  ),

                  // ROLE PROJECT & WORKLOAD (Row)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: roleInProjectController,
                          decoration: const InputDecoration(
                            labelText: "Role di Proyek",
                            hintText: "Misal: Backend Lead",
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: workloadController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Beban (%)",
                            suffixText: "%",
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // TANGGAL MULAI & SELESAI
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            startDate == null
                                ? "Mulai"
                                : DateFormat('dd MMM').format(startDate!),
                          ),
                          onPressed: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null)
                              setModalState(() => startDate = picked);
                          },
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.grey,
                      ),
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.flag, color: Colors.red),
                          label: Text(
                            endDate == null
                                ? "Selesai"
                                : DateFormat('dd MMM').format(endDate!),
                          ),
                          onPressed: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null)
                              setModalState(() => endDate = picked);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: validateAndSave,
                      child: const Text("Simpan Alokasi"),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.projectData;
    final String status = data['status'] ?? 'Pipeline';

    final DateTime start = data['start_date'] != null
        ? (data['start_date'] as Timestamp).toDate()
        : DateTime.now();
    final DateTime end = data['deadline'] != null
        ? (data['deadline'] as Timestamp).toDate()
        : DateTime.now();

    final int value = data['project_value'] ?? 0;

    final String paymentStatus = data['payment_status'] ?? 'Belum Lunas';

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Detail Proyek"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          data['project_name'] ?? 'Tanpa Nama',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusChip(status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['client_name'] ?? 'Client Tidak Diketahui',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const Divider(height: 30),
                  Row(
                    children: [
                      _buildMiniInfo(
                        Icons.laptop_mac,
                        "Platform",
                        data['platform'] ?? '-',
                      ),
                      const SizedBox(width: 20),
                      _buildMiniInfo(
                        Icons.category,
                        "Start Date",
                        data['start_date'] != null
                            ? DateFormat('dd MMM yyy').format(start)
                            : '-',
                      ),
                      const SizedBox(width: 20),
                      _buildMiniInfo(
                        Icons.calendar_month,
                        "Deadline",
                        DateFormat('dd MMM yyy').format(end),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (userRole == 'Admin') ...[
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  "Informasi Finansial",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Nilai Proyek",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        currencyFormatter.format(value),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Status Pembayaran",
                          style: TextStyle(color: Colors.white70),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            paymentStatus, // Menampilkan status termin terbaru
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    "Tim Terlibat",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (userRole == 'Admin' || userRole == 'PM')
                  TextButton.icon(
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text("Add Member"),
                    onPressed: _showAddMemberForm,
                  ),
              ],
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .doc(widget.projectId)
                  .collection('team_members')
                  .orderBy('assigned_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                if (snapshot.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.group_off_outlined,
                          size: 40,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Belum ada tim yang dialokasikan",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var member =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    String memberDocId = snapshot.data!.docs[index].id;

                    DateTime? end = member['end_date'] != null
                        ? (member['end_date'] as Timestamp).toDate()
                        : null;
                    bool isExpired =
                        end != null && end.isBefore(DateTime.now());

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            member['name'][0],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        title: Text(
                          member['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${member['project_role']} (Asli: ${member['original_position']})",
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.speed,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Load: ${member['workload'] ?? 100}%",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: (member['workload'] ?? 100) > 100
                                        ? Colors.red
                                        : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            if (end != null)
                              Text(
                                "Sampai: ${DateFormat('dd MMM yyyy').format(end)}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isExpired ? Colors.red : Colors.green,
                                ),
                              ),
                          ],
                        ),
                        trailing: (userRole == 'Admin' || userRole == 'PM')
                            ? IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('projects')
                                      .doc(widget.projectId)
                                      .collection('team_members')
                                      .doc(memberDocId)
                                      .delete();
                                },
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color text;
    switch (status) {
      case 'On-going':
        bg = Colors.blue.shade50;
        text = Colors.blue;
        break;
      case 'Done':
        bg = Colors.green.shade50;
        text = Colors.green;
        break;
      case 'Maintenance':
        bg = Colors.orange.shade50;
        text = Colors.orange;
        break;
      default:
        bg = Colors.grey.shade100;
        text = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ProjectDetailArgs {
  final String projectId;
  final Map<String, dynamic> projectData;

  ProjectDetailArgs({required this.projectId, required this.projectData});
}
