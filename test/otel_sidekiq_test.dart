// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:otel_sidekiq/otel_sidekiq.dart';
import 'package:test/test.dart';

void main() {
  group('otel_sidekiq', () {
    test('suppression toggles in zone', () async {
      expect(sidekiqInstrumentationSuppressed(), isFalse);
      await runWithoutSidekiqInstrumentationAsync(() async {
        expect(sidekiqInstrumentationSuppressed(), isTrue);
      });
      expect(sidekiqInstrumentationSuppressed(), isFalse);
    });

    test('SidekiqResult fields default null', () {
      const r = SidekiqResult();
      expect(r.statusCode, isNull);
    });
  });
}
