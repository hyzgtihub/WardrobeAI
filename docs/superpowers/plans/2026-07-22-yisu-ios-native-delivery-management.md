# YISU iOS Native Delivery Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver an iOS-native rebaselined version of the YISU project delivery management workbook.

**Architecture:** Import the existing workbook and make targeted value-only replacements while retaining all sheet styles and structures. Shift plan dates by four days from the former Sprint baseline, then replace platform-specific acceptance criteria and risks with SwiftUI/Xcode/iOS equivalents.

**Tech Stack:** Node.js, `@oai/artifact-tool`, Excel `.xlsx`.

## Global Constraints

- Preserve the source workbook unchanged.
- Export a new workbook in `outputs/project-delivery-management/`.
- Use 2026-07-22 to 2026-08-04 as the Sprint window.
- Use iOS-native SwiftUI/Xcode/iOS Simulator/XCTest terminology; no Flutter or Android execution requirements.

---

### Task 1: Inspect and revise project-management tables

**Files:**
- Read: `outputs/project-delivery-management/衣序YISU-项目交付管理包-20260718.xlsx`
- Create: `outputs/project-delivery-management/衣序YISU-项目交付管理包-iOS原生基线-20260722.xlsx`

**Interfaces:**
- Consumes: existing sheet structure and date/status/acceptance columns.
- Produces: iOS-native WBS, RAID, milestones and Sprint backlog that retain the original workbook’s format.

- [ ] **Step 1: Import and inspect all worksheets, values, formulas and targeted styles**

Run an artifact-tool builder that inspects the workbook and renders each affected sheet before editing.

Expected: target sheets and text occurrences are identified without modifying the source file.

- [ ] **Step 2: Apply iOS-native terminology and rebaseline dates**

Use the builder to update WBS, RAID, milestones, Sprint backlog and direct Flutter/Android references in other sheets. Preserve status, priority, owner, formulas and formatting unless the iOS-native baseline requires a targeted value change.

Expected: the Sprint window is 2026-07-22 to 2026-08-04 and current acceptance text refers only to iOS-native delivery.

- [ ] **Step 3: Export the revised workbook**

Run the builder export to the exact output path.

Expected: source workbook remains present and the rebaselined workbook exists.

- [ ] **Step 4: Verify tables, formulas and rendering**

Inspect WBS, RAID, milestones and Sprint Backlog; scan for formula errors; render affected sheets for visual review.

Expected: no active Flutter/Android baseline text remains, no formula errors are introduced, and headers/cells remain readable.
