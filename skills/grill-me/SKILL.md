---
name: grill-me
description: Interview the user relentlessly to flesh out an idea before writing any code. Auto-activate when the user proposes a new feature, starts a new project, asks to build or design something, or when scope is unclear or ambiguous. Walks the design tree, resolving dependencies between decisions one by one. Do NOT activate for trivial fixes (typos, one-line changes, renames).
---

# Grill Me

Interview the user relentlessly about every aspect of this plan until you reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one by one. If a question can be answered by exploring the code base, explore the code base instead of asking.

## When to grill

Activate automatically when the user:

- Proposes a new feature ("add X", "let's build Y", "I want a Z")
- Starts a new project or non-trivial subsystem
- Describes something with unclear scope or vague requirements
- Uses Plan Mode for anything larger than a one-file change

Do NOT activate for:

- Typo fixes, one-line changes, renames, simple refactors
- Questions about existing code
- Anything the user has already scoped precisely

## How to grill

1. Identify the top of the design tree — the single thing the user is trying to build.
2. List the major decision branches under it. Do not surface all of them at once.
3. Walk the tree depth-first: pick the branch with the most downstream dependencies and resolve it first.
4. At every branch, ask ONE focused question at a time. Never batch 5 questions into one message — it dilutes the answers.
5. Before asking, check whether the code base answers the question. If it does, read the code instead of asking.
6. Track resolved decisions and open branches explicitly so nothing is forgotten.
7. Stop only when every branch has been walked to a leaf or the user explicitly calls it done.

## What a good grilling looks like

- 10–50 questions is normal for a feature of real substance
- Each question should be answerable in one or two sentences
- Questions surface trade-offs, hidden assumptions, edge cases, and integration points the user hasn't thought about yet
- You are not writing code during grilling — resist the urge to draft an implementation

## What a bad grilling looks like

- Jumping to "here's a plan" before the tree is walked
- Asking questions the code base already answers
- Asking vague, open-ended questions ("what should this look like?") instead of forced-choice ones ("A or B?")
- Stopping at the first layer of the tree instead of walking to leaves

## End state

When the grilling is complete, you and the user share a full mental model of the system to be built, with every major decision pinned down. Only then is it safe to write a spec, a plan, or code.
