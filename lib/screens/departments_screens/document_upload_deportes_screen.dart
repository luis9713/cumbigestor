import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DocumentUploadDeportesScreen extends StatefulWidget {
  const DocumentUploadDeportesScreen({Key? key}) : super(key: key);

  @override
  _DocumentUploadDeportesScreenState createState() => _DocumentUploadDeportesScreenState();
}

class _DocumentUploadDeportesScreenState extends State<DocumentUploadDeportesScreen> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  final TextEditingController _procesoController = TextEditingController(text: "Solicitud Deportes");
  final TextEditingController _tituloDocumentoController = TextEditingController(text: "Documento de Solicitud");

  @override
  void dispose() {
    _procesoController.dispose();
    _tituloDocumentoController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
      withData: true,
    );
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedFile == null) return;

    if (_procesoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor ingresa un nombre para el proceso")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final String fileName = _selectedFile!.name;
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
      final String proceso = _procesoController.text.trim();
      final String tituloDocumento = _tituloDocumentoController.text.trim();

      DocumentReference solicitudRef = await FirebaseFirestore.instance
          .collection("solicitudes_deporte")
          .add({
            "uid": uid,
            "proceso": proceso,
            "fecha": FieldValue.serverTimestamp(),
            "estado": "Pendiente",
          });

      final String storagePath = "solicitudes_deporte/${solicitudRef.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName";
      Reference ref = FirebaseStorage.instance.ref().child(storagePath);
      await ref.putData(_selectedFile!.bytes!);
      String downloadUrl = await ref.getDownloadURL();

      await solicitudRef.collection("documentos").add({
        "docTitle": tituloDocumento,
        "fileName": fileName,
        "downloadUrl": downloadUrl,
        "fecha": FieldValue.serverTimestamp(),
      });

      // Actualizar el token FCM del usuario en la colección 'users'
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({'fcmToken': fcmToken}, SetOptions(merge: true));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Documento subido exitosamente.")),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/user-home', (route) => false);

      setState(() {
        _selectedFile = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Realizar Solicitud - Deportes"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Nombre del Proceso:",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _procesoController,
                decoration: const InputDecoration(
                  hintText: "Ej: Solicitud Deportes, Inscripción Torneo, etc.",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Título del Documento:",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tituloDocumentoController,
                decoration: const InputDecoration(
                  hintText: "Ej: Formulario de Inscripción, Certificado, etc.",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text("Seleccionar Documento"),
              ),
              const SizedBox(height: 20),
              if (_selectedFile != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Archivo seleccionado:",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(_selectedFile!.name),
                      Text("Tamaño: ${(_selectedFile!.size / 1024).toStringAsFixed(2)} KB"),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadDocument,
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text("Subiendo..."),
                        ],
                      )
                    : const Text("Subir Documento"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}