// lib/utils/app_prefs.dart
import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const String _firstLaunchKey = 'firstLaunchCompleted';
  static const String _itemPropertiesKey = 'itemProperties';
  static const String _useCardLayoutKey = 'useCardLayout';
  static const String _quantityDecimalsKey = 'quantityDecimals';
  static const String _selectedStoreIdKey = 'selectedStoreId'; // Para Fase 1.2

  // Constantes para nomes de propriedades (evita erros de digitação)
  static const String propName = 'name';
  static const String propCategory = 'category';
  static const String propQuantity = 'quantity';
  static const String propImage = 'image';
  static const String propBarcode = 'barcode';
  static const String propDescription = 'description';
  static const String propTags = 'tags';
  static const String propUom = 'uom'; // Unit of Measure
  static const String propMinStock = 'minStock';

  static Future<SharedPreferences> _getPrefs() async {
    return SharedPreferences.getInstance();
  }

  // --- First Launch ---
  static Future<bool> isFirstLaunch() async {
    final prefs = await _getPrefs();
    return !(prefs.getBool(_firstLaunchKey) ?? false);
  }

  static Future<void> setFirstLaunchCompleted(bool completed) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_firstLaunchKey, completed);
  }

  // --- Item Properties ---
  static Future<List<String>> getItemProperties() async {
    final prefs = await _getPrefs();
    // Retorna uma lista padrão se nada estiver salvo ainda
    return prefs.getStringList(_itemPropertiesKey) ??
        [propName, propQuantity, propCategory, propImage]; // Padrão inicial
  }

  static Future<void> setItemProperties(List<String> properties) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(_itemPropertiesKey, properties);
  }

  // --- Layout Preference ---
  static Future<bool> getUseCardLayout() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_useCardLayoutKey) ?? false; // Padrão: Lista
  }

   static Future<void> setUseCardLayout(bool useCards) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_useCardLayoutKey, useCards);
  }

   // --- Quantity Decimals ---
  static Future<int> getQuantityDecimals() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_quantityDecimalsKey) ?? 0; // Padrão: 0
  }

   static Future<void> setQuantityDecimals(int decimals) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_quantityDecimalsKey, decimals);
  }

  // --- Selected Store (Para o futuro) ---
   static Future<int?> getSelectedStoreId() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_selectedStoreIdKey); // Pode ser null se nenhuma selecionada
  }

   static Future<void> setSelectedStoreId(int? storeId) async {
     final prefs = await _getPrefs();
     if (storeId == null) {
       await prefs.remove(_selectedStoreIdKey);
     } else {
       await prefs.setInt(_selectedStoreIdKey, storeId);
     }
   }
}