// Runs a load one at a time and skips repeats within a short cooldown.
class ThrottledLoader {
  ThrottledLoader(this._load, {this.cooldown = const Duration(seconds: 5)});

  final Future<void> Function() _load;
  final Duration cooldown;

  Future<void>? _inFlight;
  DateTime? _lastRun;

  // `force` ignores the cooldown, e.g. right after a new scan is saved.
  Future<void> call({bool force = false}) {
    final running = _inFlight;
    if (running != null) {
      return force ? running.whenComplete(() => call(force: true)) : running;
    }
    final last = _lastRun;
    if (!force && last != null && DateTime.now().difference(last) < cooldown) {
      return Future.value();
    }
    _lastRun = DateTime.now();
    return _inFlight = _load().whenComplete(() => _inFlight = null);
  }
}
