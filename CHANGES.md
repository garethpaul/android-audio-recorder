# Changes

## 2026-06-08

- Added a repository changelog and expanded the documented Android verification
  gate to include lint, tests, and debug assembly.
- Cleaned Android lint findings by removing unused starter resources, moving
  bitmap assets to `drawable-nodpi`, documenting the nodpi lint baseline, and
  adding button accessibility labels.
- Moved the recorder background color into the app theme to avoid root-layout
  overdraw.
