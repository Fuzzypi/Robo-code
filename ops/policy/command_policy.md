# Command Policy

## Overview
This document outlines the command policy enforced by the AOS system to ensure safe and controlled execution of automated scripts.

## Denylist
The following commands are strictly prohibited:
- `rm -rf`
- `sudo`
- Shell forks (e.g., `:(){ :|:&; : }`)
- Unapproved env dumps
- Keychain access
- Network commands such as `curl` or `wget`, unless explicitly enabled in metadata

## Allowlist
Only commands specified in the allowlisted section of the `READY_<JOB>.json` metadata file are permitted.

## Enforcement
All scripts and commands are checked against this policy at runtime, and any breaches will halt execution with clear error messages.