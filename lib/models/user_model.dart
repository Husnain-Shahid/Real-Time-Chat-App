import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class UserModel {
  final String uid;
  final String uniqueId;
  final String name;
  final String email;
  final String profileImage;
  final String about;
  final bool isOnline;
  final dynamic lastSeen;
  final DateTime createdAt;
  final String fcmToken;

  UserModel({
    required this.uid,
    required this.uniqueId,
    required this.name,
    required this.email,
    this.profileImage = '',
    this.about = 'Hey there! I am using WhatsApp.',
    this.isOnline = true,
    required this.lastSeen,
    required this.createdAt,
    this.fcmToken = '',
  });

  // Helper to generate a unique shareable ID (e.g., U8xK29mP4L)
  static String generateUniqueId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    String part1 = String.fromCharCodes(Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    String part2 = String.fromCharCodes(Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return 'U$part1-$part2'; // e.g. U8xK-29mP
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'uniqueId': uniqueId,
      'name': name,
      'username': email.split('@')[0], // default username from email
      'email': email,
      'profileImage': profileImage,
      'about': about,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'createdAt': createdAt,
      'fcmToken': fcmToken,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final createdAtValue = map['createdAt'];
    final createdAt = createdAtValue is Timestamp
        ? createdAtValue.toDate()
        : (createdAtValue is DateTime ? createdAtValue : DateTime.now());

    return UserModel(
      uid: map['uid'] ?? '',
      uniqueId: map['uniqueId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profileImage: map['profileImage'] ?? '',
      about: map['about'] ?? 'Hey there! I am using WhatsApp.',
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] ?? Timestamp.now(),
      createdAt: createdAt,
      fcmToken: map['fcmToken'] ?? '',
    );
  }
}