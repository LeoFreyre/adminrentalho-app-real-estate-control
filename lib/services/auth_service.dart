import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Registro de usuario con asignación de rol
  Future<User?> registerWithEmailAndPassword(
      String email, String password, String name, String? id) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        // Actualizamos el nombre en el perfil del usuario
        await user.updateDisplayName(name);

        // Determinar rol
        String role = 'employee';
        if (id != null && id.isNotEmpty) {
          // Se pretende registrar como dueño; primero verifica que no exista ya un dueño
          bool ownerExists = await _firestoreService.existeOwner();
          if (ownerExists) {
            // Se comunica que ya existe un dueño registrado
            throw Exception('There is already a registered owner.');
          }
          role = 'owner';
        }

        // Guarda la información del usuario en Firestore
        await _firestoreService.saveUser(user.uid, {
          'name': name,
          'email': email,
          'role': role,
        });
      }
      return user;
    } catch (e) {
      throw e.toString();
    }
  }

  // Inicio de sesión
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw e.toString();
    }
  }

  // Stream de cambios en la autenticación
  Stream<User?> get userChanges => _auth.authStateChanges();

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;
}
