import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teamgrid/pages/Auth/auth_service.dart';
import 'package:teamgrid/routes/app_rouutes.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Admin Workspace",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            Text(
              "Hi, Admin! Today is ${DateFormat.yMMMMd().format(DateTime.now())}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Selamat Datang, Admin",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    context,
                    "Manajemen Karyawan",
                    Icons.people,
                    Colors.blue,
                    () =>
                        Navigator.pushNamed(context, AppRoutes.manageEmployees),
                  ),
                  _buildMenuCard(
                    context,
                    "Manajemen Proyek",
                    Icons.assignment,
                    Colors.green,
                    () =>
                        Navigator.pushNamed(context, AppRoutes.manageProjects),
                  ),
                  _buildMenuCard(
                    context,
                    "Alokasi Resource",
                    Icons.build,
                    Colors.orange,
                    () => Navigator.pushNamed(
                      context,
                      AppRoutes.manageResourcesEmployees,
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    "Laporan Utilitas",
                    Icons.bar_chart,
                    Colors.purple,
                    () => Navigator.pushNamed(
                      context,
                      AppRoutes.utilizationReport,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
