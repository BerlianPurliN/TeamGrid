import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:teamgrid/pages/Detail/project.dart';
import 'package:teamgrid/routes/app_rouutes.dart';

class ManageProjectsPage extends StatefulWidget {
  const ManageProjectsPage({super.key});

  @override
  State<ManageProjectsPage> createState() => _ManageProjectsPageState();
}

class _ManageProjectsPageState extends State<ManageProjectsPage> {
  final _projectNameController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _valueController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<String> _allStatuses = [
    'Pipeline',
    'On-going',
    'Maintenance',
    'Done',
  ];

  String _selectedPlatform = 'Web';

  DateTime? _startDate;
  DateTime? _deadline;

  String _selectedStatus = 'Pipeline';
  List<String> _selectedStatusFilters = [
    'Pipeline',
    'On-going',
    'Maintenance',
    'Done',
  ];

  String _selectedPaymentStatus = "Belum Lunas";
  int _totalTerminOption = 0;

  bool _isSearching = false;

  String _searchKeyword = "";

  String? userRole;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  void _getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (mounted) {
      setState(() => userRole = doc.data()?['role']);
    }
  }

  void _showAddProjectForm() {
    _selectedPaymentStatus = "Belum Lunas";
    _totalTerminOption = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          List<String> getDropdownItems() {
            List<String> items = ["Belum Lunas", "Lunas"];
            for (int i = 1; i <= _totalTerminOption; i++) {
              items.add("Termin $i");
            }
            return items;
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
                children: [
                  const Text(
                    "Tambah Proyek Baru",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _projectNameController,
                    decoration: const InputDecoration(labelText: "Nama Proyek"),
                  ),

                  TextField(
                    controller: _clientNameController,
                    decoration: const InputDecoration(labelText: "Nama Client"),
                  ),

                  DropdownButtonFormField<String>(
                    value: _selectedPlatform,
                    items: ['Web', 'App']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => _selectedPlatform = val!),
                    decoration: const InputDecoration(labelText: "Platform"),
                  ),

                  const SizedBox(height: 20),

                  if (userRole == 'Admin' || userRole == 'PM') ...[
                    const Text(
                      "Data Finansial (Admin Only)",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    TextField(
                      controller: _valueController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: "Nilai Proyek",
                        prefixText: "Rp ",
                        hintText: "Contoh: 50000000",
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPaymentStatus,
                            decoration: const InputDecoration(
                              labelText: "Status Pembayaran Saat Ini",
                            ),
                            items: getDropdownItems().map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setModalState(
                                () => _selectedPaymentStatus = val!,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          "Opsi Termin:",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            if (_totalTerminOption > 0) {
                              setModalState(() {
                                _totalTerminOption--;
                                if (_selectedPaymentStatus ==
                                    "Termin ${_totalTerminOption + 1}") {
                                  _selectedPaymentStatus = "Belum Lunas";
                                }
                              });
                            }
                          },
                        ),
                        Text(
                          "$_totalTerminOption",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            setModalState(() {
                              _totalTerminOption++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],

                  ListTile(
                    title: Text(
                      _startDate == null
                          ? "Pilih Tanggal Mulai"
                          : "Mulai: ${DateFormat('dd MMM yyyy').format(_startDate!)}",
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null)
                        setModalState(() => _startDate = picked);
                    },
                  ),

                  ListTile(
                    title: Text(
                      _deadline == null
                          ? "Pilih Deadline"
                          : "Deadline: ${DateFormat('dd MMM yyyy').format(_deadline!)}",
                    ),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null)
                        setModalState(() => _deadline = picked);
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _saveProject,
                    child: const Text("Simpan Proyek"),
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

  void _saveProject() async {
    if (_projectNameController.text.trim().isEmpty ||
        _startDate == null ||
        _deadline == null ||
        _clientNameController.text.trim().isEmpty ||
        ((userRole == 'Admin' || userRole == 'PM') &&
            _valueController.text.trim().isEmpty)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Field Tidak Lengkap"),
            content: const Text("Mohon lengkapi semua field yang diperlukan."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );

      return;
    }

    if (_startDate!.isAfter(_deadline!)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Tanggal Tidak Valid"),
            content: const Text("Tanggal mulai tidak boleh setelah deadline."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    await FirebaseFirestore.instance.collection('projects').add({
      'project_name': _projectNameController.text,
      'client_name': _clientNameController.text,
      'platform': _selectedPlatform,
      'status': 'Pipeline',
      'start_date': _startDate,
      'deadline': _deadline,
      'project_value': userRole == 'Admin' || userRole == 'PM'
          ? int.tryParse(_valueController.text) ?? 0
          : 0,
      'payment_status': userRole == 'Admin' || userRole == 'PM'
          ? _selectedPaymentStatus
          : "Belum Lunas",
      'total_termin_options': userRole == 'Admin' || userRole == 'PM'
          ? _totalTerminOption
          : 0,
      'created_at': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
    _projectNameController.clear();
    _clientNameController.clear();
    _valueController.clear();
    _startDate = null;
    _deadline = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Proyek berhasil ditambahkan.")),
    );
  }

  void _deleteProject(String projectId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Proyek?"),
        content: const Text(
          "PERINGATAN: Semua data tim dan alokasi resource di proyek ini juga akan dihapus permanen.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                WriteBatch batch = FirebaseFirestore.instance.batch();

                var subCollectionSnapshot = await FirebaseFirestore.instance
                    .collection('projects')
                    .doc(projectId)
                    .collection('team_members')
                    .get();

                for (var doc in subCollectionSnapshot.docs) {
                  batch.delete(doc.reference);
                }

                var projectRef = FirebaseFirestore.instance
                    .collection('projects')
                    .doc(projectId);
                batch.delete(projectRef);

                await batch.commit();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Proyek dan Data Tim berhasil dibersihkan.",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal menghapus: $e")),
                  );
                }
              }
            },
            child: const Text("Hapus Permanen"),
          ),
        ],
      ),
    );
  }

  void _showEditProjectForm(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String projectId = doc.id;

    _projectNameController.text = data['project_name'] ?? '';
    _clientNameController.text = data['client_name'] ?? '';
    _valueController.text = (data['project_value'] ?? 0).toString();
    _selectedPlatform = data['platform'] ?? 'Web';
    _selectedPaymentStatus = data['payment_status'] ?? 'Belum Lunas';
    _totalTerminOption = data['total_termin_options'] ?? 0;
    _startDate = (data['start_date'] as Timestamp).toDate();
    _deadline = (data['deadline'] as Timestamp).toDate();
    _selectedStatus = data['status'] ?? 'Pipeline';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          List<String> getDropdownItems() {
            List<String> items = ["Belum Lunas", "Lunas"];
            for (int i = 1; i <= _totalTerminOption; i++) {
              items.add("Termin $i");
            }
            return items;
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
                children: [
                  const Text(
                    "Edit Proyek",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _projectNameController,
                    decoration: const InputDecoration(labelText: "Nama Proyek"),
                  ),
                  TextField(
                    controller: _clientNameController,
                    decoration: const InputDecoration(labelText: "Nama Client"),
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    controller: _valueController,
                    decoration: const InputDecoration(
                      labelText: "Nilai Proyek",
                    ),
                  ),

                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    items: ['Pipeline', 'On-going', 'Maintenance', 'Done']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => _selectedStatus = val!),
                    decoration: const InputDecoration(
                      labelText: "Status Proyek",
                    ),
                  ),

                  if (userRole == 'Admin' || userRole == 'PM') ...[
                    const Divider(),
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentStatus,
                      items: getDropdownItems()
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setModalState(() => _selectedPaymentStatus = val!),
                      decoration: const InputDecoration(
                        labelText: "Status Pembayaran",
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _updateProject(projectId),
                    child: const Text("Simpan Perubahan"),
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

  void _updateProject(String projectId) async {
    if (_startDate!.isAfter(_deadline!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Cek kembali tanggal!")),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .update({
          'project_name': _projectNameController.text,
          'client_name': _clientNameController.text,
          'platform': _selectedPlatform,
          'status': _selectedStatus,
          'start_date': _startDate,
          'deadline': _deadline,
          'project_value': userRole == 'Admin'
              ? int.tryParse(_valueController.text) ?? 0
              : 0,
          'payment_status': userRole == 'Admin'
              ? _selectedPaymentStatus
              : "Belum Lunas",
          'total_termin_options': userRole == 'Admin' ? _totalTerminOption : 0,
        });

    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Proyek berhasil diperbarui")));
  }

  void _showFilterDialog() {
    List<String> tempSelected = List.from(_selectedStatusFilters);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text("Filter Status Proyek"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _allStatuses.map((status) {
                  return CheckboxListTile(
                    activeColor: Colors.lightBlue,
                    title: Text(status),
                    value: tempSelected.contains(status),
                    onChanged: (bool? checked) {
                      setDialogState(() {
                        if (checked == true) {
                          tempSelected.add(status);
                        } else {
                          tempSelected.remove(status);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _selectedStatusFilters = tempSelected;
                  });
                  Navigator.pop(context);
                },
                child: const Text("Terapkan"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.black),
                cursorColor: Colors.black,
                decoration: const InputDecoration(
                  hintText: "Cari nama proyek...",
                  hintStyle: TextStyle(color: Colors.black),
                  contentPadding: EdgeInsets.all(30.0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchKeyword = value.toLowerCase();
                  });
                },
              )
            : const Text("Manajemen Proyek"),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchKeyword = "";
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.filter_list),

                  if (_selectedStatusFilters.length < _allStatuses.length)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _showFilterDialog,
            ),
        ],
      ),

      body: _selectedStatusFilters.isEmpty
          ? const Center(
              child: Text(
                "Tidak ada filter status yang dipilih.\nSilakan pilih minimal satu.",
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .where('status', whereIn: _selectedStatusFilters)
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print("Error: ${snapshot.error}");
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<DocumentSnapshot> docs = snapshot.data!.docs;

                if (_searchKeyword.isNotEmpty) {
                  docs = docs.where((doc) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    String projectName = (data['project_name'] ?? '')
                        .toString()
                        .toLowerCase();
                    return projectName.contains(_searchKeyword);
                  }).toList();
                }
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_off,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _searchKeyword.isNotEmpty
                              ? "Proyek dengan kata kunci '$_searchKeyword' tidak ditemukan"
                              : "Belum ada data proyek",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_off,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Belum ada data proyek",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = docs[index];
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    String docId = doc.id;

                    String deadline = data['deadline'] != null
                        ? DateFormat(
                            'dd MMM yyyy',
                          ).format((data['deadline'] as Timestamp).toDate())
                        : '-';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 1,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: data['platform'] == 'Web'
                                  ? Colors.blue.shade50
                                  : Colors.green.shade50,
                              child: Icon(
                                data['platform'] == 'Web'
                                    ? Icons.language
                                    : Icons.phone_android,
                                color: data['platform'] == 'Web'
                                    ? Colors.blue
                                    : Colors.green,
                              ),
                            ),
                            title: Text(
                              data['project_name'] ?? 'Tanpa Nama',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text("Client: ${data['client_name']}"),
                                Text(
                                  "Deadline: $deadline",
                                  style: TextStyle(
                                    color: Colors.red[300],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),

                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                data['status'] ?? 'Pipeline',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const Divider(height: 0),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () {
                                  _deleteProject(docId);
                                },
                              ),
                              const SizedBox(width: 8),

                              TextButton.icon(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                label: const Text(
                                  "Edit",
                                  style: TextStyle(color: Colors.blue),
                                ),
                                onPressed: () => _showEditProjectForm(doc),
                              ),

                              const SizedBox(width: 8),

                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade50,
                                  foregroundColor: Colors.blue,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.visibility, size: 18),
                                label: const Text("Detail"),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.detailProject,
                                    arguments: ProjectDetailArgs(
                                      projectId: docId,
                                      projectData: data,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProjectForm,
        backgroundColor: Colors.lightBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
