import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      //we need a firebase acc for our group !
      apiKey: "AIzaSyB0BxpvMWLVHUrtXFaDFyhomPpGnGpIvcI",
      //authDomain: "appfb-7123f.firebaseapp.com",
      projectId: "testing-22fda",
      //storageBucket: "appfb-7123f.appspot.com",
      messagingSenderId: "421309501948",
      appId: "1:421309501948:web:6df14606227098d844e279",
      //measurementId: "G-24WW5SKLJ5"
    ),
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: Text("a"));
  }
}
