---
name: improve-codebase-architecture
description: Explore a codebase looking for shallow modules, tangled coupling, and premature extraction, then propose deepening candidates. Auto-activate when the user asks to improve code architecture, clean up the codebase, find refactoring candidates, or says tests and changes are getting harder. Best run once a week or after a surge of new development.
---

# Improve Codebase Architecture

A well-structured codebase has clear module boundaries and deep modules. Agents (and humans) make far better changes in a deep-module codebase than in a shallow one. This skill finds the spots where the architecture is fighting you and proposes targeted deepening.

## What to look for

Walk the repo and hunt for these smells. For each one you find, record the file, the smell, and a concrete deepening proposal.

### 1. Bounce navigation

*Symptom*: understanding one concept requires opening five or six files in sequence, each a few lines long, each calling the next.

*Cause*: a concept was sliced into too many tiny modules, usually for "reusability" that never materialized.

*Fix*: collapse the chain into one deeper module with a single clear entry point. Delete the intermediate files.

### 2. Extracted-for-testability pure functions

*Symptom*: a file full of pure helpers exists only so tests can call them directly. Real bugs hide in the untested code that composes them.

*Cause*: the design treated "easy to unit test" as the goal instead of "easy to verify correct behavior".

*Fix*: inline the helpers back into their callers and test the real composed behavior at the boundary.

### 3. Tight coupling across module lines

*Symptom*: two "separate" modules import each other's internals, share mutable state, or must be changed in lockstep.

*Cause*: the boundary was drawn in the wrong place.

*Fix*: either merge them or redraw the boundary so all cross-module traffic goes through a thin documented interface.

### 4. Shallow modules

*Symptom*: a module's public interface is almost as wide as its implementation. Reading the interface does not save you from reading the implementation.

*Cause*: the module wraps rather than abstracts.

*Fix*: push more logic inside. A good module hides substantial complexity behind a narrow surface.

### 5. Dead seams

*Symptom*: interfaces, abstract classes, or plugin points with exactly one implementation. No one else has ever plugged in.

*Cause*: speculative extensibility.

*Fix*: delete the seam. Inline the single implementation. If a second one ever appears, extract then.

## Process

1. **Scope the walk.** Ask the user which area of the codebase to focus on, or walk the most-changed files from the last 30 days of git log.
2. **Read broadly before proposing anything.** Build a mental map of the module graph first. Do not start fixing as you go.
3. **Collect candidates** into a list. Each entry: location, smell category, one-paragraph deepening proposal.
4. **Rank** by impact: how many future changes will this make easier?
5. **Present the top five** to the user. Do not start refactoring unless the user picks a candidate to execute on.

## Rules

- Do not rewrite anything during the walk. This skill is analysis, not execution.
- Ranking matters more than quantity. Five real candidates beat twenty speculative ones.
- If you cannot name a concrete future change that a refactor would make easier, drop it from the list. Refactors without a named beneficiary are waste.
- Run this skill periodically — once a week or after a surge of new development is the right cadence. Running it every day is noise.
