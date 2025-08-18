import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ipo_model.dart';
import '../config/app_config.dart';

class ApiService {
  static const String baseUrl = AppConfig.apiBaseUrl;
  static const Duration timeoutDuration = AppConfig.apiTimeout;

  // GET /api/ipos/company/:companyId – Fetch IPO data for a specific company
  static Future<IpoModel> getIpoByCompanyId(String companyId) async {
    try {
      // debugPrint('DEBUG API: Fetching IPO for company ID: $companyId');
      // debugPrint(
      //     'DEBUG API: Request URL: $baseUrl/api/ipos/company/$companyId');

      final response = await http.get(
        Uri.parse('$baseUrl/api/ipos/company/$companyId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeoutDuration);

      // debugPrint('DEBUG API: Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Handle the company API response structure
        Map<String, dynamic> ipoData;
        if (data.containsKey('data') && data['data'] is Map) {
          final apiData = data['data'] as Map<String, dynamic>;

          // Check for body structure (company endpoint)
          if (apiData.containsKey('body') && apiData['body'] is Map) {
            ipoData = apiData['body'] as Map<String, dynamic>;
          } else {
            ipoData = apiData;
          }
        } else if (data.containsKey('ipo')) {
          ipoData = data['ipo'] as Map<String, dynamic>;
        } else {
          ipoData = data;
        }

        return IpoModel.fromJson(ipoData);
      } else if (response.statusCode == 404) {
        // debugPrint('DEBUG API: IPO not found (404) for company ID: $companyId');
        // debugPrint(
        //     'DEBUG API: Exception occurred: Exception: IPO not found for company ID: $companyId');
        throw Exception('IPO not found for company ID: $companyId');
      } else {
        // debugPrint(
        //     'DEBUG API: Failed to load IPO with status: ${response.statusCode}');
        throw Exception('Failed to load IPO: ${response.statusCode}');
      }
    } catch (e) {
      // debugPrint('DEBUG API: Exception occurred: $e');
      throw Exception('Error fetching IPO for company $companyId: $e');
    }
  }

  // GET /api/ipos/screener/:year – Fetch IPO screener data for a specific year
  static Future<List<IpoModel>> getIposByYear(int year) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/ipos/screener/$year'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Handle different response structures for year-based data
        List<dynamic> ipoList = [];

        if (responseData.containsKey('data') && responseData['data'] is Map) {
          final data = responseData['data'] as Map<String, dynamic>;

          // Check for table structure (screener endpoint)
          if (data.containsKey('table') && data['table'] is Map) {
            final table = data['table'] as Map<String, dynamic>;
            if (table.containsKey('row_data') && table['row_data'] is List) {
              ipoList = table['row_data'] as List<dynamic>;
            }
          }
          // Fallback to other structures
          else {
            if (data.containsKey('upcoming_open')) {
              ipoList.addAll(data['upcoming_open'] as List<dynamic>);
            }
            if (data.containsKey('recently_listed')) {
              ipoList.addAll(data['recently_listed'] as List<dynamic>);
            }
            if (data.containsKey('listing_soon')) {
              ipoList.addAll(data['listing_soon'] as List<dynamic>);
            }
          }
        } else if (responseData.containsKey('data') &&
            responseData['data'] is List) {
          ipoList = responseData['data'] as List<dynamic>;
        } else if (responseData.containsKey('ipos')) {
          ipoList = responseData['ipos'] as List<dynamic>;
        } else if (responseData is List) {
          ipoList = responseData as List<dynamic>;
        } else {
          ipoList = [responseData];
        }

        // The screener endpoint already filters by year, so no need for additional filtering
        return ipoList
            .map((json) => IpoModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        return []; // Return empty list if no IPOs found for the year
      } else {
        throw Exception(
            'Failed to load IPOs for year $year: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching IPOs for year $year: $e');
    }
  }

  // GET /api/ipos/listing-details – Fetch categorized IPOs
  static Future<Map<String, List<IpoModel>>> getCategorizedIpos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/ipos/listing-details'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Map<String, List<IpoModel>> categorizedIpos = {};

        if (responseData.containsKey('data') && responseData['data'] is Map) {
          final data = responseData['data'] as Map<String, dynamic>;

          // Process each category
          final categories = [
            'draft_issues',
            'upcoming_open',
            'listing_soon',
            'recently_listed',
            'gain_loss_analysis'
          ];

          for (final category in categories) {
            if (data.containsKey(category) && data[category] is List) {
              final categoryData = data[category] as List<dynamic>;
              categorizedIpos[category] = categoryData
                  .map(
                      (json) => IpoModel.fromJson(json as Map<String, dynamic>))
                  .toList();
            } else {
              categorizedIpos[category] = [];
            }
          }
        }

        return categorizedIpos;
      } else {
        throw Exception('Failed to load IPOs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categorized IPOs: $e');
    }
  }

  // Helper method to check API connectivity
  static Future<bool> checkApiConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/ipos/listing-details'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
