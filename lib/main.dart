import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Certificado Checker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CertificadoChecker(),
    );
  }
}

class CertificadoChecker extends StatefulWidget {
  @override
  _CertificadoCheckerState createState() => _CertificadoCheckerState();
}

class _CertificadoCheckerState extends State<CertificadoChecker> {
  String _message = '';
  String _exception = '';
  final TextEditingController _urlController = TextEditingController();

  Future<void> verificarCertificado() async {
    final String url = _urlController.text;
    Uri uri;

    try {
      uri = Uri.parse(url);
      if (!uri.hasScheme) {
        uri = Uri.parse('https://$url');
      }
    } catch (e) {
      setState(() {
        _exception = 'URL inválida: $e';
        _message = '';
      });
      return;
    }

    try {
      final socket = await SecureSocket.connect(uri.host, uri.port == 80 ? 443 : uri.port);

      final X509Certificate? cert = socket.peerCertificate;

      setState(() {
        _message = 'Certificado emitido por: ${cert?.issuer}\n'
            'Es válido y CA reconocida por Android.\n'
            '{$cert.}'
            'Válido desde: ${cert?.startValidity}\n'
            'Válido hasta: ${cert?.endValidity}';
        _exception = ''; // Limpia la zona de excepciones si todo salió bien
      });

      socket.close();
    } catch (e) {
      setState(() {
        _exception = 'Error al verificar el certificado: $e';
        _message = ''; // Limpia la zona de mensajes si hay una excepción
      });
    }

    final response = await http.get(uri);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Certificado Checker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Introduce la URL',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: verificarCertificado,
              icon: Icon(Icons.check),
              label: Text('Verificar Certificado'),
            ),
            SizedBox(height: 20),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            if (_exception.isNotEmpty)
              Text(
                _exception,
                style: TextStyle(
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
