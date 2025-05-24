import 'package:flutter/material.dart';
import 'package:adminrentalho/services/smoobu_api.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BookingsScreenState createState() => _BookingsScreenState();
}

// Estado de la pantalla de reservas que extiende de BookingsScreen
class _BookingsScreenState extends State<BookingsScreen> {
  // Instancia del servicio de API de Smoobu
  final _smoobuService = SmoobuApiService();
  // Banderas para controlar estados de carga y error
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  // Listas para almacenar todas las reservas y las filtradas
  List<dynamic> _bookings = [];
  List<dynamic> _filteredBookings = [];
  // Consulta de búsqueda actual
  String _searchQuery = "";

  @override
  // Se ejecuta cuando se inicializa el widget
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  // Se ejecuta cuando se destruye el widget
  void dispose() {
    super.dispose();
  }

  // Método asíncrono para cargar las reservas desde la API
  Future<void> _loadBookings() async {
    if (!mounted) return;
    
    try {
      // Actualiza el estado para mostrar la carga
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Obtiene las reservas del servicio
      final bookings = await _smoobuService.getAllBookings();

      if (!mounted) return;
      // Actualiza el estado con las reservas obtenidas
      setState(() {
        _bookings = bookings;
        _filteredBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Maneja los errores actualizando el estado
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Método para filtrar las reservas según la consulta de búsqueda
  void _filterBookings(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredBookings = _bookings.where((booking) {
        final guest = booking['guest-name']?.toLowerCase() ?? '';
        final property = booking['apartment']['name']?.toLowerCase() ?? '';
        final portal = booking['channel']['name']?.toLowerCase() ?? '';
        return guest.contains(_searchQuery) ||
            property.contains(_searchQuery) ||
            portal.contains(_searchQuery);
      }).toList();
    });
  }

  // Widget para mostrar errores
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_errorMessage'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBookings,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar el indicador de carga
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading all bookings...'),
        ],
      ),
    );
  }

  // Widget para construir la lista de reservas
  Widget _buildBookingsList() {
    if (_filteredBookings.isEmpty) {
      return const Center(child: Text('No bookings found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        itemCount: _filteredBookings.length,
        itemBuilder: (context, index) {
          final booking = _filteredBookings[index];
          // Construye una tarjeta para cada reserva
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              // ignore: deprecated_member_use
              border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información detallada de la reserva
                  Text(
                    'Guest: ${booking['guest-name'] ?? 'Unknown'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text('Arrival: ${booking['arrival'] ?? 'Unknown'}', style: const TextStyle(fontSize: 14)),
                  Text('Departure: ${booking['departure'] ?? 'Unknown'}', style: const TextStyle(fontSize: 14)),
                  Text('Property: ${booking['apartment']['name'] ?? 'Unknown'}', style: const TextStyle(fontSize: 14)),
                  Text('Portal: ${booking['channel']['name'] ?? 'Unknown'}', style: const TextStyle(fontSize: 14)),
                  Text('Created: ${booking['created-at'] ?? 'Unknown'}', style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  // Construye la interfaz principal de la pantalla
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search bookings',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: _filterBookings,
            ),
          ),
          // Contenido principal que muestra carga, error o lista de reservas
          Expanded(
            child: _isLoading
                ? _buildLoadingWidget()
                : _hasError
                    ? _buildErrorWidget()
                    : _buildBookingsList(),
          ),
        ],
      ),
    );
  }
}
