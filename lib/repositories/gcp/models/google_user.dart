class GoogleUser {
  final String? displayName;
  final String email;
  final String? photoUrl;
  final String idToken;

  const GoogleUser({
    this.displayName,
    required this.email,
    this.photoUrl,
    required this.idToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'idToken': idToken,
    };
  }

  factory GoogleUser.fromMap(Map<String, dynamic> map) {
    return GoogleUser(
      displayName: map['displayName'],
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      idToken: map['idToken'],
    );
  }
}
