/// Home screen — app entry point with navigation to manual input.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../engine/decision_engine.dart';
import '../../models/hand_record.dart';
import '../../services/crash_reporting_service.dart';
import '../../services/history_service.dart';
import '../../services/theme_service.dart';
import '../utils/error_helpers.dart';
import '../widgets/card_widget.dart';
import 'history_screen.dart';
import 'manual_input_screen.dart';
import 'range_chart_screen.dart';

/// The main landing screen of the Poker Buddy app.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.themeService});

  final ThemeService themeService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<HandRecord> _recentHands = [];
  HistoryService? _historyService;
  String _appVersion = '';
  bool _hasHistoryError = false;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _initHistory();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _appVersion = info.version);
    } catch (e, st) {
      // Version display is non-critical — keep _appVersion as empty string.
      CrashReportingService.recordError(e, st);
    }
  }

  Future<void> _initHistory() async {
    try {
      final service = await HistoryService.create();
      if (!mounted) return;
      setState(() {
        _historyService = service;
        _isLoadingHistory = false;
      });
      await _loadRecent();
    } catch (e, st) {
      CrashReportingService.recordError(e, st);
      if (!mounted) return;
      setState(() {
        _hasHistoryError = true;
        _isLoadingHistory = false;
      });
      showErrorSnackBar(context, 'Could not load hand history');
    }
  }

  Future<void> _loadRecent() async {
    final service = _historyService;
    if (service == null) return;
    final records = await service.getHistory();
    if (mounted) {
      setState(() => _recentHands = records.take(3).toList());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRecent();
  }

  void _openHistory() {
    final service = _historyService;
    if (service == null) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => HistoryScreen(historyService: service),
          ),
        )
        .then((_) => _loadRecent());
  }

  void _showAppearanceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _AppearanceSheet(themeService: widget.themeService);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = switch (widget.themeService.themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          // Modern, subtle radial gradient background
          gradient: RadialGradient(
            center: const Alignment(-0.5, -0.8),
            radius: 1.5,
            colors: isDark
                ? [
                    const Color(0xFF1E3C2B), // Deep emerald glow
                    const Color(0xFF090B0F), // Dark charcoal
                    const Color(0xFF050505),
                  ]
                : [
                    const Color(0xFFE8F5E9), // Soft mint glow
                    const Color(0xFFF1F5F9), // Light slate
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative background blur shapes
              Positioned(
                top: 50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.greenAccent : Colors.green).withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: const SizedBox(),
                ),
              ),

              // Main scrollable content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),

                      // Refined App icon / logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: isDark ? 0.1 : 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.style_rounded,
                            size: 48,
                            color: isDark ? Colors.white : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'Poker\nBuddy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tagline
                      Text(
                        'Mathematically optimal decisions\nat the poker table.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Modern Feature chips (Glassmorphism)
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: const [
                          _FeatureChip(icon: Icons.calculate_outlined, label: 'Equity'),
                          _FeatureChip(icon: Icons.pie_chart_outline, label: 'Pot Odds'),
                          _FeatureChip(icon: Icons.auto_graph_rounded, label: 'EV Math'),
                          _FeatureChip(icon: Icons.lightbulb_outline, label: 'Advice'),
                          _FeatureChip(icon: Icons.grid_on_rounded, label: 'Ranges'),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // Primary action — Manual Input (full-width)
                      _ActionCard(
                        icon: Icons.grid_view_rounded,
                        title: 'Manual Input',
                        description: 'Select cards and get your optimal move',
                        gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                        fullWidth: true,
                        onTap: () => Navigator.of(context)
                            .push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ManualInputScreen(),
                              ),
                            )
                            .then((_) => _loadRecent()),
                      ),
                      const SizedBox(height: 12),

                      // Hand Ranges action card (full-width row)
                      _ActionCard(
                        icon: Icons.grid_on_rounded,
                        title: 'Hand Ranges',
                        description: 'Position-based charts',
                        gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        fullWidth: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RangeChartScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Recent Activity section
                      _RecentActivity(
                        records: _recentHands,
                        onSeeAll: _openHistory,
                        isDark: isDark,
                        hasError: _hasHistoryError,
                        isLoading: _isLoadingHistory,
                      ),

                      const SizedBox(height: 24),

                      // Version / footer
                      Text(
                        _appVersion.isEmpty
                            ? 'Texas Hold\'em'
                            : 'Texas Hold\'em · v$_appVersion',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Top-left: history button
              Positioned(
                top: 12,
                left: 12,
                child: Semantics(
                  label: 'Hand History',
                  button: true,
                  child: IconButton(
                    icon: Icon(Icons.history_rounded, color: isDark ? Colors.white : Colors.black87),
                    tooltip: 'Hand History',
                    onPressed: _openHistory,
                  ),
                ),
              ),

              // Top-right: theme selector (System / Light / Dark)
              Positioned(
                top: 12,
                right: 12,
                child: Semantics(
                  label: 'Change appearance',
                  button: true,
                  child: IconButton(
                    icon: Icon(
                      switch (widget.themeService.themeMode) {
                        ThemeMode.system => Icons.brightness_auto_rounded,
                        ThemeMode.light => Icons.light_mode_rounded,
                        ThemeMode.dark => Icons.dark_mode_rounded,
                      },
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    tooltip: 'Appearance',
                    onPressed: () => _showAppearanceSheet(context),
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
// Recent Activity section
// ---------------------------------------------------------------------------

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({
    required this.records,
    required this.onSeeAll,
    required this.isDark,
    this.hasError = false,
    this.isLoading = false,
  });

  final List<HandRecord> records;
  final VoidCallback onSeeAll;
  final bool isDark;
  final bool hasError;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            if (records.isNotEmpty)
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : Colors.black54,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('See All', style: TextStyle(fontSize: 13)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          ...List.generate(2, (_) => _ShimmerPlaceholder(isDark: isDark))
        else if (hasError)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: Colors.red.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
                Text(
                  'Could not load hand history',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else if (records.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 32,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your analyzed hands will appear here',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          ...records.map((r) => _RecentHandTile(record: r, isDark: isDark)),
      ],
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  const _ShimmerPlaceholder({required this.isDark});

  final bool isDark;

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: Container(
          height: 64,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _RecentHandTile extends StatelessWidget {
  const _RecentHandTile({required this.record, required this.isDark});

  final HandRecord record;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (label, color, actionIcon) = switch (record.action) {
      PlayerAction.fold => ('FOLD', const Color(0xFFEF4444), Icons.block_rounded),
      PlayerAction.call => ('CALL', const Color(0xFFF59E0B), Icons.pan_tool_alt_rounded),
      PlayerAction.raise => ('RAISE', const Color(0xFF10B981), Icons.trending_up_rounded),
    };

    final badgeColor = isDark ? color : HSLColor.fromColor(color)
        .withLightness((HSLColor.fromColor(color).lightness * 0.8).clamp(0.0, 1.0))
        .toColor();

    final cardLabels = record.holeCards
        .map((c) => '${c.rank.name} of ${c.suit.name}')
        .join(', ');

    return Semantics(
      label: 'Recent hand: $cardLabels — $label — ${_formatRelative(record.timestamp)}',
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.4 : 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Activity Indicator line
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Hole cards
          ...record.holeCards.map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: CardWidget(card: c, size: CardSize.small),
            ),
          ),
          const SizedBox(width: 12),
          // Decision badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  actionIcon,
                  size: 11,
                  color: badgeColor,
                ),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Timestamp
          Text(
            _formatRelative(record.timestamp),
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ---------------------------------------------------------------------------
// Existing helper widgets - modernized
// ---------------------------------------------------------------------------

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: label,
      child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isDark ? Colors.white70 : Colors.black87, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// A highly polished, tappable card tile
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
    required this.onTap,
    this.enabled = true,
    this.comingSoonLabel,
    this.fullWidth = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final bool enabled;
  final String? comingSoonLabel;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Semantics(
      label: '$title: $description',
      button: true,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.3 : 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Top gradient accent line
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                    child: fullWidth
                        ? Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: gradientColors.map((c) => c.withValues(alpha: 0.15)).toList(),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  icon,
                                  size: 28,
                                  color: gradientColors.last,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: gradientColors.last.withValues(alpha: 0.7),
                                size: 24,
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: gradientColors.map((c) => c.withValues(alpha: 0.15)).toList(),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  icon,
                                  size: 32,
                                  color: gradientColors.last,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                  // "Coming Soon" ribbon badge — overlaid in top-right corner
                  if (!enabled && comingSoonLabel != null)
                    Positioned(
                      top: 12,
                      right: 4,
                      child: Transform.rotate(
                        angle: 0.3, // ~17° clockwise tilt
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: gradientColors.first.withValues(alpha: 0.80),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            comingSoonLabel!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!enabled) {
      return Opacity(opacity: 0.6, child: card);
    }
    return card;
  }
}

/// Bottom sheet for selecting System / Light / Dark theme mode.
class _AppearanceSheet extends StatefulWidget {
  const _AppearanceSheet({required this.themeService});
  final ThemeService themeService;

  @override
  State<_AppearanceSheet> createState() => _AppearanceSheetState();
}

class _AppearanceSheetState extends State<_AppearanceSheet> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = widget.themeService.themeMode;

    final options = [
      (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
      (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Appearance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          for (final (mode, icon, label) in options)
            RadioListTile<ThemeMode>(
              value: mode,
              groupValue: current,
              onChanged: (m) async {
                if (m != null) {
                  await widget.themeService.setThemeMode(m);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              secondary: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
              title: Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: current == mode ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              activeColor: const Color(0xFF10B981),
            ),
        ],
      ),
    );
  }
}
