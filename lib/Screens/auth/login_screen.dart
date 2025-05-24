import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _errorMessage; 

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _errorMessage = null;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid email and password.';
      });
      return;
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        // Query Firestore to get the user's information
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final role = data['role'] as String?;
          if (role == 'owner') {
            Navigator.pushReplacementNamed(
                // ignore: use_build_context_synchronously
                context, 'adminrentalho/Screens/owner/tasks_screen.dart');
          } else if (role == 'employee') {
            Navigator.pushReplacementNamed(
                // ignore: use_build_context_synchronously
                context, 'adminrentalho/Screens/worker/worker_screen.dart');
          } else {
            setState(() {
              _errorMessage = 'The user does not have an assigned role.';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'User information not found.';
          });
        }
      }
    } catch (e) {
      setState(() {
        if (e is FirebaseAuthException) {
          if (e.code == 'user-not-found') {
            _errorMessage = 'No user found with that email.';
          } else if (e.code == 'wrong-password') {
            _errorMessage = 'The password is incorrect.';
          } else {
            _errorMessage = 'An error occurred. Please try again.';
          }
        } else {
          _errorMessage = 'An error occurred. Please try again.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center( 
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/images/Imagotipo-principal.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Log In'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                        context, 'adminrentalho/lib/Screens/auth/register_screen.dart');
                  },
                  child: const Text('Don\'t have an account? Sign up here'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
