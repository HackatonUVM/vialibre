-- ============================================================================
-- VíaLibre: Datos Iniciales de Prueba (Seed)
-- ============================================================================

-- Obstáculo 1: Rampa bloqueada por vehículo
INSERT INTO public.barriers (
    id, location, latitude, longitude, category, category_code, severity,
    title, description, profile_flags, status, confirmations, reporter_id
) VALUES (
    'a0000000-0000-0000-0000-000000000001',
    extensions.ST_SetSRID(extensions.ST_MakePoint(-99.1332, 19.4326), 4326)::extensions.geography,
    19.4326, -99.1332,
    'Rampa inaccesible', 'open311_ramp_blocked', 'high',
    'Rampa para silla de ruedas bloqueada por camioneta repartidora',
    'Vehículo estacionado sobre la rampa peatonal del cruce. Impide el paso a personas en silla de ruedas y carriolas.',
    '{"wheelchairBlocked": true, "blindHazard": false, "strollerBlocked": true, "reducedMobilityBlocked": true}'::jsonb,
    'active', 4, '00000000-0000-0000-0000-000000000001'
) ON CONFLICT (id) DO NOTHING;

-- Obstáculo 2: Banqueta rota con zanja abierta
INSERT INTO public.barriers (
    id, location, latitude, longitude, category, category_code, severity,
    title, description, profile_flags, status, confirmations, reporter_id
) VALUES (
    'a0000000-0000-0000-0000-000000000002',
    extensions.ST_SetSRID(extensions.ST_MakePoint(-99.1340, 19.4335), 4326)::extensions.geography,
    19.4335, -99.1340,
    'Banqueta destruida', 'open311_pavement_obstacle', 'critical',
    'Zanja abierta por obras de tubería sin barandal de advertencia',
    'Banqueta levantada y zanja profunda sin señalamiento táctil ni paso peatonal protegido. Peligro grave de caída para personas ciegas o con bastón.',
    '{"wheelchairBlocked": true, "blindHazard": true, "strollerBlocked": true, "reducedMobilityBlocked": true}'::jsonb,
    'active', 7, '00000000-0000-0000-0000-000000000001'
) ON CONFLICT (id) DO NOTHING;

-- Obstáculo 3: Puesto semifijo en esquina
INSERT INTO public.barriers (
    id, location, latitude, longitude, category, category_code, severity,
    title, description, profile_flags, status, confirmations, reporter_id
) VALUES (
    'a0000000-0000-0000-0000-000000000003',
    extensions.ST_SetSRID(extensions.ST_MakePoint(-99.1320, 19.4315), 4326)::extensions.geography,
    19.4315, -99.1320,
    'Obstáculo peatonal', 'open311_street_hazard', 'medium',
    'Comercio informal reduce ancho de paso a 50 cm',
    'Puesto y cables a nivel de piso impiden el paso de silla de ruedas. Se requiere bajar al arroyo vehicular.',
    '{"wheelchairBlocked": true, "blindHazard": true, "strollerBlocked": true, "reducedMobilityBlocked": true}'::jsonb,
    'active', 2, '00000000-0000-0000-0000-000000000001'
) ON CONFLICT (id) DO NOTHING;

-- Aviso público en Lenguaje Claro de ejemplo
INSERT INTO public.public_briefs (
    id, doc_sha256, title, plain_summary
) VALUES (
    'b0000000-0000-0000-0000-000000000001',
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    'Cierre provisional de banqueta y desvío de Ruta 4 por obras de drenaje',
    '{
        "quePaso": "La banqueta poniente de Av. Juárez estará cerrada por cambio de tuberías del 27 de noviembre al 5 de diciembre.",
        "aQuienAfecta": "Peatones, usuarios en silla de ruedas y pasajeros de la Ruta 4 de transporte público.",
        "queHacerHoy": "Usa el paso peatonal señalizado de la banqueta oriente. La parada provisional de autobuses se ubica a 80 metros al norte (frente al parque)."
    }'::jsonb
) ON CONFLICT (id) DO NOTHING;
