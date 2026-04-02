/// Preflop hand range chart screen.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/hand_range.dart';
import '../../models/position.dart';

/// Displays an interactive 13×13 preflop hand range matrix for each table
/// position, colour-coded by recommended action (Raise / Call / Fold).
class RangeChartScreen extends StatefulWidget {
  const RangeChartScreen({super.key});

  @override
  State<RangeChartScreen> createState() => _RangeChartScreenState();
}

/// The purple accent colour used throughout the range chart screen.
const Color _kPurple = Color(0xFF8B5CF6);

class _RangeChartScreenState extends State<RangeChartScreen> {
  TablePosition _selectedPosition = TablePosition.button;

  // Tooltip state for tapped cell
  String? _tooltipLabel;
  RangeAction? _tooltipAction;

  static const _positions = TablePosition.values;

  void _onCellTapped(int row, int col) {
    final label = handLabel(row, col);
    final action = getAction(_selectedPosition, row, col);
    setState(() {
      if (_tooltipLabel == label) {
        // Toggle off on second tap
        _tooltipLabel = null;
        _tooltipAction = null;
      } else {
        _tooltipLabel = label;
        _tooltipAction = action;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Hand Ranges',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(0.5),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.8),
            radius: 1.5,
            colors: isDark
                ? [
                    const Color(0xFF1E1040), // Deep violet glow
                    const Color(0xFF090B0F), // Dark charcoal
                    const Color(0xFF050505),
                  ]
                : [
                    const Color(0xFFEDE9FE), // Soft violet glow
                    const Color(0xFFF1F5F9), // Light slate
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Position selector
              _PositionSelector(
                selected: _selectedPosition,
                onChanged: (pos) => setState(() {
                  _selectedPosition = pos;
                  _tooltipLabel = null;
                  _tooltipAction = null;
                }),
                positions: _positions,
                isDark: isDark,
              ),

              // Stats bar
              _StatsBar(
                position: _selectedPosition,
                isDark: isDark,
              ),

              // Tooltip (visible after a cell tap)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _tooltipLabel != null
                    ? _CellTooltip(
                        key: ValueKey(_tooltipLabel),
                        label: _tooltipLabel!,
                        action: _tooltipAction!,
                        position: _selectedPosition,
                        isDark: isDark,
                      )
                    : const SizedBox(key: ValueKey('empty'), height: 0),
              ),

              // Grid + Legend
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _RangeGrid(
                        position: _selectedPosition,
                        onCellTapped: _onCellTapped,
                        selectedLabel: _tooltipLabel,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _Legend(isDark: isDark),
                      const SizedBox(height: 8),
                      _MatrixKey(isDark: isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Position selector — horizontal scrollable chip row
// ---------------------------------------------------------------------------

class _PositionSelector extends StatelessWidget {
  const _PositionSelector({
    required this.selected,
    required this.onChanged,
    required this.positions,
    required this.isDark,
  });

  final TablePosition selected;
  final ValueChanged<TablePosition> onChanged;
  final List<TablePosition> positions;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: positions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final pos = positions[i];
          final isSelected = pos == selected;
          return GestureDetector(
            onTap: () => onChanged(pos),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [_kPurple, Color(0xFF7C3AED)],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                ),
              ),
              child: Text(
                positionLabel(pos),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats bar
// ---------------------------------------------------------------------------

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.position, required this.isDark});

  final TablePosition position;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pct = openingPercentage(position);
    final label = positionLabel(position);
    final desc = positionDescription(position).split('—').first.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _kPurple.withOpacity(isDark ? 0.15 : 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _kPurple.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label — Opens ${pct.toStringAsFixed(0)}% of hands',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            // Opening percentage badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${pct.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: _kPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cell tooltip
// ---------------------------------------------------------------------------

class _CellTooltip extends StatelessWidget {
  const _CellTooltip({
    super.key,
    required this.label,
    required this.action,
    required this.position,
    required this.isDark,
  });

  final String label;
  final RangeAction action;
  final TablePosition position;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (actionText, actionColor) = switch (action) {
      RangeAction.raise => ('Raise', const Color(0xFF10B981)),
      RangeAction.call => ('Call', const Color(0xFFF59E0B)),
      RangeAction.fold => ('Fold', const Color(0xFF6B7280)),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: actionColor.withOpacity(isDark ? 0.15 : 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: actionColor.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: actionColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: actionColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    '${positionLabel(position)}: $actionText',
                    style: TextStyle(
                      fontSize: 13,
                      color: actionColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: actionColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                actionText.toUpperCase(),
                style: TextStyle(
                  color: actionColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 13×13 Range Grid
// ---------------------------------------------------------------------------

class _RangeGrid extends StatelessWidget {
  const _RangeGrid({
    required this.position,
    required this.onCellTapped,
    required this.selectedLabel,
    required this.isDark,
  });

  final TablePosition position;
  final void Function(int row, int col) onCellTapped;
  final String? selectedLabel;
  final bool isDark;

  // Raise green, call amber, fold gray
  static const _raiseColor = Color(0xFF10B981);
  static const _callColor = Color(0xFFF59E0B);
  static const _foldColorDark = Color(0xFF374151);
  static const _foldColorLight = Color(0xFFD1D5DB);

  Color _cellColor(RangeAction action, bool isDark) {
    return switch (action) {
      RangeAction.raise => _raiseColor,
      RangeAction.call => _callColor,
      RangeAction.fold => isDark ? _foldColorDark : _foldColorLight,
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Container padding: EdgeInsets.all(6) => 6px × 2 = 12px
        // Cell margins: EdgeInsets.all(0.5) × 2 sides × 14 columns = 14px
        final cellSize =
            ((constraints.maxWidth - 12 - 14) / 14).clamp(12.0, 34.0);
        final fontSize = (cellSize * 0.36).clamp(6.0, 12.0);
        final labelFontSize = (cellSize * 0.40).clamp(6.5, 13.0);

        return _buildGrid(cellSize, fontSize, labelFontSize);
      },
    );
  }

  Widget _buildGrid(double cellSize, double fontSize, double labelFontSize) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.07),
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: blank + rank labels
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: cellSize, height: cellSize),
              for (int col = 0; col < 13; col++)
                _RankLabel(
                  rank: _rankChar(col),
                  size: cellSize,
                  fontSize: labelFontSize,
                  isDark: isDark,
                ),
            ],
          ),
          // Data rows
          for (int row = 0; row < 13; row++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row rank label
                _RankLabel(
                  rank: _rankChar(row),
                  size: cellSize,
                  fontSize: labelFontSize,
                  isDark: isDark,
                ),
                // Data cells
                for (int col = 0; col < 13; col++)
                  _GridCell(
                    row: row,
                    col: col,
                    position: position,
                    size: cellSize,
                    fontSize: fontSize,
                    color: _cellColor(getAction(position, row, col), isDark),
                    isDark: isDark,
                    isSelected: handLabel(row, col) == selectedLabel,
                    onTap: () => onCellTapped(row, col),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  static String _rankChar(int index) {
    const ranks = ['A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2'];
    return ranks[index];
  }
}

// ---------------------------------------------------------------------------
// Individual grid cell
// ---------------------------------------------------------------------------

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.row,
    required this.col,
    required this.position,
    required this.size,
    required this.fontSize,
    required this.color,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  final int row;
  final int col;
  final TablePosition position;
  final double size;
  final double fontSize;
  final Color color;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = handLabel(row, col);
    final pair = isPocketPair(row, col);
    final suited = isSuited(row, col);
    final action = getAction(position, row, col);

    // Opacity: raise = full, call = full, fold = muted
    final opacity = switch (action) {
      RangeAction.raise => 1.0,
      RangeAction.call => 0.90,
      RangeAction.fold => isDark ? 0.55 : 0.65,
    };

    // Suited cells get slightly lighter background; pairs get a bold border
    final bgColor = color.withOpacity(opacity * (suited ? 0.85 : pair ? 0.95 : 0.75));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(3),
          border: isSelected
              ? Border.all(color: Colors.white, width: 1.5)
              : pair
                  ? Border.all(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.25),
                      width: 1,
                    )
                  : null,
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 4)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: pair ? FontWeight.bold : FontWeight.w500,
              color: action == RangeAction.fold
                  ? (isDark ? Colors.white38 : Colors.black38)
                  : Colors.white,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.clip,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rank label cell
// ---------------------------------------------------------------------------

class _RankLabel extends StatelessWidget {
  const _RankLabel({
    required this.rank,
    required this.size,
    required this.fontSize,
    required this.isDark,
  });

  final String rank;
  final double size;
  final double fontSize;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          rank,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legend
// ---------------------------------------------------------------------------

class _Legend extends StatelessWidget {
  const _Legend({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: const Color(0xFF10B981),
          label: 'Raise',
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        _LegendItem(
          color: const Color(0xFFF59E0B),
          label: 'Call',
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        _LegendItem(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
          label: 'Fold',
          isDark: isDark,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDark,
  });

  final Color color;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Matrix key / explanation
// ---------------------------------------------------------------------------

class _MatrixKey extends StatelessWidget {
  const _MatrixKey({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        'Top-right = suited (e.g. AKs) · Diagonal = pairs (e.g. AA) · Bottom-left = offsuit (e.g. AKo)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.white38 : Colors.black38,
          height: 1.4,
        ),
      ),
    );
  }
}
