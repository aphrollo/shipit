---
name: writing-skills
description: When creating or modifying skills in ~/.claude/skills/. TDD applied to documentation — write failing test (baseline behavior without skill), write skill, verify agent complies, refine.
---

# Writing Skills — TDD for Documentation

**Skills are code. Test them like code.**

## RED: Baseline Test

Before writing or modifying a skill:
1. Describe a pressure scenario where the skill would matter
2. Run the scenario WITHOUT the skill (or with the old version)
3. Document what the agent does wrong — exact rationalizations, skipped steps, bad outputs

If the agent already does the right thing without the skill, you don't need the skill.

## GREEN: Write Minimal Skill

Address the specific failures from the baseline:
- Each rationalization gets an explicit counter
- Each skipped step gets a gate
- Each bad output gets a required format

Don't add content for hypothetical cases. Address what actually failed.

## REFACTOR: Close Loopholes

Run the scenario again WITH the skill:
- Agent complies? Good — look for new rationalizations
- Agent found a workaround? Add explicit counter
- Agent follows letter but not spirit? Tighten the language

Repeat until bulletproof.

## Skill Structure

```yaml
---
name: skill-name-with-hyphens
description: When [specific trigger] — [what it does]. Active voice, routing language.
---
```

- Description: start with "When..." not "Use when..."
- Under 500 words total (skills load into context)
- One clear purpose per skill
- Flowcharts only for non-obvious decisions

## Anti-Patterns

- Writing skills without testing: same as writing code without tests
- "This is obvious, no need to test": the #1 cause of bad skills
- Multi-purpose skills: split into focused skills
- Skills that duplicate CLAUDE.md: put project rules in CLAUDE.md, reusable techniques in skills
