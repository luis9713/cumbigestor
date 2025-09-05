import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import '../../../services/offline_manager.dart';
import '../../../widgets/connection_indicator.dart';

final Map<String, List<Map<String, String>>> requisitosEducacion = {
  "Actas de Pago del Transporte Escolar": [
    {
      "title": "Acta de pago",
      "description": "Acta de pago con firmas del conductor y la institución educativa."
    },
    {
      "title": "Registro de rutas",
      "description": "Registro de rutas asignadas y horarios cumplidos (adjunto al acta)."
    },
  ],
  "Subsidios para Educación Superior": [
    {
      "title": "Certificado de notas",
      "description": "Debe incluir el sello de la institución educativa y el promedio semestral."
    },
    {
      "title": "Comprobante de matrícula",
      "description": "Factura o recibo oficial emitido por la universidad o instituto."
    },
    {
      "title": "Certificación bancaria",
      "description": "Actualizada a no más de 30 días, indicando la cuenta activa del estudiante."
    },
    {
      "title": "Formato de renovación",
      "description": "Documento estandarizado que incluye declaración jurada de necesidad económica."
    },
  ],
  "Solicitudes Educativas": [
    {
      "title": "Solicitud institucional",
      "description": "Redactada en papel membreteado, con firma del rector o representante legal."
    },
    {
      "title": "Informes técnicos",
      "description": "En casos de infraestructura, se adjuntan fotos o diagnósticos de daños."
    },
    {
      "title": "Respuesta oficial",
      "description": "Incluye sello húmedo y firma de la Coordinadora, Diana Marcela Gustin."
    },
  ],
};

class SolicitudDetailScreen extends StatefulWidget {
  final String proceso;

  const SolicitudDetailScreen({
    Key? key,
    required this.proceso,
  }) : super(key: key);

  @override
  _SolicitudDetailScreenState createState() => _SolicitudDetailScreenState();
}

class _SolicitudDetailScreenState extends State<SolicitudDetailScreen> {
  final Map<String, Map<String, dynamic>> _uploadedFiles = {};
  bool _isUploading = false;

  Future<void> _pickAndUploadFile(String docTitle) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
      withData: true,
    );
    if (result == null) return;
    PlatformFile file = result.files.first;

    setState(() {
      _isUploading = true;
    });

    try {
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String extension = file.name.split('.').last;
      String storagePath = "educacion/${docTitle}_$timestamp.$extension";

      final ref = FirebaseStorage.instance.ref().child(storagePath);
      await ref.putData(file.bytes!);
      String downloadUrl = await ref.getDownloadURL();

      setState(() {
        _uploadedFiles[docTitle] = {
          "docTitle": docTitle,
          "fileName": file.name,
          "downloadUrl": downloadUrl,
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Documento '$docTitle' subido exitosamente.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error subiendo '$docTitle': $e")),
      );
      print("Error al subir documento '$docTitle': $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _guardarSolicitud() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
      final offlineManager = Provider.of<OfflineManager>(context, listen: false);
      
      if (!offlineManager.isOnline) {
        // Offline mode - save locally without loading and show message
        await _saveOfflineSolicitud(uid);
        _mostrarMensajeOffline();
        return;
      }

      // Online mode - show loading
      setState(() {
        _isUploading = true;
      });
      
      // Submit online
      await _submitToFirebase(uid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solicitud enviada exitosamente.")),
      );
      
      Navigator.pushNamedAndRemoveUntil(context, '/user-home', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar la solicitud: $e")),
      );
      print("Error al guardar la solicitud: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _mostrarMensajeOffline() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.wifi_off, color: Colors.orange, size: 48),
          title: const Text('Sin Conexión'),
          content: const Text('Tu solicitud se ha guardado localmente y se enviará automáticamente cuando tengas conexión a internet.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(context, '/user-home', (route) => false);
              },
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitToFirebase(String uid) async {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection("solicitudes_educacion")
        .doc();
    await docRef.set({
      "proceso": widget.proceso,
      "uid": uid,
      "fecha": FieldValue.serverTimestamp(),
      "estado": "Pendiente",
    });
    
    for (var entry in _uploadedFiles.values) {
      await docRef.collection("documentos").add({
        "docTitle": entry["docTitle"],
        "fileName": entry["fileName"],
        "downloadUrl": entry["downloadUrl"],
        "timestamp": FieldValue.serverTimestamp(),
      });
    }

    // Actualizar el token FCM del usuario en la colección 'users'
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': fcmToken}, SetOptions(merge: true));
    }
  }

  Future<void> _saveOfflineSolicitud(String uid) async {
    final offlineManager = Provider.of<OfflineManager>(context, listen: false);
    
    // Create offline solicitud
    final solicitudId = await offlineManager.createSolicitudOffline(
      usuarioId: uid,
      motivo: widget.proceso,
      descripcion: 'Solicitud para el proceso: ${widget.proceso}\n\nDocumentos adjuntos:\n${_uploadedFiles.values.map((e) => '- ${e['docTitle']}: ${e['fileName']}').join('\n')}',
    );

    // Add documents offline if any
    for (var entry in _uploadedFiles.values) {
      await offlineManager.addDocumentoOffline(
        solicitudId: solicitudId,
        nombre: entry['fileName'],
        tipo: entry['docTitle'],
        localPath: null, // File is already uploaded to Firebase Storage
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> requisitos = requisitosEducacion[widget.proceso] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Solicitud: ${widget.proceso}"),
        actions: [
          Consumer<OfflineManager>(
            builder: (context, offlineManager, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ConnectionStatusIcon(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de conexión
          const ConnectionIndicator(showWhenOnline: false),
          
          // Contenido principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: requisitos.length,
                itemBuilder: (context, index) {
                  final req = requisitos[index];
                  final title = req["title"] ?? "";
                  final description = req["description"] ?? "";
                  final isUploaded = _uploadedFiles.containsKey(title);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(description),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isUploaded)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).primaryColor,
                                ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _isUploading ? null : () => _pickAndUploadFile(title),
                                icon: const Icon(Icons.upload_file),
                                label: const Text("Subir documento"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isUploading ? null : _guardarSolicitud,
              child: const Text("Guardar Solicitud"),
            ),
          ],
        ),
            ),
          ),
        ],
      ),
    );
  }
}
