import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vialibre/app/theme/vialibre_theme.dart';
import 'package:vialibre/core/widgets/audio_player_bar.dart';
import 'package:vialibre/features/explore/presentation/explore_screen.dart';
import 'package:vialibre/features/gemini_assistant/data/assistant_repo.dart';
import 'package:vialibre/features/gemini_assistant/presentation/copilot_sheet.dart';
import 'package:vialibre/features/map_routes/domain/barrier_model.dart';
import 'package:vialibre/features/map_routes/domain/transit_route_model.dart';
import 'package:vialibre/features/map_routes/presentation/widgets/first_timer_guide_sheet.dart';
import 'package:vialibre/features/profile/data/profile_prefs_repo.dart';
import 'package:vialibre/features/profile/presentation/profile_screen.dart';
import 'package:vialibre/features/public_briefs/data/briefs_repo.dart';
import 'package:vialibre/features/report_barrier/data/report_repo.dart';

void main() {
  test('BarrierPin parses RPC and BFF detail payload cleanly', () {
    final pin = BarrierPin.fromRpcJson({
      'id': 42,
      'category': 'blocked_ramp',
      'title': 'Rampa obstruida',
      'description': 'Vehículo sobre la rampa peatonal',
      'severity': 4,
      'lat': 19.4326,
      'lng': -99.1332,
      'confirmations_count': 3,
      'distance_meters': 125.5,
      'photoSignedUrl': 'https://example.supabase.co/signed/photo.jpg',
    });

    expect(pin.id, 42);
    expect(pin.categoryLabel, 'Rampa bloqueada');
    expect(pin.severity, 4);
    expect(pin.confirmationsCount, 3);
    expect(pin.distanceMeters, 125.5);
    expect(pin.photoSignedUrl, isNotNull);
  });

  test('BarrierAnalysisResult parses {analysis, boundingBoxes} and agency', () {
    final res = BarrierAnalysisResult.fromJson({
      'analysis': {
        'isImageClear': false,
        'ambiguityReason': 'Poca iluminación en la toma',
        'category': 'broken_sidewalk',
        'title': 'Banqueta fracturada',
        'description': 'Desnivel pronunciado en losa peatonal.',
        'severity': 4,
        'confidenceScore': 0.91,
        'profileFlags': {'wheelchair': true},
        'boundingBoxes': [
          {
            'label': 'Grieta en banqueta',
            'box_2d': [320, 150, 780, 840],
          }
        ],
      }
    });

    expect(res.isImageClear, isFalse);
    expect(res.ambiguityReason, 'Poca iluminación en la toma');
    expect(res.confidenceScore, 0.91);
    expect(res.boundingBoxes.single.label, 'Grieta en banqueta');
    expect(res.suggestedAgency, 'Obras Públicas y Servicios Urbanos');
  });

  test('SpaceAssessmentResult and CopilotReply parse Gemini assistant payloads',
      () {
    final space = SpaceAssessmentResult.fromJson({
      'assessment': {
        'verdict': 'caution',
        'verdictLabel': 'Acceso con precaución',
        'summary': 'Rampa con inclinación moderada.',
        'featuresDetected': ['Rampa lateral', 'Puerta amplia'],
        'recommendation': 'Entra por acceso norte.',
        'boundingBoxes': [
          {
            'label': 'Rampa',
            'box_2d': [300, 100, 800, 700],
          }
        ],
      }
    });

    final reply = CopilotReply.fromJson({
      'replyText': 'Usa Metrobús L3 porque tiene piso al ras.',
      'suggestedAction': {
        'type': 'open_first_timer_guide',
        'label': 'Ver guía Metrobús',
      },
      'quickFollowUps': ['¿Dónde tomo el elevador?'],
    });

    expect(space.verdict, 'caution');
    expect(space.featuresDetected.length, 2);
    expect(space.boundingBoxes.single.label, 'Rampa');
    expect(reply.suggestedActionType, 'open_first_timer_guide');
    expect(reply.quickFollowUps.single, '¿Dónde tomo el elevador?');
  });

  test('TransitRouteOption and FirstTimerGuide parse real BFF routes payload',
      () {
    final route = TransitRouteOption.fromJson({
      'mode': 'TRANSIT',
      'durationSeconds': 1320,
      'distanceMeters': 4200,
      'recommendationReason': 'Acceso sin escalones en Metrobús.',
      'elevation': {'maxSlopePercent': 4.5, 'steepSegmentsCount': 0},
      'steps': [
        {
          'travelMode': 'TRANSIT',
          'transitLine': 'Metro Línea 2',
          'instruction': 'Aborda Metro Línea 2 hacia Cuatro Caminos',
          'stopFrom': 'Zócalo',
          'stopTo': 'Hidalgo',
          'distanceMeters': 2800,
          'durationSeconds': 720,
        }
      ],
    });

    final guide = FirstTimerGuide.fromJson({
      'summary': 'Usa el elevador norte.',
      'steps': ['Camina 100 m a la entrada accesible', 'Valida tu tarjeta'],
    });

    expect(route.durationMinutes, 22);
    expect(route.recommendationReason, 'Acceso sin escalones en Metrobús.');
    expect(route.summaryLabel, 'Metro Línea 2');
    expect(route.maxSlopePercent, 4.5);
    expect(route.steps.single.departureStop, 'Zócalo');
    expect(guide.stepByStep.length, 2);
  });

  test('SimplifiedBrief parses real BFF plainSummary and audioSignedUrl', () {
    final brief = SimplifiedBrief.fromJson(
      {
        'cached': true,
        'briefId': 9,
        'issuer': 'SEMOVI CDMX',
        'estimatedDuration': 'Del 1 al 5 de diciembre',
        'plainSummary': {
          'whatHappened': 'Cierre nocturno en estación Hidalgo.',
          'whoIsAffected': 'Usuarios de Línea 2.',
          'whatToDoToday': 'Utiliza la salida norte con elevador.',
        },
        'audioDurationSeconds': 38,
        'audioSignedUrl': 'https://example.supabase.co/signed/brief.wav',
      },
      fallbackTitle: 'Aviso',
    );

    expect(brief.cached, isTrue);
    expect(brief.issuer, 'SEMOVI CDMX');
    expect(brief.actionToday, 'Utiliza la salida norte con elevador.');
    expect(brief.audioDurationSeconds, 38);
    expect(brief.audioSignedUrl, isNotNull);
  });

  testWidgets('AudioPlayerBar enables voice button when fallbackText is set',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AudioPlayerBar(
              title: 'Prueba voz',
              fallbackText: 'Hola, esta ruta no tiene escalones.',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lectura en voz clara disponible'), findsOneWidget);
    expect(find.text('Escuchar en voz clara'), findsOneWidget);
  });

  testWidgets('ProfileScreen renders accessibility options without mandatory login',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Elige tu perfil'), findsOneWidget);
    expect(find.text(AccessibilityProfile.wheelchair.label), findsOneWidget);
    expect(find.text(AccessibilityProfile.lowVision.label), findsOneWidget);
    expect(find.text(AccessibilityProfile.plainLanguage.label), findsOneWidget);
  });

  testWidgets('ExploreScreen renders Gemini Copilot and space evaluator tiles',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ExploreScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('¿A dónde vamos hoy?'), findsOneWidget);
    expect(find.text('Evaluar foto'), findsOneWidget);
    expect(find.text('Pregúntale a VíaLibre · Gemini'), findsOneWidget);
    expect(find.text('Primera vez'), findsOneWidget);
  });

  testWidgets('CopilotSheet renders quick starter questions clearly',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CopilotSheet(onOpenFirstTimerGuide: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pregúntale a VíaLibre'), findsOneWidget);
    expect(find.text('¿Cómo uso el Metrobús por primera vez?'), findsOneWidget);
  });

  testWidgets('FirstTimerGuideSheet renders Timeline steps clearly',
      (tester) async {
    const sample = TransitRouteOption(
      id: 't1',
      mode: 'TRANSIT',
      summaryLabel: 'Metrobús Línea 3',
      durationSeconds: 900,
      distanceMeters: 2100,
      steps: [],
      barriersOnRoute: [],
      firstTimerGuide: FirstTimerGuide(
        checklistBeforeBoarding: ['Prepara tu tarjeta'],
        stepByStep: [
          FirstTimerGuideStep(
            stepNumber: 1,
            title: 'Entra por la rampa',
            plainInstruction: 'Valida en el lector verde.',
            accessibilityTip: 'Piso a nivel sin escalón.',
          ),
        ],
        spokenSummaryText: 'Resumen de prueba',
      ),
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: FirstTimerGuideSheet(route: sample)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paso 01'), findsOneWidget);
    expect(find.text('Entra por la rampa'), findsOneWidget);
  });

  testWidgets('ProfileScreen allows switching light and dark theme modes',
      (tester) async {
    late ViaLibrePalette capturedPalette;

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final mode =
                ref.watch(profileControllerProvider).valueOrNull?.themeMode ??
                    ThemeMode.system;
            return MaterialApp(
              theme: ViaLibreTheme.buildLightTheme(),
              darkTheme: ViaLibreTheme.buildDarkTheme(),
              themeMode: mode,
              home: Builder(
                builder: (ctx) {
                  capturedPalette = ViaLibreTheme.paletteOf(ctx);
                  return const ProfileScreen();
                },
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Apariencia'), findsOneWidget);
    expect(find.text('Auto'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Oscuro'), findsOneWidget);

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();
    expect(capturedPalette.isDark, isTrue);

    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();
    expect(capturedPalette.isDark, isFalse);
  });
}
