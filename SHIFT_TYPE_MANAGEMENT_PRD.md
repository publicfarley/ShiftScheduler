# Product Requirements Document (PRD)
# Shift Type Management Feature Enhancement

**Document Version:** 1.0
**Date:** October 26, 2025
**Author:** Product & Project Manager
**Project:** ShiftScheduler iOS App

---

## Executive Summary

This PRD outlines enhancements to the Shift Type management feature in the ShiftScheduler iOS application. The current implementation has incomplete functionality that prevents users from properly creating and managing shift types with all required attributes. This enhancement will deliver a production-ready shift type management system with proper validation, referential integrity, and user experience improvements.

---

## 1. Product Overview

### 1.1 Feature Scope
Enhance the existing Shift Type CRUD (Create, Read, Update, Delete) functionality to include:
- Complete form fields (description, duration options, location selection)
- Proper validation and error handling
- Referential integrity between Locations and Shift Types
- Improved user experience and form dismissal behavior

### 1.2 Business Goals
- Enable users to fully define shift templates with all required attributes
- Prevent data integrity issues through proper validation
- Ensure users cannot create orphaned data (shift types without locations)
- Maintain referential integrity (prevent deletion of locations in use)
- Provide clear user feedback when actions cannot be completed

### 1.3 Success Metrics
- Users can successfully create shift types with all required fields
- Zero instances of shift types with missing or invalid location references
- Zero crashes or errors during shift type creation/editing
- User can complete all CRUD operations without confusion or frustration
- Form dismissal works consistently across all user interaction patterns

---

## 2. User Stories

### 2.1 Epic: Complete Shift Type Creation
**As a** shift scheduler
**I want to** create shift types with complete information (symbol, title, description, times, location)
**So that** I can accurately define work shift templates for scheduling

#### User Story 2.1.1: Add Description Field
**As a** shift scheduler
**I want to** add an optional description to a shift type
**So that** I can provide additional context about the shift (e.g., "Overnight shift with extended break")

**Acceptance Criteria:**
- Description field appears in "Shift Type Details" section
- Field is optional (can be left blank)
- Description supports multiline text input (TextEditor)
- Description is saved with the shift type
- Description displays correctly when editing existing shift type
- Character limit: 500 characters
- Field has placeholder text: "Optional description"

#### User Story 2.1.2: All Day Duration Option
**As a** shift scheduler
**I want to** mark a shift as "All Day" instead of specifying specific times
**So that** I can define shifts that span entire calendar days (e.g., on-call duty)

**Acceptance Criteria:**
- Duration section includes "All Day" toggle
- When "All Day" is OFF: Start Time and End Time pickers are visible
- When "All Day" is ON: Start Time and End Time pickers are hidden
- Default state: "All Day" OFF with times set to 8:00 AM - 4:00 PM
- Toggle state persists when editing existing shift type
- Shift type duration stores either `.allDay` or `.scheduled(from:to:)`
- Display logic shows "All Day" in shift type card when appropriate

#### User Story 2.1.3: Location Selection Required
**As a** shift scheduler
**I want to** select a location when creating a shift type
**So that** shifts are associated with specific work locations

**Acceptance Criteria:**
- Location field is REQUIRED (cannot save without selecting a location)
- Location selector displays all saved locations
- Use Picker component for location selection
- If NO locations exist: show error state in sheet
- Error message: "Please create a location first before adding shift types"
- Save button is disabled when no location is selected
- Selected location displays correctly when editing existing shift type
- Location picker shows location name (not address)

### 2.2 Epic: Data Integrity Protection

#### User Story 2.2.1: Prevent Location Deletion When In Use
**As a** system administrator
**I want to** prevent deletion of locations that are used by shift types
**So that** shift type data remains valid and no orphaned references exist

**Acceptance Criteria:**
- Locations screen checks if location is used by any shift types before deletion
- If location is in use: show alert preventing deletion
- Alert title: "Cannot Delete Location"
- Alert message: "This location is used by [N] shift type(s). Remove those shift types first, then delete this location."
- Alert has single "OK" button (no destructive action)
- Delete confirmation dialog does not appear if location is in use
- System counts exact number of shift types using the location
- User can still edit location even if it's in use

#### User Story 2.2.2: Empty Location State Handling
**As a** shift scheduler
**I want to** receive clear guidance when trying to create a shift type with no locations defined
**So that** I understand what action I need to take first

**Acceptance Criteria:**
- When opening Add Shift Type sheet with zero locations: show warning banner
- Warning banner appears at top of form
- Banner message: "No locations available. Please create a location first."
- Banner has yellow/warning color scheme
- Banner includes info icon
- Save button is disabled when no locations exist
- User can tap "Create Location" button in banner (navigates to location creation)
- Banner dismisses automatically when locations become available

### 2.3 Epic: Improved User Experience

#### User Story 2.3.1: Sheet Dismissal Fix
**As a** user
**I want to** have the sheet properly close when dismissing the Add/Edit Shift Type form
**So that** the UI returns to a clean state without lingering sheet visibility issues

**Acceptance Criteria:**
- Sheet includes `onDismiss` handler
- onDismiss dispatches: `.shiftTypes(.addEditSheetDismissed)`
- Sheet dismisses when Cancel button tapped
- Sheet dismisses when Save button tapped (after successful save)
- Sheet dismisses when user swipes down to dismiss
- Redux state updates to reflect sheet closure
- No visual glitches or stuck sheets
- Pattern matches LocationsView implementation

---

## 3. Functional Requirements

### 3.1 Data Model Updates

#### 3.1.1 ShiftType Model
The `ShiftType` model must support:
```swift
struct ShiftType {
    let id: UUID
    let symbol: String              // Required, 1-3 characters
    let duration: Duration          // Required, enum .allDay or .scheduled
    let title: String               // Required, max 100 characters
    let shiftDescription: String?   // Optional, max 500 characters
    let location: Location          // Required, must reference valid Location
}

enum Duration {
    case allDay
    case scheduled(from: HourMinuteTime, to: HourMinuteTime)
}
```

#### 3.1.2 Redux State Updates
`ShiftTypesState` must include:
- `editingShiftType: ShiftType?` - currently editing shift type
- `showAddEditSheet: Bool` - controls sheet visibility
- `isLoading: Bool` - async operation indicator
- `errorMessage: String?` - validation/operation errors
- `shiftTypes: [ShiftType]` - all defined shift types

### 3.2 Redux Action Updates

#### 3.2.1 Required Actions
```swift
enum ShiftTypesAction {
    case task                                    // Load shift types on appear
    case addButtonTapped                         // Show add sheet
    case editShiftType(ShiftType)                // Show edit sheet
    case addEditSheetDismissed                   // Clean state on dismiss
    case saveShiftType(ShiftType)                // Persist shift type
    case deleteShiftType(ShiftType)              // Remove shift type
    case shiftTypesLoaded([ShiftType])           // Update state after load
    case errorOccurred(String)                   // Handle errors
}
```

### 3.3 Validation Rules

#### 3.3.1 Field Validation
| Field | Required | Min Length | Max Length | Format Rules |
|-------|----------|------------|------------|--------------|
| Symbol | Yes | 1 | 3 | Uppercase letters/numbers only |
| Title | Yes | 1 | 100 | Any text, trimmed whitespace |
| Description | No | 0 | 500 | Multiline text allowed |
| Location | Yes | N/A | N/A | Must reference existing Location |
| Duration | Yes | N/A | N/A | Either allDay or scheduled times |

#### 3.3.2 Business Rules
1. **Unique Symbol**: Each shift type must have a unique symbol (case-insensitive)
2. **Valid Time Range**: If duration is scheduled, end time must be after start time
3. **Location Existence**: Selected location must exist in locations array
4. **No Empty Fields**: Title and Symbol cannot be empty or whitespace-only

### 3.4 Error Handling

#### 3.4.1 User-Facing Error Messages
| Error Scenario | Message |
|----------------|---------|
| No locations exist | "No locations available. Please create a location first." |
| Symbol already exists | "A shift type with symbol '[SYMBOL]' already exists." |
| Invalid time range | "End time must be after start time." |
| Missing required field | "Please fill in all required fields." |
| Location deleted | "Selected location no longer exists. Please choose another." |
| Save failed | "Unable to save shift type. Please try again." |
| Delete location in use | "This location is used by [N] shift type(s). Remove those shift types first." |

---

## 4. User Interface Specifications

### 4.1 Add/Edit Shift Type Sheet

#### 4.1.1 Layout Structure
```
Navigation View
  └─ Form
      ├─ Section: "Shift Type Details"
      │   ├─ TextField: Symbol (uppercase, 3 char max)
      │   ├─ TextField: Title
      │   └─ TextEditor: Description (optional, 500 char max, multiline)
      │
      ├─ Section: "Duration"
      │   ├─ Toggle: "All Day"
      │   ├─ DatePicker: "Start Time" (if not all day)
      │   └─ DatePicker: "End Time" (if not all day)
      │
      ├─ Section: "Location"
      │   └─ Picker: Location selection
      │
      └─ Section: Error Display (conditional)
          └─ Error banner with icon and message
```

#### 4.1.2 Component Specifications

**Symbol Field:**
- Text input with character limit: 3
- Auto-capitalization: characters
- Autocorrection: disabled
- Keyboard type: default
- Placeholder: "e.g., M, N, D"

**Title Field:**
- Text input with character limit: 100
- Auto-capitalization: words
- Autocorrection: enabled
- Keyboard type: default
- Placeholder: "e.g., Morning Shift"

**Description Field:**
- Multiline text editor
- Character limit: 500
- Height: 100pt minimum
- Placeholder: "Optional description"
- Auto-capitalization: sentences
- Scrollable when content exceeds height

**Duration Toggle:**
- Label: "All Day"
- Default: OFF
- Conditional rendering:
  - ON: Hide time pickers
  - OFF: Show time pickers

**Time Pickers:**
- Components: Hour and Minute only
- Default Start Time: 8:00 AM
- Default End Time: 4:00 PM
- Display format: 12-hour with AM/PM

**Location Picker:**
- Style: Menu picker
- Display: Location name
- Empty state: "No locations available"
- Selection: Required (no "None" option)

#### 4.1.3 Navigation Bar
- Title: "Add Shift Type" or "Edit Shift Type"
- Left button: "Cancel" (gray, secondary action)
- Right button: "Save" (blue, primary action, disabled when invalid)

#### 4.1.4 Keyboard Dismissal
- Apply `.dismissKeyboardOnTap()` to entire form
- ScrollView should dismiss keyboard on scroll
- Sheet should handle keyboard dismissal on swipe-down

### 4.2 Shift Type Card Display

#### 4.2.1 Card Layout
```
┌─────────────────────────────────────┐
│ [Symbol] Title              chevron │
│ 🕐 Time Range                       │
│ 📍 Location Name                    │
└─────────────────────────────────────┘
```

**Card Components:**
- Symbol: Large text (title3 font)
- Title: Bold text (headline font)
- Time: Secondary text with clock icon
- Location: Secondary text with location icon
- Chevron: Right arrow indicating tappable
- Background: systemGray6
- Corner radius: 8pt
- Padding: 16pt

### 4.3 Error States

#### 4.3.1 No Locations Warning Banner
- Background: Yellow/warning color (systemYellow with 0.2 opacity)
- Icon: exclamationmark.triangle.fill
- Text: "No locations available. Please create a location first."
- Button: "Create Location" (navigation to LocationsView)
- Position: Top of sheet, above form sections

#### 4.3.2 Delete Prevention Alert
- Style: Alert dialog
- Title: "Cannot Delete Location"
- Message: "This location is used by [N] shift type(s). Remove those shift types first, then delete this location."
- Button: "OK" (default action)
- Icon: System alert icon

---

## 5. Technical Implementation Requirements

### 5.1 Redux Architecture Compliance

#### 5.1.1 State Management
- All state stored in `AppState.shiftTypes`
- No local state for business logic
- View @State only for UI interaction (e.g., local form fields)
- All data mutations via Redux actions

#### 5.1.2 Action Dispatch Pattern
```swift
// User interaction triggers action
store.dispatch(action: .shiftTypes(.saveShiftType(newShiftType)))

// Middleware handles side effects (persistence)
// Reducer updates state synchronously
// View re-renders from new state
```

#### 5.1.3 Middleware Responsibilities
- Load shift types from persistence on `.task`
- Save shift type to persistence on `.saveShiftType`
- Delete shift type from persistence on `.deleteShiftType`
- Validate location references before save
- Check location usage before delete
- Dispatch success/error actions back to reducer

### 5.2 Swift 6 Concurrency Requirements

#### 5.2.1 Thread Safety
- All Redux operations on `@MainActor`
- Service calls use structured concurrency (async/await)
- No force unwrapping (!) anywhere in code
- Use guard/if let for optional handling
- Sendable types for data passed between actors

#### 5.2.2 Dependency Injection
- Services injected via `ServiceContainer`
- Protocol-oriented design for testability
- Mock services for unit tests
- No singleton references in new code

### 5.3 Validation Implementation

#### 5.3.1 Client-Side Validation
```swift
// Form validation (in view)
var isValid: Bool {
    !title.isEmpty &&
    !symbol.isEmpty &&
    symbol.count <= 3 &&
    selectedLocation != nil &&
    (!isAllDay ? endTime > startTime : true)
}

// Business rule validation (in middleware)
func validateShiftType(_ shiftType: ShiftType, existingTypes: [ShiftType]) -> ValidationResult {
    // Check unique symbol
    // Check location exists
    // Check time range validity
}
```

#### 5.3.2 Location Reference Validation
```swift
// Before delete (in middleware)
func canDeleteLocation(_ location: Location, shiftTypes: [ShiftType]) -> Bool {
    return shiftTypes.filter { $0.location.id == location.id }.isEmpty
}

func countShiftTypesUsingLocation(_ location: Location, shiftTypes: [ShiftType]) -> Int {
    return shiftTypes.filter { $0.location.id == location.id }.count
}
```

### 5.4 Persistence Requirements

#### 5.4.1 JSON Schema
```json
{
  "shiftTypes": [
    {
      "id": "UUID-string",
      "symbol": "M",
      "title": "Morning Shift",
      "shiftDescription": "Optional description text",
      "duration": {
        "type": "scheduled",
        "from": { "hour": 8, "minute": 0 },
        "to": { "hour": 16, "minute": 0 }
      },
      "location": {
        "id": "UUID-string",
        "name": "Downtown Office",
        "address": "123 Main St"
      }
    }
  ]
}
```

#### 5.4.2 File Operations
- Read shift types on app launch
- Write shift types after every mutation
- Atomic file writes (write to temp, then move)
- Error handling for file I/O failures
- Backup old file before overwriting

---

## 6. Edge Cases and Error Scenarios

### 6.1 Location Management Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| User deletes all locations | Existing shift types keep location reference but show warning on edit |
| User tries to create shift type with no locations | Show warning banner, disable Save button |
| Location deleted while shift type edit sheet is open | Save fails with error message to re-select location |
| User edits location name | All shift types using that location reflect new name |
| Multiple shift types use same location | All must be deleted/updated before location can be deleted |

### 6.2 Duration Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| End time before start time | Show validation error, disable Save |
| End time equals start time | Show validation error, disable Save |
| Switch from scheduled to all-day | Hide time pickers, store .allDay duration |
| Switch from all-day to scheduled | Show time pickers with default times (8 AM - 4 PM) |
| Editing all-day shift | Toggle starts ON, time pickers hidden |

### 6.3 Symbol Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Duplicate symbol (case insensitive) | Show error: "Symbol 'X' already exists" |
| Symbol with lowercase letters | Auto-convert to uppercase |
| Symbol with spaces | Trim and validate as single word |
| Symbol exceeds 3 characters | Limit input to 3 characters |
| Symbol with special characters | Allow but validate uniqueness |

### 6.4 Persistence Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Save fails (disk full) | Show error alert, keep sheet open with data |
| Load fails on app launch | Show empty state with retry option |
| Corrupted JSON file | Attempt recovery, log error, use empty array |
| Concurrent saves (unlikely but possible) | Serialize writes through middleware queue |

---

## 7. Acceptance Criteria Summary

### 7.1 Feature Complete Checklist
- [ ] Description field added and functional
- [ ] All Day toggle implemented with conditional time pickers
- [ ] Location picker implemented with all saved locations
- [ ] Location requirement enforced (Save disabled when no location)
- [ ] No locations warning banner displayed when appropriate
- [ ] Sheet dismissal handler added to AddEditShiftTypeView
- [ ] Location deletion protection implemented
- [ ] Error message shown when attempting to delete location in use
- [ ] All validation rules implemented and tested
- [ ] All edge cases handled gracefully
- [ ] Keyboard dismissal works correctly

### 7.2 Quality Criteria
- [ ] Zero compiler warnings in new/modified code
- [ ] Zero force unwraps (!) in code
- [ ] All optionals handled safely with guard/if let
- [ ] Swift 6 concurrency compliance maintained
- [ ] Redux architecture pattern followed consistently
- [ ] No singleton usage in new code
- [ ] Protocol-oriented dependency injection used
- [ ] Code follows existing SwiftUI patterns in codebase

### 7.3 User Experience Criteria
- [ ] Users can create shift types with all required fields
- [ ] Form validation provides clear, actionable error messages
- [ ] Sheet dismissal works smoothly without UI glitches
- [ ] Location protection prevents data integrity issues
- [ ] Empty states provide helpful guidance
- [ ] Save button state clearly indicates when form is invalid
- [ ] Keyboard does not block form fields or buttons

---

## 8. Testing Requirements

### 8.1 Unit Tests

#### 8.1.1 Reducer Tests
- [ ] Test adding new shift type updates state correctly
- [ ] Test editing existing shift type preserves ID
- [ ] Test deleting shift type removes from array
- [ ] Test error state updates on validation failure
- [ ] Test sheet visibility state toggles correctly

#### 8.1.2 Middleware Tests
- [ ] Test shift type persistence after save
- [ ] Test shift type load on task action
- [ ] Test location validation before save
- [ ] Test location deletion prevention logic
- [ ] Test error handling for failed persistence operations

#### 8.1.3 Validation Tests
- [ ] Test symbol uniqueness validation
- [ ] Test required field validation
- [ ] Test time range validation (end > start)
- [ ] Test character limit enforcement
- [ ] Test location reference validation

### 8.2 Integration Tests

#### 8.2.1 User Flow Tests
- [ ] Test complete add shift type flow
- [ ] Test complete edit shift type flow
- [ ] Test delete shift type flow
- [ ] Test location deletion prevention flow
- [ ] Test no locations warning flow

#### 8.2.2 State Management Tests
- [ ] Test Redux action dispatch updates UI correctly
- [ ] Test middleware side effects complete before UI updates
- [ ] Test concurrent actions handled correctly
- [ ] Test error recovery and retry scenarios

### 8.3 UI Tests (Manual)

#### 8.3.1 Form Interaction Tests
- [ ] Verify all form fields accept input correctly
- [ ] Verify character limits enforce correctly
- [ ] Verify toggle switches between states correctly
- [ ] Verify pickers display all options
- [ ] Verify Save button enables/disables appropriately
- [ ] Verify Cancel button dismisses sheet
- [ ] Verify keyboard dismisses on tap outside

#### 8.3.2 Visual Regression Tests
- [ ] Verify form layout matches design specifications
- [ ] Verify error states display correctly
- [ ] Verify empty states display correctly
- [ ] Verify card layout displays all information
- [ ] Verify alerts display with correct styling

---

## 9. Dependencies and Risks

### 9.1 Technical Dependencies
- Existing Redux architecture must remain stable
- LocationsView pattern used as reference implementation
- Persistence service must support atomic writes
- Domain models (ShiftType, Location) must support new fields

### 9.2 Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Location deletion creates orphaned shift types | Medium | High | Implement deletion protection before release |
| Time zone handling issues with all-day shifts | Low | Medium | Use Calendar.startOfDay for all-day duration |
| Form state not clearing between add/edit | Medium | Low | Properly reset state on sheet dismissal |
| Validation rules too restrictive | Low | Medium | Gather user feedback during testing |
| Performance issues with large shift type lists | Low | Medium | Implement pagination if list exceeds 100 items |

### 9.3 Assumptions
- Users will create locations before shift types (enforced by validation)
- Maximum 50 shift types per user (reasonable limit for shift scheduling)
- Maximum 20 locations per user (reasonable limit for most organizations)
- JSON persistence is sufficient (no database migration needed)
- Users understand shift scheduling domain concepts

---

## 10. Future Enhancements (Out of Scope)

The following features are explicitly **out of scope** for this release but documented for future consideration:

1. **Shift Type Templates**: Pre-defined shift type templates (e.g., "Retail", "Healthcare")
2. **Color Coding**: Custom colors for shift types in calendar view
3. **Shift Type Groups**: Organize shift types into categories
4. **Bulk Operations**: Multi-select and bulk edit/delete shift types
5. **Import/Export**: CSV import/export of shift types
6. **Shift Type Analytics**: Reports on most-used shift types
7. **Location Reassignment**: Bulk reassign shift types to different location
8. **Audit Trail**: Track who created/modified shift types
9. **Soft Delete**: Archive instead of permanent delete with recovery option
10. **Advanced Time Rules**: Break times, overtime rules, split shifts

---

## 11. Sign-off

### 11.1 Approval Required From:
- Product Owner: _______________________
- Engineering Lead: _______________________
- QA Lead: _______________________

### 11.2 Acceptance Criteria Sign-off
Upon completion, all acceptance criteria in Section 7 must be verified and signed off before considering the feature complete.

---

**Document Status:** Draft for Review
**Next Review Date:** Upon completion of implementation
**Version History:**
- v1.0 (2025-10-26): Initial PRD creation
