import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/scanner.dart';
import 'services/pro_access.dart';
import 'models/audit_report.dart';

class AppState extends ChangeNotifier {
  bool ready = false, onboarded = false, dark = false, saveChecks = false;
  bool reminders = false, safetyTips = true;
  bool signedIn = false;
  String name = 'Your space';
  String? accountEmail;
  String accountProvider = 'Email';
  String? _accountPasswordHash;
  List<ScanResult> history = [];
  List<AuditReport> reports = [];
  List<Map<String, String>> contacts = [];
  Set<String> completedSteps = {};
  Set<String> bookmarkedPatterns = {};
  int quizBest = 0;
  SharedPreferences? _prefs;

  Future<void> load() async {
    try {
      final p = _prefs = await SharedPreferences.getInstance();
      onboarded = p.getBool('onboarded') ?? false;
      dark = p.getBool('dark') ?? false;
      saveChecks = p.getBool('remember') ?? false;
      reminders = p.getBool('reminders') ?? false;
      safetyTips = p.getBool('safetyTips') ?? true;
      name = p.getString('profileName') ?? 'Your space';
      accountEmail = p.getString('accountEmail');
      accountProvider = p.getString('accountProvider') ?? 'Email';
      _accountPasswordHash = p.getString('accountPasswordHash');
      signedIn = p.getBool('signedIn') == true && accountEmail != null;
      quizBest = p.getInt('quizBest') ?? 0;
      bookmarkedPatterns = (p.getStringList('bookmarkedPatterns') ?? [])
          .toSet();
      completedSteps = (p.getStringList('recoverySteps') ?? []).toSet();
      for (final item in p.getStringList('contacts') ?? <String>[]) {
        try {
          contacts.add(Map<String, String>.from(jsonDecode(item)));
        } catch (_) {
          /* Skip an invalid saved contact. */
        }
      }
      if (saveChecks) {
        for (final item in p.getStringList('reports') ?? <String>[]) {
          try {
            reports.add(AuditReport.decode(item));
          } catch (_) {
            /* Skip corrupt or incompatible reports. */
          }
        }
        for (final item in p.getStringList('history') ?? <String>[]) {
          try {
            final result = ScanResult.fromJson(jsonDecode(item));
            if (result.report == null ||
                !reports.any((report) => report.id == result.report!.id)) {
              history.add(result);
            }
          } catch (_) {
            /* Skip invalid entries. */
          }
        }
        history.insertAll(0, reports.map((report) => report.toLegacyResult()));
      }
    } catch (_) {
      /* The app remains usable without device persistence. */
    }
    ready = true;
    notifyListeners();
  }

  void completeOnboarding() {
    onboarded = true;
    _prefs?.setBool('onboarded', true);
    notifyListeners();
  }

  void setDark(bool value) {
    dark = value;
    _prefs?.setBool('dark', value);
    notifyListeners();
  }

  void setReminders(bool value) {
    reminders = value;
    _prefs?.setBool('reminders', value);
    notifyListeners();
  }

  void setSafetyTips(bool value) {
    safetyTips = value;
    _prefs?.setBool('safetyTips', value);
    notifyListeners();
  }

  void setName(String value) {
    name = value.trim().isEmpty ? 'Your space' : value.trim();
    _prefs?.setString('profileName', name);
    notifyListeners();
  }

  bool createAccount({
    required String accountName,
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    if (accountEmail != null && accountEmail != normalizedEmail) return false;
    name = accountName.trim();
    accountEmail = normalizedEmail;
    accountProvider = 'Email';
    _accountPasswordHash = sha256.convert(utf8.encode(password)).toString();
    signedIn = true;
    _prefs
      ?..setString('profileName', name)
      ..setString('accountEmail', accountEmail!)
      ..setString('accountProvider', accountProvider)
      ..setString('accountPasswordHash', _accountPasswordHash!)
      ..setBool('signedIn', true);
    notifyListeners();
    return true;
  }

  bool signIn(String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();
    final hash = sha256.convert(utf8.encode(password)).toString();
    if (accountEmail != normalizedEmail || _accountPasswordHash != hash) {
      return false;
    }
    signedIn = true;
    accountProvider = 'Email';
    _prefs?.setBool('signedIn', true);
    _prefs?.setString('accountProvider', accountProvider);
    notifyListeners();
    return true;
  }

  void signInWithGoogle({required String accountName, required String email}) {
    name = accountName.trim().isEmpty
        ? email.split('@').first
        : accountName.trim();
    accountEmail = email.trim().toLowerCase();
    accountProvider = 'Google';
    signedIn = true;
    _prefs
      ?..setString('profileName', name)
      ..setString('accountEmail', accountEmail!)
      ..setString('accountProvider', accountProvider)
      ..setBool('signedIn', true);
    notifyListeners();
  }

  void signOut() {
    signedIn = false;
    accountProvider = 'Email';
    _prefs?.setBool('signedIn', false);
    notifyListeners();
  }

  void setSaveChecks(bool value) {
    saveChecks = value;
    _prefs?.setBool('remember', value);
    if (value) {
      _persistHistory();
      _persistReports();
    } else {
      _prefs?.remove('history');
      _prefs?.remove('reports');
      history.clear();
      reports.clear();
    }
    notifyListeners();
  }

  void addCheck(ScanResult result) {
    history.insert(0, result);
    if (saveChecks) {
      _persistHistory();
    }
    notifyListeners();
  }

  void addReport(AuditReport report) {
    reports.removeWhere((item) => item.id == report.id);
    reports.insert(0, report);
    history.insert(0, report.toLegacyResult());
    if (saveChecks) {
      _persistHistory();
      _persistReports();
    }
    notifyListeners();
  }

  void clearHistory() {
    history.clear();
    reports.clear();
    _prefs?.remove('history');
    _prefs?.remove('reports');
    notifyListeners();
  }

  void removeReport(String id) {
    reports.removeWhere((item) => item.id == id);
    history.removeWhere((item) => item.report?.id == id);
    if (saveChecks) {
      _persistHistory();
      _persistReports();
    }
    notifyListeners();
  }

  void _persistHistory() => _prefs?.setStringList(
    'history',
    (ProAccess.instance.plan == ProPlan.ultra ? history : history.take(100))
        .map((r) => jsonEncode(r.toJson()))
        .toList(),
  );

  void _persistReports() => _prefs?.setStringList(
    'reports',
    (ProAccess.instance.plan == ProPlan.ultra ? reports : reports.take(100))
        .map((report) => report.encode())
        .toList(),
  );
  void addContact(String name, String detail) {
    contacts.add({'name': name.trim(), 'detail': detail.trim()});
    _saveContacts();
  }

  void removeContact(int i) {
    contacts.removeAt(i);
    _saveContacts();
  }

  void _saveContacts() {
    _prefs?.setStringList('contacts', contacts.map(jsonEncode).toList());
    notifyListeners();
  }

  void toggleStep(String id) {
    if (!completedSteps.add(id)) {
      completedSteps.remove(id);
    }
    _prefs?.setStringList('recoverySteps', completedSteps.toList());
    notifyListeners();
  }

  void saveQuiz(int score) {
    if (score > quizBest) {
      quizBest = score;
      _prefs?.setInt('quizBest', score);
      notifyListeners();
    }
  }

  void togglePatternBookmark(String title) {
    if (!bookmarkedPatterns.add(title)) bookmarkedPatterns.remove(title);
    _prefs?.setStringList('bookmarkedPatterns', bookmarkedPatterns.toList());
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
