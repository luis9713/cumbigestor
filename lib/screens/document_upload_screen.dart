// screens/document_upload_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String category; // 'educacion', 'deporte' o 'cultura'
  const DocumentUploadScreen({super.key, required this.category});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  bool _isUploading = false;
  PlatformFile? _selectedFile;

  Future<void> _pickFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'jpg', 'png'],
    withData: true, // Asegura que se carguen los bytes del archivo
  );
  if (result != null) {
    setState(() {
      _selectedFile = result.files.first;
    });
  }
}

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;
    setState(() => _isUploading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uid = authProvider.user!.uid;
      // Sube el archivo a Firebase Storage en una carpeta con el nombre de la categoría
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(widget.category)
          .child('${uid}_${_selectedFile!.name}');
      final uploadTask = storageRef.putData(_selectedFile!.bytes!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Guarda la información en Firestore, en una colección con el nombre de la categoría
      await FirebaseFirestore.instance
          .collection(widget.category)
          .add({
        'uid': uid,
        'fileName': _selectedFile!.name,
        'downloadUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento subido correctamente')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subir documento - ${widget.category.capitalize()}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Seleccionar documento'),
            ),
            const SizedBox(height: 20),
            if (_selectedFile != null)
              Text('Archivo seleccionado: ${_selectedFile!.name}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadFile,
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : const Text('Subir documento'),
            ),
          ],
        ),
      ),
    );
  }
}

// Extensión para capitalizar la primera letra de un String
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
