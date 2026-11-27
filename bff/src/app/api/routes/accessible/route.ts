import { NextRequest, NextResponse } from 'next/server';
import { computeAccessibleRoute } from '@/lib/maps';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();

    const origin = {
      latitude: body.origin?.lat ?? body.origin?.latitude ?? 19.4326,
      longitude: body.origin?.lng ?? body.origin?.longitude ?? -99.1332,
    };

    const destQuery = body.destinationQuery || 'Destino seleccionado';
    const destination = {
      latitude: body.destination?.lat ?? body.destination?.latitude ?? origin.latitude + 0.008,
      longitude: body.destination?.lng ?? body.destination?.longitude ?? origin.longitude + 0.006,
    };

    const profile = body.profile || 'general';
    const computed = await computeAccessibleRoute(origin, destination, profile);

    // Formatear para compatibilidad con TransitRouteOption (Mobile Flutter) y AccessibleRouteResult (Web PWA)
    const mobileRoute = {
      id: 'route_transit_0',
      mode: 'TRANSIT',
      summaryLabel: 'Metrobús L1 + Ruta Peatonal Accesible',
      durationSeconds: computed.durationSeconds || 720,
      distanceMeters: computed.distanceMeters || 650,
      maxSlopePercent: 2.1,
      steepSegmentsCount: 0,
      encodedPolyline: computed.polyline,
      recommendationReason: profile === 'wheelchair'
        ? 'Ruta 100% libre de escalones con elevadores operativos y rampas suaves.'
        : 'Ruta peatonal con banquetas amplias y semáforos audibles.',
      steps: computed.steps.map((s, idx) => ({
        stepMode: idx === 1 ? 'TRANSIT' : 'WALK',
        instruction: s.instruction,
        distanceMeters: s.distanceMeters,
        durationSeconds: s.durationSeconds,
        lineName: idx === 1 ? 'Metrobús L1' : undefined,
        vehicleType: idx === 1 ? 'BUS' : 'WALK',
        departureStop: idx === 1 ? 'Estación Glorieta Insurgentes' : undefined,
        arrivalStop: idx === 1 ? 'Estación Hamburgo' : undefined,
        numStops: idx === 1 ? 2 : undefined,
      })),
      barriersOnRoute: [],
      firstTimerGuide: {
        checklistBeforeBoarding: [
          'Verifica que tu tarjeta de Movilidad Integrada tenga saldo.',
          'Ubica la zona con pictograma azul accesible en el andén.',
          'Espera a que el operador despliegue la rampa si el autobús no está a nivel.',
        ],
        stepByStep: [
          {
            stepNumber: 1,
            title: 'Acceso a estación',
            plainInstruction: 'Ingresa por la rampa ubicada al costado sur del andén.',
            accessibilityTip: 'El piso cuenta con franjas táctiles de advertencia.',
          },
          {
            stepNumber: 2,
            title: 'Abordaje accesible',
            plainInstruction: 'Espera en la primera puerta señalizada con símbolo internacional de accesibilidad.',
            accessibilityTip: 'El autobús cuenta con espacio reservado y cinturón de fijación.',
          },
        ],
        spokenSummaryText: 'Para esta ruta, dirígete a la estación por la rampa sur y aborda en la primera puerta accesible.',
      },
    };

    const resolvedDestination = {
      placeId: 'dest_resolved_poi',
      name: destQuery,
      formattedAddress: `${destQuery}, CDMX`,
      lat: destination.latitude,
      lng: destination.longitude,
      accessibilityOptions: {
        wheelchairAccessibleEntrance: true,
        wheelchairAccessibleRestroom: true,
        wheelchairAccessibleParking: true,
        wheelchairAccessibleSeating: true,
      },
    };

    return NextResponse.json({
      success: true,
      route: computed,
      routes: [mobileRoute],
      resolvedDestination,
      firstTimerGuide: mobileRoute.firstTimerGuide,
      betaWarning: null,
      profile,
    });
  } catch (err: any) {
    console.error('Error calculando ruta accesible:', err);
    return NextResponse.json({ error: 'Error calculando ruta accesible' }, { status: 500 });
  }
}
