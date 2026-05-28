---
name: factcheck
description: |
  Anti-hallucination protocol based on Anthropic's official "Reduce Hallucinations"
  guide. Forces ground-before-answer and self-audit-after-answer workflows.
  Two modes: (1) /factcheck — audit the assistant's PREVIOUS reply, retract
  unsupported claims; (2) /factcheck <question> — answer the question under
  strict grounding rules (quote first, then reason, mark uncertainty).
  Use when: "factcheck", "verify your last answer", "no hallucination",
  "ground this", "are you sure", "审一下", "别瞎编", "核实".
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - WebFetch
  - WebSearch
  - Edit
  - Write
---

# /factcheck — Anti-Hallucination Protocol

Source of truth: Anthropic docs, *Reduce Hallucinations*
(platform.claude.com/docs/zh-CN/test-and-evaluate/strengthen-guardrails/reduce-hallucinations).

## When to use which mode

- **No argument** (`/factcheck`) → AUDIT MODE. The user wants you to re-examine
  the assistant message immediately preceding this skill invocation.
- **With argument** (`/factcheck <question or task>`) → GROUNDED ANSWER MODE.
  Answer the given question under the strict protocol below.

If unsure which mode applies, ask the user once with AskUserQuestion.

---

## AUDIT MODE — audit the previous reply

Goal: every factual claim in the previous reply must have a verifiable source,
or be retracted / softened.

### Step 1 — Enumerate claims

List every **factual claim** from the previous reply as a numbered table:

| # | Claim (verbatim or close paraphrase) | Type | Stated source (if any) |
|---|--------------------------------------|------|------------------------|

Claim types:
- `code-ref` — "file X exists / function Y takes arg Z / line N does W"
- `api-ref` — library, CLI flag, config key, protocol behavior
- `external` — web/doc/spec content
- `inference` — derived conclusion (e.g. "therefore this is a bug")
- `recommendation` — suggested action

Skip pure opinion, hedged statements ("might", "could"), and meta-commentary.

### Step 2 — Verify each claim

For each row, run the cheapest sufficient verification:

| Claim type | Verification |
|------------|--------------|
| `code-ref` | Read / Grep the exact file. Confirm path + line + content. |
| `api-ref`  | Grep the codebase OR WebFetch authoritative docs. No "I remember". |
| `external` | WebFetch the URL. If no URL was cited, claim fails. |
| `inference`| Re-check that the premises (which are other claims) survived verification. |
| `recommendation` | Confirm the recommended file/command/flag actually exists. |

Run independent verifications in parallel where possible.

### Step 3 — Verdict table

Add columns to the table:

| # | Claim | Verdict | Evidence | Action |
|---|-------|---------|----------|--------|
|   |       | ✅ supported / ⚠️ partial / ❌ unsupported / 🤷 unverifiable |  |  |

- ✅ — keep as-is
- ⚠️ — rewrite with the precise scope that IS supported
- ❌ — retract explicitly ("Correction: my earlier claim that X was wrong, because…")
- 🤷 — downgrade to "I'm not sure; you'd need to check Y"

### Step 4 — Issue corrections

Output a **Corrections** section that the user can act on directly. Format:

```
## Corrections to previous reply

- ❌ Claim N: <verbatim claim>
  Why wrong / unverified: <one line>
  Replace with: <corrected statement or "(retracted)">

- ⚠️ Claim M: <verbatim claim>
  Scope was too broad. Accurate version: <…>
```

If every claim survived: say so explicitly — "Audited N claims; all verified
against [list of sources]." Don't fake findings to look thorough.

### Step 5 — Root cause (only if ≥1 correction)

In one or two sentences, name the failure mode (e.g. "I cited a function name
from memory without grepping" / "I assumed the doc page contained X without
fetching it"). Do not write a long apology. The point is to inform the user
what kind of trust calibration to apply going forward.

---

## GROUNDED ANSWER MODE — answer under strict protocol

Use this whenever the user types `/factcheck <question>` or asks you to apply
the protocol to upcoming work.

### Protocol (apply in order)

1. **Restate the question** in one line so scope is unambiguous.

2. **Inventory available evidence**: list which files, docs, URLs, or tools
   could ground the answer. If the relevant material is a long document
   (>20k tokens), say so explicitly — it triggers the quote-first rule.

3. **Gather quotes first, then reason.** For each claim you'll make, fetch
   the supporting evidence BEFORE composing the answer:
   - Code claims → Read / Grep, capture `file:line` + the actual line(s).
   - Doc/web claims → WebFetch, capture URL + the relevant excerpt.
   - If no relevant evidence is found for a needed claim → say
     "No supporting evidence found" and do NOT fill the gap from memory.

4. **Compose the answer** with inline citations:
   - Code: `(see src/foo.ts:42)`
   - Web: `(per <URL>, fetched <date>)`
   - Internal reasoning step: prefix with "Reasoning:" so it's visibly
     distinct from cited fact.

5. **Mark uncertainty explicitly** where it exists:
   - "I verified X but did not verify Y — please confirm Y before relying on it."
   - "Two interpretations are consistent with the evidence: … . I'm going with
     the first because … ."

6. **Self-check before sending**: walk the draft once and ask, for each
   sentence, "is this supported by something I gathered in step 3?" Delete or
   soften anything that isn't.

7. **Closing line**: list what was verified vs. what was assumed, e.g.:
   ```
   Verified: file foo.ts exists; function bar signature; doc page X.
   Assumed (unverified): your env has Node ≥ 20.
   ```

### Hard rules (do not violate even if it lengthens the answer)

- **No phantom symbols.** Never name a function, file, CLI flag, config key,
  env var, or API endpoint that you have not just observed.
- **No paraphrased docs from memory.** If you didn't fetch it this turn,
  don't quote it. Say "I'd need to fetch X to be sure."
- **"I don't know" is a valid final answer.** Per the Anthropic doc: explicit
  uncertainty beats confident fabrication.
- **No silent scope creep.** If the answer would require assumptions beyond
  what the user gave, list the assumptions instead of silently making them.

---

## Interaction with other skills

- `verify` runs the code; `factcheck` checks the *claim*. They compose well:
  run `factcheck` on your own analysis, then `verify` to confirm runtime behavior.
- `code-review` / `critique` examine quality; `factcheck` examines truth.
- If the user asks for both depth AND grounding, suggest invoking `riper:strict`
  after `factcheck` AUDIT MODE.

## Anti-patterns this skill exists to prevent

- Citing `file:line` from memory after a previous Read scrolled out of context.
- Recommending a library function whose signature you guessed.
- Summarizing a webpage you never fetched in this session.
- Filling gaps in user-supplied documents with "common practice".
- Asserting "this will work" without having executed or read the relevant code.

## Output length

AUDIT MODE: as long as it needs to be — the claim/verdict table is the
deliverable, terseness is secondary.

GROUNDED ANSWER MODE: as terse as the evidence allows. Citations are required;
filler is not.
