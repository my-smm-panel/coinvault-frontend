/// User profile fields cached locally for display.
/// Financial balances and payout credentials are always fetched from the backend.
class UserModel {
  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
  });

  factory UserModel.fromFirebase(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      displayName: data['displayName'] ?? 'User',
      email: data['email'],
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
