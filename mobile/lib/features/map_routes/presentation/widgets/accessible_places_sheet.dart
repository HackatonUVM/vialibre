import 'package:flutter/material.dart';

import '../../../../app/theme/vialibre_theme.dart';
import '../../domain/accessible_place_model.dart';

/// Hoja de lugares, paradas y servicios cercanos con atributos de accesibilidad.
class AccessiblePlacesSheet extends StatelessWidget {
  const AccessiblePlacesSheet({
    required this.places,
    required this.onSelectPlace,
    super.key,
  });

  final List<AccessiblePlace> places;
  final ValueChanged<AccessiblePlace> onSelectPlace;

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Lugares y accesos cercanos (${places.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              Expanded(
                child: places.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No encontramos lugares cercanos con esa búsqueda. Intenta ampliar el término.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: places.length,
                        itemBuilder: (context, index) {
                          final place = places[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              title: Text(
                                place.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (place.address.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    SelectableText(place.address),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      if (place.wheelchairAccessibleEntrance ==
                                          true)
                                        const _PlaceTag('Entrada con rampa'),
                                      if (place.wheelchairAccessibleRestroom ==
                                          true)
                                        const _PlaceTag('Baño accesible'),
                                      if (place.wheelchairAccessibleParking ==
                                          true)
                                        const _PlaceTag('Estacionamiento'),
                                      if (place.wheelchairAccessibleSeating ==
                                          true)
                                        const _PlaceTag('Asientos accesibles'),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.directions_rounded,
                                  color: p.coral,
                                ),
                                tooltip: 'Trazar ruta hasta aquí',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  onSelectPlace(place);
                                },
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                onSelectPlace(place);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaceTag extends StatelessWidget {
  const _PlaceTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: p.mintSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: p.mintInk,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
