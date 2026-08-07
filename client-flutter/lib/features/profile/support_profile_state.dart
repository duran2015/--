import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

enum SupportProfileSection { basic, preference, support }

class SupportProfileState {
  const SupportProfileState({
    this.preferredName = '小鹿用户',
    this.personalTagline = '在这里，关注最真实的自己',
    this.gender = '不透露',
    this.lifeStage = '职场人士',
    this.avatarBytes,
    this.ageRange = '25–34 岁',
    this.city = '上海',
    this.emergencyContact = '',
    this.concerns = const ['工作压力'],
    this.preferredModes = const ['语音咨询'],
    this.preferredStyle = '',
    this.availableTime = '',
    this.currentGoal = '',
    this.counselingHistory = '',
    this.currentSupport = '',
    this.authorizedForBooking = false,
    this.lastSupportUpdatedAt,
    this.homePromptDismissed = false,
  });

  final String preferredName;
  final String personalTagline;
  final String gender;
  final String lifeStage;
  final Uint8List? avatarBytes;
  final String ageRange;
  final String city;
  final String emergencyContact;
  final List<String> concerns;
  final List<String> preferredModes;
  final String preferredStyle;
  final String availableTime;
  final String currentGoal;
  final String counselingHistory;
  final String currentSupport;
  final bool authorizedForBooking;
  final DateTime? lastSupportUpdatedAt;
  final bool homePromptDismissed;

  int get basicCompletion =>
      [preferredName, ageRange, city, emergencyContact]
          .where((value) => value.trim().isNotEmpty)
          .length *
      25;

  int get preferenceCompletion {
    final completed = [
      concerns.isNotEmpty,
      preferredModes.isNotEmpty,
      preferredStyle.isNotEmpty,
      availableTime.isNotEmpty,
    ].where((value) => value).length;
    return completed * 25;
  }

  int get supportCompletion {
    final completed = [
      currentGoal.isNotEmpty,
      counselingHistory.isNotEmpty,
      currentSupport.isNotEmpty,
      authorizedForBooking,
    ].where((value) => value).length;
    return completed * 25;
  }

  bool get preferenceNeedsAttention => preferenceCompletion < 75;

  bool get supportIsStale =>
      lastSupportUpdatedAt == null ||
      DateTime.now().difference(lastSupportUpdatedAt!).inDays >= 90;

  SupportProfileState copyWith({
    String? preferredName,
    String? personalTagline,
    String? gender,
    String? lifeStage,
    Uint8List? avatarBytes,
    String? ageRange,
    String? city,
    String? emergencyContact,
    List<String>? concerns,
    List<String>? preferredModes,
    String? preferredStyle,
    String? availableTime,
    String? currentGoal,
    String? counselingHistory,
    String? currentSupport,
    bool? authorizedForBooking,
    DateTime? lastSupportUpdatedAt,
    bool? homePromptDismissed,
  }) {
    return SupportProfileState(
      preferredName: preferredName ?? this.preferredName,
      personalTagline: personalTagline ?? this.personalTagline,
      gender: gender ?? this.gender,
      lifeStage: lifeStage ?? this.lifeStage,
      avatarBytes: avatarBytes ?? this.avatarBytes,
      ageRange: ageRange ?? this.ageRange,
      city: city ?? this.city,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      concerns: concerns ?? this.concerns,
      preferredModes: preferredModes ?? this.preferredModes,
      preferredStyle: preferredStyle ?? this.preferredStyle,
      availableTime: availableTime ?? this.availableTime,
      currentGoal: currentGoal ?? this.currentGoal,
      counselingHistory: counselingHistory ?? this.counselingHistory,
      currentSupport: currentSupport ?? this.currentSupport,
      authorizedForBooking: authorizedForBooking ?? this.authorizedForBooking,
      lastSupportUpdatedAt: lastSupportUpdatedAt ?? this.lastSupportUpdatedAt,
      homePromptDismissed: homePromptDismissed ?? this.homePromptDismissed,
    );
  }
}

class SupportProfileController extends Notifier<SupportProfileState> {
  @override
  SupportProfileState build() => const SupportProfileState();

  void dismissHomePrompt() {
    state = state.copyWith(homePromptDismissed: true);
  }

  void savePublicProfile({
    required String preferredName,
    required String personalTagline,
    required String gender,
    required String ageRange,
    required String city,
    required String lifeStage,
    Uint8List? avatarBytes,
  }) {
    state = state.copyWith(
      preferredName: preferredName,
      personalTagline: personalTagline,
      gender: gender,
      ageRange: ageRange,
      city: city,
      lifeStage: lifeStage,
      avatarBytes: avatarBytes,
    );
  }

  void saveBasic({
    required String preferredName,
    required String ageRange,
    required String city,
    required String emergencyContact,
  }) {
    state = state.copyWith(
      preferredName: preferredName,
      ageRange: ageRange,
      city: city,
      emergencyContact: emergencyContact,
    );
  }

  void savePreference({
    required List<String> concerns,
    required List<String> modes,
    required String style,
    required String availableTime,
  }) {
    state = state.copyWith(
      concerns: concerns,
      preferredModes: modes,
      preferredStyle: style,
      availableTime: availableTime,
      homePromptDismissed: true,
    );
  }

  void saveSupport({
    required String goal,
    required String counselingHistory,
    required String currentSupport,
    required bool authorized,
  }) {
    state = state.copyWith(
      currentGoal: goal,
      counselingHistory: counselingHistory,
      currentSupport: currentSupport,
      authorizedForBooking: authorized,
      lastSupportUpdatedAt: DateTime.now(),
    );
  }
}

final supportProfileProvider =
    NotifierProvider<SupportProfileController, SupportProfileState>(
  SupportProfileController.new,
);
