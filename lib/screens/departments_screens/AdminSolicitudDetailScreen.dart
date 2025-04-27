import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cumbigestor/screens/pdf_viewer_screen.dart';
import 'package:cumbigestor/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
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
  String _selectedEstado = '';
  final List<String> _estados = ['Pendiente', 'En proceso', 'Aprobado', 'Rechazado'];
  final TextEditingController _rechazoController = TextEditingController();
  bool _isUploading = false;
  String? _respuestaDocumentoUrl;
  String? _respuestaMensaje;
  double _uploadProgress = 0.0;

  Future<void> _actualizarEstado(String nuevoEstado) async {
    try {
      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.solicitudId)
          .update({'estado': nuevoEstado});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Estado actualizado a $nuevoEstado")),
      );
      if (nuevoEstado != "Aprobado" && nuevoEstado != "Rechazado") {
        await FirebaseFirestore.instance
            .collection(widget.collectionName)
            .doc(widget.solicitudId)
            .update({
          'respuesta_documento_url': FieldValue.delete(),
          'respuesta_mensaje': FieldValue.delete(),
        });
        setState(() {
          _respuestaDocumentoUrl = null;
          _respuestaMensaje = null;
          _rechazoController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al actualizar estado: $e")),
      );
    }
  }

  Future<void> _subirDocumentoRespuesta() async {
    try {
      // Verificar autenticación
      final user = FirebaseAuth.instance.currentUser;
      print("UID del usuario autenticado: ${user?.uid}");
      if (user == null) {
        throw Exception("No hay usuario autenticado. Por favor, inicia sesión nuevamente.");
      }

      // Validar los parámetros de la ruta
      if (widget.collectionName.isEmpty) {
        throw Exception("El nombre de la colección está vacío.");
      }
      if (widget.solicitudId.isEmpty) {
        throw Exception("El ID de la solicitud está vacío.");
      }
      print("Nombre de la colección: ${widget.collectionName}");
      print("ID de la solicitud: ${widget.solicitudId}");

      // Permitir al administrador seleccionar un archivo
      print("Abriendo selector de archivos...");
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Asegura que los bytes estén disponibles
      );
      print("Resultado del selector: $result");

      if (result == null || result.files.single.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se seleccionó ningún archivo o no mulai se pudieron obtener los bytes")),
        );
        return;
      }

      PlatformFile platformFile = result.files.single;
      String fileName = platformFile.name;
      print("Archivo seleccionado: ${fileName}, tamaño: ${platformFile.size} bytes");

      // Limpiar el nombre del archivo para evitar caracteres problemáticos
      fileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      print("Nombre del archivo limpio: $fileName");

      // Mostrar diálogo de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Subiendo documento"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: _uploadProgress),
                  const SizedBox(height: 10),
                  Text("${(_uploadProgress * 100).toStringAsFixed(0)}%"),
                ],
              ),
            );
          });
        },
      );

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Determinar la carpeta base en Firebase Storage según la colección
      String storageBasePath;
      if (widget.collectionName == 'solicitudes_deporte') {
        storageBasePath = 'solicitudes_deporte';
      } else if (widget.collectionName == 'solicitudes_educacion') {
        storageBasePath = 'educacion';
      } else {
        throw Exception("Colección no soportada: ${widget.collectionName}");
      }

      // Construir la ruta para Firebase Storage
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String storagePath = '$storageBasePath/${widget.solicitudId}/respuesta_$timestamp$fileName';
      print("Subiendo archivo a: $storagePath");

      // Subir el archivo a Firebase Storage usando putData
      Reference ref = FirebaseStorage.instance.ref(storagePath);
      UploadTask uploadTask = ref.putData(platformFile.bytes!);

      // Escuchar el progreso de la subida
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          print("Progreso de la subida: ${(_uploadProgress * 100).toStringAsFixed(2)}%");
        });
      }, onError: (e) {
        print("Error en el snapshotEvents: $e");
        Navigator.pop(context);
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error durante la subida: $e")),
        );
      });

      // Esperar a que la subida se complete
      print("Esperando a que la subida se complete...");
      TaskSnapshot snapshot = await uploadTask;
      print("Subida completada. Obteniendo URL de descarga...");
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print("URL de descarga obtenida: $downloadUrl");

      // Guardar los metadatos del documento de respuesta en la subcolección 'documentos'
      print("Guardando metadatos en Firestore...");
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

      // Actualizar el campo respuesta_documento_url en el documento principal
      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.solicitudId)
          .update({
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
        const SnackBar(content: Text("Documento de respuesta subido exitosamente")),
      );
    } catch (e) {
      print("Error completo al subir documento: $e");
      Navigator.pop(context);
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al subir documento: $e")),
      );
    }
  }

  Future<void> _enviarMensajeRechazo() async {
    if (_rechazoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, escribe un motivo de rechazo")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.solicitudId)
          .update({
        'respuesta_mensaje': _rechazoController.text.trim(),
        'respuesta_documento_url': FieldValue.delete(),
      });

      setState(() {
        _respuestaMensaje = _rechazoController.text.trim();
        _respuestaDocumentoUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mensaje de rechazo enviado exitosamente")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar mensaje: $e")),
      );
    }
  }

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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
                  style: const TextStyle(color: Colors.grey)),
              Text("Colección: ${widget.collectionName}",
                  style: const TextStyle(color: Colors.grey)),
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
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
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
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
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
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection(widget.collectionName)
            .doc(widget.solicitudId)
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
          _selectedEstado = estado;

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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: diasRestantes <= 3 ? Colors.red : Colors.black,
              ),
            );
          } else {
            estadoWidget = Text(
              estado == "Aprobado" ? "Completado" : "Rechazado",
              style: TextStyle(
                fontSize: 16,
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("Fecha: $fecha"),
                const SizedBox(height: 8),
                estadoWidget,
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      "Estado: ",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: _selectedEstado,
                      items: _estados.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedEstado = newValue;
                          });
                          _actualizarEstado(newValue);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedEstado == "Aprobado" && _respuestaDocumentoUrl == null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Subir documento de respuesta:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isUploading ? null : _subirDocumentoRespuesta,
                        child: _isUploading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Seleccionar documento (PDF)"),
                      ),
                    ],
                  ),
                if (_respuestaDocumentoUrl != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Documento de respuesta subido:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 3,
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
                if (_selectedEstado == "Rechazado" && _respuestaMensaje == null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Motivo del rechazo:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _rechazoController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Escribe el motivo del rechazo...",
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _enviarMensajeRechazo,
                        child: const Text("Enviar mensaje de rechazo"),
                      ),
                    ],
                  ),
                if (_respuestaMensaje != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Motivo del rechazo:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _respuestaMensaje!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                const Divider(height: 32),
                const Text(
                  "Documentos subidos:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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