import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:adminrentalho/services/smoobu_api.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:adminrentalho/services/cloudinary_service.dart';
import 'package:firebase_auth/firebase_auth.dart';


/// ===========================================================
/// Pantallas de Tareas (Owner)
/// ===========================================================

/// Clase modelo para la tarea de limpieza.
/// Utilizada para gestionar las tareas en la pestaña Cleaning & Housekeeping
class CleaningTask {
  final String propertyName;
  final DateTime checkoutDate;
  CleaningTask({required this.propertyName, required this.checkoutDate});
  static CleaningTask? fromBooking(dynamic booking) {
    if (booking['is-blocked-booking'] == true) return null;
    final departureDate =
        booking['departure'].toString().split(' ')[0];
    return CleaningTask(
      propertyName: booking['apartment']['name'] ?? 'Unknown Property',
      checkoutDate: DateTime.parse(departureDate),
    );
  }
}

// =============================================================
// CLASES EXTERNAS Y GLOBALES (_TasksScreenState)
// =============================================================

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<StatefulWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<dynamic>> _bookingsFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _tasksStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bookingsFuture = SmoobuApiService().getAllBookings();
    _tasksStream = _firestore.collection('tasks').snapshots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =============================================================
  // MÉTODOS COMUNES (UTILIDADES, FORMATEO Y OBTENCIÓN DE DATOS)
  // =============================================================

  // Formateo de fecha a formato dd-mm-yyyy
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  // Formateo de hora a formato 12h con AM/PM
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Conversión de string de hora a objeto TimeOfDay
  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(' ');
    if (parts.length == 2) {
      final hourMinute = parts[0].split(':');
      int hour = int.parse(hourMinute[0]);
      int minute = int.parse(hourMinute[1]);
      final period = parts[1];
      if (period.toUpperCase() == 'PM' && hour != 12) hour += 12;
      if (period.toUpperCase() == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 11, minute: 0);
  }

  // Obtener lista de empleados desde Firestore
  Future<List<Map<String, dynamic>>> _getEmployees() async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'employee')
        .get();
    return querySnapshot.docs.map((doc) => {
          'id': doc.id,
          'name': doc['name'],
          'type': 'employee',
        }).toList();
  }

  // Obtener lista de grupos desde Firestore
  Future<List<Map<String, dynamic>>> _getGroups() async {
    final querySnapshot = await _firestore.collection('groups').get();
    return querySnapshot.docs.map((doc) => {
          'id': doc.id,
          'name': doc['name'],
          'type': 'group',
        }).toList();
  }

  // Obtener lista combinada de empleados y grupos
  Future<List<Map<String, dynamic>>> _getAssignees() async {
    final employees = await _getEmployees();
    final groups = await _getGroups();
    return [...employees, ...groups];
  }

  // Obtener tarea existente y manejar casos especiales de grupos
  Future<Map<String, dynamic>?> _getExistingTask(CleaningTask task) async {
    final querySnapshot = await _firestore
        .collection('tasks')
        .where('propertyName', isEqualTo: task.propertyName)
        .where('checkoutDate', isEqualTo: task.checkoutDate)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      if (querySnapshot.docs.length == 1) {
        return querySnapshot.docs.first.data();
      } else {
        var docs = querySnapshot.docs;
        var firstData = docs.first.data();
        bool allSame = docs.every((doc) {
          var data = doc.data();
          return data['assigneeName'] == firstData['assigneeName'];
        });
        if (allSame) {
          List<Map<String, dynamic>> groups = await _getGroups();
          var matchingGroup = groups.firstWhere(
            (group) => group['name'] == firstData['assigneeName'],
            orElse: () => {},
          );
          if (matchingGroup.isNotEmpty) {
            firstData['assigneeId'] = matchingGroup['id'];
            firstData['assigneeType'] = 'group';
          } else {
            firstData['assigneeType'] = 'group';
          }
          return firstData;
        }
        return docs.first.data();
      }
    }
    return null;
  }

  // Asignar tarea a empleado o grupo
  Future<void> _assignTask(
    CleaningTask task,
    String assigneeId,
    String assigneeType,
    String message,
    String status,
    String time,
    String assigneeName,
  ) async {
    if (assigneeType == 'group') {
      final groupDoc =
          await _firestore.collection('groups').doc(assigneeId).get();
      if (groupDoc.exists) {
        final data = groupDoc.data();
        if (data != null && data.containsKey('members')) {
          final String taskId = _firestore.collection('tasks').doc().id;
          await _firestore.collection('tasks').doc(taskId).set({
            'taskId': taskId,
            'propertyName': task.propertyName,
            'checkoutDate': task.checkoutDate,
            'assigneeId': assigneeId,
            'assigneeType': 'group',
            'assigneeName': data['name'] ?? assigneeName,
            'groupMembers': data['members'],
            'message': message,
            'status': status,
            'time': time,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'taskType': 'cleaning',
          });
        } else {
          final String taskId = _firestore.collection('tasks').doc().id;
          await _firestore.collection('tasks').doc(taskId).set({
            'taskId': taskId,
            'propertyName': task.propertyName,
            'checkoutDate': task.checkoutDate,
            'assigneeId': assigneeId,
            'assigneeType': 'group',
            'assigneeName': data?['name'] ?? assigneeName,
            'message': message,
            'status': status,
            'time': time,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'taskType': 'cleaning',
          });
        }
      }
    } else {
      final existingTask = await _getExistingTask(task);
      if (existingTask != null) {
        await _firestore.collection('tasks').doc(existingTask['taskId']).update({
          'assigneeId': assigneeId,
          'assigneeType': assigneeType,
          'assigneeName': assigneeName,
          'message': message,
          'status': status,
          'time': time,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final String taskId = _firestore.collection('tasks').doc().id;
        await _firestore.collection('tasks').doc(taskId).set({
          'taskId': taskId,
          'propertyName': task.propertyName,
          'checkoutDate': task.checkoutDate,
          'assigneeId': assigneeId,
          'assigneeType': assigneeType,
          'assigneeName': assigneeName,
          'message': message,
          'status': status,
          'time': time,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'taskType': 'cleaning',
        });
      }
    }
  }

  // Widget para mostrar ícono de estado
  Widget _getStatusIcon(String? status) {
    Color bgColor;
    IconData iconData;
    Color iconColor;
    switch (status) {
      case null:
        // ignore: deprecated_member_use
        bgColor = Colors.amber.withOpacity(0.1);
        iconData = Icons.warning_amber_rounded;
        iconColor = Colors.amber;
        break;
      case 'pending':
        // ignore: deprecated_member_use
        bgColor = Colors.red.withOpacity(0.1);
        iconData = Icons.remove;
        iconColor = Colors.red;
        break;
      case 'in_progress':
        // ignore: deprecated_member_use
        bgColor = Colors.orange.withOpacity(0.1);
        iconData = Icons.more_horiz;
        iconColor = Colors.orange;
        break;
      case 'completed':
        // ignore: deprecated_member_use
        bgColor = Colors.green.withOpacity(0.1);
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      default:
        // ignore: deprecated_member_use
        bgColor = Colors.amber.withOpacity(0.1);
        iconData = Icons.warning_amber_rounded;
        iconColor = Colors.amber;
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 16),
    );
  }

  // Widget para mostrar chip de estado
  Widget _buildStatusChip(String label, bool isSelected, bool isInteractive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }



//-------------------------------------------------------------------//
  // COMIENZAN LAS 3 PESTAÑAS EN ESTE ORDEN:
  // 1-CLEANING & HOUSEKEEPING
  // 2-MAINTENANCE SERVICES
  // 3-DOCUMENT MANAGEMENT

  // ----------------------------------------------------------------
  // CLEANING & HOUSEKEEPING
  // ----------------------------------------------------------------

  Map<DateTime, List<CleaningTask>> _groupTasksByDate(
      List<CleaningTask> tasks) {
    final Map<DateTime, List<CleaningTask>> grouped = {};
    for (var task in tasks) {
      DateTime key = DateTime(
          task.checkoutDate.year, task.checkoutDate.month, task.checkoutDate.day);
      grouped.putIfAbsent(key, () => []).add(task);
    }
    return grouped;
  }

  Widget _buildDateHeaderWidget(DateTime date) {
    bool isToday = DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Expanded(
              child: Divider(color: Colors.grey, thickness: 1)),
          const SizedBox(width: 8),
          Text(isToday ? 'Today' : _formatDate(date),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          const Expanded(
              child: Divider(color: Colors.grey, thickness: 1)),
        ],
      ),
    );
  }

  // Construcción de la tarjeta de cada tarea.
  Widget _buildTaskCard(CleaningTask task) {
    // Cache para almacenar el último estado conocido de cada tarea
    final Map<String, Map<String, dynamic>> taskCache = {};

    return StreamBuilder<QuerySnapshot>(
      stream: _tasksStream,
      builder: (context, snapshot) {
        // Generar una clave única para cada tarea
        final String taskKey =
            '${task.propertyName}_${task.checkoutDate.toIso8601String()}';

        // Actualizar el caché solo cuando tenemos nuevos datos de Firebase
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final taskData = doc.data() as Map<String, dynamic>;
            if (taskData['propertyName'] == task.propertyName &&
                (taskData['checkoutDate'] is Timestamp &&
                    taskData['checkoutDate'].toDate().year ==
                        task.checkoutDate.year &&
                    taskData['checkoutDate'].toDate().month ==
                        task.checkoutDate.month &&
                    taskData['checkoutDate'].toDate().day ==
                        task.checkoutDate.day)) {
              // Usar datos en caché con valores nuevos
              taskCache[taskKey] = {
                'status': taskData['status'],
                'time': taskData['time'] ?? '11:00 AM',
              };
              break;
            }
          }
        }

        // Usar datos en caché o valores predeterminados
        final cachedData = taskCache[taskKey] ??
            {
              'status': null,
              'time': '11:00 AM',
            };

        return InkWell(
          onTap: () => _showCleaningTaskDetails(task),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  // ignore: deprecated_member_use
                  color: Colors.grey.withOpacity(0.3),
                  width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              // ignore: deprecated_member_use
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Task',
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          _getStatusIcon(cachedData['status']),
                        ],
                      ),
                      Text(
                          '${_formatDate(task.checkoutDate)} | ${cachedData['time']}',
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.house, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(task.propertyName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      Text('Tap to view...',
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildCleaningTab() {
    // Si la aplicación está en la web, mostrar este aviso
    if (kIsWeb) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red),
        ),
        child: const Text(
          'This feature is not available on the web version, please go to the app.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

    return FutureBuilder<List<dynamic>>(
      future: _bookingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final cleaningTasks = snapshot.data!
            .map((booking) => CleaningTask.fromBooking(booking))
            .whereType<CleaningTask>()
            .toList();
        final DateTime now = DateTime.now();
        final DateTime today = DateTime(now.year, now.month, now.day);
        final upcomingTasks = cleaningTasks
            .where((task) => !task.checkoutDate.isBefore(today))
            .toList();
        upcomingTasks.sort((a, b) => a.checkoutDate.compareTo(b.checkoutDate));
        final grouped = _groupTasksByDate(upcomingTasks);
        final sortedDates = grouped.keys.toList()
          ..sort((a, b) => a.compareTo(b));
        List<Widget> widgets = [];
        for (DateTime date in sortedDates) {
          widgets.add(_buildDateHeaderWidget(date));
          for (var task in grouped[date]!) {
            widgets.add(_buildTaskCard(task));
          }
        }
        return ListView(children: widgets);
      },
    );
  }


  /// ----------------------------------------------------------------
  /// DIÁLOGO: Detalles de tarea de Cleaning & Housekeeping.
  /// ----------------------------------------------------------------

// Verifica si una URL es de video
bool _isVideo(String url) {
  return url.toLowerCase().contains('.mp4') || 
         url.toLowerCase().contains('.mov') || 
         url.toLowerCase().contains('.avi') ||
         url.toLowerCase().contains('/video/') ||
         url.toLowerCase().contains('/video/upload/');
}

// Widget para mostrar imagen a pantalla completa
Widget _buildFullscreenImage(String url) {
  return InteractiveViewer(
    minScale: 0.5,
    maxScale: 4.0,
    child: Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 80)),
    ),
  );
}

// Widget para mostrar video a pantalla completa
Widget _buildFullscreenVideo(String url) {
  // ignore: deprecated_member_use
  final VideoPlayerController videoController = VideoPlayerController.network(url);

  return FutureBuilder(
    future: videoController.initialize(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        // Reproducir automáticamente el video al cargar
        videoController.play();
        
        return Stack(
          children: [
            // Contenedor que ocupa toda la pantalla
            Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: _buildVideoWithCorrectDimensions(videoController),
              ),
            ),
            
            // Banner inferior con efecto blur
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botón de reproducción/pausa
                        ValueListenableBuilder(
                          valueListenable: videoController,
                          builder: (context, value, child) {
                            return IconButton(
                              icon: Icon(
                                value.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              ),
                              onPressed: () {
                                if (value.isPlaying) {
                                  videoController.pause();
                                } else {
                                  videoController.play();
                                }
                                setState(() {});
                              },
                            );
                          },
                        ),
                        
                        // Botón de descarga
                        IconButton(
                          icon: const Icon(
                            Icons.download,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: () {
                            _launchUrlInBrowser(url, context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
    },
  );
}

// Widget para mostrar tanto imágenes como videos
Widget _buildMediaContent(String url) {
  bool isVideo = _isVideo(url);
  
  return GestureDetector(
    onDoubleTap: () {
      // Mostrar en pantalla completa con doble toque
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            backgroundColor: Colors.black,
            body: Center(
              child: isVideo 
                ? _buildFullscreenVideo(url) 
                : _buildFullscreenImage(url),
            ),
          ),
        ),
      );
    },
    child: Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: double.infinity,
            height: 180, // Altura fija para todos los medios
            child: isVideo
              ? Image.network(
                  // Miniatura del video desde Cloudinary con tamaño específico
                  url.replaceAll('/video/upload/', '/video/upload/c_fill,h_180,w_350/so_auto,pg_1/').replaceAll('.mp4', '.jpg'),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        color: Colors.black12, 
                        width: double.infinity,
                        height: 180,
                        child: const Center(child: Icon(Icons.movie, size: 40))
                      ),
                )
              : Image.network(
                  // Imagen con tamaño específico
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        color: Colors.black12,
                        width: double.infinity,
                        height: 180,
                        child: const Center(child: Icon(Icons.broken_image, size: 40))
                      ),
                ),
          ),
        ),
        
        // Muestra un icono de reproducción para videos
        if (isVideo)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
          ),
      ],
    ),
  );
}

Widget _buildReadOnlyCarousel(List<String> urls, int currentPage, Function(int) onPageChanged) {
  return Column(
    children: [
      SizedBox(
        height: 200,
        child: PageView.builder(
          onPageChanged: onPageChanged,
          itemCount: urls.length,
          itemBuilder: (context, index) {
            final url = urls[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildMediaContent(url),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      if (urls.length > 1)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(urls.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: currentPage == index ? 10 : 8,
              height: currentPage == index ? 10 : 8,
              decoration: BoxDecoration(
                color: currentPage == index ? Colors.blue : Colors.grey,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      const SizedBox(height: 8),
    ],
  );
}

  void _showCleaningTaskDetails(CleaningTask task) async {
    final existingTask = await _getExistingTask(task);
    String? selectedAssigneeId;
    String? selectedAssigneeType;
    String? selectedAssigneeName; // Se captura el nombre seleccionado
    String message = '';
    String status = 'pending';
    List<String> inProgressMediaUrls =
        existingTask != null && existingTask['inProgressMediaUrls'] != null
            ? List<String>.from(existingTask['inProgressMediaUrls'])
            : [];
    List<String> completedMediaUrls =
        existingTask != null && existingTask['completedMediaUrls'] != null
            ? List<String>.from(existingTask['completedMediaUrls'])
            : [];
    if (existingTask != null) {
      selectedAssigneeId = existingTask['assigneeId'];
      selectedAssigneeType = existingTask['assigneeType'];
      // Aquí se asigna el nombre que se almacenó en la tarea (ya sea empleado o grupo)
      selectedAssigneeName = existingTask['assigneeName'];
      message = existingTask['message'] ?? '';
      status = existingTask['status'] ?? 'pending';
    }
    String initialTime =
        existingTask != null && existingTask.containsKey('time')
            ? existingTask['time']
            : '11:00 AM';
    TimeOfDay selectedTime = _parseTime(initialTime);

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            contentPadding: EdgeInsets.zero,
            content: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 900, // Ancho máximo
                maxHeight: 700, // Altura máxima
              ),
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabecera: Nombre de la propiedad y fecha/hora editable.
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.propertyName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              Text('${_formatDate(task.checkoutDate)} | ',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500)),
                              GestureDetector(
                                onTap: () async {
                                  TimeOfDay? picked = await showTimePicker(
                                      context: context,
                                      initialTime: selectedTime);
                                  if (picked != null) {
                                    setState(() {
                                      selectedTime = picked;
                                    });
                                  }
                                },
                                child: Text(_formatTime(selectedTime),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.underline)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Contenido principal.
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Assign to:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            FutureBuilder<List<Map<String, dynamic>>>(
                                future: _getAssignees(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  }
                                  final assignees = snapshot.data!;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        hint: const Text(
                                            'Select employee or group'),
                                        value: selectedAssigneeId,
                                        items: assignees.map((assignee) {
                                          return DropdownMenuItem<String>(
                                            value: assignee['id'],
                                            onTap: () {
                                              selectedAssigneeType =
                                                  assignee['type'];
                                              selectedAssigneeName =
                                                  assignee['name'];
                                            },
                                            child: Row(
                                              children: [
                                                Icon(
                                                  assignee['type'] == 'employee'
                                                      ? Icons.person
                                                      : Icons.group,
                                                  size: 18,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(assignee['name']),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedAssigneeId = newValue;
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                }),
                            const SizedBox(height: 16),
                            const Text('Custom message:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            TextField(
                              maxLines: 3,
                              controller: TextEditingController(text: message),
                              decoration: InputDecoration(
                                hintText: 'Leave a message for the assignee...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                              onChanged: (value) {
                                message = value;
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text('Status:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            Center(
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 400),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        child: SizedBox(
                                          height: 36,
                                          child: LayoutBuilder(
                                              builder: (context, constraints) {
                                            return _buildStatusChip('Pending',
                                                status == 'pending', false);
                                          }),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        child: SizedBox(
                                          height: 36,
                                          child: LayoutBuilder(
                                              builder: (context, constraints) {
                                            return _buildStatusChip('Progress',
                                                status == 'in_progress', false);
                                          }),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        child: SizedBox(
                                          height: 36,
                                          child: LayoutBuilder(
                                              builder: (context, constraints) {
                                            return _buildStatusChip('Finished',
                                                status == 'completed', false);
                                          }),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            if (inProgressMediaUrls.isEmpty &&
                                completedMediaUrls.isEmpty)
                              const Text(
                                  'The employees did not attach multimedia.',
                                  style: TextStyle(fontSize: 16))
                            else ...[
                              if (inProgressMediaUrls.isNotEmpty) ...[
                                const Text('In Progress Multimedia:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  height: 230,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _buildReadOnlyCarousel(
                                      inProgressMediaUrls, 0, (index) {}),
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (completedMediaUrls.isNotEmpty) ...[
                                const Text('Completed Multimedia:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  height: 230,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _buildReadOnlyCarousel(
                                      completedMediaUrls, 0, (index) {}),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              existingTask == null
                  ? ElevatedButton.icon(
                      onPressed: (selectedAssigneeId == null ||
                              selectedAssigneeName == null)
                          ? null
                          : () async {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                    child: CircularProgressIndicator()),
                              );
                              try {
                                await _assignTask(
                                    task,
                                    selectedAssigneeId!,
                                    selectedAssigneeType!,
                                    message,
                                    status,
                                    _formatTime(selectedTime),
                                    selectedAssigneeName!);
                                // ignore: use_build_context_synchronously
                                Navigator.pop(
                                    // ignore: use_build_context_synchronously
                                    context); // Cierra indicador de carga.
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context); // Cierra diálogo.
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Task assigned successfully!'),
                                      backgroundColor: Colors.green),
                                );
                              } catch (error) {
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context);
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Error assigning task: $error'),
                                      backgroundColor: Colors.red),
                                );
                              }
                            },
                      icon: const Icon(Icons.check),
                      label: const Text('Assign Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );
                        try {
                          await _firestore
                              .collection('tasks')
                              .doc(existingTask['taskId'])
                              .update({
                            'time': _formatTime(selectedTime),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context); // Close loading
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context); // Close dialog
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task time updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (error) {
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context); // Close loading
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating task time: $error'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Done'),
                    ),
            ],
          );
        });
      },
    );
  }


// ----------------------------------------------------------------
// MAINTENANCE SERVICES
// ----------------------------------------------------------------

Widget _buildMaintenanceTab() {
  return Stack(
    children: [
      StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('tasksMaintenance')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No maintenance tasks'));
          }
          List<Map<String, dynamic>> tasks = snapshot.data!.docs.map((doc) {
            return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
          }).toList();
          // Agrupar tareas por fecha de creación
          Map<DateTime, List<Map<String, dynamic>>> grouped = {};
          for (var task in tasks) {
            DateTime createdAt =
                (task['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            DateTime key =
                DateTime(createdAt.year, createdAt.month, createdAt.day);
            grouped.putIfAbsent(key, () => []).add(task);
          }
          List<DateTime> sortedDates = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a));
          List<Widget> widgets = [];
          for (DateTime date in sortedDates) {
            widgets.add(_buildDateHeaderWidget(date));
            for (var task in grouped[date]!) {
              widgets.add(_buildMaintenanceTaskCard(task));
            }
          }
          return ListView(children: widgets);
        },
      ),
      Positioned(
        bottom: 16,
        right: 16,
        child: FloatingActionButton(
          onPressed: () => _showMaintenanceTaskDialog(),
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add),
        ),
      ),
    ],
  );
}

Widget _buildMaintenanceTaskCard(Map<String, dynamic> task) {
  String title = task['title'] ?? '';
  DateTime createdAt =
      (task['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
  String time = task['time'] ?? '11:00 AM';
  String status =
      task['status'] ?? 'pending assignment'; // 'pending assignment', 'pending' o 'completed'
  String assignedTo = task['assignedTo'] ?? '-';

  // Selección de ícono y color según estado
  IconData icon;
  Color iconColor;
  if (status == 'pending assignment') {
    icon = Icons.warning;
    iconColor = Colors.amber;
  } else if (status == 'pending') {
    icon = Icons.remove;
    iconColor = Colors.red;
  } else if (status == 'completed') {
    icon = Icons.check_circle;
    iconColor = Colors.green;
  } else {
    icon = Icons.remove;
    iconColor = Colors.red;
  }

  return InkWell(
    onTap: () {
      _showMaintenanceTaskDialog(task: task);
    },
    child: Container(
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
            // Fila superior: "To Do" + ícono, y fecha/hora
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'To Do',
                        style: TextStyle(
                          color: Colors.blue, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 16),
                    ),
                  ],
                ),
                Text(
                  '${_formatDate(createdAt)} | $time',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Fila inferior: título a la izquierda y "Assigned to" en la esquina inferior derecha
            Row(
                children: [
                const Icon(Icons.sticky_note_2, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Text(
                  'Assigned to: $assignedTo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------- Multimedia Functions ----------------------

List<String> _maintenanceMediaUrls = [];
int currentPageMaintenance = 0;

Future<void> _pickMaintenanceMedia() async {
  if (_maintenanceMediaUrls.length >= 5) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Maximum of 5 files reached')));
    return;
  }
  await showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _showMaintenanceCameraOptions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _showMaintenanceGalleryOptions();
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showMaintenanceCameraOptions() async {
  await showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
                if (pickedFile != null && _maintenanceMediaUrls.length < 5) {
                  File file = File(pickedFile.path);
                  setState(() {});
                  final cloudinaryService = CloudinaryService.fromEnv();
                  String? uploadedUrl = await cloudinaryService.uploadImage(file, 'maintenance_media');
                  if (uploadedUrl != null) {
                    setState(() {
                      _maintenanceMediaUrls.add(uploadedUrl);
                    });
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? pickedFile = await ImagePicker().pickVideo(source: ImageSource.camera);
                if (pickedFile != null && _maintenanceMediaUrls.length < 5) {
                  File file = File(pickedFile.path);
                  setState(() {});
                  final cloudinaryService = CloudinaryService.fromEnv();
                  String? uploadedUrl = await cloudinaryService.uploadVideo(file, 'maintenance_media');
                  if (uploadedUrl != null) {
                    setState(() {
                      _maintenanceMediaUrls.add(uploadedUrl);
                    });
                  }
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showMaintenanceGalleryOptions() async {
  await showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Select Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (pickedFile != null && _maintenanceMediaUrls.length < 5) {
                  File file = File(pickedFile.path);
                  setState(() {});
                  final cloudinaryService = CloudinaryService.fromEnv();
                  String? uploadedUrl = await cloudinaryService.uploadImage(file, 'maintenance_media');
                  if (uploadedUrl != null) {
                    setState(() {
                      _maintenanceMediaUrls.add(uploadedUrl);
                    });
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Select Video'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
                if (pickedFile != null && _maintenanceMediaUrls.length < 5) {
                  File file = File(pickedFile.path);
                  setState(() {});
                  final cloudinaryService = CloudinaryService.fromEnv();
                  String? uploadedUrl = await cloudinaryService.uploadVideo(file, 'maintenance_media');
                  if (uploadedUrl != null) {
                    setState(() {
                      _maintenanceMediaUrls.add(uploadedUrl);
                    });
                  }
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

bool _isMaintenanceMediaVideo(String url) {
  return url.toLowerCase().contains('.mp4') ||
         url.toLowerCase().contains('.mov') ||
         url.toLowerCase().contains('.avi') ||
         url.toLowerCase().contains('/video/') ||
         url.toLowerCase().contains('/video/upload/');
}

Widget _buildMaintenanceMediaContent(String url) {
  bool isVideo = _isMaintenanceMediaVideo(url);
  return GestureDetector(
    onDoubleTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            backgroundColor: Colors.black,
            body: Center(
              child: isVideo
                ? _buildMaintenanceFullscreenVideo(url)
                : _buildMaintenanceFullscreenImage(url),
            ),
          ),
        ),
      );
    },
    child: Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: double.infinity,
            height: 180,
            child: isVideo
              ? Image.network(
                  url.replaceAll('/video/upload/', '/video/upload/c_fill,h_180,w_350/so_auto,pg_1/').replaceAll('.mp4', '.jpg'),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                  errorBuilder: (context, error, stackTrace) =>
                    Container(
                      color: Colors.black12,
                      width: double.infinity,
                      height: 180,
                      child: const Center(child: Icon(Icons.movie, size: 40))
                    ),
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                  errorBuilder: (context, error, stackTrace) =>
                    Container(
                      color: Colors.black12,
                      width: double.infinity,
                      height: 180,
                      child: const Center(child: Icon(Icons.broken_image, size: 40))
                    ),
                ),
          ),
        ),
        if (isVideo)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
          ),
      ],
    ),
  );
}

Widget _buildMaintenanceFullscreenImage(String url) {
  return InteractiveViewer(
    minScale: 0.5,
    maxScale: 4.0,
    child: Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
        const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 80)),
    ),
  );
}

Widget _buildMaintenanceFullscreenVideo(String url) {
  // ignore: deprecated_member_use
  final VideoPlayerController videoController = VideoPlayerController.network(url);

  return FutureBuilder(
    future: videoController.initialize(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        // Reproducir automáticamente el video al cargar
        videoController.play();
        
        return Stack(
          children: [
            // Contenedor que ocupa toda la pantalla
            Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: _buildVideoWithCorrectDimensions(videoController),
              ),
            ),
            
            // Banner inferior con efecto blur
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botón de reproducción/pausa
                        ValueListenableBuilder(
                          valueListenable: videoController,
                          builder: (context, value, child) {
                            return IconButton(
                              icon: Icon(
                                value.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              ),
                              onPressed: () {
                                if (value.isPlaying) {
                                  videoController.pause();
                                } else {
                                  videoController.play();
                                }
                                setState(() {});
                              },
                            );
                          },
                        ),
                        
                        // Botón de descarga
                        IconButton(
                          icon: const Icon(
                            Icons.download,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: () {
                            _launchUrlInBrowser(url, context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
    },
  );
}

// Función para adaptar el video al tamaño de la pantalla manteniendo la relación de aspecto
Widget _buildVideoWithCorrectDimensions(VideoPlayerController controller) {
  return FittedBox(
    fit: BoxFit.contain,
    child: SizedBox(
      width: controller.value.size.width,
      height: controller.value.size.height,
      child: VideoPlayer(controller),
    ),
  );
}

// Función para abrir la URL en el navegador para descargar directamente usando la API de url_launcher
Future<void> _launchUrlInBrowser(String url, BuildContext context) async {
  try {
    // Mostrar mensaje para informar al usuario
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Downloading video"),
          content: const Text("Your browser will open to download the video. Press and hold the video and select (Save Video) or a similar option on your device."),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Crear un Uri desde la URL
                final Uri uri = Uri.parse(url);
                
                // Usar la API de url_launcher
                if (!await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication, // Abre en navegador externo
                )) {
                  throw Exception('Could not open URL: $url');
                }
              },
              child: const Text("Continue"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  } catch (e) {
    // Mostrar mensaje de error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error opening URL: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Widget _buildMaintenanceCarousel(List<String> urls, int currentPage, Function(int) onPageChanged) {
  return Column(
    children: [
      SizedBox(
        height: 200,
        child: PageView.builder(
          onPageChanged: onPageChanged,
          itemCount: urls.length,
          itemBuilder: (context, index) {
            final url = urls[index];
            return Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildMaintenanceMediaContent(url),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _maintenanceMediaUrls.removeAt(index)),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      if (urls.length > 1)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(urls.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: currentPage == index ? 10 : 8,
              height: currentPage == index ? 10 : 8,
              decoration: BoxDecoration(
                color: currentPage == index ? Colors.blue : Colors.grey,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      const SizedBox(height: 8),
    ],
  );
}

// Chip de estado para mantenimiento con onToggle (para uso en el popup)
Widget _buildMaintenanceStatusChip(String label, bool isSelected,
    bool isInteractive,
    {required Function(bool) onToggle}) {
  return GestureDetector(
    onTap: isInteractive ? () => onToggle(!isSelected) : null,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

// ---------------------- Popup Maintenance Task (OWNER / EMPLOYEE) ----------------------

void _showMaintenanceTaskDialog({Map<String, dynamic>? task}) {
  // Obtener el ID del usuario actual (empleado u otro)
  final currentUser = FirebaseAuth.instance.currentUser;
  final currentUserId = currentUser?.uid ?? '';
  final String currentUserRole = 'owner'; // O 'employee', según corresponda

  String title = task != null ? task['title'] ?? '' : '';
  String message = task != null ? task['message'] ?? '' : '';
  String? selectedAssigneeId = task != null ? task['assignedToId'] : null;
  String selectedAssigneeName = task != null ? task['assignedTo'] ?? '-' : '-';
  String status =
      task != null ? task['status'] ?? 'pending assignment' : 'pending assignment';
  String initialTime = task != null ? task['time'] ?? '11:00 AM' : '11:00 AM';

  // Variable para la fecha: se toma de createdAt o se usa la fecha actual.
  DateTime initialDate = task != null
      ? ((task['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now())
      : DateTime.now();
  DateTime selectedDate = initialDate;
  TimeOfDay selectedTime = _parseTime(initialTime);
  
  if (task != null && task['mediaUrls'] != null) {
    _maintenanceMediaUrls = List<String>.from(task['mediaUrls']);
  } else {
    _maintenanceMediaUrls = [];
  }

  // Se definen dos variables:
  // canEditAssignment: true si el usuario es owner (puede asignar la tarea).
  // canEditTaskDetails: true solo si el usuario actual es el empleado asignado (para multimedia y estado).
  bool canEditAssignment = (currentUserRole == 'owner');
  bool canEditTaskDetails =
      (selectedAssigneeId != null && selectedAssigneeId == currentUserId);

  Future<List<Map<String, dynamic>>> getEmployees() async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'employee')
        .get();
    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'],
            })
        .toList();
  }

  int currentPageMedia = 0;
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Texto edit task o new task a la izquierda
                        Expanded(
                        child: Text(
                          task != null ? 'Edit Task' : 'New Task',
                          style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          ),
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        ),
                      // Selector de fecha
                      GestureDetector(
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: Text(
                          _formatDate(selectedDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        '|',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 5),
                      // Selector de hora
                      GestureDetector(
                        onTap: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                        child: Text(
                          _formatTime(selectedTime),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        const Text(
                          'Title:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: TextField(
                            controller: TextEditingController(text: title),
                            decoration: InputDecoration(
                              hintText: 'Enter task title...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            onChanged: (value) {
                              title = value;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Mensaje
                        const Text(
                          'Message:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: TextField(
                            maxLines: 3,
                            controller: TextEditingController(text: message),
                            decoration: InputDecoration(
                              hintText: 'Enter task details...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            onChanged: (value) {
                              message = value;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Dropdown para Assigned To:
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: getEmployees(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            final employees = snapshot.data!;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color.fromARGB(255, 83, 77, 77)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: const Text('Select employee'),
                                  value: selectedAssigneeId,
                                  items: employees.map((employee) {
                                    return DropdownMenuItem<String>(
                                      value: employee['id'],
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.person,
                                            size: 18,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(employee['name']),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: canEditAssignment
                                      ? (String? newValue) {
                                          setState(() {
                                            selectedAssigneeId = newValue;
                                            selectedAssigneeName = employees
                                                .firstWhere((e) => e['id'] == newValue)['name'];
                                          });
                                        }
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        // Sección Multimedia:
                        const Text(
                          'Multimedia:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: canEditTaskDetails
                              ? () async {
                                  await _pickMaintenanceMedia();
                                  setState(() {}); // Refresca luego de adjuntar
                                }
                              : null,
                          child: Container(
                            width: double.infinity,
                            height: 230,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _maintenanceMediaUrls.isEmpty
                                ? const Text(
                                    'Multimedia (max 5 files)',
                                    style: TextStyle(fontSize: 18),
                                  )
                                : _buildMaintenanceCarousel(
                                    _maintenanceMediaUrls,
                                    currentPageMedia,
                                    (index) {
                                      setState(() {
                                        currentPageMedia = index;
                                      });
                                      currentPageMedia = index;
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Chips de Estado:
                        Row(
                          children: [
                            Expanded(
                              child: _buildMaintenanceStatusChip(
                                'Pending',
                                status == 'pending',
                                canEditTaskDetails,
                                onToggle: (selected) {
                                  if (selected) {
                                    setState(() {
                                      status = 'pending';
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMaintenanceStatusChip(
                                'Completed',
                                status == 'completed',
                                canEditTaskDetails,
                                onToggle: (selected) {
                                  if (selected) {
                                    setState(() {
                                      status = 'completed';
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón de eliminar a la izquierda (sólo si es una tarea existente)
                  if (task != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Task'),
                              content: const Text(
                                  'Are you sure you want to delete this task?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      },
                                    );

                                    try {
                                      await _firestore
                                          .collection('tasksMaintenance')
                                          .doc(task['id'])
                                          .delete();
                                      // ignore: use_build_context_synchronously
                                      Navigator.pop(context); // Close loading
                                      // ignore: use_build_context_synchronously
                                      Navigator.pop(
                                          // ignore: use_build_context_synchronously
                                          context); // Close confirm dialog
                                      // ignore: use_build_context_synchronously
                                      Navigator.pop(
                                          // ignore: use_build_context_synchronously
                                          context); // Close main dialog
                                      // ignore: use_build_context_synchronously
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Task deleted successfully!'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } catch (e) {
                                      // ignore: use_build_context_synchronously
                                      Navigator.pop(context); // Close loading
                                      // ignore: use_build_context_synchronously
                                      Navigator.pop(
                                          // ignore: use_build_context_synchronously
                                          context); // Close confirm dialog
                                      // ignore: use_build_context_synchronously
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Error deleting task: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.red.shade300,
                                Colors.red.shade500
                              ],
                              center: Alignment.center,
                              radius: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: Colors.red.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                  // Botones Cancel y Save
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                          );

                          try {
                            String taskId = task != null
                                ? task['id']
                                : _firestore
                                    .collection('tasksMaintenance')
                                    .doc()
                                    .id;
                            // Combina la fecha y la hora seleccionadas para asignar el valor de createdAt
                            DateTime finalDateTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                            Map<String, dynamic> data = {
                              'title': title,
                              'message': message,
                              'assignedTo': selectedAssigneeName,
                              'assignedToId': selectedAssigneeId,
                              'status': status,
                              'time': _formatTime(selectedTime),
                              'taskType': 'maintenance',
                              'updatedAt': FieldValue.serverTimestamp(),
                              'mediaUrls': _maintenanceMediaUrls,
                            };
                            data['createdAt'] =
                                Timestamp.fromDate(finalDateTime);
                            if (task != null) {
                              await _firestore
                                  .collection('tasksMaintenance')
                                  .doc(taskId)
                                  .update(data);
                            } else {
                              await _firestore
                                  .collection('tasksMaintenance')
                                  .doc(taskId)
                                  .set(data);
                            }
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context); // Close loading
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context); // Close dialog
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Maintenance task saved successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context); // Close loading
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error saving task: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        });
      },
    );
  }


// ----------------------------------------------------------------
// DOCUMENT MANAGEMENT
// ----------------------------------------------------------------

Map<DateTime, List<Map<String, dynamic>>> _groupCheckInsByDate(List<Map<String, dynamic>> checkIns) {
  final Map<DateTime, List<Map<String, dynamic>>> grouped = {};
  for (var checkIn in checkIns) {
    DateTime createdAt = DateTime.parse(checkIn['arrival']);
    DateTime key = DateTime(createdAt.year, createdAt.month, createdAt.day);
    grouped.putIfAbsent(key, () => []).add(checkIn);
  }
  return grouped;
}

Widget _buildDocumentTab() {
    // Si la aplicación está en la web, mostrar este aviso
    if (kIsWeb) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red),
        ),
        child: const Text(
          'This feature is not available on the web version, please go to the app.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Para determinar el rol actual
  final String currentUserRole = 'owner';
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  // Solo los dueños verán el selector de grupos
  if (currentUserRole == 'owner') {
    return Column(
      children: [
        _buildGroupSelector(),
        Expanded(
          child: _buildDocumentContent(),
        ),
      ],
    );
  } else {
    // Para empleados, verificar si tienen acceso
    return _buildAccessControlledContent(currentUserId);
  }
}

// Widget para seleccionar grupos (solo visible para dueños)
Widget _buildGroupSelector() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('groups').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      
      if (snapshot.hasError) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: ${snapshot.error}'),
        );
      }
      
      final groups = snapshot.data?.docs ?? [];
      
      // Obtener el grupo actualmente seleccionado
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('settings').doc('documentAccessControl').get(),
        builder: (context, settingsSnapshot) {
          String selectedGroupId = '';
          
          if (settingsSnapshot.connectionState == ConnectionState.done && 
              settingsSnapshot.data != null && 
              settingsSnapshot.data!.exists) {
            final data = settingsSnapshot.data!.data() as Map<String, dynamic>?;
            selectedGroupId = data?['authorizedGroupId'] ?? '';
          }
          
          // Usa StatefulBuilder para mantener un estado local que se actualiza inmediatamente
          return StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assign access to a group:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedGroupId.isNotEmpty ? selectedGroupId : null,
                          hint: const Text('Select a group'),
                          items: [
                            // Opción para "Sin restricción"
                            const DropdownMenuItem(
                              value: '',
                              child: Text('No restriction (everyone can access)'),
                            ),
                            // Grupos disponibles
                            ...groups.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text('${data['name']} (${data['type']})'),
                              );
                            }),
                          ],
                          onChanged: (String? newValue) async {
                            // Actualiza el estado local inmediatamente para obtener información en la ui
                            setState(() {
                              selectedGroupId = newValue ?? '';
                            });
                            
                            // Actualizar el grupo autorizado en Firestore
                            await FirebaseFirestore.instance
                                .collection('settings')
                                .doc('documentAccessControl')
                                .set({
                                  'authorizedGroupId': newValue ?? '',
                                  'updatedAt': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

// Widget que verifica el acceso para empleados
Widget _buildAccessControlledContent(String userId) {
  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance.collection('settings').doc('documentAccessControl').get(),
    builder: (context, settingsSnapshot) {
      if (settingsSnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (settingsSnapshot.hasError) {
        return Center(child: Text('Error: ${settingsSnapshot.error}'));
      }
      
      // Si no hay configuración o no hay restricción, mostrar el contenido
      if (!settingsSnapshot.hasData || !settingsSnapshot.data!.exists) {
        return _buildDocumentContent();
      }
      
      final settings = settingsSnapshot.data!.data() as Map<String, dynamic>;
      final authorizedGroupId = settings['authorizedGroupId'] ?? '';
      
      // Si no hay restricción, mostrar el contenido
      if (authorizedGroupId.isEmpty) {
        return _buildDocumentContent();
      }

      // Verificar si el usuario pertenece al grupo autorizado
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('groups').doc(authorizedGroupId).get(),
        builder: (context, groupSnapshot) {
          if (groupSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (groupSnapshot.hasError || !groupSnapshot.hasData || !groupSnapshot.data!.exists) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'You do not have access to this section.',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
          
          final groupData = groupSnapshot.data!.data() as Map<String, dynamic>;
          final members = List<String>.from(groupData['members'] ?? []);
          
          // Verificar si el usuario está en el grupo
          if (members.contains(userId)) {
            return _buildDocumentContent();
          } else {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'You do not have access to this section',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
        },
      );
    },
  );
}

Widget _buildDocumentContent() {
  return FutureBuilder<List<dynamic>>(
    // Se espera que getAllBookings devuelva una lista de reservas
    future: SmoobuApiService().getAllBookings(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      if (!snapshot.hasData) {
        return const Center(child: Text('No data available.'));
      }

      // Convertir a List<Map<String, dynamic>>
      final bookings = snapshot.data!.cast<Map<String, dynamic>>();
      // Filtrar bookings bloqueados (is-blocked-booking == true)
      final filteredBookings = bookings.where((booking) => booking['is-blocked-booking'] != true).toList();
      
      // Agrupar check-ins por fecha (basado en 'arrival')
      final grouped = _groupCheckInsByDate(filteredBookings);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final sortedDates = grouped.keys.toList();

      // Orden personalizado:
      // - Los eventos upcoming (hoy o futuro) se ordenan en forma ascendente.
      // - Los eventos pasados se ordenan en forma descendente y se colocan después.
      sortedDates.sort((a, b) {
        final aUpcoming = !a.isBefore(todayDate);
        final bUpcoming = !b.isBefore(todayDate);
        if (aUpcoming && bUpcoming) return a.compareTo(b);
        if (aUpcoming && !bUpcoming) return -1;
        if (!aUpcoming && bUpcoming) return 1;
        return b.compareTo(a);
      });

      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tasksDocuments').snapshots(),
        builder: (context, taskSnapshot) {
          if (taskSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (taskSnapshot.hasError) {
            return Center(child: Text('Error: ${taskSnapshot.error}'));
          }
          
          final taskDocs = taskSnapshot.data?.docs ?? [];
          
          return ListView(
            children: sortedDates.expand((date) {
              return [
                _buildDateHeaderWidget(date),
                ...grouped[date]!.map((booking) {
                  QueryDocumentSnapshot? taskDoc;
                  try {
                    taskDoc = taskDocs.firstWhere(
                      (doc) => (doc.data() as Map<String, dynamic>)['bookingId'] == booking['id'],
                    );
                  } catch (e) {
                    taskDoc = null;
                  }
                  final status = taskDoc != null && taskDoc.exists
                      ? ((taskDoc.data() as Map<String, dynamic>)['status'] ?? 'pending')
                      : 'pending';
                  return _buildCheckInCard(context, booking, status);
                }),
              ];
            }).toList(),
          );
        },
      );
    },
  );
}

Widget _buildCheckInCard(BuildContext context, Map<String, dynamic> booking, String status) {
  return InkWell(
    onTap: () => _showBookingDetails(context, booking, status),
    child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Check-in',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _getCheckInStatusIcon(status),
                  ],
                ),
                // Se asume que _formatDate es una función auxiliar implementada
                Text(
                  '${_formatDate(DateTime.parse(booking['arrival']))} | ${booking['check-in']}',
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.house, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking['apartment']?['name'] ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    booking['guest-name'] ?? '',
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _getCheckInStatusIcon(String status) {
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      // ignore: deprecated_member_use
      color: status == 'completed' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(
      status == 'completed' ? Icons.check_circle : Icons.remove,
      color: status == 'completed' ? Colors.green : Colors.red,
      size: 18,
    ),
  );
}

/// Diálogo de detalles de booking
void _showBookingDetails(BuildContext context, Map<String, dynamic> booking, String initialStatus) {
  // Variable local que se actualizará para reflejar el estado actual en el diálogo.
  String status = initialStatus;
  final arrivalDate = DateTime.parse(booking['arrival']);
  final departureDate = DateTime.parse(booking['departure']);
  final nights = departureDate.difference(arrivalDate).inDays;
  // Calcular número de huéspedes (suma de adultos y niños)
  final numGuests = (booking['adults'] ?? 0) + (booking['children'] ?? 0);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      booking['guest-name'] ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('Phone:', booking['phone'] ?? ''),
                  _buildDetailRow('Check-in:', booking['check-in'] ?? ''),
                  _buildDetailRow('Check-out:', booking['check-out']?.isNotEmpty == true ? booking['check-out'] : 'N/A'),
                  _buildDetailRow('Property:', booking['apartment']?['name'] ?? ''),
                  _buildDetailRow('Number of guests:', numGuests.toString()),
                  _buildDetailRow('Nights:', nights.toString()),
                  _buildDetailRow('Price:', 'AED ${booking['price'] ?? 0}'),
                  const SizedBox(height: 20),

                  // Mostrar Guest App Link como enlace y Booking Channel como texto normal
                  _buildLinkSectionLink('Guest App Link:', booking['guest-app-url']),
                  _buildLinkSectionText('Booking Channel:', booking['channel']?['name']),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16,),

                  // Sección de estados al final
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDocStatusChip(
                          'Pending',
                          status == 'pending',
                          () async {
                            if (status == 'completed') return;
                            await _updateStatus('pending', booking['id'], context);
                            setState(() {
                              status = 'pending';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDocStatusChip(
                          'Completed',
                          status == 'completed',
                          () async {
                            if (status != 'completed') {
                              await _updateStatus('completed', booking['id'], context);
                              setState(() {
                                status = 'completed';
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          );
        },
      );
    },
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );
}

/// Sección de link para Guest App Link (enlace clickable lol)
Widget _buildLinkSectionLink(String title, String? url) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 0, 0, 0))),
        if (url != null)
          SelectableText(
            url,
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline
            ),
          ),
      ],
    ),
  );
}

/// Sección de texto para Booking Channel (texto plano)
Widget _buildLinkSectionText(String title, String? text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.black)),
        if (text != null)
          Text(text, style: const TextStyle(color: Colors.black)),
      ],
    ),
  );
}

Widget _buildDocStatusChip(String label, bool isSelected, VoidCallback onPressed) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: isSelected ? Colors.blue : Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
      child: Center(child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w500))),
    ),
  );
}

/// Actualiza el estado en Firestore.
/// Nota: No se incluye setState aquí, ya que la actualización del UI se realiza en el diálogo.
Future<void> _updateStatus(String newStatus, dynamic bookingId, BuildContext context) async {
  try {
    await FirebaseFirestore.instance.collection('tasksDocuments').doc(bookingId.toString()).set({
      'bookingId': bookingId,
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (e) {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
  }
}

  // ----------------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Cleaning & Housekeeping'),
              Tab(text: 'Maintenance Services'),
              Tab(text: 'Documents Management'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCleaningTab(),
                _buildMaintenanceTab(),
                _buildDocumentTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

