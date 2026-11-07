---
colors:
  ground: { light: "#F4F1E8", dark: "#171613" }
  surface: { light: "#E9E5D8", dark: "#26241F" }
  ink: { light: "#25231E", dark: "#EDE8DC" }
  muted: { light: "#6A665B", dark: "#A9A496" }
  accent: { light: "#2E6A50", dark: "#5FAF8A" }
  on-accent: { light: "#FFFFFF", dark: "#171613" }
  danger: { light: "#A63A2E", dark: "#E8907F" }
  words-of-christ: { light: "#A63A2E", dark: "#E8907F" }
typography:
  family: Newsreader
  chapter: { size: 72, weight: 500 }
  display: { size: 36, weight: 500 }
  heading: { size: 20, weight: 500 }
  body: { size: 17, weight: 400 }
  label: { size: 17, weight: 500 }
  caption: { size: 14, weight: 400 }
rounded: { control: 8, button: 12 }
spacing: { unit: 4 }
---

# Gather Bible design system

## Overview

Friends around a table with a well-loved Bible. Character comes from print-inspired
type, warm tones, and plain human words, not from decoration. Scripture is the loudest
thing on the reader, and other people are always quietly present.

Surface mode: operate, with the reader in read mode. Density: 3 of 10.

Code: `Core/Design/AppColor.swift`, `AppFont.swift`, and `AppPrimaryButtonStyle.swift`.

## Colors

| Role | Use |
| --- | --- |
| ground | Screen background |
| surface | One tone step off ground, for grouped controls |
| ink | Primary text and icons |
| muted | Supporting text and quiet icons |
| accent | Actions, selection, and focus only. Keep it under 5% of a screen |
| on-accent | Content on an accent fill |
| danger | Errors and destructive actions, always with an icon or words |
| words-of-christ | Red-letter Scripture only |

Every pair above passes 4.5:1 in light and dark. Muted on surface is the tightest, at
4.55:1 in light.

`AccentColor` in the asset catalog must match the accent role.

## Typography

One family everywhere: Newsreader, licensed under the SIL Open Font License
(`Resources/Fonts/OFL.txt`). People can choose another reading font in Reader settings.
Use only the named styles in `AppFont`. Never use uppercase, except in data such as
translation abbreviations and session codes.

## Layout

Spacing is a multiple of 4. Body text sits at least 16pt from the screen edge. Touch
targets are at least 44pt. Separate surfaces with tone and space, not lines.

## Elevation

Only sheets and menus float. Resting elements have no shadow.

## Shapes

Controls use a radius of 8. Primary buttons use 12.

## Components

- **AppPrimaryButtonStyle**: the one primary action on a screen. Enabled, pressed, disabled.
- **AppSecondaryButtonStyle**: a supporting action on a surface tone. Uses danger for a destructive role.
- **AppQuietButtonStyle**: text only, for actions that should recede, such as ending a session.
- **appField()**: single-line text input on a surface tone.
- **appSheet() and appNavigationTitle()**: every sheet sits on ground with a Newsreader title.
- **InlineError**: the one error treatment. An icon and words in danger, with no box or border.
- **SessionCodeField**: six tiles over a real text field, so typing, paste, and VoiceOver work.
- **ReaderTopBar**: current book, translation, AirPlay, and reader settings. Solid ground, with a
  24pt fade so text leaves under it. This fade is functional, not decoration.
- **ChapterOpener**: the large chapter number, with who you're reading with beside it. The YouVersion
  SDK draws the verses, so a true wrapped drop cap isn't possible without replacing its renderer.
- **ChapterFooter**: chapter navigation at the end of the text.

Scripture runs edge to edge and scrolls under the tab bar. Never put a solid bar above the tab bar.

- **AppIconView**: the one icon set, Phosphor Light (MIT). Only icons from `AppIcon`. Prefer a word
  when a word is clearer, and don't add icons to buttons that already have text. No filled glyphs,
  crowns, or status dots.
- **EmptyState**: the one empty, unavailable, and retry state, in words.

## Do's and don'ts

- Do let type, tone, and space create hierarchy.
- Do write what a person would say out loud.
- Don't use glass, gradients, glows, emoji icons, or colored borders.
- Don't add a second accent color.
- Don't use the system blue, system grays, or raw colors in views.

## Responsive behavior

The reader's text column stops at 720pt on iPad, with wider side margins.

## Known gaps

- The tab bar shape, system alerts, and navigation controls such as Done are still system-drawn.
- The AirPlay icon comes from AVRoutePickerView and can't use the Phosphor set.
- The picker's selected segment is the system white, not a token.
- ExternalDisplay's TV view keeps its own always-dark look.
