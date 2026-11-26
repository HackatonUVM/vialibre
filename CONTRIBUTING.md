# Guía de contribución — VíaLibre

¡Gracias por colaborar en **VíaLibre**!

## Flujo de ramas (Git Flow simplificado para hackatón)

- `main`: rama estable para demos y entregas. No hacer `push` directo con código sin probar.
- `feat/<modulo>-<descripcion>`: nuevas funcionalidades (ej. `feat/mobile-report-camera`, `feat/bff-gemini-vision`).
- `fix/<modulo>-<descripcion>`: correcciones de errores.
- `docs/<tema>`: documentación y diagramas.

## Convención de commits

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

- `feat(mobile): agregar pantalla de perfil accesible`
- `feat(bff): implementar endpoint de análisis de barreras`
- `fix(supabase): corregir search_path en RPC de deduplicación`
- `docs: actualizar guía de instalación local`

## Reglas clave del proyecto

1. **Nunca subir llaves o credenciales reales** (`.env`, `.env.local`, `google-services.json`, keystores). Usa siempre `.env.example` o `--dart-define`.
2. **Accesibilidad obligatoria en `mobile/`**: cada botón o control interactivo debe tener área táctil mínima de `48x48 dp`, contraste suficiente (`4.5:1` en texto, `3:1` en pines/íconos) y etiquetas `Semantics` para TalkBack.
3. **Privacidad en reportes**: limpiar metadatos EXIF (`keepExif: false`) en el teléfono antes de enviar cualquier fotografía al BFF.
