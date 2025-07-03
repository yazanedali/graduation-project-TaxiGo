// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:image/src/image.dart' as img;
// import 'package:image_picker/image_picker.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

// void main() {
//   runApp(MaterialApp(
//     home: LicenseChecker(),
//     debugShowCheckedModeBanner: false,
//   ));
// }

// class LicenseChecker extends StatefulWidget {
//   @override
//   _LicenseCheckerState createState() => _LicenseCheckerState();
// }

// class _LicenseCheckerState extends State<LicenseChecker> {
//   File? _image;
//   String result = 'لم يتم فحص أي رخصة بعد';
//   late Interpreter interpreter;

//   @override
//   void initState() {
//     super.initState();
//     _loadModel();
//   }

//   Future<void> _loadModel() async {
//     interpreter = await Interpreter.fromAsset('license_model.tflite');
//   }

//   Future<void> _pickImage() async {
//     final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//         result = "جاري التحليل...";
//       });
//       await _analyzeImage(_image!);
//     }
//   }

//   Future<void> _analyzeImage(File imageFile) async {
//     final inputImage = InputImage.fromFile(imageFile);
//     final textRecognizer = GoogleMlKit.vision.textRecognizer();
//     final barcodeScanner = GoogleMlKit.vision.barcodeScanner();

//     String finalResult = '';

//     // OCR
//     final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
//     final extractedText = recognizedText.text;
//     finalResult += '\nالنص المكتشف:\n$extractedText';

//     // فحص تاريخ الانتهاء
//     RegExp dateRegex = RegExp(r'(\d{2})[/-](\d{2})[/-](\d{4})');
//     final matches = dateRegex.allMatches(extractedText);
//     bool expired = false;

//     for (final match in matches) {
//       final dateStr = match.group(0)!;
//       final parts = dateStr.split(RegExp(r'[/-]'));
//       final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
//       if (date.isBefore(DateTime.now())) {
//         expired = true;
//         break;
//       }
//     }
//     finalResult += '\nالحالة: ${expired ? '❌ منتهية' : '✅ سارية'}';

//     // QR Code
//     final barcodes = await barcodeScanner.processImage(inputImage);
//     if (barcodes.isNotEmpty) {
//       finalResult += '\nQR موجود: ${barcodes.first.rawValue}';
//     } else {
//       finalResult += '\nلا يوجد QR Code';
//     }

//     // تحليل ذكاء صناعي للصورة
//     final aiResult = await _runModelOnImage(imageFile);
//     finalResult += '\nتحليل الذكاء الصناعي: ${aiResult == 1 ? '✅ أصلية' : '❌ مشبوهة'}';

//     setState(() {
//       result = finalResult;
//     });
//   }

//   Future<int> _runModelOnImage(File imageFile) async {
//     final rawImage = FileImage(imageFile);
//     final imageProcessor = ImageProcessorBuilder()
//         .add(ResizeOp(224, 224, ResizeMethod.BILINEAR))
//         .build();

//     final input = await rawImage.obtainKey(ImageConfiguration()).then((key) async {
//       final image = await decodeImageFromList(await imageFile.readAsBytes());
//       final tensorImage = TensorImage.fromImage(image as img.Image);
//       return imageProcessor.process(tensorImage);
//     });

//     var inputBuffer = input.buffer;
//     var output = List.filled(1 * 1, 0).reshape([1, 1]);

//     interpreter.run(inputBuffer, output);

//     return output[0][0];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("فحص رخصة القيادة")),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             if (_image != null)
//               Image.file(_image!, height: 200),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _pickImage,
//               child: Text("اختر صورة الرخصة"),
//             ),
//             SizedBox(height: 20),
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Text(result, style: TextStyle(fontSize: 16)),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
