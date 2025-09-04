import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class PantallaFirma extends StatefulWidget {
  const PantallaFirma({Key? key}) : super(key: key);

  @override
  _PantallaFirmaState createState() => _PantallaFirmaState();
}

class _PantallaFirmaState extends State<PantallaFirma> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firmar Documento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _controller.clear();
            },
            tooltip: 'Borrar firma',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: Signature(
                controller: _controller,
                width: double.infinity,
                height: double.infinity,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _controller.clear();
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Borrar'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_controller.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, realice su firma antes de guardar'),
                        ),
                      );
                      return;
                    }

                    final Uint8List? data = await _controller.toPngBytes();
                    if (data != null) {
                      Navigator.pop(context, data);
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Guardar Firma'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}