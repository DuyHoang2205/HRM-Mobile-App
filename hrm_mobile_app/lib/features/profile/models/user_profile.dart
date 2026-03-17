class UserProfile {
  final int id;
  final String code;
  final String fullName;
  final String gender;
  final String? department;
  final String? organization;
  final String? position;
  final String? employeeType;
  final String? status;
  final String? birthday;
  final String? birthPlace;
  final String? taxCode;
  final String? identityNum;
  final String? datePro;
  final String? placePro;
  final String? ethnic;
  final String? religion;
  final String? phonePri;
  final String? phoneSec;
  final String? streetPri;
  final String? streetSec;
  final String? accountNum;
  final String? bankName;
  final String? insuranceNum;
  final String? dateJoin;
  final String? email;
  final String? zalo;
  final String? facebook;
  final String? attendCode;
  final double? salary;
  
  // Extra fields expected by UI
  final String? phone1;
  final String? phone2;
  final String? districtPri;
  final String? cityPri;
  final String? districtSec;
  final String? citySec;
  final String? dateSign;
  final String? dateSignEnd;
  final String? contractType;
  final String? contractNum;
  final String? appendixNum;
  final String? dateStart;
  final String? dateEnd;
  final String? dateResign;
  final String? laborGroup;
  final bool? isIgnoreScan;

  // Lists for expandable sections
  final List<EducationRecord> education;
  final List<ContractRecord> contracts;
  final List<WorkHistoryRecord> workHistory;

  UserProfile({
    required this.id,
    required this.code,
    required this.fullName,
    required this.gender,
    this.department,
    this.organization,
    this.position,
    this.employeeType,
    this.status,
    this.birthday,
    this.birthPlace,
    this.taxCode,
    this.identityNum,
    this.datePro,
    this.placePro,
    this.ethnic,
    this.religion,
    this.phonePri,
    this.phoneSec,
    this.streetPri,
    this.streetSec,
    this.accountNum,
    this.bankName,
    this.insuranceNum,
    this.dateJoin,
    this.email,
    this.zalo,
    this.facebook,
    this.attendCode,
    this.salary,
    this.phone1,
    this.phone2,
    this.districtPri,
    this.cityPri,
    this.districtSec,
    this.citySec,
    this.dateSign,
    this.dateSignEnd,
    this.contractType,
    this.contractNum,
    this.appendixNum,
    this.dateStart,
    this.dateEnd,
    this.dateResign,
    this.laborGroup,
    this.isIgnoreScan,
    this.education = const [],
    this.contracts = const [],
    this.workHistory = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    dynamic headerRaw = json['header'];
    Map<String, dynamic> data = json;
    
    if (headerRaw is Map) {
      data = Map<String, dynamic>.from(headerRaw);
    } else if (headerRaw is List && headerRaw.isNotEmpty) {
      if (headerRaw.first is Map) {
        data = Map<String, dynamic>.from(headerRaw.first);
      }
    }
    
    String? formatDate(dynamic value) {
      if (value == null) return null;
      final str = value.toString();
      if (str.isEmpty) return null;
      return str.contains('T') ? str.split('T').first : str;
    }

    String? getString(Map<String, dynamic> m, List<String> keys) {
      // Priority 1: True label-like strings (Not numbers, not empty)
      for (var key in keys) {
        if (m.containsKey(key)) {
          final value = m[key];
          if (value != null && value is String && value.trim().length > 1) {
            // Skip strings that are pure numbers (IDs)
            if (double.tryParse(value) == null) {
              return value;
            }
          }
        }
      }
      // Priority 2: Standard values (Even IDs if no labels found)
      for (var key in keys) {
        if (m.containsKey(key)) {
          final value = m[key];
          if (value != null && value.toString().isNotEmpty && value.toString() != 'null') {
            return value.toString();
          }
        }
      }
      return null;
    }

    String? getLabelOnlyString(Map<String, dynamic> m, List<String> keys) {
      final value = getString(m, keys);
      if (value == null) return null;
      return double.tryParse(value.trim()) == null ? value : null;
    }

    String parseGender(dynamic value) {
      if (value == null) return 'N/A';
      final v = value.toString().toLowerCase();
      if (v == '1' || v == 'true' || v == 'nam' || v == 'male') return 'Nam';
      if (v == '0' || v == 'false' || v == 'nữ' || v == 'female') return 'Nữ';
      return value.toString();
    }

    return UserProfile(
      id: data['ID'] ?? data['id'] ?? json['ID'] ?? json['id'] ?? 0,
      code: getString(data, ['Code', 'code', 'EmployeeCode', 'employeeCode']) ?? '',
      fullName: getString(data, ['FullName', 'fullName', 'Họ và tên']) ?? '',
      gender: parseGender(data['Gender'] ?? data['gender']),
      department: getLabelOnlyString(data, [
        'departmentName',
        'DepartmentName',
        'departmentTitle',
        'DepartmentTitle',
        'Department',
        'department',
      ]),
      organization: getLabelOnlyString(data, [
        'organizationName',
        'OrganizationName',
        'organizationTitle',
        'OrganizationTitle',
        'Organization',
        'organization',
      ]),
      position: getLabelOnlyString(data, [
        'positionName',
        'PositionName',
        'positionTitle',
        'PositionTitle',
        'Position',
        'position',
      ]),
      employeeType: getString(data, ['employeeTypeName', 'EmployeeTypeName', 'EmployeeType', 'employeeType']),
      status: getString(data, ['statusName', 'StatusName', 'EmployeeStatus', 'employeeStatus', 'Status', 'status']),
      birthday: formatDate(data['Birthday'] ?? data['birthday'] ?? data['birthDay']),
      birthPlace: getLabelOnlyString(data, [
        'BirthPlaceName',
        'birthPlaceName',
        'BirthPlaceTitle',
        'birthPlaceTitle',
        'BirthPlace',
        'birthPlace',
      ]),
      taxCode: getString(data, ['FaxCode', 'faxCode', 'TaxCode', 'taxCode']),
      identityNum: getString(data, ['IdentityNum', 'identityNum', 'SoCMND', 'Số CMND', 'CCCD']),
      datePro: formatDate(data['DatePro'] ?? data['datePro']),
      placePro: getString(data, ['PlacePro', 'placePro']),
      ethnic: getString(data, ['Ethnic', 'ethnic']),
      religion: getString(data, ['Religion', 'religion']),
      phonePri: getString(data, ['PhonePri', 'phonePri', 'SoDienThoai']),
      phoneSec: getString(data, ['PhoneSec', 'phoneSec']),
      streetPri: getString(data, ['StreetPri', 'streetPri', 'Address', 'address']),
      streetSec: getString(data, ['StreetSec', 'streetSec']),
      accountNum: getString(data, ['AccountNum', 'accountNum', 'SoTaiKhoan']),
      bankName: getString(data, ['BankName', 'bankName', 'TenNganHang']),
      insuranceNum: getString(data, ['InsuranceNum', 'insuranceNum', 'SoBHXH']),
      dateJoin: formatDate(data['DateJoin'] ?? data['dateJoin']),
      email: getString(data, ['Gmail', 'gmail', 'Email', 'email']),
      zalo: getString(data, ['Zalo', 'zalo']),
      facebook: getString(data, ['Facebook', 'facebook']),
      attendCode: getString(data, ['AttendCode', 'attendCode', 'MCC']),
      salary: data['salary'] != null ? double.tryParse(data['salary'].toString()) : null,
      
      // Additional fields for UI
      phone1: getString(data, ['phone1', 'Phone1']),
      phone2: getString(data, ['phone2', 'Phone2']),
      districtPri: getLabelOnlyString(data, [
        'districtPriName',
        'DistrictPriName',
        'districtPriTitle',
        'DistrictPriTitle',
        'districtPri',
        'DistrictPri',
      ]),
      cityPri: getLabelOnlyString(data, [
        'cityPriName',
        'CityPriName',
        'cityPriTitle',
        'CityPriTitle',
        'cityPri',
        'CityPri',
      ]),
      districtSec: getLabelOnlyString(data, [
        'districtSecName',
        'DistrictSecName',
        'districtSecTitle',
        'DistrictSecTitle',
        'districtSec',
        'DistrictSec',
      ]),
      citySec: getLabelOnlyString(data, [
        'citySecName',
        'CitySecName',
        'citySecTitle',
        'CitySecTitle',
        'citySec',
        'CitySec',
      ]),
      dateSign: formatDate(data['dateSign'] ?? data['DateSign']),
      dateSignEnd: formatDate(data['dateSignEnd'] ?? data['DateSignEnd']),
      contractType: getString(data, ['contractType', 'ContractType']),
      contractNum: getString(data, ['contractNum', 'ContractNum']),
      appendixNum: getString(data, ['appendixNum', 'AppendixNum']),
      dateStart: formatDate(data['dateStart'] ?? data['DateStart']),
      dateEnd: formatDate(data['dateEnd'] ?? data['DateEnd']),
      dateResign: formatDate(data['dateResign'] ?? data['DateResign']),
      laborGroup: getString(data, ['laborGroup', 'LaborGroup']),
      isIgnoreScan: data['isIgnoreScan'] == true,
      
      education: (json['lineEducation'] as List?)?.map((e) => EducationRecord.fromJson(e)).toList() ?? [],
      contracts: (json['lineContract'] as List?)?.map((e) => ContractRecord.fromJson(e)).toList() ?? [],
      workHistory: (json['lineWorkProgress'] as List?)?.map((e) => WorkHistoryRecord.fromJson(e)).toList() ?? [],
    );
  }
}

class EducationRecord {
  final String? level;
  final String? school;
  final String? faculty;
  final int? graduationYear;
  final String? rank;
  EducationRecord({this.level, this.school, this.faculty, this.graduationYear, this.rank});
  factory EducationRecord.fromJson(Map<String, dynamic> json) => EducationRecord(
    level: json['EducationLevel'] ?? json['level'],
    school: json['SchoolName'] ?? json['school'],
    faculty: json['FacultyName'] ?? json['faculty'],
    graduationYear: json['GraduationYear'] ?? json['year'],
    rank: json['Rank'] ?? json['rank'],
  );
}

class ContractRecord {
  final String? contractType;
  final String? signDate;
  final String? contractNum;
  final String? startDate;
  final String? endDate;
  final String? status;
  ContractRecord({this.contractType, this.signDate, this.contractNum, this.startDate, this.endDate, this.status});
  factory ContractRecord.fromJson(Map<String, dynamic> json) => ContractRecord(
    contractType: json['ContractTypeName'] ?? json['contractType'],
    signDate: json['SignDate'] ?? json['signDate'],
    contractNum: json['ContractNum'] ?? json['contractNum'],
    startDate: json['StartDate'] ?? json['startDate'],
    endDate: json['EndDate'] ?? json['endDate'],
    status: json['StatusName'] ?? json['status'],
  );
}

class WorkHistoryRecord {
  final String? action;
  final String? effectiveDate;
  final String? status;
  final String? fromTo;
  WorkHistoryRecord({this.action, this.effectiveDate, this.status, this.fromTo});
  factory WorkHistoryRecord.fromJson(Map<String, dynamic> json) => WorkHistoryRecord(
    action: json['ActionName'] ?? json['action'],
    effectiveDate: json['EffectiveDate'] ?? json['effectiveDate'],
    status: json['StatusName'] ?? json['status'],
    fromTo: json['FromTo'] ?? json['fromTo'],
  );
}
