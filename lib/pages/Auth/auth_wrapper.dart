import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teamgrid/routes/app_rouutes.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          String role = snapshot.data!.get('role');

          if (role == 'Admin') {
            _navigate(context, AppRoutes.adminDashboard);
          } else if (role == 'PM') {
            _navigate(context, AppRoutes.pmDashboard);
          } else {
            _navigate(context, AppRoutes.employeeDashboard);
          }
        }

        return const Scaffold(body: Center(child: Text("User data not found")));
      },
    );
  }

  void _navigate(BuildContext context, String route) {
    Future.delayed(Duration.zero, () {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, route);
      }
    });
  }
}
