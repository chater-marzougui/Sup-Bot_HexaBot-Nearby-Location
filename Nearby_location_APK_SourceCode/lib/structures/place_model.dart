import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' show pi, sin, cos, sqrt, atan2;

class Place {
  final String name;
  final double distance;
  final String address;
  final String type;
  final List<double> coordinates;

  Place({
    required this.name,
    required this.distance,
    required this.address,
    required this.type,
    required this.coordinates,
  });
}

class PlacesService {
  static Future<List<Place>> searchNearbyPlaces(
      double lat,
      double lon,
      String keyword,
      {double radius = 1000}
      ) async {
    final query = '''
      [out:json][timeout:25];
      (
        node["amenity"="$keyword"](around:$radius,$lat,$lon);
        node["leisure"="$keyword"](around:$radius,$lat,$lon);
        node["natural"="$keyword"](around:$radius,$lat,$lon);
        way["landuse"="$keyword"](around:$radius,$lat,$lon);
        node["tourism"="$keyword"](around:$radius,$lat,$lon);
        node["historic"="$keyword"](around:$radius,$lat,$lon);
        node["shop"="$keyword"](around:$radius,$lat,$lon);
        way["building"="$keyword"](around:$radius,$lat,$lon);
        node["emergency"="$keyword"](around:$radius,$lat,$lon);
      );
      out body;
      >;
      out skel qt;
    ''';
    print(query);
    try {
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch places');
      }

      final data = json.decode(response.body);
      final elements = (data['elements'] as List).take(10);

      List<Place> places = [];
      for (var element in elements) {
        if (element['tags'] != null) {
          final placeLat = element['lat'] ?? 0.0;
          final placeLon = element['lon'] ?? 0.0;

          final address = await getExactLocation(placeLat.toDouble(), placeLon.toDouble());
          final distance = calculateDistance(lat, lon, placeLat.toDouble(), placeLon.toDouble());

          places.add(Place(
            name: element['tags']['name'] ?? 'Unnamed',
            type: element['tags']['amenity'] ??
                element['tags']['leisure'] ??
                element['tags']['natural'] ??
                'Unknown',
            address: address,
            coordinates: [placeLat.toDouble(), placeLon.toDouble()],
            distance: distance,
          ));
        }
      }

      return places
        ..sort((a, b) => a.distance.compareTo(b.distance))
            ..toList();
    } catch (e) {
      print('Error fetching places: $e');
      throw Exception('Failed to fetch nearby places');
    }
  }

  static Future<String> getExactLocation(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'hexa-bot/0.1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'];
      }
      return 'Address unavailable';
    } catch (e) {
      return 'Address unavailable';
    }
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Earth's radius in meters
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
    cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  static String extractAmenityFromMessage(String message) {
    final keywords = ['find nearest', 'nearby', 'where is', 'find'];
    var amenity = message.toLowerCase();

    for (final keyword in keywords) {
      amenity = amenity.replaceAll(keyword, '').trim();
    }

    final amenityMap = {
      'restaurant': 'restaurant',
      'hospital': 'hospital',
      'pharmacy': 'pharmacy',
      'atm': 'atm',
      'bank': 'bank',
      'cafe': 'cafe',
      'school': 'school',
      'gas station': 'fuel',
      'police': 'police',
      'parking': 'parking',
    };

    return amenityMap[amenity] ?? amenity;
  }
}