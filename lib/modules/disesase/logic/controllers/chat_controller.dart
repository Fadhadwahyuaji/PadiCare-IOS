import '../services/api_service.dart';
import '../models/chat_model.dart';

class ChatController {
  final ApiService _apiService = ApiService();

  Future<ChatResponse?> sendMessage(
    String question,
    String diseaseContext,
  ) async {
    return await _apiService.chatWithExpert(question, diseaseContext);
  }

  Future<void> clearSession() async {
    return await _apiService.clearSession();
  }
}
