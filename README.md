# Hess Coach

A trainer's operating app for in-person 1-on-1 clients: it holds the programming,
logs sets live during a session, tracks strength and body metrics automatically,
and generates a client-facing progress report every 8 weeks. One trainer user.
Clients never log in — they receive a report card by share link or PDF.

Built to the *Trainer App MVP Technical Spec*. Section numbers in code comments
refer to it.

- **Rails 8.1** serves the app and its API as one deployable.
- **Inertia + React 19** renders every trainer screen. No separate SPA, no REST
  layer to maintain for pages that only read.
- **Plain ERB** for login, password reset and the public report card, so the
  report prints cleanly to PDF and the public page ships no JS.

## Why this shape

The spec needs offline logging (`survives airplane mode mid-session`) on exactly
one screen. Everything else is online-only and read-heavy, which is Inertia's
sweet spot. So the session logger will be a client-routed, local-first island
backed by a thin `/api/v1` and IndexedDB; the other eight screens are ordinary
Inertia pages. Going full SPA would mean maintaining the whole section-8 REST
surface to gain nothing on eight of nine screens.

## Stack

| | |
|---|---|
| Ruby | 4.0.7 |
| Rails | 8.1.3.1 |
| Database | PostgreSQL 17, UUID primary keys |
| Frontend | React 19.3, TypeScript 7, Vite 8, Tailwind 4 |
| Bridge | Inertia Rails 3.22 / `@inertiajs/react` 3.7 |
| Tests | RSpec |

### Two deliberate deviations from the spec's names

- **`Session` is the training session**, per spec section 5. Rails 8's auth
  generator also wants that name, so the *login* session is `AuthSession`
  (`auth_sessions`). Domain vocabulary wins because the 27-table list is a
  checkable requirement.
- **`conditioning_method`**, not `method`, on template/session exercises.
  An ActiveRecord attribute called `method` would shadow `Object#method` and
  break Ruby introspection.

### One pin worth knowing about

Ruby 4.0 ships `json` 3.x, whose `JSON.parse` takes one argument. ActiveSupport
8.1 still calls it with two, which breaks the message encryptor and therefore
every encrypted cookie — login 500s. `Gemfile` pins `json ~> 2.21` until Rails
ships a json 3 compatible release. Remove the pin once it does.

## Running it

```bash
source env.sh          # project-scoped Ruby 4.0.7 via rvm; does not touch machine defaults
bundle install
npm install
bin/rails db:create db:migrate db:seed
bin/dev                # Rails on :3000, Vite on :3036
```

Seed account: `julian@hesscoach.test` / `password`. Override with `TRAINER_EMAIL`,
`TRAINER_PASSWORD`, `TRAINER_NAME`, `TRAINER_BUSINESS`, `TRAINER_TZ`.
Open signup is off by design (spec section 8) — the account comes from seeds.

```bash
bundle exec rspec
```

### Trying it on an iPhone

It is a web app, not a native build (spec section 2), so there is nothing to
install from an App Store. Put the phone on the same wifi as the Mac, then open
`http://<your-mac-lan-ip>:3000` in Safari. `ipconfig getifaddr en0` prints the
address. Share > Add to Home Screen installs it: the manifest gives it an icon
and launches it standalone, without Safari's chrome.

Rails binds `0.0.0.0` and proxies `/vite-dev/` to the Vite server, so the phone
only ever talks to port 3000.

One limit worth knowing: service workers need HTTPS or localhost, so **offline
will not work over plain LAN HTTP**. That is fine for phase 1, which has no
offline logger yet. Testing the offline queue in phase 4 will need a tunnel
(`cloudflared`, `ngrok`) or local certs (`mkcert`) to get real HTTPS.

## Where things are

```
app/models/                        27 domain tables + Trainer/AuthSession
app/controllers/                   InertiaController (React screens) | ApplicationController (plain ERB)
app/services/                      ExerciseLibraryImport, MetricPresenter
app/calculations/                  Ffmi, Units - pure functions, unit tested
app/frontend/pages/                One .tsx per Inertia screen
lib/seeds/lookups.rb               Patterns, muscle groups, phases, block presets, presentations (spec 7)
lib/seeds/exercise_types.rb        Type defaults: pattern, block, prescription, muscles (spec 7)
lib/seeds/metric_types.rb          33 metric types in Julian's three assessment groups (spec 7)
db/seeds/private/                  Julian's exercise_library.csv. Gitignored: client data.
```

## The exercise library

The library is Julian's own sheet, imported as-is — nothing in it is invented by
the build (EX-1). Put `exercise_library.csv` in `db/seeds/private/` with columns
`Exercise, Exercise Type, URL, Recorded, How to`, then `bin/rails db:seed`.
Re-running is additive: it adds new rows and refreshes video and how-to by
(name, type), and never deletes (EX-7).

**On a deployed server**, upload it instead: the CSV is gitignored, so it is not in
the repo the host builds from, and seeding there skips the library. Library >
*Import from CSV* takes the sheet exported as CSV (Google Sheets: File > Download >
Comma-separated values). It reads the sheet's own headers (`RECORDED?`, `How to:`)
as well as the spec's spelling, tolerates the byte order mark Excel writes, and
runs in one transaction, so a bad file leaves nothing half-imported. It rejects an
.xlsx and a file without an Exercise and Exercise Type column, with a message.

`/library/import-review` shows what the import changed and what looks
inconsistent. From Julian's current sheet: 301 exercises, 34 rows where a type
default was overridden per spec section 7, 16 where the sheet disagrees with
itself about whether a video exists, and 1 skipped (`Dynanometer` is the grip
strength test, not a programmed exercise). Power and Aerobic Output have no rows
in the sheet, so 16 starter exercises are seeded from the training model — 317
exercises in total.

## Build order

Phases from spec section 12. Each ends with something usable.

- [x] **1** Schema (27 tables), auth, seeded lookups, app shell, exercise library
      import with its exception review screen, Library screen
- [ ] **2** Clients, notes, metrics, assessment mode, FFMI
- [ ] **3** Workout builder, phase presets, templates
- [ ] **4** Session logging, readiness check, offline queue, PR detection
- [ ] **5** Analytics, benchmarks, goals, readiness trends
- [ ] **6** Report cards, PDF, email, export
- [ ] **7** Should-haves, only after two weeks of real use

## Units

Loads, masses and lengths are stored canonically (kilograms, centimetres) and
converted at the edges, the rule the spec sets for loads in section 2. A metric
type carries a `measure` of `mass`, `length` or null; null means the metric is
unit-agnostic (degrees, bpm, percent, reps, a 1-3 score) and is stored as typed.
So switching the display unit re-renders every past entry correctly instead of
reinterpreting stored numbers.

FFMI follows from this: it needs kilograms and metres regardless of what Julian
types, and is computed from a body fat entry plus the nearest body weight entry
within 7 days (spec 6.8). It is never entered by hand.

## Open questions for Julian

Progression order **is** real — Horizontal Push runs planks → hand-elevated
pushup → pushup → weighted pushup → barbell bench — so SL-4's swap panel is safe
to build on. Remaining:

- 187 of 317 exercises have no video and 132 have no how-to text. The library
  flags these rather than hiding them; the Library screen has a "needs video"
  filter.
- Three rows read `Meicine Ball` and two of those also read `Wall FacingMeicine`.
  Left exactly as written — the import never edits his names.
- Spec section 7 expects `Jefferson Curl` and `Standing Cat Cow` to each appear
  under two types. In this sheet only `Shinbox Getups` and `Rock and Rolls` do.
  Not a problem, but the spec's exception list was written from a different
  export.
- `Copenhagen Plank` is in the spec's override list but not in the sheet; only
  `Active Copenhagen` is present.
