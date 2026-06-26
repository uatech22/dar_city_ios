/// One row in the live play-by-play feed (local / dummy until API is wired).
class LiveStatEvent {
  const LiveStatEvent({
    required this.stat,
    required this.jersey,
    required this.name,
    required this.period,
    required this.periodLabel,
    required this.clockLabel,
    this.count,
    this.isMiss = false,
  });

  final String stat;
  final int jersey;
  final String name;
  final int period;
  final String periodLabel;
  final String clockLabel;
  final int? count;
  final bool isMiss;

  bool get isExtraTime => period >= 5;
}

enum LiveStatKind {
  score2,
  score3,
  score1,
  defReb,
  offReb,
  turnover,
  steal,
  assist,
  block,
  foul,
  sub,
}
