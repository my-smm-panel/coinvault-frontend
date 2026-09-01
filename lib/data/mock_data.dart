import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/ui_models.dart';

class MockData {
  static const quickActions = [
    QuickActionItem(
      title: 'Spin Wheel',
      icon: Icons.casino_rounded,
      colors: [AppColors.purple, Color(0xFFB84BFF)],
    ),
    QuickActionItem(
      title: 'Scratch Card',
      icon: Icons.style_rounded,
      colors: [AppColors.orangeLight, AppColors.orange],
    ),
    QuickActionItem(
      title: 'Check-in',
      icon: Icons.calendar_month_rounded,
      colors: [AppColors.gold, AppColors.orange],
    ),
  ];

  static const categories = [
    EarnCategory(
      title: 'App Install',
      subtitle: 'Install & Earn',
      reward: '+32',
      icon: Icons.download_rounded,
      colors: [AppColors.orangeLight, AppColors.orange],
    ),
    EarnCategory(
      title: 'Register & Earn',
      subtitle: 'Sign Up Bonus',
      reward: '+18',
      icon: Icons.assignment_turned_in_rounded,
      colors: [Color(0xFFFFC347), AppColors.gold],
    ),
    EarnCategory(
      title: 'Surveys',
      subtitle: 'Answer & Earn',
      reward: '+25',
      icon: Icons.poll_rounded,
      colors: [AppColors.purple, Color(0xFFB84BFF)],
    ),
    EarnCategory(
      title: 'Watch Videos',
      subtitle: 'Views Reward',
      reward: '+12',
      icon: Icons.play_circle_fill_rounded,
      colors: [Color(0xFF16C1FF), AppColors.blue],
    ),
    EarnCategory(
      title: 'Watch Ads',
      subtitle: 'Ads Reward',
      reward: '+24',
      icon: Icons.ondemand_video_rounded,
      colors: [Color(0xFFFF5678), AppColors.orange],
    ),
    EarnCategory(
      title: 'Games',
      subtitle: 'Play & Earn',
      reward: '+15',
      icon: Icons.sports_esports_rounded,
      colors: [Color(0xFF00DBB8), AppColors.blue],
    ),
    EarnCategory(
      title: 'Quiz',
      subtitle: 'Answer & Earn',
      reward: '+10',
      icon: Icons.quiz_rounded,
      colors: [AppColors.orange, AppColors.gold],
    ),
    EarnCategory(
      title: 'Offers',
      subtitle: 'Best Offers',
      reward: '+22',
      icon: Icons.local_offer_rounded,
      colors: [AppColors.purple, Color(0xFFFF2B7A)],
    ),
  ];

  static const offers = [
    OfferItem(title: 'Rush', subtitle: 'Install & Open', reward: '220 Coins', tag: 'Hot', color: AppColors.blue, initials: 'R'),
    OfferItem(title: 'CoinDCX', subtitle: 'Install & Register', reward: '310 Coins', tag: 'New', color: Colors.black87, initials: 'C'),
    OfferItem(title: 'MPL', subtitle: 'Play Game', reward: '250 Coins', tag: '', color: AppColors.orange, initials: 'M'),
    OfferItem(title: 'Dream11', subtitle: 'Register', reward: '450 Coins', tag: '', color: AppColors.purple, initials: 'D'),
    OfferItem(title: 'Upstox', subtitle: 'Open Account', reward: '300 Coins', tag: '', color: Color(0xFF0F766E), initials: 'U'),
  ];

  static const surveys = [
    SurveyItem('15 mins', '120 Coins'),
    SurveyItem('20 mins', '180 Coins'),
    SurveyItem('10 mins', '80 Coins'),
    SurveyItem('25 mins', '250 Coins'),
    SurveyItem('5 mins', '50 Coins'),
  ];

  static const challenges = [
    ChallengeItem(title: 'Complete 5 Tasks', progress: '0/5', percent: .0, reward: '+500'),
    ChallengeItem(title: 'Earn 1000 Coins', progress: '450/1000', percent: .45, reward: '+600'),
    ChallengeItem(title: 'Invite 3 Friends', progress: '1/3', percent: .33, reward: '+600'),
    ChallengeItem(title: 'Complete 10 Surveys', progress: '2/10', percent: .20, reward: '+600'),
  ];

  static const withdrawMethods = [
    WithdrawMethodItem(title: 'UPI', subtitle: 'Instant Transfer', colors: [AppColors.purple, Color(0xFFB84BFF)], glyph: 'UPI'),
    WithdrawMethodItem(title: 'PhonePe', subtitle: 'Instant Transfer', colors: [Color(0xFF5B2EFF), Color(0xFFB84BFF)], glyph: 'पे'),
    WithdrawMethodItem(title: 'Google Pay', subtitle: 'Instant Transfer', colors: [Color(0xFF4285F4), Color(0xFF34A853)], glyph: 'G'),
    WithdrawMethodItem(title: 'Amazon Gift Card', subtitle: 'Get Amazon Gift Card', colors: [Colors.black87, Colors.black54], glyph: 'a'),
    WithdrawMethodItem(title: 'Flipkart Gift Card', subtitle: 'Get Flipkart Gift Card', colors: [Color(0xFF2874F0), AppColors.gold], glyph: 'F'),
    WithdrawMethodItem(title: 'Paytm', subtitle: 'Instant Transfer', colors: [Color(0xFF00BAF2), Color(0xFF0079C1)], glyph: 'P'),
    WithdrawMethodItem(title: 'Bank Transfer', subtitle: 'Deposit to Bank', colors: [Color(0xFFDDF1FF), Color(0xFFC6E5FF)], glyph: '🏦'),
  ];

  static const walletHistory = [
    ActivityItem(
      title: 'Spin Wheel',
      subtitle: '1 hr ago',
      amount: '+50',
      trailing: '',
      colors: [AppColors.purple, Color(0xFFB84BFF)],
      icon: Icons.casino_rounded,
    ),
    ActivityItem(
      title: 'App Install (Rush)',
      subtitle: '24 Apr',
      amount: '+220',
      trailing: '',
      colors: [AppColors.orangeLight, AppColors.orange],
      icon: Icons.download_rounded,
    ),
    ActivityItem(
      title: 'Survey Completed',
      subtitle: '23 Apr',
      amount: '+120',
      trailing: '',
      colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
      icon: Icons.poll_rounded,
    ),
  ];

  static const notifications = [
    ActivityItem(title: 'You earned 220 coins', subtitle: 'Cash credited to your wallet', amount: '', trailing: '2m ago', colors: [AppColors.orangeLight, AppColors.orange], icon: Icons.workspace_premium_rounded),
    ActivityItem(title: 'Daily bonus claimed', subtitle: 'You got 50 coins', amount: '', trailing: '1h ago', colors: [AppColors.gold, AppColors.orange], icon: Icons.card_giftcard_rounded),
    ActivityItem(title: 'Withdrawal Success', subtitle: '₹100 sent to your UPI', amount: '', trailing: '2h ago', colors: [AppColors.green, Color(0xFF34D399)], icon: Icons.account_balance_wallet_rounded),
    ActivityItem(title: 'New Survey Available', subtitle: 'Complete now & earn', amount: '', trailing: '4h ago', colors: [AppColors.purple, Color(0xFFA855F7)], icon: Icons.poll_rounded),
    ActivityItem(title: 'Challenge Completed', subtitle: 'You earned 500 coins', amount: '', trailing: '5h ago', colors: [AppColors.orangeLight, AppColors.orange], icon: Icons.emoji_events_rounded),
    ActivityItem(title: 'Spin Bonus', subtitle: 'You won 100 coins', amount: '', trailing: '1d ago', colors: [AppColors.gold, AppColors.orange], icon: Icons.casino_rounded),
  ];
}
