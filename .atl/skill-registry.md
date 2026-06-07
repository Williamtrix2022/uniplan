# Skill Registry

**Delegator use only.** Any agent that launches sub-agents reads this registry to resolve compact rules, then injects them directly into sub-agent prompts. Sub-agents do NOT read this registry or individual SKILL.md files.

See `_shared/skill-resolver.md` for the full resolution protocol.

## User Skills

| Trigger | Skill | Path |
|---------|-------|------|
| when writing guides, READMEs, RFCs, onboarding docs, architecture docs, or review-facing documentation | cognitive-doc-design | C:\Users\WINDOWS1164\.claude\skills\cognitive-doc-design\SKILL.md |
| when drafting or posting feedback, review comments, maintainer replies, Slack messages, or GitHub comments | comment-writer | C:\Users\WINDOWS1164\.claude\skills\comment-writer\SKILL.md |
| when writing Go tests, using teatest, or adding test coverage | go-testing | C:\Users\WINDOWS1164\.claude/skills/go-testing/SKILL.md |
| "judgment day", "judgment-day", "review adversarial", "dual review", "doble review", "juzgar", "que lo juzguen" | judgment-day | C:\Users\WINDOWS1164\.claude/skills/judgment-day/SKILL.md |
| when user asks to create a new skill, add agent instructions, or document patterns for AI | skill-creator | C:\Users\WINDOWS1164\.claude/skills/skill-creator/SKILL.md |
| when a PR would exceed 400 changed lines, when planning chained PRs, stacked PRs, or reviewable slices | gentle-ai-chained-pr | C:\Users\WINDOWS1164\.claude/skills/chained-pr/SKILL.md |
| when implementing a change, preparing commits, splitting PRs, or planning chained or stacked PRs | work-unit-commits | C:\Users\WINDOWS1164\.claude/skills/work-unit-commits/SKILL.md |
| when creating a pull request, opening a PR, or preparing changes for review | branch-pr | C:\Users\WINDOWS1164\.claude/skills/branch-pr/SKILL.md |
| when creating a GitHub issue, reporting a bug, or requesting a feature | issue-creation | C:\Users\WINDOWS1164\.claude/skills/issue-creation/SKILL.md |

## Project Skills

| Trigger | Skill | Path |
|---------|-------|------|
| addressing "RenderFlex overflowed", "Vertical viewport was given unbounded height", or similar layout issues | flutter-fix-layout-issues | C:\Users\WINDOWS1164\Documents\FlutterProjects\uniplan\.agents/skills/flutter-fix-layout-issues/SKILL.md |
| structuring a new project or refactoring for scalability | flutter-apply-architecture-best-practices | C:\Users\WINDOWS1164\Documents\FlutterProjects/uniplan\.agents/skills/flutter-apply-architecture-best-practices/SKILL.md |

## Compact Rules

Pre-digested rules per skill. Delegators copy matching blocks into sub-agent prompts as `## Project Standards (auto-resolved)`.

### cognitive-doc-design
- Lead with the answer — put decision, action, or outcome first, context after
- Progressive disclosure — happy path first, then details, edge cases, references
- Chunking — group related info into small sections, keep flat lists short
- Signposting — use headings, labels, callouts, summaries so readers know where they are
- Recognition over recall — prefer tables, checklists, examples over prose that must be remembered
- Review empathy — design docs so reviewers verify intent without reconstructing story

### comment-writer
- Be useful fast — start with actionable point, do not recap whole PR before feedback
- Be warm and direct — sound like thoughtful teammate, not corporate bot
- Keep it short — 1-3 short paragraphs or tight bullet list
- Explain why — give technical reason when asking for change
- Avoid pile-ons — comment on highest-value issue, not every tiny preference
- Match thread language — write in thread/user language (Rioplatense Spanish/voseo for Spanish threads)
- No em dashes — use commas, periods, or parentheses instead

### go-testing
- Table-driven tests for multiple test cases with struct containing name/input/expected/wantErr
- Test Model.Update() directly for Bubbletea state transitions
- Use teatest.NewTestModel() for full TUI integration flows
- Use golden file testing for visual output comparison
- Test both success and error cases, mock dependencies for side effects

### judgment-day
- Launch TWO independent blind judge sub-agents in parallel via delegate
- Neither agent knows about the other — no cross-contamination
- Synthesize verdict: confirmed (both found), suspect (one found), contradiction (disagree)
- Classify warnings: WARNING (real) = can normal user trigger this?; WARNING (theoretical) = contrived scenario
- After fixes, re-launch both judges — do not commit until re-judgment passes
- After 2 iterations, ask user before continuing

### skill-creator
- Create skill when pattern used repeatedly and AI needs guidance
- Structure: skills/{skill-name}/SKILL.md required, assets/ and references/ optional
- Frontmatter: name, description (with trigger), license (Apache-2.0), metadata.author/version
- Critical patterns first, tables for decision trees, minimal code examples
- Do not add Keywords section — agent searches frontmatter, not body

### gentle-ai-chained-pr
- MUST split when PR exceeds 400 changed lines unless maintainer-approved size:exception
- Design each PR for ≤60-minute human review
- Every chained PR must state start, end, what came before, what comes next
- One deliverable work unit per PR, autonomy requirements: CI green, reasonable rollback
- Include dependency diagram marking current PR position
- For >2 PRs, create draft tracker PR before review

### work-unit-commits
- Commit by work unit — deliverable behavior, fix, migration, or docs
- Do NOT commit by file type (models, then services, then tests)
- Keep tests with code they're verifying
- Keep docs with user-visible change they explain
- Reviewer should understand why each commit exists from diff and message

### branch-pr
- Every PR MUST link approved issue — no exceptions
- Every PR MUST have exactly one type:* label
- Automated checks must pass before merge
- Branch name: ^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)/[a-z0-9._-]+$
- Conventional commits: ^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+

### issue-creation
- Blank issues disabled — MUST use template (bug report or feature request)
- Every issue gets status:needs-review automatically
- Maintainer MUST add status:approved before PR can be opened
- Questions go to Discussions, not issues

### flutter-fix-layout-issues
- Constraints go down, sizes go up, parent sets position
- "Vertical viewport unbounded height": wrap scrollable in Expanded or SizedBox
- "InputDecorator unbounded width": wrap TextField in Expanded/Flexible
- "RenderFlex overflowed": wrap child in Expanded (force fit) or Flexible (allow smaller)
- "Incorrect use of ParentData widget": move to direct child of required parent

### flutter-apply-architecture-best-practices
- UI Layer: MVVM (Views = lean widgets, ViewModels = ChangeNotifier exposing state)
- Data Layer: Services (API clients) → Repositories (single source of truth, domain models)
- Domain Layer (optional): Use Cases for complex cross-repository logic
- Project structure: lib/data/, lib/domain/, lib/ui/features/{feature}/

## Project Conventions

| File | Path | Notes |
|------|------|-------|
| (none found) | | No AGENTS.md, CLAUDE.md, or .cursorrules found in project |

Read the convention files listed above for project-specific patterns and rules. All referenced paths have been extracted — no need to read index files to discover more.