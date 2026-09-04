# Challenge 4 — Synthesis Cards, Cycles 1–6

Six cards. Each one is short enough to paste into a canvas and say out loud from memory.

---

## L1 — Staying alive

**Question.** Why does a watch app stop recording?

**Finding.** When the wrist drops, watchOS freezes the app after about 8 seconds. No crash, no error, no warning. The app looks fine and counts nothing. Starting an `HKWorkoutSession` tells the system the person is exercising, and the app keeps running.

**Evidence.** Without a session: **79% of elapsed time lost.** With one: **1.2%.** Measured twice, 481 seconds apart, so the loss is proportional to time and not a start-up cost.

**What it changed.** The workout session is not optional and not a feature. It is the precondition for everything else in the project.

---

## L2 — Surviving a crash

**Question.** What has to be true for a race to survive the app dying?

**Finding.** Three things. The system does not restart a dead app, so there is no safety net. Recovery works once, at launch, before anything else creates a session. Every step must be written to disk the moment it happens.

**Evidence.** The app was killed at **three separate moments inside the save**, including halfway through writing the file. It never lost a segment. On restart, elapsed time had continued through the interval when the process did not exist.

**What it changed.** Saving works by writing a new copy and then swapping it in. A crash leaves either the old file or the new one, never a broken half.

---

## L3 — The crossing

**Question.** Do I have to build a connection from the watch to the phone?

**Finding.** No. Apple already carries it. A finished workout reaches the phone on its own, and my own notes attached to that workout travel with it.

**Evidence.** Arrived in **under 14 seconds** with the phone **locked** and **in another room.** All four of my custom keys arrived intact.

**What it changed.** I predicted this would only work with the phone awake and nearby, and I was wrong. That matters for real use: athletes leave their phone in a locker, and the record still arrives.

---

## L4 — The part I did not build

**Question.** Where does the free crossing break, so I know what I still have to build?

**Finding.** It does not break. A full-length race crossed complete, so every capability my planned transport was meant to provide had already been removed by measurement.

**Evidence.** **25 segments, 601 characters** sent and received. Nothing truncated.

**What it changed.** L4 was planned as the largest build in the project and produced no transport code. I wrote a decision record explaining why building it would be waste. Deleting the work was only safe because I had measured first.

---

## L5 — Honest representation

**Question.** Can I trust my own numbers?

**Finding.** Not equally. Numbers come in four kinds, and the split is not the obvious one between recorded and calculated. It sits inside "recorded": a total duration and a station start time are both timestamps, but one came from a sensor and the other from a tired person pressing a button.

| MEASURED | The device recorded it alone — heart rate, energy, total time |
|---|---|
| **MARKED** | A human pressed a button — every station boundary |
| **DERIVED** | Worked out from those — every station duration |
| **UNSUPPORTED** | The data cannot answer it at all |

**Evidence.** I double-tapped by accident in a real session and recorded a rest of **2.03 seconds.** Every automatic check reported the data intact.

**What it changed.** I found a fifth kind: **ASSUMED.** The screen said SkiErg when I had done burpees, because the app stated a station name it had never observed.

---

## L6 — The platform's own idiom

**Question.** Is the way I record structure the way the platform records it?

**Finding.** No. I stored the race as one line of text. Apple stores structure as events attached to the workout. I migrated to Apple's way, and doing so immediately exposed a bug my text version had been hiding: the last station was absorbing all leftover time.

**Evidence.** There is no HYROX workout type in HealthKit. One metadata key naming the brand made **Apple's own Health app display the workout as HYROX**, while keeping my own live screens.

**What it changed.** I checked Apple's Workout app and pressed its lap button twice **0.333 seconds apart.** It recorded both without complaint. Apple has not solved accurate mid-effort marking either, so solving it is a contribution rather than catching up.

---

## The thread through all six

**A green signal hid a failure eleven times.** The app looked healthy while losing 79% of the race. Permission reported success while reading was blocked. My integrity check passed an impossible 2-second rest. The word `AGREE` printed when nothing had been compared.

Several of these were inside the instruments I built to catch problems. Two were my own errors, and both are written down rather than removed.

**A passing test only proves what it actually checked.** My checks now state what they examined and what they did not.
