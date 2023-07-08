import 'dart:io'; // Provides support for Directory type
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart'; // Gives support for join()

// Provides support for getApplicationDocumentsDirectory
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: SqlApp(),
    title: 'SQLite List',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
    ),
  ));
}

class SqlApp extends StatefulWidget {
  const SqlApp({super.key});

  @override
  State<SqlApp> createState() => _SqlAppState();
}

class _SqlAppState extends State<SqlApp> {
  int? selectedId;
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: textController,
          ),
          backgroundColor: theme.colorScheme.primaryContainer,
        ),
        body: FutureBuilder<List<Grocery>>(
          future: DatabaseHelper.instance.getGroceries(),
          builder:
              (BuildContext context, AsyncSnapshot<List<Grocery>> snapshot) {
            if (!snapshot.hasData) {
              return Center(child: Text('Loading...'));
            }
            return snapshot.data!.isEmpty
                ? Center(child: Text('No groceries in list'))
                : ListView(
                    children: snapshot.data!.map((grocery) {
                      return Center(
                        child: Card(
                          color: selectedId == grocery.id
                              ? Colors.white70
                              : Colors.white,
                          child: ListTile(
                            title: Text(grocery.name),
                            onTap: () {
                              setState(() {
                                if (selectedId == null) {
                                  textController.text = grocery.name;
                                  selectedId = grocery.id;
                                } else {
                                  textController.clear();
                                  selectedId = null;
                                }
                              });
                            },
                            onLongPress: () {
                              setState(() {
                                DatabaseHelper.instance.delete(grocery.id!);
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  );
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.save),
          onPressed: () async {
            selectedId != null
                ? await DatabaseHelper.instance
                    .update(Grocery(name: textController.text, id: selectedId))
                : await DatabaseHelper.instance
                    .add(Grocery(name: textController.text));
            setState(() {
              textController.clear();
              selectedId = null;
            });
          },
        ),
      ),
    );
  }
}

class Grocery {
  final int? id; // Question mark here because id can be null (?)
  final String name;

  // Normal constructor
  Grocery({this.id, required this.name});

  // Create a Grocery object from a Map
  factory Grocery.fromMap(Map<String, dynamic> json) {
    return Grocery(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'groceries.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE groceries(
        id INTEGER PRIMARY KEY,
        name TEXT
      )
    ''');
  }

  Future<List<Grocery>> getGroceries() async {
    Database db = await instance.database;
    var groceries = await db.query('groceries', orderBy: 'name');

    List<Grocery> groceryList = groceries.isNotEmpty
        ? groceries.map((e) => Grocery.fromMap(e)).toList()
        : [];

    return groceryList;
  }

  Future<int> add(Grocery grocery) async {
    Database db = await instance.database;
    return await db.insert('groceries', grocery.toMap());
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete('groceries', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(Grocery grocery) async {
    Database db = await instance.database;
    return await db.update('groceries', grocery.toMap(),
        where: 'id = ?', whereArgs: [grocery.id]);
  }
}
