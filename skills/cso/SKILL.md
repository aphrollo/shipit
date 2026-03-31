---
name: cso
description: When shipping code that handles user input, authentication, data storage, or external APIs — run a dedicated security audit. OWASP Top 10 + STRIDE threat modeling.
---

# CSO — Security Audit

**Invoke after /review for any code touching auth, user input, data storage, APIs, or infrastructure.**

## OWASP Top 10 Checklist

| # | Vulnerability | What to check |
|---|--------------|---------------|
| A01 | Broken Access Control | Can users access resources they shouldn't? Missing auth checks on endpoints? |
| A02 | Cryptographic Failures | Secrets in plaintext? Weak hashing? HTTP instead of HTTPS? |
| A03 | Injection | SQL, NoSQL, OS command, LDAP injection? All inputs parameterized? |
| A04 | Insecure Design | Business logic flaws? Missing rate limits on sensitive ops? |
| A05 | Security Misconfiguration | Default credentials? Verbose error messages leaking internals? Debug mode on? |
| A06 | Vulnerable Components | Known CVEs in dependencies? Outdated libraries? |
| A07 | Auth Failures | Weak passwords allowed? No brute-force protection? Session fixation? |
| A08 | Data Integrity Failures | Unsigned updates? Deserialization of untrusted data? CI/CD tampering? |
| A09 | Logging Failures | Security events not logged? Sensitive data in logs? Logs not monitored? |
| A10 | SSRF | Can user-controlled URLs trigger server-side requests to internal services? |

## STRIDE Threat Model

For each component touched by the change:

| Threat | Question |
|--------|----------|
| **S**poofing | Can an attacker impersonate a user or service? |
| **T**ampering | Can data be modified in transit or at rest? |
| **R**epudiation | Can actions be performed without audit trail? |
| **I**nformation Disclosure | Can sensitive data leak via errors, logs, or side channels? |
| **D**enial of Service | Can the change be abused to exhaust resources? |
| **E**levation of Privilege | Can a regular user gain admin access? |

## Output

```
SCOPE: [what was audited]
OWASP FINDINGS: [list with severity — CRITICAL/HIGH/MEDIUM/LOW]
STRIDE FINDINGS: [list with severity — CRITICAL/HIGH/MEDIUM/LOW]
VERDICT: PASS / FAIL
```

## Gate (pass/fail conditions)

- **PASS**: No CRITICAL or HIGH findings. MEDIUM/LOW are advisory (surface to user, don't block).
- **FAIL**: Any CRITICAL or HIGH finding. Must be fixed before /ship.
- **3 CSO cycles without PASS → STOP.** Escalate: "Security audit has failed 3 times. Architecture may need security-focused redesign."

CRITICAL/HIGH findings in CSO are **non-overridable** — unlike code review, there is no tiebreaker for security. Fix or redesign.

## When to Skip

- Pure refactors with no behavior change
- Docs-only changes
- Frontend-only styling changes with no data handling

## Failure Paths

| Scenario | Detection | Severity | Recovery |
|----------|-----------|----------|----------|
| CRITICAL injection vulnerability | Unparameterized query, command injection | Critical | STOP. Fix immediately. Re-audit after fix. |
| Missing auth on endpoint | No access control check | Critical | Add auth middleware/check. Re-audit. |
| Secrets in code/logs | Credentials in plaintext, API keys logged | Critical | Remove, rotate secrets, scrub git history if committed. |
| Outdated dependency with CVE | Known vulnerability in dependency | High | Update dependency. If breaking change, return to /plan. |
| Missing rate limiting | Sensitive operation without throttling | Medium | Add rate limiting. Advisory — doesn't block. |
| Verbose error messages | Stack traces or internals exposed to user | Low | Sanitize error output. Advisory. |

## Next → /benchmark (if frontend) or /ship
