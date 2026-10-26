import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

/// While developing, talk to the local emulators instead of the real Firebase.
const bool useEmulators = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (useEmulators && kDebugMode) {
    // Chrome runs on this laptop, so the emulators are at localhost.
    const host = 'localhost';
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  }

  runApp(const UcuWellbeingApp());
}

class UcuWellbeingApp extends StatelessWidget {
  const UcuWellbeingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UCU Wellbeing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3F6E55),
        useMaterial3: true,
      ),
      home: const SmokeTestPage(),
    );
  }
}

/// A temporary screen that proves the app can write to and read from Firestore.
class SmokeTestPage extends StatelessWidget {
  const SmokeTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tests = FirebaseFirestore.instance.collection('smoke_tests');

    return Scaffold(
      appBar: AppBar(title: const Text('Firestore emulator test')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: tests.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('No test documents yet. Tap the button below.'),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data();
              return ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(data['message'] ?? ''),
                subtitle: Text('Document ID: ${docs[i].id}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => tests.add({
          'message': 'Hello from the UCU Wellbeing app',
          'createdAt': Timestamp.now(),
        }),
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('Write test document'),
      ),
    );
  }
}