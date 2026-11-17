class ScamPattern {
  final String title, category, example, signs, explanation;
  const ScamPattern(
    this.title,
    this.category,
    this.example,
    this.signs,
    this.explanation,
  );
}

const scamPatterns = <ScamPattern>[
  ScamPattern(
    'Bank account suspension',
    'Banking',
    'Your account will be blocked today. Verify through this link.',
    'Urgency, threat, unexpected link',
    'Open the official banking app or call the number on your card.',
  ),
  ScamPattern(
    'OTP theft',
    'OTP',
    'Tell me the code you just received so I can reverse the transfer.',
    'Requests a one-time code or PIN',
    'Never share OTPs, PINs, or recovery codes, even with someone claiming to be staff.',
  ),
  ScamPattern(
    'Fake wallet support',
    'Payment',
    'JazzCash/Easypaisa support needs your PIN to unlock your wallet.',
    'PIN request, support impersonation',
    'Support should not need your secret PIN. Contact the provider through its official app.',
  ),
  ScamPattern(
    'WhatsApp new number',
    'WhatsApp impersonation',
    'Hi, I changed my number. Please transfer money urgently.',
    'New number, secrecy, urgency',
    'Call the old known number or another trusted contact before sending money.',
  ),
  ScamPattern(
    'Upfront job fee',
    'Job',
    'Pay a registration fee to guarantee this remote job.',
    'Payment before hiring, guaranteed job',
    'Verify the company independently and do not pay to secure an unverified role.',
  ),
  ScamPattern(
    'Guaranteed investment',
    'Investment',
    'Double your money this week with guaranteed returns.',
    'Guaranteed profit, short deadline',
    'Check licensing and independent sources; never invest under pressure.',
  ),
  ScamPattern(
    'Prize processing fee',
    'Prize and lottery',
    'You won. Pay a small fee to release your prize.',
    'Unexpected win, fee to claim',
    'Verify the promotion through the official organizer; do not pay to receive an unknown prize.',
  ),
  ScamPattern(
    'Lookalike login page',
    'Phishing',
    'A message links to a domain that resembles a bank or service.',
    'Misspelled domain, login request',
    'Navigate to the service yourself and do not enter credentials via message links.',
  ),
  ScamPattern(
    'Social pressure',
    'Social engineering',
    'Keep this secret and act before the offer expires.',
    'Secrecy, pressure, emotional manipulation',
    'Pause and discuss the request with someone you trust.',
  ),
  ScamPattern(
    'Fake customer support',
    'Customer support',
    'Call this number to fix a problem you did not report.',
    'Unsolicited contact, remote access request',
    'Find the support contact on the organization’s official website or app.',
  ),
];

class QuizItem {
  final String category, difficulty, prompt, explanation;
  final List<String> choices;
  final int answer;
  const QuizItem(
    this.category,
    this.difficulty,
    this.prompt,
    this.choices,
    this.answer,
    this.explanation,
  );
}

const quizLibrary = <QuizItem>[
  QuizItem(
    'OTP',
    'Easy',
    'A caller asks you to read a bank OTP to cancel a payment. What next?',
    [
      'Share it quickly',
      'End the call and contact the bank using its official number',
      'Send a screenshot',
    ],
    1,
    'An OTP authorizes an action. Never disclose it to a caller.',
  ),
  QuizItem(
    'Banking',
    'Easy',
    'A text threatens account closure and includes a login link.',
    [
      'Open your bank app directly',
      'Enter details to stop closure',
      'Reply with your PIN',
    ],
    0,
    'Use a trusted route to check account status.',
  ),
  QuizItem(
    'Job',
    'Medium',
    'A recruiter offers unusually high pay but requests a fee before interview.',
    [
      'Pay a refundable fee',
      'Verify the company and refuse upfront fees',
      'Share identity documents in chat',
    ],
    1,
    'Upfront payment and unrealistic guarantees are warning signs.',
  ),
  QuizItem(
    'Phishing',
    'Medium',
    'A delivery notice asks for a small redelivery payment on a lookalike domain.',
    [
      'Use the link',
      'Check tracking in the official carrier app',
      'Reuse your bank password',
    ],
    1,
    'Visit the carrier independently instead of using unsolicited links.',
  ),
  QuizItem(
    'Payment',
    'Hard',
    'A friend messages from a new number asking for emergency money and secrecy.',
    [
      'Call their saved number',
      'Send a small amount first',
      'Ask for their ID photo',
    ],
    0,
    'Verify identity through a known channel; urgency can be staged.',
  ),
  QuizItem(
    'Investment',
    'Hard',
    'A group promises guaranteed returns if you transfer crypto today.',
    [
      'Research and verify independently; avoid pressure',
      'Transfer a test amount',
      'Share wallet recovery phrase',
    ],
    0,
    'Guaranteed returns and urgency are strong risk signals. Never share recovery phrases.',
  ),
];
