import 'dart:ui';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../view/my_health/health_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final HealthService _healthService = HealthService();

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
    String name,
    String mobile,
    String address,
  ) async {
    // 1. Create user with email/password
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    // 2. If sign-up successful, store additional user data
    if (authResponse.user != null) {
      await _supabase.from('profiles').upsert({
        'id': authResponse.user!.id,
        'email': email,
        'name': name,
        'mobile': mobile,
        'address': address,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    
    await _healthService.createDefaultHealthData(authResponse.user!.id);
    return authResponse;
  }

  // Add this method to get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return response;
  }

  // Add this to your AuthService class
  Future<void> updateProfile({
    required String name,
    required String mobile,
    required String address,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _supabase.from('profiles').upsert({
      'id': userId,
      'name': name,
      'mobile': mobile,
      'address': address,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get user email
  String? getCurrentUserEmail() {
      final session = _supabase.auth.currentSession;
      final user = session?.user;
      return user?.email;
  }
}
