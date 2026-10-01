# Mes Pictos (working name)

An iPad and iPhone app, inspired by PECS (Picture Exchange Communication System), that helps a
non-speaking or minimally-speaking autistic child communicate with pictograms spoken aloud in French.

See **[docs/PLAN.md](docs/PLAN.md)** for the goals, how PECS maps to app features, pictogram sources
and licences, the architecture, and the roadmap.

## Status

**Roadmap step 1 — MVP « tableau parlant » — is implemented** (see the plan §9):

- SwiftData models (Pictogram / Page / Placement), CloudKit-ready, with iCloud sync enabled
  (falls back to local-only storage if iCloud is unavailable).
- **Child mode**: pages of large pictogram cards (default 2×2), instant French speech on tap
  (recording > spoken text > label), tap debounce, haptics.
- **Show mode** (*mode montrer*): the tapped card flies to the centre of the screen to be shown
  to an adult; closing gesture, auto-close, gentle celebration and Reduce Motion are configurable.
- **Permanent bar** with *Non* and *Aide*, editable and extendable by the parent.
- **Parent mode** behind a 3-second long-press plus optional 4-digit code and Face ID: page CRUD,
  grid size, drag & drop within a page (move/swap), drag onto page tabs (spring-loading),
  context menus (move/duplicate/hide/delete), photo and camera import with square crop,
  voice recording per pictogram, and a **page manager** (add, edit, hide, reorder, delete).
- Page tabs display a **configurable icon** (curated SF Symbols catalogue) above the title —
  a child who cannot read yet finds their page by its picture.
- **Symbol library (ARASAAC)**: the pictogram editor can pick from ARASAAC online search
  (~13,000 pictograms, French keywords, CC BY-NC-SA) or from a **bundled offline starter
  pack** (72 pictograms: critical cards, sentence starters, food, play, people, emotions,
  school, animals, places). Each imported symbol keeps its ARASAAC id and licence, and the
  attribution is shown in the credits.
- Settings: French voice picker with preview, rate/pitch, label style (MAJUSCULES by default),
  touch and show-mode options, Guided Access instructions, ARASAAC credits.
- Unit tests (Swift Testing) for the move/swap logic and speech priority.

Next steps (roadmap): print/PDF export and `.pictos` import/export, then the sentence strip.
Photo background removal (Vision) is optional — his iPad 7th gen does not support it.
