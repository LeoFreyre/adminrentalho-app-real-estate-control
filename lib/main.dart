import 'package:flutter/material.dart'; // Importa el paquete de Flutter
import 'package:firebase_core/firebase_core.dart'; // Importa Firebase
import 'firebase_options.dart'; // Importa las opciones de Firebase
import 'package:adminrentalho/Screens/owner/tasks_screen.dart'; // Pantalla de tareas (owner)
import 'package:adminrentalho/Screens/owner/bookings_screen.dart'; // Pantalla de reservas (owner)
import 'package:adminrentalho/Screens/owner/employees_screen.dart'; // Pantalla de empleados y grupos (owner)
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importa el paquete dotenv
import 'package:adminrentalho/config/theme.dart'; // Tema global
import 'package:adminrentalho/Screens/auth/profile_screen.dart'; // Pantalla del perfil de cada usuario
import 'package:adminrentalho/Screens/auth/login_screen.dart'; // Pantalla de Login
import 'package:adminrentalho/Screens/auth/register_screen.dart'; // Pantalla de Registro
import 'package:adminrentalho/Screens/worker/worker_screen.dart'; // Pantalla para empleados
import 'package:adminrentalho/Screens/auth/splash_screen.dart'; // Importa la SplashScreen
import 'package:adminrentalho/services/notifications_service.dart'; // Importa el servicio de notificaciones

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga el archivo .env
  await dotenv.load(fileName: '.env');

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar el servicio de notificaciones
  await NotificationService().init();

  // Programar la notificación diaria
  await NotificationService().scheduleDailyNotification();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Tema global definido
      initialRoute: '/', // Cambiado a ruta raíz para la SplashScreen
      routes: {
        '/': (context) => const SplashScreen(), // Ruta inicial para SplashScreen
        'adminrentalho/lib/Screens/auth/login_screen.dart': (context) =>
            const LoginScreen(), // Ruta del Login
        'adminrentalho/lib/Screens/auth/register_screen.dart': (context) =>
            const RegisterScreen(), // Ruta del Registro
        'adminrentalho/Screens/owner/tasks_screen.dart': (context) =>
            const OwnerHomeScreen(), // Ruta del dueño
        'adminrentalho/Screens/worker/worker_screen.dart': (context) =>
            const WorkerScreen(), // Ruta de empleados
      },
    );
  }
}

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  int _currentIndex = 0; // Índice actual de la pantalla seleccionada

  // Lista de pantallas para el propietario
  final List<Widget> _screens = [
    TasksScreen(),
    BookingsScreen(),
    EmployeesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Panel'), // Titulo del Appbar
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(
                Icons.person,
                size: 27.0,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex], // Muestra la pantalla correspondiente al índice actual
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Índice seleccionado
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Cambia de pantalla al seleccionar un ítem
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.task), // Ícono para Tareas
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.holiday_village), // Ícono para Reservas
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group), // Ícono para Empleados
            label: 'Employees',
          ),
        ],
      ),
    );
  }
}