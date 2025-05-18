import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
      final fileName = _selectedFile!.name;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("educacion")
          .child("${widget.solicitudId}_$fileName");

      final uploadTask = storageRef.putData(_selectedFile!.bytes!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection("solicitudes_educacion")
          .doc(widget.solicitudId)
          .collection("documentos")
          .add({
        "fileName": fileName,
        "downloadUrl": downloadUrl,
        "timestamp": FieldValue.serverTimestamp(),
      });

      // Actualizar el token FCM del usuario en la colección 'users'
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
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