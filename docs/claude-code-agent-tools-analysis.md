# Claude Code Agent Tool Configuration Analysis

Based on my analysis of the 8 Claude Code sub-agent definitions, here's a comprehensive report on how to "right-size" each agent's tools section:

## Agent Tool Configuration Analysis

### 1. **ios-senior-engineer**
- **Current tools**: Edit, Write, Grep, Bash
- **Purpose**: iOS development tasks, SwiftUI implementations, functional programming patterns, Swift code architecture decisions
- **Recommended tools**: Edit, Write, Grep, Bash, **Read**, **MultiEdit**
- **Rationale**: Missing `Read` (essential for examining existing code before making changes) and `MultiEdit` (useful for large refactoring tasks common in architectural decisions)

### 2. **ios-systems-architect**
- **Current tools**: Edit, Write, Grep, Bash, Read
- **Purpose**: Architectural decisions, system design discussions, scalability planning, establishing technical standards
- **Recommended tools**: Edit, Write, Grep, Bash, Read, **Glob**, **TodoWrite**
- **Rationale**: Well-configured but would benefit from `Glob` (finding architectural patterns across codebases) and `TodoWrite` (planning complex architectural initiatives)

### 3. **product-project-manager**
- **Current tools**: Edit, MultiEdit, Write, NotebookEdit, Read, Grep, LS
- **Purpose**: Product planning, requirement generation, project scope definition, task breakdown, project management
- **Recommended tools**: ~~Edit~~, ~~MultiEdit~~, Write, NotebookEdit, Read, ~~Grep~~, **TodoWrite**, **WebSearch**
- **Rationale**: Over-tooled for coding tasks they shouldn't be doing. Missing `TodoWrite` (critical for task management) and `WebSearch` (market research). Should focus on documentation and planning tools.

### 4. **research-specialist**
- **Current tools**: WebSearch, Write, Edit, Bash
- **Purpose**: Technology research, library comparisons, framework evaluations, staying current with emerging technologies
- **Recommended tools**: WebSearch, Write, ~~Edit~~, ~~Bash~~, **Read**, **Grep**, **WebFetch**, **Glob**
- **Rationale**: Should focus on research tools. Needs `Read` (examining documentation), `Grep` (searching codebases), `WebFetch` (accessing web resources), `Glob` (finding usage patterns). Doesn't need code editing capabilities.

### 5. **senior-code-reviewer**
- **Current tools**: Edit, Grep, Read, Bash
- **Purpose**: Code quality assessment, identifying improvements, providing educational feedback
- **Recommended tools**: Edit, Grep, Read, Bash, **Glob**, **MultiEdit**
- **Rationale**: Well-configured but would benefit from `Glob` (finding code patterns for review) and `MultiEdit` (suggesting comprehensive refactors)

### 6. **senior-qe-engineer**
- **Current tools**: Edit, Write, Grep, Bash, Read
- **Purpose**: Code validation, testing strategies, quality assessment, identifying edge cases
- **Recommended tools**: Edit, Write, Grep, Bash, Read, **Glob**, **TodoWrite**
- **Rationale**: Good foundation but needs `Glob` (finding test patterns and coverage gaps) and `TodoWrite` (test planning and tracking)

### 7. **swiftui-engineer**
- **Current tools**: "*" (all tools)
- **Purpose**: Modern SwiftUI development (iOS 17+), UI components, state management, animations, navigation
- **Recommended tools**: Edit, MultiEdit, Write, Read, Grep, Glob, Bash, **TodoWrite**
- **Rationale**: Having all tools is excessive. Should focus on development tools most relevant to SwiftUI work. Add `TodoWrite` for feature planning.

### 8. **ui-design-expert**
- **Current tools**: Glob, Grep, Read, WebFetch, TodoWrite, WebSearch, BashOutput, KillShell
- **Purpose**: Interface design, visual aesthetics, UX improvements, design system creation, interface critiques
- **Recommended tools**: ~~Glob~~, ~~Grep~~, Read, WebFetch, TodoWrite, WebSearch, **Write**, ~~BashOutput~~, ~~KillShell~~
- **Rationale**: Oddly configured with technical tools they don't need. Should focus on research and documentation tools. Needs `Write` for design specifications. Remove unnecessary technical tools.

## Key Findings

**Most Over-tooled**:
- `swiftui-engineer` (has all tools unnecessarily)
- `ui-design-expert` (has technical tools inappropriate for design work)

**Most Under-tooled**:
- `product-project-manager` (missing `TodoWrite` for core PM functionality)
- `research-specialist` (missing key research tools like `Read`, `WebFetch`)

**Common Missing Tools**:
- `TodoWrite` - needed by project-oriented agents for task planning
- `Glob` - needed by agents who analyze code patterns
- `Read` - essential for agents who need to examine existing code

**Tools to Remove**:
- Technical agents don't need `BashOutput`/`KillShell`
- Non-technical agents don't need `Edit`/`MultiEdit`
- Design-focused agents don't need code search tools

The key principle should be: **each agent should have the minimum viable toolset that enables their core responsibilities without scope creep**.