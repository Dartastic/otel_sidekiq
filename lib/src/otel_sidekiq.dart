// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_sidekiq_suppression.dart';

class SidekiqResult {
  const SidekiqResult({
    this.queue,
    this.className,
    this.jobId,
    this.retry,
    this.attempt,
    this.backtrace,
    this.batchId,
    this.durationMs,
    this.statusCode,
    this.errorCode,
    this.errorMessage,
  });

  final String? queue;
  final String? className;
  final String? jobId;
  final bool? retry;
  final int? attempt;
  final String? backtrace;
  final String? batchId;
  final int? durationMs;
  final int? statusCode;
  final String? errorCode;
  final String? errorMessage;
}

class SidekiqCallResult<T> {
  const SidekiqCallResult({required this.value, this.result});
  final T value;
  final SidekiqResult? result;
}

Future<T> tracedSidekiq<T>({
  required String operation,
  required Future<SidekiqCallResult<T>> Function() invoke,
  Tracer? tracer,
}) async {
  if (sidekiqInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTel.tracerProvider().getTracer('otel_sidekiq');
  final span = t.startSpan('sidekiq $operation', kind: SpanKind.producer);
  try {
    span.setStringAttribute('messaging.system', 'sidekiq');
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.queue != null) {
        span.setStringAttribute('messaging.destination.name', res.queue!);
      }
      if (res.className != null) {
        span.setStringAttribute('sidekiq.class', res.className!);
      }
      if (res.jobId != null) {
        span.setStringAttribute('messaging.message.id', res.jobId!);
      }
      if (res.retry != null) {
        span.setBoolAttribute('sidekiq.retry', res.retry!);
      }
      if (res.attempt != null) {
        span.setIntAttribute('sidekiq.attempt', res.attempt!);
      }
      if (res.backtrace != null) {
        span.setStringAttribute('sidekiq.backtrace', res.backtrace!);
      }
      if (res.batchId != null) {
        span.setStringAttribute('sidekiq.batch.id', res.batchId!);
      }
      if (res.durationMs != null) {
        span.setIntAttribute('sidekiq.duration', res.durationMs!);
      }
      if (res.statusCode != null) {
        span.setIntAttribute('http.response.status_code', res.statusCode!);
      }
      if (res.errorCode != null) {
        span.setStringAttribute('sidekiq.error.code', res.errorCode!);
      }
      final fail =
          res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.setStringAttribute(
          ErrorResource.errorType.key,
          res.errorCode ?? 'sidekiq.error',
        );
        span.setStatus(SpanStatusCode.Error, res.errorMessage);
      }
    }
    return r.value;
  } catch (e, st) {
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
