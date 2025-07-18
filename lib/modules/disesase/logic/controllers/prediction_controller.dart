import 'dart:io';
import '../services/api_service.dart';
import '../models/prediction_model.dart';

class PredictionController {
  final ApiService _apiService = ApiService();

  Future<PredictionResult?> predict(File imageFile) async {
    try {
      // Validasi file
      if (!await imageFile.exists()) {
        print('❌ Image file does not exist');
        return null;
      }

      final fileSize = await imageFile.length();
      print('📊 Image file size: $fileSize bytes');

      if (fileSize == 0) {
        print('❌ Image file is empty');
        return null;
      }

      if (fileSize > 10 * 1024 * 1024) {
        // 10MB limit
        return null;
      }

      // Debug server connection first
      // await _apiService.debugServerConnection();

      // Proceed with prediction
      return await _apiService.predictImage(imageFile);
    } catch (e) {
      print('❌ Error in prediction controller: $e');
      return null;
    }
  }
}
