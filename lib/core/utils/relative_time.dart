/// Same relative-time format already used by the Notifications screen
/// ("2 min ago", "Yesterday", etc.) — pulled out here so Chat can share
/// it instead of growing its own copy.
String relativeTime(DateTime ts) {
  final diff = DateTime.now().difference(ts);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays == 1) return 'Yesterday';
  return '${diff.inDays} days ago';
}
