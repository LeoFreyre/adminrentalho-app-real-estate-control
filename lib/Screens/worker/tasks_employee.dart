import 'dart:io';
import 'package:adminrentalho/services/smoobu_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:adminrentalho/services/cloudinary_service.dart';


/// ===================================================================
/// Pantallas de Tareas (Empleado)
/// ===================================================================
///XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX///
/// ===================================================================
//  DIALOGO MODELO PARA DETALLES DE TAREA (TAB: CLEANING & HOUSEKEEPING)
/// ===================================================================
class _TaskDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  const _TaskDetailsDialog({required this.task});

  @override
  _TaskDetailsDialogState createState() => _TaskDetailsDialogState();
}

class _TaskDetailsDialogState extends State<_TaskDetailsDialog> {
  late String status;
  bool isTaskSaved = false;
  List<String> inProgressMediaUrls = [];
  List<String> completedMediaUrls = [];
  bool isUploadingMedia = false;
  final ImagePicker picker = ImagePicker();
  int currentPageInProgress = 0;
  int currentPageCompleted = 0;

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    status = widget.task['status'] ?? 'pending';
    isTaskSaved = status == 'completed';

    if (widget.task['inProgressMediaUrls'] != null) {
      inProgressMediaUrls =
          List<String>.from(widget.task['inProgressMediaUrls']);
    } else {
      inProgressMediaUrls = [];
    }

    if (widget.task['completedMediaUrls'] != null) {
      completedMediaUrls = List<String>.from(widget.task['completedMediaUrls']);
    } else {
      completedMediaUrls = [];
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  Widget _buildStatusChip(String label, bool isSelected, bool isInteractive,
      {Function(bool)? onToggle}) {
    return GestureDetector(
      onTap: isInteractive && onToggle != null
          ? () => onToggle(!isSelected)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 15, vertical: 10),
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

  Future<void> _pickInProgressMedia() async {
    if (inProgressMediaUrls.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Maximum of 5 files reached for In Progress')));
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
                  _showCameraOptionsInProgress();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _showGalleryOptionsInProgress();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCameraOptionsInProgress() async {
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
                  final XFile? pickedFile =
                      await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null && inProgressMediaUrls.length < 5) {
                    File file = File(pickedFile.path);
                    setState(() {
                      isUploadingMedia = true;
                    });
                    final cloudinaryService = CloudinaryService.fromEnv();
                    String? uploadedUrl = await cloudinaryService.uploadImage(
                        file, 'employee_media');
                    if (uploadedUrl != null) {
                      setState(() {
                        inProgressMediaUrls.add(uploadedUrl);
                      });
                    }
                    setState(() {
                      isUploadingMedia = false;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record Video'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile =
                      await picker.pickVideo(source: ImageSource.camera);
                  if (pickedFile != null && inProgressMediaUrls.length < 5) {
                    File file = File(pickedFile.path);
                    setState(() {
                      isUploadingMedia = true;
                    });
                    final cloudinaryService = CloudinaryService.fromEnv();
                    String? uploadedUrl = await cloudinaryService.uploadVideo(
                        file, 'employee_media');
                    if (uploadedUrl != null) {
                      setState(() {
                        inProgressMediaUrls.add(uploadedUrl);
                      });
                    }
                    setState(() {
                      isUploadingMedia = false;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showGalleryOptionsInProgress() async {
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
                  final XFile? pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null && inProgressMediaUrls.length < 5) {
                    File file = File(pickedFile.path);
                    setState(() {
                      isUploadingMedia = true;
                    });
                    final cloudinaryService = CloudinaryService.fromEnv();
                    String? uploadedUrl = await cloudinaryService.uploadImage(
                        file, 'employee_media');
                    if (uploadedUrl != null) {
                      setState(() {
                        inProgressMediaUrls.add(uploadedUrl);
                      });
                    }
                    setState(() {
                      isUploadingMedia = false;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Select Video'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile =
                      await picker.pickVideo(source: ImageSource.gallery);
                  if (pickedFile != null && inProgressMediaUrls.length < 5) {
                    File file = File(pickedFile.path);
                    setState(() {
                      isUploadingMedia = true;
                    });
                    final cloudinaryService = CloudinaryService.fromEnv();
                    String? uploadedUrl = await cloudinaryService.uploadVideo(
                        file, 'employee_media');
                    if (uploadedUrl != null) {
                      setState(() {
                        inProgressMediaUrls.add(uploadedUrl);
                      });
                    }
                    setState(() {
                      isUploadingMedia = false;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickCompletedMedia() async {
    if (completedMediaUrls.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Maximum of 5 files reached for Completed')));
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
                  _showCameraOptionsCompleted();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _showGalleryOptionsCompleted();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCameraOptionsCompleted() async {
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
                  final XFile? pickedFile =
                      await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null && completedMediaUrls.length < 5) {
                    File file = File(pickedFile.path);
                    setState(() {
                      isUploadingMedia = true;
                    });
                    final cloudinaryService = CloudinaryService.fromEnv();
                    String? uploadedUrl = await cloudinaryService.uploadImage(
                        file, 'employee_media');
                    if (uploadedUrl != null) {
                      setState(() {
                        completedMediaUrls.add(uploadedUrl);
                      });
                    }
                    setState(() {
                      isUploadingMedia = false;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record Video'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile =
                      await picker.pickVideo(source: ImageSource.camera);
                  if (pickedFile != null && completedMediaUrls.length < 5) {
                    File file = File(pickedFile.path);
                    setState(() {
                      isUploadingMedia = true;
                    });
                    final cloudinaryService = CloudinaryService.fromEnv();
                    String? uploadedUrl = await cloudinaryService.uploadVideo(
                        file, 'employee_media');
                    if (uploadedUrl != null) {
                      setState(() {
                        completedMediaUrls.add(uploadedUrl);
                      });
                    }
                    setState(() {
                      isUploadingMedia = false;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showGalleryOptionsCompleted() async {
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
                  final XFile? pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null && completedMediaUrls.length < 5) {
                    File file = File(pickedFile.path);
                    setState(() {
                      isUploadingMedia = true;
                    });
                    final cloudinaryService = CloudinaryService.fromEnv();
                    String? uploadedUrl = await cloudinaryService.uploadImage(
                        file, 'employee_media');
                    if (uploadedUrl != null) {
                      setState(() {
                        completedMediaUrls.add(uploadedUrl);
                      });
                    }
                    setState(() {
                      isUploadingMedia = false;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Select Video'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile =
                      await picker.pickVideo(source: ImageSource.gallery);
                  if (pickedFile != null && completedMediaUrls.length < 5) {
                    File file = File(pickedFile.path);
                    setState(() {
                      isUploadingMedia = true;
                    });
                    final cloudinaryService = CloudinaryService.fromEnv();
                    String? uploadedUrl = await cloudinaryService.uploadVideo(
                        file, 'employee_media');
                    if (uploadedUrl != null) {
                      setState(() {
                        completedMediaUrls.add(uploadedUrl);
                      });
                    }
                    setState(() {
                      isUploadingMedia = false;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Verifica si una URL es de video
  bool _isVideo(String url) {
    return url.toLowerCase().contains('.mp4') ||
        url.toLowerCase().contains('.mov') ||
        url.toLowerCase().contains('.avi') ||
        url.toLowerCase().contains('/video/') ||
        url.toLowerCase().contains('/video/upload/');
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
              height: 180,
              child: isVideo
                  ? Image.network(
                      // Miniatura del video desde Cloudinary con tamaño específico
                      url
                          .replaceAll('/video/upload/',
                              '/video/upload/c_fill,h_180,w_350/so_auto,pg_1/')
                          .replaceAll('.mp4', '.jpg'),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 180,
                      errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.black12,
                          width: double.infinity,
                          height: 180,
                          child:
                              const Center(child: Icon(Icons.movie, size: 40))),
                    )
                  : Image.network(
                      // Imagen con tamaño específico
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 180,
                      errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.black12,
                          width: double.infinity,
                          height: 180,
                          child: const Center(
                              child: Icon(Icons.broken_image, size: 40))),
                    ),
            ),
          ),

          // Mostrar un icono de reproducción para videos
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

  // Widget para mostrar imagen a pantalla completa
  Widget _buildFullscreenImage(String url) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white, size: 80)),
      ),
    );
  }

  // Widget para mostrar video a pantalla completa
  Widget _buildFullscreenVideo(String url) {
    // Controlador para el video
    // ignore: deprecated_member_use
    final VideoPlayerController controller = VideoPlayerController.network(url);

    return FutureBuilder(
      future: controller.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // Una vez inicializado
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: () {
                      controller.value.isPlaying
                          ? controller.pause()
                          : controller.play();
                      // Hace setState para actualizar la UI con el nuevo estado
                      // Esto está dentro de un FutureBuilder, Se usa un microtask
                      Future.microtask(() => setState(() {}));
                    },
                  ),
                ],
              ),
            ],
          );
        } else {
          // Mientras se carga el video
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
      },
    );
  }

  Widget _buildCarousel(
      List<String> urls, int currentPage, Function(int) onPageChanged) {
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
                      child: _buildMediaContent(url),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => urls.removeAt(index)),
                      child: Container(
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.black54),
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

  Widget _buildInProgressMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('In Progress Multimedia',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isUploadingMedia || isTaskSaved
              ? null
              : () async {
                  await _pickInProgressMedia();
                },
          child: Container(
            width: double.infinity,
            height: 230,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8)),
            child: isUploadingMedia
                ? const CircularProgressIndicator()
                : inProgressMediaUrls.isEmpty
                    ? const Text('Multimedia (max 5 files)',
                        style: TextStyle(fontSize: 18))
                    : _buildCarousel(inProgressMediaUrls, currentPageInProgress,
                        (index) {
                        setState(() {
                          currentPageInProgress = index;
                        });
                      }),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Completed Multimedia',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isUploadingMedia || isTaskSaved
              ? null
              : () async {
                  await _pickCompletedMedia();
                },
          child: Container(
            width: double.infinity,
            height: 230,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8)),
            child: isUploadingMedia
                ? const CircularProgressIndicator()
                : completedMediaUrls.isEmpty
                    ? const Text('Multimedia (max 5 files)',
                        style: TextStyle(fontSize: 18))
                    : _buildCarousel(completedMediaUrls, currentPageCompleted,
                        (index) {
                        setState(() {
                          currentPageCompleted = index;
                        });
                      }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime checkoutDate;
    var checkout = widget.task['checkoutDate'];
    if (checkout is Timestamp) {
      checkoutDate = checkout.toDate();
    } else if (checkout is String) {
      checkoutDate = DateTime.parse(checkout);
    } else {
      checkoutDate = checkout;
    }
    String taskId = widget.task['id'];
    String message = widget.task['message'] ?? '';
    String propertyName = widget.task['propertyName'];
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 900, 
            maxHeight: 700, 
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con propiedad y fecha/hora (solo lectura).
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
                      child: Text(propertyName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 16),
                    Text(
                        '${_formatDate(checkoutDate)} | ${widget.task['time'] ?? '11:00 AM'}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500)),
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          label: const Text('Assign To: Employee'),
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (message.isNotEmpty) ...[
                        const Text('Message:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(message),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 20),
                      const Text('Status:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: SizedBox(
                                    height: 36,
                                    child: LayoutBuilder(
                                        builder: (context, constraints) {
                                      return _buildStatusChip(
                                          'Pending',
                                          status == 'pending',
                                          status != 'completed',
                                          onToggle: (selected) {
                                        if (selected) {
                                          setState(() {
                                            status = 'pending';
                                          });
                                        }
                                      });
                                    }),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: SizedBox(
                                    height: 36,
                                    child: LayoutBuilder(
                                        builder: (context, constraints) {
                                      return _buildStatusChip(
                                          'Progress',
                                          status == 'in_progress',
                                          status != 'completed',
                                          onToggle: (selected) {
                                        if (selected) {
                                          setState(() {
                                            status = 'in_progress';
                                          });
                                        }
                                      });
                                    }),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: SizedBox(
                                    height: 36,
                                    child: LayoutBuilder(
                                        builder: (context, constraints) {
                                      return _buildStatusChip(
                                          'Finished',
                                          status == 'completed',
                                          status != 'completed',
                                          onToggle: (selected) {
                                        if (selected) {
                                          setState(() {
                                            status = 'completed';
                                          });
                                        }
                                      });
                                    }),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (status == 'in_progress')
                        _buildInProgressMediaSection()
                      else if (status == 'completed') ...[
                        _buildInProgressMediaSection(),
                        const SizedBox(height: 16),
                        _buildCompletedMediaSection(),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botón de eliminar a la izquierda
            if (!_isToday(checkoutDate))
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
                                await FirebaseFirestore.instance
                                    .collection('tasks')
                                    .doc(widget.task['id'])
                                    .delete();
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context); // Close loading
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context); // Close confirm dialog
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context); // Close main dialog
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Task deleted successfully!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } catch (e) {
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context); // Close loading
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context); // Close confirm dialog
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error deleting task: $e'),
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
                        colors: [Colors.red.shade300, Colors.red.shade500],
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
            // Botones Cancel y Save/Done
            Row(
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                status == 'completed'
                    ? ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('tasks')
                              .doc(taskId)
                              .update({
                            'status': 'completed',
                            'updatedAt': FieldValue.serverTimestamp(),
                            'inProgressMediaUrls': inProgressMediaUrls,
                            'completedMediaUrls': completedMediaUrls,
                          });
                          if (mounted) {
                            setState(() {
                              isTaskSaved = true;
                            });
                          }
                          // ignore: use_build_context_synchronously
                          if (mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Done'),
                      )
                    : ElevatedButton.icon(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                                child: CircularProgressIndicator()),
                          );
                          try {
                            Map<String, dynamic> updateData = {
                              'status': status,
                              'updatedAt': FieldValue.serverTimestamp(),
                              'inProgressMediaUrls': inProgressMediaUrls,
                              'completedMediaUrls': completedMediaUrls,
                            };
                            await FirebaseFirestore.instance
                                .collection('tasks')
                                .doc(widget.task['id'])
                                .update(updateData);
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context); // Cierra loading
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context); // Cierra diálogo
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Task status updated successfully!'),
                                  backgroundColor: Colors.green),
                            );
                          } catch (error) {
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Error updating task status: $error'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Update'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      )
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================
// CLASES EXTERNAS Y GLOBALES (_TasksEmployeeScreenState)
// =============================================================

// Widget principal que maneja la pantalla de tareas del empleado
class TasksEmployeeScreen extends StatefulWidget {
  const TasksEmployeeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TasksEmployeeScreenState createState() => _TasksEmployeeScreenState();
}

// Estado del widget principal que maneja las pestañas y la lógica de tareas
class _TasksEmployeeScreenState extends State<TasksEmployeeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // Controlador para las pestañas
  late Stream<QuerySnapshot> _tasksStream; // Stream de tareas desde Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? currentUserId; // Almacena el ID del usuario actual logueado

  // Convierte un objeto TimeOfDay a string con formato "HH:MM AM/PM"
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Convierte un string con formato "HH:MM AM/PM" a objeto TimeOfDay
  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(' ');
    if (parts.length != 2) return const TimeOfDay(hour: 11, minute: 0);
    final timeParts = parts[0].split(':');
    if (timeParts.length != 2) return const TimeOfDay(hour: 11, minute: 0);
    int hour = int.tryParse(timeParts[0]) ?? 11;
    int minute = int.tryParse(timeParts[1]) ?? 0;
    if (parts[1].toUpperCase() == 'PM' && hour != 12) {
      hour += 12;
    } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
      hour = 0;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  // Inicialización del estado y configuración inicial
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // Configura el stream de tareas según el usuario actual
    if (currentUserId != null) {
      _tasksStream = _firestore.collection('tasks').snapshots();
    } else {
      _tasksStream = _firestore
          .collection('tasks')
          .where('assigneeId', isEqualTo: 'non-existent-id')
          .snapshots();
    }
  }

  @override
  // Limpieza de recursos al destruir el widget
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Formatea una fecha al formato DD-MM-YYYY
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  // Verifica si la fecha es hoy
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Agrupa las tareas por fecha
  Map<DateTime, List<Map<String, dynamic>>> _groupTasksByDate(
      List<Map<String, dynamic>> tasks) {
    Map<DateTime, List<Map<String, dynamic>>> grouped = {};
    for (var task in tasks) {
      DateTime date;
      var checkout = task['checkoutDate'];
      if (checkout is Timestamp) {
        date = checkout.toDate();
      } else if (checkout is String) {
        date = DateTime.parse(checkout);
      } else if (checkout is DateTime) {
        date = checkout;
      } else {
        continue;
      }
      DateTime dateKey = DateTime(date.year, date.month, date.day);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(task);
    }
    return grouped;
  }

  // Genera un icono según el estado de la tarea
  Widget _getStatusIcon(String status) {
    Color bgColor;
    IconData iconData;
    Color iconColor;
    switch (status) {
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
        bgColor = Colors.red.withOpacity(0.1);
        iconData = Icons.remove;
        iconColor = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Icon(iconData, color: iconColor, size: 16),
    );
  }

  // Construye el encabezado para cada grupo de tareas por fecha
  Widget _buildDateHeader(DateTime date) {
    bool isToday = _isToday(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.grey, thickness: 1)),
          const SizedBox(width: 8),
          Text(isToday ? 'Today' : _formatDate(date),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: Colors.grey, thickness: 1)),
        ],
      ),
    );
  }

  // Muestra el diálogo con los detalles de una tarea
  void _showTaskDetails(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => _TaskDetailsDialog(task: task),
    );
  }

  // La tarjeta que muestra la información básica de una tarea
  Widget _buildTaskCard(Map<String, dynamic> task) {
    DateTime checkoutDate;
    if (task['checkoutDate'] is Timestamp) {
      checkoutDate = task['checkoutDate'].toDate();
    } else if (task['checkoutDate'] is String) {
      checkoutDate = DateTime.parse(task['checkoutDate']);
    } else {
      checkoutDate = task['checkoutDate'];
    }
    String status = task['status'] ?? 'pending';
    String time = task['time'] ?? '11:00 AM';
    return InkWell(
      onTap: () => _showTaskDetails(context, task),
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
              // Fila superior: "Task" y fecha/hora
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
                        child: const Text('Task',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      _getStatusIcon(status),
                    ],
                  ),
                  Text('${_formatDate(checkoutDate)} | $time',
                      style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 16),
              // Fila inferior: Nombre de la propiedad y texto "Tap to view..."
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.house, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(task['propertyName'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  Text('Tap to view...',
                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  //-----------------------------------------------------------------//
  // COMIENZAN LAS 3 PESTAÑAS EN ESTE ORDEN:
  // 1-CLEANING & HOUSEKEEPING
  // 2-MAINTENANCE SERVICES
  // 3-DOCUMENT MANAGEMENT

  // ===========================================================
  // CLEANING & HOUSEKEEPING
  // ===========================================================

  Widget _buildCleaningTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        // Se obtienen todas las tareas y luego se filtran según el id del usuario
        List<Map<String, dynamic>> tasks = snapshot.data!.docs.map((doc) {
          return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
        }).where((task) {
          // El empleado ve la tarea si es asignada directamente o si su id está en groupMembers
          return (task['assigneeId'] == currentUserId) ||
              (task.containsKey('groupMembers') &&
                  (task['groupMembers'] as List).contains(currentUserId));
        }).toList();

        if (tasks.isEmpty) {
          return const Center(child: Text('No tasks assigned'));
        }

        final groupedTasks = _groupTasksByDate(tasks);
        final sortedDates = groupedTasks.keys.toList()..sort((a, b) => b.compareTo(a));
        List<Widget> widgets = [];
        for (DateTime date in sortedDates) {
          widgets.add(_buildDateHeader(date));
          for (var task in groupedTasks[date]!) {
            widgets.add(_buildTaskCard(task));
          }
        }
        return ListView(children: widgets);
      },
    );
  }


// ================================================================
// MAINTENANCE SERVICES
// ================================================================

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
            widgets.add(_buildDateHeader(date));
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'To Do',
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold),
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
                        color: Colors.grey[600], fontWeight: FontWeight.w500),
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
bool isUploadingMaintenanceMedia = false;

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
                final XFile? pickedFile =
                    await ImagePicker().pickImage(source: ImageSource.camera);
                if (pickedFile != null && _maintenanceMediaUrls.length < 5) {
                  File file = File(pickedFile.path);
                    // Mostrar carga
                  setState(() {
                    isUploadingMaintenanceMedia = true;
                  });
                  final cloudinaryService = CloudinaryService.fromEnv();
                  String? uploadedUrl = await cloudinaryService.uploadImage(
                      file, 'maintenance_media');
                    // Agregar URL y ocultar carga
                  if (mounted) {
                    setState(() {
                      if (uploadedUrl != null) {
                        _maintenanceMediaUrls.add(uploadedUrl);
                        currentPageMaintenance = _maintenanceMediaUrls.length - 1;
                      }
                      isUploadingMaintenanceMedia = false;
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
                final XFile? pickedFile =
                    await ImagePicker().pickVideo(source: ImageSource.camera);
                if (pickedFile != null && _maintenanceMediaUrls.length < 5) {
                  File file = File(pickedFile.path);
                  setState(() {
                    isUploadingMaintenanceMedia = true;
                  });
                  final cloudinaryService = CloudinaryService.fromEnv();
                  String? uploadedUrl = await cloudinaryService.uploadVideo(
                      file, 'maintenance_media');
                  if (mounted) {
                    setState(() {
                      if (uploadedUrl != null) {
                        _maintenanceMediaUrls.add(uploadedUrl);
                        currentPageMaintenance = _maintenanceMediaUrls.length - 1;
                      }
                      isUploadingMaintenanceMedia = false;
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
                final XFile? pickedFile =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (pickedFile != null && _maintenanceMediaUrls.length < 5) {
                  File file = File(pickedFile.path);
                  setState(() {
                    isUploadingMaintenanceMedia = true;
                  });
                  final cloudinaryService = CloudinaryService.fromEnv();
                  String? uploadedUrl = await cloudinaryService.uploadImage(
                      file, 'maintenance_media');
                  if (mounted) {
                    setState(() {
                      if (uploadedUrl != null) {
                        _maintenanceMediaUrls.add(uploadedUrl);
                        currentPageMaintenance = _maintenanceMediaUrls.length - 1;
                      }
                      isUploadingMaintenanceMedia = false;
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
                final XFile? pickedFile =
                    await ImagePicker().pickVideo(source: ImageSource.gallery);
                if (pickedFile != null && _maintenanceMediaUrls.length < 5) {
                  File file = File(pickedFile.path);
                  setState(() {
                    isUploadingMaintenanceMedia = true;
                  });
                  final cloudinaryService = CloudinaryService.fromEnv();
                  String? uploadedUrl = await cloudinaryService.uploadVideo(
                      file, 'maintenance_media');
                  if (mounted) {
                    setState(() {
                      if (uploadedUrl != null) {
                        _maintenanceMediaUrls.add(uploadedUrl);
                        currentPageMaintenance = _maintenanceMediaUrls.length - 1;
                      }
                      isUploadingMaintenanceMedia = false;
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

// Verifica si una URL es de video
bool _isVideo(String url) {
  return url.toLowerCase().contains('.mp4') ||
      url.toLowerCase().contains('.mov') ||
      url.toLowerCase().contains('.avi') ||
      url.toLowerCase().contains('/video/') ||
      url.toLowerCase().contains('/video/upload/');
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
            height: 180,
            child: isVideo
                ? Image.network(
                    // Miniatura del video desde Cloudinary con tamaño específico
                    url
                        .replaceAll('/video/upload/', '/video/upload/c_fill,h_180,w_350/so_auto,pg_1/')
                        .replaceAll('.mp4', '.jpg'),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.black12,
                      width: double.infinity,
                      height: 180,
                      child: const Center(child: Icon(Icons.movie, size: 40)),
                    ),
                  )
                : Image.network(
                    // Imagen con tamaño específico
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.black12,
                      width: double.infinity,
                      height: 180,
                      child:
                          const Center(child: Icon(Icons.broken_image, size: 40)),
                    ),
                  ),
          ),
        ),
        // Spinner mientras sube
        if (isUploadingMaintenanceMedia)
          const Center(child: CircularProgressIndicator()),
        // Icono de reproducción para videos
        if (isVideo && !isUploadingMaintenanceMedia)
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
  // Controlador para el video
  // ignore: deprecated_member_use
  final VideoPlayerController controller = VideoPlayerController.network(url);
  return FutureBuilder(
    future: controller.initialize(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        // Una vez inicializado
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () {
                    controller.value.isPlaying
                      ? controller.pause()
                      : controller.play();
                    // Hace setState para actualizar la UI con el nuevo estado
                    // Esto está dentro de un FutureBuilder, se usa un microtask
                    Future.microtask(() => setState(() {}));
                  },
                ),
              ],
            ),
          ],
        );
      } else {
        // Mientras se carga el video
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
    },
  );
}

Widget _buildMaintenanceCarousel(
      List<String> urls, int currentPage, Function(int) onPageChanged) {
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
                      child: _buildMediaContent(url),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _maintenanceMediaUrls.removeAt(index)),
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

// Chip de estado para mantenimiento con onToggle (para uso en popup)
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

  // Obtener el rol del usuario actual (owner o employee)
  final String currentUserRole = 'employee';

  String title = task != null ? task['title'] ?? '' : '';
  String message = task != null ? task['message'] ?? '' : '';
  String? selectedAssigneeId = task != null ? task['assignedToId'] : null;
  String selectedAssigneeName = task != null ? task['assignedTo'] ?? '-' : '-';
  String status =
      task != null ? task['status'] ?? 'pending assignment' : 'pending assignment';
  String initialTime = task != null ? task['time'] ?? '11:00 AM' : '11:00 AM';
  TimeOfDay selectedTime = _parseTime(initialTime);

  // Variable para la fecha: se toma de createdAt o se usa la fecha actual.
  DateTime initialDate = task != null
      ? ((task['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now())
      : DateTime.now();
  DateTime selectedDate = initialDate;

  if (task != null && task['mediaUrls'] != null) {
    _maintenanceMediaUrls = List<String>.from(task['mediaUrls']);
  } else {
    _maintenanceMediaUrls = [];
  }

  // Variables para determinar si el usuario puede editar
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

  showDialog(
    context: context,
    builder: (context) {
      int currentPageMedia = 0;
      return StatefulBuilder(builder: (context, setStateDialog) {
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
                // Header: incluye selector de fecha a la izquierda y selector de hora a la derecha
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
                                  hint: const Text('No Selected Employee'),
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
                        StreamBuilder(
                          stream: Stream.periodic(const Duration(seconds: 2)),
                          builder: (context, snapshot) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            const Text(
                              'Multimedia:',
                              style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: canEditTaskDetails && !isUploadingMaintenanceMedia 
                              ? () async {
                                await _pickMaintenanceMedia();
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
                              child: isUploadingMaintenanceMedia
                                ? const Center(child: CircularProgressIndicator())
                                : _maintenanceMediaUrls.isEmpty
                                ? const Text(
                                  'Multimedia (max 5 files)',
                                  style: TextStyle(fontSize: 18),
                                  )
                                : _buildMaintenanceCarousel(
                                  _maintenanceMediaUrls,
                                  currentPageMedia,
                                  (index) {
                                    setStateDialog(() {
                                    currentPageMedia = index;
                                    });
                                  },
                                  ),
                              ),
                            ),
                            ],
                          );
                          }
                        ),
                        const SizedBox(height: 20),
                        // Chips de Estado: se pueden editar solo si el usuario asignado (canEditTaskDetails)
                        Row(
                          children: [
                          Expanded(
                            child: _buildMaintenanceStatusChip(
                            'Pending',
                            status == 'pending',
                            canEditTaskDetails,
                            onToggle: (selected) {
                              if (selected) {
                              setStateDialog(() {
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
                              setStateDialog(() {
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
              // Botón de eliminar a la izquierda
              if (task != null)
                Container(
                margin: const EdgeInsets.only(left: 8),
                child: InkWell(
                  onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                    title: const Text('Delete Task'),
                    content: const Text('Are you sure you want to delete this task?'),
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
                          return const Center(child: CircularProgressIndicator());
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
                        Navigator.pop(context); // Close confirm dialog
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context); // Close main dialog
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                          content: Text('Task deleted successfully!'),
                          backgroundColor: Colors.red,
                          ),
                        );
                        } catch (e) {
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context); // Close loading
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context); // Close confirm dialog
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                          content: Text('Error deleting task: $e'),
                          backgroundColor: Colors.red,
                          ),
                        );
                        }
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
                    colors: [Colors.red.shade300, Colors.red.shade500],
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
                    return const Center(child: CircularProgressIndicator());
                    },
                  );

                  try {
                    String taskId = task != null
                      ? task['id']
                      : _firestore.collection('tasksMaintenance').doc().id;
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
                    data['createdAt'] = Timestamp.fromDate(finalDateTime);
                    if (task != null) {
                    await _firestore.collection('tasksMaintenance').doc(taskId).update(data);
                    } else {
                    await _firestore.collection('tasksMaintenance').doc(taskId).set(data);
                    }
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context); // Close loading
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context); // Close dialog
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Maintenance task saved successfully!'),
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


// ================================================================
// DOCUMENT MANAGEMENT
// ================================================================

Map<DateTime, List<Map<String, dynamic>>> _groupCheckInsByDate(List<Map<String, dynamic>> checkIns) {
  final Map<DateTime, List<Map<String, dynamic>>> grouped = {};
  for (var checkIn in checkIns) {
    // Por cada arrival crea un check in y los agrupa
    DateTime createdAt = DateTime.parse(checkIn['arrival']);
    DateTime key = DateTime(createdAt.year, createdAt.month, createdAt.day);
    grouped.putIfAbsent(key, () => []).add(checkIn);
  }
  return grouped;
}

Widget _buildDocumentTab() {
  // Obtener el ID del usuario actual
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  // Verificar si el usuario tiene acceso antes de mostrar el contenido
  return _buildAccessControlledContent(currentUserId);
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
                  'You do not have access to this section.',
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

// Contenido principal del tab
Widget _buildDocumentDateHeader(DateTime date) {
  bool isToday = _isToday(date);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: Row(
      children: [
        const Expanded(child: Divider(color: Colors.grey, thickness: 1)),
        const SizedBox(width: 8),
        Text(isToday ? 'Today' : _formatDate(date),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: Colors.grey, thickness: 1)),
      ],
    ),
  );
}

Widget _buildDocumentContent() {
  return FutureBuilder<List<dynamic>>(
    // Se espera que getAllBookings devuelva una lista de bookings
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
                _buildDocumentDateHeader(date),
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


// Función auxiliar para formatear fecha en formato corto (para documentos)
String _formatDocumentDate(DateTime date) {
  final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]}';
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
                Text(
                  '${_formatDocumentDate(DateTime.parse(booking['arrival']))} | ${booking['check-in']}',
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

/// Sección de link para Guest App Link (enlace clickable)
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
        // Título y contenido en texto normal (negro)
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

  // ================================================================
  // BUILD
  // ================================================================
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
