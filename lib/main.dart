import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ReportScreen(),
    );
  }
}

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  File? _image;
  String _analysisResult = '';
  String _summary = '';
  final picker = ImagePicker();

  // Pick image from camera or gallery
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null && mounted) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _analyzeImage(_image!);
    }
  }

  // AI image analysis using TensorFlow Lite
  Future<void> _analyzeImage(File image) async {
    try {
      final interpreter = await Interpreter.fromAsset('yolo_model.tflite');
      // Placeholder: Process image for object detection
      // Replace with actual YOLO model inference logic
      // Example output: "Detected: 2 helmets, 1 excavator"
      String result = await _runModelOnImage(image);
      setState(() {
        _analysisResult = result;
      });
      await _summarizeAnalysis(result);
    } catch (e) {
      setState(() {
        _analysisResult = 'Error analyzing image: $e';
      });
    }
  }

  // Mock function for running TFLite model (replace with actual model logic)
  Future<String> _runModelOnImage(File image) async {
    // Load image, preprocess, and run inference
    // This is a placeholder; implement YOLO model processing
    return 'Detected: 2 helmets, 1 excavator, 0 safety violations';
  }

  // Summarize analysis results using xAI API
  Future<void> _summarizeAnalysis(String analysis) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.x.ai/summarize'), // Replace with actual xAI API endpoint
        headers: {'Content-Type': 'application/json'},
        body: '{"text": "$analysis"}',
      );
      if (response.statusCode == 200) {
        setState(() {
          _summary = response.body; // e.g., "Summary: 2 helmets and 1 excavator detected."
        });
      } else {
        setState(() {
          _summary = 'Error summarizing analysis';
        });
      }
    } catch (e) {
      setState(() {
        _summary = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Construction Report')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Take Photo'),
            ),
            if (_image != null)
              Image.file(_image!, height: 200),
            Text('Analysis: $_analysisResult'),
            Text('Summary: $_summary'),
          ],
        ),
      ),
    );
  }
}