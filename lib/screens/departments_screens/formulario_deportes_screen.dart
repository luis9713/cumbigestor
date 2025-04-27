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
  // Controladores para los campos del formulario
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
  
  // Variable para la firma
  Uint8List? firmaImagenBytes;
  bool tieneFirma = false;

  @override
  void dispose() {
    // Limpieza de los controladores cuando se destruye el widget
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

  // Método para capturar la firma
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

  // Método para solicitar permisos de almacenamiento
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Comprueba la versión de Android
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      
      // Para Android 11 y superior, primero solicitamos el permiso general
      var storageStatus = await Permission.storage.request();
      
      // Si está en Android 10+ necesitamos permisos adicionales
      var manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) {
        return true;
      } else if (manageStatus.isPermanentlyDenied) {
        // Si el usuario ha denegado permanentemente, ofrecer abrir configuración
        _mostrarDialogoAbrirConfiguracion();
        return false;
      }
      
      return storageStatus.isGranted;
    }
    // En iOS los permisos son manejados de forma diferente
    return true;
  }

  // Diálogo para abrir configuración cuando los permisos son denegados permanentemente
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

  // Método para generar un nombre de archivo único
  String _generateFileName() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final timestamp = formatter.format(now);
    return 'solicitud_alcaldia_$timestamp.pdf';
  }

  // Método para obtener la ruta de descargas en Android
  Future<String?> _getDownloadsPath() async {
    Directory? directory;
    
    try {
      if (Platform.isAndroid) {
        // Primero intentamos obtener el directorio de descargas estándar
        directory = Directory('/storage/emulated/0/Download');
        // Verificamos si existe y es accesible
        if (!await directory.exists()) {
          // Si no, intentamos con el directorio de almacenamiento externo
          directory = await getExternalStorageDirectory();
          
          if (directory != null) {
            // En algunos dispositivos, debemos construir manualmente la ruta a la carpeta de descargas
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
        // En iOS, usamos el directorio de documentos ya que no hay equivalente a "Descargas"
        directory = await getApplicationDocumentsDirectory();
      }
      
      // Crear el directorio si no existe
      if (directory != null && !await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      return directory?.path;
    } catch (e) {
      print("Error al obtener directorio de descargas: $e");
      return null;
    }
  }

  // Método para generar el contenido del PDF
  Future<pw.Document> _generarContenidoPDF() async {
    // Crear un documento PDF
    final pdf = pw.Document();

    // Formato de fecha
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String fechaFormateada = formatter.format(fechaSolicitud);

    // Convertir la firma para el PDF si existe
    pw.Image? firmaImagen;
    if (firmaImagenBytes != null) {
      final image = pw.MemoryImage(firmaImagenBytes!);
      firmaImagen = pw.Image(image, width: 150, height: 70);
    }

    // Añadir una página al PDF con manejo de múltiples páginas
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(30),
        // Construye el encabezado una vez para todas las páginas
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Encabezado
                pw.Header(
                  level: 0,
                  child: pw.Text('SOLICITUD A DEPARTAMENTO DE DEPORTES',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                
                // Fecha
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
        // Construye el pie de página para todas las páginas
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
        // Construye el cuerpo que se distribuirá en múltiples páginas
        build: (pw.Context context) {
          return [
            // Datos del destinatario
            pw.Text('Señor/a Director/a del Departamento de Deportes', 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Municipalidad de [Nombre del Municipio]'),
            pw.SizedBox(height: 20),
            
            // Asunto
            pw.Text('Asunto: ${asuntoController.text}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            
            // Saludo
            pw.Text('De mi consideración:'),
            pw.SizedBox(height: 10),
            
            // Cuerpo
            pw.Paragraph(
              text: 'Yo, ${nombreController.text} ${apellidoController.text}, '
                  'identificado/a con cédula de identidad Nº ${cedulaController.text}, '
                  'con domicilio en ${direccionController.text}, '
                  'teléfono ${telefonoController.text} y correo electrónico ${emailController.text}, '
                  'me dirijo a usted respetuosamente para solicitar lo siguiente:'
            ),
            
            pw.SizedBox(height: 10),
            pw.Paragraph(text: descripcionController.text),
            pw.SizedBox(height: 20),
            
            // Despedida
            pw.Paragraph(
              text: 'Sin otro particular, agradezco de antemano su atención y quedo a la espera de una respuesta favorable.'
            ),
            pw.SizedBox(height: 30),
            
            // Firma
            pw.Text('Atentamente,'),
            pw.SizedBox(height: 40),
            
            // Insertar la firma si existe, o mostrar la línea para firma si no
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

  // Método para guardar el PDF en la carpeta de descargas
  Future<void> _guardarPDFEnDescargas() async {
    setState(() {
      isGeneratingPdf = true;
    });

    try {
      // Solicitar permisos primero
      bool permissionGranted = await _requestStoragePermission();
      
      if (!permissionGranted) {
        _mostrarMensaje('Se requieren permisos de almacenamiento para guardar el PDF.');
        setState(() {
          isGeneratingPdf = false;
        });
        return;
      }

      // Generar el PDF
      final pdf = await _generarContenidoPDF();

      // Obtener la ruta de descargas
      String? downloadsPath = await _getDownloadsPath();
      
      if (downloadsPath == null) {
        _mostrarMensaje('No se pudo acceder a la carpeta de descargas.');
        setState(() {
          isGeneratingPdf = false;
        });
        return;
      }

      // Generar un nombre de archivo único
      final fileName = _generateFileName();
      final filePath = '$downloadsPath/$fileName';
      
      // Guardar el archivo
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      // Mostrar mensaje de éxito y ofrecer abrir el archivo
      _mostrarDialogoExito(file);
    } catch (e) {
      _mostrarMensaje('Error al guardar el PDF: $e');
    } finally {
      setState(() {
        isGeneratingPdf = false;
      });
    }
  }

  // Método para abrir el PDF
  Future<void> _abrirPDF(File file) async {
    try {
      await OpenFile.open(file.path);
    } catch (e) {
      _mostrarMensaje('No se pudo abrir el archivo: $e');
    }
  }

  // Método para mostrar un mensaje
  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  // Método para mostrar un diálogo de éxito
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

  // Método para seleccionar la fecha
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
                // Sección de datos personales
                const Text(
                  'Datos Personales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                
                // Sección de datos de la solicitud
                const Text(
                  'Datos de la Solicitud',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                
                // Sección de firma
                Row(
                  children: [
                    const Text(
                      'Firma: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        icon: const Icon(Icons.delete, color: Colors.red),
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
                
                // Si hay firma, mostrar una vista previa
                if (tieneFirma)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    height: 100,
                    child: Image.memory(
                      firmaImagenBytes!,
                      height: 90,
                    ),
                  ),
                
                const SizedBox(height: 30),
                
                // Botón para generar PDF
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
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
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
