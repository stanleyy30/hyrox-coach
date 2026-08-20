# C4 Predict–Test–Explain Workbook

**Owner:** Stanley Young
**Act phase:** Day 1 = 2026-08-20 → Day 10 = 2026-08-29
**Rule:** predictions are written BEFORE the experiment runs. Results after. Never edit a prediction once the test has run — a wrong prediction is the evidence, not a mistake.

> This is the single living workbook for C4. It is updated in place, never regenerated.

---

## How to use this

Each experiment has three fields:

| Field | When |
|---|---|
| **My prediction** | Before the test |
| **Actual result** | After the test |
| **The gap** | After the test |

Predictions are drafted before the experiment runs and are never edited afterwards. Revise them freely up until the moment you run the test — after that they are the record.

**The gap is the deliverable.** "Prediction correct" is a fine outcome but a cheap one. "Prediction wrong, and here is why my mental model was off" is the sentence that goes in the final evidence.

---

## Cycle map

| Cycle | Days | Dates | Learning question | Status |
|---|---|---|---|---|
| L1 · Staying alive | D1–D2 | Aug 20–21 | Why does a watch app stop recording, and what does `HKWorkoutSession` change? | ▶ E1.0 PASSED · E1.1 next |
| L2 · Recoverability | D3–D4 | Aug 22–23 | What has to be true for a workout to survive the app dying? | — |
| L3 · Ownership | D5 | Aug 24 | Which half of the record does HealthKit own, and which is mine? | — |
| L4 · Reliable transport | D6–D7 | Aug 25–26 | How does data survive an unreliable link between two devices? | — |
| L5 · Honest representation | D8–D9 | Aug 27–28 | What can this data honestly say, and what can it not? | — |
| L6 · Wrapper | D10 | Aug 29 | (no new work — presentation prep only) | — |

---

# CYCLE L1 · Staying alive — Days 1–2 (Aug 20–21)

**Learning question:** Why does a watch app stop recording, and what does `HKWorkoutSession` actually change?

**Gate:** if E1.2 has not passed by end of Day 2, cut to the floor scope and record why. That is a finding, not a failure.

---

## E1.0 — Foundation: can I even talk to HealthKit on real hardware?

*Run: Day 1*

**Scaffold status (Day 1, 09:20):** project generated and verified. `HyroxCoach.xcodeproj` built by XcodeGen from `project.yml`. Both targets carry the HealthKit entitlement, both Info.plists carry the usage descriptions, watch app is a modern single-target `WKApplication` embedded in the iOS app. Verified by `plutil -lint` and by reading the generated pbxproj. **Not yet built or run** — blocked on the `xcode-select` fix below.

**My prediction**

1. Both targets need the HealthKit capability added separately. Adding it to the iOS target alone will not enable it on the watch.
2. `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` are required. Missing either causes a **crash at authorisation time**, not a build error — so it will look like a runtime bug, not a config mistake.
3. `HKHealthStore.isHealthDataAvailable()` returns `true` on both the watch and the iPhone.
4. The authorisation sheet appears **on the watch** when requested from the watch app.
5. `requestAuthorization` succeeds even if the user denies — it reports that the *request completed*, not that permission was granted. Checking `authorizationStatus` for a read type will NOT reliably tell me whether read access was granted (Apple deliberately hides read denial to prevent inference).
6. Most likely time sink today: provisioning and signing across two targets, not HealthKit itself.

**Actual result**

*Run 2026-08-20, ~11:03, Apple Watch Ultra 3 (watchOS 26.6), iPhone 16 Pro Max (iOS 26.6.1), Xcode 26.6.*

- **PASS.** Round trip succeeded: wrote 1 kcal `activeEnergyBurned`, read it back, sample UUID `1F3508E0-D277-4395-BF3F-911E95CDE0DA`.
- Authorisation reported: *"Request completed; workout share status: sharing authorized"*.
- The authorisation sheet appeared **on the watch**.
- `isHealthDataAvailable()` returned true on the iPhone (confirmed on the iOS screen) and the watch round trip proves it on the watch.
- Getting to this point took **three separate provisioning obstacles**, none of them HealthKit: an unaccepted Program License Agreement, devices not connected/trusted, then devices not registered to the team. No HealthKit code executed until all three were cleared.

**The gap**

Four of six predictions confirmed. Two were **not tested** — which is different from being right, and is recorded as untested rather than quietly counted as a win.

| # | Prediction | Outcome |
|---|---|---|
| 1 | HealthKit capability needed on both targets separately | **Confirmed** — set in `project.yml` for both; the generated project carries it twice |
| 2 | Missing usage description crashes at authorisation time, not build time | **Not tested** — both plists had the descriptions from the start, so the failure mode never fired |
| 3 | `isHealthDataAvailable()` true on both devices | **Confirmed** on both |
| 4 | Authorisation sheet appears on the watch | **Confirmed** |
| 5 | `requestAuthorization` succeeds even when the user denies; `authorizationStatus` only meaningful for share types | **Half tested** — the share type reported `sharing authorized`, consistent with the claim, but nothing was denied, so the interesting half is unverified |
| 6 | The day's time sink is provisioning and signing, not HealthKit | **Strongly confirmed** — three consecutive blockers, all account/provisioning, zero HealthKit |

**What I actually learned, beyond the score:** the mental model that needed correcting wasn't about HealthKit at all. It was that "get an app onto a watch" is a multi-stage negotiation with Apple's account infrastructure — licence agreement, device registration, profile generation — and each stage fails with an error naming a *different* layer than the one you are in. Prediction 6 was the cheapest prediction to make and turned out to be the most useful.

Prediction 5 is worth closing properly before L1 ends: deny a read permission deliberately and confirm the call still reports success. It is thirty seconds and it converts an inherited belief into a tested one.

---

## E1.1 — Baseline: what happens WITHOUT a workout session?

*Run: Day 1 (if E1.0 clears) or Day 2*

Setup: a watch app with a repeating timer logging via `os_log` every second. No `HKWorkoutSession`. Start it, lower your wrist, wait 3 minutes, raise it.

**My prediction**

1. The app moves to the background as soon as the wrist drops and the screen turns off.
2. Logging **stops** within a few seconds of backgrounding — likely under 10 seconds, possibly immediately.
3. On raising the wrist, the app resumes, and the timer's elapsed value will be **wrong** if computed by counting ticks, but **right** if computed from a stored start `Date`. This distinction matters more than it looks.
4. There will be no crash and no error. The failure is silent — which is precisely why this is the trap.
5. `os_log` output survives the suspension and is retrievable in Console afterwards, so the gap in the timestamps is itself the evidence.

**Actual result**

<!-- -->

**The gap**

<!-- -->

---

## E1.2 — The real test: WITH an active `HKWorkoutSession`

*Run: Day 2* · **This is the gate.**

Setup: same app, but start an `HKWorkoutSession` + `HKLiveWorkoutBuilder` first. Wrist down, screen off, 15 minutes minimum (a full shortened protocol).

**My prediction**

1. Logging continues uninterrupted for the entire 15 minutes with the wrist down.
2. Heart rate samples arrive via the live builder without the screen being on.
3. The `activityType` I choose (`.crossTraining`, `.functionalStrengthTraining` or `.highIntensityIntervalTraining`) has **no effect** on whether the session stays alive — it only affects categorisation and energy estimation. HYROX has no dedicated type, so this is an approximation I will have to justify.
4. Battery drain will be noticeable but not prohibitive over 15 minutes.
5. Risk I am least sure about: whether the app is fully *running* or merely *not terminated*. It may be that timers still fire but UI updates are throttled. If so, anything I compute from tick counting is unreliable and I must compute from timestamps instead.

**Actual result**

<!-- -->

**The gap**

<!-- -->

---

## E1.3 — Does `recoverActiveWorkoutSession` do what the docs say?

*Run: Day 2*

Setup: start a session, force-quit the watch app, relaunch, call `HKHealthStore.recoverActiveWorkoutSession(completion:)`.

**My prediction**

1. It returns the still-running session rather than nil, and `session.associatedWorkoutBuilder()` gets me back to the builder with samples collected during the gap intact.
2. HealthKit's half survives. **My half does not** — current station, segment times and logged transitions are gone unless I persisted them, which is the whole reason L2 exists.
3. The recovered session's `startDate` is the original start, not the relaunch time.
4. Lowest-confidence prediction in this cycle. Recovery semantics have shifted across watchOS releases and I have not verified this on Stanley's version. If it behaves differently, L2's design changes and that is worth knowing on Day 2 rather than Day 7.

**Actual result**

<!-- -->

**The gap**

<!-- -->

---

# CYCLE L2 · Recoverability — Days 3–4 (Aug 22–23)

**Learning question:** What has to be true for a workout to survive the app dying?

Experiments to be defined at the start of L2. Provisional:
- E2.1 — State machine v1 on paper: which states, which transitions, which awkward paths?
- E2.2 — Persist on every transition; kill the app mid-station; what is missing on relaunch?
- E2.3 — Reconcile recovered HealthKit session with recovered semantic state.

---

# CYCLE L3 · Ownership — Day 5 (Aug 24) · MIDPOINT

**Learning question:** Which half of the record does HealthKit own, and which is mine?

Provisional:
- E3.1 — Save a workout on the watch. Does it reach the iPhone with none of my code involved?
- E3.2 — What survives the crossing, and what is lost? Produces the ownership table.

---

# CYCLE L4 · Reliable transport — Days 6–7 (Aug 25–26)

**Learning question:** How does data survive an unreliable link between two devices?

Provisional:
- E4.1 — All four `WCSession` methods against the same offline scenario. Predictions recorded first, per method. Produces the transfer-mode matrix.
- E4.2 — Duplicate delivery: does the same payload arrive twice, and do stable IDs prevent duplicates?
- E4.3 — Write the ADR: ownership rules, merge policy, rejected options.

---

# CYCLE L5 · Honest representation — Days 8–9 (Aug 27–28)

**Learning question:** What can this data honestly say, and what can it not?

Provisional:
- E5.1 — Real training session captured on device.
- E5.2 — For every number on the review screen, write the fact-vs-interpretation line.
- E5.3 — Design token change propagates to both targets.

---

# CYCLE L6 · Wrapper — Day 10 (Aug 29)

No new work. Presentation prep, evidence assembly, rehearsal.

---

# RUNNING FAILURE LOG

Every bug, with the symptom, the layer it *appeared* to be in, and the layer the cause was *actually* in. The mismatches are the most valuable rows.

| Date | Symptom | Looked like | Actually was | Fix |
|---|---|---|---|---|
| Aug 20 | `xcodebuild` refuses to run; no iOS/watchOS SDKs listed | Xcode not installed | Xcode IS installed at /Applications/Xcode.app, but `xcode-select` pointed at the Command Line Tools instance instead | `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` |
| Aug 20 | "No profiles for 'com.stanleyyoung.HyroxCoach.watchkitapp' were found" | Bundle ID or signing config wrong | Program License Agreement was unaccepted on the developer account, so the team could not issue any profile at all | Accept the updated PLA at developer.apple.com/account |
| Aug 20 | Same "no profiles" error, after the PLA was accepted | Still a signing config problem | Team had **no registered devices**; a development profile must name specific devices | Connect and trust iPhone, register both devices with the team |
| Aug 20 | "Your team has no devices" even with both devices connected | Devices not detected by the Mac | They *were* detected — but `generic/platform=watchOS` names no specific device, so there was nothing concrete to register | Build against `platform=watchOS,id=<device-id>` instead of the generic destination |
| | | | | |

**Note on the first row:** this is exactly the class of failure L1 is about — the symptom pointed at one layer (no Xcode) and the cause was in another (toolchain selection). Worth keeping as the template for how rows in this table should read.

---

# PREDICTION SCORECARD

| Experiment | Prediction held? | Note |
|---|---|---|
| E1.0 | 4 confirmed, 1 half-tested, 1 untested | Round trip PASSED. Prediction 6 (provisioning is the time sink) was the strongest hit. |
| E1.1 | | |
| E1.2 | | |
| E1.3 | | |
