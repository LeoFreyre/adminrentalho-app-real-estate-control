import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SmoobuApiService {
  final String apiUrl = dotenv.env['SMOOBU_BASE_URL'] ?? '';
  final String apiKey = dotenv.env['API_KEY'] ?? '';
  
  Future<List<dynamic>> getAllBookings() async {
    List<dynamic> allBookings = [];
    int page = 1;
    bool hasMorePages = true;
    
    while (hasMorePages) {
      try {
        final response = await http.get(
          Uri.parse('$apiUrl?page=$page'),
          headers: {
            'Api-Key': apiKey,
            'Cache-Control': 'no-cache',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> pageBookings = data['bookings'];
          
          if (pageBookings.isEmpty) {
            hasMorePages = false;
          } else {
            allBookings.addAll(pageBookings);
            page++;
          }
        } else {
          throw Exception('Error loading reservations: ${response.statusCode}');
        }
      } catch (e) {
        hasMorePages = false;
      }
    }
    
    return allBookings;
  }

  // Método opcional para obtener reservas con parámetros específicos
  Future<List<dynamic>> getBookingsWithParams({
    int? limit,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = {
      if (limit != null) 'limit': limit.toString(),
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'page': '1',
    };

    final uri = Uri.parse(apiUrl).replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: {
        'Api-Key': apiKey,
        'Cache-Control': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['bookings'];
    } else {
      throw Exception('Error loading reservations: ${response.statusCode}');
    }
  }
}