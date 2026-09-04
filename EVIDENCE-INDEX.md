# Evidence index — every instance of the pattern

The talk claims a recurring failure: **a signal that reported success while the interesting failure hid underneath it.** This file enumerates every instance, so the claim is checkable rather than asserted. Line numbers refer to `WORKBOOK.md`.

The workbook distinguishes two families. Both are the same underlying error — trusting the output of an instrument as evidence about the subject — but they run in opposite directions.

---

## Family A · A success signal concealing a failure

| # | Where | The signal | What was actually true |
|---|---|---|---|
| A1 | E1.1 · L386 | App running normally, no crash, no error | **79.4%** of elapsed time was not being counted |
| A2 | P2 sabotage · L384 | Build succeeded with no error or warning | Missing usage description; instant termination on authorise, **before any `catch` could run** |
| A3 | P5 denial · L385 | Authorisation reported success | Read permission was denied. Query returned an empty set with no error |
| A4 | E1.0b · L112 | Aggregate verdict **CONFIRMED** | Two queries collapsed into one verdict. Workouts returned data, so the heart-rate denial underneath stayed invisible |
| A5 | E1.0 · L147 | **PASS** — wrote a sample and read it back | Evidenced write and self-read only. HealthKit always lets an app read its own data, so this could not evidence read access |
| A6 | E1.2 · L273 | "Workout running" | True, and it does not mean every timer fired. The weaker claim was being read as the stronger one |
| A7 | Aug 20 · L1003 | `App installed:` and shell exit code 0 | The install had failed; the old binary was then launched instead |
| A8 | Aug 21 · L2126 | Ticks continued through wrist-down | A debugger was attached. The run measured the debugger, not watchOS |
| A9 | E2.2b · L843 | Nothing failed, no error appeared | The experiment nearly passed for the wrong reason. The only signal was a byte count that did not fit |
| A10 | E4.0 · L1259 | Integrity check reported **INTACT** | Every offset was negative. The check tested completeness and never tested plausibility |
| A11 | E5.0 · L1570 | Every automatic check passed | A double tap recorded a **2.03 s** roxzone. Impossible, and nothing in the data revealed it |
| A12 | E5.1 · L1657 | Apple's own **MEASURED** metadata | `HKWeatherHumidity: 4900 %`. Humidity cannot exceed 100% |
| A13 | E6.2 · L2059 | **`AGREE`** | Segment *names* matched. No durations were compared, and nothing said so |
| A14 | Sep 4 · L2134 | A `NavigationLink` drawing its chevron and highlighting on touch | No `NavigationStack` existed. It navigated nowhere |
| A15 | Sep 4 · L2133 | A `Section` heading rendering almost correctly | Nested inside a `VStack` outside any `List`. SwiftUI degrades it silently to a plain stack |

## Family B · A null result treated as evidence of absence

| # | Where | The signal | What was actually true |
|---|---|---|---|
| B1 | Aug 24 · L706 | A grep returned **0 matches** | The pattern was malformed — `\|` alternation used with `-E`. The rationale was present all along. **My error** |
| B2 | Sep 1 · L1699 | "Query succeeded: 20 workout(s) found" | None of this app's workouts were among them. Concluded HealthKit had deleted them; they returned the same day with identical data. **My error, retracted in the workbook** |

---

## Count

**17 documented instances: 15 in Family A, 2 in Family B.**

**Where they came from:**

| Source | Count |
|---|---|
| Apple's frameworks and tools reporting success | 8 |
| Instruments built in this project to detect exactly this | 5 |
| My own reasoning errors, both retracted in place | 2 |
| Test conditions invalidating a run | 2 |

**The five in the third row are the ones worth defending.** A2, A5, A9, A10 and A13 were all produced by code written specifically to catch dishonest results, and each was dishonest in the same way it was built to prevent.

---

## Why the number moved

Earlier drafts of the talk said eleven, then twelve, then thirteen. Those figures came from ordinals assigned inside the workbook as instances were found — it names a "third", a "tenth" and a "twelfth", and never names an eleventh. The count was never enumerated, only incremented.

Building this index is what produced an auditable figure. **The claim was correct in shape and wrong in size, and it was wrong because it had never been checked** — which is the same error the index is about.
