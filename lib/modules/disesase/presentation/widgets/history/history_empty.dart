import 'package:flutter/material.dart';

class HistoryEmptyState extends StatelessWidget {
  final VoidCallback onStartDiagnosis;
  final Color primaryColor;

  const HistoryEmptyState({
    Key? key,
    required this.onStartDiagnosis,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Belum ada riwayat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Mulai diagnosa tanaman padi untuk melihat riwayat',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: onStartDiagnosis,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Mulai Diagnosa'),
          ),
        ],
      ),
    );
  }
}
