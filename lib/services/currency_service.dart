import 'dart:convert';

import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl =
      'https://api.frankfurter.app/latest';

  /// Converts an amount from one currency to another.
  Future<double> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    final fromCurrency = from.trim().toUpperCase();
    final toCurrency = to.trim().toUpperCase();

    // No conversion needed.
    if (fromCurrency == toCurrency) {
      return amount;
    }

    final uri = Uri.parse(
      '$_baseUrl?amount=$amount&from=$fromCurrency&to=$toCurrency',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Could not fetch exchange rate.',
      );
    }

    final data =
        jsonDecode(response.body) as Map<String, dynamic>;

    final rates =
        data['rates'] as Map<String, dynamic>?;

    if (rates == null) {
      throw Exception(
        'Invalid exchange rate response.',
      );
    }

    final result = rates[toCurrency];

    if (result == null) {
      throw Exception(
        'No exchange rate available for '
        '$fromCurrency → $toCurrency.',
      );
    }

    return (result as num).toDouble();
  }
}