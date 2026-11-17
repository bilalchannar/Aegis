import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:scam_fraud/models/audit_report.dart';
import 'package:scam_fraud/services/scanner.dart';

class _Case {
  final String name;
  final String input;
  final bool suspicious;

  const _Case(this.name, this.input, this.suspicious);
}

void main() {
  test('balanced deterministic detection evaluation reports measured metrics', () {
    const cases = [
      _Case(
        'credential request',
        'Send your OTP to support immediately.',
        true,
      ),
      _Case(
        'account threat',
        'Your bank account will be blocked today. Verify now.',
        true,
      ),
      _Case(
        'refund fee',
        'Your refund is approved. Pay a processing fee to release it.',
        true,
      ),
      _Case(
        'unsafe APK',
        'Install this APK and disable your phone security.',
        true,
      ),
      _Case(
        'remote access',
        'Install AnyDesk and allow remote access to your computer.',
        true,
      ),
      _Case(
        'Roman Urdu lure',
        'Jaldi paise bhejo aur link kholo, inaam claim karo.',
        true,
      ),
      _Case(
        'OTP warning',
        'Never share your OTP with anyone, including support staff.',
        false,
      ),
      _Case(
        'security education',
        'This article explains how scammers steal passwords.',
        false,
      ),
      _Case(
        'payment receipt',
        'Your payment was received successfully. Thank you for your purchase.',
        false,
      ),
      _Case(
        'official app reminder',
        'Open your bank official application directly to review activity.',
        false,
      ),
      _Case(
        'ordinary password mention',
        'Our security team reminds everyone to protect their passwords.',
        false,
      ),
      _Case(
        'ordinary account request',
        'Please verify your account today.',
        false,
      ),
    ];

    var truePositive = 0;
    var falsePositive = 0;
    var falseNegative = 0;
    var trueNegative = 0;
    for (final item in cases) {
      final report = Scanner.analyzeMessage(item.input);
      final detected =
          report.findings.isNotEmpty &&
          report.riskLevel != RiskLevel.inconclusive;
      if (item.suspicious && detected) {
        truePositive++;
      } else if (item.suspicious) {
        falseNegative++;
      } else if (detected) {
        falsePositive++;
      } else {
        trueNegative++;
      }
      if (item.name == 'ordinary account request') expect(detected, isFalse);
    }

    final precision = truePositive / (truePositive + falsePositive);
    final recall = truePositive / (truePositive + falseNegative);
    final falsePositiveRate = falsePositive / (falsePositive + trueNegative);
    // These are measurements of this small fixture, not product accuracy claims.
    debugPrint(
      'Evaluation: n=${cases.length}, precision=${precision.toStringAsFixed(3)}, '
      'recall=${recall.toStringAsFixed(3)}, '
      'false-positive-rate=${falsePositiveRate.toStringAsFixed(3)}',
    );
    expect(cases.length, 12);
    expect(truePositive, greaterThan(0));
  });
}
