// lib/models/user_model.dart
class UserModel {
  final int id;
  final String name;
  final String email;
  final String mode;
  final List<String> diseases;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mode,
    required this.diseases,
    this.age,
    this.gender,
    this.height,
    this.weight,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['full_name'] ?? '',
      email: json['email'] ?? '',
      mode: json['preferred_mode'] ?? 'swasthya',
      diseases: List<String>.from(json['diseases'] ?? []),
      age: json['age'],
      gender: json['gender'],
      height: json['height'],
      weight: json['weight'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': name,
      'email': email,
      'preferred_mode': mode,
      'diseases': diseases,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
    };
  }
}
