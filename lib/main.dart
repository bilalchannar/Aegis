import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'app_state.dart';
import 'ui/design.dart';
import 'ui/shield_art.dart';
import 'features/account.dart';
import 'features/check.dart';
import 'features/safety.dart';
import 'services/pro_access.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final state = AppState();
  bool splashVisible = true;
  @override
  void initState() {
    super.initState();
    state.load();
    ProAccess.instance.initialize();
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => splashVisible = false);
    });
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    state: state,
    child: ListenableBuilder(
      listenable: state,
      builder: (_, _) => ListenableBuilder(
        listenable: ProAccess.instance,
        builder: (_, _) => MaterialApp(
          title: 'Aegis — A calmer digital life',
          debugShowCheckedModeBanner: false,
          theme: appTheme(false),
          darkTheme: appTheme(true),
          themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
          home: splashVisible || !state.ready
              ? const SplashPage()
              : !state.onboarded
              ? const OnboardingPage()
              : !state.signedIn
              ? const AuthPage()
              : const AppShell(),
        ),
      ),
    ),
  );
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Brand(),
          const SizedBox(height: 18),
          Text(
            'A calmer digital life.',
            style: TextStyle(color: context.subtle, fontSize: 13),
          ),
          const SizedBox(height: 28),
          const CupertinoActivityIndicator(),
        ],
      ),
    ),
  );
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int page = 0;
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    const titles = [
      'A calmer\ndigital life.',
      'A second look.\nA better instinct.',
      'Your people.\nYour peace.',
    ];
    const bodies = [
      'For the messages, links and little moments\nthat make you pause. Meet Aegis.',
      'Understand the warning signs.\nKnow what to do next. Keep living.',
      'Build a trusted circle and a space of your own.\nAn account is always your choice.',
    ];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Brand(),
                              const Spacer(),
                              TextButton(
                                onPressed: app.completeOnboarding,
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: context.subtle,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: 170,
                                maxHeight: 350,
                              ),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey(page),
                                    tween: Tween(begin: -.05, end: .03),
                                    duration: const Duration(
                                      milliseconds: 1200,
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder: (_, value, child) =>
                                        Transform.rotate(
                                          angle:
                                              MediaQuery.disableAnimationsOf(
                                                context,
                                              )
                                              ? 0
                                              : value,
                                          child: child,
                                        ),
                                    child: SizedBox(
                                      width: 270,
                                      height: 270,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          const ShieldArt(size: 225),
                                          Positioned(
                                            bottom: 4,
                                            left: 7,
                                            right: 7,
                                            child: GlassPanel(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  14,
                                                ),
                                                child: Row(
                                                  children: [
                                                    iconTile(
                                                      context,
                                                      [
                                                        CupertinoIcons
                                                            .chat_bubble_text,
                                                        CupertinoIcons
                                                            .checkmark_shield,
                                                        CupertinoIcons.person_2,
                                                      ][page],
                                                      size: 35,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            [
                                                              'Something feels off?',
                                                              'A little more clarity.',
                                                              'You’re not on your own.',
                                                            ][page],
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            [
                                                              'Aegis is here for a second look.',
                                                              'Reasons, not just a verdict.',
                                                              'Keep a trusted person close.',
                                                            ][page],
                                                            style: TextStyle(
                                                              color: context
                                                                  .subtle,
                                                              fontSize: 9,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
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
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              titles[page],
                              key: ValueKey('title$page'),
                              textAlign: TextAlign.center,
                              style: headline(43),
                            ),
                          ),
                          const SizedBox(height: 17),
                          Text(
                            bodies[page],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.subtle,
                              fontSize: 13,
                              height: 1.8,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              3,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: i == page ? 25 : 6,
                                height: 5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: i == page ? green : context.line,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          ActionButton(
                            page == 2 ? 'Start with Aegis' : 'Continue',
                            onTap: () {
                              if (page == 2) {
                                app.completeOnboarding();
                              } else {
                                setState(() => page++);
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: page == 2
                                ? () {
                                    app.completeOnboarding();
                                    openPage(context, const AuthPage());
                                  }
                                : () => infoSheet(
                                    context,
                                    title: 'Private from the start',
                                    body:
                                        'On-device text checks work without an account. You decide whether to save history. Cloud services and sign-in are not connected in this preview.',
                                  ),
                            child: Text(
                              page == 2
                                  ? 'Create an account instead'
                                  : 'Private by default. Always your choice.',
                              style: TextStyle(
                                color: context.subtle,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final Widget page = switch (tab) {
      1 => const HistoryView(),
      3 => const LearnView(),
      4 => const ProfileView(),
      _ => HomeView(
        onHistory: () => setState(() => tab = 1),
        onLearn: () => setState(() => tab = 3),
        onProfile: () => setState(() => tab = 4),
      ),
    };
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Entrance(key: ValueKey(tab), child: page),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: GlassPanel(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 7,
                  ),
                  child: Row(
                    children: List.generate(5, (i) => navItem(context, i)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget navItem(BuildContext context, int i) {
    final active = tab == i;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: [
          'Home tab',
          'History tab',
          'Check',
          'Learn tab',
          'Profile tab',
        ][i],
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            if (i == 2) {
              openPage(context, const CheckPage());
            } else {
              setState(() => tab = i);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 230),
            padding: EdgeInsets.symmetric(vertical: i == 2 ? 3 : 11),
            decoration: BoxDecoration(
              color: active ? context.soft : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (i == 2)
                  Container(
                    width: 45,
                    height: 38,
                    decoration: BoxDecoration(
                      color: context.isDark ? mint : forest,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      CupertinoIcons.viewfinder,
                      color: context.isDark ? forest : mint,
                      size: 23,
                    ),
                  )
                else
                  Icon(
                    [
                      CupertinoIcons.house,
                      CupertinoIcons.clock,
                      CupertinoIcons.viewfinder,
                      CupertinoIcons.book,
                      CupertinoIcons.person_crop_circle,
                    ][i],
                    size: 21,
                    color: active
                        ? context.isDark
                              ? mint
                              : forest
                        : context.subtle,
                  ),
                const SizedBox(height: 5),
                Text(
                  ['Home', 'History', 'Check', 'Learn', 'Profile'][i],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: active || i == 2
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: active ? context.ink : context.subtle,
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

class HomeView extends StatelessWidget {
  final VoidCallback onHistory, onLearn, onProfile;
  const HomeView({
    super.key,
    required this.onHistory,
    required this.onLearn,
    required this.onProfile,
  });
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 23, 16, 125),
      children: [
        Row(
          children: [
            const Brand(),
            const Spacer(),
            IconButton(
              tooltip: 'Your updates',
              onPressed: () => openPage(context, const NotificationsPage()),
              icon: Icon(CupertinoIcons.bell, size: 21, color: context.ink),
            ),
            const SizedBox(width: 3),
            GestureDetector(
              onTap: onProfile,
              child: Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: context.soft,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.line),
                ),
                child: Center(
                  child: Text(
                    app.name == 'Your space'
                        ? 'A'
                        : app.name.characters.first.toUpperCase(),
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        eyebrow(
          context,
          app.name == 'Your space'
              ? 'A CALMER DIGITAL EVERYDAY'
              : 'A LITTLE PEACE, ${app.name.toUpperCase()}',
        ),
        const SizedBox(height: 10),
        Text('Less worry.\nMore living.', style: headline(39)),
        const SizedBox(height: 13),
        caption(context, 'Trust your instinct. Let’s find some clarity.'),
        const SizedBox(height: 25),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(29),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF163E35), Color(0xFF2A5745)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -30,
                top: 10,
                child: ShieldArt(size: 170),
              ),
              Padding(
                padding: const EdgeInsets.all(23),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Pill(
                      'YOUR SECOND OPINION',
                      color: mint,
                      background: Color(0xFF345648),
                      icon: CupertinoIcons.sparkles,
                    ),
                    const SizedBox(height: 21),
                    const Text(
                      'A little pause.\nA lot more clarity.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        letterSpacing: -.9,
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Messages, links, and things\nthat don’t feel quite right.',
                      style: TextStyle(
                        color: Color(0xFFB8CCBD),
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 23),
                    SizedBox(
                      width: double.infinity,
                      height: 49,
                      child: FilledButton(
                        onPressed: () => openPage(context, const CheckPage()),
                        style: FilledButton.styleFrom(
                          backgroundColor: mint,
                          foregroundColor: forest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(CupertinoIcons.viewfinder, size: 19),
                            SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                'Check something',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Icon(CupertinoIcons.arrow_up_right, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 23),
        Row(
          children: [
            _quick(context, 'Message', CupertinoIcons.chat_bubble_text, 0),
            const SizedBox(width: 10),
            _quick(context, 'Link', CupertinoIcons.link, 1),
            const SizedBox(width: 10),
            _quick(context, 'Screenshot', CupertinoIcons.photo, 2),
          ],
        ),
        const SizedBox(height: 17),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.lock, size: 11, color: context.subtle),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Private by default. No account needed.',
                style: TextStyle(color: context.subtle, fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        section(context, 'A little more in your corner'),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _tool(
                context,
                'Your trusted\ncircle',
                'A human second opinion',
                CupertinoIcons.person_2,
                const CirclePage(),
                context.soft,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _tool(
                context,
                'Before\nyou pay',
                'A 30-second pause',
                CupertinoIcons.hand_raised,
                const VerifyPage(),
                context.isDark
                    ? const Color(0xFF3C3528)
                    : const Color(0xFFF1ECDF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Surface(
          padding: EdgeInsets.zero,
          child: MenuRow(
            'Already shared something?',
            icon: CupertinoIcons.heart,
            subtitle: 'Let’s work through the next steps.',
            color: rust,
            onTap: () => openPage(context, const RecoveryPage()),
          ),
        ),
        const SizedBox(height: 28),
        section(
          context,
          'A sharper instinct',
          action: 'Explore  ↗',
          onTap: onLearn,
        ),
        const SizedBox(height: 11),
        const GuideCard(0),
        const SizedBox(height: 27),
        section(
          context,
          'Recent moments of clarity',
          action: 'View all',
          onTap: onHistory,
        ),
        const SizedBox(height: 10),
        if (app.history.isEmpty)
          Surface(
            child: Row(
              children: [
                iconTile(context, CupertinoIcons.clock, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: caption(
                    context,
                    'Your first check starts a clearer story.\nResults will appear here.',
                  ),
                ),
              ],
            ),
          )
        else
          ...app.history
              .take(2)
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HistoryCard(r),
                ),
              ),
        const SizedBox(height: 25),
        const BannerPreview(),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'A LITTLE AWARENESS GOES A LONG WAY',
            style: TextStyle(
              color: context.subtle.withValues(alpha: .7),
              fontSize: 8,
              letterSpacing: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _quick(BuildContext context, String title, IconData icon, int mode) =>
      Expanded(
        child: GestureDetector(
          onTap: () => openPage(context, CheckPage(initialMode: mode)),
          child: Surface(
            padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 8),
            radius: 21,
            child: Column(
              children: [
                Icon(icon, color: context.isDark ? mint : green, size: 22),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  Widget _tool(
    BuildContext context,
    String title,
    String detail,
    IconData icon,
    Widget page,
    Color color,
  ) => GestureDetector(
    onTap: () => openPage(context, page),
    child: Surface(
      color: color,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 23, color: context.isDark ? mint : forest),
              const Spacer(),
              Icon(
                CupertinoIcons.arrow_up_right,
                size: 14,
                color: context.subtle,
              ),
            ],
          ),
          const SizedBox(height: 23),
          Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              letterSpacing: -.6,
              height: 1.08,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 9),
          Text(detail, style: TextStyle(fontSize: 9, color: context.subtle)),
        ],
      ),
    ),
  );
}

class BannerPreview extends StatelessWidget {
  const BannerPreview({super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => infoSheet(
      context,
      title: 'Banner placement preview',
      body:
          'This is the planned space for a Unity banner on the free plan. No advertising SDK is connected. Banners will stay away from results, recovery steps and the bottom navigation.',
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: context.line),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.rectangle, color: context.subtle, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A space for thoughtful sponsors',
                  style: TextStyle(color: context.subtle, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Text(
                  'BANNER AD · DESIGN PREVIEW',
                  style: TextStyle(
                    color: context.subtle.withValues(alpha: .7),
                    fontSize: 8,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Icon(CupertinoIcons.info_circle, color: context.subtle, size: 14),
        ],
      ),
    ),
  );
}
