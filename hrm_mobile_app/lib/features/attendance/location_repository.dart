import 'package:flutter/foundation.dart';
import '../../../core/network/dio_client.dart';
import 'models/location.dart';

class LocationRepository {
  final DioClient _dioClient;

  LocationRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  Future<List<Location>> getLocations(List<String> siteIds) async {
    final allLocations = <Location>[];
    for (final siteId in siteIds) {
      try {
        debugPrint('Fetching locations for site: $siteId');
        final response = await _dioClient.dio.get('location/$siteId');
        if (response.statusCode == 200) {
          final List<dynamic> data = response.data;
          allLocations.addAll(data.map((e) => Location.fromJson(e)).toList());
        }
      } catch (e) {
        debugPrint('Error fetching locations for $siteId: $e');
        // Continue to next site even if one fails
      }
    }
    return allLocations;
  }
}
