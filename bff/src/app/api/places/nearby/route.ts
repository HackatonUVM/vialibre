import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    const { lat = 19.4326, lng = -99.1332 } = body;

    const places = [
      {
        placeId: 'metro_insurgentes_l1',
        name: 'Estación Insurgentes (Línea 1)',
        address: 'Glorieta de Insurgentes, Roma Norte, CDMX',
        lat: lat + 0.0012,
        lng: lng - 0.0015,
        wheelchairAccessibleEntrance: true,
        wheelchairAccessibleRestroom: true,
        wheelchairAccessibleParking: false,
        wheelchairAccessibleSeating: true,
        accessibilityOptions: {
          wheelchairAccessibleEntrance: true,
          wheelchairAccessibleRestroom: true,
          wheelchairAccessibleParking: false,
          wheelchairAccessibleSeating: true,
        },
      },
      {
        placeId: 'metro_juarez_l3',
        name: 'Estación Juárez (Línea 3)',
        address: 'Balderas y Artículo 123, Centro Histórico, CDMX',
        lat: lat - 0.0018,
        lng: lng + 0.0022,
        wheelchairAccessibleEntrance: true,
        wheelchairAccessibleRestroom: false,
        wheelchairAccessibleParking: false,
        wheelchairAccessibleSeating: true,
        accessibilityOptions: {
          wheelchairAccessibleEntrance: true,
          wheelchairAccessibleRestroom: false,
          wheelchairAccessibleParking: false,
          wheelchairAccessibleSeating: true,
        },
      },
      {
        placeId: 'clinica_accesible_1',
        name: 'Clínica de Especialidades y Accesibilidad CDMX',
        address: 'Dr. Márquez 162, Doctores, CDMX',
        lat: lat + 0.0025,
        lng: lng + 0.0018,
        wheelchairAccessibleEntrance: true,
        wheelchairAccessibleRestroom: true,
        wheelchairAccessibleParking: true,
        wheelchairAccessibleSeating: true,
        accessibilityOptions: {
          wheelchairAccessibleEntrance: true,
          wheelchairAccessibleRestroom: true,
          wheelchairAccessibleParking: true,
          wheelchairAccessibleSeating: true,
        },
      },
    ];

    return NextResponse.json({
      places,
      barriers: [],
    });
  } catch (err: any) {
    return NextResponse.json({ error: 'Error buscando lugares accesibles' }, { status: 500 });
  }
}
