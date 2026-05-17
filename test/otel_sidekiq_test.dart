// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

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
