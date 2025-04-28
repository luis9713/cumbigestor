import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'pdf_viewer_screen.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/utils.dart';

class SolicitudDetailViewScreen extends StatelessWidget {
  final String solicitudId;
  final String collectionName;

  const SolicitudDetailViewScreen({
    super.key,
    required this.solicitudId,
    this.collectionName = "solicitudes_educacion",
  });

  Future<void> _downloadFile(
      BuildContext context, String downloadUrl, String fileName) async {
    await _checkAndRequestPermissions(context);
    try {
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        _showErrorSnackBar(context, 'No se pudo encontrar un directorio de descargas');
        return;
      }
      final downloadPath = await _getUniqueFilePath(directory, fileName);
      await _performDownload(context, downloadUrl, downloadPath);
    } catch (e) {
      _showErrorSnackBar(context, 'Error durante la descarga: ${e.toString()}');
      print('Detalle del error de descarga: $e');
    }
  }

  Future<void> _checkAndRequestPermissions(BuildContext context) async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.storage, Permission.manageExternalStorage].request();
    bool isPermissionGranted = statuses.values.any((status) => status.isGranted);
    if (!isPermissionGranted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permisos Requeridos'),
          content: const Text(
              'La aplicación necesita permisos de almacenamiento. Por favor, conceda los permisos en la configuración de la aplicación.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
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

  Future<String> _getUniqueFilePath(Directory directory, String fileName) async {
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
      BuildContext context, String downloadUrl, String downloadPath) async {
    double progress = 0.0;
    late void Function(void Function()) setStateDialog;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          setStateDialog = setState;
          return AlertDialog(
            title: const Text("Descargando archivo"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 10),
                Text("${(progress * 100).toStringAsFixed(0)} %"),
              ],
            ),
          );
        });
      },
    );
    try {
      final dio = Dio();
      await dio.download(
        downloadUrl,
        downloadPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progress = received / total;
            setStateDialog(() {});
          }
        },
      );
      Navigator.pop(context);
      if (await File(downloadPath).exists()) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Archivo descargado'),
              content: Text('El archivo se ha descargado en:\n$downloadPath\n¿Desea abrirlo?'),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final result = await OpenFile.open(downloadPath);
                    print('Resultado al abrir archivo: $result');
                  },
                  child: const Text('Abrir'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      } else {
        _showErrorSnackBar(context, 'La descarga no se completó correctamente');
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar(context, 'Error en la descarga: ${e.toString()}');
      print('Detalle del error de descarga: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildDocumentsSection(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection(collectionName)
          .doc(solicitudId)
          .collection("documentos")
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text("Error al cargar documentos: ${snapshot.error}");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // Filtrar los documentos para excluir el documento de respuesta
        final filteredDocs = docs.where((doc) {
          final docData = doc.data() as Map<String, dynamic>;
          String docTitle = docData["docTitle"] ?? "";
          return docTitle != "Documento de Respuesta";
        }).toList();

        if (filteredDocs.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("No hay documentos subidos."),
              const SizedBox(height: 10),
              Text("ID de solicitud: $solicitudId",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              Text("Colección: $collectionName",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ElevatedButton(
                onPressed: () {},
                child: const Text("Subir documento adicional"),
              )
            ],
          );
        }

        return _buildDocumentsList(context, filteredDocs, "documentos");
      },
    );
  }

  Widget _buildDocumentsList(
      BuildContext context, List<QueryDocumentSnapshot> docs, String subcoleccion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final docData = docs[index].data() as Map<String, dynamic>;

            String docTitle = docData["docTitle"] ?? "Documento";
            String fileName = docData["fileName"] ?? "archivo.pdf";
            String downloadUrl = docData["downloadUrl"] ?? "";

            if (downloadUrl.isEmpty) {
              return Card(
                child: ListTile(
                  title: Text(docTitle),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fileName),
                      const Text("URL no disponible", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              );
            }

            return Card(
              child: ListTile(
                title: Text(docTitle),
                subtitle: Text(fileName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfViewerScreen(
                              pdfUrl: downloadUrl,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () async {
                        await _downloadFile(context, downloadUrl, fileName);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de la Solicitud"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection(collectionName)
            .doc(solicitudId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Solicitud no encontrada"));
          }
          final solicitudData = snapshot.data!.data() as Map<String, dynamic>;
          String proceso = solicitudData["proceso"] ?? "Sin proceso";
          Timestamp? fechaTimestamp = solicitudData["fecha"];
          String fecha = fechaTimestamp != null
              ? "${fechaTimestamp.toDate().day}/${fechaTimestamp.toDate().month}/${fechaTimestamp.toDate().year} ${fechaTimestamp.toDate().hour}:${fechaTimestamp.toDate().minute.toString().padLeft(2, '0')}"
              : "Sin fecha";
          String estado = solicitudData["estado"] ?? "Pendiente";
          String? respuestaDocumentoUrl = solicitudData["respuesta_documento_url"];
          String? respuestaMensaje = solicitudData["respuesta_mensaje"];

          Widget estadoWidget;
          if (estado == "Pendiente" || estado == "En proceso") {
            int diasRestantes = 0;
            if (fechaTimestamp != null) {
              DateTime fechaCreacion = fechaTimestamp.toDate();
              diasRestantes = calcularDiasHabilesRestantes(fechaCreacion, 15);
            }
            estadoWidget = Text(
              "Días hábiles restantes para respuesta: $diasRestantes",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: diasRestantes <= 3 ? Colors.red : Colors.black,
                  ),
            );
          } else {
            estadoWidget = Text(
              estado == "Aprobado" ? "Completado" : "Rechazado",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: estado == "Aprobado" ? Colors.green : Colors.red,
                  ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Proceso: $proceso",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text("Fecha: $fecha"),
                const SizedBox(height: 8),
                estadoWidget,
                const SizedBox(height: 8),
                Text("Estado: $estado"),
                const SizedBox(height: 16),
                if (estado == "Aprobado" && respuestaDocumentoUrl != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Documento de respuesta:",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          title: const Text("Documento de respuesta"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PdfViewerScreen(
                                        pdfUrl: respuestaDocumentoUrl,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () async {
                                  await _downloadFile(context, respuestaDocumentoUrl, "respuesta.pdf");
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                if (estado == "Rechazado" && respuestaMensaje != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Motivo del rechazo:",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        respuestaMensaje,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                const Divider(height: 32),
                Text(
                  "Documentos subidos:",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                _buildDocumentsSection(context),
              ],
            ),
          );
        },
      ),
    );
  }
}