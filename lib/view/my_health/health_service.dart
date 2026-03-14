import 'package:supabase_flutter/supabase_flutter.dart';

class HealthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Save or update health data (now without calories parameter)
  Future<void> saveHealthData({
    required double weight,
    required double height,
    required int age,
  }) async {
    // Get calorie estimate before saving
    final estimatedCalories = await getUserCalorie();

    await _supabase.from('user_health').upsert({
      'id': _supabase.auth.currentUser!.id,
      'weight_kg': weight,
      'height_cm': height,
      'age': age,
      'last_calorie_intake': estimatedCalories,
      'last_updated': DateTime.now().toIso8601String(),
    });
  }

  // Get user's estimated calories based on yesterday's orders
  Future<int?> getUserCalorie() async {
    try {
      // Get current time and 24 hours ago
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

      // Query orders from yesterday
      final response = await _supabase
          .from('order_history')
          .select('total_amount')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .gte('created_at', twentyFourHoursAgo.toIso8601String())
          .lt('created_at', now.toIso8601String());

      if (response.isEmpty) return null;

      // Calculate total spent and convert to calories (0.7 calories per currency unit)
      double totalSpent = 0;
      for (var order in response) {
        totalSpent += (order['total_amount'] as num).toDouble();
      }

      return (totalSpent * 7).round();
    } catch (e) {
      print('Error calculating calories: $e');
      return null;
    }
  }

  // Get user's estimated calories based on yesterday's orders
  Future<void> updateUserCalorie() async {
    try {
      // Get current time and 24 hours ago
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

      // Query orders from yesterday
      final response = await _supabase
          .from('order_history')
          .select('total_amount')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .gte('created_at', twentyFourHoursAgo.toIso8601String())
          .lt('created_at', now.toIso8601String());

      if (response.isEmpty) return null;

      // Calculate total spent and convert to calories (7 kcal per currency unit)
      double totalSpent = 0;
      for (var order in response) {
        totalSpent += (order['total_amount'] as num).toDouble();
      }
      final estimatedCalories = (totalSpent * 7).round();

      // Update the user's health record with new calorie data
      await _supabase.from('user_health').upsert({
        'id': _supabase.auth.currentUser!.id,
        'last_calorie_intake': estimatedCalories,
        'last_updated': DateTime.now().toIso8601String(),
      });

      return;
    } catch (e) {
      print('Error calculating calories: $e');
      return null;
    }
  }

  // Get current health data
  Future<Map<String, dynamic>?> getHealthData() async {
    final response = await _supabase
        .from('user_health')
        .select()
        .eq('id', _supabase.auth.currentUser!.id)
        .maybeSingle();

    return response;
  }

  // Calculate BMI
  Future<double?> calculateBMI() async {
    final data = await getHealthData();
    if (data == null || data['weight_kg'] == null || data['height_cm'] == null) {
      return null;
    }
    final heightM = data['height_cm'] / 100;
    return data['weight_kg'] / (heightM * heightM);
  }

  // Save generated tip
  Future<void> saveHealthTip(String tip, double bmi) async {
    await _supabase.from('health_tips').insert({
      'user_id': _supabase.auth.currentUser!.id,
      'tip_text': tip,
      'bmi': bmi,
    });
  }

  // Get latest tips
  Future<List<Map<String, dynamic>>> getHealthTips() async {
    final response = await _supabase
        .from('health_tips')
        .select()
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('generated_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createDefaultHealthData(String userId) async {
    // Default values
    final defaultWeight = 70.0;
    final defaultHeight = 170.0;
    final heightInMeters = defaultHeight / 100;
    final defaultBmi = defaultWeight / (heightInMeters * heightInMeters);

    const defaultTip = '''
    Welcome to your health journey! Here are some general tips to get started:
    1. Aim for 7-9 hours of sleep each night
    2. Drink at least 2 liters of water daily
    3. Include fruits and vegetables in every meal
    4. Start with 30 minutes of moderate activity daily
    ''';

    // Create health profile
    await _supabase.from('user_health').upsert({
      'id': userId,
      'weight_kg': defaultWeight,
      'height_cm': defaultHeight,
      'age': 25,
      'last_calorie_intake': 100,
    });

    // Create default health tip
    await _supabase.from('health_tips').insert({
      'user_id': userId,
      'tip_text': defaultTip,
      'bmi': defaultBmi,
    });
  }
}