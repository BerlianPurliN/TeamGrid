import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String projectName;
  final String clientName;
  final String platform;
  final DateTime startDate;
  final DateTime deadline;
  final String status;
  final int projectValue;
  

  ProjectModel({
    required this.id,
    required this.projectName,
    required this.clientName,
    required this.platform,
    required this.startDate,
    required this.deadline,
    required this.status,
    this.projectValue = 0,
  });

  factory ProjectModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProjectModel(
      id: docId,
      projectName: map['project_name'] ?? '',
      clientName: map['client_name'] ?? '',
      platform: map['platform'] ?? 'Web',
      startDate: (map['start_date'] as Timestamp).toDate(),
      deadline: (map['deadline'] as Timestamp).toDate(),
      status: map['status'] ?? 'Pipeline',
      projectValue: map['project_value'] ?? 0,
    );
  }
}
