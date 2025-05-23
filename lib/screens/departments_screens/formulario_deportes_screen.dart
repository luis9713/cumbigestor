import 'dart:io';
import 'dart:typed_data';
import 'package:cumbigestor/screens/departments_screens/pantalla_firma.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class FormularioDeportesScreen extends StatefulWidget {
  const FormularioDeportesScreen({super.key});

  @override
  _FormularioDeportesScreenState createState() => _FormularioDeportesScreenState();
}

class _FormularioDeportesScreenState extends State<FormularioDeportesScreen> {
  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final cedulaController = TextEditingController();
  final direccionController = TextEditingController();
  final telefonoController = TextEditingController();
  final emailController = TextEditingController();
  final asuntoController = TextEditingController();
  final descripcionController = TextEditingController();
  DateTime fechaSolicitud = DateTime.now();
  bool isGeneratingPdf = false;

  Uint8List? firmaImagenBytes;
  bool tieneFirma = false;

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    cedulaController.dispose();
    direccionController.dispose();
    telefonoController.dispose();
    emailController.dispose();
    asuntoController.dispose();
    descripcionController.dispose();
    super.dispose();
  }

  Future<void> _capturarFirma() async {
    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (context) => const PantallaFirma()),
    );

    if (result != null) {
      setState(() {
        firmaImagenBytes = result;
        tieneFirma = true;
      });
      _mostrarMensaje('Firma guardada correctamente');
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      var storageStatus = await Permission.storage.request();
      var manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) {
        return true;
      } else if (manageStatus.isPermanentlyDenied) {
        _mostrarDialogoAbrirConfiguracion();
        return false;
      }

      return storageStatus.isGranted;
    }
    return true;
  }

  Future<bool> _mostrarDialogoAbrirConfiguracion() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos necesarios'),
        content: const Text('Esta aplicación necesita permisos de almacenamiento para guardar archivos PDF. Por favor, activa los permisos en la configuración de la aplicación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    ) ?? false;
  }

  String _generateFileName() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final timestamp = formatter.format(now);
    return 'solicitud_alcaldia_$timestamp.pdf';
  }

  Future<String?> _getDownloadsPath() async {
    Directory? directory;

    try {
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();

          if (directory != null) {
            String newPath = "";
            List<String> folders = directory.path.split("/");

            for (int i = 1; i < folders.length; i++) {
              String folder = folders[i];
              if (folder != "Android") {
                newPath += "/" + folder;
              } else {
                break;
              }
            }

            newPath += "/Download";
            directory = Directory(newPath);
          }
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null && !await directory.exists()) {
        await directory.create(recursive: true);
      }

      return directory?.path;
    } catch (e) {
      print("Error al obtener directorio de descargas: $e");
      return null;
    }
  }

  Future<pw.Document> _generarContenidoPDF() async {
    final pdf = pw.Document();

    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String fechaFormateada = formatter.format(fechaSolicitud);

    pw.Image? firmaImagen;
    if (firmaImagenBytes != null) {
      final image = pw.MemoryImage(firmaImagenBytes!);
      firmaImagen = pw.Image(image, width: 150, height: 70);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(30),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('SOLICITUD A DEPARTAMENTO DE DEPORTES',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Align(
                  alignment: pw.Alignment.topRight,
                  child: pw.Text('Fecha: $fechaFormateada'),
                ),
                pw.SizedBox(height: 20),
              ],
            );
          } else {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: pw.EdgeInsets.only(bottom: 10, top: 10),
              child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}'),
            );
          }
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 8),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.Text('Señor/a Director/a del Departamento de Deportes',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Municipalidad de [Nombre del Municipio]'),
            pw.SizedBox(height: 20),
            pw.Text('Asunto: ${asuntoController.text}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('De mi consideración:'),
            pw.SizedBox(height: 10),
            pw.Paragraph(
              text: 'Yo, ${nombreController.text} ${apellidoController.text}, '
                  'identificado/a con cédula de identidad Nº ${cedulaController.text}, '
                  'con domicilio en ${direccionController.text}, '
                  'teléfono ${telefonoController.text} y correo electrónico ${emailController.text}, '
                  'me dirijo a usted respetuosamente para solicitar lo siguiente:'),
            pw.SizedBox(height: 10),
            pw.Paragraph(text: descripcionController.text),
            pw.SizedBox(height: 20),
            pw.Paragraph(
              text: 'Sin otro particular, agradezco de antemano su atención y quedo a la espera de una respuesta favorable.'),
            pw.SizedBox(height: 30),
            pw.Text('Atentamente,'),
            pw.SizedBox(height: 40),
            tieneFirma
                ? firmaImagen!
                : pw.Container(
                    width: 150,
                    height: 1,
                    color: PdfColors.black,
                  ),
            pw.SizedBox(height: 5),
            pw.Text('____________________'),
            pw.Text('${nombreController.text} ${apellidoController.text}'),
            pw.Text('C.I.: ${cedulaController.text}'),
          ];
        },
      ),
    );

    return pdf;
  }

  Future<void> _guardarPDFEnDescargas() async {
    setState(() {
      isGeneratingPdf = true;
    });

    try {
      bool permissionGranted = await _requestStoragePermission();

      if (!permissionGranted) {
        _mostrarMensaje('Se requieren permisos de almacenamiento para guardar el PDF.');
        setState(() {
          isGeneratingPdf = false;
        });
        return;
      }

      final pdf = await _generarContenidoPDF();

      String? downloadsPath = await _getDownloadsPath();

      if (downloadsPath == null) {
        _mostrarMensaje('No se pudo acceder a la carpeta de descargas.');
        setState(() {
          isGeneratingPdf = false;
        });
        return;
      }

      final fileName = _generateFileName();
      final filePath = '$downloadsPath/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      _mostrarDialogoExito(file);
    } catch (e) {
      _mostrarMensaje('Error al guardar el PDF: $e');
    } finally {
      setState(() {
        isGeneratingPdf = false;
      });
    }
  }

  Future<void> _abrirPDF(File file) async {
    try {
      await OpenFile.open(file.path);
    } catch (e) {
      _mostrarMensaje('No se pudo abrir el archivo: $e');
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  void _mostrarDialogoExito(File file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('PDF Guardado Exitosamente'),
          content: Text('El archivo se ha guardado en la carpeta de descargas como: ${file.path.split('/').last}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _abrirPDF(file);
              },
              child: const Text('Abrir PDF'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaSolicitud,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != fechaSolicitud) {
      setState(() {
        fechaSolicitud = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Solicitud para Alcaldía'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datos Personales',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su apellido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: cedulaController,
                  decoration: const InputDecoration(
                    labelText: 'Cédula de Identidad',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su cédula';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su dirección';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su teléfono';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su correo';
                    } else if (!value.contains('@')) {
                      return 'Por favor ingrese un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Datos de la Solicitud',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Fecha: ${DateFormat('dd/MM/yyyy').format(fechaSolicitud)}'),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _seleccionarFecha(context),
                      child: const Text('Cambiar Fecha'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: asuntoController,
                  decoration: const InputDecoration(
                    labelText: 'Asunto',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el asunto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción de la solicitud',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor describa su solicitud';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Firma: ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _capturarFirma,
                      icon: const Icon(Icons.draw),
                      label: Text(tieneFirma ? 'Cambiar Firma' : 'Añadir Firma'),
                    ),
                    if (tieneFirma) ...[
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            firmaImagenBytes = null;
                            tieneFirma = false;
                          });
                          _mostrarMensaje('Firma eliminada');
                        },
                        tooltip: 'Eliminar firma',
                      ),
                    ],
                  ],
                ),
                if (tieneFirma)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(5),
                    

                    height: 100,
                    child: Image.memory(
                      firmaImagenBytes!,
                      height: 90,
                    ),
                  ),
                const SizedBox(height: 30),
                Center(
                  child: isGeneratingPdf
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _guardarPDFEnDescargas();
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Generar y Guardar PDF'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}