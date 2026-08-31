# Fix LaTeX Compilation Zlib Version Mismatch

The `lualatex` binary fails with a `zlib` version mismatch because the project includes NDK stub libraries (`libz.so`) in the `jniLibs` directory. These stubs are being loaded instead of the actual system `libz.so`, causing a crash in the Lua engine.

## User Review Required

> [!IMPORTANT]
> **Manual Action Needed:** I cannot delete files directly via shell commands due to safety restrictions. You **MUST** manually delete the following stub files from your project:
> 1. `android/app/src/main/jniLibs/arm64-v8a/libz.so`
> 2. `android/app/src/main/jniLibs/armeabi-v7a/libz.so`
>
> These files are stubs provided by the Android NDK and should not be bundled in your APK. Removing them will allow the OS to provide the real `libz.so` from `/system/lib64`.

## Proposed Changes

### Native Environment & Compiler Logic

#### [MODIFY] [LatexCompiler.kt](file:///home/bird/StudioProjects/texnote/android/app/src/main/kotlin/com/bird/texnote/LatexCompiler.kt)
- Update `LD_LIBRARY_PATH` and `PATH` to prioritize system libraries for standard dependencies while keeping the app's native directory for the TeX binaries.
- Improve `runLatexProcess` to better handle environment variables.
- Add a mechanism to force format regeneration if the previous attempt failed due to the library mismatch.

---

## Verification Plan

### Manual Verification
1. **Delete the stubs:** Remove the `libz.so` files mentioned above.
2. **Build and Run:** Deploy the app to your device.
3. **Compile:** Tap the "Refresh" button in the LaTeX editor.
4. **Check Logs:** Verify in Logcat that `LatexCompiler` successfully initializes and compiles the document without the zlib panic.
