import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';

/// Daily Quiz — simple math/general quiz, coins on correct answers.
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

  static const _questions = [
    {
      'q': '100 coins equal how much money?',
      'options': ['₹1', '₹10', '₹100', '₹1000'],
      'answer': 1,
    },
    {
      'q': 'Which is India\'s UPI based fast payment?',
      'options': ['PayTM', 'UPI', 'Both are UPI apps', 'None'],
      'answer': 2,
    },
    {
      'q': 'How many free spins do you get daily?',
      'options': ['1', '2', '5', '10'],
      'answer': 1,
    },
    {
      'q': 'What is 25 + 75?',
      'options': ['90', '100', '110', '125'],
      'answer': 1,
    },
    {
      'q': 'Which app gives coins for tasks & spins?',
      'options': ['CoinVault', 'Others', 'No app', 'Cannot say'],
      'answer': 0,
    },
  ];

  void _pick(int i) {
    if (_answered) return;
    setState(() {
      _selected = i;
      _answered = true;
      if (i == _questions[_index]['answer'] as int) {
        _score++;
        _earned += 2;
      }
    });
  }

  void _next() {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    final passed = _score >= 3;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.surface, AppColors.spinCard]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color:
                    (passed ? AppColors.gold : AppColors.primary)
                        .withOpacity(0.5),
                width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                passed
                    ? Icons.emoji_events_rounded
                    : Icons.replay_rounded,
                size: 64,
                color: passed ? AppColors.gold : AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                '$_score / ${_questions.length} correct',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                passed
                    ? 'You earned $_earned coins! 🪙'
                    : 'Need 3+ correct to earn. Try again tomorrow!',
                style: GoogleFonts.inter(
                    color: Colors.white70, fontSize: 13),
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
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text('Done',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    final options = (q['options'] as List).cast<String>();
    final correct = q['answer'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // ===== Header =====
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Text('Daily Quiz',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.gold.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded,
                            color: AppColors.gold, size: 14),
                        const SizedBox(width: 4),
                        Text('$_earned',
                            style: GoogleFonts.inter(
                                color: AppColors.goldLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ===== Progress =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: List.generate(_questions.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i <= _index
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Question ${_index + 1} of ${_questions.length}',
                      style: GoogleFonts.inter(
                          color: AppColors.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      q['q'] as String,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.3),
                    ),
                    const SizedBox(height: 24),

                    // ===== Options =====
                    ...options.asMap().entries.map((e) {
                      final i = e.key;
                      final opt = e.value;
                      Color bg = const Color(0xFFFFFFFF);
                      Color border = Colors.white.withOpacity(0.08);
                      Color text = Colors.white;
                      IconData? trailing;

                      if (_answered) {
                        if (i == correct) {
                          bg = const Color(0xFFE6F4EC);
                          border = const Color(0xFF1E7A55);
                          text = const Color(0xFF4ADE80);
                          trailing = Icons.check_rounded;
                        } else if (i == _selected) {
                          bg = const Color(0xFFFFE9EC);
                          border = const Color(0xFF5A2A2E);
                          text = const Color(0xFFEF4444);
                          trailing = Icons.close_rounded;
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _pick(i),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 15),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: border),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + i),
                                        style: GoogleFonts.inter(
                                            color: text,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      opt,
                                      style: GoogleFonts.inter(
                                          color: text,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (trailing != null)
                                    Icon(trailing,
                                        color: text, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 8),

                    // ===== Next button =====
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _answered ? _next : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFFE8F0FF),
                          disabledForegroundColor: Colors.white38,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)),
                        ),
                        child: Text(
                          _index == _questions.length - 1
                              ? 'See Result'
                              : 'Next Question',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    if (_answered && _selected != correct)
                      Center(
                        child: Text(
                          'Correct answer highlighted in green',
                          style: GoogleFonts.inter(
                              color: Colors.white38, fontSize: 11),
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
