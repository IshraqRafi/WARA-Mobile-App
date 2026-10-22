import 'package:flutter/material.dart';
import 'motion.dart';

/// Column of keyed items that animates list diffs: items that appear after
/// the first build slide and grow in; items that disappear fade and
/// collapse where they were. [skipExit] ids leave at once (e.g. a swiped
/// Dismissible, which must not stay in the tree). Reduce-motion: no motion.
class DiffList<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) idOf;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final bool Function(String id)? skipExit;

  const DiffList({super.key, required this.items, required this.idOf, required this.itemBuilder, this.skipExit});

  @override
  State<DiffList<T>> createState() => _DiffListState<T>();
}

class _Entry<T> {
  final T item;
  final bool fresh;
  bool leaving;
  _Entry(this.item, {this.fresh = false, this.leaving = false});
}

class _DiffListState<T> extends State<DiffList<T>> {
  late List<_Entry<T>> _entries = [for (final i in widget.items) _Entry(i)];

  @override
  void didUpdateWidget(DiffList<T> old) {
    super.didUpdateWidget(old);
    final ids = {for (final i in widget.items) widget.idOf(i)};
    final known = {for (final e in _entries) widget.idOf(e.item)};
    final next = <_Entry<T>>[];
    for (final i in widget.items) {
      final id = widget.idOf(i);
      final prev = _entries.where((e) => widget.idOf(e.item) == id && !e.leaving).firstOrNull;
      next.add(_Entry(i, fresh: prev?.fresh ?? !known.contains(id)));
    }
    // Re-insert leavers at their old position.
    for (var k = 0; k < _entries.length; k++) {
      final e = _entries[k];
      final id = widget.idOf(e.item);
      if (ids.contains(id)) continue;
      if (widget.skipExit?.call(id) ?? false) continue;
      next.insert(k.clamp(0, next.length), _Entry(e.item, leaving: true));
    }
    _entries = next;
  }

  @override
  Widget build(BuildContext context) {
    var index = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in _entries)
          KeyedSubtree(
            key: ValueKey('diff_${widget.idOf(e.item)}${e.leaving ? '_out' : ''}'),
            child: e.leaving
                ? _CollapseNow(
                    onEnd: () {
                      if (mounted) setState(() => _entries.remove(e));
                    },
                    child: IgnorePointer(child: widget.itemBuilder(context, e.item, -1)),
                  )
                : _SlideIn(play: e.fresh, child: widget.itemBuilder(context, e.item, index++)),
          ),
      ],
    );
  }
}

class _SlideIn extends StatefulWidget {
  final bool play;
  final Widget child;
  const _SlideIn({required this.play, required this.child});
  @override
  State<_SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<_SlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, value: widget.play ? 0 : 1);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.play && _c.value == 0) {
      _c.duration = Motion.of(context, Motion.medium);
      if (Motion.reduced(context)) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
        sizeFactor: _a,
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: _a,
          child: SlideTransition(position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(_a), child: widget.child),
        ),
      );
}

class _CollapseNow extends StatefulWidget {
  final VoidCallback onEnd;
  final Widget child;
  const _CollapseNow({required this.onEnd, required this.child});
  @override
  State<_CollapseNow> createState() => _CollapseNowState();
}

class _CollapseNowState extends State<_CollapseNow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, value: 1);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeInCubic);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _c.duration = Motion.of(context, Motion.medium);
    if (Motion.reduced(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onEnd());
    } else {
      _c.reverse().whenComplete(widget.onEnd);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
        sizeFactor: _a,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: _a, child: widget.child),
      );
}
