# Implementation Plan - Optimize Note Loading Performance

The application is experiencing significant UI lag (skipped frames) during the initial loading of notes on the `HomeScreen`. This is primarily due to the heavy JSON parsing and object mapping of `HandwrittenNote` files (which contain many strokes and points) occurring on the main thread.

## Proposed Changes

### [HandwrittenNote Model]

#### [MODIFY] [HandwrittenNote.dart](file:///home/bird/StudioProjects/texnote/lib/models/HandwrittenNote.dart)
- Introduce a static helper function `_parseHandwrittenNote` that takes the raw JSON string and other metadata, performs `jsonDecode` and mapping, and returns a `HandwrittenNote` instance.
- Update the `load` static method to offload the call to `_parseHandwrittenNote` using Flutter's `compute` function. This moves the expensive parsing logic to a background isolate, preventing the main thread from blocking.

### [File I/O]

#### [MODIFY] [browse_file.dart](file:///home/bird/StudioProjects/texnote/lib/io/browse_file.dart)
- Refactor the `collect()` function to load multiple files in parallel using `Future.wait` instead of a sequential `while` loop. This will reduce the total time spent waiting for file I/O and isolate processing.

## Verification Plan

### Automated Tests
- I will add `debugPrint` statements to measure the time taken for individual note loading before and after the changes.
- Ensure that the notes are still loaded correctly and displayed on the `HomeScreen`.

### Manual Verification
- Observe the logs for "Skipped frames" or "Slow delivery" warnings during app startup.
- Verify that both `HandwrittenNote` and `TextNote` items appear correctly in the list.
