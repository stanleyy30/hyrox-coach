# Challenge 4 — Synthesis, Cycles 1–6

Six cards. Each is short enough to paste into the canvas and say from memory.

**The project in one sentence.** I set out to build an app that records a HYROX race on the watch and explains it on the phone. I tested every assumption before building. Most were wrong, and being wrong saved me from writing code I did not need.

---

## L1 — Staying alive

**Question.** Why does a watch app stop recording?

**Finding.** When the wrist drops, watchOS freezes the app after about 8 seconds. No crash, no error, no warning. The app looks fine and counts nothing. Starting an `HKWorkoutSession` tells the system this person is exercising, and the app keeps running.

**Evidence.** Without a session, **79% of elapsed time lost.** With one, **1.2%.** Measured twice, 481 seconds apart, so the loss grows with time and is not a start-up cost.

**Say this carefully.** Those percentages measure **how often the app was allowed to run.** They do not measure the accuracy of any recorded time. Every time in the race record is a subtraction between two timestamps, so **the record was always exact.** The percentages come from a counter I built on purpose to detect the freezing.

**What it changed.** The workout session is not a feature. It is the precondition for everything else. I also handed the on-screen clock to the system, so the display cannot lag either.

---

## L2 — Surviving a crash

**Question.** What has to be true for a race to survive the app dying?

**Finding.** Three things. The system does not restart a dead app, so there is no safety net. Recovery works once, at launch, before anything else creates a session. Every step must be written to disk the moment it happens.

**Evidence.** I killed the app at **three separate moments inside the save**, including halfway through writing the file. It never lost a segment. On restart, elapsed time had continued through the interval when the process did not exist.

**What it changed.** Saving works by writing a new copy first, then swapping it in. A crash leaves either the old file or the new one, never a broken half.

---

## L3 — The crossing

**Question.** Do I have to build a connection from the watch to the phone?

**Finding.** No. Apple already carries it. A finished workout reaches the phone by itself, and my own notes attached to that workout travel with it.

**Evidence.** Arrived in **under 14 seconds**, with the phone **locked** and **in another room.** All four of my custom keys arrived intact.

**What it changed.** I predicted this would only work with the phone awake and nearby. I was wrong, and that matters for real use: athletes leave their phone in a locker, and the record still arrives.

---

## L4 — The part I did not build

**Question.** Where does the free crossing break, so I know what I still have to build?

**Finding.** It does not break. A full-length race crossed complete, so every capability my planned transport was meant to provide had already been made unnecessary.

**Evidence.** **25 segments, 601 characters** sent and received, nothing truncated. The record also **survives deleting the app entirely** — I uninstalled it, reinstalled it, and the sessions were still in Apple's Health app.

**What it changed.** L4 was planned as the largest build in the project and produced no transport code. I wrote a decision record explaining why building it would be waste. Deleting the work was only safe because I had measured first.

**One catch, found on the same test.** The data survives deletion. **The permission does not.** After reinstalling, the app could not read the workouts until I granted access again — and a refused permission returns an empty list with no error, which looks exactly like having no workouts.

---

## L5 — Honest representation

**Question.** Can I trust my own numbers?

**Finding.** Not equally. They come in four kinds, and the important split is not the obvious one between recorded and calculated. It sits inside "recorded": a total duration and a station start time are both timestamps, but one came from a sensor and the other from a tired person pressing a button.

| Kind | Meaning |
|---|---|
| **MEASURED** | The device recorded it alone — heart rate, energy, total time |
| **MARKED** | A human pressed a button — every station boundary |
| **DERIVED** | Worked out from those — every station duration |
| **UNSUPPORTED** | The data cannot answer it at all |

**Evidence.** I double-tapped by accident in a real session and recorded a rest of **2.03 seconds** — impossible. Every automatic check reported the data intact.

**What it changed.** I found a fifth kind: **ASSUMED.** The screen said SkiErg when I had done burpees, because the app stated a station name it had never observed.

---

## L6 — The platform's own idiom

**Question.** Is the way I record structure the way the platform records it?

**Finding.** No. I stored the race as one line of text. Apple stores structure as proper events attached to the workout. I migrated to Apple's way, and doing so **immediately exposed a bug** my text version had been hiding: the last station was absorbing all the leftover time.

**Evidence.** There is no HYROX workout type in HealthKit. One metadata key naming the brand made **Apple's own Health app display my workout as HYROX**, while I kept my own live screens. The alternative approach would have given the same name and taken the live experience away.

**What it changed.** I checked Apple's own Workout app and pressed its lap button twice **0.333 seconds apart.** It recorded both without complaint. **Apple has not solved accurate marking mid-effort either**, so solving it is a contribution rather than catching up.

---

## The thread through all six

**A green signal hid a failure thirteen times.**

- The app looked healthy while losing 79% of the race.
- Permission reported success while reading was actually blocked.
- My integrity check passed an impossible 2-second rest.
- The word `AGREE` printed when nothing had been compared.

Several of these were inside the instruments I built to catch problems. **Two were my own mistakes, and both are written down rather than removed.**

**What I learned: a passing test only proves what it actually checked.** My checks now state what they examined and what they did not.

---

## Where this goes next

Design the screens on paper, in Sketch, before writing more interface code. Everything so far went straight into code, and my worst problems are design problems that paper would have caught.

Three questions the drawing has to answer:

1. **Where does correction live**, so it can be reached one-handed, mid-effort? My undo exists and I did not use it, because it was on another screen.
2. **How does the athlete say what they actually did**, so the app stops asserting station names it never observed?
3. **What does the review screen show when permission is missing**, so it does not look identical to having no workouts?
