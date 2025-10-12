# Pending Tasks - ShiftScheduler

## Known Issues

### MockCalendarService Protocol Conformance Issue

**Status:** Pending user guidance
**Priority:** Medium
**Created:** 2025-10-10

**Description:**
There's a Swift compiler bug where `@Observable` classes cannot properly conform to protocols when used with `@testable import` across module boundaries. This prevents `MockCalendarService` from compiling in tests, despite having identical type signatures to the protocol requirements.

**Current State:**
- CalendarService uses `@Observable` macro for state management
- CalendarServiceProtocol is defined in main target
- MockCalendarService in test target cannot conform to protocol due to compiler limitation
- Error: "type 'MockCalendarService' does not conform to protocol 'CalendarServiceProtocol'"
- All method signatures match but compiler reports type mismatch

**Impact:**
- Unit tests that depend on MockCalendarService cannot compile
- Main application is fully functional
- All other tests (domain models, repositories, etc.) work correctly

**Potential Solutions:**
1. Remove `@Observable` from CalendarService and use alternative state management
2. Use dependency injection with concrete types instead of protocols for CalendarService
3. Move MockCalendarService into main target
4. Create a type-erased wrapper (AnyCalendarService already created but not fully integrated)
5. Wait for Apple to fix Swift compiler bug

**Files Involved:**
- `ShiftScheduler/Services/CalendarService.swift` - Uses @Observable
- `ShiftScheduler/Protocols/CalendarServiceProtocol.swift` - Protocol definition
- `ShiftSchedulerTests/Mocks/MockCalendarService.swift` - Mock that won't compile
- `ShiftScheduler/Services/AnyCalendarService.swift` - Type-erased wrapper (created but not used)

**Next Steps:**
User will inspect the issue and provide guidance on the preferred solution approach.

---

## Future Enhancements

### From PRD Section 12 - Future Enhancements

**Short-term (Next Release):**
- Bulk shift switching (select multiple dates)
- Change log export (CSV, PDF)
- Advanced filtering (custom date ranges, complex queries)
- Statistics dashboard (most changed shifts, etc.)

**Medium-term (3-6 months):**
- Team collaboration features (share change logs)
- Shift swap requests (between users)
- Approval workflows for shift changes
- Integration with external scheduling systems

**Long-term (6+ months):**
- AI-powered shift suggestions
- Predictive analytics on shift patterns
- Automated conflict detection
- Calendar sync across platforms (Google Calendar, Outlook)
