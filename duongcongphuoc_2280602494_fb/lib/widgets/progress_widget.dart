import 'package:flutter/material.dart';

class ProgressWidget extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;
  final double percentage;

  const ProgressWidget({
    super.key,
    required this.totalTasks,
    required this.completedTasks,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: totalTasks == 0 ? 0 : percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage == 100 ? Colors.green : Colors.pink,
                  ),
                ),
                Text(
                  '${percentage.toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.pink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tiến độ chuẩn bị',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completedTasks / $totalTasks công việc hoàn thành',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                if (percentage == 100)
                  const Text(
                    'Tuyệt vời! Bạn đã sẵn sàng.',
                    style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500),
                  )
                else
                  Text(
                    'Cố lên! Sắp tới đích rồi.',
                    style: TextStyle(fontSize: 13, color: Colors.orange[700]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
