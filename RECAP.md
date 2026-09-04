# Challenge 4 — What I Learned, In Plain Words

**Challenge:** Learn to build connected data tracking across watchOS and iOS.

**The whole project in one sentence.** I set out to build an app that records a HYROX race on the watch and explains it on the phone. I tested every assumption before building. Most of my assumptions were wrong, and being wrong saved me from writing code I did not need.

---

## The one-line version of each cycle

| Cycle | I asked | I found |
|---|---|---|
| **L1** | Why do watch apps stop recording? | The screen turns off and the app is frozen. A workout session stops that. |
| **L2** | What if the app crashes mid-race? | Nobody saves you. You must save yourself, after every single step. |
| **L3** | Does the watch send data to the phone? | Yes, by itself. I did not have to build anything. |
| **L4** | Where does that break? | It does not break. So I deleted a whole planned feature. |
| **L5** | Is my data honest? | No. Some numbers are real. Some are just me pressing a button. |
| **L6** | Does Apple do it the way I did? | No. I switched to Apple's way, and it exposed a bug in mine. |

---

# L1 — Staying alive

**The question.** Why does a watch app stop counting?

**The answer.** When you drop your wrist, the watch freezes the app after about **8 seconds**. The app does not crash. It does not show an error. It just quietly stops counting, and you have no idea.

Starting a **workout session** tells the watch "this person is exercising, keep me running."

**The number to remember:**

| | Without workout session | With workout session |
|---|---|---|
| Time lost | **79%** | **1.2%** |

**The surprise.** Nothing warned me. No error, no crash, no message. The app looked perfectly fine while losing four-fifths of the race.

---

# L2 — Surviving a crash

**The question.** If the app dies in the middle of a race, what happens?

**The answer.** Three things I had to learn:

1. **Nobody restarts your app.** I thought the watch would bring it back. It does not. I had to open it by hand both times.
2. **You can recover, but only once, at the very start.** Asking twice fails.
3. **You must save the time of every step, immediately, every time.**

**The number to remember.** I killed the app on purpose at **3 different moments** while it was saving. It never lost data once.

**The surprise.** The way I save files works like this: write a new copy first, then swap it in. So a crash either leaves the old copy or the new copy — never a broken half-copy.

---

# L3 — Getting to the phone

**The question.** Do I need to build a connection from the watch to the phone?

**The answer.** **No.** Apple already does it. I finished a workout on the watch and it appeared on the phone by itself.

**The number to remember:** it arrived in **under 14 seconds**, with the phone **locked** and **in another room**.

**The surprise.** I predicted this would only work if the phone was awake and nearby. I was wrong, and being wrong was good news. Athletes leave their phone in a locker, and it still works.

I can also attach my own notes to the workout, and those travel too.

---

# L4 — The part I did not build

**The question.** Where does Apple's free connection break, so I know what I still have to build myself?

**The answer.** **It does not break.** I sent a full-length race — **25 steps, 601 characters** — and every bit arrived.

**What I did.** L4 was planned as the biggest build in the project. I wrote **zero** transport code. Instead I wrote a document explaining why building it would be waste.

**The surprise.** The most valuable thing I did all project was delete work. I only knew it was safe to delete because I had measured it first.

---

# L5 — Being honest about data

**The question.** Can I trust my own numbers?

**The answer.** Not all of them. They come in **four kinds**:

| Kind | What it means | Example |
|---|---|---|
| **MEASURED** | The watch recorded it by itself | Heart rate, calories, total time |
| **MARKED** | I pressed a button, tired and out of breath | When each station started |
| **DERIVED** | Worked out from the two above | How long each station took |
| **UNSUPPORTED** | The data simply cannot tell you | Whether my form was good |

**The number to remember.** I ran a real session and pressed the button twice by accident. It recorded a rest of **2.03 seconds** — impossible. Every automatic check said the data was fine.

**The surprise.** A timestamp looks equally solid whichever way it was made. But "the watch measured this" and "a tired human pressed a button" are very different levels of trust, and the screen showed them identically.

I also found a **fifth kind: ASSUMED.** My app printed "SkiErg" when I had actually done burpees — because the app assumed, and never asked.

---

# L6 — Doing it Apple's way

**The question.** Is the way I record the race the way Apple records a race?

**The answer.** **No.** I stored my steps as a line of text. Apple stores them as proper **events** attached to the workout.

So I switched to Apple's way. And doing that **immediately exposed a bug** in my phone screen that my text version had been hiding — the last station was absorbing all the leftover time.

**The number to remember.** There is no HYROX workout type in Apple's system. I added **one line** naming the brand, and now Apple's own Health app displays my workout as **HYROX**.

**The surprise.** I checked Apple's own Workout app. I pressed its lap button twice quickly — **0.333 seconds apart** — and it recorded both without complaint. **Apple has not solved this either.** So fixing it properly is a real contribution, not catching up.

---

# The one thing that happened over and over

**A green light hid a failure. Seventeen times.**

- The app looked fine while losing 79% of the time.
- Permission looked granted when reading was actually blocked.
- My "everything is fine" check passed on an impossible 2-second rest.
- The word `AGREE` appeared when nothing had actually been compared.

Some of these were inside the very tools I built to catch problems. **Two of them were mistakes I made myself, and I wrote both down instead of hiding them.**

**What I learned:** a passing test only proves what it actually checked. So now my checks say what they looked at, and what they did not.

---

# Where I am now

**All 6 cycles complete. 24 experiments. Everything tested on a real Apple Watch and a real iPhone, not a simulator.**

**Proven by measurement:**
- Workout session is required — 79% loss without it
- Data survives the app crashing
- Data reaches the phone by itself, locked, in another room
- Data survives **deleting the app completely**
- Apple's Health app shows it as HYROX

**Next:** design the screens in Sketch, on paper first. My two worst problems are both design problems, and both would have been obvious on paper:

1. The undo button is on a different screen, so when I made a mistake mid-race I did not use it.
2. The app says the station name instead of asking me what I actually did.
