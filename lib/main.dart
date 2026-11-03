import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TasisatApp());
}

class TasisatApp extends StatelessWidget {
  const TasisatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدیریت تأسیسات',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Tahoma',
      ),
      home: const HomeScreen(),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasisat.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE equipment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        location TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertEquipment(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('equipment', row);
  }

  Future<List<Map<String, dynamic>>> getEquipment() async {
    final db = await instance.database;
    return await db.query('equipment', orderBy: 'id DESC');
  }

  Future<int> deleteEquipment(int id) async {
    final db = await instance.database;
    return await db.delete('equipment', where: 'id = ?', whereArgs: [id]);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _equipmentList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    final data = await DatabaseHelper.instance.getEquipment();
    setState(() {
      _equipmentList = data;
      _isLoading = false;
    });
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final locationController = TextEditingController();
    String status = 'سالم';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('افزودن تجهیز جدید'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'نام تجهیز')),
              TextField(controller: codeController, decoration: const InputDecoration(labelText: 'کد / پلاک تجهیز')),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'محل نصب (سالن/خط)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await DatabaseHelper.instance.insertEquipment({
                  'name': nameController.text,
                  'code': codeController.text.isEmpty ? '-' : codeController.text,
                  'location': locationController.text.isEmpty ? '-' : locationController.text,
                  'status': status,
                });
                Navigator.pop(context);
                _refreshData();
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت تأسیسات و تجهیزات (CMMS)'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _equipmentList.isEmpty
              ? const Center(child: Text('هنوز هیچ تجهیزی ثبت نشده است.', style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  itemCount: _equipmentList.length,
                  itemBuilder: (context, index) {
                    final item = _equipmentList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: const Icon(Icons.settings, color: Colors.blue),
                        ),
                        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('کد: ${item['code']} | محل: ${item['location']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await DatabaseHelper.instance.deleteEquipment(item['id']);
                            _refreshData();
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
