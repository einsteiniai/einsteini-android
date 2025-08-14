import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../utils/permission_utils.dart';
import '../constants/app_constants.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final ApiService _apiService = ApiService();
  String? _cachedCountry;
  
  /// Get user's country code for pricing (returns 'inr' for India, 'usd' for others)
  Future<String> getUserCountry() async {
    // Return cached result if available
    if (_cachedCountry != null) {
      print('LocationService: Using cached country: $_cachedCountry');
      return _cachedCountry!;
    }

    try {
      // Check if location permission is granted
      bool hasPermission = await PermissionUtils.checkPermissionGranted(AppPermission.location);
      if (!hasPermission) {
        print('LocationService: No location permission, defaulting to USD');
        // Default to USD if no permission
        _cachedCountry = 'usd';
        return _cachedCountry!;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );

      print('LocationService: Got position - lat: ${position.latitude}, lon: ${position.longitude}');

      // Get country info from backend
      final locationInfo = await _apiService.getLocationInfo(
        position.latitude,
        position.longitude,
      );

      print('LocationService: Backend response: $locationInfo');

      if (locationInfo['success'] == true) {
        _cachedCountry = locationInfo['country'] ?? 'usd';
        print('LocationService: Country detected: $_cachedCountry');
      } else {
        _cachedCountry = 'usd';
        print('LocationService: Backend failed, defaulting to USD');
      }
    } catch (e) {
      print('LocationService: Error occurred: $e');
      // Default to USD on any error
      _cachedCountry = 'usd';
    }

    print('LocationService: Final country result: $_cachedCountry');
    return _cachedCountry!;
  }

  /// Clear cached country (useful for testing or when user changes location)
  void clearCache() {
    _cachedCountry = null;
  }

  /// Check if user is in India (for INR pricing)
  Future<bool> isIndianUser() async {
    final country = await getUserCountry();
    return country.toLowerCase() == 'inr';
  }
}
