# AOS Workflow Rules

## Canonical Source

**All AOS edits must happen in `Robo-code` (the AOS core repository).**

App repositories only **pull** updates via git subtree. They do not push changes back except in emergency situations.

---

## Standard Workflow

### Updating AOS in an App Repo

When AOS has been updated in Robo-code and you need to pull those changes into an app repo:

```bash
# In the app repo (e.g., LongPro-Pest-Control-App)
git remote add aos-core https://github.com/Fuzzypi/Robo-code.git  # if not already added
git fetch aos-core
git subtree pull --prefix=ops/aos aos-core main --squash
```

### Making Changes to AOS

1. Clone or navigate to `Robo-code`
2. Make changes on a branch or directly on `main`
3. Commit and push to Robo-code
4. Pull into app repos via subtree (see above)

---

## Exception: Emergency Hotfixes

In rare cases, you may need to fix AOS directly in an app repo's subtree (e.g., a blocking bug during a job). This is allowed under these conditions:

1. **Document the emergency** in your commit message
2. **Push back to Robo-code within the same job**:

```bash
# In the app repo, after making the hotfix in ops/aos/
git add ops/aos/
git commit -m "fix(aos): emergency hotfix - [describe issue]"

# Push the subtree changes back to Robo-code
git subtree push --prefix=ops/aos aos-core main
```

3. **Pull to confirm round-trip**:

```bash
git subtree pull --prefix=ops/aos aos-core main --squash
```

**Do not leave subtree edits unpushed.** The app repo subtree must always be in sync with Robo-code main.

---

## Commands Reference

| Action | Command |
|--------|---------|
| Add aos-core remote | `git remote add aos-core https://github.com/Fuzzypi/Robo-code.git` |
| Fetch from aos-core | `git fetch aos-core` |
| Pull AOS updates | `git subtree pull --prefix=ops/aos aos-core main --squash` |
| Push hotfix to Robo-code | `git subtree push --prefix=ops/aos aos-core main` |

---

## Why This Matters

- **Single source of truth**: Robo-code is canonical; app repos are consumers
- **Avoids drift**: All app repos get the same AOS version
- **Audit trail**: Changes flow through Robo-code where they can be reviewed
- **Simplifies updates**: One place to update, many places to pull

---

*This is a workflow rule, not an automated enforcement. Agents and humans are expected to follow this process.*
