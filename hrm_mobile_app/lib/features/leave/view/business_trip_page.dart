import 'package:flutter/material.dart';

import 'leave_list_page.dart';

class BusinessTripPage extends StatelessWidget {
  const BusinessTripPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LeaveListPage(
      pageTitle: 'Công tác',
      onlyBusinessTripByDefault: true,
      lockBusinessTripFilter: true,
      registrationTitle: 'Đăng ký công tác',
      forcePermissionSymbol: 'C',
    );
  }
}
