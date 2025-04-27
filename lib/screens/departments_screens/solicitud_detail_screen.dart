// solicitud_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';


/// Mapa de requisitos para cada proceso de Educación.
/// Cada entrada es una lista de documentos requeridos, con título y descripción.
final Map<String, List<Map<String, String>>> requisitosEducacion = {
  "Actas de Pago del Transporte Escolar": [
    {
      "title": "Acta de pago",
      "description":
          "Acta de pago con firmas del conductor y la institución educativa."
    },
    {
      "title": "Registro de rutas",
      "description":
          "Registro de rutas asignadas y horarios cumplidos (adjunto al acta)."
    },
  ],
  "Subsidios para Educación Superior": [
    {
      "title": "Certificado de notas",
      "description":
          "Debe incluir el sello de la institución educativa y el promedio semestral."
    },
    {
      "title": "Comprobante de matrícula",
      "description":
          "Factura o recibo oficial emitido por la universidad o instituto."
    },
    {
      "title": "Certificación bancaria",
      "description":
          "Actualizada a no más de 30 días, indicando la cuenta activa del estudiante."
    },
    {
      "title": "Formato de renovación",
      "description":
          "Documento estandarizado que incluye declaración jurada de necesidad económica."
    },
  ],
  "Solicitudes Educativas": [
    {
      "title": "Solicitud institucional",
      "description":
          "Redactada en papel membreteado, con firma del rector o representante legal."
    },
    {
      "title": "Informes técnicos",
      "description":
          "En casos de infraestructura, se adjuntan fotos o diagnósticos de daños."
    },
    {
      "title": "Respuesta oficial",
      "description":
          "Incluye sello húmedo y firma de la Coordinadora, Diana Marcela Gustin."
    },
  ],
};

class SolicitudDetailScreen extends StatefulWidget {
  final String proceso; // Ejemplo: "Actas de Pago del Transporte Escolar"

  const SolicitudDetailScreen({
    Key? key,
    required this.proceso,
  }) : super(key: key);

  @override
  _SolicitudDetailScreenState createState() => _SolicitudDetailScreenState();
}

class _SolicitudDetailScreenState extends State<SolicitudDetailScreen> {
  // Mapa para almacenar, por cada documento (clave: título), la metadata del archivo subido.
  // La metadata incluirá: docTitle, fileName y downloadUrl.
  final Map<String, Map<String, dynamic>> _uploadedFiles = {};

  bool _isUploading = false;

  /// Función para seleccionar y subir un archivo para un documento requerido.
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
      // Generar un nombre único para el archivo utilizando timestamp.
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String extension = file.name.split('.').last;
      String storagePath =
          "educacion/${docTitle}_$timestamp.$extension";

      // Subir el archivo a Firebase Storage.
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      await ref.putData(file.bytes!);
      String downloadUrl = await ref.getDownloadURL();

      // Guardar la metadata en el estado local, sin escribir en Firestore aún.
      setState(() {
        _uploadedFiles[docTitle] = {
          "docTitle": docTitle,
          "fileName": file.name,
          "downloadUrl": downloadUrl,
          // Aquí podrías guardar también la fecha con DateTime.now()
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

  /// Función para guardar la solicitud en Firestore.
  /// Se crea el documento principal y luego se añade cada archivo en la subcolección "documentos".
  Future<void> _guardarSolicitud() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
      // Crear el documento principal en Firestore.
      DocumentReference docRef = FirebaseFirestore.instance
          .collection("solicitudes_educacion")
          .doc(); // Se genera un ID único
      await docRef.set({
        "proceso": widget.proceso,
        "uid": uid,
        "fecha": FieldValue.serverTimestamp(),
        "estado": "Pendiente",
      });
      // Para cada documento subido (almacenado en _uploadedFiles), guardarlo en la subcolección "documentos".
      for (var entry in _uploadedFiles.values) {
        await docRef.collection("documentos").add({
          "docTitle": entry["docTitle"],
          "fileName": entry["fileName"],
          "downloadUrl": entry["downloadUrl"],
          "timestamp": FieldValue.serverTimestamp(),
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solicitud guardada exitosamente.")),
      );
      // Regresar a la pantalla de inicio (Home) y limpiar la pila de navegación.
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
    // Obtener la lista de requisitos para el proceso actual
    final List<Map<String, String>> requisitos =
        requisitosEducacion[widget.proceso] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Solicitud: ${widget.proceso}"),
      ),
      body: Padding(
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
                  // Verifica si ya se subió un archivo para este requisito.
                  final isUploaded = _uploadedFiles.containsKey(title);
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(description),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isUploaded)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _isUploading
                                    ? null
                                    : () => _pickAndUploadFile(title),
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
    );
  }
}
