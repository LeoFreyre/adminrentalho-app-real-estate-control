import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:adminrentalho/services/smoobu_api.dart';
import 'package:adminrentalho/Screens/stock/available_stock_screen.dart';

// Esta es la pantalla de perfil que muestra la información del usuario y sus grupos
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Future para obtener los datos del usuario desde Firestore
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userDataFuture;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Inicializa la obtención de datos del usuario actual
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _userDataFuture =
          FirebaseFirestore.instance.collection('users').doc(uid).get();
    }
  }

  // Obtiene las estadísticas diarias de reservas
  Future<Map<String, dynamic>> _getDailyStatistics() async {
    final List<dynamic> bookings = await SmoobuApiService().getAllBookings();
    final DateTime today = DateTime.now();
    final DateTime todayStart = DateTime(today.year, today.month, today.day);

    int checkIns = 0;
    int checkOuts = 0;
    int activeReservations = 0;

    // Recorre todas las reservas para contar check-ins, check-outs y reservas activas
    for (var booking in bookings) {
      try {
        // Ignorar las reservas bloqueadas
        if (booking['is-blocked-booking'] == true) {
          continue;
        }

        final DateTime arrival = DateTime.parse(booking['arrival']);
        final DateTime departure = DateTime.parse(booking['departure']);

        // Asegurarse de que estamos comparando solo fechas sin tiempo
        final DateTime arrivalDate =
            DateTime(arrival.year, arrival.month, arrival.day);
        final DateTime departureDate =
            DateTime(departure.year, departure.month, departure.day);

        if (arrivalDate.isAtSameMomentAs(todayStart)) {
          checkIns++;
        }
        if (departureDate.isAtSameMomentAs(todayStart)) {
          checkOuts++;
        }
        if (arrivalDate.isBefore(todayStart) && departureDate.isAfter(todayStart)) {
          activeReservations++;
        }
      } catch (e) {
        continue;
      }
    }

    return {
      'activeReservations': activeReservations,
      'checkIns': checkIns,
      'checkOuts': checkOuts,
    };
  }

  // Construye el widget que muestra las estadísticas diarias
  Widget _buildDailyStatistics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getDailyStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('No statistics available.');
        }
        final stats = snapshot.data!;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            // ignore: deprecated_member_use
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              const Text(
                'Daily Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildStatItem(
                  'Total Active Reservations', stats['activeReservations']),
              const SizedBox(height: 12),
              _buildStatItem('Check-ins Today', stats['checkIns']),
              const SizedBox(height: 12),
              _buildStatItem('Check-outs Today', stats['checkOuts']),
            ],
          ),
        );
      },
    );
  }

  // Construye cada elemento de estadística individual
  Widget _buildStatItem(String label, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _getIconForStat(label),
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 15),
        ),
        Text(
          '$value',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Devuelve el icono apropiado para cada tipo de estadística
  IconData _getIconForStat(String label) {
    if (label.contains('Reservations')) return Icons.calendar_today;
    if (label.contains('Check-ins')) return Icons.login;
    if (label.contains('Check-outs')) return Icons.logout;
    return Icons.info;
  }

  // Obtiene los nombres de los miembros de un grupo desde Firestore
  Future<List<String>> _getMemberNames(List<dynamic> memberIds) async {
    List<String> memberNames = [];

    for (String memberId in memberIds.cast<String>()) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .get();
        if (userDoc.exists) {
          String name = userDoc.data()?['name'] ?? 'Unknown Member';
          memberNames.add(name);
        } else {
          memberNames.add('Unknown Member');
        }
      } catch (e) {
        memberNames.add('Unknown Member');
      }
    }

    return memberNames;
  }

  // Construye la sección que muestra los grupos de empleados
  Widget _buildEmployeeGroups(String userId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: userId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Column(
            children: [
              Text(
                'Groups You Belong To:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text('No work group assigned.'),
            ],
          );
        }

        final groups = snapshot.data!.docs;
        return Column(
          children: [
            Text(
              'Groups You Belong To:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...groups.map((group) {
              final Map<String, dynamic> groupData =
                  group.data() as Map<String, dynamic>;
              final List<dynamic> members = groupData['members'] ?? [];

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  // ignore: deprecated_member_use
                  border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      'Group: ${groupData['name']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Type: ${groupData['type']}',
                      style: const TextStyle(fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Group Members',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<String>>(
                      future: _getMemberNames(members),
                      builder: (context, memberSnapshot) {
                        if (memberSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        }

                        final memberNames = memberSnapshot.data ?? [];

                        if (memberNames.isEmpty) {
                          return const Text('No members found');
                        }

                        return Text(
                          memberNames.join(', '),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // Construye el avatar del perfil con la inicial del nombre
  Widget _buildProfileAvatar(String name) {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Theme.of(context).primaryColor,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Construye la sección de información del perfil
  Widget _buildProfileInfo(String name, String email, String role) {
    final String userId = _auth.currentUser?.uid ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(email, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
      
        // Botón para ver el stock disponible
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.black54),
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StockScreen()),
                );
              },
          child: const Text(
            'Available Stock',
            style: TextStyle(color: Colors.black54),
          ),
        ),
        const SizedBox(height: 12),
        // Botón de cierre de sesión
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: () {
            Navigator.pushReplacementNamed(context, 'adminrentalho/lib/Screens/auth/login_screen.dart');
          },
          child: const Text(
            'Log Out',
            style: TextStyle(color: Colors.red),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 24),
        // Muestra estadísticas diarias para propietarios o grupos para empleados
        role.toLowerCase() == 'owner'
            ? _buildDailyStatistics()
            : _buildEmployeeGroups(userId),
      ],
    );
  }

  // Construye la estructura principal de la pantalla
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User data not found.'));
          }
          final data = snapshot.data!.data()!;
          final String name = data['name'] as String? ?? 'No Name';
          final String email = data['email'] as String? ?? 'No Email';
          final String role = (data['role'] as String?)?.toLowerCase() ?? 'owner';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProfileAvatar(name),
                const SizedBox(height: 16),
                _buildProfileInfo(name, email, role),
              ],
            ),
          );
        },
      ),
    );
  }
}
