import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cumbigestor/screens/pdf_viewer_screen.dart';
import 'package:cumbigestor/utils/utils.dart';
import 'package:cumbigestor/utils/web_download.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AdminSolicitudDetailScreen extends StatefulWidget {
  final String solicitudId;
  final String collectionName;

  const AdminSolicitudDetailScreen({
    Key? key,
    required this.solicitudId,
    required this.collectionName,
  }) : super(key: key);

  @override
  _AdminSolicitudDetailScreenState createState() => _AdminSolicitudDetailScreenState();
}

class _AdminSolicitudDetailScreenState extends State<AdminSolicitudDetailScreen> {
  bool _isUploading = false;
  String? _respuestaDocumentoUrl;
  String? _respuestaMensaje;
  double _uploadProgress = 0.0;
  PlatformFile? _responseFile;
  final TextEditingController _rechazoController = TextEditingController();

  @override
  void dispose() {
    _rechazoController.dispose();
    super.dispose();
  }

  // Método para cambiar el estado a "En proceso"
  Future<void> _startProcess() async {
    try {
      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.solicitudId)
          .update({'estado': 'En proceso'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solicitud iniciada correctamente.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al iniciar el proceso: $e")),
      );
    }
  }

  // Diálogo para aprobar y completar con carga de archivo
  Future<void> _showApprovalDialog() async {
    setState(() {
      _responseFile = null;
      _uploadProgress = 0.0;
    });

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Aprobar y Completar Solicitud"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Por favor, sube el documento de respuesta (PDF):"),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                    withData: true,
                  );
                  if (result != null) {
                    setDialogState(() {
                      _responseFile = result.files.single;
                    });
                  }
                },
                child: const Text("Seleccionar Documento"),
              ),
              if (_responseFile != null) ...[
                const SizedBox(height: 10),
                Text("Archivo seleccionado: ${_responseFile!.name}"),
              ],
              if (_isUploading) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(value: _uploadProgress),
                Text("${(_uploadProgress * 100).toStringAsFixed(0)}%"),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: _responseFile == null || _isUploading
                  ? null
                  : () async {
                      setState(() {
                        _isUploading = true;
                      });
                      try {
                        // Subir el archivo a Firebase Storage
                        String fileName = _responseFile!.name;
                        fileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
                        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
                        String storageBasePath = widget.collectionName == 'solicitudes_deporte'
                            ? 'solicitudes_deporte'
                            : 'educacion';
                        String storagePath = '$storageBasePath/${widget.solicitudId}/respuesta_$timestamp$fileName';
                        Reference ref = FirebaseStorage.instance.ref(storagePath);
                        UploadTask uploadTask = ref.putData(_responseFile!.bytes!);

                        // Escuchar el progreso de la subida
                        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
                          setDialogState(() {
                            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
                          });
                        });

                        TaskSnapshot snapshot = await uploadTask;
                        String downloadUrl = await snapshot.ref.getDownloadURL();

                        // Guardar metadatos en Firestore
                        await FirebaseFirestore.instance
                            .collection(widget.collectionName)
                            .doc(widget.solicitudId)
                            .collection('documentos')
                            .add({
                          'docTitle': 'Documento de Respuesta',
                          'fileName': "respuesta_$timestamp$fileName",
                          'downloadUrl': downloadUrl,
                          'fecha': FieldValue.serverTimestamp(),
                        });

                        // Actualizar el documento principal
                        await FirebaseFirestore.instance
                            .collection(widget.collectionName)
                            .doc(widget.solicitudId)
                            .update({
                          'estado': 'Aprobado',
                          'respuesta_documento_url': downloadUrl,
                          'respuesta_mensaje': FieldValue.delete(),
                        });

                        setState(() {
                          _respuestaDocumentoUrl = downloadUrl;
                          _respuestaMensaje = null;
                          _isUploading = false;
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Solicitud aprobada exitosamente.")),
                        );
                      } catch (e) {
                        setState(() {
                          _isUploading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error al aprobar la solicitud: $e")),
                        );
                      }
                    },
              child: const Text("Confirmar"),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo para rechazar con mensaje
  Future<void> _showRejectionDialog() async {
    _rechazoController.clear();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Rechazar Solicitud"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Por favor, ingresa el motivo del rechazo:"),
              const SizedBox(height: 10),
              TextField(
                controller: _rechazoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Escribe el motivo del rechazo...",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setDialogState(() {}); // Actualiza el diálogo cuando el texto cambia
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: _rechazoController.text.trim().isEmpty || _isUploading
                  ? null
                  : () async {
                      setState(() {
                        _isUploading = true;
                      });
                      try {
                        String mensaje = _rechazoController.text.trim();
                        await FirebaseFirestore.instance
                            .collection(widget.collectionName)
                            .doc(widget.solicitudId)
                            .update({
                          'estado': 'Rechazado',
                          'respuesta_mensaje': mensaje,
                          'respuesta_documento_url': FieldValue.delete(),
                        });

                        setState(() {
                          _respuestaMensaje = mensaje;
                          _respuestaDocumentoUrl = null;
                          _isUploading = false;
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Solicitud rechazada exitosamente.")),
                        );
                      } catch (e) {
                        setState(() {
                          _isUploading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error al rechazar la solicitud: $e")),
                        );
                      }
                    },
              child: const Text("Confirmar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(BuildContext context, String downloadUrl, String fileName) async {
    if (kIsWeb) {
      await _downloadFileWeb(context, downloadUrl, fileName);
      return;
    }
    
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

  Future<void> _downloadFileWeb(
      BuildContext context, String downloadUrl, String fileName) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Descargando archivo..."),
            ],
          ),
        ),
      );

      final response = await Dio().get(
        downloadUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data as List<int>;
      downloadFile(Uint8List.fromList(bytes), fileName);

      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Archivo descargado: $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorSnackBar(context, 'Error durante la descarga: ${e.toString()}');
      print('Detalle del error de descarga web: $e');
    }
  }

  Future<void> _checkAndRequestPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ].request();

      bool isPermissionGranted = statuses.values.every((status) => status.isGranted);
      if (!isPermissionGranted) {
        bool isPermanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);
        if (isPermanentlyDenied) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permisos Requeridos'),
              content: const Text(
                  'La aplicación necesita permisos para acceder a fotos, videos y audio. Por favor, conceda los permisos en la configuración de la aplicación.'),
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
    }
  }

  Future<Directory?> _getDownloadDirectory() async {
    Directory? directory;
    try {
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      print('Error obteniendo directorio de descargas: $e');
      directory = await getApplicationDocumentsDirectory();
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

  Future<void> _performDownload(BuildContext context, String downloadUrl, String downloadPath) async {
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
          .collection(widget.collectionName)
          .doc(widget.solicitudId)
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
              Text("ID de solicitud: ${widget.solicitudId}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              Text("Colección: ${widget.collectionName}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
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
        title: const Text("Administrar Solicitud"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(widget.collectionName)
            .doc(widget.solicitudId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text("Solicitud no encontrada"));
          }

          final solicitudData = snapshot.data!.data() as Map<String, dynamic>;
          String proceso = solicitudData["proceso"] ?? "Sin proceso";
          Timestamp? fechaTimestamp = solicitudData["fecha"];
          String fecha = fechaTimestamp != null
              ? "${fechaTimestamp.toDate().day}/${fechaTimestamp.toDate().month}/${fechaTimestamp.toDate().year} ${fechaTimestamp.toDate().hour}:${fechaTimestamp.toDate().minute.toString().padLeft(2, '0')}"
              : "Sin fecha";
          String estado = solicitudData["estado"] ?? "Pendiente";

          _respuestaDocumentoUrl = solicitudData["respuesta_documento_url"];
          _respuestaMensaje = solicitudData["respuesta_mensaje"];

          Widget estadoWidget;
          if (estado == "Pendiente" || estado == "En proceso") {
            int diasRestantes = 0;
            if (fechaTimestamp != null) {
              DateTime fechaCreacion = fechaTimestamp.toDate();
              diasRestantes = calcularDiasHabilesRestantes(fechaCreacion, 15);
            }
            estadoWidget = Text(
              "Días hábiles restantes para responder: $diasRestantes",
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
                Text("Estado: $estado"),
                const SizedBox(height: 8),
                estadoWidget,
                const SizedBox(height: 16),
                // Botones según el estado
                if (estado == "Pendiente")
                  Center(
                    child: ElevatedButton(
                      onPressed: _startProcess,
                      child: const Text("Iniciar Proceso"),
                    ),
                  ),
                if (estado == "En proceso")
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _showApprovalDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              "Aprobar y Completar",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _showRejectionDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF44336),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              "Rechazar",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if (_respuestaDocumentoUrl != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Documento de respuesta subido:",
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
                                        pdfUrl: _respuestaDocumentoUrl!,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () async {
                                  await _downloadFile(context, _respuestaDocumentoUrl!, "respuesta.pdf");
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_respuestaMensaje != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Motivo del rechazo:",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _respuestaMensaje!,
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