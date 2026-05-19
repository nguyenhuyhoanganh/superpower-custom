# Stop Adding Rules When You Need Workflows

> Archived from <https://cline.bot/blog/stop-adding-rules-when-you-need-workflows>
> Author: Nick Baumann · Published: 2025-09-10

---

## What workflows actually are

Workflows are on-demand automation for multi-step processes. When you type `/pr-review.md`, Cline wraps that workflow's content in `<explicit_instructions>` tags and injects it into that specific message. The workflow executes once, completes its sequence, and disappears.

This is fundamentally different from clinerules, which append to your system prompt and affect every interaction. Workflows are procedural ("execute this process now"), while clinerules are behavioral ("always behave this way").

The technical distinction matters. Workflows only consume tokens when invoked. Clinerules consume tokens on every message because they're part of the persistent system context. Choose wrong, and you're either paying for unused context or manually repeating processes that should be automated.

## The decision framework

Build a workflow when you can describe something as "first I do X, then Y, then Z." The PR review workflow exemplifies this perfectly:

First, it gathers PR information using `gh pr view` and `gh pr diff`. Then it examines the original files with `read_file` and `search_files` to understand context. Next, it analyzes the changes for quality issues and potential bugs. Finally, it asks for confirmation and executes the approval with the appropriate `gh pr review` command.

This sequence involves multiple tools — the GitHub CLI, Cline's built-in file operations, and user interaction via `ask_followup_question`. It's a complete process that produces a specific outcome: a reviewed and approved (or rejected) PR.

Use clinerules when you want consistent behavior across all tasks. Coding standards, architectural constraints, and project-specific context belong in clinerules because they should influence every interaction. The rule about "always use TypeScript strict mode" should affect all code generation, not just when you remember to invoke it.

## Real workflow examples

The self-improving Cline workflow demonstrates another pattern. It reflects on completed tasks and proposes improvements to your active clinerules based on user feedback. This meta-workflow only makes sense as an on-demand process — you don't want Cline constantly analyzing and proposing rule changes.

Consider a deployment workflow triggered by `/deploy-staging.md`. First, it runs `npm test` to validate the code. Then it builds the application with `npm run build`. Next, it deploys to staging using `docker deploy` and runs health checks with `curl /health`. Finally, it notifies the team via a Slack MCP server and asks for user approval before proceeding to production.

This sequence demonstrates the power of workflows: multiple tools (CLI commands, file operations, MCP servers, user interaction) orchestrated into a single command. The same process that might take 20 minutes of manual work becomes a one-shot automation that maintains human oversight at critical decision points.

Content generation workflows shine for repetitive publishing tasks. A blog workflow might gather research, structure arguments, write drafts, and format for publication. Database migration workflows can run migrations, check for conflicts, update documentation, and notify teams of schema changes.

Deployment workflows orchestrate complex release processes. They might run tests, build artifacts, update version numbers, create release notes, and deploy to staging environments. These sequences involve multiple CLI tools and external services, making them perfect workflow candidates.

## How to create and invoke workflows

Access workflows through the Workflows tab in Cline's interface. You'll see both Global Workflows (stored in `~/Documents/Cline/Workflows`) and Workspace Workflows (stored in `.clinerules/workflows/`). Each workflow has a toggle switch to enable or disable it, plus edit and delete options.

To create a new workflow, click "New workflow file...". This opens a markdown file where you define your process. Alternatively, you can create files directly in the `.clinerules/workflows/` directory.

Global workflows work across all your projects, while workspace workflows are project-specific. Local workflows take precedence when both exist with the same name, allowing project-specific customizations of global processes.

## Building your first workflow

Just finished a task that you'll need to repeat? Ask Cline to create a workflow for you. Simply say "Cline, create a workflow for the process I just completed" and it will analyze the conversation, identify the steps, and generate a properly structured workflow file.

If you want more guidance, there's actually a workflow for creating workflows. It walks you through defining the purpose, objective, major steps, and detailed substeps, then generates the properly structured workflow file. Meta-workflows like this demonstrate the recursive power of the system.

The workflow structure uses `<task_objective>` to define the goal and `<detailed_sequence_of_steps>` to outline the process. Cline can reference its built-in tools like `read_file`, `search_files`, and `ask_followup_question`, CLI tools you have installed, and MCP server calls for external integrations.

Invoke any workflow by typing `/create-new-workflow.md` in the chat. The filename becomes the command. Test your workflow on a small example before using it for critical work. Workflows improve through iteration — start simple and add complexity as needed.

## When workflows excel

Workflows shine for processes that involve multiple tools and decision points. The PR review workflow combines GitHub CLI commands, file analysis, and human confirmation. A deployment workflow might orchestrate Docker builds, environment updates, and health checks.

They're particularly powerful for processes that require context gathering before action. Research workflows can query multiple sources, synthesize information, and produce structured outputs. Testing workflows can run suites, analyze results, and generate reports.

Workflows also excel at standardizing team processes. Instead of documenting procedures in wikis that get outdated, encode them as executable workflows. New team members can run the same processes experienced developers use, ensuring consistency and reducing onboarding time.

## Getting started

The prompts repository contains workflow examples you can adapt. The PR review workflow provides a template for processes involving external tools and user confirmation. The self-improving workflow shows how to create meta-processes that enhance your Cline setup.

Your most tedious recurring task is probably your best first workflow candidate. Turn that repetitive sequence into a single command, and discover what it feels like when your AI assistant truly automates your work instead of just assisting with it.

Ready to build workflows that actually work? Share your creations and discoveries with our community on Reddit and Discord. The best workflows emerge from real problems, and your unique challenges might inspire solutions others need.

_— Nick_

---

## Sources & Links

- [Cline Documentation](https://docs.cline.bot)
- [Prompts Repository](https://github.com/cline/prompts)
- [Cline GitHub](https://github.com/cline/cline)
- [Reddit Community](https://www.reddit.com/r/cline/)
- [Discord Community](https://discord.gg/cline)
