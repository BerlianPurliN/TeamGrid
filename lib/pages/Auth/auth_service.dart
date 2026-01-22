import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> loginUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        DocumentSnapshot doc = await _db
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          return doc.get('role');
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> registerUserByAdmin({
    required String email,
    required String password,
    required String name,
    required String role,
    required String position,
    required String level,
    List<String> skills = const [],
  }) async {
    String appName = "temp_app_${DateTime.now().millisecondsSinceEpoch}";

    FirebaseApp tempApp = await Firebase.initializeApp(
      name: appName,
      options: Firebase.app().options,
    );

    try {
      UserCredential result = await FirebaseAuth.instanceFor(
        app: tempApp,
      ).createUserWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        await _db.collection('users').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'name': name,
          'email': email,
          'role': role,
          'position': position,
          'level': level,
          'skills': skills,
          'status': 'Active',
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    } finally {
      await tempApp.delete();
    }
  }

  Future<void> updateEmployee(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEmployee(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      rethrow;
    }
  }
}
