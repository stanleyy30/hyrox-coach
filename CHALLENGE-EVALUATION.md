# Challenge Evaluation — Challenge 4

---

## 1 · Does your challenge response meet your challenge statement? Why or why not?

**Yes, and the strongest evidence is a part I did not build.**

My challenge was to learn to build connected data tracking across watchOS and iOS. I produced two apps on real devices: a watch app that records a HYROX race and survives a force quit, and an iPhone app that reads the record back and labels where every number came from. Data crosses in under 14 seconds with the phone locked and in another room, and it survives deleting the app entirely.

Cycle 4 was planned as the largest build in the project — a watch-to-phone transport. I built none of it, because Cycles 2 and 3 had already measured that it was unnecessary. I wrote a decision record instead. The statement asked me to **learn** how connected tracking works, not to write the most code, and knowing what not to build is that learning showing up as a decision.

**Where it falls short:** I never ran a full 90-minute race end to end. The longest real session was 5 minutes 11 seconds, and the full-length payload was seeded rather than performed. I also tested on one watch, one phone, one OS version.

---

## 2 · What considerations guided your actions in each SRL phase?

**Plan.** I wrote what I expected to happen before every experiment, and I wrote predictions specific enough to be wrong. A prediction like "it will probably work" cannot teach me anything. The rule was that a prediction is never edited after the test runs.

**Execute.** Real hardware only, never a simulator, because the thing I was testing was how the operating system behaves when nobody is watching. I changed one variable at a time, and when a run was invalid I threw it out rather than keeping the number — the first E1.1 run measured the debugger instead of watchOS, so it did not count.

**Evaluate.** I treated a passing result as a claim about the test, not about the world. This mattered: my checks reported INTACT on an impossible 2.03-second rest, and printed AGREE when nothing had been compared. Both passed. Both were wrong.

**Reflect.** I kept the wrong predictions and both of my retracted conclusions in place, with the incorrect text above the correction. Removing them would have made the record look better and made it useless.

---

## 3 · Based on learning review, what could you improve, and how will you apply your key takeaway?

**What the feedback changed.** My mentor said my plan read like a building plan rather than a learning plan. She was right — it listed features. I rewrote it around learning questions, and each cycle then had something it could fail to answer. My design mentor told me to draw the screens before writing more interface code, which is why the lo-fi exists. She also told me to ask a tech mentor, and that question produced Cycle 6 and the migration to `HKWorkoutEvent`.

**What I should improve.** I shared results after cycles closed, when the predictions were already settled. Sharing mid-cycle, while a prediction is still open, would have let someone tell me my test was weak before I trusted it — which is exactly when I needed it. I also stopped writing predictions once I got curious: Cycle 6 has none, and it is the one cycle I cannot score.

**Key takeaway, applied forward.** *A passing test only proves what it actually checked.* I now make my checks state their own coverage. Instead of printing `AGREE`, my tool prints `AGREE — 6 durations compared; the final one skipped, because there is nothing after it to compare against`. I will carry that into every project: a green result must say what it looked at, and what it did not.

---

## 4 · Did Challenge 4 help you develop your SRL and become more thoughtful?

**Yes, and I can show it rather than claim it.**

I indexed every instance of the pattern this project kept finding — a signal reporting success while the interesting failure hid underneath. There are seventeen. **Five of them were produced by instruments I built specifically to catch that failure**, and I kept finding them because I had learned to look. Two were my own reasoning errors, both retracted in the workbook with the wrong text still visible above the correction.

**Why it worked.** Writing a prediction before a test forces the mental model into the open, where it can be shown wrong. Being wrong is uncomfortable and it is the fastest thing in the method: every important finding in this project came from a prediction that failed, not one that held.

**What could be improved.** The count itself is the best example. I said the pattern appeared eleven times, then twelve, then thirteen — all incremented, never counted. When I finally enumerated it, the real figure was seventeen. **The claim was right in shape and wrong in size, and it was wrong because it had never been checked** — which is precisely what the claim is about. I should have built the index the first time I made the claim.
