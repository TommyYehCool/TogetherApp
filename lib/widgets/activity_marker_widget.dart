import 'package:flutter/material.dart';

class ActivityMarkerWidget extends StatelessWidget {
  final String title;
  final String participantCount;
  final bool isFull;
  final bool isBoosted;

  const ActivityMarkerWidget({
    super.key,
    required this.title,
    required this.participantCount,
    this.isFull = false,
    this.isBoosted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isFull ? Colors.grey[300] : Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isBoosted 
              ? const Color(0xFFFFD700) 
              : (isFull ? Colors.grey : const Color(0xFF00D0DD)),
          width: isBoosted ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event,
            size: 18,
            color: isFull ? Colors.grey[600] : const Color(0xFF00D0DD),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isFull ? Colors.grey[700] : const Color(0xFF2D3436),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isFull 
                  ? Colors.grey[400] 
                  : const Color(0xFF00D0DD).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              participantCount,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isFull ? Colors.grey[700] : const Color(0xFF00D0DD),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
