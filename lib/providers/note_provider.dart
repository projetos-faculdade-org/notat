import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_again/resources/auth_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notesProvider = StreamProvider(((ref) => FirebaseFirestore.instance
    .collection(AuthService().useUid)
    .orderBy('date', descending: true)
    // Avisa tambem quando so muda o estado de sincronizacao, para o card
    // deixar de mostrar "pendente" assim que o servidor confirma a nota.
    .snapshots(includeMetadataChanges: true)));
