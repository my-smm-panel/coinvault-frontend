import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../services/auth_service.dart';

/// Daily Quiz — backend-fetched questions (GET /api/quiz) + submit (POST /api/quiz/submit).
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  int _earned = 0;
  int _correctCount = 0;

  // Backend-fetched state
  List<Map<String, dynamic>>? _questions;
  bool _loading = true;
  bool _submitting = false;
  bool _done = false;
  int _coinsPerCorrect = 2;
  int _passThreshold = 3;
  final List<int?> _answers = List.filled(5, null);

  void _pick(int i) {
    if (_answered || _done || _submitting) return;
    setState(() {
      _selected = i;
      _answered = true;
      _answers[_index] = i;
      if (i == (_questions?[_index]['answer'] as int? ?? -1)) {
        _score++;
      }
    });
  }

  void _next() {
    if (_done) return;
    if (_index < (_questions?.length ?? 0) - 1) {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
    } else {
      _submitQuiz();
    }
  }

  Future<void> _loadQuiz() async {
    final data = await AppRepository.instance.fetchQuiz();
    if (!mounted) return;
    if (data != null && data['questions'] is List) {
      setState(() {
        _questions = List<Map<String, dynamic>>.from(data['questions'] as List);
        _coinsPerCorrect = data['coinsPerCorrect'] as int? ?? 2;
        _passThreshold = data['passThreshold'] as int? ?? 3;
        _loading = false;
        _answers.fillRange(0, _questions!.length, null);
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitQuiz() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      // Build compact answers list (only answered indices)
      final List<int> compact = <int>[];
      for (var i = 0; i < _answers.length; i++) {
        if (_answers[i] != null) compact.add(_answers[i]!);
      }
      if (compact.length < (_questions?.length ?? 0)) {
        // Fill unanswered with first option to avoid backend 400
        for (var i = 0; i < _answers.length; i++) {
          if (_answers[i] == null) compact.add(0);
          else compact.add(_answers[i]!);
        }
      }
      final res = await AppRepository.instance.submitQuiz(compact);
      if (!mounted) return;
      if (res != null) {
        setState(() {
          _correctCount = res['correctCount'] as int? ?? 0;
          _earned = res['coinsEarned'] as int? ?? 0;
          _done = true;
          // Optimistic local coin update if auth available
          try {
            AuthService().addCoins(_earned);
          } catch (_) {}
        });
      } else {
        setState(() => _done = true);
      }
    } catch (_) {
      if (mounted) setState(() => _done = true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showResult() {
    final passed = _earned > 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.surface, AppColors.spinCard],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (passed ? AppColors.gold : AppColors.primary).withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                passed ? Icons.emoji_events_rounded : Icons.replay_rounded,
                size: 64,
                color: passed ? AppColors.gold : AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                '$_score / ${_questions?.length ?? 0} correct',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                passed
                    ? 'You earned $_earned coins! 🪙'
                    : 'Need 3+ correct to earn. Try again tomorrow!',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Loading Quiz...',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_done) {
      _showResult();
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          child: Center(
            child: Text(
              'Submitting results...',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    final q = _questions?[_index];
    if (q == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          child: Center(
            child: Text(
              'No questions available',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    final options = List<String>.from(q['options'] ?? []);
    final correct = q['answer'] as int? ?? -1;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Text(
                    'Daily Quiz',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.gold.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded,
                            color: AppColors.gold, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$_earned',
                          style: GoogleFonts.inter(
                            color: AppColors.goldLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: List.generate(_questions!.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _index
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            // Question
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${_index + 1}',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      q['q'] as String,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Options
                    ...List.generate(options.length, (i) {
                      final isSelected = _selected == i;
                      final isCorrect = i == correct;
                      final showResult = _answered;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => _pick(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: showResult
                                  ? (isCorrect
                                      ? AppColors.gold.withOpacity(0.12)
                                      : isSelected && !isCorrect
                                          ? AppColors.primary.withOpacity(0.12)
                                          : const Color(0xFFFFFFFF))
                                  : const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: showResult
                                    ? (isCorrect
                                        ? AppColors.gold
                                        : isSelected && !isCorrect
                                            ? AppColors.primary
                                            : AppColors.border)
                                    : AppColors.border,
                                width: showResult ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '${i + 1}',
                                    style: GoogleFonts.inter(
                                      color: isCorrect
                                          ? AppColors.gold
                                          : isSelected && !isCorrect
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    options[i],
                                    style: GoogleFonts.inter(
                                      color: showResult && isCorrect
                                          ? AppColors.gold
                                          : AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: isCorrect
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (showResult) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    isCorrect
                                        ? Icons.check_circle_rounded
                                        : isSelected && !isCorrect
                                            ? Icons.cancel_rounded
                                            : Icons.radio_button_unchecked_rounded,
                                    color: isCorrect
                                        ? AppColors.gold
                                        : isSelected && !isCorrect
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    // Next/Done button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _index < (_questions!.length - 1) ? 'Next' : 'Submit',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
