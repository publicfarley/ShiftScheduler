# Detailed Task Plan
# Shift Type Management Feature Enhancement

**Project:** ShiftScheduler iOS App
**Date:** October 26, 2025
**Estimated Total Effort:** 16-20 hours
**Priority:** High

---

## Task Breakdown Overview

| Phase | Tasks | Estimated Hours | Priority |
|-------|-------|----------------|----------|
| Phase 1: Foundation & State Setup | 3 tasks | 2-3 hours | Critical |
| Phase 2: UI Implementation | 5 tasks | 6-8 hours | Critical |
| Phase 3: Validation & Business Logic | 4 tasks | 4-5 hours | Critical |
| Phase 4: Location Protection | 2 tasks | 2-3 hours | Critical |
| Phase 5: Testing & Polish | 3 tasks | 2-3 hours | High |

---

## Phase 1: Foundation & State Setup

### Task 1.1: Update Domain Models
**Complexity:** Low
**Estimated Time:** 30 minutes
**Priority:** Critical
**Dependencies:** None

**Description:**
Update the `ShiftType` struct to include the optional description field and ensure proper support for all-day duration.

**Implementation Steps:**
1. Locate the ShiftType model file (likely in Domain/Models)
2. Add `shiftDescription: String?` property (if not already present)
3. Verify `Duration` enum supports both `.allDay` and `.scheduled(from:to:)` cases
4. Ensure Codable conformance handles optional description
5. Update initializer to include description parameter with default nil

**Acceptance Criteria:**
- [ ] ShiftType has optional shiftDescription property
- [ ] Duration enum has .allDay case
- [ ] Model compiles without errors
- [ ] Codable encoding/decoding works for all fields
- [ ] No force unwrapping in model code

**Code Pattern:**
```swift
struct ShiftType: Identifiable, Codable, Equatable {
    let id: UUID
    let symbol: String
    let duration: Duration
    let title: String
    let shiftDescription: String?  // Add or verify this
    let location: Location

    enum Duration: Codable, Equatable {
        case allDay
        case scheduled(from: HourMinuteTime, to: HourMinuteTime)
    }
}
```

**Testing:**
- Verify JSON encoding/decoding with and without description
- Verify equality comparison works correctly

---

### Task 1.2: Update Redux State
**Complexity:** Low
**Estimated Time:** 30 minutes
**Priority:** Critical
**Dependencies:** Task 1.1

**Description:**
Ensure ShiftTypesState has all necessary properties to support the enhanced form.

**Implementation Steps:**
1. Locate ShiftTypesState definition
2. Verify presence of required state properties:
   - `shiftTypes: [ShiftType]`
   - `editingShiftType: ShiftType?`
   - `showAddEditSheet: Bool`
   - `isLoading: Bool`
   - `errorMessage: String?`
3. Add any missing properties
4. Update initializer if needed

**Acceptance Criteria:**
- [ ] ShiftTypesState has all required properties
- [ ] State is Observable (@Observable macro applied)
- [ ] Initial state sets sensible defaults
- [ ] No compiler errors or warnings

**Code Pattern:**
```swift
struct ShiftTypesState {
    var shiftTypes: [ShiftType] = []
    var editingShiftType: ShiftType?
    var showAddEditSheet: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
}
```

**Testing:**
- Verify initial state creates correctly
- Verify state mutations compile

---

### Task 1.3: Verify Redux Actions
**Complexity:** Low
**Estimated Time:** 30 minutes
**Priority:** Critical
**Dependencies:** Task 1.2

**Description:**
Ensure all necessary Redux actions exist for shift type management.

**Implementation Steps:**
1. Locate ShiftTypesAction enum
2. Verify existence of required actions:
   - `task` (load on appear)
   - `addButtonTapped` (show add sheet)
   - `editShiftType(ShiftType)` (show edit sheet)
   - `addEditSheetDismissed` (clean state)
   - `saveShiftType(ShiftType)` (persist)
   - `deleteShiftType(ShiftType)` (remove)
   - `shiftTypesLoaded([ShiftType])` (update state)
   - `errorOccurred(String)` (handle errors)
3. Add any missing actions
4. Update reducer to handle all actions

**Acceptance Criteria:**
- [ ] All required actions defined in enum
- [ ] Reducer handles all actions appropriately
- [ ] No unhandled action cases
- [ ] Code compiles without warnings

**Code Pattern:**
```swift
enum ShiftTypesAction {
    case task
    case addButtonTapped
    case editShiftType(ShiftType)
    case addEditSheetDismissed
    case saveShiftType(ShiftType)
    case deleteShiftType(ShiftType)
    case shiftTypesLoaded([ShiftType])
    case errorOccurred(String)
}

// In reducer:
case .shiftTypes(.addEditSheetDismissed):
    state.shiftTypes.showAddEditSheet = false
    state.shiftTypes.editingShiftType = nil
    state.shiftTypes.errorMessage = nil
```

**Testing:**
- Test each action updates state correctly
- Verify no compiler warnings

---

## Phase 2: UI Implementation

### Task 2.1: Fix Sheet Dismissal
**Complexity:** Low
**Estimated Time:** 15 minutes
**Priority:** Critical
**Dependencies:** Task 1.3

**Description:**
Add the missing `onDismiss` handler to the sheet presentation in ShiftTypesView.

**Implementation Steps:**
1. Open `ShiftTypesView.swift`
2. Locate the `.sheet` modifier (around line 108)
3. Add `onDismiss` parameter before the content closure
4. Dispatch `.shiftTypes(.addEditSheetDismissed)` action
5. Follow the exact pattern from LocationsView (lines 108-119)

**Acceptance Criteria:**
- [ ] Sheet has onDismiss handler
- [ ] Handler dispatches addEditSheetDismissed action
- [ ] Sheet dismisses correctly on all exit methods (Cancel, Save, swipe-down)
- [ ] No visual glitches or stuck sheets
- [ ] Pattern matches LocationsView implementation

**Code Changes:**
```swift
// BEFORE (line 108):
.sheet(isPresented: .constant(store.state.shiftTypes.showAddEditSheet)) {
    AddEditShiftTypeView(...)
}

// AFTER:
.sheet(
    isPresented: .constant(store.state.shiftTypes.showAddEditSheet),
    onDismiss: {
        store.dispatch(action: .shiftTypes(.addEditSheetDismissed))
    }
) {
    AddEditShiftTypeView(...)
}
```

**Testing:**
- Test Cancel button dismisses sheet
- Test Save button dismisses sheet
- Test swipe-down dismisses sheet
- Verify state clears on dismiss

---

### Task 2.2: Add Description Field
**Complexity:** Low
**Estimated Time:** 1 hour
**Priority:** Critical
**Dependencies:** Task 1.1, Task 2.1

**Description:**
Add an optional multiline description field to the shift type form.

**Implementation Steps:**
1. Open `AddEditShiftTypeView.swift`
2. Add `@State private var description: String = ""` to view properties
3. Add description to form in "Shift Type Details" section after Symbol field
4. Use TextEditor for multiline input (not TextField)
5. Set frame height to minimum 100pt
6. Add character limit indicator if desired (optional)
7. Update saveShiftType() method to include description
8. Update onAppear to populate description when editing

**Acceptance Criteria:**
- [ ] Description field appears in "Shift Type Details" section
- [ ] Field uses TextEditor for multiline support
- [ ] Field is optional (can be empty)
- [ ] Placeholder text shows "Optional description"
- [ ] Character limit enforced at 500 characters
- [ ] Description saves correctly
- [ ] Description populates when editing existing shift type
- [ ] Keyboard dismissal works correctly

**Code Pattern:**
```swift
// Add state property:
@State private var shiftDescription: String = ""

// In form section:
Section("Shift Type Details") {
    TextField("Title", text: $title)
        .textInputAutocapitalization(.words)

    TextField("Symbol", text: $symbol)
        .textInputAutocapitalization(.characters)

    VStack(alignment: .leading, spacing: 4) {
        Text("Description (optional)")
            .font(.caption)
            .foregroundColor(.secondary)
        TextEditor(text: $shiftDescription)
            .frame(minHeight: 100)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .onChange(of: shiftDescription) { oldValue, newValue in
                if newValue.count > 500 {
                    shiftDescription = String(newValue.prefix(500))
                }
            }
    }
}

// In saveShiftType():
let newShiftType = ShiftType(
    id: shiftType?.id ?? UUID(),
    symbol: trimmedSymbol,
    duration: duration,
    title: trimmedTitle,
    shiftDescription: shiftDescription.isEmpty ? nil : shiftDescription,
    location: selectedLocation
)

// In onAppear:
if let shiftType = shiftType {
    shiftDescription = shiftType.shiftDescription ?? ""
}
```

**Testing:**
- Test entering multiline text
- Test character limit enforcement
- Test saving with description
- Test saving without description
- Test editing preserves description

---

### Task 2.3: Implement All Day Toggle
**Complexity:** Medium
**Estimated Time:** 2 hours
**Priority:** Critical
**Dependencies:** Task 1.1, Task 2.2

**Description:**
Add "All Day" toggle that conditionally shows/hides time pickers and updates duration type.

**Implementation Steps:**
1. Add `@State private var isAllDay: Bool = false` to view properties
2. Create new "Duration" section in form
3. Add Toggle("All Day", isOn: $isAllDay) to section
4. Conditionally render DatePickers based on isAllDay state
5. Update saveShiftType() to create correct Duration enum case
6. Update onAppear to set isAllDay when editing shift with .allDay duration
7. Set default times to 8:00 AM and 4:00 PM
8. Add validation that end time > start time (only when not all day)

**Acceptance Criteria:**
- [ ] Toggle appears in Duration section
- [ ] When ON: time pickers are hidden
- [ ] When OFF: time pickers are visible
- [ ] Default times are 8:00 AM - 4:00 PM
- [ ] Editing all-day shift sets toggle to ON
- [ ] Editing scheduled shift sets toggle to OFF and shows times
- [ ] Duration saves as .allDay or .scheduled correctly
- [ ] Validation prevents end time before start time

**Code Pattern:**
```swift
// Add state properties:
@State private var isAllDay: Bool = false
@State private var startTime: Date = {
    var components = DateComponents()
    components.hour = 8
    components.minute = 0
    return Calendar.current.date(from: components) ?? Date()
}()
@State private var endTime: Date = {
    var components = DateComponents()
    components.hour = 16
    components.minute = 0
    return Calendar.current.date(from: components) ?? Date()
}()

// In form:
Section("Duration") {
    Toggle("All Day", isOn: $isAllDay)

    if !isAllDay {
        DatePicker(
            "Start Time",
            selection: $startTime,
            displayedComponents: .hourAndMinute
        )

        DatePicker(
            "End Time",
            selection: $endTime,
            displayedComponents: .hourAndMinute
        )
    }
}

// Update validation:
var isValid: Bool {
    !title.trimmingCharacters(in: .whitespaces).isEmpty &&
    !symbol.trimmingCharacters(in: .whitespaces).isEmpty &&
    selectedLocation != nil &&
    (isAllDay || endTime > startTime)
}

// In saveShiftType():
let duration: ShiftType.Duration
if isAllDay {
    duration = .allDay
} else {
    let start = HourMinuteTime(from: startTime)
    let end = HourMinuteTime(from: endTime)
    duration = .scheduled(from: start, to: end)
}

// In onAppear:
if let shiftType = shiftType {
    switch shiftType.duration {
    case .allDay:
        isAllDay = true
    case .scheduled(let from, let to):
        isAllDay = false
        startTime = from.toDate()
        endTime = to.toDate()
    }
}
```

**Testing:**
- Test toggle switches states correctly
- Test time pickers show/hide correctly
- Test default times appear correctly
- Test validation prevents invalid time ranges
- Test editing all-day shift
- Test editing scheduled shift
- Test saving both duration types

---

### Task 2.4: Add Location Picker
**Complexity:** Medium
**Estimated Time:** 2 hours
**Priority:** Critical
**Dependencies:** Task 2.3

**Description:**
Add location picker that displays all saved locations and requires selection.

**Implementation Steps:**
1. Add `@State private var selectedLocation: Location?` to view properties
2. Access locations from Redux store: `store.state.locations.locations`
3. Create new "Location" section in form
4. Add Picker with all locations
5. Display location name in picker (not address)
6. Handle empty locations array (show warning)
7. Update validation to require location selection
8. Update saveShiftType() to use selectedLocation
9. Update onAppear to set selectedLocation when editing

**Acceptance Criteria:**
- [ ] Location picker appears in form
- [ ] Picker displays all saved locations by name
- [ ] Picker shows "Select Location" placeholder when none selected
- [ ] Location is required (Save disabled without selection)
- [ ] Empty locations shows warning banner
- [ ] Selected location saves correctly
- [ ] Editing populates selected location

**Code Pattern:**
```swift
// Add state property:
@State private var selectedLocation: Location?

// Access locations from store:
var availableLocations: [Location] {
    store.state.locations.locations
}

// Add to validation:
var isValid: Bool {
    !title.trimmingCharacters(in: .whitespaces).isEmpty &&
    !symbol.trimmingCharacters(in: .whitespaces).isEmpty &&
    selectedLocation != nil &&
    (isAllDay || endTime > startTime)
}

// In form:
Section("Location") {
    if availableLocations.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("No locations available")
                    .font(.callout)
                    .foregroundColor(.orange)
            }
            Text("Please create a location first before adding shift types.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    } else {
        Picker("Select Location", selection: $selectedLocation) {
            Text("Select Location")
                .tag(nil as Location?)

            ForEach(availableLocations) { location in
                Text(location.name)
                    .tag(location as Location?)
            }
        }
        .pickerStyle(.menu)
    }
}

// In saveShiftType():
guard let location = selectedLocation else {
    store.dispatch(action: .shiftTypes(.errorOccurred("Please select a location")))
    return
}

let newShiftType = ShiftType(
    id: shiftType?.id ?? UUID(),
    symbol: trimmedSymbol,
    duration: duration,
    title: trimmedTitle,
    shiftDescription: shiftDescription.isEmpty ? nil : shiftDescription,
    location: location
)

// In onAppear:
if let shiftType = shiftType {
    selectedLocation = shiftType.location
} else {
    // Auto-select first location if available
    selectedLocation = availableLocations.first
}
```

**Testing:**
- Test picker displays all locations
- Test selecting different locations
- Test empty locations shows warning
- Test Save disabled when no location selected
- Test editing preserves selected location
- Test auto-select first location when adding new

---

### Task 2.5: Update Shift Type Card Display
**Complexity:** Low
**Estimated Time:** 1 hour
**Priority:** Medium
**Dependencies:** Task 2.4

**Description:**
Update the ShiftTypeCard component to display location information and handle all-day duration.

**Implementation Steps:**
1. Open `ShiftTypesView.swift`
2. Locate `ShiftTypeCard` struct (around line 137)
3. Add location display with icon
4. Update time range display to show "All Day" when appropriate
5. Match design pattern from LocationCard (icon + text layout)
6. Ensure proper text truncation and spacing

**Acceptance Criteria:**
- [ ] Card displays location name with location icon
- [ ] Card shows "All Day" for all-day shifts
- [ ] Card shows time range for scheduled shifts
- [ ] Layout is clean and readable
- [ ] Text truncates properly on small screens
- [ ] Icons and text align correctly

**Code Pattern:**
```swift
struct ShiftTypeCard: View {
    let shiftType: ShiftType

    var durationText: String {
        switch shiftType.duration {
        case .allDay:
            return "All Day"
        case .scheduled(let from, let to):
            return "\(from.formatted()) - \(to.formatted())"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(shiftType.symbol)
                            .font(.title3)
                        Text(shiftType.title)
                            .font(.headline)
                            .lineLimit(1)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(durationText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(shiftType.location.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
```

**Testing:**
- Test card displays all information
- Test all-day duration shows "All Day"
- Test scheduled duration shows time range
- Test long location names truncate correctly
- Test layout on different screen sizes

---

## Phase 3: Validation & Business Logic

### Task 3.1: Implement Symbol Uniqueness Validation
**Complexity:** Medium
**Estimated Time:** 1 hour
**Priority:** Critical
**Dependencies:** Task 2.4

**Description:**
Validate that shift type symbols are unique (case-insensitive) across all shift types.

**Implementation Steps:**
1. Locate or create validation logic in middleware
2. When saving shift type, check if symbol already exists
3. Exclude current shift type ID when editing (allow keeping same symbol)
4. Return error if duplicate found
5. Display error message in form
6. Normalize symbol to uppercase for comparison

**Acceptance Criteria:**
- [ ] Duplicate symbols are detected (case-insensitive)
- [ ] Error message shows which symbol is duplicate
- [ ] Editing preserves ability to keep same symbol
- [ ] Error displays clearly in form
- [ ] Save is prevented when duplicate exists

**Code Pattern:**
```swift
// In ShiftTypesMiddleware:
case .saveShiftType(let shiftType):
    // Check for duplicate symbol
    let existingWithSymbol = state.shiftTypes.shiftTypes.filter {
        $0.symbol.uppercased() == shiftType.symbol.uppercased() &&
        $0.id != shiftType.id  // Exclude self when editing
    }

    if !existingWithSymbol.isEmpty {
        state.shiftTypes.errorMessage = "A shift type with symbol '\(shiftType.symbol)' already exists."
        state.shiftTypes.isLoading = false
        return
    }

    // Continue with save...
```

**Testing:**
- Test creating shift type with duplicate symbol
- Test editing shift type keeping same symbol
- Test editing shift type changing to duplicate symbol
- Test case-insensitive comparison
- Test error message displays correctly

---

### Task 3.2: Implement Time Range Validation
**Complexity:** Low
**Estimated Time:** 30 minutes
**Priority:** Critical
**Dependencies:** Task 2.3

**Description:**
Validate that end time is after start time for scheduled shifts.

**Implementation Steps:**
1. Add validation to `isValid` computed property in AddEditShiftTypeView
2. Check endTime > startTime only when isAllDay is false
3. Show inline error message when times are invalid
4. Disable Save button when invalid
5. Consider edge case of times being equal

**Acceptance Criteria:**
- [ ] Validation checks end > start for scheduled shifts
- [ ] All-day shifts bypass time validation
- [ ] Save button disabled when times invalid
- [ ] Error message displays when times invalid
- [ ] Equal times are treated as invalid

**Code Pattern:**
```swift
// Already partially implemented in Task 2.3:
var isValid: Bool {
    let hasValidBasicFields = !title.trimmingCharacters(in: .whitespaces).isEmpty &&
                              !symbol.trimmingCharacters(in: .whitespaces).isEmpty &&
                              selectedLocation != nil

    let hasValidTimes = isAllDay || (endTime > startTime)

    return hasValidBasicFields && hasValidTimes
}

// Optional: Add inline error message
if !isAllDay && endTime <= startTime {
    Section {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            Text("End time must be after start time")
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(.vertical, 4)
    }
}
```

**Testing:**
- Test end time before start time disables save
- Test end time equal to start time disables save
- Test end time after start time enables save
- Test all-day toggle bypasses validation

---

### Task 3.3: Implement Location Existence Validation
**Complexity:** Medium
**Estimated Time:** 1.5 hours
**Priority:** Critical
**Dependencies:** Task 2.4

**Description:**
Validate that selected location still exists before saving shift type, and handle deleted locations gracefully.

**Implementation Steps:**
1. In middleware, verify selected location exists in locations array
2. Check location by ID match (not reference equality)
3. If location deleted since sheet opened, show error
4. Provide clear error message with recovery option
5. Consider edge case of location edited (name/address changed)

**Acceptance Criteria:**
- [ ] Validation checks location exists in current locations array
- [ ] Location ID used for matching (not reference)
- [ ] Error shown if location was deleted
- [ ] Error message suggests selecting another location
- [ ] Edited location details (name/address) are accepted

**Code Pattern:**
```swift
// In ShiftTypesMiddleware:
case .saveShiftType(let shiftType):
    // Validate location exists
    let locationExists = state.locations.locations.contains { loc in
        loc.id == shiftType.location.id
    }

    if !locationExists {
        state.shiftTypes.errorMessage = "Selected location no longer exists. Please select another location."
        state.shiftTypes.isLoading = false
        return
    }

    // Get current location data (in case name/address changed)
    guard let currentLocation = state.locations.locations.first(where: { $0.id == shiftType.location.id }) else {
        state.shiftTypes.errorMessage = "Location error. Please reselect location."
        state.shiftTypes.isLoading = false
        return
    }

    // Update shift type with current location data
    let updatedShiftType = ShiftType(
        id: shiftType.id,
        symbol: shiftType.symbol,
        duration: shiftType.duration,
        title: shiftType.title,
        shiftDescription: shiftType.shiftDescription,
        location: currentLocation  // Use current location data
    )

    // Continue with save...
```

**Testing:**
- Test saving with valid location
- Test saving after location deleted (error)
- Test saving after location edited (accepts changes)
- Test error message displays correctly
- Test recovery by selecting different location

---

### Task 3.4: Add Character Limit Enforcement
**Complexity:** Low
**Estimated Time:** 30 minutes
**Priority:** Medium
**Dependencies:** Task 2.2

**Description:**
Enforce character limits on all text fields to prevent excessively long inputs.

**Implementation Steps:**
1. Add onChange handlers to Symbol, Title, and Description fields
2. Enforce limits: Symbol (3), Title (100), Description (500)
3. Truncate input when limit exceeded
4. Optionally show character count for Description field
5. Consider adding visual feedback when approaching limit

**Acceptance Criteria:**
- [ ] Symbol limited to 3 characters
- [ ] Title limited to 100 characters
- [ ] Description limited to 500 characters
- [ ] Limits enforced in real-time as user types
- [ ] Optional character count shown for Description

**Code Pattern:**
```swift
// Symbol field:
TextField("Symbol", text: $symbol)
    .textInputAutocapitalization(.characters)
    .onChange(of: symbol) { oldValue, newValue in
        if newValue.count > 3 {
            symbol = String(newValue.prefix(3))
        }
    }

// Title field:
TextField("Title", text: $title)
    .textInputAutocapitalization(.words)
    .onChange(of: title) { oldValue, newValue in
        if newValue.count > 100 {
            title = String(newValue.prefix(100))
        }
    }

// Description field (already in Task 2.2):
TextEditor(text: $shiftDescription)
    .frame(minHeight: 100)
    .onChange(of: shiftDescription) { oldValue, newValue in
        if newValue.count > 500 {
            shiftDescription = String(newValue.prefix(500))
        }
    }

// Optional character counter for description:
HStack {
    Spacer()
    Text("\(shiftDescription.count)/500")
        .font(.caption2)
        .foregroundColor(shiftDescription.count > 450 ? .orange : .secondary)
}
```

**Testing:**
- Test typing beyond each character limit
- Test pasting text that exceeds limits
- Test character counter updates correctly
- Test visual feedback (if implemented)

---

## Phase 4: Location Protection

### Task 4.1: Implement Location Deletion Protection Logic
**Complexity:** Medium
**Estimated Time:** 1.5 hours
**Priority:** Critical
**Dependencies:** Task 3.3

**Description:**
Prevent deletion of locations that are referenced by any shift types.

**Implementation Steps:**
1. Locate LocationsMiddleware delete handler
2. Before deleting location, check if any shift types use it
3. Count number of shift types using the location
4. If count > 0, dispatch error action with count
5. If count = 0, proceed with deletion
6. Update LocationsState to store deletion prevention error

**Acceptance Criteria:**
- [ ] Location deletion checks shift type references
- [ ] Deletion prevented when shift types use location
- [ ] Error message includes count of shift types
- [ ] Error message displayed to user
- [ ] Deletion proceeds normally when location not in use

**Code Pattern:**
```swift
// In LocationsMiddleware:
case .deleteLocation(let location):
    state.locations.isLoading = true
    state.locations.errorMessage = nil

    // Check if location is used by any shift types
    let shiftTypesUsingLocation = state.shiftTypes.shiftTypes.filter {
        $0.location.id == location.id
    }

    if !shiftTypesUsingLocation.isEmpty {
        let count = shiftTypesUsingLocation.count
        let message = "This location is used by \(count) shift type\(count == 1 ? "" : "s"). Remove those shift types first, then delete this location."
        state.locations.errorMessage = message
        state.locations.isLoading = false
        return
    }

    // Proceed with deletion
    do {
        var updatedLocations = state.locations.locations
        updatedLocations.removeAll { $0.id == location.id }

        try await persistenceService.saveLocations(updatedLocations)

        state.locations.locations = updatedLocations
        state.locations.isLoading = false
    } catch {
        state.locations.errorMessage = "Failed to delete location: \(error.localizedDescription)"
        state.locations.isLoading = false
    }
```

**Testing:**
- Test deleting location not in use (succeeds)
- Test deleting location used by 1 shift type (prevented)
- Test deleting location used by multiple shift types (prevented)
- Test error message displays count correctly
- Test error message cleared after dismissal

---

### Task 4.2: Add Location Deletion Alert in UI
**Complexity:** Low
**Estimated Time:** 45 minutes
**Priority:** Critical
**Dependencies:** Task 4.1

**Description:**
Update LocationsView to show a dedicated alert when location deletion is prevented.

**Implementation Steps:**
1. Open LocationsView.swift
2. Add state variable for deletion prevention alert
3. Check for specific error message pattern from middleware
4. Show alert instead of inline error for deletion prevention
5. Allow inline error for other error types
6. Ensure alert dismisses correctly

**Acceptance Criteria:**
- [ ] Alert appears when deletion prevented
- [ ] Alert has clear title and message
- [ ] Alert includes shift type count
- [ ] Alert has single "OK" button
- [ ] Alert dismisses correctly
- [ ] Other errors still show inline

**Code Pattern:**
```swift
// In LocationsView:
@State private var showDeletionPreventedAlert = false
@State private var deletionPreventionMessage = ""

// Monitor error changes:
.onChange(of: store.state.locations.errorMessage) { oldValue, newValue in
    if let message = newValue, message.contains("is used by") {
        deletionPreventionMessage = message
        showDeletionPreventedAlert = true
        // Clear error after showing alert
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            store.dispatch(action: .locations(.errorOccurred("")))
        }
    }
}

// Add alert:
.alert("Cannot Delete Location", isPresented: $showDeletionPreventedAlert) {
    Button("OK", role: .cancel) {
        showDeletionPreventedAlert = false
        deletionPreventionMessage = ""
    }
} message: {
    Text(deletionPreventionMessage)
}

// Update error display to exclude deletion errors:
if let error = store.state.locations.errorMessage, !error.contains("is used by") {
    // Show inline error banner
}
```

**Testing:**
- Test alert appears for deletion prevention
- Test alert shows correct message with count
- Test alert dismisses correctly
- Test other errors still show inline
- Test no double error display

---

## Phase 5: Testing & Polish

### Task 5.1: Add Unit Tests for Validation Logic
**Complexity:** Medium
**Estimated Time:** 1.5 hours
**Priority:** High
**Dependencies:** Phase 3 complete

**Description:**
Create comprehensive unit tests for all validation logic.

**Implementation Steps:**
1. Create or update test file for shift type validation
2. Test symbol uniqueness validation
3. Test time range validation
4. Test location existence validation
5. Test character limit enforcement
6. Test all edge cases documented in PRD
7. Use Swift Testing framework with @Test macro

**Acceptance Criteria:**
- [ ] All validation functions have test coverage
- [ ] Edge cases are tested
- [ ] Tests use #expect assertions (not XCTest)
- [ ] Tests are isolated and independent
- [ ] All tests pass

**Code Pattern:**
```swift
import Testing
@testable import ShiftScheduler

@Suite("Shift Type Validation Tests")
struct ShiftTypeValidationTests {

    @Test("Symbol uniqueness validation")
    func testSymbolUniqueness() async throws {
        // Test duplicate symbol detection
        // Test case-insensitive matching
        // Test editing preserves same symbol
    }

    @Test("Time range validation")
    func testTimeRangeValidation() async throws {
        // Test end > start is valid
        // Test end < start is invalid
        // Test end == start is invalid
        // Test all-day bypasses validation
    }

    @Test("Location existence validation")
    func testLocationExistence() async throws {
        // Test valid location passes
        // Test deleted location fails
        // Test updated location accepted
    }

    @Test("Character limit enforcement")
    func testCharacterLimits() async throws {
        // Test symbol limit 3
        // Test title limit 100
        // Test description limit 500
    }
}
```

**Testing:**
- Run all tests and verify they pass
- Check test coverage is adequate
- Verify tests run quickly (< 1 second total)

---

### Task 5.2: Integration Testing
**Complexity:** Medium
**Estimated Time:** 1 hour
**Priority:** High
**Dependencies:** Phase 4 complete

**Description:**
Test complete user flows end-to-end to verify all features work together.

**Implementation Steps:**
1. Test complete add shift type flow
2. Test complete edit shift type flow
3. Test location deletion prevention flow
4. Test all validation error flows
5. Test sheet dismissal in all scenarios
6. Document any bugs found

**Test Scenarios:**
1. **Happy Path - Add Shift Type:**
   - Open ShiftTypesView
   - Tap Add button
   - Fill all fields (including description)
   - Toggle All Day on and off
   - Select location
   - Tap Save
   - Verify shift type appears in list
   - Verify sheet dismisses

2. **Happy Path - Edit Shift Type:**
   - Tap existing shift type
   - Modify fields
   - Change location
   - Tap Save
   - Verify changes persist
   - Verify sheet dismisses

3. **Error Path - No Locations:**
   - Delete all locations
   - Try to add shift type
   - Verify warning banner shows
   - Verify Save disabled

4. **Error Path - Duplicate Symbol:**
   - Create shift type with symbol "M"
   - Try to create another with symbol "M"
   - Verify error message
   - Verify Save prevented

5. **Error Path - Invalid Times:**
   - Set end time before start time
   - Verify Save disabled
   - Verify error message

6. **Protection Path - Location Deletion:**
   - Create location
   - Create shift type using location
   - Try to delete location
   - Verify deletion prevented
   - Verify alert shows

**Acceptance Criteria:**
- [ ] All happy path scenarios complete successfully
- [ ] All error scenarios show appropriate messages
- [ ] No crashes or unexpected behavior
- [ ] UI responds correctly to all interactions
- [ ] Data persists correctly across scenarios

**Testing:**
- Test on iOS 26.0 simulator
- Test on different device sizes (iPhone SE, Pro Max)
- Test with different data volumes (0, 1, 10 items)
- Test rapid interactions (tap Save multiple times, etc.)

---

### Task 5.3: UI Polish and Accessibility
**Complexity:** Low
**Estimated Time:** 1 hour
**Priority:** Medium
**Dependencies:** Phase 2 complete

**Description:**
Polish UI details and ensure accessibility compliance.

**Implementation Steps:**
1. Verify all form fields have proper labels
2. Add accessibility labels to icons and buttons
3. Test VoiceOver navigation
4. Verify color contrast meets WCAG standards
5. Test with Dynamic Type (larger text sizes)
6. Add haptic feedback for important actions (optional)
7. Ensure keyboard dismissal works everywhere

**Acceptance Criteria:**
- [ ] All interactive elements have accessibility labels
- [ ] VoiceOver can navigate entire form
- [ ] Color contrast passes WCAG AA standards
- [ ] Layout works with largest Dynamic Type size
- [ ] Keyboard dismissal works on all screens
- [ ] Error messages are announced by VoiceOver

**Code Pattern:**
```swift
// Add accessibility labels:
Button("Save") { ... }
    .accessibilityLabel("Save shift type")
    .accessibilityHint("Saves the shift type and closes the form")

Image(systemName: "location.fill")
    .accessibilityLabel("Location")

// Ensure proper labeling:
TextEditor(text: $shiftDescription)
    .accessibilityLabel("Shift description")
    .accessibilityHint("Optional description for the shift type")

// Test with VoiceOver:
// - Navigate through all fields
// - Verify labels are read correctly
// - Test form submission flow
```

**Testing:**
- Enable VoiceOver and navigate entire form
- Test with largest text size in Settings
- Verify all colors have sufficient contrast
- Test haptic feedback (if added)

---

## Implementation Order Summary

**Recommended implementation order for maximum efficiency:**

1. **Day 1 (Foundation):**
   - Task 1.1: Update Domain Models (30 min)
   - Task 1.2: Update Redux State (30 min)
   - Task 1.3: Verify Redux Actions (30 min)
   - Task 2.1: Fix Sheet Dismissal (15 min)
   - Task 2.2: Add Description Field (1 hour)
   - **Total: ~3 hours**

2. **Day 2 (Core UI):**
   - Task 2.3: Implement All Day Toggle (2 hours)
   - Task 2.4: Add Location Picker (2 hours)
   - Task 2.5: Update Shift Type Card Display (1 hour)
   - **Total: ~5 hours**

3. **Day 3 (Validation):**
   - Task 3.1: Symbol Uniqueness Validation (1 hour)
   - Task 3.2: Time Range Validation (30 min)
   - Task 3.3: Location Existence Validation (1.5 hours)
   - Task 3.4: Character Limit Enforcement (30 min)
   - Task 4.1: Location Deletion Protection Logic (1.5 hours)
   - **Total: ~5 hours**

4. **Day 4 (Testing & Polish):**
   - Task 4.2: Location Deletion Alert UI (45 min)
   - Task 5.1: Unit Tests (1.5 hours)
   - Task 5.2: Integration Testing (1 hour)
   - Task 5.3: UI Polish and Accessibility (1 hour)
   - **Total: ~4.25 hours**

**Total Estimated Time: 17.25 hours (3-4 working days)**

---

## Risk Mitigation

### High-Risk Areas:
1. **Location reference integrity** - Mitigated by Task 3.3 and Task 4.1
2. **Redux state synchronization** - Mitigated by following existing patterns
3. **Form validation complexity** - Mitigated by incremental validation in Phase 3

### Dependencies on Existing Code:
- LocationsView pattern must remain stable
- Redux architecture must not change during implementation
- Persistence service must support shift type model changes

### Testing Strategy:
- Unit tests for each validation function
- Integration tests for complete user flows
- Manual testing on multiple device sizes
- Accessibility testing with VoiceOver

---

## Success Criteria

**The implementation is complete when:**
- [ ] All 17 tasks are completed and tested
- [ ] All acceptance criteria met
- [ ] No compiler errors or warnings
- [ ] All unit tests pass
- [ ] All integration test scenarios pass
- [ ] VoiceOver navigation works correctly
- [ ] No force unwrapping (!) in code
- [ ] Code follows Swift 6 concurrency rules
- [ ] Redux architecture patterns followed consistently
- [ ] User can complete all CRUD operations successfully

---

## Post-Implementation Checklist

Before considering the feature complete:
- [ ] Code review completed
- [ ] All tests passing
- [ ] Documentation updated (if needed)
- [ ] Accessibility verified
- [ ] Performance tested (no lag with 50+ shift types)
- [ ] Build succeeds with zero warnings
- [ ] Feature tested on iOS 26.0 simulator
- [ ] Edge cases verified from PRD Section 6
- [ ] User experience validated against PRD Section 4

---

**Document Status:** Ready for Implementation
**Last Updated:** October 26, 2025
**Estimated Completion:** November 1, 2025 (given 4 full working days)
