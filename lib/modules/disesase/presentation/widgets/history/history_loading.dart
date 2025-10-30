import 'package:flutter/material.dart';

class HistoryLoadingState extends StatelessWidget {
  final Color primaryColor;

  const HistoryLoadingState({Key? key, required this.primaryColor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          SizedBox(height: 16),
          Text(
            'Memuat riwayat...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
