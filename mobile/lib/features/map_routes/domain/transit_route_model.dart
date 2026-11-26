import 'barrier_model.dart';

class TransitStep {
  const TransitStep({
    required this.stepMode,
    required this.instruction,
    this.vehicleType,
    this.lineName,
    this.headsign,
    this.departureStop,
    this.arrivalStop,
    this.numStops,
    this.distanceMeters,
    this.durationSeconds,
  });

  /// WALK | TRANSIT
  final String stepMode;
  final String instruction;

  /// BUS | SUBWAY | RAIL | LIGHT_RAIL | COMBI | WALK
  final String? vehicleType;
  final String? lineName;
  final String? headsign;
  final String? departureStop;
  final String? arrivalStop;
  final int? numStops;
  final int? distanceMeters;
  final int? durationSeconds;

  factory TransitStep.fromJson(Map<String, dynamic> json) {
    final travel = (json['travelMode'] as String?) ??
        (json['stepMode'] as String?) ??
        'WALK';
    final line =
        (json['transitLine'] as String?) ?? (json['lineName'] as String?);
    return TransitStep(
      stepMode: travel,
      instruction: (json['instruction'] as String?) ?? '',
      vehicleType: (json['vehicleType'] as String?) ??
          (travel == 'TRANSIT' ? 'BUS' : null),
      lineName: line,
      headsign: json['headsign'] as String?,
      departureStop:
          (json['stopFrom'] as String?) ?? (json['departureStop'] as String?),
      arrivalStop:
          (json['stopTo'] as String?) ?? (json['arrivalStop'] as String?),
      numStops: (json['numStops'] as num?)?.toInt(),
      distanceMeters: (json['distanceMeters'] as num?)?.toInt(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
    );
  }
}

class FirstTimerGuideStep {
  const FirstTimerGuideStep({
    required this.stepNumber,
    required this.title,
    required this.plainInstruction,
    required this.accessibilityTip,
  });

  final int stepNumber;
  final String title;
  final String plainInstruction;
  final String accessibilityTip;

  factory FirstTimerGuideStep.fromJson(Map<String, dynamic> json) {
    return FirstTimerGuideStep(
      stepNumber: (json['stepNumber'] as num?)?.toInt() ?? 1,
      title: (json['title'] as String?) ?? '',
      plainInstruction: (json['plainInstruction'] as String?) ?? '',
      accessibilityTip: (json['accessibilityTip'] as String?) ?? '',
    );
  }
}

class FirstTimerGuide {
  const FirstTimerGuide({
    required this.checklistBeforeBoarding,
    required this.stepByStep,
    required this.spokenSummaryText,
  });

  final List<String> checklistBeforeBoarding;
  final List<FirstTimerGuideStep> stepByStep;
  final String spokenSummaryText;

  factory FirstTimerGuide.fromJson(Map<String, dynamic> json) {
    final checklistRaw = (json['checklistBeforeBoarding'] as List?) ?? const [];
    final structuredSteps = json['stepByStep'] as List?;
    final flatSteps = json['steps'] as List?;

    final parsedSteps = <FirstTimerGuideStep>[];
    if (structuredSteps != null && structuredSteps.isNotEmpty) {
      parsedSteps.addAll(
        structuredSteps
            .whereType<Map<String, dynamic>>()
            .map(FirstTimerGuideStep.fromJson),
      );
    } else if (flatSteps != null && flatSteps.isNotEmpty) {
      for (var i = 0; i < flatSteps.length; i++) {
        parsedSteps.add(
          FirstTimerGuideStep(
            stepNumber: i + 1,
            title: 'Indicación ${i + 1}',
            plainInstruction: flatSteps[i].toString(),
            accessibilityTip: '',
          ),
        );
      }
    }

    return FirstTimerGuide(
      checklistBeforeBoarding: checklistRaw.map((e) => e.toString()).toList(),
      stepByStep: parsedSteps,
      spokenSummaryText: (json['spokenSummaryText'] as String?) ??
          (json['summary'] as String?) ??
          '',
    );
  }
}

class TransitRouteOption {
  const TransitRouteOption({
    required this.id,
    required this.mode,
    required this.summaryLabel,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.steps,
    required this.barriersOnRoute,
    this.maxSlopePercent,
    this.steepSegmentsCount = 0,
    this.encodedPolyline,
    this.firstTimerGuide,
    this.audioBase64,
    this.recommendationReason,
  });

  /// WALK | TRANSIT
  final String mode;
  final String id;
  final String summaryLabel;
  final int durationSeconds;
  final int distanceMeters;
  final double? maxSlopePercent;
  final int steepSegmentsCount;
  final String? encodedPolyline;
  final List<TransitStep> steps;
  final List<BarrierPin> barriersOnRoute;
  final FirstTimerGuide? firstTimerGuide;
  final String? audioBase64;
  final String? recommendationReason;

  int get durationMinutes => (durationSeconds / 60).ceil();

  TransitRouteOption copyWith({
    FirstTimerGuide? firstTimerGuide,
  }) {
    return TransitRouteOption(
      id: id,
      mode: mode,
      summaryLabel: summaryLabel,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      maxSlopePercent: maxSlopePercent,
      steepSegmentsCount: steepSegmentsCount,
      encodedPolyline: encodedPolyline,
      steps: steps,
      barriersOnRoute: barriersOnRoute,
      firstTimerGuide: firstTimerGuide ?? this.firstTimerGuide,
      audioBase64: audioBase64,
      recommendationReason: recommendationReason,
    );
  }

  factory TransitRouteOption.fromJson(
    Map<String, dynamic> json, {
    int index = 0,
  }) {
    final stepsRaw = (json['steps'] as List?) ?? const [];
    final barriersRaw = (json['barriersOnRoute'] as List?) ?? const [];
    final guideJson = json['firstTimerGuide'] as Map<String, dynamic>?;
    final elev = json['elevation'] as Map<String, dynamic>?;
    final parsedSteps = stepsRaw
        .whereType<Map<String, dynamic>>()
        .map(TransitStep.fromJson)
        .toList();

    final mode = (json['mode'] as String?) ?? 'WALK';
    final transitLines = parsedSteps
        .map((s) => s.lineName)
        .whereType<String>()
        .where((l) => l.isNotEmpty)
        .toSet()
        .join(' + ');

    final defaultLabel = transitLines.isNotEmpty
        ? transitLines
        : (mode == 'TRANSIT' ? 'Ruta transporte público' : 'Ruta peatonal accesible');

    return TransitRouteOption(
      id: (json['id'] as String?) ?? 'route_${mode}_$index',
      mode: mode,
      summaryLabel: (json['summaryLabel'] as String?) ?? defaultLabel,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
      maxSlopePercent: (elev?['maxSlopePercent'] as num?)?.toDouble() ??
          (json['maxSlopePercent'] as num?)?.toDouble(),
      steepSegmentsCount:
          (elev?['steepSegmentsCount'] as num?)?.toInt() ?? 0,
      encodedPolyline: json['encodedPolyline'] as String?,
      steps: parsedSteps,
      barriersOnRoute: barriersRaw
          .whereType<Map<String, dynamic>>()
          .map(BarrierPin.fromRpcJson)
          .toList(),
      firstTimerGuide:
          guideJson != null ? FirstTimerGuide.fromJson(guideJson) : null,
      audioBase64: json['audioBase64'] as String?,
      recommendationReason: json['recommendationReason'] as String?,
    );
  }
}
