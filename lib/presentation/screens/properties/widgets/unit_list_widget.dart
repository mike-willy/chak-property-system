import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../data/models/unit_model.dart';

class UnitListWidget extends StatelessWidget {
  final List<UnitModel> units;
  final Function(UnitModel) onApply;

  const UnitListWidget({
    super.key,
    required this.units,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Available Units',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: units.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final unit = units[index];
            return _buildUnitCard(context, unit);
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildUnitCard(BuildContext context, UnitModel unit) {
    final bool isAvailable = unit.status == UnitStatus.vacant;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Unit Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAvailable ? Colors.blue.shade50 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                FontAwesomeIcons.doorOpen,
                size: 20,
                color: isAvailable ? Colors.blue : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            
            // Unit Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unit ${unit.unitNumber}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildStatusChip(unit.status),
                      if (unit.floor > 0)
                        Text(
                          'Floor ${unit.floor}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Button
            ElevatedButton(
              onPressed: isAvailable ? () => onApply(unit) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isAvailable 
                      ? 'Apply' 
                      : unit.status == UnitStatus.maintenance
                          ? 'Maint.'
                          : 'Occupied',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(UnitStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case UnitStatus.vacant:
        color = Colors.green;
        label = 'Available';
        icon = FontAwesomeIcons.check;
        break;
      case UnitStatus.occupied:
        color = Colors.red.shade300;
        label = 'Occupied';
        icon = FontAwesomeIcons.userLock;
        break;
      case UnitStatus.maintenance:
        color = Colors.orange;
        label = 'Maintenance';
        icon = FontAwesomeIcons.tools;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
