import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as firebase_ui;
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'add_content_screen.dart';
import 'widgets/content_card.dart';
import 'screens/full_text_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lexup',
      debugShowCheckedModeBanner: false, // Disable DEBUG banner
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MainPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuthGate();
  }
}

class AuthGate extends StatefulWidget {
  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Auto login on startup
    _autoSignIn();
  }

  Future<void> _autoSignIn() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        // Use existing email login method
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'nikolaev.gd@gmail.com',
          password: 'Gagauz1a'
        );
      }
    } catch (e) {
      print('Auto login error: $e');
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator only on first login
        if (_isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        // Show error message only if login actually failed
        if (!snapshot.hasData && _hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Auto login error'),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                    });
                    _autoSignIn();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        // If user data exists or login is in progress, show HomePage
        return HomePage();
      },
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lexup Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return HomeContent();
      case 1:
        return Center(child: Text('Learn Page'));
      case 2:
        return AddContentScreen();
      case 3:
        return Center(child: Text('Profile Page'));
      default:
        return Center(child: Text('Unknown Page'));
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('content')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No content added yet'));
        }

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            String text = data['text'] ?? '';
            String link = data['link'] ?? '';
            return ContentCard(
              text: text,
              link: link,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullTextScreen(
                      text: text,
                      link: link,
                      title: text.isNotEmpty 
                        ? text.split('\n')[0].replaceAll(RegExp(r'\*\*|__|\*|_|#+\s'), '').trim()
                        : 'Link',
                      documentId: document.id,
                    ),
                  ),
                );
              },
              onDelete: () async {
                try {
                  // Delete all word cards related to this content card
                  final cardsSnapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .collection('content')
                      .doc(document.id)
                      .collection('cards')
                      .get();

                  final batch = FirebaseFirestore.instance.batch();

                  for (var cardDoc in cardsSnapshot.docs) {
                    batch.delete(cardDoc.reference);
                  }

                  // Delete the content card itself
                  batch.delete(FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .collection('content')
                      .doc(document.id));

                  // Execute all delete operations
                  await batch.commit();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Content and related cards successfully deleted')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting content: $e')),
                  );
                }
              },
            );
          }).toList(),
        );
      },
    );
  }
}
