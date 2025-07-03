// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:permission_handler/permission_handler.dart';

// class SmileToPayScreen extends StatefulWidget {
//   const SmileToPayScreen({Key? key}) : super(key: key);

//   @override
//   _SmileToPayScreenState createState() => _SmileToPayScreenState();
// }

// class _SmileToPayScreenState extends State<SmileToPayScreen> {
//   CameraController? _controller;
//   Future<void>? _initializeControllerFuture;
//   late FaceDetector _faceDetector;
//   bool _isProcessing = false;

//   @override
//   void initState() {
//     super.initState();
//     _faceDetector = FaceDetector(
//       options: FaceDetectorOptions(
//         enableClassification: true, // تمكين تصنيف الابتسامة
//       ),
//     );
//     _requestCameraPermission();
//   }

//   Future<void> _requestCameraPermission() async {
//     var status = await Permission.camera.request();
//     if (status.isGranted) {
//       await _initializeCamera();
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Camera permission denied!")),
//       );
//     }
//   }

//   Future<void> _initializeCamera() async {
//     final cameras = await availableCameras();
//     final frontCamera = cameras.firstWhere(
//         (camera) => camera.lensDirection == CameraLensDirection.front,
//         orElse: () => cameras.first);
    
//     _controller = CameraController(frontCamera, ResolutionPreset.medium);
//     _initializeControllerFuture = _controller!.initialize();
//     setState(() {});
//   }

//   Future<void> _processSmileDetection() async {
//     if (_controller == null || !_controller!.value.isInitialized) return;

//     setState(() => _isProcessing = true);

//     await Future.delayed(Duration(seconds: 2));

//     try {
//       final XFile picture = await _controller!.takePicture();
//       final InputImage inputImage = InputImage.fromFilePath(picture.path);
//       final List<Face> faces = await _faceDetector.processImage(inputImage);

//       if (faces.isNotEmpty) {
//         final Face face = faces.first;
//         if (face.smilingProbability != null && face.smilingProbability! > 0.7) {
//           _showMessage("Smile detected! Payment Successful ✅");
//         } else {
//           _showMessage("No smile detected! Try again ❌");
//         }
//       } else {
//         _showMessage("No face detected! Try again ❌");
//       }
//     } catch (e) {
//       _showMessage("Error processing image: $e");
//     }

//     setState(() => _isProcessing = false);
//   }

//   void _showMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

//     if (message.contains("Successful")) {
//       Future.delayed(Duration(seconds: 2), () {
//         Navigator.pop(context);
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     _faceDetector.close();
//     super.dispose();
//   }

//    @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Smile to Pay")),
//       body: Column(
//         children: [
//           Expanded(
//             child: Center(
//               child: _controller == null
//                   ? CircularProgressIndicator()
//                   : FutureBuilder<void>(
//                       future: _initializeControllerFuture,
//                       builder: (context, snapshot) {
//                         if (snapshot.connectionState == ConnectionState.done) {
//                           return AspectRatio(
//                             aspectRatio: _controller!.value.aspectRatio,
//                             child: CameraPreview(_controller!),
//                           );
//                         } else {
//                           return CircularProgressIndicator();
//                         }
//                       },
//                     ),
//             ),
//           ),
//           SizedBox(height: 20),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//             child: ElevatedButton(
//               onPressed: _isProcessing ? null : _processSmileDetection,
//               child: Text("Scan for Smile 😊"),
//               style: ElevatedButton.styleFrom(
//                 padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
//                 textStyle: TextStyle(fontSize: 18),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

// }
