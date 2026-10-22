import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/motion/celebration.dart';
import '../../../core/constants/app_constants.dart';
import '../../projects/domain/project_provider.dart';
import 'bkash_pay_screen.dart';

/// Runs the bKash test flow for [projects] (one editor) and, on success,
/// approves them, stores the receipts and notifies the editor. True if paid.
Future<bool> payWithBkashFlow(BuildContext context, WidgetRef ref, List<ProjectItem> projects, {required String editorName}) async {
  if (projects.isEmpty) return false;
  final sum = projects.fold<double>(0, (a, p) => a + p.editorPayout);
  final reference = projects.length == 1 ? projects.first.title : '${projects.length} projects';
  final receipt = await showBkashPay(context, payee: editorName, amount: sum, reference: reference);
  if (receipt == null) return false;
  await ref.read(projectsProvider.notifier).payWithBkash(projects, trxId: receipt.trxId, wallet: receipt.wallet);
  if (context.mounted) Celebration.sparkle(context);
  return true;
}
