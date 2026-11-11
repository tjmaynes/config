# General Guidelines

- Never use the em dash "—". Use a plain dash "-" instead.
- Never manually modify CHANGELOG.md files or files marked as auto-generated.
- Use Conventional Commits for commit messages.
- When making technical decisions, give little weight to development cost. Prefer quality, simplicity, robustness, scalability, and long-term maintainability.
- When fixing bugs, start by reproducing the bug in an end-to-end setting that is as close as possible to how an end user experiences it. This helps identify the real problem and ensures the fix addresses it.
- When testing a product end to end, be picky about the UI and strive for pixel perfection. If something clearly looks off, even if it is not directly related to the task, try to fix it as well.
- Apply the same high standard to engineering excellence. If you encounter lint issues, test failures, or flaky tests, try to fix them even if they were not caused by the current task.
- Explain consequential decisions: When a decision has meaningful tradeoffs, explain the options and recommend an approach.
- Keep ownership clear: Prefer a clear source of truth, and identify redundant configuration when changing how something is managed.
- Make follow-through actionable: When a task requires a manual step, explain what to do and what effect it will have.
