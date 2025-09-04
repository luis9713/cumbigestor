import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final Map<String, List<Map<String, String>>> requisitosCulturaInscripciones = {
  "Inscripciones a Escuelas de Formación": [
    {
      "title": "Formato de inscripción",
      "description": "Con datos del aspirante (nombre, edad, escuela actual) y acudiente responsable."
    },
    {
      "title": "Registro civil del aspirante",
      "description": "Documento de identidad del aspirante (registro civil o tarjeta de identidad)."
    },
    {
      "title": "Cédula del acudiente",
      "description": "Cédula de ciudadanía del acudiente responsable."
    },
    {
      "title": "Acta de responsabilidad",
      "description": "Firmada por el acudiente, aceptando normas de conducta y asistencia."
    },
  ],
};

class CulturaInscripcionesScreen extends StatefulWidget {
  const CulturaInscripcionesScreen({Key? key}) : super(key: key);

  @override
  _CulturaInscripcionesScreenState createState() => _CulturaInscripcionesScreenState();
}

class _CulturaInscripcionesScreenState extends State<CulturaInscripcionesScreen> {
  final Map<String, Map<String, dynamic>> _uploadedFiles = {};
  bool _isUploading = false;
  final String proceso = "Inscripciones a Escuelas de Formación";
  String _selectedEscuela = "Música";
  final List<String> _escuelas = ["Música", "Danza", "Artes Audiovisuales"];

  final TextEditingController _nombreAspiranteController = TextEditingController();
  final TextEditingController _edadAspiranteController = TextEditingController();
  final TextEditingController _escuelaActualController = TextEditingController();
  final TextEditingController _nombreAcudienteController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _nombreAspiranteController.dispose();
    _edadAspiranteController.dispose();
    _escuelaActualController.dispose();
    _nombreAcudienteController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

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
      String storagePath = "cultura_inscripciones/${docTitle}_$timestamp.$extension";

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

  bool _validarFormulario() {
    if (_nombreAspiranteController.text.trim().isEmpty ||
        _edadAspiranteController.text.trim().isEmpty ||
        _nombreAcudienteController.text.trim().isEmpty ||
        _telefonoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor complete todos los campos obligatorios.")),
      );
      return false;
    }

    int? edad = int.tryParse(_edadAspiranteController.text.trim());
    if (edad == null || edad < 7 || edad > 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La edad del aspirante debe estar entre 7 y 18 años.")),
      );
      return false;
    }

    return true;
  }

  Future<void> _guardarInscripcion() async {
    if (!_validarFormulario()) return;

    if (_uploadedFiles.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debe subir al menos los documentos obligatorios para continuar.")),
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
        "tipo": "inscripcion",
        "escuela_seleccionada": _selectedEscuela,
        "datos_aspirante": {
          "nombre": _nombreAspiranteController.text.trim(),
          "edad": int.parse(_edadAspiranteController.text.trim()),
          "escuela_actual": _escuelaActualController.text.trim(),
        },
        "datos_acudiente": {
          "nombre": _nombreAcudienteController.text.trim(),
          "telefono": _telefonoController.text.trim(),
          "email": _emailController.text.trim(),
        },
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
        const SnackBar(content: Text("Inscripción guardada exitosamente.")),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/user-home', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar la inscripción: $e")),
      );
      print("Error al guardar la inscripción: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> requisitos = requisitosCulturaInscripciones[proceso] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inscripciones a Escuelas de Formación"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Las escuelas de formación en música, danza y artes audiovisuales ofrecen capacitación gratuita a niños y jóvenes entre 7 y 18 años.",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              
              // Selección de escuela
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Escuela de formación:",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEscuela,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _escuelas.map((escuela) {
                        return DropdownMenuItem(
                          value: escuela,
                          child: Text(escuela),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEscuela = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Datos del aspirante
              Text(
                "Datos del aspirante:",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nombreAspiranteController,
                decoration: const InputDecoration(
                  labelText: "Nombre completo del aspirante *",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _edadAspiranteController,
                      decoration: const InputDecoration(
                        labelText: "Edad (7-18 años) *",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _escuelaActualController,
                      decoration: const InputDecoration(
                        labelText: "Institución educativa actual",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Datos del acudiente
              Text(
                "Datos del acudiente responsable:",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nombreAcudienteController,
                decoration: const InputDecoration(
                  labelText: "Nombre completo del acudiente *",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(
                        labelText: "Teléfono de contacto *",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Correo electrónico",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Documentos requeridos
              Text(
                "Documentos requeridos:",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _guardarInscripcion,
                  icon: const Icon(Icons.app_registration),
                  label: const Text("Guardar Inscripción"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
