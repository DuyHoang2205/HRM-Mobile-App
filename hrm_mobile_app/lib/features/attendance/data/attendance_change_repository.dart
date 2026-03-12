import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class AttendanceChangeRepository {
  final DioClient _client;

  AttendanceChangeRepository({DioClient? client})
    : _client = client ?? DioClient();

  Future<List<Map<String, dynamic>>> getInvalidAttendance({
    required String siteID,
    required String fromDate,
    required String toDate,
    int deptId = 0,
    String empCode = '',
  }) async {
    final response = await _client.dio.post(
      'attendance/invalid/$siteID',
      data: {
        'deptId': deptId,
        'fromDate': fromDate,
        'toDate': toDate,
        'empCode': empCode,
      },
    );

    if (response.statusCode == 200 && response.data is List) {
      final rows = response.data as List;
      return rows
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getHistoryByEmployee({
    required int employeeID,
    required int period,
    required String siteID,
  }) async {
    final response = await _client.dio.get(
      'attendance/historyChange/$employeeID/$period/$siteID',
    );

    if (response.statusCode == 200 && response.data is List) {
      final rows = response.data as List;
      return rows
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<bool> approveChange({
    required int docID,
    required int status,
    required String createdBy,
    required String siteID,
    String docType = 'ATDocType',
    String stepType = 'APPROVE',
  }) async {
    final response = await _client.dio.post(
      '/approveProgress/changeStatus',
      data: {
        'listDocID': <int>[docID],
        'status': status,
        'docType': docType,
        'stepType': stepType,
        'createdBy': createdBy,
        'siteID': siteID,
      },
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<List<Map<String, dynamic>>> getTimekeepingOffsets({
    required int period,
    required String siteID,
    required String fromDate,
    required String toDate,
  }) async {
    final response = await _client.dio.post(
      'timekeepingOffset/$period/$siteID',
      data: {'fromDate': fromDate, 'toDate': toDate},
    );

    if (response.statusCode == 200 && response.data is List) {
      final rows = response.data as List;
      return rows
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<bool> acceptTimekeepingOffset({
    required int employeeID,
    required String date,
    required int shiftID,
  }) async {
    final response = await _client.dio.post(
      'timekeepingOffset/acceptTimekeepingOffset',
      data: {'employeeID': employeeID, 'date': date, 'shift': shiftID},
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<Response<dynamic>> saveAttendanceChangeRaw({
    required int employeeID,
    required String authDate,
    required String authTime,
    required String createdBy,
    required String siteID,
  }) {
    return _client.dio.post(
      'attendance/change/$siteID',
      data: {
        'employeeID': employeeID,
        'authDate': authDate,
        'authTime': authTime,
        'createdBy': createdBy,
        'siteID': siteID,
      },
    );
  }
}
