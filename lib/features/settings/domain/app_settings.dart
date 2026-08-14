import 'package:equatable/equatable.dart';

import '../../../core/utils/json_codec.dart';

class AppSettings extends Equatable {
  const AppSettings({
    this.onboardingCompleted = false,
    this.selectedHorseId,
    this.useMockWeather = false,
    this.showDisclaimerAccepted = false,
    this.gramStep = 50,
  });

  final bool onboardingCompleted;
  final String? selectedHorseId;
  final bool useMockWeather;
  final bool showDisclaimerAccepted;
  final int gramStep;

  AppSettings copyWith({
    bool? onboardingCompleted,
    String? selectedHorseId,
    bool? useMockWeather,
    bool? showDisclaimerAccepted,
    int? gramStep,
    bool clearSelectedHorseId = false,
  }) {
    return AppSettings(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      selectedHorseId: clearSelectedHorseId
          ? null
          : (selectedHorseId ?? this.selectedHorseId),
      useMockWeather: useMockWeather ?? this.useMockWeather,
      showDisclaimerAccepted:
          showDisclaimerAccepted ?? this.showDisclaimerAccepted,
      gramStep: _normalizeGramStep(gramStep ?? this.gramStep),
    );
  }

  Map<String, dynamic> toJson() => {
    'onboardingCompleted': onboardingCompleted,
    'selectedHorseId': selectedHorseId,
    'useMockWeather': useMockWeather,
    'showDisclaimerAccepted': showDisclaimerAccepted,
    'gramStep': gramStep,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      onboardingCompleted: jsonBool(json['onboardingCompleted']),
      selectedHorseId: jsonString(json['selectedHorseId']),
      useMockWeather: jsonBool(json['useMockWeather']),
      showDisclaimerAccepted: jsonBool(json['showDisclaimerAccepted']),
      gramStep: _normalizeGramStep(jsonInt(json['gramStep']) ?? 50),
    );
  }

  static int _normalizeGramStep(int step) => step == 100 ? 100 : 50;

  @override
  List<Object?> get props => [
    onboardingCompleted,
    selectedHorseId,
    useMockWeather,
    showDisclaimerAccepted,
    gramStep,
  ];
}

abstract class SettingsRepository {
  Future<AppSettings> get();
  Future<void> save(AppSettings settings);
  Stream<AppSettings> watch();
}
