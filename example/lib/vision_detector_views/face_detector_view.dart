import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'detector_view.dart';
import 'painters/face_detector_painter.dart';

// Clasa principală StatefulWidget care primește valoarea timer-ului, URL-ul serverului și token-ul de acces ca parametri.
class FaceDetectorView extends StatefulWidget {
  final int timerValue;
  final String serverUrl;
  final String accessToken;

  FaceDetectorView({required this.timerValue, required this.serverUrl, required this.accessToken, });
  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

// Clasa de stare pentru FaceDetectorView
class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.front;
  GlobalKey _globalKey = GlobalKey();
  List<int> ids = [];
  List<String> names = [];
  List<String> roles = [];
  List<String> bbox = [];

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  bool _canTakeScreenshot = true;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _globalKey,
      child: DetectorView(
        title: 'Face Detector',
        customPaint: _customPaint,
        text: _text,
        onImage: _processImage,
        initialCameraLensDirection: _cameraLensDirection,
        onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
      ),
    );
  }

  // Procesează imaginea capturată folosind detectorul de fețe.
  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = FaceDetectorPainter(
        faces,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
        ids,
        names,
        roles,
        bbox,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
      }
      _text = text;
      _customPaint = null;
    }
    // Face un screenshot dacă sunt detectate fețe.
    if (faces.isNotEmpty && _canTakeScreenshot) {
      _canTakeScreenshot = false;
      _takeScreenshot();
      Timer(Duration(milliseconds: widget.timerValue * 100), () {
        _canTakeScreenshot = true;
      });
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  // Capturează un screenshot al vizualizării curente.
  void _takeScreenshot() async {
    try {
      RenderRepaintBoundary boundary =
          context.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Salvează temporar screenshot-ul
      String tempPath = (await getTemporaryDirectory()).path;
      File tempFile = File('$tempPath/screenshot.png');
      await tempFile.writeAsBytes(pngBytes);

      // Trimite screenshot-ul salvat la server
      await _sendImageToServer(tempFile, widget.accessToken);
    } catch (e) {
      print('Error taking screenshot and sending to server: $e');
    }
  }

  Future<void> _sendImageToServer(File imageFile, String accessToken) async {
    try {
      // URL-ul Serverului
      String url =
          '${widget.serverUrl}';

      // Creează o cerere multipart pentru încărcarea imaginii
      var request = http.MultipartRequest('POST', Uri.parse(url));

      print('access token: $accessToken');

      request.headers['Authorization'] = 'Bearer $accessToken';

      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      // Trimite cererea
      var response = await request.send();

      // Verifică dacă cererea a avut succes
      if (response.statusCode == 200) {
        // Process response if needed
        print('Image uploaded successfully');

        await _processServerResponse(await response.stream.bytesToString());
      } else {
        print('Error uploading image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending image to server: $e');
    }
  }

  // Procesează răspunsul serverului pentru a extrage informațiile despre fețele detectate
  Future<void> _processServerResponse(String responseString) async {
    String facesString = responseString;
    this.ids = [];
    this.names = [];
    this.roles = [];
    this.bbox = [];

    // Găsește indicele de început și sfârșit al array-ului "faces"
    int startIndex = facesString.indexOf('[{');
    int endIndex = facesString.indexOf('}]');

    // Extrage substring-ul care conține array-ul "faces"
    String facesSubstring = facesString.substring(startIndex + 1, endIndex + 1);

    // Împarte substring-ul după '},{'
    List<String> faceEntries = facesSubstring.split('},{');

    // Extrage id, name și role pentru fiecare intrare de față
    for (var entry in faceEntries) {
      String bboxCoord = _extractValue(entry, '"bbox":[', ']');

      int id = int.tryParse(_extractValue(entry, '"id":', ',')) ?? -1;

      String name = _extractValue(entry, '"name":"', '"');

      String role = _extractValue(entry, '"role":"', '"');


      // Adaugă id, name și role la listele respective
      if (id != -1) {
        this.ids.add(id);
        this.names.add(name);
        this.roles.add(role);
        this.bbox.add(bboxCoord);
      }
    }

    // Afișează informațiile extrase
    print('IDs: $ids');
    print('Names: $names');
    print('Roles: $roles');
    print('Bbox: $bbox');
  }

  // Funcție ajutătoare pentru a extrage valorile dintre două delimitatoare
  String _extractValue(
      String entry, String startDelimiter, String endDelimiter) {
    int startIndex = entry.indexOf(startDelimiter);
    if (startIndex != -1) {
      int endIndex =
          entry.indexOf(endDelimiter, startIndex + startDelimiter.length);
      if (endIndex != -1) {
        return entry.substring(startIndex + startDelimiter.length, endIndex);
      }
    }
    return '';
  }
}
