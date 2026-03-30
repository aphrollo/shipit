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
OWASP FINDINGS: [list with severity]
STRIDE FINDINGS: [list with severity]
VERDICT: SECURE / NEEDS FIX (list specific issues)
```

## When to Skip

- Pure refactors with no behavior change
- Docs-only changes
- Frontend-only styling changes with no data handling

## Next → /benchmark (if frontend) or /ship
