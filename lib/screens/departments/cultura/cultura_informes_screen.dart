import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final Map<String, List<Map<String, String>>> requisitosCulturaInformes = {
  "Recolección de Informes": [
    {
      "title": "Informe narrativo",
      "description": "Describe actividades realizadas, participación ciudadana y lecciones aprendidas."
    },
    {
      "title": "Informe financiero",
      "description": "Detalla gastos ejecutados, adjuntando facturas, recibos y contratos."
    },
    {
      "title": "Informe de monitoreo",
      "description": "Incluye fotos, videos y encuestas de satisfacción del proyecto ejecutado."
    },
    {
      "title": "Soportes financieros",
      "description": "Facturas con RUT del proveedor, contratos con firmas autógrafas."
    },
    {
      "title": "Evidencias multimedia",
      "description": "Archivos digitales etiquetados con fecha y descripción del proyecto."
    },
  ],
};

class CulturaInformesScreen extends StatefulWidget {
  const CulturaInformesScreen({Key? key}) : super(key: key);

  @override
  _CulturaInformesScreenState createState() => _CulturaInformesScreenState();
}

class _CulturaInformesScreenState extends State<CulturaInformesScreen> {
  final Map<String, Map<String, dynamic>> _uploadedFiles = {};
  bool _isUploading = false;
  final String proceso = "Recolección de Informes";

  Future<void> _pickAndUploadFile(String docTitle) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'mp4', 'mov', 'xlsx', 'docx'],
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
      String storagePath = "cultura_informes/${docTitle}_$timestamp.$extension";

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

  Future<void> _guardarInforme() async {
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
        "tipo": "informe"
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
        const SnackBar(content: Text("Informe guardado exitosamente.")),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/user-home', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar el informe: $e")),
      );
      print("Error al guardar el informe: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> requisitos = requisitosCulturaInformes[proceso] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recolección de Informes"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tras la ejecución de proyectos culturales, los beneficiarios deben entregar informes que justifiquen el uso de recursos públicos.",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tipos de informes requeridos:",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "• Informe narrativo: Actividades y participación\n"
                    "• Informe financiero: Gastos y soportes\n"
                    "• Informe de monitoreo: Evidencias multimedia",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
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
                onPressed: _isUploading ? null : _guardarInforme,
                icon: const Icon(Icons.save),
                label: const Text("Guardar Informe"),
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
