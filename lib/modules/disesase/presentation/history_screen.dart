import 'package:flutter/material.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/old/prediction_chat_screen.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/history/delete_confirmation.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/history/history_card.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/history/history_empty.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/history/history_error.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/history/history_filter.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/history/history_loading.dart';
import '../logic/services/api_service.dart';
import '../logic/models/history_model.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  List<PredictionHistoryItem> _historyItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  String _selectedFilter = 'all';
  String _selectedSort = 'newest';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Color primaryColor = Colors.green.shade700;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _scrollController.addListener(_onScroll);
    _loadHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreHistory();
      }
    }
  }

  Future<void> _loadHistory({bool refresh = false}) async {
    print('🔄 Loading history - refresh: $refresh');

    if (refresh) {
      setState(() {
        _currentPage = 0;
        _historyItems.clear();
        _hasMoreData = true;
        _errorMessage = null;
      });
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.getUserHistory(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (response != null && response.success) {
        setState(() {
          if (refresh) {
            _historyItems = response.history;
          } else {
            _historyItems.addAll(response.history);
          }
          _hasMoreData = response.pagination.hasMore;
          _isLoading = false;
          _errorMessage = null;
        });

        _fadeController.forward();
        Future.delayed(Duration(milliseconds: 200), () {
          _slideController.forward();
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response == null
              ? 'Tidak dapat terhubung ke server'
              : 'Gagal memuat riwayat';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final response = await _apiService.getUserHistory(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (response != null && response.success) {
        setState(() {
          _historyItems.addAll(response.history);
          _hasMoreData = response.pagination.hasMore;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
          _currentPage--;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--;
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => HistoryFilterDialog(
        selectedFilter: _selectedFilter,
        selectedSort: _selectedSort,
        onApply: (filter, sort) {
          setState(() {
            _selectedFilter = filter;
            _selectedSort = sort;
          });
        },
      ),
    );
  }

  void _navigateToNewDiagnosis() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PredictionChatScreen(isHistoryMode: false),
      ),
    );
  }

  Future<void> _deleteHistoryItem(PredictionHistoryItem item) async {
    try {
      final success = await _apiService.deleteHistoryItem(item.id);

      if (success) {
        setState(() {
          _historyItems.removeWhere((historyItem) => historyItem.id == item.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Riwayat berhasil dihapus'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus riwayat'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteConfirmation(PredictionHistoryItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteConfirmationDialog(
        item: item,
        onConfirm: () => _deleteHistoryItem(item),
      ),
    );
  }

  void _navigateToDetail(PredictionHistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PredictionChatScreen(historyItem: item, isHistoryMode: true),
      ),
    ).then((_) => _loadHistory(refresh: true));
  }

  List<PredictionHistoryItem> _getFilteredHistory() {
    List<PredictionHistoryItem> filteredList = [];

    if (_selectedFilter == 'all') {
      filteredList = List.from(_historyItems);
    } else if (_selectedFilter == 'healthy') {
      filteredList = _historyItems
          .where((item) => item.diseaseCategory == 'Sehat')
          .toList();
    } else if (_selectedFilter == 'disease') {
      filteredList = _historyItems
          .where((item) => item.diseaseCategory != 'Sehat')
          .toList();
    }

    if (_selectedSort == 'newest') {
      filteredList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_selectedSort == 'oldest') {
      filteredList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_selectedSort == 'confidence') {
      filteredList.sort(
        (a, b) => b.confidencePercentage.compareTo(a.confidencePercentage),
      );
    }

    return filteredList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Riwayat Diagnosa',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter & Urutkan',
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: _navigateToNewDiagnosis,
            tooltip: 'Diagnosa Baru',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadHistory(refresh: true),
        color: primaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _historyItems.isEmpty) {
      return HistoryLoadingState(primaryColor: primaryColor);
    }

    if (_errorMessage != null && _historyItems.isEmpty) {
      return HistoryErrorState(
        errorMessage: _errorMessage,
        onRetry: () => _loadHistory(refresh: true),
        primaryColor: primaryColor,
      );
    }

    if (_historyItems.isEmpty) {
      return HistoryEmptyState(
        onStartDiagnosis: () => Navigator.pop(context),
        primaryColor: primaryColor,
      );
    }

    return _buildHistoryList();
  }

  Widget _buildHistoryList() {
    final filteredHistory = _getFilteredHistory();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(16),
          itemCount: filteredHistory.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == filteredHistory.length) {
              return Container(
                padding: EdgeInsets.all(16),
                alignment: Alignment.center,
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            final item = filteredHistory[index];
            return HistoryCard(
              item: item,
              index: index,
              onTap: () => _navigateToDetail(item),
              onDelete: () => _showDeleteConfirmation(item),
            );
          },
        ),
      ),
    );
  }
}
