import 'package:flutter/services.dart' show rootBundle;
import 'package:excel/excel.dart';
import 'dart:typed_data';

Future<bool> isDriverInExcel(String driverName) async {
  ByteData data = await rootBundle.load('assets/taxi_drivers.xlsx');
  Uint8List bytes = data.buffer.asUint8List();

  var excel = Excel.decodeBytes(bytes);

  for (var table in excel.tables.keys) {
    var sheet = excel.tables[table]!;
    for (var row in sheet.rows) {
      if (row.isNotEmpty) {
        var cellValue = row[0]?.value.toString().trim();
        if (cellValue == driverName.trim()) {
          return true; // السائق موجود
        }
      }
    }
  }
  return false; // السائق غير موجود
}
