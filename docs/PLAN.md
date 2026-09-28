# Plan: a PECS-inspired communication app for iPad and iPhone

> Status: **draft / proposal**. Nothing is built yet. This document covers what
> the app should do, why (grounded in PECS), how to build it, and in what order.
> The open questions at the end need an answer before development starts.

Working name: **"Mes Pictos"** (placeholder). See [§8](#8-licensing-privacy-and-safety)
for why the store name should not contain "PECS".

---

## 1. Goals and non-goals

**Goals**

1. Show pages of pictograms. When the child taps one, the app says it out loud **in French**.
2. Let a parent create several pages, each with pictograms. Every pictogram has a text label.
3. Let the parent move pictograms around a page and between pages.
4. Create pictograms from a **photo** (library or camera) or from a **pictogram library** made
   for AAC/PECS (ARASAAC first, see [§5](#5-pictogram-sources)).
5. **Import and export** pictograms and pages.
6. Later: build **phrases** by putting pictograms in order on a sentence strip (*bande phrase*).
7. Work **offline**, keep the child's data private, and make it hard for the child to change or
   delete anything by accident.

**Non-goals (for now)**

- The app does not replace PECS training. Phases I–III depend on physically handing a card to a
  communication partner, and the app should support that, not remove it (see [§2](#2-pecs-in-brief-and-what-it-means-for-the-app)).
- No accounts, no server, no ads, no analytics.
- No Android or web version.

---

## 2. PECS in brief, and what it means for the app

PECS (Picture Exchange Communication System, Bondy & Frost / Pyramid Educational Consultants) teaches
a child to **start** a communication by **giving a picture to a partner** in exchange for what they
want. It is taught in 6 phases, plus additional lessons on attributes and "critical communication skills".

| Phase | What the child learns | What it means for the app |
|---|---|---|
| **I. How to communicate** | Exchange one picture for a highly motivating item (*renforçateur*). Taught with 2 adults, no verbal prompts. | Mostly low-tech. The app helps by **printing the same cards** used in the app, and offers a *single-pictogram* page layout (1 huge card). |
| **II. Distance and persistence** | Go and get the picture/book, go to the partner, even when they're far away. | The device must always be available and quick to use: no login, opens on the last page, large targets. |
| **III. Picture discrimination** | Choose the right picture among several in the *classeur de communication*, with correspondence checks. | **Adjustable grid size** per page (1, 2, 4, 6, 9, 12, …), the ability to **hide** pictograms without deleting them, and **stable positions** so the child can build motor memory. |
| **IV. Sentence structure** | Build "**Je veux** + item" on a detachable sentence strip, then "read" it to the partner. | The **sentence strip**: a fixed "Je veux" starter, tapping pictograms adds them to the strip, tapping the strip reads the whole sentence while **highlighting each picture in turn**. |
| **Attributes** | Expand requests: "Je veux **la grosse** balle **rouge**". | Pages or sections for colours, sizes, quantities, shapes. Optional colour coding by word type. |
| **V. Answering "Qu'est-ce que tu veux ?"** | Respond to the question as well as initiating spontaneously. | No specific feature. The same strip works for this. |
| **VI. Commenting** | "**Je vois** …", "**J'entends** …", "**J'ai** …", "**C'est** …". | More **sentence starters**, and a way to switch between them. |

**Critical communication skills** (additional PECS lessons) map to pre-made cards that should always
be visible in a **permanent bar**: **Aide** (help), **Pause** (break), **Non** (no), **Oui** (yes),
**Attends** (wait, which works well with a visual timer), and **Fini** / **Encore** (finished / more).
Transitions and **visual schedules** (*emploi du temps visuel*) are also part of those lessons.

**Principles to follow throughout the design**

- **The child starts the exchange.** The app speaks only when the child acts. It never talks on its own
  or plays sounds unprompted.
- **Consistency.** A pictogram stays in the same place, and a card looks the same in the app and in
  the paper binder.
- **Reinforcers first.** Early vocabulary is what the child *really* wants. Real photos of *his*
  cup or *his* favourite biscuits often work better than generic drawings at first, so photos are
  a first-class source, not a fallback.
- **The communication partner stays central.** The sentence strip is something the child shows or
  reads *to someone*. It is not just a speech button.
- **Low-tech backup.** Devices run out of battery or break. The paper binder must stay usable, which
  is one more reason to be able to print cards.

> Pyramid sells its own iPad app (**PECS IV+**). It reproduces the PECS book (up to 30 pages, a
> Sentence Starter page, a Sentence Strip) as a speech-generating device. It is worth trying and
> discussing with your son's speech therapist (*orthophoniste*) or PECS consultant before building.
> Free alternatives to try for inspiration: **LetMeTalk** (iOS, ARASAAC symbols) and **CBoard**
> (open-source web app, Open Board Format).

---

## 3. Features

### 3.1 Requested scope (MVP)

**Child mode (*Mode enfant*)**, the default and only screen the child sees:
- A grid of pictograms (image and label) on the current page, with page tabs.
- Tap a pictogram to highlight it, give haptic feedback, and speak it in French.
- Nothing in this mode can be edited, deleted, or moved.

**Parent mode (*Mode parent*)**, protected by a 3-second long-press on a lock icon plus an optional code or Face ID:
- Create, rename, reorder, and delete **pages** (*pages*). Set the grid size per page (columns × rows).
- Create or edit a **pictogram**:
  - **Label** (*texte affiché*), for example "pomme".
  - **Spoken text** (*texte prononcé*), optional, for example "une pomme". It also fixes TTS mistakes such as first names.
  - **Image** from the photo library (`PhotosPicker`), the camera, or a symbol library (§5), then cropped to a square.
- **Move** pictograms:
  - Within a page: drag onto an empty slot to place it there, or onto a filled slot to **swap**. Swapping keeps every other pictogram where it was.
  - Between pages: drag onto a page tab. Hovering for about 0.6 s opens that page so the pictogram can be dropped into a slot.
  - Fallback for iPhone and for accessibility: a context menu with "Déplacer vers…", "Dupliquer vers…", "Masquer", and "Supprimer de la page".
- **Import and export** (§7.6): a single pictogram, a set of pages, or a full backup, shared through AirDrop, Mail, or Files.

### 3.2 Planned: sentence strip (*bande phrase*)

- A strip at the top of the screen that can be enabled per profile.
- **Sentence starters** (*débuts de phrase*): "Je veux", "Je vois", "J'entends", "J'ai", "C'est", "Je sens". A setting can require a starter as the first card, following the Phase IV rule.
- Tapping a pictogram adds it to the strip. Speaking the single word at that moment is optional.
- Tapping the strip, or the ▶ button, reads the whole sentence and **highlights each card as it is spoken**.
- Buttons to remove the last card and to clear the strip. Cards on the strip can be reordered by dragging.
- Settings for "clear after reading" and maximum length.
- The data model supports this from day one (see `SentenceStrip` in §7.3).

### 3.3 Suggested additions, in priority order

**High value, low cost. These should go into the first releases.**
1. **Hide without deleting** (*masquer*). This lets you control how many choices the child sees (Phase III) without losing work.
2. **Permanent bar** with Aide, Pause, Non, Oui, Attends, and Fini. It stays visible on every page and each card can be turned on or off.
3. **Recorded voice per pictogram**. Record a parent's voice, which is often more engaging than TTS. Playback priority: recording, then spoken text, then label.
4. **Print cards** (AirPrint or PDF). Choose a size (5 cm is typical), with a border, the label, and cutting guides. This keeps the paper binder and the app identical.
5. **Label style**: capital letters (*MAJUSCULES D'IMPRIMERIE*, which children learn first in French *maternelle*), lower case, or no label. Also font size and position.
6. **Touch adaptations**: ignore repeated taps for a configurable delay, an optional "hold to select" mode, and a choice of visual feedback.

**Strongly recommended**

7. **Phase presets** (*niveau PECS*): one setting that switches the layout. Phases I–II show 1 large card and no strip. Phase III uses an N-card grid with no strip. Phase IV and above turn on the strip with "Je veux". Phase VI adds the comment starters.
8. **Attributes**: ready-made pages for colours, sizes, quantities, and shapes.
9. **Colour coding by word type** (modified Fitzgerald key, optional): people, verbs, nouns, adjectives, social words, and starters each get a different border colour.
10. **Folder pictograms**: a pictogram that opens another page, for example "Manger" opening the food page.
11. **iCloud sync** between the parent's iPhone and the child's iPad, plus automatic local backups.
12. **Communication log** (*journal*): which pictograms and sentences were used, and when. Stored on the device, exportable as CSV for the orthophoniste. It can be turned off.

**Nice to have, later**

13. **Visual schedule** (*emploi du temps*) and a **"D'abord / Ensuite"** (first/then) board. Not strictly PECS, but closely related and very useful for transitions.
14. **Visual timer** for "Attends" (a disappearing disc), a companion to the Attends card.
15. **Background removal** for photos. Vision's subject lifting (`VNGenerateForegroundInstanceMaskRequest`) turns a photo of an object into a clean, pictogram-like card.
16. **Open Board Format (.obf / .obz)** import and export, to work with CBoard, AsTeRICS Grid, CoughDrop, and others.
17. **Several child profiles**, for siblings or for a school or therapist setup.
18. **Personal Voice** (iOS 17 and later), so the app can speak with a voice the parent created on the device.
19. **Token board** (*tableau de jetons*) and a reinforcer menu. These are often used alongside PECS.

---

## 4. Screens and UX

### 4.1 iPad, child mode (landscape)

```
┌──────────────────────────────────────────────────────────────────────┐
│ [Je veux] [pomme] [ · ] [ · ] [ · ]                    ▶ Lire   ⌫  ✕ │  bande phrase (optional)
├──────────────────────────────────────────────────────────────────────┤
│  Manger │ Jouer │ Personnes │ Lieux │ Émotions                        │  page tabs (can be hidden)
├──────────────────────────────────────────────────────────────────────┤
│  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐               │
│  │  img  │  │  img  │  │  img  │  │  img  │  │       │               │
│  │ POMME │  │BANANE │  │ LAIT  │  │GÂTEAU │  │ (vide)│               │  grid: columns × rows per page
│  └───────┘  └───────┘  └───────┘  └───────┘  └───────┘               │
│  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐               │
│  │  ...  │  │  ...  │  │  ...  │  │  ...  │  │  ...  │               │
│  └───────┘  └───────┘  └───────┘  └───────┘  └───────┘               │
├──────────────────────────────────────────────────────────────────────┤
│  [AIDE] [PAUSE] [NON] [OUI] [ATTENDS] [FINI]                     🔒  │  permanent bar + parent lock
└──────────────────────────────────────────────────────────────────────┘
```

### 4.2 Screen list

| Screen | Mode | Notes |
|---|---|---|
| Board (grid, tabs, strip, bar) | Child | Opens on the last page used. Calm visuals, no animations beyond tap feedback. |
| Board in edit mode | Parent | Same layout with drag handles, "+" on empty slots, and a toolbar (add page, grid size, import, export). |
| Pictogram editor (sheet) | Parent | Image source picker (Photos, Camera, Library, Files), crop, label, spoken text, ▶ preview, record voice, word type, pages it appears on. |
| Symbol search (sheet) | Parent | Search field in French, results grid, colour and skin options, attribution shown. |
| Page settings | Parent | Title, icon, grid size, hidden or visible, background colour. |
| Settings | Parent | Voice (choose a French voice, speed, pitch), phase preset, label style, touch options, parent lock, sync, backups, log, credits and licences. |
| Import review | Parent | Preview of incoming pictograms and pages, conflict handling (keep both, replace, skip). |

### 4.3 iPhone

The iPhone uses the same data and the same pages. The grid scales down, and a page can set a smaller
column count for compact width if needed. On iPhone the parent will probably edit more than the child
uses it, so the editor must be comfortable to use one-handed. The "Déplacer vers…" menu matters most here.

### 4.4 Locking the child in the app

- Document **Guided Access** (*Accès guidé*: Réglages ▸ Accessibilité) in an onboarding screen. It is the only reliable way to stop the child leaving the app.
- Inside the app, parent mode needs a hidden gesture (3 s long-press) plus an optional code or Face ID.

---

## 5. Pictogram sources

| Source | Size | French? | Licence | Access | Use in the app |
|---|---|---|---|---|---|
| **[ARASAAC](https://arasaac.org)** (Gov. of Aragón, drawings by Sergio Palao) | about 13,000 | **Yes**, native French keywords | **CC BY-NC-SA** | Public REST API, no key needed | **Primary online search.** Also a bundled starter pack. |
| **[Mulberry Symbols](https://mulberrysymbols.org/)** | about 3,400 | No (English names, labels need translating) | CC BY-SA 2.0 UK | SVG on GitHub | Bundled alternative if the app ever becomes commercial (commercial use allowed). |
| **[Sclera](https://www.opensymbols.org/repositories/sclera)** | about 11,000 | Partial | CC BY-NC | Through aggregators | Optional high-contrast (white on black) set. |
| **[OpenMoji](https://openmoji.org/)** | about 4,000 | Emoji names (Unicode CLDR has French) | CC BY-SA 4.0 | SVG/PNG download | Optional emotions and emoji-style set. |
| **[Global Symbols](https://globalsymbols.com/api/docs)** | several sets | Multilingual search | Varies by set | Public API | Later: a second search provider. |
| **[OpenSymbols](https://www.opensymbols.org/api)** | aggregator | Some | Varies by set | API with shared-secret token | Later, optional. |
| PCS (Boardmaker / Tobii Dynavox) | large | Yes | **Proprietary** | Needs a licence | **Not usable.** Often seen in official PECS material. |
| **Your own photos** | n/a | n/a | Yours | Camera or Photos | **First-class.** Often the most effective option for reinforcers. |

**Recommendation.** Use **ARASAAC** as the main library. It has French keywords, a free API with no
key, it is widely used in French-speaking special education, and its style is consistent. It fits a
free or personal app.

Consequences of the ARASAAC licence:
- Show the attribution on a Credits screen and keep it in exported files. The text is "Les symboles pictographiques utilisés sont la propriété du Gouvernement d'Aragon et ont été créés par Sergio Palao pour ARASAAC (https://arasaac.org), qui les distribue sous licence Creative Commons BY-NC-SA."
- **NC**: the app (or at least the ARASAAC content) cannot be sold.
- **SA**: exported packs that contain ARASAAC-derived images keep the same licence. The export format records each image's source and licence.

**ARASAAC API (endpoints to confirm against [arasaac.org/developers/api](https://arasaac.org/developers/api) when implementing)**

```
GET https://api.arasaac.org/api/pictograms/fr/search/{texte}       # keyword search in French
GET https://api.arasaac.org/api/pictograms/fr/bestsearch/{texte}   # best / exact matches
GET https://api.arasaac.org/api/pictograms/fr/{id}                 # metadata (keywords, categories…)
GET https://api.arasaac.org/api/pictograms/{id}?resolution=500&color=true&plural=false&skin=…&hair=…
                                                                   # rendered PNG with options
GET https://static.arasaac.org/pictograms/{id}/{id}_500.png         # static PNG (300 / 500 / 2500)
```

Store the ARASAAC id and the options used with each pictogram. That makes it possible to download it
again at a higher resolution or with other options later.

**Starter pack.** Bundle about 150 ARASAAC pictograms with French labels so the app is useful offline
on first launch:
- critical cards: *aide, pause, non, oui, attends, fini, encore*
- starters: *je veux, je vois, j'entends, j'ai, c'est*
- common foods and drinks, toys and activities, family placeholders to replace with photos, body needs (*toilettes, dormir, mal*), emotions, colours, sizes

---

## 6. Speech (French)

- Use `AVSpeechSynthesizer` with a `fr-FR` voice. Let the parent choose from `AVSpeechSynthesisVoice.speechVoices()` filtered on French, and preview each voice.
  - Explain in the app how to download an **enhanced or premium** voice (Réglages ▸ Accessibilité ▸ Contenu énoncé ▸ Voix ▸ Français). They sound much better than the default voice.
  - Settings for rate and pitch.
- Keep **one long-lived synthesizer**. It stops speaking if it is deallocated. Pre-warm it at launch to avoid a delay on the first tap.
- Set the audio session to `.playback` so speech still plays when the silent switch is on. This is a common problem with AAC apps.
- What gets spoken, in priority order:
  1. the recorded audio clip, if any
  2. the spoken text, if set
  3. the label
- **Sentence playback**: play a queue of items, where each item is either a recording or a TTS utterance, one per card. The delegate callbacks drive the highlight on the card currently being spoken.
- **French grammar**: PECS accepts short "telegraphic" sentences ("Je veux pomme"). Putting the article in the spoken text ("une pomme") makes the sentence sound natural without adding a grammar engine. Automatic articles and agreement are a possible later feature.
- **Personal Voice** (iOS 17 and later): request authorisation, then list personal voices alongside the system voices.

---

## 7. Technical architecture

### 7.1 Stack

| Concern | Choice | Why |
|---|---|---|
| Language / UI | **Swift 6, SwiftUI** | One code base for iPad and iPhone, with native drag and drop and accessibility. |
| Minimum OS | **iOS / iPadOS 18** (check on your son's iPad) | Needed for SwiftData improvements, Vision subject lifting, and Personal Voice. |
| Persistence | **SwiftData** | Simple, works with SwiftUI, and can sync through CloudKit. |
| Sync | SwiftData + **CloudKit private database** | No server of our own, and data stays in the family's iCloud. |
| Speech | AVFoundation (`AVSpeechSynthesizer`, `AVAudioPlayer`, `AVAudioRecorder`) | Built into iOS. |
| Images | PhotosUI (`PhotosPicker`), camera (`UIImagePickerController` wrapper), Vision (background removal), Core Image (crop, resize) | Built into iOS. |
| Networking | `URLSession` with async/await | Only needed for symbol search. |
| Export | `ZIPFoundation` (Swift package) or Apple Archive | Pack format (§7.6). |
| Tests | Swift Testing, XCTest UI tests | |
| CI | GitHub Actions on a macOS runner (`xcodebuild test`) | |

Development needs a Mac with Xcode. Running on a real iPad and using TestFlight needs an Apple
Developer Program membership (99 €/year). A free account can run the app on your own device, but it
has to be re-signed every 7 days.

### 7.2 Project layout

```
MesPictos.xcodeproj
App/                        @main, scene setup, dependency wiring, deep links (file opening)
Features/
  Board/                    child mode: grid, page tabs, permanent bar, sentence strip
  Editor/                   parent mode: edit grid, drag & drop, pictogram editor, page settings
  SymbolSearch/             search UI over SymbolProvider(s)
  Settings/                 voice, presets, lock, sync, log, credits
  Onboarding/               first launch, Guided Access explanation, starter pack
Packages/PictoKit/          Swift package, UI-independent, unit-tested
  Model/                    SwiftData models + migrations
  Speech/                   SpeechService (TTS + recordings + sentence queue)
  Symbols/                  SymbolProvider protocol, ArasaacProvider, BundledProvider
  Transfer/                 pack export/import, OBF (later), print/PDF rendering
  Media/                    image normalisation, background removal
Resources/
  StarterPack/              bundled pictograms + manifest.json
  Localizable.xcstrings     French first, English second
```

### 7.3 Data model

Pictograms live in a **library**. A page holds **placements** that point to pictograms. With this split:
- moving a pictogram between pages only changes the placement
- the same pictogram (for example "Je veux" or "Aide") can appear in several places
- removing a pictogram from a page does not delete it

```swift
@Model final class Pictogram {
    var id: UUID = UUID()
    var label: String = ""                 // "pomme"
    var spokenText: String?                // "une pomme" (overrides label for speech)
    @Attribute(.externalStorage) var image: Data?        // normalised PNG, e.g. 512×512
    @Attribute(.externalStorage) var recording: Data?    // AAC .m4a, parent's voice
    var wordType: WordType = .noun         // for colour coding & starters
    var source: SymbolSource = .photo      // .photo, .arasaac(id), .mulberry(name), .imported
    var licence: String?                   // e.g. "CC BY-NC-SA – ARASAAC"
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \Placement.pictogram)
    var placements: [Placement]? = []
}

@Model final class Page {
    var id: UUID = UUID()
    var title: String = ""
    var sortIndex: Int = 0
    var columns: Int = 4
    var rows: Int = 3
    var isHidden: Bool = false
    var kind: PageKind = .normal           // .normal, .permanentBar, .starters
    @Relationship(deleteRule: .cascade, inverse: \Placement.page)
    var placements: [Placement]? = []
}

@Model final class Placement {
    var id: UUID = UUID()
    var slot: Int = 0                      // row * columns + column → stable position
    var isHidden: Bool = false             // hidden in child mode, kept in parent mode
    var linkedPageID: UUID?                // "folder" pictogram opening another page
    var page: Page?
    var pictogram: Pictogram?
}

enum WordType: String, Codable { case person, verb, noun, adjective, social, starter, other }
```

- **CloudKit constraints**, to respect from day one even before sync is on: no `@Attribute(.unique)`, every property optional or with a default value, every relationship optional.
- **Slots, not free positions.** Positions snap to a grid. This supports motor planning, works on both screen sizes, and makes swapping simple. Empty slots are allowed.
- **The sentence strip is state, not a model.** It is `[Pictogram.ID]` in an `@Observable` `SentenceStrip` object. If the communication log is on, spoken sentences are added to a `LogEntry` model.

### 7.4 Moving pictograms

- The dragged item is a `Transferable` struct holding the placement ID, exported under a custom UTType through `CodableRepresentation`. Each grid slot uses `.dropDestination(for:)`.
- Dropping on an empty slot moves the placement there. Dropping on a filled slot swaps the two. All of this is one SwiftData transaction, so it can be undone with `UndoManager`.
- **Page tabs are drop targets too.** When `isTargeted` stays true for about 0.6 s, the app switches to that page, the same "spring-loading" behaviour as in the Files app.
- On iPad, **images dragged in from other apps** (Safari, Photos, Files in Split View) onto an empty slot create a new pictogram.
- Build this first as a small prototype, because grid drag and drop in SwiftUI has edge cases (scrolling during a drag, drag previews, iPhone behaviour).

### 7.5 Symbol providers

```swift
protocol SymbolProvider: Sendable {
    var id: String { get }
    var displayName: String { get }
    var attribution: String { get }
    func search(_ query: String, language: String) async throws -> [SymbolHit]
    func image(for hit: SymbolHit, options: SymbolOptions) async throws -> Data
}
```

The first implementations are `ArasaacProvider` (network) and `BundledProvider` (starter pack, offline).
A provider for Global Symbols or Mulberry can be added without touching the UI. Search results are
cached in memory. Downloaded images are copied into the pictogram, so everything keeps working offline.

### 7.6 Import and export format

A **`.pictos`** file is a zip archive with its own exported UTType, for example `com.example.pictos.pack`
(replace with your own reverse-DNS identifier). It is registered in `CFBundleDocumentTypes` so that
tapping a file in Mail, Messages, or Files opens the app.

```
MesPictos-Manger.pictos
├── manifest.json        { "format": "pictos-pack", "version": 1, "app": "…", "createdAt": "…",
│                          "pictograms": [ { "id", "label", "spokenText", "wordType",
│                                            "source", "licence", "image": "images/<id>.png",
│                                            "recording": "audio/<id>.m4a" } ],
│                          "pages": [ { "id", "title", "columns", "rows",
│                                       "placements": [ { "slot", "pictogramID", "hidden" } ] } ] }
├── images/<uuid>.png
└── audio/<uuid>.m4a
```

- **Export scopes**: one or more pictograms, one or more pages (with their pictograms), or a full backup (everything plus settings).
- **Import**:
  1. Open a preview screen.
  2. Match items by `id` and handle conflicts: keep both, replace, or skip.
  3. Put pages that come without a destination into a new page or into the library.
- Plain image files (PNG, JPG, HEIC, SVG) can also be imported. Each file becomes a pictogram, with the file name as the label.
- The format is versioned, with a migration on import. `manifest.json` is plain JSON so other tools can read it.
- Later, add **Open Board Format** (.obf is JSON for one board, .obz is a zip of boards and images) as a second import and export target for interoperability.

---

## 8. Licensing, privacy, and safety

- **"PECS" is a registered trademark** of Pyramid Educational Consultants. Using it for a personal
  project is fine. For an App Store release, keep it out of the app name and describe the app as
  "inspired by PECS" or as a picture-communication or AAC app.
- **ARASAAC is non-commercial and share-alike** (§5). Keep the app free if it is published, and show the credits.
- **Privacy**:
  - Photos of the child, family, and home stay on the device and in the family's iCloud.
  - No third-party SDKs and no tracking. Network calls go only to the symbol APIs, and only from parent mode.
  - The communication log is off by default and stays on the device.
- If published in the **Kids category**, Apple adds requirements: no third-party analytics or ads, and a parental gate before external links or purchases. The design above already meets them.
- **Always keep a low-tech backup**: the printed binder. See the "print cards" feature.

---

## 9. Roadmap

Sizes are rough (S is a few days, M 1–2 weeks, L 2–4 weeks of evening or weekend work).

| Step | Content | Size |
|---|---|---|
| **0. Preparation** | Answer the open questions (§11). Get an Apple Developer account. Create the Xcode project, GitHub Actions CI, and README. Sketch the pages on paper and test the vocabulary with printed cards. Try PECS IV+, LetMeTalk, and CBoard for inspiration. | S |
| **1. MVP "tableau parlant"** | Models (§7.3). Child mode grid with tabs and French TTS. Parent mode with lock. Page CRUD and grid size. Pictogram editor with photo library, camera, crop, label, and spoken text. Move within and between pages (drag and menu). Hide and show. Basic settings (voice, rate, label style). | L |
| **2. Symbol library** | ARASAAC search and download, with attribution and credits. Bundled starter pack with critical cards and starters. Permanent bar. Photo background removal. | M |
| **3. Sharing and backup** | `.pictos` export and import (pictogram, pages, full backup) through AirDrop, Files, and Mail. Print cards to PDF. iCloud sync between iPhone and iPad. Automatic local backups. | M |
| **4. Sentence strip** | Strip, starters, reading with sequential highlight, reorder and clear. Phase presets. Attribute pages. Fitzgerald colour coding. | M |
| **5. Extras** | Voice recordings. Folder pictograms. Communication log with CSV export. Visual schedule and D'abord/Ensuite. Timer for Attends. OBF import/export. Several profiles. Personal Voice. | L |

Each step ends with a TestFlight build that you test with your son. If possible, also get feedback
from his orthophoniste or PECS consultant.

---

## 10. Testing strategy

- **Unit tests** (Swift Testing, in-memory SwiftData container):
  - move and swap logic, including between pages and into empty or filled slots
  - pack export and import round trip, conflict handling, format migration
  - speech priority (recording, then spoken text, then label) and sentence queue ordering
  - ARASAAC response decoding against recorded JSON fixtures, with no network in CI
- **UI tests** (XCUITest):
  - child mode cannot enter edit mode without the unlock gesture
  - tapping a pictogram triggers speech (through a fake `SpeechService`)
  - `performAccessibilityAudit()` on main screens
- **Manual checklist on a real iPad**:
  - silent switch on
  - Guided Access
  - airplane mode (offline)
  - rotation
  - fast repeated taps
  - large grids (5×4 and above)
  - low storage
- **Field testing**: short sessions with your son at each milestone. Watch which pictures he recognises, where he taps by mistake, and what distracts him.

---

## 11. Open questions (please answer before step 1)

1. **Current PECS level.** Which phase is your son working on, and does he already use a physical *classeur PECS*? This decides whether the sentence strip is needed early.
2. **Professionals.** Is an orthophoniste or PECS-trained consultant involved? Which symbols do they use (ARASAAC, PCS, photos)? The app should match what he already knows.
3. **Distribution.** Is this only for your family (TestFlight or direct install), or should it go on the App Store for free? This affects naming, the ARASAAC licence, and the Kids-category work.
4. **Devices.** Which iPad model and iOS version does he use? Will you edit from your own iPhone (which needs iCloud sync early), or only on the iPad?
5. **Development setup.** Do you have a Mac with Xcode? Which Swift and SwiftUI experience level should the code target?
6. **Voice.** A synthetic French voice, your own recorded voice, or both?

---

## 12. References

- [PECS France: what is PECS?](https://pecs-france.fr/picture-exchange-communication-system-pecs/)
- [Autisme Info Service: PECS](https://www.autismeinfoservice.fr/accompagner/travailler-enfants-autistes/pecs/). A description of the phases in French, including the *bande phrase* and "Je veux".
- [L'Aventure Autistique: Le PECS, un outil de communication visuelle](https://www.l-aventure-autistique.fr/le-pecs-un-outil-de-communication-visuelle-pour-les-enfants-autistes/)
- [PECS Implementation Program for children with ASD (PMC)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10546919/)
- [Pyramid: PECS IV+ app](https://pecsusa.com/pecs-iv-support/) and [Pyramid apps](https://pecsusa.com/apps/)
- [ARASAAC](https://arasaac.org), [ARASAAC API for developers](https://arasaac.org/developers/api), and [licence and attribution notes (PictoSearch)](https://github.com/kitsteam/pictosearch)
- [Mulberry Symbols](https://mulberrysymbols.org/) and [GitHub](https://github.com/mulberrysymbols/mulberry-symbols)
- [Global Symbols API](https://globalsymbols.com/api/docs), [OpenSymbols API](https://www.opensymbols.org/api), [Sclera on OpenSymbols](https://www.opensymbols.org/repositories/sclera), [OpenMoji](https://openmoji.org/)
- [Open Board Format](https://github.com/open-aac/openboardformat)
