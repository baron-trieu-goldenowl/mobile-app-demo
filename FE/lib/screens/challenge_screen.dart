import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../l10n/app_strings.dart';
import '../models/alarm.dart';
import '../models/mission.dart';
import '../theme/app_theme.dart';
import 'qr_scan_screen.dart';

/// Mission alarm: the user must complete a mission before the alarm can be
/// dismissed. Pops `true` when solved; closing returns to the ringing screen.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key, required this.alarm});

  final Alarm alarm;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late String _type = widget.alarm.challengeType;
  late String _difficulty = widget.alarm.challengeDifficulty;
  double _progress = 0;

  void _solved() {
    HapticFeedback.heavyImpact();
    Navigator.pop(context, true);
  }

  void _onProgress(double p) {
    if (mounted) setState(() => _progress = p.clamp(0, 1));
  }

  /// Used by the QR mission when the camera / code is unavailable.
  void _fallbackToMath() => setState(() {
    _type = 'math';
    _difficulty = 'hard';
    _progress = 0;
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final mission = Mission.of(_type);
    final key = ValueKey(_type);

    final Widget body = switch (_type) {
      'math' => _MathChallenge(
        key: key,
        difficulty: _difficulty,
        onSolved: _solved,
        onProgress: _onProgress,
      ),
      'memory' => _MemoryChallenge(
        key: key,
        difficulty: _difficulty,
        onSolved: _solved,
        onProgress: _onProgress,
      ),
      'typing' => _TypingChallenge(
        key: key,
        difficulty: _difficulty,
        onSolved: _solved,
        onProgress: _onProgress,
      ),
      'shake' => _ShakeChallenge(
        key: key,
        difficulty: _difficulty,
        onSolved: _solved,
        onProgress: _onProgress,
      ),
      'walk' => _WalkChallenge(
        key: key,
        difficulty: _difficulty,
        onSolved: _solved,
        onProgress: _onProgress,
      ),
      'puzzle' => _PuzzleChallenge(
        key: key,
        difficulty: _difficulty,
        onSolved: _solved,
      ),
      'qr' => _QrChallenge(
        key: key,
        expected: widget.alarm.qrCode,
        onSolved: _solved,
        onFallback: _fallbackToMath,
      ),
      _ => Center(
        child: FilledButton(onPressed: _solved, child: Text(s.dismiss)),
      ),
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D1A),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.night),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    Icon(mission.icon, color: mission.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.missionName(_type),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      widget.alarm.time,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    color: AppColors.accent,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

const _titleStyle = TextStyle(
  color: Colors.white,
  fontSize: 20,
  fontWeight: FontWeight.w600,
);
const _hintStyle = TextStyle(color: Colors.white60, fontSize: 15);

int _byDifficulty(String d, int easy, int medium, int hard) => d == 'hard'
    ? hard
    : d == 'medium'
    ? medium
    : easy;

// ---------------------------------------------------------------------------
// 1. Math
// ---------------------------------------------------------------------------
class _MathChallenge extends StatefulWidget {
  const _MathChallenge({
    super.key,
    required this.difficulty,
    required this.onSolved,
    required this.onProgress,
  });

  final String difficulty;
  final VoidCallback onSolved;
  final ValueChanged<double> onProgress;

  @override
  State<_MathChallenge> createState() => _MathChallengeState();
}

class _MathChallengeState extends State<_MathChallenge> {
  final _rng = Random();
  late String _expr;
  late int _answer;
  String _input = '';
  int _solved = 0;
  bool _wrong = false;

  int get _target => _byDifficulty(widget.difficulty, 3, 4, 5);

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    switch (widget.difficulty) {
      case 'easy':
        final a = _rng.nextInt(40) + 10, b = _rng.nextInt(40) + 10;
        _expr = '$a + $b';
        _answer = a + b;
      case 'medium':
        final a = _rng.nextInt(12) + 3,
            b = _rng.nextInt(9) + 3,
            c = _rng.nextInt(40) + 5;
        _expr = '$a × $b + $c';
        _answer = a * b + c;
      default:
        final a = _rng.nextInt(40) + 12,
            b = _rng.nextInt(8) + 3,
            c = _rng.nextInt(90) + 10;
        _expr = '$a × $b − $c';
        _answer = a * b - c;
    }
    _input = '';
  }

  void _key(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      _wrong = false;
      if (k == '⌫') {
        if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
      } else if (k == '−') {
        _input = _input.startsWith('-') ? _input.substring(1) : '-$_input';
      } else if (_input.length < 6) {
        _input += k;
      }
    });
  }

  void _submit() {
    if (int.tryParse(_input) == _answer) {
      _solved++;
      widget.onProgress(_solved / _target);
      if (_solved >= _target) {
        widget.onSolved();
        return;
      }
      setState(_next);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _wrong = true;
        _input = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),
          Text('${_solved + 1} / $_target', style: _hintStyle),
          const SizedBox(height: 12),
          FittedBox(
            child: Text(
              '$_expr = ?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _wrong ? AppColors.danger : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Text(
              _input.isEmpty ? (_wrong ? s.wrongTryAgain : ' ') : _input,
              style: TextStyle(
                color: _wrong && _input.isEmpty
                    ? AppColors.danger
                    : Colors.white,
                fontSize: _input.isEmpty ? 16 : 30,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          _Keypad(
            onKey: _key,
            onSubmit: _submit,
            allowNegative: widget.difficulty == 'hard',
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onKey,
    required this.onSubmit,
    this.allowNegative = false,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onSubmit;
  final bool allowNegative;

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      allowNegative ? '−' : '⌫',
      '0',
      '✓',
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.9,
      children: [
        for (final k in keys)
          Material(
            color: k == '✓'
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => k == '✓' ? onSubmit() : onKey(k),
              onLongPress: k == '−' ? () => onKey('⌫') : null,
              child: Center(
                child: k == '⌫'
                    ? const Icon(Icons.backspace_outlined, color: Colors.white)
                    : Text(
                        k,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Memory: tiles light up in sequence, repeat them in order.
// ---------------------------------------------------------------------------
class _MemoryChallenge extends StatefulWidget {
  const _MemoryChallenge({
    super.key,
    required this.difficulty,
    required this.onSolved,
    required this.onProgress,
  });

  final String difficulty;
  final VoidCallback onSolved;
  final ValueChanged<double> onProgress;

  @override
  State<_MemoryChallenge> createState() => _MemoryChallengeState();
}

class _MemoryChallengeState extends State<_MemoryChallenge> {
  final _rng = Random();
  List<int> _sequence = [];
  int _inputIndex = 0;
  int? _lit;
  int? _wrongTile;
  bool _showing = true;

  int get _length => _byDifficulty(widget.difficulty, 4, 6, 8);
  int get _grid => widget.difficulty == 'hard' ? 4 : 3;

  @override
  void initState() {
    super.initState();
    // _newRound reports progress to the parent (setState), which is not
    // allowed while this widget is being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_newRound());
    });
  }

  Future<void> _newRound() async {
    _sequence = List.generate(_length, (_) => _rng.nextInt(_grid * _grid));
    _inputIndex = 0;
    widget.onProgress(0);
    setState(() => _showing = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    for (final tile in _sequence) {
      if (!mounted) return;
      setState(() => _lit = tile);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() => _lit = null);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    if (mounted) setState(() => _showing = false);
  }

  Future<void> _tap(int tile) async {
    if (_showing) return;
    unawaited(HapticFeedback.selectionClick());
    if (tile != _sequence[_inputIndex]) {
      unawaited(HapticFeedback.heavyImpact());
      setState(() => _wrongTile = tile);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _wrongTile = null);
      await _newRound();
      return;
    }
    setState(() => _lit = tile);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted && _lit == tile) setState(() => _lit = null);
    });
    _inputIndex++;
    widget.onProgress(_inputIndex / _sequence.length);
    if (_inputIndex == _sequence.length) widget.onSolved();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_showing ? s.memorize : s.repeatSequence, style: _titleStyle),
          const SizedBox(height: 8),
          Text('$_inputIndex / ${_sequence.length}', style: _hintStyle),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: GridView.count(
              crossAxisCount: _grid,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                for (var i = 0; i < _grid * _grid; i++)
                  GestureDetector(
                    onTap: () => _tap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        gradient: _lit == i ? AppColors.sunrise : null,
                        color: _wrongTile == i
                            ? AppColors.danger
                            : _lit == i
                            ? null
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Typing: type the motivational phrase exactly.
// ---------------------------------------------------------------------------
class _TypingChallenge extends StatefulWidget {
  const _TypingChallenge({
    super.key,
    required this.difficulty,
    required this.onSolved,
    required this.onProgress,
  });

  final String difficulty;
  final VoidCallback onSolved;
  final ValueChanged<double> onProgress;

  @override
  State<_TypingChallenge> createState() => _TypingChallengeState();
}

class _TypingChallengeState extends State<_TypingChallenge> {
  final _ctrl = TextEditingController();
  String? _phrase;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final phrases = AppStrings.of(context).typingPhrases(widget.difficulty);
    _phrase ??= phrases[Random().nextInt(phrases.length)];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static String _normalize(String v) =>
      v.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  void _changed(String value) {
    final target = _normalize(_phrase!);
    final typed = _normalize(value);
    var match = 0;
    while (match < typed.length &&
        match < target.length &&
        typed[match] == target[match]) {
      match++;
    }
    widget.onProgress(match / target.length);
    if (typed == target) widget.onSolved();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final typed = _normalize(_ctrl.text);
    final target = _phrase!;
    final correctPrefix = _normalize(target).startsWith(typed);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(s.typePhrase, style: _hintStyle, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '“$target”',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            maxLines: null,
            onChanged: _changed,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              fillColor: Colors.white.withValues(alpha: 0.08),
              hintText: s.typeHere,
              hintStyle: const TextStyle(color: Colors.white38),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: correctPrefix ? Colors.white24 : AppColors.danger,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: correctPrefix ? AppColors.accent : AppColors.danger,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Shake
// ---------------------------------------------------------------------------
class _ShakeChallenge extends StatefulWidget {
  const _ShakeChallenge({
    super.key,
    required this.difficulty,
    required this.onSolved,
    required this.onProgress,
  });

  final String difficulty;
  final VoidCallback onSolved;
  final ValueChanged<double> onProgress;

  @override
  State<_ShakeChallenge> createState() => _ShakeChallengeState();
}

class _ShakeChallengeState extends State<_ShakeChallenge> {
  StreamSubscription<AccelerometerEvent>? _sub;
  int _count = 0;
  DateTime _lastShake = DateTime.now();

  int get _target => _byDifficulty(widget.difficulty, 20, 35, 50);

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream().listen((e) {
      final magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      // ~9.8 at rest; a shake exceeds ~18
      if (magnitude > 18 &&
          DateTime.now().difference(_lastShake) >
              const Duration(milliseconds: 250)) {
        _lastShake = DateTime.now();
        if (!mounted || _count >= _target) return;
        setState(() => _count++);
        HapticFeedback.lightImpact();
        widget.onProgress(_count / _target);
        if (_count >= _target) widget.onSolved();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return _CounterBody(
      icon: Icons.vibration_rounded,
      title: s.shakeToDismiss,
      value: '${_target - _count}',
      caption: s.shakesLeft,
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Walk (accelerometer-based step counter)
// ---------------------------------------------------------------------------
class _WalkChallenge extends StatefulWidget {
  const _WalkChallenge({
    super.key,
    required this.difficulty,
    required this.onSolved,
    required this.onProgress,
  });

  final String difficulty;
  final VoidCallback onSolved;
  final ValueChanged<double> onProgress;

  @override
  State<_WalkChallenge> createState() => _WalkChallengeState();
}

class _WalkChallengeState extends State<_WalkChallenge> {
  StreamSubscription<AccelerometerEvent>? _sub;
  int _steps = 0;
  bool _above = false;

  int get _target => _byDifficulty(widget.difficulty, 20, 40, 70);

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream().listen((e) {
      final magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      // Simple peak detection around ~9.8 rest magnitude
      if (magnitude > 12 && !_above) {
        _above = true;
        if (!mounted || _steps >= _target) return;
        setState(() => _steps++);
        widget.onProgress(_steps / _target);
        if (_steps >= _target) widget.onSolved();
      } else if (magnitude < 9) {
        _above = false;
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return _CounterBody(
      icon: Icons.directions_walk_rounded,
      title: s.walkToDismiss,
      value: '${_target - _steps}',
      caption: s.stepsLeft,
    );
  }
}

class _CounterBody extends StatelessWidget {
  const _CounterBody({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String title;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 80),
          const SizedBox(height: 20),
          Text(title, style: _titleStyle, textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 96,
              fontWeight: FontWeight.w200,
            ),
          ),
          Text(caption, style: _hintStyle),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Sliding puzzle (3x3)
// ---------------------------------------------------------------------------
class _PuzzleChallenge extends StatefulWidget {
  const _PuzzleChallenge({
    super.key,
    required this.difficulty,
    required this.onSolved,
  });

  final String difficulty;
  final VoidCallback onSolved;

  @override
  State<_PuzzleChallenge> createState() => _PuzzleChallengeState();
}

class _PuzzleChallengeState extends State<_PuzzleChallenge> {
  // Solved layout: 1..8 then the blank (0) in the last cell.
  static const _solvedTiles = [1, 2, 3, 4, 5, 6, 7, 8, 0];
  late List<int> _tiles;
  final _rng = Random();
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  /// Shuffle by making random legal moves from the solved state, so the
  /// puzzle is always solvable (a random permutation is not, half the time).
  void _shuffle() {
    _tiles = List.of(_solvedTiles);
    final count = _byDifficulty(widget.difficulty, 20, 40, 80);
    var previous = -1;
    for (var i = 0; i < count || _isSolved(); i++) {
      final blank = _tiles.indexOf(0);
      final options = _neighbors(blank).where((n) => n != previous).toList();
      final pick = options[_rng.nextInt(options.length)];
      _tiles[blank] = _tiles[pick];
      _tiles[pick] = 0;
      previous = blank;
    }
  }

  static List<int> _neighbors(int index) {
    final row = index ~/ 3, col = index % 3;
    return [
      if (row > 0) index - 3,
      if (row < 2) index + 3,
      if (col > 0) index - 1,
      if (col < 2) index + 1,
    ];
  }

  bool _isSolved() {
    for (var i = 0; i < 9; i++) {
      if (_tiles[i] != _solvedTiles[i]) return false;
    }
    return true;
  }

  void _tap(int index) {
    final blank = _tiles.indexOf(0);
    if (!_neighbors(blank).contains(index)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _tiles[blank] = _tiles[index];
      _tiles[index] = 0;
      _moves++;
    });
    if (_isSolved()) widget.onSolved();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.arrangeNumbers, style: _titleStyle),
          const SizedBox(height: 6),
          Text(s.movesCount(_moves), style: _hintStyle),
          const SizedBox(height: 24),
          SizedBox(
            width: 300,
            height: 300,
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < 9; i++)
                  GestureDetector(
                    onTap: () => _tap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        gradient: _tiles[i] == 0 ? null : AppColors.sunrise,
                        color: _tiles[i] == 0
                            ? Colors.white.withValues(alpha: 0.04)
                            : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: _tiles[i] == 0
                            ? null
                            : Text(
                                '${_tiles[i]}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7. QR / barcode: scan the code registered when the alarm was set up.
// ---------------------------------------------------------------------------
class _QrChallenge extends StatefulWidget {
  const _QrChallenge({
    super.key,
    required this.expected,
    required this.onSolved,
    required this.onFallback,
  });

  /// Registered code; null in previews, where any code is accepted.
  final String? expected;
  final VoidCallback onSolved;
  final VoidCallback onFallback;

  @override
  State<_QrChallenge> createState() => _QrChallengeState();
}

class _QrChallengeState extends State<_QrChallenge> {
  bool _done = false;
  bool _wrong = false;
  bool _showFallback = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    // Escape hatch if the code is lost or the camera does not work.
    _fallbackTimer = Timer(const Duration(seconds: 45), () {
      if (mounted) setState(() => _showFallback = true);
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final value = b.rawValue;
      if (value == null || value.isEmpty) continue;
      if (widget.expected == null ||
          widget.expected!.isEmpty ||
          value == widget.expected) {
        _done = true;
        widget.onSolved();
        return;
      }
      if (!_wrong) {
        HapticFeedback.heavyImpact();
        setState(() => _wrong = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _wrong = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            s.scanRegisteredCode,
            style: _titleStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    onDetect: _onDetect,
                    errorBuilder: (context, error) => Center(
                      child: Text(
                        s.cameraUnavailable,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const Center(child: ScanFrame(size: 220)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            opacity: _wrong ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              s.wrongCode,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
          if (_showFallback)
            TextButton(onPressed: widget.onFallback, child: Text(s.qrFallback)),
        ],
      ),
    );
  }
}
