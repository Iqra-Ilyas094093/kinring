import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/group_event_model.dart';

/// Wraps a `Stream<List<GroupEventModel>>` factory (e.g.
/// `EventsViewModel.listenUpcomingEvents`) and periodically rebuilds it.
///
/// Why: [EventsViewModel.listenUpcomingEvents]/`listenGroupEvents` filter
/// with `where('timeUTC', isGreaterThanOrEqualTo: Timestamp.now())` —
/// but that `now()` is captured ONCE, when the stream is created, not
/// re-evaluated as wall-clock time passes. An event that was upcoming
/// when the screen opened stays matched by that same live listener even
/// after its `timeUTC` is now in the past, until something forces a
/// fresh subscription. This widget is that "something": every
/// [refreshInterval] it discards the old stream and calls
/// [streamBuilder] again, capturing a fresh `now()` — so a fired event
/// disappears from "Upcoming" within one interval, without needing the
/// user to navigate away and back.
class LiveEventsStreamBuilder extends StatefulWidget {
  const LiveEventsStreamBuilder({
    super.key,
    required this.streamBuilder,
    required this.builder,
    this.refreshInterval = const Duration(seconds: 20),
  });

  final Stream<List<GroupEventModel>> Function() streamBuilder;
  final Widget Function(BuildContext context, AsyncSnapshot<List<GroupEventModel>> snapshot) builder;
  final Duration refreshInterval;

  @override
  State<LiveEventsStreamBuilder> createState() => _LiveEventsStreamBuilderState();
}

class _LiveEventsStreamBuilderState extends State<LiveEventsStreamBuilder> {
  late Stream<List<GroupEventModel>> _stream = widget.streamBuilder();
  late final Timer _timer = Timer.periodic(widget.refreshInterval, (_) {
    if (mounted) setState(() => _stream = widget.streamBuilder());
  });

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GroupEventModel>>(stream: _stream, builder: widget.builder);
  }
}
