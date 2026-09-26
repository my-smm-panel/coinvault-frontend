import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../services/app_repository.dart';

/// Daily Quiz. Answer correctness and any reward policy remain server-owned.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int? _selected;
  bool _answered = false;
  int? _earned;
  int? _correctCount;
  List<Map<String, dynamic>>? _questions;
  bool _loading = true;
  bool _submitting = false;
  bool _done = false;
  bool _alreadyPlayed = false;
  bool _submissionFailed = false;
  List<int?> _answers = [];

  void _pick(int i) {
    if (_answered || _done || _submitting) return;
    setState(() {
      _selected = i;
      _answered = true;
      if (_index < _answers.length) _answers[_index] = i;
    });
  }

  void _next() {
    if (_done || !_answered) return;
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
      final raw = data['questions'] as List;
      setState(() {
        _questions = raw.whereType<Map>().map((q) => Map<String, dynamic>.from(q)).toList();
        _alreadyPlayed = data['alreadyPlayed'] == true;
        _loading = false;
        _answers = List<int?>.filled(_questions!.length, null);
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitQuiz() async {
    if (_submitting || _questions == null) return;
    if (_questions!.length != 5 ||
        _answers.length != _questions!.length ||
        _answers.any((answer) => answer == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer every question before submitting.')),
      );
      return;
    }
    setState(() {
      _submitting = true;
      _submissionFailed = false;
    });
    try {
      final answers = _answers.cast<int>().toList();
      final res = await AppRepository.instance.submitQuiz(answers);
      if (!mounted) return;
      if (res != null) {
        final earned = res['coinsEarned'];
        final correct = res['correctCount'];
        setState(() {
          _correctCount = correct is num ? correct.toInt() : null;
          _earned = earned is num ? earned.toInt() : null;
          _done = true;
        });
      } else {
        setState(() => _submissionFailed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit the quiz. Check your connection and retry.')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submissionFailed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit the quiz. Check your connection and retry.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showResult() {
    final hasResult = _correctCount != null || _earned != null;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(hasResult ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 64, color: hasResult ? AppColors.success : AppColors.primary),
              const SizedBox(height: 12),
              if (_correctCount != null)
                Text('$_correctCount / ${_questions?.length ?? 0} answered correctly',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
              if (_earned != null) ...[
                const SizedBox(height: 6),
                Text('Coins earned: $_earned',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
              if (!hasResult)
                const Text('The server did not return quiz results.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24))),
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_alreadyPlayed && !_done) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 64),
                const SizedBox(height: 14),
                const Text('You already played today',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Come back when the server makes another quiz available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Done')),
              ]),
            ),
          ),
        ),
      );
    }
    if (_done) {
      _showResult();
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: Text('Submitting results…')),
      );
    }
    final q = _questions == null || _questions!.isEmpty ? null : _questions![_index];
    if (q == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: Text('No quiz is available right now.', style: TextStyle(color: AppColors.textSecondary))),
      );
    }
    final options = (q['options'] is List) ? List<String>.from(q['options'] as List) : <String>[];
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 16, 0),
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                    onPressed: () => Navigator.of(context).maybePop()),
                const Text('Daily Quiz', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${_index + 1}/${_questions!.length}', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: List.generate(_questions!.length, (i) => Expanded(child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: i <= _index ? AppColors.primary : AppColors.border, borderRadius: BorderRadius.circular(3)),
              )))),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Q${_index + 1}', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text((q['q'] ?? q['question'] ?? '').toString(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  ...List.generate(options.length, (i) {
                    final selected = _selected == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _pick(i),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary.withOpacity(0.12) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
                          ),
                          child: Row(children: [
                            Text('${i + 1}', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(options[i], style: const TextStyle(color: AppColors.textPrimary, fontSize: 15))),
                            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                          ]),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting || !_answered ? null : _next,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: Text(
                        _index < _questions!.length - 1
                            ? 'Next'
                            : (_submissionFailed ? 'Retry' : 'Submit'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
