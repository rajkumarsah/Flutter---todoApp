import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'todoApp',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MyHomePage(title: 'todoApp'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final textEditingController = TextEditingController();
  int? selectedId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Add todo"),
                  content: TextField(
                    controller: textEditingController,
                  ),
                  actions: [
                    TextButton(
                        onPressed: () async {
                          await DatabaseHelper.instance.add(
                            Todos(name: textEditingController.text),
                          );
                          setState(() {
                            textEditingController.clear();
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text("Add"))
                  ],
                );
              });
        },
        tooltip: 'Add todos',
        backgroundColor: Colors.deepPurple,
        focusColor: Colors.deepOrange,
        splashColor: Colors.red,
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: FutureBuilder<List<Todos>>(
          future: DatabaseHelper.instance.getTodos(),
          builder: (BuildContext context, AsyncSnapshot<List<Todos>> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: Text('Loading...'));
            }
            return snapshot.data!.isEmpty
                ? const Center(child: Text('Nothing to do...'))
                : ListView(
                    children: snapshot.data!.map((todos) {
                      return Card(
                          color: selectedId == todos.id
                              ? Colors.white70
                              : Colors.white,
                          child: ListTile(
                            leading: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.green,
                                ),
                                onPressed: () {
                                  setState(() {
                                    textEditingController.text = todos.name;
                                    selectedId = todos.id;
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Add todo"),
                                            content: TextField(
                                              controller: textEditingController,
                                            ),
                                            actions: [
                                              TextButton(
                                                  onPressed: () async {
                                                    selectedId != null
                                                        ? await DatabaseHelper
                                                            .instance
                                                            .update(Todos(
                                                                id: selectedId,
                                                                name:
                                                                    textEditingController
                                                                        .text))
                                                        : await DatabaseHelper
                                                            .instance
                                                            .add(Todos(
                                                                name:
                                                                    textEditingController
                                                                        .text));

                                                    setState(() {
                                                      textEditingController
                                                          .clear();
                                                      selectedId = null;
                                                    });
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text("Add")),
                                            ],
                                          );
                                        });
                                  });
                                }),
                            title: Text(todos.name),
                            trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    DatabaseHelper.instance.remove(todos.id!);
                                  });
                                }),
                          ));
                    }).toList(),
                  );
          },
        ),
      ),
    );
  }
}

class Todos {
  final int? id;
  final String name;

  Todos({this.id, required this.name});

  factory Todos.fromMap(Map<String, dynamic> json) => Todos(
        id: json['id'],
        name: json['name'],
      );

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
    String path = join(documentsDirectory.path, 'todos.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos(
          id INTEGER PRIMARY KEY,
          name TEXT
      )
      ''');
  }

  Future<List<Todos>> getTodos() async {
    Database db = await instance.database;
    var todo = await db.query('todos', orderBy: 'name');
    List<Todos> todoList =
        todo.isNotEmpty ? todo.map((c) => Todos.fromMap(c)).toList() : [];
    return todoList;
  }

  Future<int> add(Todos todos) async {
    Database db = await instance.database;
    return await db.insert('todos', todos.toMap());
  }

  Future<int> remove(int id) async {
    Database db = await instance.database;
    return await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(Todos todos) async {
    Database db = await instance.database;
    return await db
        .update('todos', todos.toMap(), where: "id = ?", whereArgs: [todos.id]);
  }
}
