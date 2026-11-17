import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../ui/design.dart';
import '../services/offline_content.dart';
import '../services/pro_access.dart';
import '../services/custom_rules.dart';
import '../models/audit_report.dart';
import 'dashboard.dart';
export '../ui/design.dart' show SubscriptionPage;

class CirclePage extends StatelessWidget {
  const CirclePage({super.key});

  String? _whatsappUrl(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return null;
    return 'https://wa.me/$digits';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageFrame(
      title: 'Trusted circle',
      children: [
        const SizedBox(height: 15),
        const Pill('A HUMAN SECOND OPINION', icon: CupertinoIcons.heart),
        const SizedBox(height: 22),
        Text('Some things are\nbetter checked together.', style: headline(33)),
        const SizedBox(height: 15),
        caption(
          context,
          'Keep a trusted person close. If a message feels urgent, pause and verify with someone you know.',
        ),
        const SizedBox(height: 26),
        if (app.contacts.isEmpty)
          Surface(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final item in [
                      (CupertinoIcons.person, Color(0xFFE9E3D3)),
                      (CupertinoIcons.heart, mint),
                      (CupertinoIcons.person, Color(0xFFD8E8E1)),
                    ])
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 59,
                        height: 59,
                        decoration: BoxDecoration(
                          color: item.$2,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.$1, color: forest, size: 25),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Build your small circle.',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  'A parent. A friend. Someone whose\njudgement helps you feel grounded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.subtle,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          )
        else
          ...List.generate(app.contacts.length, (i) {
            final person = app.contacts[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Surface(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: context.soft,
                      child: Text(
                        person['name']!.characters.first.toUpperCase(),
                        style: TextStyle(color: context.ink),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person['name']!,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            person['detail']!,
                            style: TextStyle(
                              color: context.subtle,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy contact',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: person['detail']!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Contact copied. Verify through a number you trust.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(CupertinoIcons.doc_on_doc, size: 18),
                    ),
                    IconButton(
                      tooltip: 'Remove contact',
                      onPressed: () async {
                        final yes = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Remove this contact?'),
                            content: const Text(
                              'This only removes the saved entry in Aegis.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Keep'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                        if (yes == true) {
                          app.removeContact(i);
                        }
                      },
                      icon: const Icon(
                        CupertinoIcons.minus_circle,
                        size: 18,
                        color: rust,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Open WhatsApp',
                      onPressed: () async {
                        final url = _whatsappUrl(person['detail']!);
                        if (url == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Save a valid phone number with country code first.',
                              ),
                            ),
                          );
                          return;
                        }
                        final opened = await launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        );
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open WhatsApp.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        CupertinoIcons.chat_bubble_2,
                        size: 18,
                        color: green,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 20),
        ActionButton(
          'Add a trusted person',
          icon: CupertinoIcons.plus,
          onTap: () => openPage(context, const AddContactPage()),
        ),
        const SizedBox(height: 25),
        Surface(
          color: context.soft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              eyebrow(context, 'THE CALL-BACK RULE'),
              const SizedBox(height: 12),
              const Text(
                'A familiar voice isn’t proof.',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 10),
              caption(
                context,
                'If someone claims to be family and asks for money, contact them on a number you already trust. Voice recordings and caller IDs can be imitated.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        caption(
          context,
          'Contacts are saved locally. Aegis does not access your address book, invite anyone, or send messages.',
        ),
      ],
    );
  }
}

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});
  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final name = TextEditingController(), detail = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    name.dispose();
    detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Add someone you trust',
    children: [
      const SizedBox(height: 20),
      Text('A familiar voice.\nA clearer perspective.', style: headline()),
      const SizedBox(height: 30),
      Form(
        key: form,
        child: Column(
          children: [
            TextFormField(
              controller: name,
              maxLength: 40,
              decoration: InputDecoration(
                labelText: 'Name',
                fillColor: context.card,
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Add their name' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: detail,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: 'Phone number or email',
                fillColor: context.card,
              ),
              validator: (v) => (v ?? '').trim().length < 5
                  ? 'Add a contact detail you already trust'
                  : null,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      ActionButton(
        'Save trusted person',
        onTap: () {
          if (form.currentState!.validate()) {
            AppScope.of(context).addContact(name.text, detail.text);
            Navigator.pop(context);
          }
        },
      ),
      const SizedBox(height: 15),
      caption(
        context,
        'Use a contact detail you have verified independently. Saving a contact does not notify them.',
      ),
    ],
  );
}

const recoveryTitles = [
  'I sent money',
  'I shared a password',
  'I shared a code',
];
const recoverySteps = [
  [
    (
      'Contact your payment provider',
      'Use its official app or a known number. Report the scam promptly and ask whether the payment can be reversed.',
    ),
    (
      'Keep the evidence',
      'Save the transaction reference and relevant messages for your provider.',
    ),
    (
      'Stop further payments',
      'Be wary of anyone charging a fee to recover your money.',
    ),
  ],
  [
    (
      'Change the password',
      'Open the real service directly. Replace the exposed password and any reused copies.',
    ),
    (
      'Secure the account',
      'Enable two-factor authentication and review unfamiliar sign-ins.',
    ),
    (
      'Use official recovery',
      'If locked out, follow the provider’s account recovery process.',
    ),
  ],
  [
    (
      'Contact the account provider',
      'Tell them a verification code was shared. Use an independently verified channel.',
    ),
    (
      'Review account access',
      'Check recent activity and secure the account through its official app.',
    ),
    (
      'Check related payments',
      'Report unfamiliar transactions to the relevant provider.',
    ),
  ],
];

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key});
  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  int scenario = 0;
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final done = List.generate(
      3,
      (i) => '$scenario:$i',
    ).where(app.completedSteps.contains).length;
    return PageFrame(
      title: 'Your recovery plan',
      children: [
        const SizedBox(height: 12),
        const Pill(
          'ONE STEP AT A TIME',
          color: rust,
          icon: CupertinoIcons.heart,
        ),
        const SizedBox(height: 22),
        Text('Take a breath.\nThere’s a next step.', style: headline()),
        const SizedBox(height: 15),
        caption(
          context,
          'You are not the first person this has happened to. Start with what happened, then work through your next steps.',
        ),
        const SizedBox(height: 25),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: List.generate(
            3,
            (i) => ChoiceChip(
              label: Text(
                recoveryTitles[i],
                style: const TextStyle(fontSize: 11),
              ),
              selected: scenario == i,
              onSelected: (_) => setState(() => scenario = i),
            ),
          ),
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(
              child: Text(
                'Your next steps',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$done of 3',
              style: TextStyle(color: context.subtle, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(end: done / 3),
          duration: const Duration(milliseconds: 300),
          builder: (_, value, _) => LinearProgressIndicator(
            value: value,
            color: green,
            backgroundColor: context.line,
            minHeight: 5,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 21),
        ...List.generate(3, (i) {
          final step = recoverySteps[scenario][i];
          final complete = app.completedSteps.contains('$scenario:$i');
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              checked: complete,
              button: true,
              label: step.$1,
              child: GestureDetector(
                onTap: () => app.toggleStep('$scenario:$i'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: complete ? context.soft : context.card,
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: complete
                          ? green.withValues(alpha: .3)
                          : context.line,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        complete
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                        color: complete ? green : context.subtle,
                        size: 23,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.$1,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 9),
                            caption(context, step.$2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        if (done == 3)
          Entrance(
            child: Surface(
              color: context.soft,
              child: const Row(
                children: [
                  Icon(CupertinoIcons.checkmark_seal, color: green),
                  SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      'You’ve worked through these steps. Keep following your provider’s guidance.',
                      style: TextStyle(fontSize: 13, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        caption(
          context,
          'Progress is saved on this device. These steps don’t submit reports or guarantee recovery. Source: FTC consumer guidance; local reporting routes vary by country.',
        ),
        const SizedBox(height: 20),
        ActionButton(
          'Reach out to someone you trust',
          secondary: true,
          icon: CupertinoIcons.person_2,
          onTap: () => openPage(context, const CirclePage()),
        ),
      ],
    );
  }
}

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});
  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final checked = <int>{};
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Before you pay',
    children: [
      const SizedBox(height: 18),
      iconTile(context, CupertinoIcons.hand_raised, size: 64),
      const SizedBox(height: 22),
      Text('A 30-second pause.\nA better decision.', style: headline(33)),
      const SizedBox(height: 15),
      caption(context, 'A short ritual before sending money to someone new.'),
      const SizedBox(height: 26),
      ...List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Surface(
            padding: EdgeInsets.zero,
            child: CheckboxListTile(
              value: checked.contains(i),
              activeColor: green,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                [
                  'I verified who I’m paying',
                  'I checked the request independently',
                  'I’m not being pressured to rush',
                ][i],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: Text(
                  [
                    'Using a trusted contact or official app.',
                    'Without using links from this message.',
                    'I have time to ask questions.',
                  ][i],
                  style: TextStyle(color: context.subtle, fontSize: 11),
                ),
              ),
              onChanged: (_) => setState(() {
                if (!checked.add(i)) {
                  checked.remove(i);
                }
              }),
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Surface(
          key: ValueKey(checked.length == 3),
          color: context.soft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                checked.length == 3
                    ? 'You made room to think.'
                    : 'Unsure about any of these?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              caption(
                context,
                checked.length == 3
                    ? 'This checklist supports your judgement. It cannot confirm a recipient or payment is safe.'
                    : 'Pause the payment and ask someone you trust. There is no need to decide under pressure.',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      ActionButton(
        'Open trusted circle',
        secondary: true,
        onTap: () => openPage(context, const CirclePage()),
      ),
    ],
  );
}

const quizQuestions = [
  (
    '“Your bank account closes in 10 minutes. Reply with your OTP to keep it active.”',
    ['Reply quickly', 'Open the bank’s official app', 'Ask the sender for ID'],
    1,
    'Pressure plus a request for a secret code is a strong warning sign. Verify independently.',
  ),
  (
    '“Hi Mum, new number. My phone broke. Can you transfer money right now?”',
    [
      'Call the old, trusted number',
      'Send a small test payment',
      'Trust the familiar greeting',
    ],
    0,
    'A familiar name or voice is not enough. Use a number you already know to verify the story.',
  ),
  (
    '“You won! Pay a small processing fee to receive your prize.”',
    ['Pay to claim it', 'Share bank details', 'Pause and verify the promotion'],
    2,
    'Unexpected rewards that require payment deserve scrutiny. Don’t let excitement replace verification.',
  ),
  (
    'A caller requests an OTP to cancel a transfer.',
    ['Share it', 'Hang up and call official support', 'Send screenshot'],
    1,
    'An OTP can authorize account access or a transfer. Never share it.',
  ),
  (
    'A recruiter asks for an upfront fee for a guaranteed job.',
    [
      'Pay to reserve',
      'Verify the employer and refuse upfront fees',
      'Share ID in chat',
    ],
    1,
    'Upfront fees and unrealistic guarantees are warning signs.',
  ),
  (
    'A delivery text links to a lookalike payment page.',
    [
      'Pay there',
      'Check through the carrier app directly',
      'Reuse bank password',
    ],
    1,
    'Navigate to the carrier independently instead of using unsolicited links.',
  ),
];

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int question = 0, score = 0;
  int? selected;
  bool complete = false;
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final questions = ProAccess.instance.plan == ProPlan.free
        ? quizQuestions.take(3).toList()
        : quizQuestions;
    if (complete) {
      return PageFrame(
        title: 'Instinct practice',
        children: [
          const SizedBox(height: 50),
          Center(
            child: iconTile(context, CupertinoIcons.checkmark_seal, size: 90),
          ),
          const SizedBox(height: 28),
          Text(
            'A sharper instinct.\nOne check at a time.',
            textAlign: TextAlign.center,
            style: headline(),
          ),
          const SizedBox(height: 20),
          Text(
            '$score / ${questions.length} thoughtful choices',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: green),
          ),
          const SizedBox(height: 18),
          Text(
            'There’s no perfect score in real life.\nThe habit of pausing is what matters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.subtle, height: 1.7),
          ),
          const SizedBox(height: 34),
          ActionButton(
            'Practice again',
            onTap: () => setState(() {
              question = 0;
              score = 0;
              selected = null;
              complete = false;
            }),
          ),
          if (ProAccess.instance.plan == ProPlan.free) ...[
            const SizedBox(height: 10),
            ActionButton(
              'Unlock the complete quiz',
              secondary: true,
              onTap: () => openPage(context, const SubscriptionPage()),
            ),
          ],
          const SizedBox(height: 14),
          ActionButton(
            'Back to learning',
            secondary: true,
            onTap: () => Navigator.pop(context),
          ),
        ],
      );
    }
    final q = questions[question];
    return PageFrame(
      key: ValueKey(question),
      title: 'Spot the scam',
      children: [
        const SizedBox(height: 15),
        Row(
          children: [
            const Pill('60-SECOND PRACTICE', icon: CupertinoIcons.bolt),
            const Spacer(),
            Text(
              '${question + 1} / ${questions.length}',
              style: TextStyle(color: context.subtle, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Text('What would\nyou do next?', style: headline()),
        const SizedBox(height: 26),
        Surface(
          color: context.soft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              eyebrow(context, 'EXAMPLE MESSAGE'),
              const SizedBox(height: 17),
              Text(
                q.$1,
                style: const TextStyle(
                  fontSize: 21,
                  height: 1.45,
                  letterSpacing: -.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        ...List.generate(
          q.$2.length,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: OutlinedButton(
              onPressed: selected != null
                  ? null
                  : () => setState(() {
                      selected = i;
                      if (i == q.$3) {
                        score++;
                      }
                    }),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(18),
                backgroundColor: selected == i ? context.soft : context.card,
                side: BorderSide(
                  color: selected != null && i == q.$3 ? green : context.line,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${i + 1}'.padLeft(2, '0'),
                    style: TextStyle(color: context.subtle, fontSize: 11),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      q.$2[i],
                      style: TextStyle(color: context.ink, fontSize: 13),
                    ),
                  ),
                  if (selected != null && i == q.$3)
                    const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: green,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (selected != null) ...[
          const SizedBox(height: 10),
          Entrance(
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected == q.$3
                        ? 'That’s a good instinct.'
                        : 'Here’s a useful clue.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  caption(context, q.$4),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ActionButton(
            question == questions.length - 1
                ? 'See my progress'
                : 'Next example',
            onTap: () {
              if (question == questions.length - 1) {
                app.saveQuiz((score * 100 / questions.length).round());
                setState(() => complete = true);
              } else {
                setState(() {
                  question++;
                  selected = null;
                });
              }
            },
          ),
        ],
      ],
    );
  }
}

const guideTitles = [
  'That parcel text?\nLet’s unpack it.',
  'When “easy money”\nasks for a deposit.',
  'Your one-time code\nis for your eyes only.',
];
const guideBodies = [
  'A text says your parcel is waiting. There’s just a small delivery fee. It feels ordinary — and that is the trick.\n\nLook for the pressure\nScammers ask you to act immediately so you won’t stop to think.\n\nCheck independently\nOpen the courier’s official app or type its known website yourself. Check whether you actually have a matching delivery.\n\nKeep your details close\nA professional-looking page or familiar logo does not verify the sender.',
  'A new job, an unexpected prize, or an investment opportunity sounds exciting. Then comes a fee before you can receive anything.\n\nQuestion the promise\nUnrealistic returns, secrecy and advance payments are reasons to pause.\n\nFind the real organisation\nUse independently verified contact details. A screenshot of earnings is not proof.\n\nAsk for another perspective\nA trusted person can help you notice what excitement makes easy to overlook.',
  'A caller sounds professional. They know your name and say they need the code that just arrived.\n\nA code can be a key\nIt may authorise a sign-in or a payment. Treat it like a password.\n\nVerify somewhere else\nEnd an unexpected conversation and open the organisation’s official app yourself.\n\nGet help early\nIf you already shared something, use the recovery plan to organise your next steps.',
];

class GuideCard extends StatelessWidget {
  final int index;
  const GuideCard(this.index, {super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => openPage(context, GuidePage(index)),
    child: Surface(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 78,
            decoration: BoxDecoration(
              color: [
                const Color(0xFFEFE5CE),
                const Color(0xFFDFE9E0),
                const Color(0xFFE6E3F0),
              ][index],
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              [
                CupertinoIcons.cube_box,
                CupertinoIcons.money_dollar_circle,
                CupertinoIcons.lock_shield,
              ][index],
              color: [amber, green, const Color(0xFF8B80AC)][index],
              size: 29,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                eyebrow(
                  context,
                  [
                    'DELIVERY SCAMS',
                    'MONEY & TRUST',
                    'DIGITAL CONFIDENCE',
                  ][index],
                ),
                const SizedBox(height: 7),
                Text(
                  guideTitles[index],
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '2 min read',
                  style: TextStyle(color: context.subtle, fontSize: 10),
                ),
              ],
            ),
          ),
          Icon(CupertinoIcons.arrow_up_right, size: 15, color: context.subtle),
        ],
      ),
    ),
  );
}

class PatternLibraryPage extends StatefulWidget {
  const PatternLibraryPage({super.key});
  @override
  State<PatternLibraryPage> createState() => _PatternLibraryPageState();
}

class _PatternLibraryPageState extends State<PatternLibraryPage> {
  final search = TextEditingController();
  String category = 'All';
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pro = ProAccess.instance.plan != ProPlan.free;
    final available = pro ? scamPatterns : scamPatterns.take(4).toList();
    final categories = ['All', ...available.map((p) => p.category).toSet()];
    final items = available
        .where(
          (p) =>
              (category == 'All' || p.category == category) &&
              '${p.title} ${p.category} ${p.signs}'.toLowerCase().contains(
                search.text.toLowerCase(),
              ),
        )
        .toList();
    return PageFrame(
      title: 'Scam patterns',
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(CupertinoIcons.search),
            hintText: 'Search patterns',
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: category == c,
                      onSelected: (_) => setState(() => category = c),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 15),
        ...items.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Surface(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  p.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(p.category),
                trailing: IconButton(
                  icon: Icon(
                    AppScope.of(context).bookmarkedPatterns.contains(p.title)
                        ? CupertinoIcons.bookmark_fill
                        : CupertinoIcons.bookmark,
                  ),
                  onPressed: () =>
                      AppScope.of(context).togglePatternBookmark(p.title),
                ),
                children: [
                  ListTile(
                    title: const Text('Example'),
                    subtitle: Text(p.example),
                  ),
                  ListTile(
                    title: const Text('Warning signs'),
                    subtitle: Text(p.signs),
                  ),
                  ListTile(
                    title: const Text('What to do'),
                    subtitle: Text(p.explanation),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!pro) ...[
          const SizedBox(height: 10),
          ActionButton(
            'Unlock complete library',
            onTap: () => openPage(context, const SubscriptionPage()),
          ),
        ],
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No patterns match this search.'),
          ),
      ],
    );
  }
}

class CustomRulesPage extends StatefulWidget {
  const CustomRulesPage({super.key});
  @override
  State<CustomRulesPage> createState() => _CustomRulesPageState();
}

class _CustomRulesPageState extends State<CustomRulesPage> {
  final phrase = TextEditingController();
  final explanation = TextEditingController();
  FindingSeverity severity = FindingSeverity.medium;
  String? error;
  @override
  void initState() {
    super.initState();
    CustomRuleBook.instance.load();
  }

  @override
  void dispose() {
    phrase.dispose();
    explanation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ProAccess.instance.allows(FeatureAccess.customRules)) {
      return PageFrame(
        title: 'Custom rules',
        children: [
          const SizedBox(height: 24),
          caption(
            context,
            'Create local phrase rules to highlight wording that is personally relevant to you.',
          ),
          const SizedBox(height: 18),
          ActionButton(
            'Unlock custom rules',
            onTap: () => openPage(context, const SubscriptionPage()),
          ),
        ],
      );
    }
    return ListenableBuilder(
      listenable: CustomRuleBook.instance,
      builder: (context, _) => PageFrame(
        title: 'Custom rules',
        children: [
          const SizedBox(height: 10),
          caption(
            context,
            'Rules stay on this device and match phrases in text or links. A match adds a finding to the scan report; it does not check a live threat feed.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phrase,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Phrase to flag',
              hintText: 'Example: gift card payment',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: explanation,
            maxLength: 240,
            decoration: const InputDecoration(
              labelText: 'Why should Aegis flag it?',
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<FindingSeverity>(
            initialValue: severity,
            decoration: const InputDecoration(labelText: 'Severity'),
            items: FindingSeverity.values
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item.name.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => severity = value);
            },
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: const TextStyle(color: rust)),
            ),
          const SizedBox(height: 12),
          ActionButton(
            'Add local rule',
            onTap: () async {
              final added = await CustomRuleBook.instance.add(
                phrase.text,
                explanation.text,
                severity,
              );
              if (!mounted) return;
              setState(() {
                error = added
                    ? null
                    : 'Enter a unique phrase with at least 3 characters.';
                if (added) {
                  phrase.clear();
                  explanation.clear();
                }
              });
            },
          ),
          const SizedBox(height: 24),
          eyebrow(
            context,
            'YOUR RULES (${CustomRuleBook.instance.rules.length})',
          ),
          if (CustomRuleBook.instance.rules.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: caption(
                context,
                'No custom rules yet. Add one above; matching is local and case-insensitive.',
              ),
            ),
          ...CustomRuleBook.instance.rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Surface(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule.phrase,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 5),
                          caption(
                            context,
                            '${rule.severity.name.toUpperCase()} • ${rule.explanation}',
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete rule',
                      icon: const Icon(CupertinoIcons.trash, color: rust),
                      onPressed: () => CustomRuleBook.instance.remove(rule.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LearnView extends StatelessWidget {
  const LearnView({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 26, 24, 125),
    children: [
      eyebrow(context, 'THE AEGIS FIELD GUIDE'),
      const SizedBox(height: 12),
      Text('A sharper\ninstinct.', style: headline(40)),
      const SizedBox(height: 13),
      caption(context, 'A little knowledge changes how you see things.'),
      const SizedBox(height: 27),
      GestureDetector(
        onTap: () => openPage(context, const QuizPage()),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: forest,
            borderRadius: BorderRadius.circular(27),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Pill(
                    'INTERACTIVE PRACTICE',
                    color: mint,
                    background: Color(0xFF345447),
                  ),
                  Spacer(),
                  Icon(CupertinoIcons.bolt, size: 22, color: mint),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Can you spot\nthe red flag?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  letterSpacing: -.8,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Three real-world situations. One sharper instinct.',
                style: TextStyle(color: Color(0xFFB6CABB), fontSize: 12),
              ),
              const SizedBox(height: 22),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Try the 60-second challenge',
                      style: TextStyle(
                        color: mint,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(CupertinoIcons.arrow_right, color: mint, size: 17),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 30),
      Surface(
        child: MenuRow(
          'Offline scam pattern library',
          icon: CupertinoIcons.book,
          subtitle: 'Browse warning signs and prevention steps.',
          onTap: () => openPage(context, const PatternLibraryPage()),
        ),
      ),
      const SizedBox(height: 12),
      Surface(
        child: MenuRow(
          'My security dashboard',
          icon: CupertinoIcons.chart_bar,
          subtitle: 'See your actual saved scan activity.',
          onTap: () => openPage(context, const SecurityDashboardPage()),
        ),
      ),
      const SizedBox(height: 30),
      Surface(
        child: MenuRow(
          'Custom detection rules',
          icon: CupertinoIcons.slider_horizontal_3,
          subtitle: ProAccess.instance.allows(FeatureAccess.customRules)
              ? 'Add phrases that matter to you.'
              : 'A Pro tool for your own phrase matches.',
          onTap: () => ProAccess.instance.allows(FeatureAccess.customRules)
              ? openPage(context, const CustomRulesPage())
              : openPage(context, const SubscriptionPage()),
        ),
      ),
      const SizedBox(height: 12),
      section(context, 'Good to know'),
      const SizedBox(height: 15),
      ...List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GuideCard(i),
        ),
      ),
      const SizedBox(height: 20),
      Surface(
        color: context.soft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            eyebrow(context, 'REMEMBER THIS'),
            const SizedBox(height: 12),
            const Text(
              'If it makes you rush,\ngive yourself a pause.',
              style: TextStyle(fontSize: 24, letterSpacing: -.6, height: 1.2),
            ),
            const SizedBox(height: 12),
            caption(context, 'Educational examples, not a live threat feed.'),
          ],
        ),
      ),
    ],
  );
}

class GuidePage extends StatelessWidget {
  final int index;
  const GuidePage(this.index, {super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'The field guide',
    children: [
      const SizedBox(height: 22),
      eyebrow(context, 'A SHARPER INSTINCT / 2 MIN READ'),
      const SizedBox(height: 22),
      Text(guideTitles[index], style: headline(36)),
      const SizedBox(height: 28),
      ...guideBodies[index]
          .split('\n\n')
          .map(
            (part) => Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Text(
                part,
                style: TextStyle(
                  color: context.subtle,
                  fontSize: 16,
                  height: 1.8,
                ),
              ),
            ),
          ),
      const SizedBox(height: 15),
      ActionButton(
        'Already shared something?',
        secondary: true,
        onTap: () => openPage(context, const RecoveryPage()),
      ),
    ],
  );
}
