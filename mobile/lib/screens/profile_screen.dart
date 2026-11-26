import 'package:flutter/material.dart';
import '../models/barrier.dart';

class ProfileScreen extends StatelessWidget {
  final AccessibilityProfile selectedProfile;
  final ValueChanged<AccessibilityProfile> onProfileChanged;

  const ProfileScreen({
    super.key,
    required this.selectedProfile,
    required this.onProfileChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Semantics(
          header: true,
          child: const Text(
            'Elige tu Perfil',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFB300),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'VíaLibre adapta rutas, pendientes y avisos públicos a tus necesidades sin exigir cuentas ni contraseñas.',
          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 24),
        _buildProfileCard(
          context: context,
          profile: AccessibilityProfile.wheelchair,
          icon: Icons.accessible_forward,
          title: 'Silla de ruedas / Carriola',
          description: 'Evita banquetas rotas, escalones sin rampa y pendientes > 6%. Cruces a nivel.',
        ),
        const SizedBox(height: 14),
        _buildProfileCard(
          context: context,
          profile: AccessibilityProfile.lowVision,
          icon: Icons.visibility_outlined,
          title: 'Baja visión',
          description: 'Alto contraste, advertencia de zanjas u obstáculos aéreos y guía sonora de pasos.',
        ),
        const SizedBox(height: 14),
        _buildProfileCard(
          context: context,
          profile: AccessibilityProfile.clearReading,
          icon: Icons.menu_book_outlined,
          title: 'Lectura clara / Neurodivergencia',
          description: 'Instrucciones cortas paso a paso, vocabulario simple y reducción de estímulos visuales.',
        ),
      ],
    );
  }

  Widget _buildProfileCard({
    required BuildContext context,
    required AccessibilityProfile profile,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = selectedProfile == profile;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title. $description',
      child: InkWell(
        onTap: () => onProfileChanged(profile),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF0F2444),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFB300) : const Color(0xFF1E293B),
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 36, color: const Color(0xFFFFB300)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.3),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xFFFFB300), size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
