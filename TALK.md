# Challenge 4 — 10 minute talk

Four parts, matching the speaker's talking points. Timings are a guide.

---

# 1 · What I chose to grow
**≈1 minute**

My challenge was: **learn to build connected data tracking across watchOS and iOS.**

My growth focus statement was this.

> Learn how connected data tracking works across watchOS and iOS — background execution, data ownership, transport reliability, and source of truth — by producing one complete workout captured on the watch and reviewed on the phone, together with a written explanation of each decision and a log of what I predicted wrongly, as my learning evidence, so that I am able to build a working data crossing between watch and phone that holds through airplane mode, screen-off and a force-quit, and explain why it holds, by the end of the 10-day Act phase.

The important part of that sentence is **"a log of what I predicted wrongly."** I put it in on purpose. I will come back to it.

I train HYROX. It is eight runs and eight stations, and the rest between them counts. I wanted an app that records the race on the watch and explains it honestly on the phone.

---

# 2 · My starting point, and where I am now
**≈2 minutes**

**My starting point was zero.** Every technology in this challenge was new to me. HealthKit, workout sessions, background execution on watchOS, moving data between two devices. I had used none of them.

So I did not plan to build first. **I planned to predict first.**

I made a workbook. Before every experiment I wrote down what I expected to happen. After it ran, I wrote what actually happened, and then the gap between the two. **The rule was that a prediction can never be edited after the test.** A wrong prediction is the evidence. It is not a mistake to hide.

**Where I am now, after ten days:**

- Six cycles, twenty-four experiments
- Everything tested on a real Apple Watch and a real iPhone, not a simulator
- A watch app that records a HYROX race and a phone app that reviews it
- A workbook of two thousand lines, with every prediction I got wrong still in it

And one number that surprises people. **I predicted wrongly a lot, and the wrong predictions were worth more than the right ones.**

Here is the clearest example. Cycle 4 was planned as the largest build in the project: a connection to move data from the watch to the phone. **I built none of it.** Cycle 3 had already measured that Apple moves the data for free — in under fourteen seconds, with the phone locked and in another room. So Cycle 4 stopped being a build and became a decision. I wrote a document explaining why building it would be waste.

**The largest planned task in my project produced zero code, and that is the outcome I am most confident about** — because I only knew it was safe to delete after I had measured it.

---

# 3 · What and how I learned
**≈4 minutes — this is the main part**

I will take one moment, because it changed everything after it.

## The 2.03 second rest

In Cycle 5 I stopped tapping through tests at my desk and ran a **real session**. Real running, real burpees, real sled work. I was out of breath and pressing a button on my wrist between stations.

At the second rest, **I pressed the button twice by accident.**

My app recorded a rest of **2.03 seconds.** That is impossible. A rest between HYROX stations is never two seconds.

**And every single check I had written said the data was fine.** The timestamps were in order. Nothing was negative. Everything was inside the workout. My integrity check reported INTACT.

## Why that mattered

I had been treating all my numbers as equally solid. They are not. I learned there are four kinds, and the important line is not where I expected.

| **MEASURED** | The watch recorded it alone — heart rate, energy, total time |
|---|---|
| **MARKED** | A human pressed a button — every station boundary |
| **DERIVED** | Worked out from those — every station duration |
| **UNSUPPORTED** | The data cannot answer it at all |

The obvious split would be recorded versus calculated. **That split is wrong.** The real split sits inside "recorded". My total workout time and my station start time are both timestamps and look identical on screen. But one came from a sensor, and the other came from **a tired person pressing a button.** Those are not the same level of trust, and my screen was showing them the same way.

Then I found a fifth kind that no plan of mine contained. My app printed **"SkiErg"** when I had actually done burpees — because the app **assumed** the station, and never asked. I called that one **ASSUMED**.

## The pattern underneath it

Once I saw it, I could see it everywhere in my own project. **A green signal hiding a failure. It happened eleven times.**

- The app looked completely healthy while losing **79%** of the race, with no crash and no error.
- Permission reported success while reading was actually blocked, because HealthKit returns an empty list instead of an error.
- My integrity check passed that impossible two second rest.
- My comparison tool printed the word **AGREE** when it had compared nothing.

Several of these were inside **the very tools I built to catch problems.** And two of them were **my own mistakes** — I once concluded that HealthKit had deleted all my workouts, and they came back the same day, unchanged. That retraction is still in my workbook.

**What I actually learned, in one sentence: a passing test only proves what it actually checked.**

So I changed my checks. They now state what they looked at and what they did not. Instead of printing `AGREE`, my tool now prints:

> `AGREE — 6 durations compared; the final one skipped, because there is nothing after it to compare against`

That is the same word doing honest work.

## One more thing that gave me confidence

Late in the project I checked **Apple's own Workout app.** I pressed its lap button twice, **0.333 seconds apart.** It recorded both, with no complaint and no flag.

**Apple has not solved this either.** So the problem I hit is not me being a beginner. Solving it properly is a real contribution.

---

# 4 · Learning Evidence
**≈2 minutes**

**The app.** A watch app that records a HYROX race and survives a force quit, and a phone app that reviews it and labels where every number came from.

**The workbook.** Two thousand lines. Every prediction written before the test, every result after, and every gap between them. Including the ones where I was wrong, and the two conclusions I had to retract.

**The decision records.** Three written documents, including the one that says do not build the transport, with the conditions that would reverse it.

**The commits.** Every finding is a commit with the reasoning in the message, so the history is the record.

**On the device, and I can show this live:** three clocks side by side during a workout. One counts by timer and falls behind when the watch suspends the app. Two count from timestamps and stay correct. **That single screen is my whole first cycle, happening live.**

**And one line in Apple's Health app.** There is no HYROX workout type in HealthKit. I added one metadata key, and **Apple's own Health app now displays my workout as HYROX** — while I keep my own live screens.

## Where I go next

I am going to design the screens on paper in Sketch **before** writing more interface code. Everything so far went straight into code, and my two worst problems are design problems that paper would have caught immediately.

I built an undo, and **when I made the mistake mid-race, I did not use it** — because it was on a different screen.

And my app still tells the athlete what station they did, instead of asking.

**Thank you.**
