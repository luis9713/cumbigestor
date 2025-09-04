import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final Map<String, List<Map<String, String>>> requisitosCulturaSolicitudes = {
  "Solicitudes de Procesos Culturales": [
    {
      "title": "Propuesta técnica",
      "description": "Mínimo 10 páginas con objetivos, metodología, cronograma y presupuesto. Incluir análisis de impacto social y económico."
    },
    {
      "title": "Acta de validación",
      "description": "Firmada por al menos tres miembros de la junta comunal para garantizar alineación con necesidades reales."
    },
    {
      "title": "Presupuesto desglosado",
      "description": "Incluir costos detallados de materiales, honorarios y logística."
    },
  ],
};

class CulturaSolicitudesScreen extends StatefulWidget {
  const CulturaSolicitudesScreen({Key? key}) : super(key: key);

  @override
  _CulturaSolicitudesScreenState createState() => _CulturaSolicitudesScreenState();
}

class _CulturaSolicitudesScreenState extends State<CulturaSolicitudesScreen> {
  final Map<String, Map<String, dynamic>> _uploadedFiles = {};
  bool _isUploading = false;
  final String proceso = "Solicitudes de Procesos Culturales";

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
      String storagePath = "cultura_solicitudes/${docTitle}_$timestamp.$extension";

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
    if (_uploadedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debe subir al menos un documento para continuar.")),
      );
      return;
    }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
      DocumentReference docRef = FirebaseFirestore.instance
          .collection("solicitudes_cultura")
          .doc();
      
      await docRef.set({
        "proceso": proceso,
        "uid": uid,
        "fecha": FieldValue.serverTimestamp(),
        "estado": "Pendiente",
        "tipo": "solicitud"
      });

      for (var entry in _uploadedFiles.values) {
        await docRef.collection("documentos").add({
          "docTitle": entry["docTitle"],
          "fileName": entry["fileName"],
          "downloadUrl": entry["downloadUrl"],
          "timestamp": FieldValue.serverTimestamp(),
        });
      }

      // Actualizar el token FCM del usuario
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({'fcmToken': fcmToken}, SetOptions(merge: true));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solicitud guardada exitosamente.")),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/user-home', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar la solicitud: $e")),
      );
      print("Error al guardar la solicitud: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> requisitos = requisitosCulturaSolicitudes[proceso] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Solicitudes de Procesos Culturales"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Artistas, colectivos o juntas de acción comunal pueden solicitar apoyo para actividades como festivales, talleres de danza o exposiciones artesanales.",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              "Proceso de evaluación: 20 días hábiles",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isUploaded)
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isUploaded)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    _uploadedFiles[title]?["fileName"] ?? "",
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ElevatedButton.icon(
                                onPressed: _isUploading ? null : () => _pickAndUploadFile(title),
                                icon: Icon(isUploaded ? Icons.refresh : Icons.upload_file),
                                label: Text(isUploaded ? "Reemplazar" : "Subir documento"),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _guardarSolicitud,
                icon: const Icon(Icons.save),
                label: const Text("Guardar Solicitud"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
