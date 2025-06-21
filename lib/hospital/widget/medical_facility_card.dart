// 의료기관 검색 화면에서 병원 카드 컴포넌트

import 'package:flutter/material.dart';
import '../../component/medical_facility.dart';
import 'package:easy_localization/easy_localization.dart';

class MedicalFacilityCard extends StatelessWidget {
  final MedicalFacility facility;
  final String? distanceText;
  final VoidCallback onTap;

  const MedicalFacilityCard({
    required this.facility,
    required this.distanceText,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  String _getTranslatedStatus(String? status) {
    if (status == null) {
      return 'no_status'.tr();
    }

    if (status.contains('운영중')) {
      return 'operating'.tr();
    } else if (status.contains('운영종료')) {
      return 'closed'.tr();
    } else if (status.contains('운영 시간 정보 없음') || status.contains('운영 시간 판단 불가')) {
      return 'no_status'.tr();
    }

    return status;
  }

  Color _getStatusColor(String? status) {
    if (status == null) {
      return Colors.grey;
    }

    if (status.contains('운영중')) {
      return Colors.green;
    } else if (status.contains('운영종료')) {
      return Colors.red;
    }

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final status = facility.finalOpenStatus;
    final translatedStatus = _getTranslatedStatus(status);
    final statusColor = _getStatusColor(status);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1.0,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          facility.getCleanDutyName() ?? 'no_name'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(facility.dutyAddr ?? 'no_address'.tr()),
            Text('${'phone'.tr()}: ${facility.dutyTel1 ?? 'no_phone'.tr()}'),
            Row(
              children: [
                Text(
                  translatedStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                if (distanceText != null)
                  Text(
                    distanceText!,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}