// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

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
    span.addAttributes(
        OTel.attributes([OTel.attributeString('messaging.system', 'sidekiq')]));
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.queue != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeString('messaging.destination.name', res.queue!)]));
      }
      if (res.className != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeString('sidekiq.class', res.className!)]));
      }
      if (res.jobId != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeString('messaging.message.id', res.jobId!)]));
      }
      if (res.retry != null) {
        span.addAttributes(
            OTel.attributes([OTel.attributeBool('sidekiq.retry', res.retry!)]));
      }
      if (res.attempt != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeInt('sidekiq.attempt', res.attempt!)]));
      }
      if (res.backtrace != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeString('sidekiq.backtrace', res.backtrace!)]));
      }
      if (res.batchId != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeString('sidekiq.batch.id', res.batchId!)]));
      }
      if (res.durationMs != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeInt('sidekiq.duration', res.durationMs!)]));
      }
      if (res.statusCode != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeInt('http.response.status_code', res.statusCode!)]));
      }
      if (res.errorCode != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeString('sidekiq.error.code', res.errorCode!)]));
      }
      final fail = res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.addAttributes(OTel.attributes([
          OTel.attributeString(
            ErrorResource.errorType.key,
            res.errorCode ?? 'sidekiq.error',
          )
        ]));
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
