# Miro synthesis cards — one paragraph each, Cycles 1–6

---

**L1 · STAYING ALIVE**

I learned that a watch app stops counting about 8 seconds after the wrist drops, with no crash and no error, and that an `HKWorkoutSession` is what keeps it running. Without a session the app lost 79% of elapsed time; with one it lost 1.2%. Those figures measure how often the app was allowed to run, not the accuracy of the record, because every recorded time is a subtraction between two timestamps. The session is not a feature. It is the precondition for the whole project.

---

**L2 · SURVIVING A CRASH**

I learned that nothing rescues a dead app. watchOS does not relaunch it, recovery works only once at launch, and every step must be written to disk the moment it happens. I killed the app at three separate moments inside the save, including halfway through writing the file, and it never lost a segment. Saving works by writing a new copy and then swapping it in, so a crash leaves either the old file or the new one and never a broken half.

---

**L3 · THE CROSSING**

I learned that I do not have to build a connection between the watch and the phone, because Apple already carries one. A finished workout reached the phone in under 14 seconds with the phone locked and in another room, and my own notes attached to that workout travelled with it. I had predicted this would only work with the phone awake and nearby, and I was wrong. That matters for real use, because athletes leave their phone in a locker and the record still arrives.

---

**L4 · THE PART I DID NOT BUILD**

I learned that measuring before building can remove the work entirely. A full-length race of 25 segments and 601 characters crossed complete, and the record survived deleting the app and reinstalling it. Every capability my planned transport was meant to provide had already been made unnecessary, so I wrote a decision record explaining why building it would be waste. L4 was planned as the largest build in the project and produced no transport code. The permission, unlike the data, does not survive deletion.

---

**L5 · HONEST REPRESENTATION**

I learned that my numbers are not equally trustworthy, and that the real division is not between recorded and calculated. It sits inside recorded: a total duration and a station start time are both timestamps, but one came from a sensor and the other from a tired person pressing a button. I classified every value as MEASURED, MARKED, DERIVED or UNSUPPORTED. Then I found a fifth kind, ASSUMED, when the screen said SkiErg and I had actually done burpees.

---

**L6 · THE PLATFORM'S OWN IDIOM**

I learned that I was recording structure in my own way rather than the platform's. I stored the race as a line of text; Apple stores it as events attached to the workout. Migrating to Apple's way immediately exposed a bug my text version had hidden. One metadata key naming the brand made Apple's own Health app display my workout as HYROX while I kept my own live screens. I then found Apple's app accepts a 0.333-second double-press without complaint, so this problem is unsolved for them too.

---

**ACT PHASE · OVERALL**

Across six cycles I predicted what would happen before every experiment, and being wrong was consistently more useful than being right. The pattern that repeated eleven times was a green signal hiding a failure: the app looked healthy while losing 79% of the race, permission reported success while reading was blocked, and my own integrity check passed an impossible 2-second rest. Several of these were inside the instruments I built to catch problems, and two were my own errors, which I recorded rather than removed. A passing test only proves what it actually checked.
