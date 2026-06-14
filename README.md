# Temporal .NET -- Cox Automotive Day 2

Instruqt track for the second half-day of the Cox Automotive Temporal Dev Day.

## Track structure

```
instruqt/
  track.yml                  Track metadata and lab config
  config.yml                 Sandbox container definition
  track_scripts/
    setup-workshop           Track-level setup: stages /opt/workshop, starts services
  01-wiring/
    assignment.md            Two-stage exercise: activities + signals
    setup-workshop           Stages 06_wiring practice/solution
    check-workshop           Validates Stage A wiring and Stage B signal gate
    solve-workshop           Copies solution into exercise directory
    cleanup-workshop         Kills stray dotnet processes
  02-saga/
    assignment.md            Saga / compensation pattern
    setup-workshop           Stages 05_saga practice/solution
    check-workshop           Validates compensation stack and observed refund
    solve-workshop           Copies solution into exercise directory
    cleanup-workshop         Kills stray dotnet processes
docker/
  Dockerfile                 Sandbox image (extends Day 1 pattern, Day 2 exercises only)
justfile                     push / pull / validate / create / init recipes
```

## Image

Image: `mmerrell/temporal-dotnet-cox-day2:latest`

Bakes in:
- .NET 9 SDK
- Temporal CLI
- code-server
- `exercises/06_wiring/practice` and `exercises/06_wiring/solution`
- `exercises/05_saga/practice` and `exercises/05_saga/solution`
- NuGet packages pre-restored for all four projects

Build context requires `temporal-dotnet-hands-on/` checked out alongside the
Dockerfile (same pattern as the Day 1 image build).

```bash
# From repo root, with temporal-dotnet-hands-on/ present:
docker build -f docker/Dockerfile -t mmerrell/temporal-dotnet-cox-day2:latest .
docker push mmerrell/temporal-dotnet-cox-day2:latest
```

## First-time track registration

```bash
just create    # registers slug server-side (once)
just init      # first push + pulls back assigned ids
git add instruqt/ && git commit -m "Pin Instruqt track and tab ids"
```

## Ongoing workflow

```bash
just push      # push local changes to Instruqt
just pull      # pull any server-side id assignments
just validate  # run instruqt track validate
```

## Exercise source

Exercise code lives in `temporal-dotnet-hands-on`:
- `exercises/06_wiring/` -- new for Day 2 (activities, retry policies, signal gate)
- `exercises/05_saga/` -- lifted from Day 1 track as-is

## Known issues

- The track slug `temporal-dotnet-cox-day2` must be created server-side before
  the first push. Run `just create` before `just init`.
- After `just init`, commit the populated `id:` fields in `track.yml` and all
  `assignment.md` frontmatter -- Instruqt assigns these server-side on first push.
