import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Guarda la información del usuario en la colección 'users'
  Future<void> saveUser(String uid, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(uid).set(userData);
  }

  // Obtiene la información de un usuario a partir de su uid
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // Verifica si ya existe un dueño
  Future<bool> existeOwner() async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'owner')
        .get();
    return querySnapshot.docs.isNotEmpty;
  }
}
