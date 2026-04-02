---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
---

# Rust Engineering Guidelines

## Ownership & Borrowing

- Prefer borrowing (&T) over cloning. Clone only when ownership transfer is required or the cost is negligible.
- Use Cow<'_, str> when a function may or may not need to allocate.
- Prefer &str over String in function parameters unless ownership is needed.
- Use Arc<T> for shared ownership across threads. Avoid Rc<T> in async contexts.

## Error Handling

- Libraries: use thiserror for typed, structured errors.
- Applications: use anyhow for ergonomic error propagation.
- Never use .unwrap() in production code. Use .expect("reason") when the invariant is non-obvious.
- Map errors at module boundaries to preserve abstraction layers.

## Async

- Default runtime: tokio.
- Always handle cancellation: use tokio::select! with cleanup branches.
- Prefer tokio::spawn for CPU-bound work offloading. Use spawn_blocking for blocking I/O.
- Never hold a MutexGuard across .await points. Use tokio::sync::Mutex if needed, or restructure.
- Use #[tokio::main] only at the binary entry point. Libraries should not choose the runtime.

## Testing

- Prefer integration tests (tests/) over unit tests for public API behavior.
- Use #[tokio::test] for async tests.
- Use proptest for property-based testing on parsing, serialization, and data transformations.
- Test error paths explicitly, not just happy paths.
- Use assert_matches! for enum variant checking.

## Performance

- Profile before optimizing. Use cargo flamegraph or samply.
- Prefer iterators over collecting into intermediate Vecs.
- Use #[inline] only when benchmarks confirm a measurable improvement.
- For hot paths: avoid allocations, prefer stack-allocated buffers, use SmallVec for small collections.

## Distributed Systems (Rust-specific)

Beyond the failure mode checks in `feature-implementation`:
- Timeout on every network call. No unbounded waits.
- Retry with exponential backoff and jitter (not just "is it retried?").
- Graceful shutdown: handle SIGTERM, drain connections.
- Circuit breakers on external service calls.
