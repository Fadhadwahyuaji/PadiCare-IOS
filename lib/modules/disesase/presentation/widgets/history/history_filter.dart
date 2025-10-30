import 'package:flutter/material.dart';

class HistoryFilterDialog extends StatefulWidget {
  final String selectedFilter;
  final String selectedSort;
  final Function(String filter, String sort) onApply;

  const HistoryFilterDialog({
    Key? key,
    required this.selectedFilter,
    required this.selectedSort,
    required this.onApply,
  }) : super(key: key);

  @override
  State<HistoryFilterDialog> createState() => _HistoryFilterDialogState();
}

class _HistoryFilterDialogState extends State<HistoryFilterDialog> {
  late String _selectedFilter;
  late String _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.selectedFilter;
    _selectedSort = widget.selectedSort;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Filter & Urutkan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterSection(),
          SizedBox(height: 16),
          _buildSortSection(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_selectedFilter, _selectedSort);
            Navigator.pop(context);
          },
          child: Text('Terapkan'),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filter:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        _buildFilterOption('all', 'Semua'),
        _buildFilterOption('healthy', 'Sehat'),
        _buildFilterOption('disease', 'Penyakit'),
      ],
    );
  }

  Widget _buildFilterOption(String value, String label) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _selectedFilter,
      onChanged: (newValue) {
        setState(() => _selectedFilter = newValue!);
      },
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Urutkan:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        _buildSortOption('newest', 'Terbaru'),
        _buildSortOption('oldest', 'Terlama'),
        _buildSortOption('confidence', 'Confidence'),
      ],
    );
  }

  Widget _buildSortOption(String value, String label) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _selectedSort,
      onChanged: (newValue) {
        setState(() => _selectedSort = newValue!);
      },
    );
  }
}
