import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../projects/domain/project_provider.dart';
import '../../auth/domain/auth_provider.dart';

/// Simulated payout receipt at agencies/{agencyId}/payouts/{projectId}.
/// Test mode only: no money moves.
class PayoutRecord {
  final String projectId;
  final String projectTitle;
  final String method;
  final String mode;
  final String trxId;
  final double amount;
  final String editorId;
  final String wallet; // masked
  final DateTime? paidAt;

  const PayoutRecord({
    required this.projectId,
    required this.trxId,
    required this.amount,
    required this.editorId,
    required this.wallet,
    this.projectTitle = '',
    this.method = 'bkash',
    this.mode = 'test',
    this.paidAt,
  });

  bool get isTest => mode == 'test';
  String get methodLabel => method == 'bkash' ? 'bKash' : method;

  factory PayoutRecord.fromMap(String id, Map<String, dynamic> m) => PayoutRecord(
        projectId: id,
        projectTitle: m['projectTitle'] as String? ?? '',
        method: m['method'] as String? ?? 'bkash',
        mode: m['mode'] as String? ?? 'test',
        trxId: m['trxId'] as String? ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        editorId: m['editorId'] as String? ?? '',
        wallet: m['wallet'] as String? ?? '',
        paidAt: switch (m['paidAt']) { final Timestamp t => t.toDate(), _ => null },
      );

  /// Fields for a new doc; paidAt is the server time (required by rules).
  Map<String, dynamic> draft(String paidBy) => {
        'projectTitle': projectTitle.length > 200 ? projectTitle.substring(0, 200) : projectTitle,
        'method': method,
        'mode': mode,
        'trxId': trxId,
        'amount': amount,
        'editorId': editorId,
        'wallet': wallet,
        'paidAt': FieldValue.serverTimestamp(),
        'paidBy': paidBy,
      };
}

/// Bangladeshi mobile wallet: 01 + operator 3-9 + 8 digits.
bool isValidWallet(String s) => RegExp(r'^01[3-9]\d{8}$').hasMatch(s.trim());

/// '01712345678' -> '017*****678'.
String maskWallet(String s) {
  final w = s.trim();
  if (w.length < 7) return w;
  return '${w.substring(0, 3)}${'*' * (w.length - 6)}${w.substring(w.length - 3)}';
}

const _alnum = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789';

/// 'BK' + 10 uppercase alphanumerics.
String generateTrxId([Random? rng]) {
  final r = rng ?? Random.secure();
  return 'BK${List.generate(10, (_) => _alnum[r.nextInt(_alnum.length)]).join()}';
}

/// Payout receipts by project id: the whole agency for a manager, own for
/// an editor (the rules only allow those reads).
final payoutsProvider = StreamProvider.autoDispose<Map<String, PayoutRecord>>((ref) {
  final user = ref.watch(authProvider.select((s) => s.user));
  final agencyId = user?.agencyId;
  if (user == null || agencyId == null || agencyId.isEmpty) return Stream.value(const {});
  final svc = ref.watch(firestoreServiceProvider);
  return svc
      .streamPayouts(agencyId, editorId: user.role == UserRole.manager ? null : user.id)
      .map((l) => {for (final p in l) p.projectId: p});
});
