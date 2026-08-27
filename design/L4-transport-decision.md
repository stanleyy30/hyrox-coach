# ADR: Watch-to-phone transport

**Decision: Do not build a watch-to-phone transport for the current product; use HealthKit sync to carry the completed workout and its semantic metadata.**

Date: 27 August 2026  
Status: Accepted

## Context

Cycle 4 originally planned a WatchConnectivity transport. It would choose between transfer methods, cope with devices being apart, define delivery behaviour, handle duplicates and deduplicate by stable ID. That was reasonable when the project did not know whether a completed workout would cross unaided, under what conditions it would cross, or whether the phone would receive the HYROX structure inside it. The measurements below answer those questions for the current product.

## What the measurements changed

| Capability planned for the transport | Is it still needed? | Evidence and conclusion |
|---|---|---|
| Move a completed workout from watch to phone | No | E3.0 measured three unaided crossings: phone unlocked and nearby, phone locked, and phone in another room. All arrived. The prior prediction that the phone had to be awake and nearby was falsified. |
| Carry the HealthKit workout envelope | No | E3.1 measured the arriving UUID, start, end, duration, activity type, active energy, source app and device. HealthKit already carries this record. |
| Carry station identity and segment structure | No, once the workout finishes | E3.1 found no HYROX semantics unaided, but E3.2 measured four custom metadata keys crossing intact when attached at `finishWorkout`, including the full segment string. |
| Carry a realistic full-race payload | No | E4.0 measured all 25 segments crossing complete. The 601 characters sent matched the 601 received, and all eight stations retained the correct order. No truncation limit was reached. |
| Merge the phone record with independently timed boundaries | No | E2.3 measured boundary offsets from the workout session's `startDate` round-tripping exactly, to the millisecond. The phone can reconstruct absolute boundary times from the shared origin. |
| Deliver while the devices are apart | No for the measured post-workout need | E3.0 measured arrival with the phone in another room. It did not measure every possible separation or network condition. |
| Select a WatchConnectivity transfer method and maintain delivery guarantees | No for the current requirements | This is an inference from E3.0, E3.2 and E4.0: the complete post-workout record already arrives through HealthKit, so a second delivery path has no current consumer. |
| Detect duplicate deliveries and deduplicate by stable ID | No | This is an inference from not adding a second app-owned delivery path. The measured HealthKit record already has a UUID (E3.1); this decision does not create competing HealthKit and WatchConnectivity copies. |
| Keep recording after the wrist drops | No transport can provide this | E1.2 established that an active `HKWorkoutSession` is required for capture. Without one, the app was suspended after about eight seconds. Session lifetime remains a watch recording concern, not a phone transport concern. |
| Send live in-workout state to the phone | Technically still a candidate | E3.2 attaches metadata only at `finishWorkout`. It therefore cannot carry current station, elapsed time or other changing state during the workout. |

### Evidence boundary

Measured: completed workouts crossed in all three E3.0 conditions; the workout envelope crossed in E3.1; custom semantics crossed in E3.2; and the full E4.0 payload crossed without truncation.

Measured: E2.3 reconstructed the tested boundaries exactly from offsets, and E1.2 showed why the watch still requires an active workout session.

Inferred: these measured capabilities satisfy the current post-workout phone requirements. They do not prove a universal delivery guarantee or a live-data capability.

## What is genuinely left

The measurements leave one capability that completed-workout metadata cannot provide: live data during the workout. Metadata is attached once, at `finishWorkout` (E3.2). It is a completed summary, not a live stream.

The product does not currently need that capability. Its stated division of responsibility is:

- The watch owns the live workout: tracking, glanceable information and immediate feedback during training.
- The phone owns what follows: history, review, comparison, trends and deeper analysis.
- The iOS app does not display live in-workout data and was never intended to do so.

Those are product requirements, not measurements. Applied to the measured transport boundary, they remove the only remaining consumer for live watch-to-phone data.

The conclusion is therefore an inference, not a new measurement: because the complete post-workout record crosses through HealthKit, and because no phone feature consumes live state, this product does not need its own watch-to-phone transport.

## Decision and consequences

Do not implement WatchConnectivity transport in the current product. In particular, do not add transfer-method selection, an app-owned delivery queue, retry or delivery guarantees, duplicate handling, or stable-ID deduplication for a second transport path.

The consequences are:

- Fewer moving parts and fewer failure states.
- No duplicate handling between HealthKit sync and an app-owned transport.
- No app-owned delivery guarantees or retry policy to maintain.
- No merge step for segment boundaries, because E2.3 measured exact reconstruction from offsets.
- The phone receives semantic data only after the workout finishes, as measured in E3.2.
- The design depends on HealthKit sync continuing to behave as measured in E3.0, E3.2 and E4.0.
- The watch must still run an active `HKWorkoutSession`; E1.2 showed that transport is not a substitute for the session that keeps capture alive.

This decision avoids adding code. It does not claim that HealthKit provides a general-purpose, guaranteed transport. It says only that the behaviour measured is sufficient for the current product requirements.

## What would reverse this decision

Build or reconsider an app-owned transport if any of these concrete conditions becomes true:

- The iOS app gains a screen or feature that displays current in-workout state before `finishWorkout`.
- Any requirement says data must reach the phone before the workout ends.
- A representative production payload is sent through HealthKit metadata and arrives truncated, missing, rejected or unable to save; compare sent and received length, segment count, ordering and content.
- The product must support users who have disabled iCloud Health sync between their watch and phone; test with that setting off and confirm that the required completed record does not arrive.
- Repeated real-hardware tests under a required operating condition show that a completed workout or its metadata does not reach the phone within the product's stated post-workout availability target.
- The phone begins to require data that cannot be encoded in the property-list metadata accepted at `finishWorkout`.

Any reversal should identify the failed requirement and repeat the relevant experiment. The existence of WatchConnectivity alone is not a reversal condition.

## Risks accepted

- HealthKit's metadata size limit is unknown. E4.0 proved that 25 segments and 601 characters cross intact, but the limit was never reached.
- The crossing depends on the user's iCloud Health sync being enabled. The project did not test the behaviour with that setting off.
- The 14 seconds from E3.0 is an upper bound on time since the workout ended. It is not a measured sync delay, because arrival itself was not timestamped.
- E3.0 covered three real-hardware conditions, not all possible distances, connectivity states, account states or delays.
- E3.2 established metadata attachment at workout finish. A crash or failure before a successful finish is outside the post-workout crossing measured here.
- HealthKit sync behaviour may change. The project accepts that dependency and should rerun E3.0, E3.2 and E4.0 if platform behaviour or product availability targets change.

These risks are accepted because the current product needs a complete record afterwards, not a live phone mirror, and that requirement was met in the measured cases.

## The reasoning risk

The temptation was to build the transport because it was in the plan and because it is the more impressive thing to demonstrate. Neither is a technical reason.

The original plan was justified by uncertainty. E3.0, E3.2, E4.0 and E2.3 removed that uncertainty for the current requirements. Continuing as though those results had not happened would turn the plan into an obligation rather than a hypothesis.

A decision not to build something is a legitimate engineering result when it is evidenced. This decision is reversible if a checkable product need or a failed measurement supplies a reason to reverse it.
