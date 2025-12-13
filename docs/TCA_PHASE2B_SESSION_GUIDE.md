# TCA Phase 2B - Session Guide

## How to Use This Tracking System

This guide explains how to use the task tracking system for consistent progress tracking across multiple sessions.

---

## 📋 The Three Tracking Documents

### 1. **TCA_PHASE2B_TASK_CHECKLIST.md** (Primary Reference)
**Purpose**: Detailed task-by-task breakdown with acceptance criteria and notes
**Use When**:
- Starting a new task - read the acceptance criteria
- Stuck on implementation - check the notes section
- Need to understand task dependencies
- Want session recommendations

### 2. **Active Todo List in Claude Code** (Session Tracker)
**Purpose**: Quick status updates between sessions
**Use When**:
- Finishing a task - mark as completed
- Starting next session - see what's pending
- Need quick overview of progress
- Sharing status with team

### 3. **This Guide** (Workflow Reference)
**Purpose**: Instructions on how to use the tracking system
**Use When**:
- Starting a new session
- Need to understand the workflow
- Want best practices for tracking

---

## 🚀 Start of Session Workflow

When you begin a new session:

### 1. Review Current Status
```
Ask: "What tasks are currently pending in the todo list?"
Claude Code will show all active todos with their status
```

### 2. Pick Your Task
```
Choose from pending tasks based on:
- Task dependencies (look at TCA_PHASE2B_TASK_CHECKLIST.md)
- Your available time (check estimated hours)
- Prerequisites (must complete tasks in order shown)

Recommended approach:
- Start with Task 1 if just beginning
- Complete dependent tasks in order
- Can work on parallel tasks if needed
```

### 3. Reference the Checklist
```
Open: TCA_PHASE2B_TASK_CHECKLIST.md
Look up your task number for:
- Acceptance Criteria ✓
- Implementation Checklist ✓
- Expected Time ⏱️
- Files to Modify 📝
- Notes & Tips 💡
```

### 4. Mark Task as In Progress
```
Ask: "Mark task X as in_progress"
Claude Code will update the todo list
Status changes from ⏹️ pending → ⏳ in_progress
```

---

## 💻 During Session Workflow

### If You Complete the Task
```
Ask: "Mark task X as completed"
Claude Code updates the todo list
Status changes from ⏳ in_progress → ✅ completed
Progress automatically updates

Example:
Before: 2/14 tasks complete (14%)
After:  3/14 tasks complete (21%)
```

### If You Get Stuck
```
1. Check the "Notes" section in TCA_PHASE2B_TASK_CHECKLIST.md
2. Review the specific checklist items
3. Look at dependency tasks - may need to complete those first
4. Ask Claude Code for specific help with the issue
```

### If You Need to Save Progress (but task isn't done)
```
Request: "Create a brief git commit for the work in progress"
This saves your progress without marking task as complete

Leave task as ⏳ in_progress so it shows up next session
```

---

## 📍 End of Session Workflow

Before stopping work:

### 1. Commit Your Work
```bash
git add .
git commit -m "WIP: Task X - [brief description]"
```

### 2. Update Todo Status
```
Ask: "Update the todo status for task X"
- If complete: mark as completed ✅
- If in progress: leave as in_progress ⏳ (will show next session)
- If not started: leave as pending ⏹️
```

### 3. Add Session Notes (Optional but Recommended)
```
Request: "Add a note to Task X in the checklist"
This helps future you remember:
- What you accomplished
- What's left
- Any blockers or learnings
- Next steps

Example note:
"✅ Completed: ShiftSwitchClient created with all 5 methods
⏳ Next: Integrate with TodayFeature in next session
🚫 Blocker: None
💡 Learned: ShiftSwitchService uses actor isolation"
```

### 4. Summary (Optional)
```
Update your git commit message if needed:
git commit --amend -m "Task X - [final summary]"
```

---

## 🔄 Multi-Session Example Workflow

### Session 1: Task 1 (ShiftSwitchClient)
```
Start of Session:
  Q: "What's currently pending?"
  → Shows 14 tasks, Task 1 is first

During Session:
  1. Open TCA_PHASE2B_TASK_CHECKLIST.md → Task 1 section
  2. Mark Task 1 as in_progress
  3. Follow implementation checklist
  4. Create ShiftScheduler/Dependencies/ShiftSwitchClient.swift

End of Session:
  1. Make git commit
  2. Task 1 complete? Mark as completed ✅
  3. Add note: "ShiftSwitchClient working, ready for Task 2"
```

### Session 2: Task 2 (TodayFeature - Part 1)
```
Start of Session:
  Q: "Show me the status"
  → Shows Task 1 ✅ complete, Task 2 ⏳ selected

During Session:
  1. Open TCA_PHASE2_TODAYVIEW_MIGRATION.md (detailed design)
  2. Open TCA_PHASE2B_TASK_CHECKLIST.md (Task 2 section)
  3. Create ShiftScheduler/Features/TodayFeature.swift
  4. Implement State struct and Action enum

End of Session:
  1. Partial work on Task 2
  2. Leave as in_progress ⏳
  3. Add note: "State & Actions done, need reducer implementation"
```

### Session 3: Task 2 (TodayFeature - Part 2)
```
Start of Session:
  Q: "Resume task 2"
  → Shows Task 2 ⏳ in_progress with previous notes

During Session:
  1. Reference previous session notes
  2. Continue with reducer implementation
  3. Complete remaining checklist items

End of Session:
  1. Task 2 complete ✅
  2. Mark as completed
  3. Note: "Reducer done, 6/14 tests would be good next"
```

---

## 📊 Tracking Progress

### View Overall Progress
```
The todo list shows completion percentage:

Tasks Completed:
✅ 1/14 = 7% (After Session 1)
✅ 2/14 = 14% (After Session 2-3)
✅ 3/14 = 21% (After next feature)
...
✅ 14/14 = 100% (Phase 2B Complete!)
```

### Recommended Pace
```
If 2-3 hours per session:
- 2-3 tasks per week (14-18 hours/week)
- 2-3 weeks total for Phase 2B
- 7-10 sessions total

If 1 hour per session:
- 1 task per week
- 3-4 weeks total
- 14-20 sessions total
```

---

## 🎯 Task Dependency Chain

These tasks MUST be done in order:

```
Task 1 (2-3 hrs)
  ↓
Task 2 (4-6 hrs)
  ├── Task 3 (2-3 hrs)
  └── Task 4 (2-3 hrs)

Can do in parallel after Task 1:
  Task 5 → Task 6
  Task 7 → Task 8 & Task 9
  Task 10 (anytime)
  Task 11 (anytime)

After all features done:
  Task 12 (3-4 hrs)
  Task 13 (2 hrs)
  Task 14 (1 hr)
```

---

## ✅ Quality Checklist

Before marking a task as "completed", verify:

- [ ] Code compiles without errors
- [ ] All items in the task's "Acceptance Criteria" are met
- [ ] All items in the task's "Implementation Checklist" are done
- [ ] File modifications match what was planned
- [ ] Tests pass (if applicable)
- [ ] No new warnings introduced
- [ ] Code follows project conventions (see CLAUDE.md)

---

## 💡 Pro Tips

1. **Read Ahead**: Before ending a session, peek at the next task requirements
2. **Stack Tasks**: If Task 2 takes only 4 hours instead of 6, start Task 5 in same session
3. **Keep Notes**: Brief notes in checklist help future sessions move faster
4. **Pair Session Tasks**: Tasks 3 & 4 are good for same session (both depend on Task 2)
5. **Save Often**: Don't wait until task is "done" - commit regularly
6. **Reference Documentation**: Always check TCA_PHASE2_TODAYVIEW_MIGRATION.md before coding

---

## 🚨 If You Get Blocked

### Blocker: Task depends on incomplete prerequisite
```
Solution: Complete prerequisite first
Check dependency chain in TCA_PHASE2B_TASK_CHECKLIST.md
```

### Blocker: Don't understand how to implement
```
Solution:
1. Check "Notes" section in task checklist
2. Review similar completed task (e.g., LocationsFeature for reference)
3. Check TCA documentation links
4. Ask Claude Code for specific implementation help
```

### Blocker: Merge conflict or git issue
```
Solution:
1. Don't abandon work - stash or branch
2. Resolve conflicts before committing
3. Update todo list when resolved
```

### Blocker: Build errors after changes
```
Solution:
1. Run clean build: xcodebuild clean build
2. Check compilation output for specific errors
3. Revert if needed and try different approach
4. Leave task as in_progress if you need next session
```

---

## 📱 Quick Command Reference

```bash
# View todo status anytime
Ask: "Show the todo list status"

# Mark task complete
Ask: "Mark task X as completed"

# Mark task in progress
Ask: "Mark task X as in_progress"

# View specific task details
Ask: "Show details for task X from the checklist"

# Get time estimates
Ask: "What's the estimated time for remaining tasks?"

# See what's blocking
Ask: "What tasks are blocking others?"
```

---

## 🏁 Completion Definition

**Phase 2B is complete when:**

✅ All 14 tasks marked as completed
✅ All views compile without errors
✅ All features have unit tests
✅ Integration tests pass
✅ Performance acceptable
✅ Zero singletons accessed from views

**Success Metrics:**
- 100% of business logic in TCA features
- 100% of views using stores
- >80% test coverage
- Build time < 30 seconds
- No architecture-related warnings

---

## 📞 Session Handoff Template

Use this when stopping work to help next session:

```markdown
## Session Summary

**Date**: [Date]
**Duration**: [Hours]
**Tasks Completed**: [List with checkmarks]
**Tasks In Progress**: [Task X - description of where stopped]

### What Was Done
- [Specific accomplishments]
- [Code changes]
- [Tests added]

### What's Next
- [Next task to work on]
- [Any preparation needed]
- [Dependencies to check]

### Blockers/Learnings
- [Any issues encountered]
- [Solutions discovered]
- [Tips for next session]

### Git Status
- Commits: [List of commit messages]
- Branches: [Current branch]
- Ready to push? [Yes/No]
```

---

**Happy coding! 🚀**

Remember: Track tasks consistently so you can pick up right where you left off!
