import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Gets the current device location (updated for geolocator ^14.0.0)
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await _checkLocationPermissions();
      if (!hasPermission) return null;

      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0, // Update location even if no movement
      );

      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Converts coordinates to a readable address
  Future<String?> getAddressFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode
        ].where((part) => part?.isNotEmpty ?? false).join(', ');
      }
      return null;
    } catch (e) {
      print('Error converting location to address: $e');
      return null;
    }
  }

  /// Updates user's location in Supabase
  Future<bool> updateUserLocation() async {
    try {
      final position = await getCurrentLocation();
      if (position == null) return false;

      final address = await getAddressFromPosition(position);
      if (address == null) return false;

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('profiles').upsert({
        'id': userId,
        'address': address,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error updating location: $e');
      return false;
    }
  }

  /// Checks and requests location permissions
  Future<bool> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
      return false;
    }

    return true;
  }

  /// Shows a dialog requesting location access
  static Future<bool> showLocationRequestDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Access Needed'),
        content: const Text(
          'To provide accurate delivery estimates and show nearby restaurants, '
              'we need access to your location. You can change this later in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    ) ?? false; // Returns false if dialog is dismissed
  }
}