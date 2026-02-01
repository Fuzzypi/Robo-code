# AOS Job Scaffolder

One command to create the standard job artifacts. No more freestyling structure.

## Usage

```bash
./.aos/scaffold/job.new.sh <job_id> [title...]
```

## What It Creates

```
reports/
└── jobs/
    └── <job_id>/
        └── proof.md          # Proof template with standard sections

jobs/                         # Only if jobs/ directory exists
└── <job_id>.md               # Job stub linking to proof
```

## Examples

### Basic usage

```bash
./.aos/scaffold/job.new.sh AOS__PHASE9_TEST
```

### With a title

```bash
./.aos/scaffold/job.new.sh AOS__PHASE9_TEST "Phase 9 Test Job"
```

### Build job

```bash
./.aos/scaffold/job.new.sh JOB__BUILD "Build and verify"
```

## Proof Template

The generated `proof.md` includes:

- Job ID and date (auto-filled)
- Repo and branch (auto-detected)
- **Summary** section
- **Commands Run** section
- **Outputs** section
- **Files Changed** table
- **Result** checklist

## Behavior

### Idempotency

Safe to run multiple times:
- Will NOT overwrite existing `proof.md`
- Will NOT overwrite existing job stubs
- Prints "Exists" and continues

### Evlog Integration

Emits a `job_scaffold` event to the evlog with:
- Job ID
- Created artifacts list
- Timestamp

## Example Output

```
╔════════════════════════════════════════╗
║         AOS Job Scaffolder             ║
╚════════════════════════════════════════╝

Job ID:  AOS__PHASE9_TEST
Title:   Phase 9 Test Job
Repo:    my-app
Branch:  main

━━━ Creating Directories ━━━
✅ Created: reports/jobs/AOS__PHASE9_TEST/

━━━ Creating Proof Template ━━━
✅ Created: reports/jobs/AOS__PHASE9_TEST/proof.md

━━━ Checking for jobs/ Directory ━━━
ℹ️  No jobs/ directory found (skipping job stub)

━━━ Logging to Evlog ━━━
✅ Emitted job_scaffold event to evlog

╔════════════════════════════════════════╗
║              Summary                   ║
╚════════════════════════════════════════╝

Created:
  ✅ reports/jobs/AOS__PHASE9_TEST/
  ✅ reports/jobs/AOS__PHASE9_TEST/proof.md

━━━ Next Steps ━━━

  1. Edit the proof template:
     $EDITOR reports/jobs/AOS__PHASE9_TEST/proof.md

  2. Run your job through the golden path:
     ./.aos/golden/aos.run.sh AOS__PHASE9_TEST -- <your-command>

  3. Update proof.md with results

  4. Commit when complete:
     git add reports/jobs/AOS__PHASE9_TEST/
     git commit -m "docs: add AOS__PHASE9_TEST proof artifact"
```

## Workflow Integration

1. **Start a new job:**
   ```bash
   ./.aos/scaffold/job.new.sh MY_JOB "Description"
   ```

2. **Run commands through golden path:**
   ```bash
   ./.aos/golden/aos.run.sh MY_JOB -- npm run build
   ```

3. **Update proof.md** with results

4. **Commit:**
   ```bash
   git add reports/jobs/MY_JOB/
   git commit -m "docs: add MY_JOB proof artifact"
   ```
