# Notes on what to improve with the boilerplate

1. consider whether to use the same model for all agents in the system,
or different ones per agent. The starter uses `gpt-4` for all agents, but some teams may want to use a mix of `gpt-3.5` and `gpt-4`, or even custom models.

2. consider what skills to include in the default specialist set, and whether to add or remove skills based on the repo's needs. The starter includes a default set of skills that cover common software development tasks, but some teams may want to customize this set based on their specific workflows and tools.

3. consider whether to use guided handoffs or automatic handoffs for agent orchestration, and whether to add an optional overlay for approval-gated orchestration if needed. The starter uses guided handoffs by default, but some teams may want to enable automatic handoffs for more seamless agent collaboration, while others may prefer to keep manual control over agent interactions.

4. to further enhance we'll use TOON instead of json for configuration, and we'll use a single file for all agent policies instead of separate files for lifecycle configuration and block rules. This will simplify the configuration process and make it easier to manage agent policies in one place.

5. consider how to handle agent state and memory, and whether to use a centralized state management system or allow agents to manage their own state independently. The starter does not include a built-in state management system, but some teams may want to implement one to enable more complex agent interactions and memory capabilities.

6. consider how to handle agent errors and exceptions, and whether to implement a centralized error handling system or allow agents to handle their own errors independently. The starter does not include a built-in error handling system, but some teams may want to implement one to ensure that agents can recover gracefully from errors and continue functioning effectively.