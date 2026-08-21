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
| L1 · Staying alive | D1–D2 | Aug 20–21 | Why does a watch app stop recording, and what does `HKWorkoutSession` change? | **GATE PASSED** · E1.0 ✔ E1.1 ✔ E1.2 ✔ · E1.3 next |
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
| 2 | Missing usage description crashes at authorisation time, not build time | **Confirmed** — tested deliberately, see the sabotage test below |
| 3 | `isHealthDataAvailable()` true on both devices | **Confirmed** on both |
| 4 | Authorisation sheet appears on the watch | **Confirmed** |
| 5 | `requestAuthorization` succeeds even when the user denies; `authorizationStatus` only meaningful for share types | **Confirmed** — tested by deliberate denial, see below |
| 6 | The day's time sink is provisioning and signing, not HealthKit | **Strongly confirmed** — three consecutive blockers, all account/provisioning, zero HealthKit |

**What I actually learned, beyond the score:** the mental model that needed correcting wasn't about HealthKit at all. It was that "get an app onto a watch" is a multi-stage negotiation with Apple's account infrastructure — licence agreement, device registration, profile generation — and each stage fails with an error naming a *different* layer than the one you are in. Prediction 6 was the cheapest prediction to make and turned out to be the most useful.

Prediction 5 is worth closing properly before L1 ends: deny a read permission deliberately and confirm the call still reports success. It is thirty seconds and it converts an inherited belief into a tested one.

### Amendment — prediction 5, tested by deliberate denial

**Method.** Turned Heart Rate **off** under Settings → Health → Data Access & Devices → HyroxCoach, leaving Workouts **on**. Relaunched the watch app with the previous instance terminated, then re-ran authorisation and E1.0b.

**Result.**

| Observation | Outcome |
|---|---|
| `requestAuthorization` after denial | Reported success. No error, no exception, no indication anything had been refused. |
| Heart rate query | **Zero samples.** No error raised — an empty set, identical in every observable way to "this device has no heart-rate data". |
| Workouts query | Still returned samples, as expected, since that permission was left on. |

**Prediction 5 is confirmed.** Read denial is genuinely invisible from inside the app: it produces neither an error nor a distinguishable signal, only an empty result.

**But a prediction made during this test was WRONG, and it is the more useful finding.**

I expected E1.0b's overall verdict to flip to INCONCLUSIVE once heart rate was denied. It stayed **CONFIRMED** — because the probe runs two queries and collapses them into a single aggregate verdict. Workouts still returned data, so the summary reported success while the heart-rate denial sat underneath it, invisible.

**So the probe built to catch over-claiming was itself over-claiming.** E1.0's original PASS hid the fact that it never tested read access; E1.0b's CONFIRMED hides the fact that one of its two queries returned nothing. Same error, one level up, committed while explicitly trying to avoid it.

**Design flaw, stated plainly:** an aggregate verdict over multiple independent checks masks any individual failure. A per-type verdict — heart rate CONFIRMED/INCONCLUSIVE, workouts CONFIRMED/INCONCLUSIVE, reported separately — carries the information the aggregate destroys.

**Fixed and verified on device, 2026-08-21.** `readForeignSamples()` now computes a verdict per type and an OVERALL line that is CONFIRMED only when every type returned data, MIXED when some did not, INCONCLUSIVE when none did. Re-run against the identical condition that fooled the old version — heart rate denied, workouts permitted — it now reports **MIXED**, where before it reported a clean CONFIRMED.

That re-run is the point: the fix was tested against the specific case that exposed the bug, not against a fresh one where it could have passed for the wrong reason. Same discipline the amendments above are about.

**Why this matters beyond E1.0.** This is the third instance in L1 of a result that reported success while the interesting failure hid inside it. It is the same shape as every row in the failure log: the signal surfaces at one level, the cause sits at another. The lesson for L4 is direct — "the sync worked" will be an aggregate over several things that can each fail independently, and a single green verdict there will hide exactly as much as this one did.

---

### Amendment — prediction 2, tested deliberately

**Method.** Removed `NSHealthShareUsageDescription` from the watch `Info.plist` with `plutil -remove`, rebuilt, installed to the watch, and tapped authorise. Restored afterwards with `git checkout`.

**Result — both halves of the prediction hold.**

| Claim | Outcome |
|---|---|
| The build still succeeds with the key missing | **Confirmed.** `BUILD SUCCEEDED`, no error, **no warning**. The bundle shipped without the key and nothing complained. |
| Authorisation crashes rather than returning a catchable error | **Confirmed.** Instant termination the moment authorise was tapped. No sheet, no error string, no `catch` block reached. |

**Why this matters more than it looks.** The `requestAuthorization` call sits inside a `do/catch` that logs failures — and that `catch` is useless here. The process is killed before it can run, so no amount of defensive Swift makes a missing plist key recoverable. The only defence is configuration being right in the first place.

**The diagnostic signature.** A HealthKit app that builds cleanly and dies instantly on the permission tap is almost certainly missing a usage description. Nothing in the build output, the crash timing, or the code points at the plist — it presents as a code bug in the authorisation path, which is where the time gets wasted looking.

This is the same symptom-versus-cause gap that runs through this cycle's failure log: the error surfaces in one layer, the cause sits in another.

---

### Amendment — E1.0b, added after the fact

**Why this was added.** Reviewing the E1.0 result exposed a flaw in what the PASS actually evidenced. The round trip wrote a sample and read back *the same sample it had just written* — and HealthKit always permits an app to read its own written data regardless of read authorisation. So `PASS: wrote and read back sample UUID …` proved **write access and self-read only**. It was not evidence of read access at all, despite reading like it was.

**The probe.** `readForeignSamples()` queries heart rate and workouts while excluding this app's own `HKSource`, so any result is data the app did not write. The outcome is deliberately asymmetric and the probe says so in its own output:
- non-empty → **CONFIRMED**, read access is real
- empty → **INCONCLUSIVE**, because HealthKit makes read-denied and no-data-present indistinguishable

**Result, 2026-08-20:** **CONFIRMED.** Foreign samples were read successfully, so read authorisation is genuinely granted — consistent with the iPhone's Health → Data Access screen, which showed all four read types enabled.

**What this changes about the E1.0 entry.** The original PASS stands, but it was over-claimed at the moment it was written: it evidenced less than it appeared to. Read access is now separately evidenced. Prediction 5 remains **half tested** — the deny path is still unexercised, and granting everything is exactly the condition under which the interesting half stays invisible.

**The transferable lesson, which is the actual finding here.** A test that passes is not automatically evidence of the thing you wanted to test. This one passed for a reason unrelated to the question being asked, and nothing in the green result would have revealed that. Worth carrying into L4, where "the data arrived" will be similarly tempting to read as "the transport is reliable" — when it may only mean the phone happened to be in range.

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

*Run 2026-08-21, Apple Watch Ultra 3 (watchOS 26.6). **Always-On Display: OFF.** App launched from the watch itself, no debugger attached.*

| Reading | Value |
|---|---|
| Ticks recorded | 20 |
| Elapsed **by counting ticks** | 20.0 s |
| Elapsed **from stored start `Date`** | 97.0 s |
| **Divergence** | **77.0 s** |
| Time from wrist-down to ticks stopping | ~8 s |

No crash. No error. No callback. The app simply stopped executing and later resumed as though nothing had happened.

**FIRST ATTEMPT WAS INVALID — recorded because the reason matters.** The initial run was made after installing from Xcode with the debugger still attached, and the ticks never stopped at all. An attached debugger prevents watchOS from suspending the process, so the experiment was measuring the debugger rather than the operating system. Re-run cleanly by stopping the Xcode session and launching from the watch itself.

**The gap**

All five predictions confirmed, one of them unusually precisely.

| # | Prediction | Outcome |
|---|---|---|
| 1 | App backgrounds as soon as the wrist drops | **Confirmed** |
| 2 | Logging stops within a few seconds, likely under 10 | **Confirmed** — ~8 s |
| 3 | Tick-counted elapsed is wrong; `Date`-computed elapsed is right | **Confirmed** — 20.0 s vs 97.0 s |
| 4 | No crash and no error; the failure is silent | **Confirmed** |
| 5 | `os_log` survives suspension, so the timestamp gap is the evidence | **Confirmed** |

**What the number actually means.** A tick-counted timer under-reports by exactly the duration the app was suspended. Here it lost 77 of 97 seconds — it saw **21%** of real time. This is not drift or imprecision; it is time the process did not exist for.

**Why this decides an architectural rule, not just a coding preference.** Every duration in a HYROX session — station times, roxzone transitions, total race time — must be computed from stored timestamps, never by accumulating ticks or incrementing a counter. A wrist-down during a sled push would silently subtract that entire period from the recorded station time, and nothing in the app would report an error. The number would simply be wrong, and plausibly wrong, which is worse.

**This is the baseline E1.2 is measured against.** E1.2 must be run under identical conditions — Always-On Display OFF, launched from the watch, no debugger — or the comparison means nothing.

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

**Actual result — GATE PASSED**

*Run 2026-08-21, ending ~09:44. Apple Watch Ultra 3 (watchOS 26.6). Always-On Display OFF, launched from the watch, no debugger. Same conditions as E1.1.*

| Reading | Value |
|---|---|
| Session state | `Workout running` / `Workout collection running` |
| Ticks recorded | 1,134 |
| Elapsed **by counting ticks** | 1,134.0 s |
| Elapsed **from stored start `Date`** | 1,149.0 s |
| **Divergence** | **15.0 s** |
| Heart rate, screen off | **84 bpm**, arriving live |
| Duration | ~19 minutes |

**Direct comparison against the E1.1 baseline, run under identical conditions:**

| | No session (E1.1) | Workout session (E1.2) |
|---|---|---|
| Real elapsed | 97.0 s | 1,149.0 s |
| Counted by ticks | 20.0 s | 1,134.0 s |
| Time lost | 77.0 s | 15.0 s |
| **Proportion lost** | **79.4 %** | **1.3 %** |

**The gap**

| # | Prediction | Outcome |
|---|---|---|
| 1 | Logging continues *uninterrupted* for the full duration | **Mostly confirmed, and usefully wrong in detail.** It continued, but not uninterrupted — 15 seconds of ticks were still lost. |
| 2 | Heart rate arrives via the live builder without the screen on | **Confirmed** — 84 bpm with the screen off |
| 3 | `activityType` does not affect whether the session stays alive | **Untested** — only `.crossTraining` was used |
| 4 | Battery drain noticeable but not prohibitive | **Untested** — not measured |
| 5 | Least confident: the app may be *not terminated* rather than *fully running*, with timers throttled | **Confirmed** — this is exactly what the 15 s shortfall shows |

**The headline answer to L1's question.** An `HKWorkoutSession` is what keeps the app executing while the wrist is down and the screen is off. Without it the app lost 79% of elapsed time; with it, 1.3%. That is the difference between an app that records a workout and one that merely appears to.

**The more interesting result is that 15 seconds, not the pass.** Prediction 5 — the one flagged as least confident — was right. A workout session prevents *suspension*; it does not guarantee a timer fires every second. The process stays alive while individual ticks are still coalesced or dropped.

So the architectural rule from E1.1 is not softened by this result, it is **reinforced**: durations must come from stored timestamps even *with* an active workout session. Tick-counting under a session is wrong by roughly 1.3% — about 15 seconds over 19 minutes. On a 4-minute sled push that is a 3-second error, silently, with no way to detect it from inside the app.

**Which is the same shape as everything else in this cycle.** "Workout running" is a green signal that means the session is alive. It does not mean every tick fired. Believing the stronger claim because the weaker one is true is precisely the error the rest of L1 documented.

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
| Aug 20 | `devicectl` install reported shell exit code 0 | Install succeeded | Install had **failed** (`IXRemoteErrorDomain error 6`); the exit code came from the shell, not the install. The old build was then launched instead | Read the actual output, not the exit status. Reinstalled from Xcode |
| Aug 21 | E1.1 ticks never stopped with the wrist down | watchOS is more permissive than predicted | The **debugger was attached** after installing from Xcode. A debug session prevents suspension, so the experiment measured the debugger, not the OS | Stop the Xcode session; launch from the watch itself |
| | | | | |

**Note on the first row:** this is exactly the class of failure L1 is about — the symptom pointed at one layer (no Xcode) and the cause was in another (toolchain selection). Worth keeping as the template for how rows in this table should read.

---

# PREDICTION SCORECARD

| Experiment | Prediction held? | Note |
|---|---|---|
| E1.0 | 6 of 6 confirmed | Round trip PASSED, but over-claimed — see E1.0b amendment. Prediction 6 (provisioning is the time sink) was the strongest hit. |
| P5 | Confirmed by denial test | Denial is invisible: no error, empty result. The side-prediction that E1.0b would flip to INCONCLUSIVE was WRONG — the aggregate verdict masked it. Probe since fixed and re-verified: reports MIXED on the same case. |
| P2 | Confirmed by sabotage test | Builds clean, crashes instantly on authorise. `catch` never runs. |
| E1.0b | CONFIRMED | Added after review found the round trip could not evidence read access. Read access now separately proven. |
| E1.1 | 5 of 5 confirmed | 20.0 s counted vs 97.0 s real — 77 s lost. First attempt invalid: debugger attached. |
| E1.2 | 2 confirmed, 1 refined, 2 untested | GATE PASSED. 1.3% lost vs 79.4% without a session. The 15 s shortfall confirms timers are still throttled. |
| E1.3 | | |
