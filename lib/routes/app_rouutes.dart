import 'package:flutter/material.dart';
import 'package:teamgrid/pages/Auth/login.dart';
import 'package:teamgrid/pages/Dashboard/admin.dart';
import 'package:teamgrid/pages/Dashboard/pm.dart';
import 'package:teamgrid/pages/Dashboard/employee.dart';
import 'package:teamgrid/pages/Detail/project.dart';
import 'package:teamgrid/pages/Manage/bench_list.dart';
import 'package:teamgrid/pages/Manage/employees.dart';
import 'package:teamgrid/pages/Manage/resources-employees.dart';
import 'package:teamgrid/pages/Manage/projects.dart';
import 'package:teamgrid/pages/Manage/resources-projects.dart';
import 'package:teamgrid/pages/Report/utilization.dart';

class AppRoutes {
  static const String login = '/login';
  static const String adminDashboard = '/adminDashboard';
  static const String pmDashboard = '/pmDashboard';
  static const String employeeDashboard = '/employeeDashboard';
  static const String manageEmployees = '/manage-employees';
  static const String manageProjects = '/manage-projects';
  static const String manageResourcesProjects = '/manage-resources-projects';
  static const String manageResourcesEmployees = '/manage-resources-employees';
  static const String detailProject = '/detail-project';
  static const String benchList = '/bench-list';
  static const String utilizationReport = '/utilization-report';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildRoute(const LoginPage());

      case adminDashboard:
        return _buildRoute(const AdminDashboard());

      case pmDashboard:
        return _buildRoute(const PmDashboardPage());

      case employeeDashboard:
        final args = settings.arguments as Map<String, dynamic>?;

        return _buildRoute(
          EmployeeDashboardPage(userName: args?['name'] ?? 'Employee'),
        );

      case manageEmployees:
        return _buildRoute(const ManageEmployeesPage());

      case manageResourcesEmployees:
        return _buildRoute(const ResourceMonitorEmployeesPage());

      case manageResourcesProjects:
        return _buildRoute(const ResourceMonitorProjectsPage());

      case manageProjects:
        return _buildRoute(const ManageProjectsPage());

      case benchList:
        return _buildRoute(const BenchListPage());

      case detailProject:
        final args = settings.arguments as ProjectDetailArgs;
        return _buildRoute(
          ProjectDetailPage(
            projectId: args.projectId,
            projectData: args.projectData,
          ),
        );

      case utilizationReport:
        return _buildRoute(const UtilizationReportPage());

      default:
        return _buildRoute(
          Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Halaman tidak ditemukan (404)')),
          ),
        );
    }
  }

  static Route<dynamic> _buildRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
