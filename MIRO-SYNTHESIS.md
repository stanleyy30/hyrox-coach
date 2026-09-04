# Miro synthesis cards — Cycles 1–6
Each card covers Reflection, Review your Learning Plan, and Decide your next learning focus.

---

# L1 · STAYING ALIVE

**REFLECTION**
I learned that a watch app stops counting about 8 seconds after the wrist drops, with no crash and no error, and that an `HKWorkoutSession` is what keeps it running. Without a session the app lost 79% of elapsed time. With one it lost 1.2%. What worked was writing my prediction down before every test, because it made me notice that the app can fail while looking completely healthy. What did not work was trusting a passing result: my first authorisation test read back a sample it had written itself, which proved nothing about reading at all.

**REVIEW YOUR LEARNING PLAN**
The plan said to prove background execution before building anything. That held, and the gate passed on Day 2. One experiment had to be added that the plan did not contain, E1.0b, because the original test could not evidence what I claimed for it. The plan also assumed recovery after a force quit would be simple, and it was not.

**DECIDE YOUR NEXT LEARNING FOCUS**
Learn what has to be true for a workout to survive the app dying, because recovery failed reliably while a workout was active and I did not yet know why.

---

# L2 · SURVIVING A CRASH

**REFLECTION**
I learned that nothing rescues a dead app. watchOS does not relaunch it, recovery works only once at launch, and every step must be written to disk the moment it happens. What worked was designing the state machine on paper first, which showed that 4 awkward states carried 20 of the 26 transitions. What worked even better was deliberately crashing the app at three separate moments inside the save. It never lost a segment. What did not work was my central prediction that the system would restart the app, which was simply false.

**REVIEW YOUR LEARNING PLAN**
The plan expected to build recovery around retries. Measurement replaced that with a rule: recover exactly once, at launch, before anything creates a session. The plan did not include testing atomicity, and I added it, which is how I found the write was genuinely safe rather than assuming it.

**DECIDE YOUR NEXT LEARNING FOCUS**
Find out whether the workout reaches the phone on its own, and what actually arrives when it does, before designing anything that assumes I must move it myself.

---

# L3 · THE CROSSING

**REFLECTION**
I learned that I do not have to build a connection between the watch and the phone, because Apple already carries one. A finished workout reached the phone in under 14 seconds with the phone locked and in another room, and my own notes travelled with it. What worked was testing the worst case rather than the easy one. What did not work was my prediction that the phone had to be awake and nearby. I was wrong, and being wrong here removed a feature from the plan instead of adding one.

**REVIEW YOUR LEARNING PLAN**
The plan for the next cycle was to build a watch-to-phone transport. This cycle made that questionable, so the following cycle had to be rescoped from building to deciding. The plan's assumption that the crossing carries only physiology was also wrong, because custom metadata crossed too.

**DECIDE YOUR NEXT LEARNING FOCUS**
Find where the free crossing breaks, so I know exactly what genuinely still needs a transport of my own.

---

# L4 · THE PART I DID NOT BUILD

**REFLECTION**
I learned that measuring before building can remove the work entirely. A full-length race of 25 segments and 601 characters crossed complete, and the record survived deleting the app and reinstalling it. What worked was writing a decision record with reversal conditions instead of just abandoning the plan quietly. What did not work was my checking code: it reported the data intact while every timestamp was negative, because the seeding reused a stale start time. The bug mattered more than the result it was hiding.

**REVIEW YOUR LEARNING PLAN**
This cycle was planned as the largest build in the project and produced no transport code. That is the correct outcome, not a shortfall. The work had already been made unnecessary by earlier cycles, and I could only delete it safely because I had measured first.

**DECIDE YOUR NEXT LEARNING FOCUS**
Stop asking whether the data arrives and start asking whether it is honest, because the checks I trusted had already reported something false once.

---

# L5 · HONEST REPRESENTATION

**REFLECTION**
I learned that my numbers are not equally trustworthy, and the real division is not between recorded and calculated. It sits inside recorded: a total duration and a station start time are both timestamps, but one came from a sensor and the other from a tired person pressing a button. What worked was running genuine sessions instead of tapping through at a desk, because only real effort produced the mistake that mattered. I double-pressed by accident and recorded a 2.03-second rest, and every automatic check said the data was fine.

**REVIEW YOUR LEARNING PLAN**
The plan expected two categories, recorded and calculated. The data needed four: MEASURED, MARKED, DERIVED and UNSUPPORTED. Then a fifth appeared that no plan contained, ASSUMED, when the screen said SkiErg and I had actually done burpees. The plan also assumed the undo control would be used if a mistake happened. It was not, because it lived on another screen.

**DECIDE YOUR NEXT LEARNING FOCUS**
Design the screens on paper in Sketch before writing more interface code, because both of my worst problems are design problems that paper would have caught.

---

# L6 · THE PLATFORM'S OWN IDIOM

**REFLECTION**
I learned that I was recording structure in my own way rather than the platform's. I stored the race as a line of text; Apple stores it as events attached to the workout. Migrating to Apple's way immediately exposed a bug my text version had been hiding, where the last station absorbed all leftover time. What worked was comparing my app against Apple's own app directly. I pressed Apple's lap button twice 0.333 seconds apart and it accepted both without complaint, so this problem is unsolved for them too.

**REVIEW YOUR LEARNING PLAN**
This cycle was not in the plan. It began as a follow-up to a mentor's question and I wrote no predictions before running it, which is a real departure from the method the other five followed. It is recorded that way rather than presented as planned work. It also answered a question the plan had left open: one metadata key naming the brand made Apple's own Health app display my workout as HYROX, while I kept my own live screens.

**DECIDE YOUR NEXT LEARNING FOCUS**
Draw the live workout screen, the correction flow and the review screen in Sketch, and answer three questions with them. Where does correction live so it can be reached one-handed, mid-effort. How does the athlete say what they actually did, instead of the app asserting it. What does the review screen show when permission is missing, so it does not look identical to having no workouts.
