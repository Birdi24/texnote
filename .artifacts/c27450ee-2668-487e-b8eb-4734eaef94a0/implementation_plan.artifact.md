# Performance Optimization for Large PDFs

The app currently experiences significant lag when importing and writing on large PDFs (e.g., 1600 pages). This is caused by:
1.  **Inefficient Rendering**: All strokes in the entire document are iterated and repainted on every frame of a new stroke, regardless of their visibility.
2.  **Widget Tree Bloat**: 1600 page containers are created in a `Column` during initial load.
3.  **O(N) Calculations**: Many operations iterate through every stroke in the document.

## User Review Required

> [!IMPORTANT]
> This change refactors how strokes, images, and texts are stored in memory during the editing session to allow for page-based partitioning. This significantly improves performance but requires careful handling of content that spans page boundaries (though the current app treats content as belonging to a specific Y-range anyway).

## Proposed Changes

### 1. Data Partitioning
Modify `CanvasView` to maintain content partitioned by page. This avoids iterating through all 1600 pages' worth of data when only one page is being viewed/edited.

### 2. ListView Optimization
#### [MODIFY] [CanvasBackground.dart](file:///home/bird/StudioProjects/texnote/lib/screens/HandwrittenNoteScreen/CanvasBackground.dart)
Replace the `Column` with a `ListView.builder` or a similar lazy-loading mechanism. However, since the current architecture uses a manual `Transform` for zooming, a better approach is to simply ensure that only "in-window" pages render their heavy components.

### 3. Page-Based Rendering (Tiling)
#### [NEW] [PageCanvas.dart](file:///home/bird/StudioProjects/texnote/lib/screens/HandwrittenNoteScreen/PageCanvas.dart)
Create a new component that renders a single page's background, paper lines, and its specific strokes/images/texts.

#### [MODIFY] [BottomCanvas.dart](file:///home/bird/StudioProjects/texnote/lib/screens/HandwrittenNoteScreen/BottomCanvas.dart)
Remove the global `BottomCanvas` and instead use multiple `PageBottomCanvas` instances within each page.

#### [MODIFY] [HandwritingPainter.dart](file:///home/bird/StudioProjects/texnote/lib/screens/HandwrittenNoteScreen/HandwritingPainter.dart)
Add basic bounding box checks to skip drawing strokes that are completely outside the current canvas clip.

### 4. Logic Updates
#### [MODIFY] [CanvasView/main.dart](file:///home/bird/StudioProjects/texnote/lib/screens/HandwrittenNoteScreen/CanvasView/main.dart) & associated parts
Update the `_buildPageContent` method to use a `ListView.builder` for pages. Each page will contain its own `BottomCanvas`.

## Verification Plan

### Manual Verification
1.  Import a large PDF (100+ pages).
2.  Verify that the initial loading time is significantly reduced.
3.  Write on page 1, then scroll to page 100 and write there.
4.  Observe the FPS during drawing; it should remain high regardless of the total number of strokes in the document.
5.  Verify that zooming and panning still work correctly with the new `ListView` structure.
