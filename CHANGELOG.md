# Changelog

## [0.1.0-beta.1-wip]

### Added

- Initial release.
- `tracedSidekiq<T>(...)` — wraps a otel_sidekiq call in a CLIENT-kind span
  with vendor-specific attributes.
- Zone-scoped suppression via `runWithoutSidekiqInstrumentation()` / `Async()`.
