import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Configurar la animación de fade
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_animationController);
    
    // Hacer que la animación se repita en ambas direcciones
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });
    
    // Iniciar la animación
    _animationController.forward();
    
    // Verificar usuario actual
    _checkCurrentUser();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkCurrentUser() async {
    // Pequeño retraso para permitir que la pantalla de splash se muestre
    await Future.delayed(const Duration(seconds: 2));

    final User? currentUser = _auth.currentUser;
    
    if (currentUser != null) {
      // El usuario ya está logueado, verificar su rol
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final role = data['role'] as String?;
          
          if (mounted) {
            if (role == 'owner') {
              Navigator.pushReplacementNamed(
                  context, 'adminrentalho/Screens/owner/tasks_screen.dart');
            } else if (role == 'employee') {
              Navigator.pushReplacementNamed(
                  context, 'adminrentalho/Screens/worker/worker_screen.dart');
            } else {
              // Usuario sin rol asignado, redirigir a login
              Navigator.pushReplacementNamed(
                  context, 'adminrentalho/lib/Screens/auth/login_screen.dart');
            }
          }
        } else {
          // Usuario existe en Auth pero no en Firestore
          if (mounted) {
            Navigator.pushReplacementNamed(
                context, 'adminrentalho/lib/Screens/auth/login_screen.dart');
          }
        }
      } catch (e) {
        // Error al obtener información del usuario
        if (mounted) {
          Navigator.pushReplacementNamed(
              context, 'adminrentalho/lib/Screens/auth/login_screen.dart');
        }
      }
    } else {
      // No hay usuario logueado, redirigir a login
      if (mounted) {
        Navigator.pushReplacementNamed(
            context, 'adminrentalho/lib/Screens/auth/login_screen.dart');
      }
    }
  }
  // Logo con fade aimation
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset(
            'assets/images/Imagotipo-principal.png',
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}