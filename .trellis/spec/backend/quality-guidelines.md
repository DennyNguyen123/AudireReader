# Quality Guidelines

> Code quality standards for backend development.

---

## Overview

<!--
Document your project's quality standards here.

Questions to answer:
- What patterns are forbidden?
- What linting rules do you enforce?
- What are your testing requirements?
- What code review standards apply?
-->

(To be filled by the team)

---

## Forbidden Patterns

- **Using `StreamAudioSource` (just_audio) for background/persistent audio play on iOS and Android:**
  - *Why:* On iOS, the local HTTP proxy server created by `just_audio` to feed the native player from stream is easily suspended or killed by iOS background management. On Android, HTTP connections to `localhost` are blocked by default due to cleartext network security policy.
  - *Solution:* Always download/synthesize audio to a local file (e.g. `.mp3` or `.wav` inside cache directory) and play via `ja.AudioSource.uri(Uri.file(filePath))`.

---

## Required Patterns

- **Explicit cancellation of prefetch/WebSocket connections during state transition:**
  - Always register active streams/sockets in a managed list (like `_activePrefetches`) and cancel them on playback pause, stop, or skip, preventing background resource leaks and WebSocket rate limits.

---

## Testing Requirements

<!-- What level of testing is expected -->

(To be filled by the team)

---

## Code Review Checklist

<!-- What reviewers should check -->

(To be filled by the team)
