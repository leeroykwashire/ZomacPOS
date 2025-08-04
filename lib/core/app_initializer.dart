import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';

class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Load saved user session if exists
      await ref.read(currentUserProvider.notifier).loadSavedSession();
    } catch (e) {
      print('❌ Error during app initialization: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing App...'),
            ],
          ),
        ),
      );
    }

    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser != null) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
