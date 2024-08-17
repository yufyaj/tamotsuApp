import 'package:flutter/foundation.dart';
import 'package:tamotsu/services/nutritionist_service.dart';

class NutritionistViewModel extends ChangeNotifier {
  final NutritionistService _nutritionistService;

  NutritionistViewModel({required NutritionistService nutritionistService})
      : _nutritionistService = nutritionistService;

  Map<String, dynamic>? _nutritionistProfile;
  Map<String, dynamic>? get nutritionistProfile => _nutritionistProfile;

  Map<String, dynamic>? _publicProfile;
  Map<String, dynamic>? get publicProfile => _publicProfile;

  List<Map<String, dynamic>> _nutritionistList = [];
  List<Map<String, dynamic>> get nutritionistList => _nutritionistList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchNutritionistProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _nutritionistProfile = await _nutritionistService.getNutritionistProfile();
    } catch (e) {
      print('Error fetching nutritionist profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateNutritionistProfile(Map<String, dynamic> profileData) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _nutritionistService.updateNutritionistProfile(profileData);
      await fetchNutritionistProfile();
      return true;
    } catch (e) {
      print('Error updating nutritionist profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNutritionistPublicProfile(String nutritionistId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _publicProfile = await _nutritionistService.getNutritionistPublicProfile(nutritionistId);
    } catch (e) {
      print('Error fetching nutritionist public profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNutritionistList({
    String? search,
    int page = 1,
    int perPage = 10,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _nutritionistService.getNutritionistList(
        search: search,
        page: page,
        perPage: perPage,
      );
      _nutritionistList.addAll(List<Map<String, dynamic>>.from(result['nutritionists']));
    } catch (e) {
      print('Error fetching nutritionist list: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearNutritionistList() async {
    _nutritionistList.clear();
  }
}
