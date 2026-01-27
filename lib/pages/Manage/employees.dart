import 'package:flutter/material.dart';
import 'package:teamgrid/pages/Auth/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teamgrid/routes/app_rouutes.dart';

class ManageEmployeesPage extends StatefulWidget {
  const ManageEmployeesPage({super.key});

  static _ManageEmployeesPageState? of(BuildContext context) {
    return context.findAncestorStateOfType<_ManageEmployeesPageState>();
  }

  @override
  State<ManageEmployeesPage> createState() => _ManageEmployeesPageState();
}

class _ManageEmployeesPageState extends State<ManageEmployeesPage> {
  final _authService = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'Employee';

  String _selectedLevel = 'Junior';

  String _selectedPosition = 'Frontend';
  final List<String> _positionOptions = ['Frontend', 'Backend', 'UI/UX', 'PM'];

  final List<String> _availableSkills = [
    'Flutter',
    'Laravel',
    'React JS',
    'Vue JS',
    'Node JS',
    'Python',
    'Go',
    'Figma',
    'Adobe XD',
    'Docker',
    'AWS',
  ];

  List<String> _skills = [];
  bool _isSaving = false;

  void _showAddEmployeeForm() {
    _skills = [];
    String? currentSelectedSkill;
    _selectedPosition = 'Frontend';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void addSkillFromDropdown() {
            if (currentSelectedSkill != null) {
              if (!_skills.contains(currentSelectedSkill)) {
                setModalState(() {
                  _skills.add(currentSelectedSkill!);
                  currentSelectedSkill = null;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Skill ini sudah ditambahkan"),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            }
          }

          void removeSkillInModal(String skill) {
            setModalState(() {
              _skills.remove(skill);
            });
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
                    "Tambah Karyawan Baru",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Nama Lengkap",
                    ),
                  ),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                  ),

                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    items: ['PM', 'Employee']
                        .map(
                          (role) =>
                              DropdownMenuItem(value: role, child: Text(role)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => _selectedRole = val!),
                    decoration: const InputDecoration(labelText: "Role"),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField(
                          value: _selectedLevel,
                          items: ['Junior', 'Senior']
                              .map(
                                (lvl) => DropdownMenuItem(
                                  value: lvl,
                                  child: Text(lvl),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setModalState(
                            () => _selectedLevel = val.toString(),
                          ),
                          decoration: const InputDecoration(labelText: "Level"),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: DropdownButtonFormField(
                          value: _selectedPosition,
                          items: _positionOptions
                              .map(
                                (pos) => DropdownMenuItem(
                                  value: pos,
                                  child: Text(pos),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setModalState(
                            () => _selectedPosition = val.toString(),
                          ),
                          decoration: const InputDecoration(
                            labelText: "Posisi",
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Skill Tags (Pilih dari list)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: currentSelectedSkill,
                          hint: const Text("Pilih Skill..."),
                          items: _availableSkills
                              .map(
                                (skill) => DropdownMenuItem(
                                  value: skill,
                                  child: Text(skill),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setModalState(() => currentSelectedSkill = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: addSkillFromDropdown,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _skills.isEmpty
                      ? const Text(
                          "- Belum ada skill dipilih -",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        )
                      : Wrap(
                          spacing: 8.0,
                          children: _skills
                              .map(
                                (skill) => Chip(
                                  label: Text(skill),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () => removeSkillInModal(skill),
                                  backgroundColor: Colors.blue.shade50,
                                ),
                              )
                              .toList(),
                        ),

                  const SizedBox(height: 20),
                  _isSaving
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () => _saveEmployee(),
                          child: const Text("Simpan Karyawan"),
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

  void _saveEmployee() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedRole.isEmpty ||
        _selectedPosition.isEmpty ||
        _selectedLevel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Harap isi data wajib (Nama, Email, Password, Role, Posisi, Level)",
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _authService.registerUserByAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: _selectedRole,
        position: _selectedPosition,
        level: _selectedLevel,
        skills: _skills,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Karyawan Berhasil Didaftarkan"),
          backgroundColor: Colors.green,
        ),
      );

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _skills.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void deleteEmployee(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Karyawan?"),
        content: const Text(
          "Data akan hilang permanen. Jika karyawan resign, sebaiknya gunakan fitur Edit -> Ubah Status.",
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
              await _authService.deleteEmployee(uid);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.green,
                  content: Text("Data berhasil dihapus")),
              );
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  void showEditForm(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String uid = doc.id;

    _nameController.text = data['name'];
    _emailController.text = data['email'];
    _selectedPosition = data['position'];
    _selectedLevel = data['level'];
    _selectedRole = data['role'];

    _skills = List<String>.from(data['skills'] ?? []);

    String _selectedStatus = data['status'] ?? 'Active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
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
                    "Edit Data Karyawan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Nama Lengkap",
                    ),
                  ),

                  TextField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Email (Tidak bisa diubah)",
                      fillColor: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 10),
                  DropdownButtonFormField(
                    value: _selectedStatus,
                    items: ['Active', 'Cuti', 'Resign']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => _selectedStatus = val.toString()),
                    decoration: const InputDecoration(
                      labelText: "Status Karyawan",
                      filled: true,
                    ),
                  ),

                  DropdownButtonFormField(
                    value: _selectedPosition,
                    items: _positionOptions
                        .map(
                          (pos) =>
                              DropdownMenuItem(value: pos, child: Text(pos)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => _selectedPosition = val.toString()),
                    decoration: const InputDecoration(labelText: "Posisi"),
                  ),

                  DropdownButtonFormField(
                    value: _selectedLevel,
                    items: ['Junior', 'Senior']
                        .map(
                          (lvl) =>
                              DropdownMenuItem(value: lvl, child: Text(lvl)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => _selectedLevel = val.toString()),
                    decoration: const InputDecoration(labelText: "Level"),
                  ),

                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    items: ['PM', 'Employee']
                        .map(
                          (role) =>
                              DropdownMenuItem(value: role, child: Text(role)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => _selectedRole = val!),
                    decoration: const InputDecoration(labelText: "Role"),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Skill Tags (Pilih dari list)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: null,
                          hint: const Text("Pilih Skill..."),
                          items: _availableSkills
                              .map(
                                (skill) => DropdownMenuItem(
                                  value: skill,
                                  child: Text(skill),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null && !_skills.contains(val)) {
                              setModalState(() {
                                _skills.add(val);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _skills.isEmpty
                      ? const Text(
                          "- Belum ada skill dipilih -",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        )
                      : Wrap(
                          spacing: 8.0,
                          children: _skills
                              .map(
                                (skill) => Chip(
                                  label: Text(skill),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () {
                                    setModalState(() {
                                      _skills.remove(skill);
                                    });
                                  },
                                  backgroundColor: Colors.blue.shade50,
                                ),
                              )
                              .toList(),
                        ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // AKSI UPDATE
                        try {
                          await _authService.updateEmployee(uid, {
                            'name': _nameController.text,
                            'position': _selectedPosition,
                            'level': _selectedLevel,
                            'role': _selectedRole,
                            'status': _selectedStatus,
                            'skills': _skills,
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Data berhasil diupdate"),
                            ),
                          );
                        } catch (e) {
                          print(e);
                        }
                      },
                      child: const Text("Update Perubahan"),
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Manajemen Karyawan"),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                icon: Icon(color: Colors.lightBlue, Icons.manage_accounts),
                text: "Project Managers",
              ),
              Tab(
                icon: Icon(color: Colors.lightBlue, Icons.people),
                text: "Employees",
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EmployeeListStream(roleFilter: 'PM'),

            EmployeeListStream(roleFilter: 'Employee'),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FloatingActionButton(
              onPressed: _showAddEmployeeForm,
              backgroundColor: Colors.lightBlue,
              child: const Icon(Icons.add, color: Colors.white),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.benchList),
              label: const Text("Who Is Free Now?"),
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
              extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class EmployeeListStream extends StatelessWidget {
  final String roleFilter;

  const EmployeeListStream({super.key, required this.roleFilter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: roleFilter)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("Error terdeteksi: ${snapshot.error}");
          return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text("Belum ada data ${roleFilter}"),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final String uid = doc.id;
            final String name = data['name'] ?? 'Tanpa Nama';
            final String position = data['position'] ?? '-';
            final String level = data['level'] ?? '-';
            final String status = data['status'] ?? 'Active';
            final List<dynamic> skills = data['skills'] ?? [];

            return Card(
              color: Colors.white,
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$position ($level)",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                ManageEmployeesPage.of(
                                  context,
                                )?.showEditForm(doc);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                ManageEmployeesPage.of(
                                  context,
                                )?.deleteEmployee(uid);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'Active'
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: status == 'Active'
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            skills.join(", "),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
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
    );
  }
}
