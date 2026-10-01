# Mes Pictos

An iPad and iPhone app, inspired by PECS (Picture Exchange Communication System), that helps a
non-speaking or minimally-speaking autistic child communicate with pictograms spoken aloud in French.

The plan is in **[docs/PLAN.md](docs/PLAN.md)**. This is the first version (step 1 of the roadmap).

## What works in this version

- **Child mode.** Pages of large cards (1 to 4 by default). Tapping a card speaks it in French
  and brings it to the centre of the screen (**show mode**) so the child can show it to an adult.
  An adult closes it, and the card flies back to its place.
- **Permanent bar** with "Non" and "Aide", visible on every page.
- **Parent mode**: press the lock for 3 seconds (optionally followed by a code, Face ID, or Touch ID).
  - Create, rename, reorder, hide, and delete pages. Choose the grid size.
  - Create a card from a photo (library or camera), crop it, set its label and spoken text, and record your voice.
  - Move cards: drag onto another slot (cards swap), or onto a page tab. You can also long-press a card and use the
    menu: "Déplacer vers…", "Ajouter aussi sur…", "Masquer pour l'enfant", "Retirer de la page".
- **Settings**: French voice, speed and pitch, show mode (how it closes, auto-close, animation), label style
  (MAJUSCULES by default), ignoring repeated taps, and parent mode protection.
- **iCloud sync** between the iPad and an iPhone signed in to the same iCloud account.

## Build and run on the iPad

Requirements: a Mac with **Xcode 16 or later**, and **[XcodeGen](https://github.com/yonaskolb/XcodeGen)**,
which generates the Xcode project from `project.yml`.

1. **Install XcodeGen**

   ```sh
   brew install xcodegen
   ```

2. **Set your signing team and bundle identifier.** Create `Config/Signing.local.xcconfig`. It is not committed.

   ```
   DEVELOPMENT_TEAM = ABCDE12345
   APP_BUNDLE_ID = lu.yourname.mespictos
   ```

   The Team ID is in Xcode ▸ Settings ▸ Accounts, or on developer.apple.com ▸ Membership. The bundle identifier
   must be unique to you. The iCloud container is `iCloud.<APP_BUNDLE_ID>`. Xcode creates it the first time you
   build.

3. **Generate and open the project.** Run `xcodegen generate` again after each `git pull` that adds files.

   ```sh
   xcodegen generate
   open MesPictos.xcodeproj
   ```

4. **Run on the iPad:**
   1. Connect the iPad with a cable.
   2. Select it as the run destination in Xcode and press ▶.
   3. The first time, on the iPad, trust the developer in Réglages ▸ Général ▸ VPN et gestion de l'appareil.
   4. On iPadOS 18, turn on Developer Mode in Réglages ▸ Confidentialité et sécurité.

5. **For the iPhone**, do the same. Both devices must use the same iCloud account for sync.

### Free Apple account (no paid developer membership)

iCloud sync needs the paid Apple Developer Program. With a free account:
- Remove the `entitlements:` block for the `MesPictos` target in `project.yml`, then run `xcodegen generate` again. The app then stores its data on each device only.
- The app has to be re-installed from Xcode every 7 days.

## Tips for use with your child

- Turn on **Accès guidé** (Réglages ▸ Accessibilité ▸ Accès guidé). Then triple-click the side or home button inside
  Mes Pictos, so your child cannot leave the app.
- Start with **photos of his real things and of the cards in his binder**, with few cards per page.
- Replace the "Non" and "Aide" pictures with photos of the cards his speech therapist uses. Tap the card in parent mode, then "Choisir dans la photothèque" or "Prendre une photo".

## Project layout

```
project.yml                  XcodeGen project definition
Config/Signing.xcconfig      signing defaults (override in Signing.local.xcconfig)
MesPictos/
  App/                       app entry point
  Model/                     SwiftData models (CloudKit compatible) and PictoStore (all edits)
  Services/                  speech, voice recording, images, settings, device authentication
  Features/Board/            child mode, show mode, page tabs, grid, drag and drop
  Features/Editor/           pictogram editor, crop, camera, page settings
  Features/Settings/         settings screen
  Features/Onboarding/       first launch
  Features/Lock/             parent lock and code
MesPictosTests/              store tests (in-memory SwiftData)
Packages/PictoCore/          pure logic (grid moves and resize, speech priority, labels, crop math), with tests
```

## Tests

```sh
swift test --package-path Packages/PictoCore
xcodebuild test -project MesPictos.xcodeproj -scheme MesPictos -destination 'platform=iOS Simulator,name=iPad (10th generation)'
```

GitHub Actions runs both on every push (`.github/workflows/ci.yml`).

## Credits

Pictograms you add are your own photos. A later version will add the ARASAAC library (CC BY-NC-SA, Government of
Aragón, drawings by Sergio Palao).
