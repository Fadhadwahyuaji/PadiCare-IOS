class ChatHistory {
  final double? timestamp;
  final String? type;
  final String? question;
  final String? answer;

  ChatHistory({this.timestamp, this.type, this.question, this.answer});

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      timestamp: (json['timestamp'] ?? 0.0).toDouble(),
      type: json['type'],
      question: json['question'],
      answer: json['answer'],
    );
  }
}

class ChatResponse {
  final String answer;
  final String? error;

  ChatResponse({required this.answer, this.error});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(answer: json['answer'] ?? '', error: json['error']);
  }
}
