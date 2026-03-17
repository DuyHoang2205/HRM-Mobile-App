import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  final DioClient _dioClient = DioClient();

  Future<UserProfile?> getProfile(int employeeId, String siteId) async {
    try {
      final baseResponses = await Future.wait([
        _safeGet('employee/infoMobile/$employeeId/$siteId'),
        _safeGet('employee/allInfo/$employeeId/$siteId/VIEW'),
      ]);

      final combinedData = _mergeProfilePayloads(
        infoMobileRaw: baseResponses[0].data,
        allInfoRaw: baseResponses[1].data,
      );

      if (combinedData.isEmpty) return null;

      final masterResponses = await _loadMasterDataIfNeeded(combinedData, siteId);
      _applyResolvedNames(combinedData, masterResponses);

      return UserProfile.fromJson(combinedData);
    } catch (e) {
      print('Error fetching combined profile: $e');
      return null;
    }
  }

  Future<Response<dynamic>> _safeGet(String path) {
    return _dioClient.dio
        .get(path)
        .catchError((_) => Response(
              requestOptions: RequestOptions(path: path),
              data: const [],
              statusCode: 404,
            ));
  }

  Map<String, dynamic> _mergeProfilePayloads({
    required dynamic infoMobileRaw,
    required dynamic allInfoRaw,
  }) {
    final combinedData = <String, dynamic>{};

    final infoMobile = _extractPayload(infoMobileRaw);
    if (infoMobile is List && infoMobile.isNotEmpty && infoMobile.first is Map) {
      combinedData.addAll(Map<String, dynamic>.from(infoMobile.first));
    } else if (infoMobile is Map) {
      combinedData.addAll(Map<String, dynamic>.from(infoMobile));
    }

    final allInfo = _extractPayload(allInfoRaw);
    if (allInfo is! List || allInfo.isEmpty) {
      return combinedData;
    }

    Map<String, dynamic>? header;
    if (allInfo.first is List) {
      final headerList = allInfo.first as List;
      if (headerList.isNotEmpty && headerList.first is Map) {
        header = Map<String, dynamic>.from(headerList.first);
      }
      if (allInfo.length > 1) combinedData['lineEducation'] = allInfo[1];
      if (allInfo.length > 2) combinedData['lineContract'] = allInfo[2];
      if (allInfo.length > 3) combinedData['lineWorkProgress'] = allInfo[3];
    } else if (allInfo.first is Map) {
      header = Map<String, dynamic>.from(allInfo.first);
    }

    if (header != null) {
      _mergePreferredLabels(combinedData, header);
    }

    return combinedData;
  }

  dynamic _extractPayload(dynamic raw) {
    if (raw is Map && raw.containsKey('data')) {
      return raw['data'];
    }
    return raw;
  }

  void _mergePreferredLabels(
    Map<String, dynamic> target,
    Map<String, dynamic> source,
  ) {
    source.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      String? existingKey;

      for (final currentKey in target.keys) {
        if (currentKey.toLowerCase() == lowerKey) {
          existingKey = currentKey;
          break;
        }
      }

      if (existingKey == null) {
        target[key] = value;
        return;
      }

      final existingValue = target[existingKey];
      final hasExistingLabel = _isTextLabel(existingValue);
      final hasIncomingLabel = _isTextLabel(value);

      if (hasExistingLabel) return;
      if (hasIncomingLabel || existingValue == null || existingValue == '') {
        target[existingKey] = value;
      }
    });
  }

  Future<Map<String, dynamic>> _loadMasterDataIfNeeded(
    Map<String, dynamic> combinedData,
    String siteId,
  ) async {
    final futures = <String, Future<Response<dynamic>>>{};

    if (_isNumericLike(combinedData['employeeType'])) {
      futures['employeeType'] = _safeGet('EmployeeSpecies/GetAll/$siteId');
    }
    if (_isNumericLike(combinedData['employeeStatus']) ||
        _isNumericLike(combinedData['status'])) {
      futures['status'] = _safeGet('EmployeeStatus/GetAll/$siteId');
    }
    if (_isNumericLike(combinedData['department'])) {
      futures['department'] = _safeGet('organization/department/getAll/$siteId');
    }
    if (_isNumericLike(combinedData['organization']) ||
        _isNumericLike(combinedData['organizationID'])) {
      futures['organization'] = _safeGet('organization/$siteId');
    }
    if (_isNumericLike(combinedData['position']) ||
        _isNumericLike(combinedData['positionID'])) {
      futures['position'] = _safeGet('position');
    }

    if (futures.isEmpty) return const {};

    final entries = futures.entries.toList();
    final responses = await Future.wait(entries.map((entry) => entry.value));

    final result = <String, dynamic>{};
    for (var i = 0; i < entries.length; i++) {
      result[entries[i].key] = responses[i].data;
    }
    return result;
  }

  void _applyResolvedNames(
    Map<String, dynamic> combinedData,
    Map<String, dynamic> masterResponses,
  ) {
    final employeeTypeId = combinedData['employeeType'];
    final employeeTypeName = _resolveName(
      masterResponses['employeeType'],
      employeeTypeId,
      const ['id', 'ID'],
      const ['EmployeeSpecies', 'employeeSpecies', 'name', 'title', 'Name', 'Title'],
    );
    if (employeeTypeName != null) {
      combinedData['employeeTypeName'] = employeeTypeName;
    }

    final statusId = combinedData['employeeStatus'] ?? combinedData['status'];
    final statusName = _resolveName(
      masterResponses['status'],
      statusId,
      const ['id', 'ID'],
      const ['EmployeeStatus', 'employeeStatus', 'name', 'title', 'Name', 'Title'],
    );
    if (statusName != null) {
      combinedData['statusName'] = statusName;
    }

    final departmentId = combinedData['department'];
    final departmentName = _resolveName(
      masterResponses['department'],
      departmentId,
      const ['id', 'ID'],
      const ['title', 'name', 'Title', 'Name'],
    );
    if (departmentName != null && departmentName != combinedData['position']) {
      combinedData['departmentName'] = departmentName;
    }

    final organizationId = combinedData['organization'] ?? combinedData['organizationID'];
    final organizationName = _resolveName(
      masterResponses['organization'],
      organizationId,
      const ['id', 'ID'],
      const ['title', 'name', 'Title', 'Name'],
    );
    if (organizationName != null) {
      combinedData['organizationName'] = organizationName;
    }

    final positionId = combinedData['position'] ?? combinedData['positionID'];
    final positionName = _resolveName(
      masterResponses['position'],
      positionId,
      const ['id', 'ID'],
      const ['name', 'Name', 'title', 'Title', 'altName'],
    );
    if (positionName != null) {
      combinedData['positionName'] = positionName;
    }

    if (!_isTextLabel(combinedData['departmentName']) &&
        _isTextLabel(combinedData['organization'])) {
      combinedData['departmentName'] = combinedData['organization'];
    }
  }

  String? _resolveName(
    dynamic raw,
    dynamic id,
    List<String> idKeys,
    List<String> nameKeys,
  ) {
    if (raw == null || id == null) return null;
    final items = _extractPayload(raw);
    if (items is! List) return null;

    for (final item in items) {
      if (item is! Map) continue;

      var matches = false;
      for (final idKey in idKeys) {
        if (item[idKey]?.toString() == id.toString()) {
          matches = true;
          break;
        }
      }
      if (!matches) continue;

      for (final nameKey in nameKeys) {
        final value = item[nameKey];
        if (_isTextLabel(value)) {
          return value.toString().trim();
        }
      }
    }

    return null;
  }

  bool _isNumericLike(dynamic value) {
    if (value == null) return false;
    return double.tryParse(value.toString().trim()) != null;
  }

  bool _isTextLabel(dynamic value) {
    if (value == null) return false;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null' || text == 'N/A') {
      return false;
    }
    return double.tryParse(text) == null;
  }
}
