# Data honesty after a workout

## Why this document exists

The second roxzone in the real session was shown as 2.03 s. It passed every integrity rule, but an accidental double-tap made it false. That case made it necessary to separate what the device sensed, what a person marked, what the app calculated, and what the data cannot support.

## The four categories

### MEASURED

The device recorded the value with no human action. It can be trusted only to the accuracy and availability of the sensor or HealthKit source, so sensor error, missing samples and denied access remain possible.

### MARKED

A person pressed a button and the app wrote a timestamp. The stored timestamp may be exact, but the event time is only as accurate as the press; a late, early or accidental press is wrong in a way the data cannot reveal.

### DERIVED

The app calculated the value from MEASURED or MARKED inputs. It inherits every weakness of those inputs, and a result made from two MARKED timestamps is weaker than either timestamp because either press can move the result.

### UNSUPPORTED

The available data cannot answer the question. No trust should be placed in such a claim, and the app must not state or imply one from timing, energy, heart rate or colour.

## Classification table

The category describes the evidence behind the displayed value. Exact storage or arithmetic does not make the event itself exact.

| Number the app can show | Category | What limits it |
|---|---|---|
| Workout start | MEASURED | HealthKit supplies it without a press; it remains limited by HealthKit's clock and workout recording. |
| Workout end | MEASURED | HealthKit supplies it without a press; it remains limited by HealthKit's clock and workout recording. |
| Workout duration | MEASURED | HealthKit supplies the completed duration without human timing; trust is limited to that recorded workout envelope. |
| Active energy | MEASURED | The device records it without a press, but it is still an estimate limited by its sensors and energy model. |
| Heart-rate sample | MEASURED | Each available sample comes from the sensor; sensor accuracy, gaps and denied read access limit it. |
| Each segment's start offset | MARKED | It records an Advance press relative to workout start; millisecond round-trip accuracy does not prove that the press matched the physical boundary. |
| Each segment's duration | DERIVED | It is the difference between two MARKED boundaries, so either press can make it wrong. |
| Total run time | DERIVED | It sums run durations made from MARKED boundaries and accumulates their timing errors. |
| Total station time | DERIVED | It sums station durations made from MARKED boundaries and accumulates their timing errors. |
| Total roxzone time | DERIVED | It sums roxzone durations made from MARKED boundaries and accumulates their timing errors. |
| Station-by-station comparison | DERIVED | It compares durations built from different pairs of MARKED boundaries, so apparent differences may be press differences. |
| Activity type | UNSUPPORTED | HealthKit has no HYROX type; Cross Training is a permanent recording approximation, not a measured classification. |

## Why the split is not where it looks

A station duration feels like a fact because it is displayed as elapsed time. It is not a sensor reading. It is a subtraction performed after two human actions.

At the station start, the athlete presses Advance and the app writes a boundary. At the station end, another press writes another boundary. Both boundaries are MARKED.

The station duration is the second boundary minus the first. It is therefore DERIVED from the weakest category twice over. A late first press shortens it, a late second press lengthens it, and two errors can either compound or conceal one another.

The real session on 2026-08-31 lasted 3 m 47 s and recorded 33.43 kcal. That is about 8.8 kcal/min, against 3.3 kcal/min for a desk run. Those MEASURED values support the limited claim that the recorded energy rate was higher during the real session; they do not validate any segment boundary.

Roxzone 1 was calculated as 24.76 s. Roxzone 2 was calculated as 2.03 s. Both were produced by the same subtraction and both had valid stored inputs.

The second value was false. Advance had been tapped twice by accident, so the second MARKED boundary followed the first almost immediately. A two-second transition between a run and a station is physically impossible.

The integrity check still reported the workout INTACT. The 2.03 s value was non-negative, in order and inside the workout duration. It was plausible by every implemented rule and false in fact.

This is not a rounding fault or a transport fault. Segment offsets round-trip exactly to the millisecond. The false input survived perfectly, which proves storage integrity but says nothing about whether the press was timely.

## Rules for the interface

- MEASURED and DERIVED values must not use an identical visual treatment. A review screen must make the distinction visible without opening help text.

- Every value derived from a MARKED timestamp must carry a visible indication such as a persistent category label. That indication must appear beside the value, not only in a legend elsewhere.

- MARKED boundaries must not be described as automatic, sensed or verified. Exact round-trip storage may be stated only as a storage property.

- An INTACT result may describe ordering, bounds and transport completeness. It must not be presented as proof that a press matched the real event.

- UNSUPPORTED claims must never appear, even as a hint, ranking, badge, colour or suggested interpretation.

- Colour must not be the only way a category or limitation is communicated. The meaning must remain explicit without colour.

- The app must never show a calculated number with more precision than its inputs justify. Millisecond storage does not justify millisecond claims about human presses.

- Totals and comparisons must retain the DERIVED indication. Summing more segments does not turn marked timing into measurement.

- Missing heart-rate samples must be shown as missing, not as a zero or as evidence of low effort. Denied access and no available samples can look the same to the app.

- Cross Training must not be presented as proof of the workout's real activity type. It is the only available HealthKit approximation for this record.

## What this app must never say

- Why a station was slow.

- Whether the athlete is improving.

- Whether pacing was correct.

- Anything about injury, health or training load.

## The open weakness

Nothing in the data distinguishes a well-timed press from a late, early or accidental one. No integrity rule and no amount of interface honesty can repair a MARKED value after the fact. The only remedies are correction at the moment of the error, or refusing to claim precision that the input cannot support.
