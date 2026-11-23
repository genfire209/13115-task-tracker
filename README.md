# 13115 Task Tracker

FTC Team 13115's first team app, used by the team in the 2026 season. **Retired in November 2026**: it was replaced by
[Telemetry](https://apps.apple.com/us/app/telemetry-by-13115/id6830405761), which works for any FTC team.

## What it did

- Google sign-in, then approval by the captain or an admin.
- Tasks by subteam (mechanical, programming, outreach, strategy): claim a task, accept or decline an assignment with a
  reason, request more time, and mark it done.
- Push notifications through Firebase Cloud Messaging, with hourly due-date reminders.
- Meet mode: pulls match schedules from FIRST's FTC Events API and alerts the team before each match.

## How it was built

- **App:** Flutter for iPhone, Android and the web (this repository).
- **Server:** Node.js and Express on Azure App Service with Azure SQL, deployed with GitHub Actions (a separate,
  private repository).

The servers are shut down, so this code is here for reference.
