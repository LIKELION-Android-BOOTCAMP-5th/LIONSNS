import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 날짜 구분선 위젯
class DateDivider extends StatelessWidget {
  final DateTime date;

  const DateDivider({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = '오늘';
    } else if (messageDate == yesterday) {
      dateText = '어제';
    } else {
      // 같은 해면 월일만 표시, 다른 해면 년월일 표시
      if (messageDate.year == now.year) {
        dateText = DateFormat('M월 d일').format(date);
      } else {
        dateText = DateFormat('yyyy년 M월 d일').format(date);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }
}

