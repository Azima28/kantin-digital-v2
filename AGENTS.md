# Kantin Digital — Agent Coordination Guide

## Agent Routing

| Task | Agents | Topology |
|------|--------|----------|
| **New Feature** | architect, coder, tester, reviewer | Hierarchical |
| **Bug Fix** | researcher, coder, tester | Hierarchical |
| **UI Polish** | designer, coder | Pipeline |
| **Database Change** | architect, coder, reviewer | Hierarchical |
| **Auth / Security** | security-architect, coder, reviewer | Hierarchical |
| **Refactor** | architect, coder, reviewer | Hierarchical |
| **Research** | researcher | Single |

## Agent Roles for This Project

| Agent | Responsibility |
|-------|---------------|
| **architect** | Design feature architecture, plan file changes, define data flow |
| **coder** | Implement Flutter/Dart code following the rules in CLAUDE.md |
| **tester** | Write widget/unit tests, verify UI states |
| **reviewer** | Review code quality, security, adherence to design rules |
| **researcher** | Investigate bugs, read docs, find solutions |
| **designer** | UI/UX refinement, theme updates, asset management |

## Pipeline Patterns

### Feature Development
```
architect → coder → tester → reviewer
```
- Architect produces a plan with exact file paths and data flow
- Coder implements feature following Feature-First pattern
- Tester adds widget tests for all states (loading, empty, error, success)
- Reviewer checks: AppColors usage, AppStrings usage, security rules, RPC compliance

### Bug Fix
```
researcher → coder → tester
```
- Researcher investigates root cause (check docs, recent commits, error logs)
- Coder implements fix
- Tester adds regression test

### Database Migration
```
architect → coder → reviewer
```
- Architect designs schema change + RPC function update
- Coder writes migration SQL + updates Dart models
- Reviewer checks RLS policies and RPC security

## Communication Rules
- Each agent messages the next in the pipeline with: work summary, changed files, decisions made
- NO polling — agent automatically sends handoff when complete
- If blocked or needs clarification, agent `SendMessage` to the coordinator

## Critical Rules for All Agents

### DO NOT
- Directly mutate student balance via `supabase.from('students').update()` — use RPC `process_purchase` / `process_refund`
- Use hardcoded colors — ALWAYS reference `AppColors.*`
- Use inline strings — ALWAYS reference `AppStrings.*`
- Create screens outside `lib/features/<feature>/screens/`
- Modify `AppRouter` without checking all route definitions
- Skip state handling (loading, empty, error, success required for every screen)

### ALWAYS
- Run `flutter analyze` before completing a coding task
- Run existing tests before adding new ones
- Update `docs/implementasi/progress_tugas.md` when completing a task
- Check `docs/implementasi/catatan_perbaikan.md` for known issues
