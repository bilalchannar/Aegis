import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pro_access.dart';
import 'shield_art.dart';

const forest = Color(0xFF163C34);
const mint = Color(0xFFD7F3A8);
const green = Color(0xFF388674);
const rust = Color(0xFFCC6D54);
const amber = Color(0xFFB78B42);

extension Palette on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get ink => isDark ? const Color(0xFFF1F5EF) : const Color(0xFF1A352F);
  Color get subtle =>
      isDark ? const Color(0xFFA5B9AD) : const Color(0xFF7B8B82);
  Color get card => isDark ? const Color(0xFF1C302A) : Colors.white;
  Color get line => isDark ? const Color(0xFF30473D) : const Color(0xFFE5EBE3);
  Color get soft => isDark ? const Color(0xFF253F32) : const Color(0xFFEDF3E8);
}

ThemeData appTheme(bool dark) => ThemeData(
  useMaterial3: true,
  brightness: dark ? Brightness.dark : Brightness.light,
  scaffoldBackgroundColor: dark
      ? const Color(0xFF10221D)
      : const Color(0xFFF6F8F3),
  fontFamily: '.SF Pro Display',
  colorScheme: ColorScheme.fromSeed(
    seedColor: green,
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: dark ? mint : forest,
    surface: dark ? const Color(0xFF1C302A) : Colors.white,
  ),
  splashFactory: NoSplash.splashFactory,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  ),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  ),
);
TextStyle headline([double size = 34]) => TextStyle(
  fontSize: size,
  height: 1.08,
  letterSpacing: -1.35,
  fontWeight: FontWeight.w600,
);

class Brand extends StatelessWidget {
  final bool light;
  const Brand({super.key, this.light = false});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        CupertinoIcons.shield_lefthalf_fill,
        size: 26,
        color: light ? mint : green,
      ),
      const SizedBox(width: 8),
      Text(
        'aegis',
        style: TextStyle(
          color: light ? Colors.white : context.ink,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -1.5,
        ),
      ),
      Text('  °', style: TextStyle(color: light ? mint : green, fontSize: 20)),
    ],
  );
}

class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.radius = 25,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? context.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: context.line.withValues(alpha: .8)),
    ),
    child: child,
  );
}

class Pill extends StatelessWidget {
  final String text;
  final Color? color, background;
  final IconData? icon;
  const Pill(this.text, {super.key, this.color, this.background, this.icon});
  @override
  Widget build(BuildContext context) {
    final c = color ?? green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? c.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: c),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: c,
                fontSize: 9,
                letterSpacing: .6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool secondary, busy;
  const ActionButton(
    this.label, {
    super.key,
    required this.onTap,
    this.icon = CupertinoIcons.arrow_right,
    this.secondary = false,
    this.busy = false,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child: FilledButton(
      onPressed: busy
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap?.call();
            },
      style: FilledButton.styleFrom(
        backgroundColor: secondary
            ? context.soft
            : context.isDark
            ? mint
            : forest,
        foregroundColor: secondary
            ? context.ink
            : context.isDark
            ? forest
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy) ...[
            const CupertinoActivityIndicator(),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          if (!busy && icon != null) ...[
            const SizedBox(width: 12),
            Icon(icon, size: 18),
          ],
        ],
      ),
    ),
  );
}

class Entrance extends StatelessWidget {
  final Widget child;
  const Entrance({super.key, required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(
      milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 480,
    ),
    curve: Curves.easeOutCubic,
    builder: (_, v, child) => Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child),
    ),
    child: child,
  );
}

class PageFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? bottom, trailing;
  const PageFrame({
    super.key,
    required this.title,
    required this.children,
    this.bottom,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(CupertinoIcons.chevron_left, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      actions: [?trailing],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          children: children,
        ),
      ),
    ),
    bottomNavigationBar: bottom == null
        ? null
        : SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: bottom,
            ),
          ),
  );
}

Widget section(
  BuildContext context,
  String text, {
  String? action,
  VoidCallback? onTap,
}) => Row(
  children: [
    Expanded(
      child: Text(
        text,
        style: TextStyle(
          color: context.ink,
          fontSize: 18,
          letterSpacing: -.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    if (action != null)
      TextButton(
        onPressed: onTap,
        child: Text(
          action,
          style: TextStyle(color: context.isDark ? mint : green, fontSize: 12),
        ),
      ),
  ],
);
Widget caption(BuildContext context, String text) => Text(
  text,
  style: TextStyle(color: context.subtle, fontSize: 12, height: 1.6),
);
Widget eyebrow(BuildContext context, String text) => Text(
  text,
  style: TextStyle(
    color: context.subtle,
    fontSize: 9,
    letterSpacing: 1.8,
    fontWeight: FontWeight.w700,
  ),
);
Widget iconTile(
  BuildContext context,
  IconData icon, {
  Color? color,
  double size = 46,
}) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    color: (color ?? green).withValues(alpha: .09),
    borderRadius: BorderRadius.circular(size * .32),
  ),
  child: Icon(
    icon,
    color: color ?? (context.isDark ? mint : green),
    size: size * .46,
  ),
);
void openPage(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
Future<void> infoSheet(
  BuildContext context, {
  required String title,
  required String body,
  String label = 'Got it',
  IconData icon = CupertinoIcons.info_circle,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: context.card,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
  ),
  builder: (c) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(26, 8, 26, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconTile(c, icon),
          const SizedBox(height: 18),
          Text(title, style: headline(28)),
          const SizedBox(height: 14),
          Text(
            body,
            style: TextStyle(color: c.subtle, height: 1.6, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ActionButton(label, onTap: () => Navigator.pop(c)),
        ],
      ),
    ),
  ),
);

class MenuRow extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;
  const MenuRow(
    this.title, {
    super.key,
    required this.icon,
    this.subtitle = '',
    this.onTap,
    this.trailing,
    this.color,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(22),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      child: Row(
        children: [
          iconTile(context, icon, size: 38, color: color),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.ink,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.subtle,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              Icon(
                CupertinoIcons.chevron_right,
                size: 13,
                color: context.subtle,
              ),
        ],
      ),
    ),
  );
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  const GlassPanel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .08),
          blurRadius: 25,
          offset: const Offset(0, 9),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: context.card.withValues(alpha: .91),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: context.line),
          ),
          child: child,
        ),
      ),
    ),
  );
}

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});
  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  ProPlan selected = ProPlan.pro;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ProAccess.instance,
    builder: (context, _) {
      final access = ProAccess.instance;
      const plans = [ProPlan.free, ProPlan.pro, ProPlan.ultra];
      String quota(int? value, String unit) =>
          value == null ? 'Unlimited by app quota' : '$value $unit';
      final features = <ProPlan, List<String>>{
        ProPlan.free: [
          'Rules based text and link checks',
          'Screenshot intake and local guidance (no OCR)',
          '2 PDF exports per month',
          'Basic patterns, quiz and dashboard',
          'Limited history',
        ],
        ProPlan.pro: [
          'AI scans · 10 successful requests per day',
          '10 PDF exports per month',
          'Complete patterns, quiz and dashboard',
          'Extended history and custom rules',
          'Advanced analytics and PDF customization',
        ],
        ProPlan.ultra: [
          'Everything in Pro',
          'AI and PDF exports without app-imposed quotas',
          'Unlimited local history',
          'All premium features unlocked',
        ],
      };
      return PageFrame(
        title: 'Aegis plans',
        trailing: TextButton(
          onPressed: access.busy || !access.available ? null : access.restore,
          child: const Text('Restore'),
        ),
        children: [
          const Center(child: ShieldArt(size: 105)),
          const SizedBox(height: 12),
          Center(
            child: Pill(
              'CURRENT PLAN · ${ProAccess.names[access.plan]!.toUpperCase()}',
              icon: CupertinoIcons.sparkles,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Choose your level of protection.',
            textAlign: TextAlign.center,
            style: headline(29),
          ),
          const SizedBox(height: 10),
          caption(
            context,
            'AI and PDF limits are managed by your plan. Ultra removes Aegis app quotas, while external providers can still enforce their own limits.',
          ),
          const SizedBox(height: 17),
          ...plans.map((plan) {
            final item = plan == ProPlan.free
                ? null
                : access.offers[ProAccess.products[plan]];
            final isSelected = selected == plan;
            final isCurrent = access.plan == plan;
            final limits = PlanConfiguration.values[plan]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => setState(() => selected = plan),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? green : context.line,
                      width: isSelected ? 1.5 : 1,
                    ),
                    color: isSelected ? context.soft : context.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSelected
                                ? CupertinoIcons.checkmark_alt_circle_fill
                                : CupertinoIcons.circle,
                            color: isSelected ? green : context.subtle,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ProAccess.names[plan]!.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: .7,
                              ),
                            ),
                          ),
                          if (isCurrent) const Pill('ACTIVE'),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        plan == ProPlan.free
                            ? 'Free'
                            : item?.price ??
                                  'Price shown by the configured store',
                        style: TextStyle(color: context.subtle, fontSize: 12),
                      ),
                      Text(
                        'AI: ${quota(limits.aiPerDay, 'per day')}  ·  PDF: ${quota(limits.pdfPerMonth, 'per month')}',
                        style: TextStyle(color: context.subtle, fontSize: 11),
                      ),
                      const SizedBox(height: 9),
                      ...features[plan]!.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                CupertinoIcons.checkmark,
                                size: 14,
                                color: green,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  f,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (!access.available)
            caption(
              context,
              'Purchases are supported in the configured Aegis Android application. Plan comparisons and Free features remain available here.',
            ),
          if (access.statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                access.statusMessage!,
                style: TextStyle(color: context.subtle, fontSize: 12),
              ),
            ),
          if (access.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(access.error!, style: const TextStyle(color: rust)),
            ),
          ActionButton(
            access.busy
                ? 'Waiting for store…'
                : selected == ProPlan.free
                ? 'Free plan'
                : access.available
                ? 'Continue with ${ProAccess.names[selected]}'
                : 'Available in Android app',
            onTap: selected == ProPlan.free || access.busy || !access.available
                ? null
                : () => access.buy(selected),
          ),
          const SizedBox(height: 14),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                eyebrow(context, 'YOUR USAGE'),
                const SizedBox(height: 10),
                Text(
                  'AI today: ${access.aiLimit == null ? 'Unlimited' : '${access.aiRequestsToday} / ${access.aiLimit} used · ${access.aiRemaining} remaining'}',
                ),
                const SizedBox(height: 6),
                Text(
                  'PDF this month: ${access.pdfLimit == null ? 'Unlimited' : '${access.pdfExportsThisMonth} / ${access.pdfLimit} used · ${access.pdfRemaining} remaining'}',
                ),
                const SizedBox(height: 8),
                caption(
                  context,
                  'AI resets on ${access.nextAiReset.year}-${access.nextAiReset.month.toString().padLeft(2, '0')}-${access.nextAiReset.day.toString().padLeft(2, '0')} at 12:00 AM local time. PDF usage resets on ${access.nextPdfReset.year}-${access.nextPdfReset.month.toString().padLeft(2, '0')}-01.',
                ),
              ],
            ),
          ),
          if (ProAccess.simulatorEnabled) ...[
            const SizedBox(height: 16),
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  eyebrow(context, 'OWNER TESTING · DEBUG ONLY'),
                  const SizedBox(height: 8),
                  caption(
                    context,
                    'This in-memory override is for development and QA. It does not create a store purchase or persist as a production entitlement.',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: plans
                        .map(
                          (plan) => OutlinedButton(
                            onPressed: () => access.setDebugPlan(plan),
                            child: Text('Test ${ProAccess.names[plan]}'),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Text('Active test plan: ${ProAccess.names[access.plan]}'),
                  Text(
                    'Unlocked: ${FeatureAccess.values.where(access.allows).map((f) => f.name).join(', ')}',
                  ),
                  Text(
                    'Locked: ${FeatureAccess.values.where((f) => !access.allows(f)).map((f) => f.name).join(', ')}',
                  ),
                  Wrap(
                    spacing: 7,
                    children: [
                      TextButton(
                        onPressed: access.resetDailyUsage,
                        child: const Text('Reset daily AI'),
                      ),
                      TextButton(
                        onPressed: access.resetMonthlyUsage,
                        child: const Text('Reset monthly PDFs'),
                      ),
                      TextButton(
                        onPressed: access.clearUsage,
                        child: const Text('Clear test usage'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          caption(
            context,
            'Store prices appear only when configured products are available. Client-side purchase status is not server-verified; production should validate receipts and manage renewals/revocations. Client API keys can be extracted, and external AI use may incur provider costs and rate limits.',
          ),
        ],
      );
    },
  );
}
