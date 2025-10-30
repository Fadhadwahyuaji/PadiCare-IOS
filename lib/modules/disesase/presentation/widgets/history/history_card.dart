import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../logic/models/history_model.dart';

class HistoryCard extends StatelessWidget {
  final PredictionHistoryItem item;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HistoryCard({
    Key? key,
    required this.item,
    required this.index,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade700;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 12),
                _buildDiseasePrediction(context),
                if (item.chatMessages.isNotEmpty) ...[
                  SizedBox(height: 12),
                  _buildChatMessagesBadge(),
                ],
                SizedBox(height: 8),
                _buildTapIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Row(
          children: [
            _buildConfidenceBadge(),
            SizedBox(width: 8),
            _buildDeleteButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildConfidenceBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: item.confidenceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${item.confidencePercentage.toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 12,
          color: item.confidenceColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: onDelete,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline, size: 16, color: Colors.red[600]),
      ),
    );
  }

  Widget _buildDiseasePrediction(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item.diseaseCategory == 'Sehat'
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item.diseaseCategory == 'Sehat' ? Icons.eco : Icons.warning,
            color: item.diseaseCategory == 'Sehat' ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.predictedClass,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                item.diseaseCategory,
                style: TextStyle(
                  fontSize: 12,
                  color: item.diseaseCategory == 'Sehat'
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      ],
    );
  }

  Widget _buildChatMessagesBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat, size: 12, color: Colors.blue),
          SizedBox(width: 4),
          Text(
            '${item.chatMessages.length} pesan',
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        'Tap untuk melihat detail lengkap',
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 10,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
