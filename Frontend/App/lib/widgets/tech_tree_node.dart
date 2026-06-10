import 'package:flutter/material.dart';
import 'package:argusx/config/argus_fonts.dart';

class TechTreeNode extends StatelessWidget {
  final String title;
  final List<TechTreeItem> items;

  const TechTreeNode({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.folder_outlined, color: activeColor, size: 14.0),
            const SizedBox(width: 8.0),
            Text(
              title,
              style: ArgusFonts.display(
                color: activeColor,
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Padding(
          padding: const EdgeInsets.only(left: 6.0),
          child: Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: _buildItemRow(item, context),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(TechTreeItem item, BuildContext context) {
    final bool isSelected = item.isSelected;
    final activeColor = Theme.of(context).colorScheme.primary;
    final glowColor = Theme.of(context).colorScheme.secondary;
    const inactiveColor = Color(0xFFE5E2E3);

    return Container(
      decoration: isSelected
          ? BoxDecoration(
              color: glowColor.withValues(alpha: 0.1),
              border: Border.all(
                color: activeColor.withValues(alpha: 0.5),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.2),
                  blurRadius: 4.0,
                ),
              ],
            )
          : BoxDecoration(
              border: Border.all(
                color: Colors.transparent,
                width: 1.0,
              ),
            ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '-- ',
                style: ArgusFonts.display(
                  color: const Color(0xFF4D4354),
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                item.label,
                style: ArgusFonts.display(
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 10.0,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          Text(
            '[${item.value}]',
            style: ArgusFonts.display(
              color: const Color(0xFF998CA0),
              fontSize: 10.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class TechTreeItem {
  final String label;
  final String value;
  final bool isSelected;

  TechTreeItem({
    required this.label,
    required this.value,
    this.isSelected = false,
  });
}
