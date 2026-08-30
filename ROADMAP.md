# Roadmap

> Last updated: 2026-08-30. LinuxClean is a conservative maintenance tool; changes favor safety over features.

## Short term

- `--json` output mode for machine-readable reports (pairs with the existing dry-run preview).
- Document and test exit codes comprehensively in `test-report.md`.

## Mid term

- Optional systemd timer unit example for unattended weekly runs.
- Flatpak cache and snap old-revision cleanup behind explicit opt-in flags.
- Per-user include/exclude lists for cache paths.

## Long term / ideas

- Package for common distros (deb/rpm) once the flag surface stabilizes.
- Evaluate RHEL/Fedora family support beyond APT-specific paths.
