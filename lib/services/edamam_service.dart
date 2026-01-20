import 'dart:convert';
import 'package:http/http.dart' as http;

class EdamamService {
  static const String _appId = 'eabb9297';
  static const String _appKey = 'aae21ab029fd618761b7c7f48d0d5d31';
  static const String _baseUrl = 'https://api.edamam.com/api/nutrition-details';

  // Daily Reference Intakes
  static const Map<String, double> _dris = {
    'ENERC_KCAL': 2000,
    'FAT': 78,
    'FASAT': 20,
    'CHOLE': 300,
    'NA': 2300,
    'CHOCDF': 275,
    'FIBTG': 28,
    'PROCNT': 50,
    'VITD': 20,
    'CA': 1300,
    'FE': 18,
    'K': 4700,
  };

  /// Call Edamam API and aggregate nutrition data
  Future<NutritionResult?> getNutritionFacts(String ingredientString) async {
    try {
      // Parse ingredient string and ensure each has a quantity
      final ingredientsList = ingredientString
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (ingredientsList.isEmpty) {
        print('❌ No ingredients provided.');
        return null;
      }

      // Call Edamam API
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        'title': 'Food',
        'ingr': ingredientsList,
      });

      final uri = Uri.parse('$_baseUrl?app_id=$_appId&app_key=$_appKey');
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode != 200) {
        print('❌ Edamam error: ${response.statusCode} - ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Aggregate nutrients from all parsed ingredients
      final totalNutrients = <String, NutrientData>{};
      final ingredientBreakdowns = <IngredientBreakdown>[];

      for (final ing in (data['ingredients'] as List? ?? [])) {
        if (ing is Map && ing['parsed'] is List) {
          final parsedList = ing['parsed'] as List;
          if (parsedList.isNotEmpty) {
            final parsed = parsedList[0] as Map<String, dynamic>;
            final nutrients =
                (parsed['nutrients'] as Map<String, dynamic>? ?? {});

            // Add ingredient breakdown
            ingredientBreakdowns.add(
              IngredientBreakdown.fromJson(parsed),
            );

            // Aggregate nutrients
            nutrients.forEach((code, nutrientData) {
              if (nutrientData is Map) {
                final quantity =
                    (nutrientData['quantity'] as num?)?.toDouble() ?? 0.0;
                final label = nutrientData['label'] as String? ?? code;
                final unit = nutrientData['unit'] as String? ?? '';

                if (totalNutrients[code] == null) {
                  totalNutrients[code] = NutrientData(
                    code: code,
                    label: label,
                    quantity: quantity,
                    unit: unit,
                  );
                } else {
                  totalNutrients[code]!.quantity += quantity;
                }
              }
            });
          }
        }
      }

      if (totalNutrients.isEmpty) {
        print('❌ No nutrients found in Edamam response.');
        return null;
      }

      return NutritionResult(
        nutrients: totalNutrients,
        ingredients: ingredientBreakdowns,
      );
    } catch (e) {
      print('❌ Error calling Edamam: $e');
      return null;
    }
  }
}

/// Single nutrient with quantity and unit
class NutrientData {
  final String code;
  final String label;
  double quantity;
  final String unit;

  NutrientData({
    required this.code,
    required this.label,
    required this.quantity,
    required this.unit,
  });

  /// Daily Value percentage (based on DRI)
  double get dailyValuePercent {
    final dri = EdamamService._dris[code];
    if (dri == null || dri == 0) return 0;
    return (quantity / dri * 100).roundToDouble();
  }

  double roundToDouble() => double.parse(quantity.toStringAsFixed(1));
}

/// Per-ingredient nutrition breakdown
class IngredientBreakdown {
  final String name;
  final double weight;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;

  IngredientBreakdown({
    required this.name,
    required this.weight,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  factory IngredientBreakdown.fromJson(Map<String, dynamic> json) {
    final nutrients = (json['nutrients'] as Map<String, dynamic>? ?? {});
    return IngredientBreakdown(
      name: json['food'] as String? ?? 'Unknown',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      calories:
          (nutrients['ENERC_KCAL']?['quantity'] as num?)?.toDouble() ?? 0.0,
      carbs: (nutrients['CHOCDF']?['quantity'] as num?)?.toDouble() ?? 0.0,
      protein: (nutrients['PROCNT']?['quantity'] as num?)?.toDouble() ?? 0.0,
      fat: (nutrients['FAT']?['quantity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Complete nutrition analysis result
class NutritionResult {
  final Map<String, NutrientData> nutrients;
  final List<IngredientBreakdown> ingredients;

  NutritionResult({
    required this.nutrients,
    required this.ingredients,
  });

  /// Convenient getters for common nutrients
  double? get calories => nutrients['ENERC_KCAL']?.quantity;
  double? get protein => nutrients['PROCNT']?.quantity;
  double? get carbs => nutrients['CHOCDF']?.quantity;
  double? get fat => nutrients['FAT']?.quantity;
  double? get fiber => nutrients['FIBTG']?.quantity;
  double? get sodium => nutrients['NA']?.quantity;
}
