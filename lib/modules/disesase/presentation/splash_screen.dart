// lib/modules/disease/presentation/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/disease_modul.dart';
import '../logic/services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize API service
    final apiService = Modular.get<ApiService>();
    await apiService.initializeSession();

    // Navigate to home screen after initialization
    await Future.delayed(const Duration(seconds: 2));
    Modular.to.navigate(DiseaseModule.homeRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[700],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_rounded, size: 80, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'Deteksi Penyakit Padi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
