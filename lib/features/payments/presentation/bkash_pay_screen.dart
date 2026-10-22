import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/motion/motion.dart';
import '../domain/payout.dart';

/// bKash brand pink.
const bkashPink = Color(0xFFE2136E);

/// Result of a completed (simulated) bKash payment.
class BkashReceipt {
  final String trxId;
  final String wallet; // full number, masked before storing
  final DateTime paidAt;
  const BkashReceipt(this.trxId, this.wallet, this.paidAt);
}

/// How the manager settles: plain 'Mark paid' or the bKash test flow.
enum PayMethod { manual, bkash }

/// Asks how to pay; null when cancelled.
Future<PayMethod?> choosePayMethod(BuildContext context, {required String title, required String detail}) =>
    showDialog<PayMethod>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(detail),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(key: const ValueKey('confirm_paid'), onPressed: () => Navigator.pop(ctx, PayMethod.manual), child: const Text('Mark paid')),
          FilledButton(
            key: const ValueKey('confirm_bkash'),
            style: FilledButton.styleFrom(backgroundColor: bkashPink, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, PayMethod.bkash),
            child: const Text('Pay with bKash'),
          ),
        ],
      ),
    );

/// Full-screen simulated bKash Send Money. Resolves to a receipt on
/// success, null if closed early. Nothing real is charged.
Future<BkashReceipt?> showBkashPay(BuildContext context,
        {required String payee, required double amount, required String reference, String? wallet}) =>
    Navigator.of(context).push<BkashReceipt>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BkashPayScreen(payee: payee, amount: amount, reference: reference, wallet: wallet),
    ));

enum BkashStep { details, otp, pin, processing, success }

class BkashPayScreen extends StatefulWidget {
  final String payee;
  final double amount;
  final String reference;
  final String? wallet;
  /// Processing delay (shortened in tests).
  final Duration processing;
  const BkashPayScreen({
    super.key,
    required this.payee,
    required this.amount,
    required this.reference,
    this.wallet,
    this.processing = const Duration(milliseconds: 1500),
  });

  @override
  State<BkashPayScreen> createState() => _BkashPayScreenState();
}

class _BkashPayScreenState extends State<BkashPayScreen> {
  var _step = BkashStep.details;
  late final _wallet = TextEditingController(text: widget.wallet ?? '');
  late final _ref = TextEditingController(text: widget.reference);
  final _otp = TextEditingController();
  final _pin = TextEditingController();
  String? _error;
  BkashReceipt? _receipt;

  @override
  void dispose() {
    for (final c in [_wallet, _ref, _otp, _pin]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _amountLabel => '৳${widget.amount.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  void _next() {
    setState(() => _error = null);
    switch (_step) {
      case BkashStep.details:
        if (!isValidWallet(_wallet.text)) return setState(() => _error = 'Enter a valid bKash number (01XXXXXXXXX)');
        setState(() => _step = BkashStep.otp);
      case BkashStep.otp:
        if (!RegExp(r'^\d{6}$').hasMatch(_otp.text)) return setState(() => _error = 'Enter the 6-digit code');
        setState(() => _step = BkashStep.pin);
      case BkashStep.pin:
        if (!RegExp(r'^\d{5}$').hasMatch(_pin.text)) return setState(() => _error = 'Enter your 5-digit PIN');
        setState(() => _step = BkashStep.processing);
        Future.delayed(widget.processing, () {
          if (!mounted) return;
          Haptics.success();
          setState(() {
            _receipt = BkashReceipt(generateTrxId(), _wallet.text.trim(), DateTime.now());
            _step = BkashStep.success;
          });
        });
      case BkashStep.processing:
        break;
      case BkashStep.success:
        Navigator.of(context).pop(_receipt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final busy = _step == BkashStep.processing;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: bkashPink,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(children: [
            Text('bKash', style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
            const SizedBox(width: 10),
            Container(
              key: const ValueKey('bkash_test_badge'),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(border: Border.all(color: Colors.white70), borderRadius: BorderRadius.circular(4)),
              child: Text('TEST', style: t.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
            ),
          ]),
          actions: [
            if (_step != BkashStep.success)
              IconButton(
                key: const ValueKey('bkash_close'),
                tooltip: 'Cancel',
                icon: const Icon(Icons.close_rounded),
                onPressed: busy ? null : () => Navigator.of(context).pop(),
              ),
          ],
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: Motion.of(context, const Duration(milliseconds: 220)),
            child: KeyedSubtree(key: ValueKey(_step), child: _body(t)),
          ),
        ),
      ),
    );
  }

  Widget _summary(TextTheme t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bkashPink.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Send money to', style: t.labelMedium?.copyWith(color: Colors.black54)),
          const SizedBox(height: 2),
          Text(widget.payee, style: t.titleMedium?.copyWith(color: Colors.black87, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text('Amount', style: t.labelMedium?.copyWith(color: Colors.black54)),
          Text(_amountLabel,
              key: const ValueKey('bkash_amount'),
              style: t.headlineSmall?.copyWith(color: Colors.black87, fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
      );

  Widget _field(TextEditingController c, String key, String label,
          {int? max, bool obscure = false, bool digits = true, String? hint, bool autofocus = false}) =>
      TextField(
        key: ValueKey(key),
        controller: c,
        autofocus: autofocus,
        obscureText: obscure,
        keyboardType: digits ? TextInputType.number : TextInputType.text,
        inputFormatters: [if (digits) FilteringTextInputFormatter.digitsOnly, if (max != null) LengthLimitingTextInputFormatter(max)],
        style: const TextStyle(color: Colors.black87, letterSpacing: 1),
        cursorColor: bkashPink,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.black54),
          hintStyle: const TextStyle(color: Colors.black38),
          filled: true,
          fillColor: const Color(0xFFF6F6F6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: bkashPink)),
        ),
        onSubmitted: (_) => _next(),
      );

  Widget _button(String label) => SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          key: const ValueKey('bkash_next'),
          style: FilledButton.styleFrom(backgroundColor: bkashPink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: _next,
          child: Text(label),
        ),
      );

  Widget _page(List<Widget> children, String action) => ListView(padding: const EdgeInsets.all(20), children: [
        ...children,
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, key: const ValueKey('bkash_error'), style: const TextStyle(color: Color(0xFFC62828), fontSize: 13)),
        ],
        const SizedBox(height: 20),
        _button(action),
      ]);

  Widget _body(TextTheme t) {
    switch (_step) {
      case BkashStep.details:
        return _page([
          _summary(t),
          const SizedBox(height: 16),
          _field(_wallet, 'bkash_wallet', 'Receiver bKash number', max: 11, hint: '01XXXXXXXXX', autofocus: _wallet.text.isEmpty),
          const SizedBox(height: 12),
          _field(_ref, 'bkash_ref', 'Reference', digits: false, max: 50),
        ], 'Next');
      case BkashStep.otp:
        return _page([
          _summary(t),
          const SizedBox(height: 16),
          Text('Verification code sent to ${maskWallet(_wallet.text)}', style: t.bodyMedium?.copyWith(color: Colors.black87)),
          const SizedBox(height: 12),
          _field(_otp, 'bkash_otp', '6-digit code', max: 6, autofocus: true),
          const SizedBox(height: 6),
          Text('Test mode · any 6 digits', key: const ValueKey('bkash_test_hint'), style: t.labelSmall?.copyWith(color: Colors.black45)),
        ], 'Verify');
      case BkashStep.pin:
        return _page([
          _summary(t),
          const SizedBox(height: 16),
          _field(_pin, 'bkash_pin', 'bKash PIN', max: 5, obscure: true, autofocus: true),
          const SizedBox(height: 6),
          Text('Test mode · any 5 digits', style: t.labelSmall?.copyWith(color: Colors.black45)),
        ], 'Confirm');
      case BkashStep.processing:
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(color: bkashPink, strokeWidth: 3)),
            const SizedBox(height: 16),
            Text('Processing…', style: t.bodyMedium?.copyWith(color: Colors.black54)),
          ]),
        );
      case BkashStep.success:
        final r = _receipt!;
        final d = r.paidAt;
        final ts = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
            '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
        return ListView(padding: const EdgeInsets.all(20), children: [
          const SizedBox(height: 12),
          const Center(child: Icon(Icons.check_circle_rounded, color: bkashPink, size: 64)),
          const SizedBox(height: 12),
          Center(child: Text('Send money successful', style: t.titleMedium?.copyWith(color: Colors.black87, fontWeight: FontWeight.w600))),
          const SizedBox(height: 20),
          _summary(t),
          const SizedBox(height: 12),
          _kv(t, 'Receiver', maskWallet(r.wallet)),
          _kv(t, 'TrxID', r.trxId, key: 'bkash_trx'),
          _kv(t, 'Time', ts),
          if (_ref.text.trim().isNotEmpty) _kv(t, 'Reference', _ref.text.trim()),
          const SizedBox(height: 20),
          _button('Done'),
        ]);
    }
  }

  Widget _kv(TextTheme t, String k, String v, {String? key}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(k, style: t.bodyMedium?.copyWith(color: Colors.black54)),
          const Spacer(),
          SelectableText(v, key: key == null ? null : ValueKey(key), style: t.bodyMedium?.copyWith(color: Colors.black87, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
      );
}
