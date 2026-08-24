# C4 Predict–Test–Explain Workbook

**Owner:** Stanley Young
**Act phase:** Day 1 = 2026-08-20 → Day 10 = 2026-09-04. Ten **working** days: Aug 20, 21, 24, 25, 27, 28, 31, Sep 1, 3, 4.
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
| L1 · Staying alive | D1–D2 | **Aug 20–21** | Why does a watch app stop recording, and what does `HKWorkoutSession` change? | **COMPLETE** · E1.0 ✔ E1.1 ✔ E1.2 ✔ E1.3 ✔ · gate passed Day 2 · E1.3 raises an open question for L2 |
| L2 · Recoverability | D3–D4 | **Aug 24–25** | What has to be true for a workout to survive the app dying? | ▶ **IN PROGRESS** · E2.0 falsified · E2.0b SOLVED the endpoint mystery · launch path settled · E2.1 next |
| L3 · Ownership | D5–D6 | **Aug 27–28** | Which half of the record does HealthKit own, and which is mine? | — |
| L4 · Reliable transport | D7–D8 | **Aug 31 – Sep 1** | How does data survive an unreliable link between two devices? | — |
| L5 · Honest representation | D9–D10 | **Sep 3–4** | What can this data honestly say, and what can it not? | — |

**Re-baselined 2026-08-24 against the project Gantt.** The ten Act days are **working days, not consecutive calendar days**: Aug 20, 21, 24, 25, 27, 28, 31, Sep 1, 3, 4. Weekends and the intervening gap days are not Act days.

**This means the project is ON SCHEDULE, not behind.** An earlier note in this workbook assumed consecutive days and concluded L2 was running two days late. That was wrong: 24 August is Day 3, the first day of L2, exactly as planned.

**Cycle L6 has been dropped.** The Gantt carries five cycles, not six. Presentation preparation now sits inside L5 or after Act ends on 4 September, rather than consuming a numbered day of its own.

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

Session state throughout: `Workout running` / `Workout collection running`. Heart rate **84 bpm**, arriving live with the screen off.

**Two readings were taken, which turned out to matter more than one.**

| | Reading A (09:43) | Reading B (09:51, final) |
|---|---|---|
| Ticks recorded | 1,134 | 1,610 |
| Elapsed **by counting ticks** | 1,134.0 s | 1,610.0 s |
| Elapsed **from stored `Date`** | 1,149.0 s | 1,630.0 s |
| **Divergence** | **15.0 s** | **20.0 s** |
| Loss as a proportion | 1.31 % | 1.23 % |
| Duration | ~19 min | ~27 min |

Between the two readings, 481 s of real time passed and 476 ticks were recorded — 5 s lost in that window, about 1.04 %.

**Direct comparison against the E1.1 baseline, run under identical conditions:**

| | No session (E1.1) | Workout session (E1.2, final) |
|---|---|---|
| Real elapsed | 97.0 s | 1,630.0 s |
| Counted by ticks | 20.0 s | 1,610.0 s |
| Time lost | 77.0 s | 20.0 s |
| **Proportion lost** | **79.4 %** | **1.23 %** |

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

So the architectural rule from E1.1 is not softened by this result, it is **reinforced**: durations must come from stored timestamps even *with* an active workout session.

**The second reading is what makes this conclusive.** A single measurement could have been dismissed as a start-up artifact — some cost paid once while the session spun up, then negligible. It is not. Loss held at 1.31 % after 19 minutes and 1.23 % after 27, with 1.04 % across the window between them. **The drift is steady and proportional to elapsed time, not a fixed one-off cost.**

That converts an observation into an extrapolation. At ~1.2 %, a full HYROX race of roughly 90 minutes would lose about **65 seconds** to tick-counting — comfortably enough to misreport a station, a transition, and the total. On a 4-minute sled push it is a ~3-second error. Silent, plausible, and undetectable from inside the app.

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

**Actual result — RECOVERED SUCCESSFULLY (second attempt)**

*Run 2026-08-21, 10:21. Apple Watch Ultra 3 (watchOS 26.6). Session started 10:19:35, force-quit via Side button + Digital Crown, relaunched, recovery attempted as the first action.*

```
Recovered state running; start 21 Aug 2026 at 10.19.35;
associated builder: yes
```

| Reading | Value |
|---|---|
| Session returned | Yes, state `running` |
| `associatedWorkoutBuilder()` | Yes |
| Recovered `startDate` | **10:19:35** — the original start |
| Time of recovery | ~10:21, roughly 90 s later |

**FIRST ATTEMPT FAILED — and the reason is itself a design constraint.**

At 10:14 recovery threw:

```
Task server endpoint for '43DFBD17-…-14D9DA5FA508' already exists
(for instance 'E8AB3AF1-F0AC-4632-B29E-9D72CC693B96')
```

Cause: the E1.2 workout was **still running** and its session manager still held a live `HKWorkoutSession`. Recovery was called while an instance already existed, and the framework correctly refused to issue a second one. The test was malformed, not the API.

**The gap**

| # | Prediction | Outcome |
|---|---|---|
| 1 | Returns the still-running session; `associatedWorkoutBuilder()` gets back to the builder | **Confirmed** — state `running`, builder present |
| 2 | HealthKit's half survives; my semantic half does not | **First half confirmed. Second half not yet testable** — there is no semantic state to lose, because no state machine exists until L2. Recorded as untested rather than assumed. |
| 3 | The recovered `startDate` is the original start, not the relaunch time | **Confirmed** — 10:19:35, roughly 90 s before recovery |
| 4 | Lowest-confidence prediction; recovery semantics may differ on this watchOS version | **Resolved.** Recovery behaves as documented *when called correctly*. The uncertainty was warranted, but the risk turned out to sit in the calling sequence rather than the API. |

**The real finding is the constraint the failed attempt exposed.** Recovery cannot be called while the process already holds a session object for that workout. It must be **the first thing a relaunched app does**, before any screen, view model or manager instantiates a session. Touch E1.2's screen first and you re-register an endpoint and reproduce the failure — for the correct reason, which is what makes it dangerous.

**Direct consequence for L2.** Recovery is not a repair step you reach for after noticing something is wrong; it is a launch-path decision made before normal startup runs. Combined with prediction 2 — HealthKit restores its own record while the semantic layer does not — L2's design follows: persist semantic state on every transition, and on launch attempt recovery *first*, then rehydrate the semantic layer alongside whatever HealthKit hands back.

**Prediction 3 matters more than it looks.** Given that E1.1 and E1.2 established every duration must be computed from stored timestamps rather than counters, the recovered `startDate` is the field all of those computations hang from. It surviving a force-quit intact is what makes recovery useful rather than merely possible.

---

### Amendment — E1.3 is reproducible, and the earlier conclusion was too simple

**Reported behaviour, reproducible across attempts:**

| Sequence | Result |
|---|---|
| Start workout → force-quit → relaunch → attempt recovery | **"Recovery failed"** — endpoint already exists |
| Then end the workout → attempt recovery | **"No active workout session was available to recover"** |
| Then attempt recovery **again** | **"Recovered state running"** |

**The probe code was audited and is not the cause.** `RecoveryProbe.attemptRecovery()` sets `latestResult` on every branch — success, nil, and error — and each tap issues a fresh `recoverActiveWorkoutSession` call. There is no cached or stale result. The three outcomes are the framework's, not the app's.

**What this establishes (recorded fact):**

1. Recovery immediately after a force-quit **reliably fails** while a workout is active, with an endpoint-already-exists error.
2. After the workout is ended, recovery reports **no session available**.
3. A subsequent attempt then returns a **running session with the original `startDate`**.

**What this suggested at the time (hypothesis — since FALSIFIED by E2.0 on 2026-08-24):** an app holding an active `HKWorkoutSession` is not really terminated by a force-quit — the system keeps or relaunches an instance to sustain the session, so its endpoint is still registered when the user reopens the app. **E2.0 showed the app stays dead. This explanation is wrong. The cause was later identified by E2.0b: the conflict occurs whenever the process already holds a live `HKWorkoutSession` object — in E1.3's case, E1.2's still-running workout in the same process.** Ending the workout releases the endpoint held by *this* process's session object, after which recovery can return the session that is still running at system level. That would explain all three states and the preserved start time, but the mechanism has **not** been proven here.

**How this changes the earlier conclusion.** The original entry recorded recovery as working, with the failed first attempt written off as a malformed test. That was true but incomplete. The failure is not a one-off procedural slip — it is the **reliable** outcome of the exact scenario L2 must handle: the app dying mid-workout. Recovery succeeded only after an intervening end-workout, which is not something a crashed app gets to do.

**Consequence for L2, and it is a significant one.** "Force-quit the app and recover the session" cannot be assumed to work as a straight sequence. Before designing persist-on-transition, L2 must first establish what genuinely happens to a watch app that dies mid-workout — whether the system resurrects it, and what state the process comes back in. The recovery path may need to tolerate an endpoint conflict on launch and retry, rather than calling recovery once and trusting the result.

**Status: recovery is confirmed possible, but the launch-path design is now an open question for L2 rather than a settled one.**

---

# CYCLE L1 · RESULTS SUMMARY

**Status: COMPLETE.** Gate passed on Day 2 (2026-08-21), on schedule.

**Conditions for every measurement below** — Apple Watch Ultra 3 (watchOS 26.6), iPhone 16 Pro Max (iOS 26.6.1), Xcode 26.6. Always-On Display **OFF**, app launched **from the watch**, **no debugger attached**. E1.1 and E1.2 are directly comparable because both were run this way; any result taken under different conditions is marked where it appears.

---

## The question, and the answer

> Why does a watch app stop recording, and what does `HKWorkoutSession` actually change?

**Answer.** Without a workout session, watchOS suspends the app within about 8 seconds of the wrist dropping, and it loses 79% of elapsed time while reporting no error of any kind. With an active `HKWorkoutSession` the app keeps executing and loses about 1.2%. The session is what buys background execution — but it buys *survival of the process*, not *reliable execution of every timer*.

---

## Results by experiment

| Experiment | Question | Result |
|---|---|---|
| **E1.0** | Can the app reach HealthKit on real hardware? | **PASS** — authorised on the watch; wrote 1 kcal and read it back, sample `1F3508E0-D277-4395-BF3F-911E95CDE0DA` |
| **E1.0b** | Was *read* access actually granted? | **CONFIRMED** — foreign-source samples read. Added because E1.0's pass could not evidence read access |
| **P2** (sabotage) | Does a missing usage description fail the build or crash at runtime? | **Crash.** Build succeeded with no error or warning; instant termination on tapping authorise, before any `catch` |
| **P5** (denial) | Is a denied read permission detectable from inside the app? | **No.** Authorisation still reported success; the query returned an empty set with no error |
| **E1.1** | What happens with **no** workout session? | Ticks stopped ~8 s after wrist-down. **20 ticks / 20.0 s counted vs 97.0 s real — 77.0 s lost (79.4%)** |
| **E1.2** | What happens **with** an active session? | **GATE PASSED.** Two readings: 1,134 ticks / 1,149.0 s (15.0 s lost, 1.31%) and 1,610 ticks / 1,630.0 s (20.0 s lost, 1.23%). Heart rate 84 bpm live with the screen off |
| **E1.3** | Does `recoverActiveWorkoutSession` work? | **Possible, but the launch path is an OPEN QUESTION.** Recovery after force-quit *reliably fails* while a workout is active. Success required an intervening end-workout, which a crashed app cannot perform |

---

## The headline measurement

| | No session (E1.1) | Workout session (E1.2, final) |
|---|---|---|
| Real elapsed | 97.0 s | 1,630.0 s |
| Counted by ticks | 20.0 s | 1,610.0 s |
| Time lost | 77.0 s | 20.0 s |
| **Proportion lost** | **79.4 %** | **1.23 %** |

Two E1.2 readings taken 481 s apart lost 5.0 s between them (1.04%), so the shortfall is **proportional to elapsed time, not a one-off start-up cost**. Extrapolated, a ~90-minute HYROX race would lose roughly **65 seconds** to tick-counting.

---

## Prediction tally

| Experiment | Confirmed | Wrong | Untested |
|---|---|---|---|
| E1.0 (6 predictions) | 6 | 0 | 0 |
| E1.0b + side-prediction | 1 | **1** | 0 |
| E1.1 (5 predictions) | 5 | 0 | 0 |
| E1.2 (5 predictions) | 2 confirmed, 1 refined | 0 | 2 |
| E1.3 (4 predictions) | 2, 1 resolved | 0 | 1 |

**Untested and honestly marked, not counted as wins:**
- E1.2 · whether `activityType` affects staying alive — only `.crossTraining` was used
- E1.2 · battery drain — never measured
- E1.3 · whether semantic state is lost on recovery — **untestable until L2 exists**, since there is no semantic state to lose yet

**The one wrong prediction was the most useful.** Expecting E1.0b to report INCONCLUSIVE after denying heart rate exposed that the probe aggregated two independent queries into a single verdict, hiding an individual failure. Fixed to report per-type verdicts, and re-verified against the same case.

---

## Architectural rules this cycle established

These are the durable output of L1 — decisions now backed by measurement rather than assumption.

1. **Every duration must be computed from stored timestamps, never from accumulated ticks or counters.** Holds even with an active workout session, where tick-counting is still wrong by ~1.2%. On a 4-minute sled push that is a ~3-second silent error.
2. **An `HKWorkoutSession` must be running for any live capture.** Without it there is no recording, and no error to tell you so.
3. **Configuration correctness is not defensible in code.** A missing Info.plist usage description kills the process before any error handler runs.
4. **Read permission state cannot be inferred from inside the app.** An empty result is indistinguishable from a denial. Anything built on "we got no data" must treat that as ambiguous.
5. **Verification must be per-check, never aggregated.** A single verdict over independent checks hides individual failures.
6. **The recovered `startDate` survives and is the anchor for every derived duration** — which is what makes recovery worth having at all.

---

## The pattern that ran through the whole cycle

Six times, a success signal at one level concealed a failure at another:

| Green signal | What it hid |
|---|---|
| Round trip `PASS` | Read access was never tested |
| `BUILD SUCCEEDED` | A fatal missing configuration key |
| Authorisation `success` | Read access had been denied |
| Probe `CONFIRMED` | One of its two checks returned nothing |
| Install exit code `0` | The install had actually failed |
| E1.1 ticks continuing | A debugger was holding the app alive |

A seventh belongs to the record-keeping rather than the tooling: E1.3's first failure was written up as a one-off malformed test, and only proved reproducible because the sequence was repeated rather than accepted.

**This was not L1's subject. It is L1's most transferable finding**, and the direct warning for L4, where "the sync worked" will be an aggregate over transfer, delivery, duplicate handling and deduplication — each able to fail independently, with no sample identifier on screen to make it obvious.

---

## Open questions carried into L2

1. **What actually happens to a watch app that dies mid-workout?** Does the system resurrect it to sustain the session? What state does the process return in? This must be answered before persistence is designed, not after.
2. **Can recovery be called reliably on launch**, or must the launch path tolerate an endpoint conflict and retry?
3. Does `activityType` affect session longevity? (Untested; low priority.)
4. What is the battery cost of a long session? (Untested; matters for a 90-minute race.)

---

# CYCLE L2 · Recoverability — Days 3–4 (Aug 24–25)

**Learning question:** What has to be true for a workout to survive the app dying?

**Opened 2026-08-21. All predictions below were written before any L2 code was created.**

**L1 changed this cycle's shape.** The plan was to design persist-on-transition and call recovery on launch. E1.3 showed recovery *reliably fails* in the crash-like case, so a prior question has to be answered first: what actually happens to a watch app that dies mid-workout? E2.0 exists to answer that, and everything after it depends on the answer.

---

## E2.0 — What actually happens when the app dies mid-workout?

*This is the question E1.3 left open. It must be answered before persistence is designed.*

Setup: start a workout session, kill the app several ways — force-quit gesture, and a deliberate crash (`fatalError`) — then observe. Does the process come back? When? In what state? Is an endpoint already registered when the user reopens it?

**My prediction**

1. **Force-quit does not really kill it.** An app holding an active `HKWorkoutSession` is relaunched by the system in the background to sustain the session. This is the hypothesis that explains E1.3's three-state sequence, and it is the single most important thing to confirm or kill.
2. Because of #1, by the time the user reopens the app, an instance already exists and its endpoint is registered — which is why recovery reports "already exists" rather than handing the session back.
3. **A deliberate crash may behave differently from a force-quit.** A force-quit is a user gesture the system may treat as "keep the workout"; a crash is a fault. If they differ, the crash case is the one that matters, since it is what actually happens in the field.
4. `recoverActiveWorkoutSession` will therefore need to tolerate the conflict — either by retrying, or by detecting that the process already holds a session and using that instead of recovering.
5. **Lowest confidence in this cycle.** All of the above is inference from one reproducible symptom, not from documentation. I expect at least one of these to be wrong.

**Actual result — PREDICTION 1 FALSIFIED**

*Run 2026-08-24, Apple Watch Ultra 3. App installed with **no debugger attached**, launched from the watch. **A workout session was confirmed running at the moment of the crash.***

| Reading | Value |
|---|---|
| Launch 1 (opened by hand) | 08:57:22 |
| Deliberate crash | 08:58:14 — 52 s into the session |
| Launch 2 | 09:00:15 |
| First launch after crash | **2 m 0 s** |
| Total launches | **2** |
| Latest launch followed a crash | YES |

**The system did NOT relaunch the app.** Two launches, both performed by hand — the first to start, the second after deliberately waiting two minutes. The gap of exactly 2 m 0 s matches the wait, not an autonomous restart. Had watchOS resurrected the process to sustain the workout, a third launch would have appeared within seconds of the crash. None did.

**The gap**

| # | Prediction | Outcome |
|---|---|---|
| 1 | Force-quit/crash does not really kill it; the system relaunches the app to sustain the session | **WRONG.** The app stayed dead. |
| 2 | Therefore an instance already exists on reopening, which is why recovery reports "already exists" | **WRONG — it depended on #1.** |
| 3 | A deliberate crash may behave differently from a force-quit | **Untested** — force-quit comparison not yet run |
| 4 | Recovery will need to tolerate the conflict | **Undecided** — the conflict's cause is now unknown |
| 5 | Lowest confidence in this cycle; I expect at least one of these to be wrong | **Correct.** Two were wrong, including the central one. |

**E1.3 is now MORE mysterious, not less.** The background-relaunch hypothesis was the only explanation on the table for "task server endpoint already exists", and it is dead. If no process survives the crash, nothing should hold that endpoint when the app is reopened — yet E1.3 reproduced the conflict every time.

**New hypothesis, and the obvious next test: `recoverActiveWorkoutSession` may not be idempotent.** E1.3's own sequence is the clue — two identical consecutive calls returned *different* answers ("no active session", then "recovered state running"). A pure query cannot do that. It suggests the call itself has side effects: registering an endpoint, or transitioning state, so that the second call observes a world the first one changed.

Note also that `RecoveryProbe` **discards the recovered session** — it calls `associatedWorkoutBuilder()` and keeps nothing. If a successful recovery registers an endpoint that is only released when the session object is retained and properly ended, a discarded session could leave a dangling registration behind.

**Consequence for L2.** The cycle cannot proceed to persistence design yet. E2.2 assumed the app dies and is restored; E2.0 confirms the app really does die, which is good — but the recovery path is now less understood than when the cycle opened. **E2.0b must come next:** call recovery twice in a row on a clean launch and observe whether the call changes what it reports.

**Worth stating plainly:** this cycle's central prediction was wrong, and I would not have found that out by building persistence on top of it. It would have surfaced somewhere around Day 8, as a bug that looked like something else.

---

## E2.0b — Is `recoverActiveWorkoutSession` idempotent?

*Added 2026-08-24 after E2.0 falsified the background-relaunch hypothesis. Predictions written before the code was changed.*

**Why this exists.** E1.3 showed two identical consecutive calls returning different answers — "no active session", then "recovered state running". A pure query cannot do that. Either the call has side effects, or something outside the app changes between calls. E2.0 ruled out a resurrected process, so the cause must be inside the call or inside HealthKit's own bookkeeping.

**A supporting detail in my own code:** `RecoveryProbe` currently **discards** the recovered session. It calls `associatedWorkoutBuilder()` and retains nothing. If a recovered session registers an endpoint that is only released when the object is retained and properly ended, discarding it could leave a registration behind that nothing can clear.

Setup: on a clean launch with a workout running, call `recoverActiveWorkoutSession` **twice in succession**, reporting both results separately. Then repeat with the returned session **retained** in a property rather than discarded, and compare.

**My prediction**

1. **The two calls will not agree.** If they return the same result twice, the non-idempotence hypothesis dies immediately and E1.3's behaviour needs a different explanation again.
2. **Retaining the session will change the outcome.** Specifically, I expect discarding it to be what leaves the dangling endpoint, so the retained version should either succeed cleanly or fail *consistently* rather than alternating.
3. If the first call fails with "already exists" on a genuinely clean launch — no prior recovery in that process — then the registration survives process death, which the app cannot see or control. That would make it a HealthKit-level constraint rather than an app bug.
4. **The honest possibility I cannot rule out:** the mechanism may be none of the above. Two hypotheses have already died this cycle, and I have no documentation for any of this — only observed behaviour.
5. Whatever the mechanism, the practical rule for L2 will be the same: recovery must be attempted defensively, its result checked rather than assumed, and the returned session retained.

**Actual result — NOT IDEMPOTENT. CONFIRMED, and it explains E1.3.**

*Run 2026-08-24, 09:30. Clean install, no debugger, workout started then force-quit, recovery tapped as the first action on relaunch.*

```
CALL 1: recovered (state: running; startDate: 24 Aug 2026 at 9.29.49)
CALL 2: error: Task server endpoint for
        'AE606960-1713-4A2E-A074-4A75B063496A' already exists
        (for instance '472919D3-D983-4B57-8E5F-C465356092B0')
VERDICT: DIFFERENT
```

Two identical consecutive calls. The first succeeded. The second failed with the exact error that has haunted this cycle since E1.3.

**The gap**

| # | Prediction | Outcome |
|---|---|---|
| 1 | The two calls will not agree | **Confirmed** — VERDICT: DIFFERENT |
| 2 | Retaining the session will change the outcome; expect consistent behaviour rather than alternating | **Confirmed in effect, wrong in mechanism.** Retention did not prevent the conflict — the retained session *is* the conflict. But behaviour is now deterministic rather than alternating, which is what mattered. |
| 3 | If call 1 fails on a genuinely clean launch, the registration survives process death | **Antecedent did not occur.** Call 1 *succeeded* on a clean launch, so a registration does **not** survive process death. This rules out the HealthKit-level-constraint scenario. |
| 4 | The mechanism may be none of the above | **Not needed.** It was one of the above. |
| 5 | Whatever the mechanism, recovery must be defensive, checked, and the session retained | **Confirmed as the right rule**, now for a known reason rather than a precautionary one. |

---

## The mechanism, finally

`recoverActiveWorkoutSession` fails with "task server endpoint already exists" whenever **the process already holds a live `HKWorkoutSession` object for that workout** — regardless of where that object came from.

This explains every observation in the cycle:

| Observation | Explanation |
|---|---|
| E1.3, first attempt failed | E1.2's workout was still running **in the same process**, so `WorkoutSessionManager` held a live session object and its endpoint was registered |
| E1.3, after ending the workout: "no active session" | The in-process session had been ended, releasing its endpoint |
| E1.3, next tap: "recovered state running" | With the endpoint free, recovery could return the session still running at system level |
| E2.0: no background relaunch | Correct and irrelevant — the conflict was never about a surviving process |
| E2.0b CALL 1 succeeded | Clean launch, nothing held a session |
| E2.0b CALL 2 failed | CALL 1's own retained session now holds the endpoint |

**The earlier "malformed test" reading of E1.3 was right after all**, but for a reason nobody had identified at the time. It was then wrongly overturned in favour of a background-relaunch hypothesis that E2.0 killed. Two wrong explanations preceded the correct one, and both were written down before being disproved — which is the point of keeping them.

---

## L2's open question is now closed: the launch path

Recovery is **not** a repair step to be reached for when something looks wrong. It is a **one-shot decision made at launch, before anything else can create a session**:

1. On launch, call `recoverActiveWorkoutSession` **exactly once**, before any view, view model or manager can instantiate an `HKWorkoutSession`.
2. **Retain** whatever it returns and treat it as *the* session for the process.
3. **Never call recovery again** in that process — a second call is guaranteed to fail against the first's own registration.
4. If recovery returns nil, only then create a new session.
5. If recovery throws "already exists", the process has a bug: something created a session before recovery ran.

Point 5 is the useful one. That error is not an environmental hazard to be retried around — it is a **self-inflicted ordering error**, and it should be treated as a programming mistake rather than a condition to tolerate.

---

## E2.1 — The state machine, on paper before in code

Setup: draw the HYROX session as typed states and transitions. Deliberately a design artifact, not code. Kept in two versions — before implementation and after — because the diff is the learning.

**My prediction**

1. The happy path is small: `idle → run(leg n) → transition → station(n) → transition → run(leg n+1) → … → complete`. Roughly five state *kinds*, repeated sixteen times.
2. **The awkward paths will outnumber the happy path.** Pause, resume, interruption by a call, app death, accidental advance, ending mid-station. I expect the recovery and correction logic to be larger than the logic that runs when nothing goes wrong.
3. **Accidental advance will be the hardest to model.** Undoing a mis-tap means restoring the previous state *and* its timestamps, so the machine needs history, not just a current state.
4. Every state must carry a **start timestamp**, never an accumulating duration — a direct consequence of L1's measured rule.

**Actual result**

<!-- -->

**The gap**

<!-- -->

---

## E2.2 — Persist on every transition, then kill it

Setup: write semantic state to disk at every transition. Kill the app mid-station. Relaunch. Compare what was restored against what was true at the moment of death.

**My prediction**

1. Writing on every transition is cheap. A HYROX race has ~17 transitions in ~90 minutes, not one per second, so cost is irrelevant and there is no reason to batch.
2. **Nothing meaningful is lost, provided timestamps are persisted rather than durations.** If the file records "station 3 started at 10:19:35", elapsed time is recomputable at any later moment. If it records "station 3 has run for 47 seconds", everything after the last write is lost. This is L1's rule applied to storage.
3. **The write must be atomic.** A crash during a write corrupts the file, and a corrupt file is worse than a missing one, because a missing file is obviously missing. Write to a temp file and rename.
4. What *is* genuinely lost: any transition that happened between the last successful write and the death. With per-transition writes that window is one transition at most.
5. I expect the first implementation to fail on relaunch for a boring reason — a decoding error or a missing file on first run — rather than anything conceptually interesting.

**Actual result**

<!-- -->

**The gap**

<!-- -->

---

## E2.3 — Reconcile HealthKit's record with mine

Setup: after a recovery, compare the recovered session's `startDate` against the persisted semantic state's session start. Decide, in writing, which wins when they disagree.

**My prediction**

1. **They will not match exactly.** My state file is written a moment after the session starts, so I expect a difference of well under a second — but non-zero.
2. Under the source-of-truth policy: **HealthKit is authoritative for the session envelope** (start, end, heart rate, energy) and **I am authoritative for what happened inside it** (station identity, transition boundaries, notes).
3. Therefore station boundaries should be stored as **offsets from HealthKit's `startDate`**, not as independent absolute times. That way the two records cannot drift apart, and there is nothing to reconcile.
4. If prediction 3 holds, "reconciliation" mostly disappears as a problem — which would be a better outcome than solving it, and is worth testing before building a merge routine nobody needs.

**Actual result**

<!-- -->

**The gap**

<!-- -->

---

**Order of work for L2:** E2.0 first and alone. Its result decides whether E2.2's design survives contact with reality, and whether E2.3 is a real problem or an avoidable one.

---

# CYCLE L3 · Ownership — Days 5–6 (Aug 27–28) · MIDPOINT

**Learning question:** Which half of the record does HealthKit own, and which is mine?

Provisional:
- E3.1 — Save a workout on the watch. Does it reach the iPhone with none of my code involved?
- E3.2 — What survives the crossing, and what is lost? Produces the ownership table.

---

# CYCLE L4 · Reliable transport — Days 7–8 (Aug 31 – Sep 1)

**Learning question:** How does data survive an unreliable link between two devices?

Provisional:
- E4.1 — All four `WCSession` methods against the same offline scenario. Predictions recorded first, per method. Produces the transfer-mode matrix.
- E4.2 — Duplicate delivery: does the same payload arrive twice, and do stable IDs prevent duplicates?
- E4.3 — Write the ADR: ownership rules, merge policy, rejected options.

---

# CYCLE L5 · Honest representation — Days 9–10 (Sep 3–4)

**Learning question:** What can this data honestly say, and what can it not?

Provisional:
- E5.1 — Real training session captured on device.
- E5.2 — For every number on the review screen, write the fact-vs-interpretation line.
- E5.3 — Design token change propagates to both targets.

---

# CYCLE L6 · Wrapper — REMOVED

Dropped in the 2026-08-24 re-baseline. The Gantt carries five cycles. Presentation prep, evidence assembly and rehearsal now sit inside L5 or after Act closes on 4 September, rather than taking a numbered Act day.

---

# L1 VERIFICATION PASS — 2026-08-21

An independent consistency check of every recorded L1 number, run against the source code rather than against the photographs. This does **not** re-run the experiments; it checks whether the recorded data is internally coherent and consistent with what the code can produce.

**Code model confirmed.** Both probes use `Timer.scheduledTimer(withTimeInterval: 1, repeats: true)`, and `elapsedByTicks` accumulates per tick while `elapsedByDate` is computed from a stored `startDate`. So one tick must equal exactly 1.0 s of counted time, and the two figures are genuinely independent measures rather than two views of the same counter.

| Check | Result |
|---|---|
| Ticks equal counted seconds — E1.1, E1.2 A, E1.2 B | PASS (20/20.0, 1134/1134.0, 1610/1610.0) |
| Divergence arithmetic — all three readings | PASS (77.0, 15.0, 20.0 s) |
| Proportion lost — all three readings | PASS (79.38 %, 1.305 %, 1.227 %) |
| Inter-reading window A→B: 481 s elapsed, 476 ticks | PASS — 5.0 s lost, 1.04 % |
| Extrapolation to a 90-minute race at reading B's rate | PASS — 66.3 s |
| E1.3: start 10:19:35 against recovery at ~10:21 | PASS — ~85 s, consistent with a force-quit and relaunch |

**Verdict: all consistent.** No arithmetic error, and no figure that the code could not have produced.

**What this verification does NOT establish.** It confirms the recorded numbers are coherent. It cannot confirm they were observed under the stated conditions — that Always-On was off, that no debugger was attached, that the wrist was actually down. Those are physical facts about the room, evidenced only by the photographs and by Stanley's account of them. A consistency check cannot substitute for a witness, and claiming otherwise would repeat this cycle's central error at the level of the record itself.

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
| Aug 21 | `recoverActiveWorkoutSession` threw "endpoint already exists" | Recovery is broken on this watchOS version | Initially read as a malformed test. On repetition it proved **reproducible**: recovery reliably fails after a force-quit while a workout is active. The one-off explanation was wrong | Open question for L2 — see the E1.3 amendment |
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
| E1.2 | 2 confirmed, 1 refined, 2 untested | GATE PASSED. 1.23% lost vs 79.4% without a session. Two readings show the drift is steady, not a start-up artifact. |
| E1.3 | Recovery possible; launch path OPEN | Reproducible three-state sequence. Recovery after force-quit reliably FAILS while a workout is active — the exact case L2 must handle. Success required an intervening end-workout, which a crashed app cannot do. |
| E2.0b | 3 confirmed, 1 refined, 1 unneeded | NOT IDEMPOTENT. Call 1 succeeds, call 2 conflicts with call 1's own session. Explains every E1.3 observation and settles L2's launch path. |
| E2.0 | Prediction 1 FALSIFIED | The system does NOT relaunch a crashed app holding a workout session. Kills the only explanation for E1.3's endpoint conflict — cause now unknown. |
| E2.1 | | |
| E2.2 | | |
| E2.3 | | |
