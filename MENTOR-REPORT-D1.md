# Mentor Report — Day 1

| | |
|---|---|
| **Learner** | Stanley Young |
| **Challenge** | Challenge 4 |
| **Phase** | Act, Day 1 of 10 |
| **Date** | 2026-08-20 |
| **Cycle in progress** | L1 — Staying alive |

## The learning question for this cycle

> Why does a watch app stop recording, and what does `HKWorkoutSession` actually change?

This must be answered before later cycles because recovery, ownership and reliable transport all depend on first knowing whether recording continues when the watch screen is off.

## Method in three sentences

Before each experiment, predictions are written down in the workbook.
The experiment is then run on real hardware because background execution, heart rate, wrist-down behaviour and force-quit recovery do not behave truthfully in the simulator.
The gap between prediction and result is explained, and no prediction is edited after its test has run.

## Prediction scorecard

HealthKit is Apple's protected store and framework for health and workout data; an `HKWorkoutSession` is the mechanism in watchOS, Apple's operating system for Apple Watch, that tells the system an active workout is in progress.

| Prediction | Outcome recorded | Evidence |
|---|---|---|
| 1. Both targets need the HealthKit capability separately. | **Confirmed** | It was set for both targets and appears twice in the generated project. |
| 2. Missing either usage description causes a crash at authorisation, not a build error. | **Confirmed** | The sabotage build succeeded without warning, then the app terminated instantly when authorisation was tapped; no error handler ran. |
| 3. `isHealthDataAvailable()` returns true on watch and phone. | **Confirmed on both** | The phone reported true; the successful watch round trip demonstrated availability there. |
| 4. The authorisation sheet appears on the watch. | **Confirmed** | The sheet appeared on the watch. |
| 5. An authorisation request succeeds after denial, and read denial cannot be reliably detected through authorisation status. | **Confirmed by denial test** | After heart-rate access was turned off, the request reported success and the query returned zero samples without error. This prediction had earlier been recorded as **half-tested** until the deny path was exercised. |
| 6. Provisioning and signing would be the day's main time sink. | **Strongly confirmed** | Three consecutive blockers concerned the account, device trust or device registration; no HealthKit code ran until they were cleared. |
| E1.0b: excluding this app's own data will establish whether foreign samples can be read. | **CONFIRMED** | The probe read foreign samples; read access was therefore separately evidenced. |
| Side-prediction during the denial test: E1.0b's overall verdict would become INCONCLUSIVE. | **WRONG** | It remained CONFIRMED because the workouts query returned data even though the heart-rate query returned nothing. |
| E1.1 predictions: without a workout session, logging will stop shortly after wrist-down, silently. | **Untested** | No actual result or gap is recorded. |
| E1.2 predictions: an active workout session will sustain logging and live heart rate for at least 15 minutes wrist-down. | **Untested** | No actual result or gap is recorded. |
| E1.3 predictions: the system can recover its active workout session after force-quit, but app-owned state will be lost unless persisted. | **Untested** | No actual result or gap is recorded. |

The evidence boundary is narrow: E1.0 and its amendments are the only recorded results.
The E1.1, E1.2 and E1.3 entries above report predictions and status, not findings.

## What was actually learned

- A passing test is not necessarily evidence of what its label appears to test. E1.0 wrote one active-energy sample and read that same sample back. Because HealthKit always lets an app read its own written data, the pass established write access and self-read only; it did not establish permission to read other health data. E1.0b had to exclude the app's own source before foreign samples separately confirmed read access.

- Prediction 2 exposed a configuration failure that ordinary code-level defences cannot handle. Removing the required HealthKit usage-description key still produced `BUILD SUCCEEDED`, with neither error nor warning. Tapping authorise then caused immediate termination before the permission sheet, error string or `catch` block could appear. The only defence is correct configuration.

- Prediction 5 showed that denied read permission is deliberately invisible inside the app. After heart-rate access was denied, the authorisation request still completed successfully and the heart-rate query produced an empty set without error. From inside the app, that result is indistinguishable from there simply being no heart-rate data.

- The wrong side-prediction exposed a flaw in the learner's own verification probe. E1.0b combined independent heart-rate and workout queries into one verdict; it reported CONFIRMED because workouts returned samples even while heart rate returned nothing. An aggregate verdict destroyed the information needed to see the individual failure, so future probes need a separate verdict for each type.

## The pattern across the day

Four separate times, a success signal at one level concealed a failure at another: a round-trip pass concealed that read access had not been tested; a clean build concealed a fatal missing configuration key; a successful authorisation call concealed denied read access; and E1.0b's CONFIRMED verdict concealed an empty heart-rate result.

This was not the intended subject of L1, but it is the day's most transferable finding.
It is expected to recur in Cycle L4, where “the sync worked” will aggregate several steps that can fail independently: transfer while devices are disconnected, later delivery, duplicate handling and stable-ID deduplication.
A single green transport verdict could therefore conceal a failure in any one of those steps.

## Failure log summary

| Symptom | Layer it appeared to be in | Layer the cause was actually in |
|---|---|---|
| `xcodebuild` refused to run and listed no iOS or watchOS SDKs. | Xcode installation | Toolchain selection: `xcode-select` pointed to Command Line Tools rather than the installed Xcode. |
| No profile existed for the watch app. | Bundle identifier or signing configuration | The developer account's Program License Agreement had not been accepted, so no profile could be issued. |
| The same no-profile error remained after the agreement was accepted. | Signing configuration | The team had no registered devices, while a development profile must name specific devices. |
| “Your team has no devices” appeared although both devices were connected. | Device detection by the Mac | A generic watchOS destination named no specific device to register. |

## Honest status

- Cycle L1's gate experiment, E1.2 — whether an active workout session keeps the app alive with the wrist down — **has not run**.

- E1.1, the no-session baseline against which E1.2 must be measured, **has not run**.

- E1.3 has also not run; its predictions remain untested.

- One code fix is committed but remains unverified on device because installation failed.

Day 1 was consumed largely by provisioning and account setup rather than by the learning question.
The app, icon and repository are therefore only supporting evidence of the test conditions, not achievements or evidence that L1 has been answered.

## Next

First, run E1.1 to establish the no-session baseline.
Then run E1.2 with an active workout session.
Compare the wrist-down logs and elapsed-time measurements from the two experiments.

The gate rule is explicit: if background execution is not proven by the end of Day 2, scope is cut to the floor and the reason is recorded as a finding.
