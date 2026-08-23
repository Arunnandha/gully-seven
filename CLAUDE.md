# Gully Seven Project Guidance

## Project

Gully Seven is a 2D Android arcade game combining Lagori, Kabaddi, Kancha, Snake-style trailing stones, and maze-chase mechanics.

## Technical Requirements

- Use Godot 4.7.2 standard edition with the Compatibility renderer.
- Use typed GDScript only. Do not introduce C#.
- Target a stable 60 FPS on Android devices around Snapdragon 665/680 or Helio G85 with 4 GB RAM.
- Use a fixed 60 Hz physics update for gameplay.
- Separate gameplay simulation, presentation, UI, and platform services.
- Use explicit match states: `READY`, `AIM`, `BREAK`, `RAID`, `RETURN`, `REBUILD`, and `RESULT`.

## Gameplay and Performance

- Do not instantiate or free objects repeatedly during active gameplay; use object pools.
- Avoid per-frame allocations, dynamic lights, expensive shaders, and unnecessary physics bodies.
- Use `CharacterBody2D`, `Area2D`, and simple collision shapes for core gameplay.
- Run defender decisions less frequently than movement updates.
- Use touch-first controls while retaining mouse input for desktop testing.

## MVP Scope

The MVP includes player movement, a seven-stone tower, break/scatter behavior, stone collection and trail behavior, a breath meter, one defender, a defender ball, and a rebuild zone.

## Scope and Safety

- The MVP must remain offline. Do not add a backend, analytics, ads, multiplayer, or third-party plugins without approval.
- Do not manually edit anything inside `.godot`.
- Do not modify generated UID files.
- Keep changes small and focused.
- Do not modify unrelated files.
- Codex and Claude must not work on the same files concurrently.

## Validation and Reporting

- Validate GDScript and project loading after changes.
- Report files changed, verification performed, and remaining risks.
