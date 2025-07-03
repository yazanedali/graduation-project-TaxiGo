import 'package:mongo_dart/mongo_dart.dart';

class MongoService {
  Db? _db;

  // إنشاء الاتصال بـ MongoDB
  Future<void> connect() async {
    try {
      _db = await Db.create("mongodb://<mongodb+srv://TaxiGo:0594348312Adham@taxigo-db.fwrc8.mongodb.net/TaxiGo-db?retryWrites=true&w=majority>");
      await _db?.open();
      print("MongoDB connection established!");
    } catch (e) {
      print("Error: $e");
    }
  }

  // إضافة مستخدم جديد إلى قاعدة البيانات
  Future<void> createUser(Map<String, dynamic> user) async {
    final collection = _db?.collection('users');
    await collection?.insert(user);
  }

  // إغلاق الاتصال بـ MongoDB
  Future<void> closeConnection() async {
    await _db?.close();
  }
}
