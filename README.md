# HyroxCoach

HyroxCoach is Challenge Based Learning (CBL) Challenge 4 by Stanley Young, exploring how to connect real-time HYROX workout tracking across watchOS and iOS. It is a 10-day learning project: the intended evidence is one complete workout captured on the watch and reviewed on the phone, with written reasoning about what held and what did not.

## What this is

This is a private, solo learning repository, not a product launch. The work follows a learning question through experiments, predictions, results and explanations; a build that works is useful evidence, but it does not prove that the author understands why it works.

The eventual responsibility split is a learning target, not current functionality:

- watchOS owns live capture during the workout: glanceable, haptic and usable in motion.
- iOS owns history, review, splits, comparison and deeper analysis afterwards.

## Challenge and growth focus

**Big Idea:** Growth

**Essential Question:** How can I learn to connect real-time HYROX workout tracking on watchOS with clear and meaningful post-workout analysis on iOS?

**Challenge:** Learn to build connected data tracking across watchOS and iOS.

**Growth Focus Statement:**

> “Learn how connected data tracking works across watchOS and iOS — background execution, data ownership, transport reliability, and source of truth — by producing one complete workout captured on the watch and reviewed on the phone, together with a written explanation of each decision and a log of what I predicted wrongly, as my learning evidence, so that I am able to build a working data crossing between watch and phone that holds through airplane mode, screen-off and a force-quit, and explain why it holds, by the end of the 10-day Act phase.”

## Method

Each experiment follows a predict–test–explain loop:

1. **Predict:** write the prediction in `WORKBOOK.md` before the experiment.
2. **Test:** run the experiment on real hardware, never in the simulator.
3. **Explain:** record the result and explain the gap between the prediction and the result.

The real-hardware rule is deliberate. Background execution, heart rate, wrist-down behaviour and force-quit recovery do not behave truthfully in the simulator. The gap between what was predicted and what happened is the learning evidence, including when the prediction was wrong.

## Current state

**Only Cycle L1 exists.** The repository deliberately contains no workout state machine, no persistence, no WatchConnectivity and no sync. Those belong to later cycles; building them early would hollow out the cycles they belong to. The iOS app is intentionally near-empty until L3.

The current watchOS code is four L1 experiment harnesses. The generated `HyroxCoach.xcodeproj` is not committed: `project.yml` is the XcodeGen source of truth. The targets are `HyroxCoach` (iOS 17+) and `HyroxCoachWatch` (watchOS 10+, a modern single-target `WKApplication` embedded in the iOS app). Both carry the HealthKit entitlement. The project has been verified building clean against the watchOS 26.5 and iOS 26.5 SDKs under Xcode 26.6.

E1.2 is the L1 gate. If it has not passed by the end of Day 2, the reduced scope and the reason are recorded as a finding rather than hidden by starting later-cycle work.

## Experiments

| ID | File | What it tests |
| --- | --- | --- |
| E1.0 | `HyroxCoachWatch/HealthKitAuth.swift` | HealthKit authorisation plus a write-and-read-back round trip. |
| E1.1 | `HyroxCoachWatch/BackgroundProbe.swift` | A 1 Hz `os_log` ticker with no workout session: the baseline for background execution. |
| E1.2 | `HyroxCoachWatch/WorkoutSessionManager.swift` | The same ticker with an active `HKWorkoutSession` and live heart rate. This is the L1 gate. |
| E1.3 | `HyroxCoachWatch/RecoveryProbe.swift` | `HKHealthStore.recoverActiveWorkoutSession` after a force-quit. |

E1.1 and E1.2 measure elapsed time in two ways: by counting ticks and from a stored start `Date`. The divergence between those numbers is the actual measurement.

## Repository layout

```text
.
├── project.yml                         # XcodeGen source of truth
├── SETUP.md                            # setup, signing and real-hardware run guide
├── WORKBOOK.md                         # predictions, results, gaps and failure log
├── README.md
├── HyroxCoach/                         # iOS target; intentionally minimal in L1
│   ├── ContentView.swift
│   ├── HealthKitStatus.swift
│   ├── HyroxCoachApp.swift
│   ├── HyroxCoach.entitlements
│   └── Info.plist
├── HyroxCoachWatch/                    # watchOS L1 experiment harnesses
│   ├── BackgroundProbe.swift            # E1.1
│   ├── ContentView.swift
│   ├── HealthKitAuth.swift              # E1.0
│   ├── HyroxCoachWatchApp.swift
│   ├── RecoveryProbe.swift              # E1.3
│   ├── WorkoutSessionManager.swift      # E1.2
│   ├── HyroxCoachWatch.entitlements
│   └── Info.plist
└── Shared/
    └── AppLog.swift                     # shared os_log evidence
```

The generated `HyroxCoach.xcodeproj` is intentionally absent from this layout and from the committed source.

## Getting started

Read `SETUP.md` for Xcode selection, signing, HealthKit capabilities, pairing, real-hardware run steps and Console log instructions. From the repository root, install XcodeGen and generate the project:

```bash
brew install xcodegen
```

```bash
xcodegen generate
```

Open the generated project in Xcode and run the watch scheme on the paired physical Apple Watch. Experiments must use the paired watch and iPhone; the simulator is not a valid test environment for this work.

## Act phase and cycle plan

The Act phase runs from Day 1, 2026-08-20, to Day 10, 2026-08-29.

| Cycle | Days | Dates | Learning question | Status |
| --- | --- | --- | --- | --- |
| L1 · Staying alive | D1–D2 | 2026-08-20–2026-08-21 | Why does a watch app stop recording, and what does `HKWorkoutSession` change? | Current; gate |
| L2 · Recoverability | D3–D4 | 2026-08-22–2026-08-23 | What has to be true for a workout to survive the app dying? | Later |
| L3 · Ownership | D5 | 2026-08-24 | Which half of the record does HealthKit own, and which is mine? | Later |
| L4 · Reliable transport | D6–D7 | 2026-08-25–2026-08-26 | How does data survive an unreliable link between two devices? | Later |
| L5 · Honest representation | D8–D9 | 2026-08-27–2026-08-28 | What can this data honestly say, and what can it not? | Later |
| L6 · Wrapper | D10 | 2026-08-29 | Presentation preparation only; no new work. | Later |

## Evidence

`WORKBOOK.md` holds the predictions written before each test, the actual results and the gap analyses. Its failure log records which layer each symptom appeared to be in versus where the cause actually was.

The on-device logs are the other evidence source:

- `Shared/AppLog.swift` writes to the `com.stanleyyoung.HyroxCoach` subsystem; `SETUP.md` explains how to inspect it in Console.app.
- For E1.1 and E1.2, a timestamp gap after wrist-down suspension is evidence of what happened, while the two elapsed-time values show how it happened.

Those mismatches, alongside the experiment logs, are the evidence for what was learned.
