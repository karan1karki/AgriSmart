// lib/core/services/soil_analysis.dart
import 'dart:typed_data'; // Required for Float32List
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SoilAnalysisService {
  // Label arrays matching your Python LabelEncoder definitions exactly
  static const List<String> _soilLabels = ['Black', 'Clayey', 'Loamy', 'Sandy'];
  static const List<String> _fertilizerLabels = ['10-26-26', '14-35-14', '28-28-0', 'DAP', 'Urea'];

  /// Runs complete on-device sequential multi-stage Random Forest inference
  Future<Map<String, dynamic>> predictSoilMetrics({
    required double temperature,
    required double humidity,
    required double nitrogen,
    required double phosphorous,
    required double potassium,
  }) async {
    
    // Initialize the ONNX environment
    OrtEnv.instance.init();

    try {
      // 1. Force values into explicit 32-bit Float lists to avoid the "Expected: tensor(float)" error
      final Float32List baseInputFeatures = Float32List.fromList([
        temperature, 
        humidity, 
        nitrogen, 
        phosphorous, 
        potassium
      ]);
      final List<int> baseShape = [1, 5]; // 1 Row, 5 Columns

      // =======================================================================
      // STEP A: PREDICT SOIL TYPE
      // =======================================================================
      final soilModelBytes = await rootBundle.load('assets/ml/rf_soil_classifier.onnx');
      final soilSession = OrtSession.fromBuffer(soilModelBytes.buffer.asUint8List(), OrtSessionOptions());
      
      final soilTensor = OrtValueTensor.createTensorWithDataList(baseInputFeatures, baseShape);
      final soilOutputs = soilSession.run(OrtRunOptions(), {'float_input': soilTensor});
      
      // Safe unpacking of nested 2D array output (translating the Streamlit numpy extraction)
      final List<dynamic> rawSoilOuter = soilOutputs[0]?.value as List<dynamic>;
      final List<dynamic> rawSoilInner = rawSoilOuter.first as List<dynamic>;
      final int soilIndex = rawSoilInner.first as int;
      final String predictedSoilType = _soilLabels[soilIndex];

      // =======================================================================
      // STEP B: PREDICT MOISTURE REGRESSION
      // =======================================================================
      final moistureModelBytes = await rootBundle.load('assets/ml/rf_moisture_regressor.onnx');
      final moistureSession = OrtSession.fromBuffer(moistureModelBytes.buffer.asUint8List(), OrtSessionOptions());
      
      final moistureOutputs = moistureSession.run(OrtRunOptions(), {'float_input': soilTensor});
      
      // Safe unpacking of the regression continuous list layer (solves the 0-dim scalar issue)
      final List<dynamic> rawMoistureOuter = moistureOutputs[0]?.value as List<dynamic>;
      final List<dynamic> rawMoistureInner = rawMoistureOuter.first as List<dynamic>;
      final double predictedMoisture = rawMoistureInner.first as double;

      // Clean up step references before moving to fertilizer
      soilTensor.release();
      soilSession.release();
      moistureSession.release();

      // =======================================================================
      // STEP C: PREDICT FERTILIZER RECOMMENDATION
      // =======================================================================
      // Expects 6 columns: [Temparature, Humidity, Moisture, Nitrogen, Phosphorous, Potassium]
      final Float32List fertInputFeatures = Float32List.fromList([
        temperature, 
        humidity, 
        predictedMoisture, 
        nitrogen, 
        phosphorous, 
        potassium
      ]);
      final List<int> fertShape = [1, 6];

      final fertModelBytes = await rootBundle.load('assets/ml/rf_fertilizer_classifier.onnx');
      final fertSession = OrtSession.fromBuffer(fertModelBytes.buffer.asUint8List(), OrtSessionOptions());
      
      final fertTensor = OrtValueTensor.createTensorWithDataList(fertInputFeatures, fertShape);
      final fertOutputs = fertSession.run(OrtRunOptions(), {'float_input': fertTensor});
      
      // Safe unpacking of nested classifier array
      final List<dynamic> rawFertOuter = fertOutputs[0]?.value as List<dynamic>;
      final List<dynamic> rawFertInner = rawFertOuter.first as List<dynamic>;
      final int fertIndex = rawFertInner.first as int;
      final String recommendedFertilizer = _fertilizerLabels[fertIndex];

      // Final resource clean up
      fertTensor.release();
      fertSession.release();

      // Return evaluation matrix payload down to UI layout screens
      return {
        'status': 'success',
        'detected_soil_type': predictedSoilType,
        'calculated_moisture': "${predictedMoisture.toStringAsFixed(1)}%",
        'recommended_fertilizer': recommendedFertilizer,
        'action_tip': "On-device compilation complete. Model suggests deploying $recommendedFertilizer for optimal yields."
      };

    } catch (e) {
      print("On-device inference execution crash vector: $e");
      return {
        'status': 'error',
        'message': 'Failed running internal ML model parsing pipeline.'
      };
    } finally {
      // Release ONNX Environment variables securely
      OrtEnv.instance.release();
    }
  }
}



class ApiService {
  // 📍 Replace with your computer's actual local IP address
  static const String baseUrl = 'http://192.168.X.X:8000'; 

  /// Sends location to FastAPI and returns satellite metrics + crop recommendation
  Future<Map<String, dynamic>> fetchCropRecommendation(String location) async {
    final url = Uri.parse('$baseUrl/api/analyze-location');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'location': location}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }
}
