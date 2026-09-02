import 'dart:math' as math;

/// User model
class UserModel {
  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final int coins;
  final int dailySpinsUsed;
  final DateTime? lastSpinDate;
  final String? upiId;
  final String? bankDetails;

  User({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
    this.coins = 0,
    this.dailySpinsUsed = 0,
    this.lastSpinDate,
    this.upiId,
    this.bankDetails,
  });

  factory UserModel.fromFirebase(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      displayName: data['displayName'] ?? 'User',
      email: data['email'],
      photoUrl: data['photoUrl'],
      coins: data['coins'] ?? 0,
      dailySpinsUsed: data['dailySpinsUsed'] ?? 0,
      lastSpinDate: data['lastSpinDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['lastSpinDate'])
          : null,
      upiId: data['upiId'],
      bankDetails: data['bankDetails'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'coins': coins,
      'dailySpinsUsed': dailySpinsUsed,
      'lastSpinDate': lastSpinDate?.millisecondsSinceEpoch,
      'upiId': upiId,
      'bankDetails': bankDetails,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    int? coins,
    int? dailySpinsUsed,
    DateTime? lastSpinDate,
    String? upiId,
    String? bankDetails,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      coins: coins ?? this.coins,
      dailySpinsUsed: dailySpinsUsed ?? this.dailySpinsUsed,
      lastSpinDate: lastSpinDate ?? this.lastSpinDate,
      upiId: upiId ?? this.upiId,
      bankDetails: bankDetails ?? this.bankDetails,
    );
  }

  /// Check if user can spin today (max 2 spins per day)
  bool canSpin() {
    final now = DateTime.now();
    if (lastSpinDate == null) return true;
    final isSameDay = lastSpinDate!.year == now.year &&
                      lastSpinDate!.month == now.month &&
                      lastSpinDate!.day == now.day;
    if (!isSameDay) return true;
    return dailySpinsUsed < 2;
  }

  /// Get remaining spins for today
  int remainingSpins() {
    final now = DateTime.now();
    if (lastSpinDate == null) return 2;
    final isSameDay = lastSpinDate!.year == now.year &&
                      lastSpinDate!.month == now.month &&
                      lastSpinDate!.day == now.day;
    if (!isSameDay) return 2;
    return (2 - dailySpinsUsed).clamp(0, 2);
  }
}

/// Spin result model
class SpinResult {
  final int coins;
  final bool isJackpot;
  
  SpinResult({required this.coins, this.isJackpot = false});
  
  static const List<int> rewards = [10, 2, 3]; // 100 coin jackpot is weighted 0%
  
  /// Generate spin result with weighted probability
  /// 10 coins: 40%, 2 coins: 30%, 3 coins: 30%, 100 coins: 0% (never wins)
  static SpinResult generate() {
    final random = math.Random();
    final roll = random.nextDouble();
    
    if (roll < 0.40) {
      return SpinResult(coins: 10);
    } else if (roll < 0.70) {
      return SpinResult(coins: 2);
    } else {
      return SpinResult(coins: 3);
    }
  }
  
  /// 100 coins is programmatically impossible to win
  // static SpinResult generateWithJackpot() {
  //   return SpinResult.generate(); // 100 coins never returned
  // }
}

/// Withdraw request model
class WithdrawRequest {
  final String id;
  final String userId;
  final int coins;
  final double amountINR;
  final String method; // 'upi' or 'bank'
  final String details; // UPI ID or bank details
  final String status; // 'pending', 'paid', 'rejected'
  final DateTime createdAt;
  final DateTime? paidAt;

  WithdrawRequest({
    required this.id,
    required this.userId,
    required this.coins,
    required this.amountINR,
    required this.method,
    required this.details,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  factory WithdrawRequest.fromMap(Map<String, dynamic> map) {
    return WithdrawRequest(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      coins: map['coins'] ?? 0,
      amountINR: (map['amountINR'] ?? 0).toDouble(),
      method: map['method'] ?? 'upi',
      details: map['details'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      paidAt: map['paidAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['paidAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'coins': coins,
      'amountINR': amountINR,
      'method': method,
      'details': details,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'paidAt': paidAt?.millisecondsSinceEpoch,
    };
  }
}