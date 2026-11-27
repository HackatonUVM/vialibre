import { NextRequest, NextResponse } from 'next/server';
import { computeWalkOrTransitRoutes } from '@/lib/apis/open-maps';
import { decodeEncodedPolyline, toLineStringWKT } from '@/lib/geo/polyline';
import { supabaseAdmin } from '@/lib/supabase';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));

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
    const avoidSlopes = body.avoidSlopes !== undefined ? Boolean(body.avoidSlopes) : true;
    const maxSlopePercent = typeof body.maxSlopePercent === 'number' ? body.maxSlopePercent : 8.0;
    const modes = Array.isArray(body.modes) ? body.modes : ['WALK'];
    const includeFirstTimerGuide = body.includeFirstTimerGuide !== undefined ? Boolean(body.includeFirstTimerGuide) : true;

    // Cálculo con el adaptador gratuito de OpenStreetMap (Valhalla / OSRM / ORS + Open-Meteo)
    const { routes, provider, betaWarning } = await computeWalkOrTransitRoutes({
      origin,
      destination,
      profile,
      avoidSlopes,
      maxSlopePercent,
      modes,
      includeFirstTimerGuide,
      destinationQuery: destQuery,
    });

    const primaryRoute = routes[0];

    // Intersección geoespacial PostGIS con barreras activas a lo largo de la ruta
    try {
      const routePoints = decodeEncodedPolyline(primaryRoute.encodedPolyline, 5);
      const lineStringWkt = toLineStringWKT(routePoints);

      const { data, error } = await supabaseAdmin.rpc('find_barriers_along_route', {
        p_route_wkt: lineStringWkt,
        p_buffer_meters: 25.0,
        p_profile: profile,
      });

      if (!error && Array.isArray(data)) {
        primaryRoute.barriersOnRoute = data;
      }
    } catch (rpcErr) {
      // Degradar con lista vacía si PostGIS no está disponible
      primaryRoute.barriersOnRoute = [];
    }

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
      routes,
      route: primaryRoute,
      routeProvider: provider,
      resolvedDestination,
      firstTimerGuide: primaryRoute.firstTimerGuide,
      firstTimerSummary: primaryRoute.firstTimerGuide?.spokenSummaryText,
      firstTimerSteps: primaryRoute.firstTimerGuide?.checklistBeforeBoarding,
      betaWarning,
      profile,
    });
  } catch (err: any) {
    console.error('Error calculando ruta accesible:', err);
    return NextResponse.json({ error: 'Error calculando ruta accesible' }, { status: 500 });
  }
}
