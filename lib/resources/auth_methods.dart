import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_again/models/deletion_result.dart';
import 'package:flutter_application_again/resources/firestore_methods.dart';
import 'package:flutter_application_again/resources/firstore_folder_methods.dart';
import 'package:flutter_application_again/resources/internet_connection.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get useUid => _auth.currentUser!.uid;

  Future<String> createUser(
      {required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await FirestoreFolderService().createMainFolder();
      return 'Account created successfully';
    } on FirebaseException catch (e) {
      return e.message!;
    }
  }

  Future<String?> loginUser(
      {required String email, required String password}) async {
    String? feedback;
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseException catch (e) {
      feedback = e.message;
    }
    return feedback;
  }

  Future<String?> restPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      return e.message!;
    }
    return null;
  }

  Future<String?> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
    return null;
  }

  /// Apaga tudo que pertence ao usuario: notas, pastas e a propria conta.
    Future<DeletionResult> deleteAccount() async {
    if (!await Connection.checkInternet()) {
      return const DeletionResult(error: 'sem conexão com a internet');
    }

    final firestore = FirestoreService();

    final result = await firestore.deleteAllUserData();
    if (!result.success) {
      return result;
    }

    try {
      await _auth.currentUser!.delete();
    } on FirebaseException catch (e) {
      return DeletionResult(
          deletedNotes: result.deletedNotes,
          error: e.message ?? 'erro ao apagar a conta');
    }
    return result;
  }

  Future<String?> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } on FirebaseException catch (e) {
      return e.message;
    }
    return null;
  }

  Future<String?> reauthentication(String password) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
          email: _auth.currentUser!.email!, password: password);
      await _auth.currentUser!.reauthenticateWithCredential(credential);
    } on FirebaseException catch (e) {
      return e.message;
    }
    return null;
  }

  bool get isVerified => _auth.currentUser!.emailVerified;
}
