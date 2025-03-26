import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_drawer.dart';
import 'pdf_viewer_screen.dart';

// Mapeo de UID de administradores a su departamento.
// Reemplaza estos valores con los UID reales de tus administradores.
const Map<String, String> adminDepartmentMapping = {
  'A3zwu7ksPzZQ0BLoYHSO46jUFy03': 'educación',
  'uid_admin_deporte': 'deporte',
  'uid_admin_cultura': 'cultura',
};

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Future<void> _downloadFile(
    BuildContext context,
    String downloadUrl,
    String fileName,
  ) async {
    // Paso 1: Verificar y solicitar permisos de manera comprehensiva
    await _checkAndRequestPermissions(context);

    try {
      // Paso 2: Obtener directorio de descargas
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        _showErrorSnackBar(
          context,
          'No se pudo encontrar un directorio de descargas',
        );
        return;
      }

      // Paso 3: Crear la ruta completa de descarga
      final downloadPath = await _getUniqueFilePath(directory, fileName);

      // Paso 4: Realizar la descarga
      await _performDownload(context, downloadUrl, downloadPath);
    } catch (e) {
      _showErrorSnackBar(context, 'Error durante la descarga: ${e.toString()}');
      print('Detalle del error de descarga: $e');
    }
  }

  Future<void> _checkAndRequestPermissions(BuildContext context) async {
    // Solicitar múltiples permisos
    Map<Permission, PermissionStatus> statuses =
        await [Permission.storage, Permission.manageExternalStorage].request();

    bool isPermissionGranted = statuses.values.any(
      (status) => status.isGranted,
    );

    if (!isPermissionGranted) {
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Permisos Requeridos'),
              content: const Text(
                'La aplicación necesita permisos de almacenamiento. Por favor, conceda los permisos en la configuración de la aplicación.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings(); // Abre la configuración de la aplicación
                  },
                  child: const Text('Abrir Configuración'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
      );
    }
  }

  Future<Directory?> _getDownloadDirectory() async {
    Directory? directory;

    try {
      if (Platform.isAndroid) {
        // Intentar múltiples rutas de descarga
        final possibleDirectories = [
          Directory('/storage/emulated/0/Download'),
          await getExternalStorageDirectory(),
          await getApplicationDocumentsDirectory(),
        ];

        for (var dir in possibleDirectories) {
          if (dir != null && await dir.exists()) {
            directory = dir;
            break;
          }
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      print('Error obteniendo directorio de descargas: $e');
    }

    return directory;
  }

  Future<String> _getUniqueFilePath(
    Directory directory,
    String fileName,
  ) async {
    // Asegurar nombre de archivo único
    String basePath = '${directory.path}/$fileName';
    String filePath = basePath;
    int counter = 1;

    while (await File(filePath).exists()) {
      String nameWithoutExtension = fileName.split('.').first;
      String extension = fileName.split('.').last;
      filePath = '${directory.path}/$nameWithoutExtension($counter).$extension';
      counter++;
    }

    return filePath;
  }

  Future<void> _performDownload(
    BuildContext context,
    String downloadUrl,
    String downloadPath,
  ) async {
    try {
      final dio = Dio();
      await dio.download(
        downloadUrl,
        downloadPath,
        onReceiveProgress: (receivedBytes, totalBytes) {
          double progress = receivedBytes / totalBytes;
          print(
            'Progreso de descarga: ${(progress * 100).toStringAsFixed(2)}%',
          );
        },
      );

      // Verificar si el archivo se descargó correctamente
      if (await File(downloadPath).exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo descargado en: $downloadPath'),
            action: SnackBarAction(
              label: 'Abrir',
              onPressed: () {
                // Implementar apertura de archivo si es necesario
              },
            ),
          ),
        );
      } else {
        _showErrorSnackBar(context, 'La descarga no se completó correctamente');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Error en la descarga: ${e.toString()}');
      print('Detalle del error de descarga: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final uid = authProvider.user?.uid ?? '';
    final department = adminDepartmentMapping[uid];

    if (department == null) {
      return const Scaffold(
        body: Center(
          child: Text('No se encontró el departamento para este administrador'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Administrador')),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Bienvenido, Administrador\nDepartamento: ${department.capitalize()}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection(department)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final documents = snapshot.data!.docs;
                  if (documents.isEmpty) {
                    return const Center(
                      child: Text('No hay documentos en este departamento'),
                    );
                  }
                  return ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final data =
                          documents[index].data() as Map<String, dynamic>;
                      final fileName = data['fileName'] ?? 'Sin nombre';
                      final timestamp = data['timestamp'];
                      final dateString =
                          timestamp != null
                              ? (timestamp as Timestamp).toDate().toString()
                              : 'Sin fecha';
                      final downloadUrl = data['downloadUrl'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(dateString),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('Ver'),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => PdfViewerScreen(
                                                pdfUrl: downloadUrl,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: const Icon(Icons.download),
                                    label: const Text('Descargar'),
                                    onPressed: () async {
                                      await _downloadFile(
                                        context,
                                        downloadUrl,
                                        fileName,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
