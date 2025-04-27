import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String solicitudId;
  final String proceso;
  const DocumentUploadScreen({Key? key, required this.solicitudId, required this.proceso}) : super(key: key);

  @override
  _DocumentUploadScreenState createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;

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
    setState(() {
      _isUploading = true;
    });
    try {
      // Define la ruta en Storage. En este ejemplo se guarda en una carpeta "educacion".
      final fileName = _selectedFile!.name;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("educacion")
          .child("${widget.solicitudId}_$fileName");

      final uploadTask = storageRef.putData(_selectedFile!.bytes!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Guardar la información del archivo en la subcolección "documentos" del documento de solicitud
      await FirebaseFirestore.instance
          .collection("solicitudes_educacion")
          .doc(widget.solicitudId)
          .collection("documentos")
          .add({
        "fileName": fileName,
        "downloadUrl": downloadUrl,
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Documento subido exitosamente.")),
      );
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
        title: Text("Subir Documentos para ${widget.proceso}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text("Seleccionar Archivo"),
            ),
            const SizedBox(height: 20),
            if (_selectedFile != null)
              Text("Archivo seleccionado: ${_selectedFile!.name}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadDocument,
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : const Text("Subir Documento"),
            ),
          ],
        ),
      ),
    );
  }
}
