// COMPLETELY SIMPLIFIED - NO STATS
import 'dart:convert';
import 'dart:ui' show Color;
import 'package:flutter/material.dart' show Colors;

// Import TopPrediction from prediction_model
import 'prediction_model.dart';

class HistoryResponse {
  final bool success;
  final List<PredictionHistoryItem> history;
  final HistoryPagination pagination;

  HistoryResponse({
    required this.success,
    required this.history,
    required this.pagination,
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Parsing COMPLETELY SIMPLIFIED HistoryResponse...');

      // Parse history items
      List<PredictionHistoryItem> historyItems = [];
      if (json['history'] != null) {
        for (var i = 0; i < json['history'].length; i++) {
          try {
            var item = json['history'][i];
            if (item is Map<String, dynamic>) {
              historyItems.add(PredictionHistoryItem.fromJson(item));
            }
          } catch (itemError) {
            print('❌ Error parsing history item $i: $itemError');
          }
        }
      }

      // Parse pagination
      HistoryPagination pagination;
      try {
        if (json['pagination'] != null &&
            json['pagination'] is Map<String, dynamic>) {
          pagination = HistoryPagination.fromJson(json['pagination']);
        } else {
          pagination = HistoryPagination.empty();
        }
      } catch (paginationError) {
        print('⚠️ Pagination parsing error: $paginationError');
        pagination = HistoryPagination.empty();
      }

      print(
        '✅ SIMPLIFIED HistoryResponse parsed successfully: ${historyItems.length} items',
      );

      return HistoryResponse(
        success: json['success'] ?? false,
        history: historyItems,
        pagination: pagination,
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing SIMPLIFIED HistoryResponse: $e');
      print('🔍 StackTrace: $stackTrace');
      rethrow;
    }
  }
}

class PredictionHistoryItem {
  final String id;
  final String imageFilename;
  final String predictedClass;
  final double confidencePercentage;
  final String? expertAdvice;
  final DateTime createdAt;
  final double? processingTime;
  final List<ChatMessageItem> chatMessages;
  final List<TopPrediction>? topPredictions;

  PredictionHistoryItem({
    required this.id,
    required this.imageFilename,
    required this.predictedClass,
    required this.confidencePercentage,
    this.expertAdvice,
    required this.createdAt,
    this.processingTime,
    required this.chatMessages,
    this.topPredictions,
  });

  factory PredictionHistoryItem.fromJson(Map<String, dynamic> json) {
    try {
      // Parse chat messages dengan improved error handling
      List<ChatMessageItem> messages = [];

      if (json['chat_messages'] != null) {
        print(
          '📊 Raw chat_messages type: ${json['chat_messages'].runtimeType}',
        );
        print('📊 Raw chat_messages: ${json['chat_messages']}');

        var chatData = json['chat_messages'];

        // Handle different data types
        if (chatData is String) {
          try {
            chatData = jsonDecode(chatData);
          } catch (e) {
            print('❌ Error parsing chat_messages JSON string: $e');
            chatData = [];
          }
        }

        if (chatData is List) {
          print('📊 Processing ${chatData.length} chat messages...');

          for (var i = 0; i < chatData.length; i++) {
            try {
              var msgData = chatData[i];
              if (msgData != null && msgData is Map<String, dynamic>) {
                var chatMessage = ChatMessageItem.fromJson(msgData);
                messages.add(chatMessage);
                print(
                  '✅ Parsed chat message $i: ${chatMessage.isUser ? "User" : "Bot"}',
                );
              } else {
                print('⚠️ Invalid chat message format at index $i: $msgData');
              }
            } catch (msgError) {
              print('❌ Error parsing chat message at index $i: $msgError');
            }
          }
        } else {
          print('⚠️ chat_messages is not a List: ${chatData.runtimeType}');
        }
      } else {
        print('⚠️ No chat_messages found in JSON');
      }

      print('✅ Successfully parsed ${messages.length} chat messages');

      // Parse created_at
      DateTime createdAt;
      try {
        if (json['created_at'] is String) {
          createdAt = DateTime.parse(json['created_at']);
        } else {
          createdAt = DateTime.now();
        }
      } catch (dateError) {
        print('⚠️ Date parsing error: $dateError');
        createdAt = DateTime.now();
      }

      // Parse top predictions
      // Parse top predictions
      List<TopPrediction>? topPredictions;
      if (json['top_predictions'] != null && json['top_predictions'] is List) {
        try {
          topPredictions = (json['top_predictions'] as List)
              .asMap()
              .entries
              .map((entry) {
                var predData = entry.value;
                if (predData is Map<String, dynamic>) {
                  if (!predData.containsKey('rank')) {
                    predData['rank'] = entry.key + 1;
                  }
                  return TopPrediction.fromJson(predData);
                }
                return null;
              })
              .where((pred) => pred != null)
              .cast<TopPrediction>()
              .toList();
        } catch (e) {
          print('❌ Error parsing top_predictions: $e');
          topPredictions = null;
        }
      }

      return PredictionHistoryItem(
        id: json['id']?.toString() ?? '',
        imageFilename: json['image_filename']?.toString() ?? '',
        predictedClass: json['predicted_class']?.toString() ?? '',
        confidencePercentage: (json['confidence_percentage'] ?? 0.0).toDouble(),
        expertAdvice: json['expert_advice']?.toString(),
        createdAt: createdAt,
        processingTime: json['processing_time']?.toDouble(),
        chatMessages: messages, // PASTIKAN MESSAGES DISET
        topPredictions: topPredictions,
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing PredictionHistoryItem: $e');
      print('🔍 StackTrace: $stackTrace');
      print('📄 Raw JSON: $json');
      rethrow;
    }
  }

  // Helper methods
  String get diseaseCategory {
    if (predictedClass.toLowerCase().contains('sehat') ||
        predictedClass.toLowerCase().contains('harvest') ||
        predictedClass.toLowerCase().contains('normal')) {
      return 'Sehat';
    }
    return 'Penyakit';
  }

  bool get isHealthy => diseaseCategory == 'Sehat';

  Color get confidenceColor {
    if (confidencePercentage >= 80) return Colors.green;
    if (confidencePercentage >= 60) return Colors.orange;
    return Colors.red;
  }

  // Top predictions helpers
  bool get hasTopPredictions =>
      topPredictions != null && topPredictions!.isNotEmpty;

  List<TopPrediction> get top3Predictions {
    if (!hasTopPredictions) return [];
    return topPredictions!.take(3).toList();
  }
}

class ChatMessageItem {
  final String id;
  final String message;
  final bool isUser;
  final DateTime createdAt;
  final String? responseSource;

  ChatMessageItem({
    required this.id,
    required this.message,
    required this.isUser,
    required this.createdAt,
    this.responseSource,
  });

  factory ChatMessageItem.fromJson(Map<String, dynamic> json) {
    try {
      DateTime createdAt;
      try {
        if (json['created_at'] != null && json['created_at'] is String) {
          createdAt = DateTime.parse(json['created_at']);
        } else {
          createdAt = DateTime.now();
        }
      } catch (e) {
        print('⚠️ Date parsing error in ChatMessageItem: $e');
        createdAt = DateTime.now();
      }

      return ChatMessageItem(
        id: json['id']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        isUser: json['is_user'] ?? false,
        createdAt: createdAt,
        responseSource: json['response_source']?.toString(),
      );
    } catch (e) {
      print('❌ Error parsing ChatMessageItem: $e');
      print('📄 Raw JSON: $json');
      rethrow;
    }
  }
}

class HistoryPagination {
  final int limit;
  final int offset;
  final int total;
  final bool hasMore;

  HistoryPagination({
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
  });

  factory HistoryPagination.fromJson(Map<String, dynamic> json) {
    return HistoryPagination(
      limit: json['limit'] ?? 20,
      offset: json['offset'] ?? 0,
      total: json['total'] ?? 0,
      hasMore: json['has_more'] ?? false,
    );
  }

  factory HistoryPagination.empty() {
    return HistoryPagination(limit: 20, offset: 0, total: 0, hasMore: false);
  }
}
