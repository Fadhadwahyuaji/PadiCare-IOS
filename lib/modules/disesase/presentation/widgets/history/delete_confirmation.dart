import 'package:flutter/material.dart';
import '../../../logic/models/history_model.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final PredictionHistoryItem item;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    Key? key,
    required this.item,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Text('Konfirmasi Hapus'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Anda yakin ingin menghapus riwayat diagnosa ini?'),
          SizedBox(height: 8),
          _buildWarningBox(),
        ],
      ),
      actions: [
        TextButton(
          child: Text('Batal'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text('Hapus Permanen'),
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
        ),
      ],
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWarningText('• Data diagnosa akan dihapus permanen'),
          _buildWarningText('• Gambar yang terkait akan dihapus dari server'),
          _buildWarningText('• Riwayat chat akan ikut terhapus'),
          _buildWarningText('• Aksi ini tidak dapat dibatalkan', bold: true),
        ],
      ),
    );
  }

  Widget _buildWarningText(String text, {bool bold = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.red[700],
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
