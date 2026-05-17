# otel_sidekiq

Dartastic OpenTelemetry bridge for Sidekiq (Ruby background jobs).

Wraps each call in a CLIENT-kind span with vendor-specific attributes following OpenTelemetry semantic conventions where applicable.

```dart
import 'package:otel_sidekiq/otel_sidekiq.dart';

await tracedSidekiq<void>(
  operation: 'someOp',
  invoke: () async {
    final r = await client.someOp();
    return SidekiqCallResult(value: r, result: SidekiqResult(statusCode: 200));
  },
);
```

Suppress instrumentation within a block:

```dart
await runWithoutSidekiqInstrumentationAsync(() async {
  await client.someInternalSync();
});
```
