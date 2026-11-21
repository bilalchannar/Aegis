import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../app_state.dart';
import '../ui/design.dart';
import '../services/pro_access.dart';
import 'safety.dart';
export '../ui/design.dart' show SubscriptionPage;

final _googleSignIn = GoogleSignIn(scopes: <String>['email', 'profile']);

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 125),
      children: [
        Row(
          children: [
            const Brand(),
            const Spacer(),
            IconButton(
              tooltip: 'Settings',
              onPressed: () => openPage(context, const SettingsPage()),
              icon: const Icon(CupertinoIcons.gear_alt, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Text('Your peace.\nYour space.', style: headline(37)),
        const SizedBox(height: 24),
        Surface(
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [mint, const Color(0xFF9AC6AB)],
                  ),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Text(
                    app.name == 'Your space'
                        ? 'A'
                        : app.name.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: forest,
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Pill('GUEST PROFILE', icon: CupertinoIcons.lock),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit profile',
                onPressed: () => openPage(context, const EditProfilePage()),
                icon: const Icon(CupertinoIcons.pencil, size: 19),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        caption(context, 'Your personal space, even without an account.'),
        const SizedBox(height: 25),
        GestureDetector(
          onTap: () => openPage(context, const SubscriptionPage()),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [forest, Color(0xFF2B5848)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Pill(
                      'AEGIS ${ProAccess.names[ProAccess.instance.plan]!.toUpperCase()}',
                      color: mint,
                      background: Color(0xFF365849),
                      icon: CupertinoIcons.sparkles,
                    ),
                    Spacer(),
                    Icon(CupertinoIcons.arrow_up_right, color: mint, size: 19),
                  ],
                ),
                const SizedBox(height: 17),
                Text(
                  '${ProAccess.names[ProAccess.instance.plan]} plan\nfor your peace of mind.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    letterSpacing: -.8,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  'View plan and usage  →',
                  style: TextStyle(
                    color: mint.withValues(alpha: .9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        eyebrow(context, 'YOUR ACCOUNT'),
        const SizedBox(height: 12),
        Surface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MenuRow(
                app.signedIn
                    ? 'Signed in account'
                    : 'Sign in or create an account',
                icon: CupertinoIcons.person_crop_circle_badge_plus,
                subtitle: app.signedIn
                    ? (app.accountEmail?.toLowerCase().endsWith('@gmail.com') ==
                              true
                          ? 'Gmail'
                          : app.accountProvider == 'Google'
                          ? 'Google account'
                          : 'Email account')
                    : '',
                onTap: app.signedIn
                    ? () => _showAccountDetails(context, app)
                    : () => openPage(context, const AuthPage(signUp: false)),
              ),
              Divider(height: 1, indent: 66, color: context.line),
              MenuRow(
                'Your trusted circle',
                icon: CupertinoIcons.person_2,
                subtitle:
                    '${app.contacts.length} trusted ${app.contacts.length == 1 ? 'person' : 'people'} on this device',
                onTap: () => openPage(context, const CirclePage()),
              ),
              Divider(height: 1, indent: 66, color: context.line),
              MenuRow(
                'My plan',
                icon: CupertinoIcons.star_circle,
                subtitle:
                    '${ProAccess.names[ProAccess.instance.plan]} · AI ${ProAccess.instance.aiLimit == null ? 'Unlimited' : '${ProAccess.instance.aiRequestsToday}/${ProAccess.instance.aiLimit} today'} · PDFs ${ProAccess.instance.pdfLimit == null ? 'Unlimited' : '${ProAccess.instance.pdfExportsThisMonth}/${ProAccess.instance.pdfLimit} this month'}',
                onTap: () => openPage(context, const SubscriptionPage()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.star_circle, color: green),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${ProAccess.names[ProAccess.instance.plan]} plan usage',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Pill(ProAccess.names[ProAccess.instance.plan]!.toUpperCase()),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'AI requests today: ${ProAccess.instance.aiLimit == null ? 'Unlimited' : '${ProAccess.instance.aiRequestsToday} used · ${ProAccess.instance.aiRemaining} remaining'}',
              ),
              const SizedBox(height: 6),
              Text(
                'PDF reports this month: ${ProAccess.instance.pdfLimit == null ? 'Unlimited' : '${ProAccess.instance.pdfExportsThisMonth} used · ${ProAccess.instance.pdfRemaining} remaining'}',
              ),
              const SizedBox(height: 8),
              caption(
                context,
                'AI reset: ${ProAccess.instance.nextAiReset.year}-${ProAccess.instance.nextAiReset.month.toString().padLeft(2, '0')}-${ProAccess.instance.nextAiReset.day.toString().padLeft(2, '0')} at 12:00 AM local time. PDF reset: ${ProAccess.instance.nextPdfReset.year}-${ProAccess.instance.nextPdfReset.month.toString().padLeft(2, '0')}-01.',
              ),
              const SizedBox(height: 12),
              ActionButton(
                'Manage plans',
                secondary: true,
                onTap: () => openPage(context, const SubscriptionPage()),
              ),
              if (ProAccess.instance.available)
                Center(
                  child: TextButton(
                    onPressed: ProAccess.instance.busy
                        ? null
                        : ProAccess.instance.restore,
                    child: const Text('Restore purchases'),
                  ),
                ),
            ],
          ),
        ),
        if (ProAccess.simulatorEnabled) ...[
          const SizedBox(height: 12),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.wrench_fill, color: green),
                    const SizedBox(width: 9),
                    Expanded(
                      child: eyebrow(context, 'OWNER TESTING · DEBUG ONLY'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                caption(
                  context,
                  'Switch plans to test feature access. This temporary override does not create a purchase.',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ProPlan.values
                      .map(
                        (plan) => OutlinedButton(
                          onPressed: () =>
                              ProAccess.instance.setDebugPlan(plan),
                          child: Text('Test ${ProAccess.names[plan]}'),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 7),
                Text(
                  'Active test plan: ${ProAccess.names[ProAccess.instance.plan]}',
                ),
              ],
            ),
          ),
        ],
        if (app.signedIn) ...[
          const SizedBox(height: 18),
          ActionButton(
            'Sign out',
            icon: CupertinoIcons.square_arrow_right,
            secondary: true,
            onTap: () => _confirmSignOut(context, app),
          ),
        ],
        const SizedBox(height: 25),
        eyebrow(context, 'MAKE IT YOURS'),
        const SizedBox(height: 12),
        Surface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MenuRow(
                'Appearance & preferences',
                icon: CupertinoIcons.slider_horizontal_3,
                subtitle: 'Theme, language and notifications',
                onTap: () => openPage(context, const SettingsPage()),
              ),
              Divider(height: 1, indent: 66, color: context.line),
              MenuRow(
                'Privacy centre',
                icon: CupertinoIcons.lock_shield,
                subtitle: 'You decide what stays on your device',
                onTap: () => openPage(context, const PrivacyPage()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Center(child: caption(context, 'Designed around you. Not your data.')),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AppState app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out of Aegis?'),
        content: const Text(
          'Your local profile, contacts, and saved checks will remain on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (app.accountProvider == 'Google') {
        try {
          await _googleSignIn.signOut();
        } catch (_) {
          // Signing out of the local Aegis session still takes precedence.
        }
      }
      app.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have been signed out.')),
        );
      }
    }
  }

  Future<void> _showAccountDetails(BuildContext context, AppState app) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Signed in account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _accountDetail(context, 'Name', app.name),
            const SizedBox(height: 14),
            _accountDetail(
              context,
              app.accountProvider == 'Google' ? 'Google account' : 'Email',
              app.accountEmail ?? 'Not available',
            ),
            const SizedBox(height: 14),
            _accountDetail(context, 'Status', 'Signed in on this device'),
            const SizedBox(height: 14),
            Text(
              'Your password is kept private and is never shown here.',
              style: TextStyle(
                color: context.subtle,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _accountDetail(BuildContext context, String label, String value) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: context.subtle, fontSize: 11)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      );
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final name = TextEditingController();
  bool loaded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded) {
      name.text = AppScope.of(context).name == 'Your space'
          ? ''
          : AppScope.of(context).name;
      loaded = true;
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Your profile',
    children: [
      const SizedBox(height: 20),
      Text('A space that\nfeels like you.', style: headline()),
      const SizedBox(height: 30),
      const Center(
        child: CircleAvatar(
          radius: 46,
          backgroundColor: mint,
          child: Icon(CupertinoIcons.person, size: 40, color: forest),
        ),
      ),
      const SizedBox(height: 30),
      TextField(
        controller: name,
        maxLength: 30,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'What should we call you?',
          fillColor: context.card,
        ),
      ),
      const SizedBox(height: 18),
      ActionButton(
        'Save profile',
        onTap: () {
          AppScope.of(context).setName(name.text);
          Navigator.pop(context);
        },
      ),
      const SizedBox(height: 14),
      caption(
        context,
        'This is a local profile. Your name stays on this device and does not create an account.',
      ),
    ],
  );
}

class AuthPage extends StatefulWidget {
  final bool signUp;
  const AuthPage({super.key, this.signUp = true});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late bool signUp = widget.signUp;
  bool hidden = true;
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> _continueWithGoogle() async {
    final app = AppScope.of(context);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      app.signInWithGoogle(
        accountName: googleUser.displayName ?? '',
        email: googleUser.email,
      );
    } catch (error, stackTrace) {
      debugPrint('Google sign-in failed: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Google sign-in failed: $error',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Your account',
    children: [
      const SizedBox(height: 8),
      const Pill('ALWAYS OPTIONAL', icon: CupertinoIcons.lock),
      const SizedBox(height: 23),
      Text(
        signUp
            ? 'Good instincts.\nEven better together.'
            : 'Welcome back.\nBreathe a little easier.',
        style: headline(35),
      ),
      const SizedBox(height: 14),
      caption(
        context,
        signUp
            ? 'A home for your checks, your preferences, and the people you look out for.'
            : 'Your personal space is waiting for you.',
      ),
      const SizedBox(height: 26),
      _social(
        context,
        'Continue with Google',
        Icons.g_mobiledata,
        _continueWithGoogle,
      ),
      const SizedBox(height: 23),
      Row(
        children: [
          Expanded(child: Divider(color: context.line)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'or use email',
              style: TextStyle(color: context.subtle, fontSize: 11),
            ),
          ),
          Expanded(child: Divider(color: context.line)),
        ],
      ),
      const SizedBox(height: 20),
      Form(
        key: form,
        child: Column(
          children: [
            if (signUp) ...[
              TextFormField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Your name',
                  prefixIcon: const Icon(CupertinoIcons.person, size: 19),
                  fillColor: context.card,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Email address',
                prefixIcon: const Icon(CupertinoIcons.mail, size: 19),
                fillColor: context.card,
              ),
              validator: (v) =>
                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v ?? '')
                  ? null
                  : 'Enter a valid email address',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: password,
              obscureText: hidden,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(CupertinoIcons.lock, size: 19),
                fillColor: context.card,
                suffixIcon: IconButton(
                  tooltip: hidden ? 'Show password' : 'Hide password',
                  icon: Icon(
                    hidden ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                    size: 19,
                  ),
                  onPressed: () => setState(() => hidden = !hidden),
                ),
              ),
              validator: (v) =>
                  (v ?? '').length >= 8 ? null : 'Use at least 8 characters',
            ),
          ],
        ),
      ),
      if (!signUp)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => infoSheet(
              context,
              title: 'Reset your password',
              body:
                  'Password reset email will be available after account services are connected. No email is sent in this preview.',
            ),
            child: const Text(
              'Forgot password?',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      const SizedBox(height: 22),
      ActionButton(
        signUp ? 'Create account' : 'Sign in',
        onTap: () async {
          if (form.currentState!.validate()) {
            final app = AppScope.of(context);
            final success = signUp
                ? app.createAccount(
                    accountName: name.text,
                    email: email.text,
                    password: password.text,
                  )
                : app.signIn(email.text, password.text);
            if (!success) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Email or password does not match this device account.',
                    ),
                  ),
                );
              }
              return;
            }
          }
        },
      ),
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            signUp ? 'Already have an account?' : 'New to Aegis?',
            style: TextStyle(color: context.subtle, fontSize: 12),
          ),
          TextButton(
            onPressed: () => setState(() => signUp = !signUp),
            child: Text(
              signUp ? 'Sign in' : 'Create account',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        'Your account session is saved on this device.\nSign in or create an account to continue.',
        textAlign: TextAlign.center,
        style: TextStyle(color: context.subtle, fontSize: 10, height: 1.7),
      ),
    ],
  );
  Widget _social(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback tap, {
    bool dark = false,
  }) => SizedBox(
    height: 54,
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: tap,
      icon: Icon(icon, size: icon == Icons.g_mobiledata ? 31 : 23),
      label: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: dark ? context.ink : context.card,
        foregroundColor: dark ? context.card : context.ink,
        side: BorderSide(color: context.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
    ),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageFrame(
      title: 'Preferences',
      children: [
        const SizedBox(height: 12),
        Text('Make yourself\ncomfortable.', style: headline()),
        const SizedBox(height: 28),
        eyebrow(context, 'LOOK & FEEL'),
        const SizedBox(height: 12),
        Surface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MenuRow(
                'Dark appearance',
                icon: CupertinoIcons.moon,
                subtitle: app.dark
                    ? 'A softer glow after hours'
                    : 'Light, fresh and clear',
                trailing: CupertinoSwitch(
                  value: app.dark,
                  activeTrackColor: green,
                  onChanged: app.setDark,
                ),
              ),
              Divider(height: 1, indent: 65, color: context.line),
              MenuRow(
                'Language',
                icon: CupertinoIcons.globe,
                subtitle: 'English',
                onTap: () => infoSheet(
                  context,
                  title: 'Aegis, in your language',
                  body:
                      'English is available now. Urdu, Hindi and Arabic are planned for a later release. Your language will be selectable here.',
                  icon: CupertinoIcons.globe,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        eyebrow(context, 'NOTIFICATIONS'),
        const SizedBox(height: 12),
        Surface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MenuRow(
                'Gentle reminders',
                icon: CupertinoIcons.bell,
                subtitle: 'A little nudge to stay aware',
                trailing: CupertinoSwitch(
                  value: app.reminders,
                  activeTrackColor: green,
                  onChanged: app.setReminders,
                ),
              ),
              Divider(height: 1, indent: 65, color: context.line),
              MenuRow(
                'Safety tips',
                icon: CupertinoIcons.lightbulb,
                subtitle: 'Small lessons, when they matter',
                trailing: CupertinoSwitch(
                  value: app.safetyTips,
                  activeTrackColor: green,
                  onChanged: app.setSafetyTips,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        caption(
          context,
          'Preferences are saved on this device. Notification delivery will be connected later.',
        ),
        const SizedBox(height: 28),
        eyebrow(context, 'YOUR DATA'),
        const SizedBox(height: 12),
        Surface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MenuRow(
                'Save check history',
                icon: CupertinoIcons.clock,
                subtitle: 'Only on this device',
                trailing: CupertinoSwitch(
                  value: app.saveChecks,
                  activeTrackColor: green,
                  onChanged: app.setSaveChecks,
                ),
              ),
              Divider(height: 1, indent: 65, color: context.line),
              MenuRow(
                'Privacy centre',
                icon: CupertinoIcons.lock_shield,
                onTap: () => openPage(context, const PrivacyPage()),
              ),
              Divider(height: 1, indent: 65, color: context.line),
              MenuRow(
                'Clear check history',
                icon: CupertinoIcons.trash,
                color: rust,
                onTap: () async {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Clear your checks?'),
                      content: const Text(
                        'Saved and session checks will be removed from this device.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Keep'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (yes == true) {
                    app.clearHistory();
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Aegis · Design preview 2.0\nMade for a more confident everyday.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.subtle, fontSize: 11, height: 1.8),
        ),
      ],
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Privacy centre',
    children: [
      const SizedBox(height: 20),
      iconTile(context, CupertinoIcons.lock_shield, size: 65),
      const SizedBox(height: 25),
      Text('Your trust is\nthe whole point.', style: headline()),
      const SizedBox(height: 15),
      caption(
        context,
        'Here is exactly how this preview handles your information.',
      ),
      const SizedBox(height: 25),
      ...[
        (
          CupertinoIcons.device_phone_portrait,
          'Checks stay with you',
          'Text checks run on your device. History is saved only when you switch it on. Saved history uses local app storage, not an encrypted vault.',
        ),
        (
          CupertinoIcons.person,
          'No account required',
          'Your guest profile and trusted circle stay on this device. Google sign-in uses Google OAuth; Aegis saves your name and email locally. Email and Apple sign-in are previews.',
        ),
        (
          CupertinoIcons.sparkles,
          'AI, with your choice',
          'Cloud analysis will be managed by Aegis when connected. You will not need an API key. This preview does not upload your screenshots or text.',
        ),
        (
          CupertinoIcons.rectangle,
          'A clear line around ads',
          'The banner is a labelled design placeholder. No ad SDK is running and no advertising data is collected.',
        ),
      ].map(
        (r) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(r.$1, size: 21, color: green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        r.$2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                caption(context, r.$3),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      caption(
        context,
        'This explains the current design preview. A published privacy policy and service terms will be added before launch.',
      ),
    ],
  );
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Your updates',
    children: [
      const SizedBox(height: 55),
      Center(child: iconTile(context, CupertinoIcons.bell, size: 80)),
      const SizedBox(height: 28),
      Text(
        'A little quiet\nis a good thing.',
        textAlign: TextAlign.center,
        style: headline(),
      ),
      const SizedBox(height: 16),
      Text(
        'Your updates will appear here.\nNo notifications have been delivered yet.',
        textAlign: TextAlign.center,
        style: TextStyle(color: context.subtle, fontSize: 14, height: 1.7),
      ),
      const SizedBox(height: 35),
      ActionButton(
        'Notification preferences',
        secondary: true,
        onTap: () => openPage(context, const SettingsPage()),
      ),
    ],
  );
}
