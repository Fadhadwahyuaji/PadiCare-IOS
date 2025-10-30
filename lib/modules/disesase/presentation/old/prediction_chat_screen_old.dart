// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/controllers/chat_controller.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/controllers/prediction_controller.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/models/history_model.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/models/prediction_model.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/services/api_service.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/history_screen.dart';

class PredictionChatScreen extends StatefulWidget {
  final PredictionHistoryItem? historyItem; // Parameter untuk history mode
  final bool isHistoryMode; // Flag untuk menentukan mode

  const PredictionChatScreen({
    Key? key,
    this.historyItem,
    this.isHistoryMode = false,
  }) : super(key: key);

  @override
  State<PredictionChatScreen> createState() => _PredictionChatScreenState();
}

class _PredictionChatScreenState extends State<PredictionChatScreen>
    with TickerProviderStateMixin {
  File? _selectedImage;
  PredictionResult? _result;
  bool _isLoading = false;
  final picker = ImagePicker();
  final predictionController = PredictionController();
  final chatController = ChatController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();

  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isChatLoading = false;
  bool _isChatMinimized = true;
  bool _isChatFullScreen = false;

  // Animation controller for chat minimization
  late AnimationController _chatAnimationController;
  late Animation<double> _chatAnimation;

  // Tambahkan DraggableScrollableController untuk mengontrol swipe
  late DraggableScrollableController _draggableController;

  // App theme colors
  final Color primaryColor = Colors.green.shade700;
  final Color accentColor = Colors.green.shade300;
  final Color userBubbleColor = Colors.green.shade600;
  final Color botBubbleColor = Colors.grey.shade100;
  final Color backgroundColor = Colors.grey.shade50;

  Future<String?>? _historyImageUrlFuture;

  // Add to initState method

  bool _isServerReachable = true;
  String _serverStatus = "Memeriksa server...";

  @override
  void initState() {
    super.initState();
    _chatAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _chatAnimation = CurvedAnimation(
      parent: _chatAnimationController,
      curve: Curves.easeInOut,
    );

    // Initialize DraggableScrollableController
    _draggableController = DraggableScrollableController();

    // Load history data jika dalam mode history
    if (widget.isHistoryMode && widget.historyItem != null) {
      _loadHistoryData();
      // Cache future image url hanya sekali
      _historyImageUrlFuture = _getImageUrl(widget.historyItem!.id);
    }

    // Check server connectivity
    _checkServerStatus();
  }

  // Sederhanakan method _checkServerStatus() untuk hanya update state tanpa notifikasi
  Future<void> _checkServerStatus() async {
    print('🔍 Starting server status check...');
    try {
      // Try a simple endpoint call to check server status
      final isActive = await ApiService().checkServerStatus();
      print('✅ Server status check result: $isActive');

      setState(() {
        _isServerReachable = isActive;
        _serverStatus = isActive ? "Server aktif" : "Server tidak aktif";
      });
    } catch (e) {
      print('❌ Server status check error: $e');
      setState(() {
        _isServerReachable = false;
        _serverStatus = "Server tidak aktif";
      });
    }
  }

  // Update _loadHistoryData untuk include top predictions dari history
  void _loadHistoryData() {
    final historyItem = widget.historyItem!;
    print('📊 Loading history data for: ${historyItem.predictedClass}');
    print('💬 Chat messages count: ${historyItem.chatMessages.length}');
    print('🏆 Top predictions available: ${historyItem.hasTopPredictions}');

    setState(() {
      // Set result dari history DENGAN top predictions
      _result = PredictionResult(
        predictedClass: historyItem.predictedClass,
        confidencePercentage: historyItem.confidencePercentage,
        expertAdvice: historyItem.expertAdvice,
        success: true,
        predictionId: historyItem.id,
        processingTime: historyItem.processingTime,
        topPredictions: historyItem.topPredictions, // INCLUDE TOP PREDICTIONS
      );

      // Load chat messages dari history
      _messages.clear();

      // Add expert advice as first message if available
      if (historyItem.expertAdvice != null &&
          historyItem.expertAdvice!.isNotEmpty) {
        _messages.add({
          'isUser': false,
          'message': historyItem.expertAdvice!,
          'timestamp': historyItem.createdAt,
          'isExpertAdvice': true,
        });
        print('✅ Added expert advice to messages');
      }

      // Load chat history dalam urutan yang benar (chronological)
      List<ChatMessageItem> sortedMessages = List.from(
        historyItem.chatMessages,
      );
      sortedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (var chatMsg in sortedMessages) {
        _messages.add({
          'isUser': chatMsg.isUser,
          'message': chatMsg.message,
          'timestamp': chatMsg.createdAt,
          'isExpertAdvice': false,
        });
      }

      // DEFAULT TERTUTUP untuk history juga
      _isChatMinimized = true;
      print('💬 Total messages loaded: ${_messages.length}');
      print('📊 Chat minimized: $_isChatMinimized');
    });

    // Debug top predictions
    if (historyItem.hasTopPredictions) {
      print('🏆 Top predictions from history:');
      for (var pred in historyItem.top3Predictions) {
        print(
          '   ${pred.rank}. ${pred.className}: ${pred.confidence.toStringAsFixed(1)}%',
        );
      }
    } else {
      print('❌ No top predictions in history item');
    }

    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _result = null;
        _messages.clear();
      });
    }
  }

  // Update method _analyzeImage untuk memberikan pesan error yang lebih jelas
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    // Periksa status server terlebih dahulu
    await _checkServerStatus(); // Pastikan status server terbaru

    // Jika server tidak aktif, tampilkan dialog modern minimalis
    if (!_isServerReachable) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon di atas dengan latar belakang lingkaran
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                SizedBox(height: 20),

                // Judul dialog
                Text(
                  'Server Tidak Aktif',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 12),

                // Pesan error
                Text(
                  'Tidak dapat menganalisis gambar karena server sedang tidak tersedia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),

                // Garis pemisah
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: Colors.grey[200]),
                ),

                // Tombol-tombol aksi
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Tutup',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _checkServerStatus().then((_) {
                            // Jika setelah cek server sudah aktif, coba analisis lagi
                            if (_isServerReachable) {
                              _analyzeImage();
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Coba Lagi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    print('🔬 Starting image analysis...');
    setState(() => _isLoading = true);

    try {
      final result = await predictionController.predict(_selectedImage!);

      setState(() {
        _isLoading = false;
        _result = result;
        _messages.clear();
        _isChatMinimized = true; // DEFAULT TERTUTUP

        if (result != null && result.expertAdvice != null) {
          _messages.add({
            'isUser': false,
            'message': result.expertAdvice!,
            'timestamp': DateTime.now(),
            'isExpertAdvice': true,
          });
        }
      });

      print('✅ Analysis completed successfully');

      // Jangan auto-expand chat, biarkan user yang buka manual
      _scrollToBottom();
    } catch (e) {
      print('❌ Analysis error: $e');
      setState(() {
        _isLoading = false;
      });

      // Show more specific error message based on error type
      String errorMessage = 'Gagal menganalisis gambar';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection timed out')) {
        errorMessage =
            'Server tidak dapat dijangkau. Periksa koneksi internet atau server sedang tidak aktif.';
      } else if (e.toString().contains('500')) {
        errorMessage =
            'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
      }

      // Show error dialog instead of just a snackbar
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 10),
                Text('Gagal Terhubung'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                SizedBox(height: 10),
                Text(
                  'Detail: ${e.toString().substring(0, min(100, e.toString().length))}...',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Tutup'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _analyzeImage(); // Try again
                },
                child: Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _result == null) return;

    final timestamp = DateTime.now();
    setState(() {
      _messages.add({
        'isUser': true,
        'message': text,
        'timestamp': timestamp,
        'isExpertAdvice': false,
      });
      _isChatLoading = true;
    });
    _messageController.clear();

    _scrollToBottom();

    final response = await chatController.sendMessage(
      text,
      _result!.predictedClass,
    );

    setState(() {
      _messages.add({
        'isUser': false,
        'message':
            response?.answer ??
            'Maaf, terjadi kesalahan saat memproses pertanyaan Anda',
        'timestamp': DateTime.now(),
        'isExpertAdvice': false,
      });
      _isChatLoading = false;
    });

    _scrollToBottom();
  }

  void _toggleChat() {
    setState(() {
      if (_isChatMinimized) {
        // Dari minimized ke half-screen
        _isChatMinimized = false;
        _isChatFullScreen = false;
      } else if (!_isChatFullScreen) {
        // Dari half-screen ke minimized
        _isChatMinimized = true;
        _isChatFullScreen = false;
      } else {
        // Dari full-screen ke minimized
        _isChatMinimized = true;
        _isChatFullScreen = false;
      }
    });

    if (_isChatMinimized) {
      _chatAnimationController.reverse();
    } else {
      _chatAnimationController.forward();
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isChatFullScreen = !_isChatFullScreen;
      if (_isChatFullScreen) {
        _isChatMinimized = false;
      }
    });

    if (!_isChatMinimized) {
      _chatAnimationController.forward();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('dd/MM HH:mm').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}j yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mainScrollController.dispose();
    _messageController.dispose();
    _chatAnimationController.dispose();
    _draggableController.dispose(); // Dispose draggable controller
    super.dispose();
  }

  Widget _buildFormattedExpertAdvice(String advice) {
    List<Widget> widgets = [];
    List<String> lines = advice.split('\n');

    for (String line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(SizedBox(height: 8));
        continue;
      }

      Widget textWidget;

      // Check for section headers (with emojis)
      if (RegExp(r'^[🦠🏠💡👁️⚠️🔧💊🛡️🌾🚨].*:$').hasMatch(line.trim())) {
        textWidget = Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: EdgeInsets.only(top: 8, bottom: 4),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(width: 4, color: primaryColor)),
          ),
          child: Text(
            line.trim(),
            style: TextStyle(
              color: primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        );
      }
      // Check for numbered list items
      else if (RegExp(r'^\d+\.').hasMatch(line.trim())) {
        textWidget = Container(
          padding: EdgeInsets.only(left: 16, right: 8, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: EdgeInsets.only(top: 6, right: 8),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  line.trim().replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      // Check for sub-information (with specific emojis)
      else if (RegExp(r'^[📉⏱️🏪📖🕐💰]').hasMatch(line.trim())) {
        textWidget = Container(
          padding: EdgeInsets.only(left: 16, right: 8, top: 2, bottom: 2),
          child: Text(
            line.trim(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }
      // Regular text
      else {
        textWidget = Container(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            line.trim(),
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13,
              height: 1.4,
            ),
          ),
        );
      }

      widgets.add(textWidget);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  void _showFullScreenImage(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(10),
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.95,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Tutup',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Update method _buildHistoryImageView dengan perbaikan overflow dan display
  Widget _buildHistoryImageView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.grey[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: FutureBuilder<String?>(
          // GUNAKAN future yang sudah dicache
          future: _historyImageUrlFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingImage();
            }

            if (snapshot.hasData && snapshot.data != null) {
              return _buildNetworkImage(snapshot.data!);
            }

            return _buildPlaceholderImage();
          },
        ),
      ),
    );
  }

  Future<String?> _getImageUrl(String predictionId) async {
    try {
      final response = await ApiService().getImageUrl(predictionId);
      return response;
    } catch (e) {
      print('❌ Failed to get image URL: $e');
      return null;
    }
  }

  // Update _buildNetworkImage dengan zoom support seperti _buildImagePickerView
  Widget _buildNetworkImage(String imageUrl) {
    final fullImageUrl = '${ApiService.baseUrl}$imageUrl';

    return GestureDetector(
      onTap: () => _showFullScreenHistoryImage(context, fullImageUrl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                fullImageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildLoadingImage();
                },
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Network image error: $error');
                  return _buildPlaceholderImage();
                },
              ),
            ),

            // Zoom indicator overlay (sama seperti _buildImagePickerView)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.zoom_in, color: Colors.white, size: 16),
              ),
            ),

            // History badge (untuk membedakan dari gambar normal)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Riwayat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simplified full screen image viewer untuk history images (mirip _showFullScreenImage)
  void _showFullScreenHistoryImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(10),
          child: Stack(
            children: [
              // Background tap to close
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),

              // Main image content (simplified)
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.95,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: primaryColor,
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Memuat gambar...',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red[300],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Gagal memuat gambar',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Close button (sama seperti _showFullScreenImage)
              Positioned(
                top: 40,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Tutup',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      alignment: Alignment.center,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat gambar riwayat...',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Pastikan koneksi internet stabil',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.image_outlined,
                  size: 28,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Gambar Diagnosa',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth - 24,
                ),
                child: Text(
                  widget.historyItem!.imageFilename,
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePickerView() {
    return _selectedImage != null
        ? GestureDetector(
            onTap: () => _showFullScreenImage(context),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.zoom_in, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 48,
                  color: Colors.grey[600],
                ),
                SizedBox(height: 8),
                Text(
                  'Tambahkan gambar daun padi',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'untuk diagnosa',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          );
  }

  // Update method _buildPredictionResult untuk show top 3 predictions
  // Update method _buildPredictionResult untuk SELALU show top 3 jika ada
  Widget _buildPredictionResult() {
    if (_result == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Diagnosis Header with better styling
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  accentColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.science_outlined,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Hasil Diagnosa',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          // History indicator
                          if (widget.isHistoryMode) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Riwayat',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        '${_result!.predictedClass}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _result!.confidencePercentage > 70
                        ? Colors.green.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: _result!.confidencePercentage > 70
                          ? Colors.green.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_result!.confidencePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _result!.confidencePercentage > 70
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top 3 Predictions - ALWAYS SHOW if available (baik normal maupun history mode)
          if (_result!.hasTopPredictions) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.bar_chart,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.isHistoryMode
                              ? 'Top 3 Hasil Diagnosa (Riwayat)'
                              : 'Top 3 Kemungkinan Penyakit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // Debug info
                      if (widget.isHistoryMode)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_result!.topPredictions?.length ?? 0}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Show Top 3 predictions
                  ...(_result!.top3Predictions.asMap().entries.map((entry) {
                    int index = entry.key;
                    TopPrediction prediction = entry.value;

                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: index == 0
                            ? primaryColor.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: index == 0
                              ? primaryColor.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? primaryColor
                                  : Colors.grey[600],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              prediction.className,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: index == 0
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getConfidenceColor(
                                prediction.confidence,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${prediction.confidence.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getConfidenceColor(
                                  prediction.confidence,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()),
                ],
              ),
            ),
            SizedBox(height: 16),
          ] else if (widget.isHistoryMode) ...[
            // Show message if no top predictions in history
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Top 3 prediksi tidak tersedia untuk riwayat ini',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Expert Advice Section (tetap sama)
          if (_result!.expertAdvice != null &&
              _result!.expertAdvice!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Saran Ahli Penyuluhan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildFormattedExpertAdvice(_result!.expertAdvice!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Helper method untuk confidence color
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildChatSection() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700; // Threshold for smaller devices

    return AnimatedBuilder(
      animation: _chatAnimation,
      builder: (context, child) {
        return Container(
          height: _isChatMinimized
              ? 60
              : (_isChatFullScreen
                    ? screenHeight *
                          0.75 // Mode fullscreen
                    : screenHeight * (isSmallScreen ? 0.4 : 0.5)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Chat header
              InkWell(
                onTap: _toggleChat,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat, color: primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        widget.isHistoryMode
                            ? 'Konsultasi Lanjutan'
                            : 'Konsultasi Ahli',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // Tambahkan indikator untuk history mode
                      if (widget.isHistoryMode) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Riwayat',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(width: 8),
                      AnimatedRotation(
                        duration: Duration(milliseconds: 300),
                        turns: _isChatMinimized ? 0.5 : 0,
                        child: Icon(
                          Icons.keyboard_arrow_up,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Chat content
              if (!_isChatMinimized)
                Expanded(
                  child: Column(
                    children: [
                      // Messages list
                      Expanded(
                        child: _messages.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        size: 60,
                                        color: Colors.grey[300],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        widget.isHistoryMode
                                            ? 'Lanjutkan konsultasi'
                                            : 'Mulai konsultasi dengan AI',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        widget.isHistoryMode
                                            ? 'Tanyakan lebih lanjut tentang ${_result?.predictedClass ?? "diagnosa ini"}'
                                            : 'Tanyakan tentang penyakit yang terdeteksi\natau cara pengobatannya',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : // Inside the ListView.builder in _buildChatSection() method, update the message bubble:
                              ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                itemCount: _messages.length,
                                itemBuilder: (_, i) {
                                  final msg = _messages[i];
                                  final isUser = msg['isUser'] as bool;
                                  final isExpertAdvice =
                                      msg['isExpertAdvice'] as bool? ?? false;
                                  final isError =
                                      msg['isError'] as bool? ??
                                      false; // Add this line
                                  final timestamp =
                                      msg['timestamp'] as DateTime? ??
                                      DateTime.now();

                                  return Align(
                                    alignment: isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.85,
                                      ),
                                      margin: EdgeInsets.only(
                                        top: 4,
                                        bottom: 4,
                                        left: isUser ? 20 : 0,
                                        right: isUser ? 0 : 20,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isUser
                                            ? userBubbleColor
                                            : (isError
                                                  ? Colors.red.withOpacity(
                                                      0.1,
                                                    ) // Red background for error
                                                  : (isExpertAdvice
                                                        ? primaryColor
                                                              .withOpacity(0.1)
                                                        : botBubbleColor)),
                                        borderRadius: BorderRadius.circular(16)
                                            .copyWith(
                                              bottomRight: isUser
                                                  ? Radius.circular(4)
                                                  : null,
                                              bottomLeft: !isUser
                                                  ? Radius.circular(4)
                                                  : null,
                                            ),
                                        border: isExpertAdvice
                                            ? Border.all(
                                                color: primaryColor.withOpacity(
                                                  0.3,
                                                ),
                                              )
                                            : (isError
                                                  ? Border.all(
                                                      color: Colors.red
                                                          .withOpacity(0.3),
                                                    )
                                                  : null),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 5,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Error label or Expert advice label or history indicator
                                          if (isError) ...[
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  size: 14,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Kesalahan Koneksi',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 6),
                                          ] else if (isExpertAdvice) ...[
                                            // Existing expert advice label code...
                                          ],

                                          // Message content
                                          isUser
                                              ? Text(
                                                  msg['message'],
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    height: 1.4,
                                                  ),
                                                )
                                              : _buildFormattedExpertAdvice(
                                                  msg['message'],
                                                ),

                                          SizedBox(height: 4),

                                          // Timestamp
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Text(
                                              _formatTimestamp(timestamp),
                                              style: TextStyle(
                                                color: isUser
                                                    ? Colors.white.withOpacity(
                                                        0.7,
                                                      )
                                                    : Colors.black54,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      // Loading indicator
                      if (_isChatLoading)
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    primaryColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'AI Ahli sedang mengetik...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Input field - SELALU AKTIF (baik normal maupun history mode)
                      Container(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              offset: Offset(0, -1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: widget.isHistoryMode
                                      ? 'Tanyakan lebih lanjut...'
                                      : 'Ketik pertanyaan...',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide(color: accentColor),
                                  ),
                                ),
                                minLines: 1,
                                maxLines: 3,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: _isChatLoading ? null : _sendMessage,
                                tooltip: 'Kirim Pesan',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToNewDiagnosis() {
    print('🆕 Navigating to new diagnosis with stack clearing...');

    if (widget.isHistoryMode) {
      // History mode: Clear stack dan kembali ke home diagnosis
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => PredictionChatScreen(
            isHistoryMode: false, // Normal mode
          ),
        ),
        (route) =>
            route.isFirst, // Keep only the first route (main/home screen)
      );
    } else {
      // Normal mode: Just reset current screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PredictionChatScreen(isHistoryMode: false),
        ),
      );
    }
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dalam build method, ubah AppBar menjadi:
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.isHistoryMode ? 'Detail Riwayat' : 'Diagnosa & Konsultasi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_isServerReachable) // Tampilkan indikator status server
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Server Offline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        centerTitle: true,
        elevation: 2,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (!_isServerReachable) // Tambahkan tombol refresh untuk server offline
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _checkServerStatus,
              tooltip: 'Periksa Koneksi Server',
            ),
          if (widget.isHistoryMode) ...[
            IconButton(
              icon: Icon(Icons.add_circle_outline),
              onPressed: _navigateToNewDiagnosis,
              tooltip: 'Diagnosa Baru',
            ),
            SizedBox(width: 8),
          ],
          if (!widget.isHistoryMode) ...[
            IconButton(
              icon: Icon(Icons.history),
              onPressed: _navigateToHistory,
              tooltip: 'Lihat Riwayat',
            ),
          ],
        ],
      ),
      backgroundColor: backgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              // Main scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: _mainScrollController,
                  child: Column(
                    children: [
                      // Image picker & prediction area (modified for history)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // History date info jika dalam mode history
                            if (widget.isHistoryMode) ...[
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: primaryColor.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.history,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Diagnosa pada ${DateFormat('dd MMMM yyyy, HH:mm').format(widget.historyItem!.createdAt)}',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // FIXED IMAGE CONTAINER - Height yang lebih responsif
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Tentukan height berdasarkan kondisi
                                double imageHeight;
                                if (widget.isHistoryMode) {
                                  // History mode: height berdasarkan screen size
                                  imageHeight =
                                      MediaQuery.of(context).size.height *
                                      0.15; // 15% of screen height
                                  imageHeight = imageHeight.clamp(
                                    100.0,
                                    160.0,
                                  ); // Min 100, max 160
                                } else if (_result != null) {
                                  // Normal mode dengan result
                                  imageHeight = 120;
                                } else {
                                  // Normal mode tanpa result
                                  imageHeight = 200;
                                }

                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  height: imageHeight,
                                  width: double.infinity,
                                  margin: EdgeInsets.all(16),
                                  child: widget.isHistoryMode
                                      ? _buildHistoryImageView()
                                      : _buildImagePickerView(),
                                );
                              },
                            ),

                            // Camera/Gallery buttons (hide in history mode)
                            if (!widget.isHistoryMode) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _pickImage(ImageSource.camera),
                                        icon: Icon(Icons.camera_alt, size: 18),
                                        label: Text('Kamera'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: accentColor,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _pickImage(ImageSource.gallery),
                                        icon: Icon(
                                          Icons.photo_library,
                                          size: 18,
                                        ),
                                        label: Text('Galeri'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: accentColor,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Analyze button
                              if (_selectedImage != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    child: ElevatedButton(
                                      onPressed:
                                          (_selectedImage == null || _isLoading)
                                          ? null
                                          : _analyzeImage,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isLoading
                                            ? primaryColor.withOpacity(0.7)
                                            : primaryColor,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                            Colors.grey[300],
                                        disabledForegroundColor:
                                            Colors.grey[600],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        elevation: _isLoading ? 0 : 2,
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: Duration(milliseconds: 200),
                                        child: _isLoading
                                            ? Row(
                                                key: ValueKey('loading'),
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2.0,
                                                        ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    'Menganalisis...',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                key: ValueKey('analyze'),
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.science_outlined,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Analisis Penyakit',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),

                      // Enhanced Prediction result display
                      if (_result != null) _buildPredictionResult(),

                      // Add bottom padding when chat is minimized
                      if (_result != null && _isChatMinimized)
                        SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Chat section (disable input in history mode)
              if (_result != null) _buildChatSection(),
            ],
          ),
        ),
      ),
    );
  }
}
