# Architecture Diagrams

This document provides visual representations of the Agentic Development Starter's structure, module relationships, and workflows.

## High-Level Architecture

```mermaid
graph TB
    subgraph "Core Foundation"
        A[.github/copilot-instructions.md]
        B[.github/instructions/core.instructions.md]
        C[.github/instructions/security.instructions.md]
        D[.github/instructions/memory.instructions.md]
    end
    
    subgraph "Governance Layer"
        E[.github/starter-modules.json]
        F[.github/roles/tool-access.json]
        G[CHANGELOG.md]
        H[DOC-CHANGELOG.md]
    end
    
    subgraph "Validation Layer"
        I[.github/scripts/check-*.sh]
        J[.github/scripts/check-*.ps1]
        K[.github/workflows/validation.yml]
    end
    
    subgraph "Workflow Assets"
        L[.github/prompts/]
        M[.github/skills/]
        N[.github/agents/]
    end
    
    subgraph "Guardrails"
        O[.github/hooks/]
        P[.github/roles/]
    end
    
    subgraph "Optional Overlays"
        Q[Hermes Runtime]
        R[Honcho Memory]
        S[Stack-Specific Instructions]
    end
    
    A --> E
    B --> E
    C --> E
    D --> E
    E --> I
    E --> J
    I --> K
    J --> K
    L --> I
    M --> I
    N --> I
    O --> I
    P --> F
    Q -.-> D
    R -.-> D
    S -.-> B
```

## Module Dependency Graph

```mermaid
graph LR
    subgraph "Core Modules"
        CB[core-baseline]
        CG[core-governance]
        CC[core-ci-validation]
        CD[core-guardrails]
        CE[core-agents]
    end
    
    subgraph "Optional Modules"
        WP[workflow-prompts]
        WS[workflow-skills]
        WE[workflow-evals]
    end
    
    subgraph "Overlay Modules"
        OJS[overlay-js-ui]
        ORU[overlay-react-ui]
        ONJ[overlay-nextjs]
        OFV[overlay-frontend-vitest-rtl]
        OFE[overlay-frontend-e2e]
        OPS[overlay-python-sql-backend]
        OFA[overlay-fastapi]
        OVT[overlay-vitest-tdd]
        OAG[overlay-approval-gated-orchestration]
        OHR[overlay-hermes-runtime]
        OHM[overlay-honcho-memory]
    end
    
    CB --> CG
    CG --> CC
    CG --> CD
    CG --> CE
    CE --> WP
    CE --> WS
    WP --> WE
    WS --> WE
    OJS --> CG
    ORU --> OJS
    ONJ --> ORU
    OFV --> OJS
    OFE --> OJS
    OPS --> CG
    OFA --> OPS
    OVT --> CE
    OAG --> CE
    OHR --> CD
    OHM --> CD
```

## Validation Workflow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Git as Git Repository
    participant CI as GitHub Actions
    participant Val as Validation Scripts
    
    Dev->>Git: Push changes
    Git->>CI: Trigger workflow
    CI->>CI: Checkout code
    CI->>Val: Run check-starter-workflow.sh
    
    par Parallel Validation
        Val->>Val: check-starter-manifest.sh
        Val->>Val: check-starter-skills.sh
        Val->>Val: check-agent-contracts.sh
        Val->>Val: check-approval-gated-orchestration.sh
        Val->>Val: check-hook-policy.sh
        Val->>Val: check-prompt-contracts.sh
        Val->>Val: check-mcp-posture.sh
        Val->>Val: check-markdown-quality.sh
        Val->>Val: check-evals.sh
    end
    
    Val-->>CI: Validation results
    CI-->>Git: Status check
    Git-->>Dev: Pass/Fail notification
```

## Agent Workflow Pattern

```mermaid
graph TB
    subgraph "Input Phase"
        A[User Request]
        B[Context Gathering]
    end
    
    subgraph "Planning Phase"
        C[Tech Planner Agent]
        D[Architecture Reviewer Agent]
        E[ADR Creation]
    end
    
    subgraph "Implementation Phase"
        F[Senior Software Engineer Agent]
        G[Code Implementation]
        H[Unit Tests]
    end
    
    subgraph "Review Phase"
        I[Code Reviewer Agent]
        J[Security Reviewer Agent]
        K[QA Agent]
    end
    
    subgraph "Documentation Phase"
        L[Documentation Maintainer Agent]
        M[Update Docs]
        N[Update Changelogs]
    end
    
    subgraph "Validation Phase"
        O[Run Validation]
        P[Fix Issues]
        Q[Final Review]
    end
    
    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> H
    H --> I
    I --> J
    J --> K
    K --> L
    L --> M
    M --> N
    N --> O
    O --> P
    P --> Q
    Q -->|Pass| Done[Complete]
    Q -->|Fail| F
```

## Memory Layer Architecture

```mermaid
graph TB
    subgraph "Layer 1: Session Memory"
        A[Current Task State]
        B[Active Context]
        C[Temporary Notes]
    end
    
    subgraph "Layer 2: Repo Truth"
        D[Instructions]
        E[Decisions]
        F[Standards]
        G[Contracts]
        H[Runbooks]
        I[Changelogs]
    end
    
    subgraph "Layer 3: Durable Memory (Optional)"
        J[User Preferences]
        K[Team Patterns]
        L[Repeated Workflows]
    end
    
    subgraph "Memory Providers"
        M[Hermes Runtime]
        N[Honcho]
    end
    
    A --> D
    B --> E
    C --> F
    D --> J
    E --> K
    F --> L
    M -.-> Layer 3
    N -.-> Layer 3
    
    style Layer 1 fill:#e1f5ff
    style Layer 2 fill:#fff4e1
    style Layer 3 fill:#e8f5e9
```

## Hook Policy Flow

```mermaid
graph LR
    A[Agent Action] --> B{Pre-Tool Hook}
    B -->|Check| C[policy-rules.tsv]
    C -->|Match Found| D[Block Action]
    C -->|No Match| E[Allow Action]
    D --> F[Log to Audit]
    E --> G[Execute Action]
    G --> F
    
    subgraph "Policy Rules"
        H[Destructive Commands]
        I[Secret Writes]
        J[Unsafe Paths]
        K[Network Requests]
        L[Policy Edits]
    end
    
    C -.-> H
    C -.-> I
    C -.-> J
    C -.-> K
    C -.-> L
```

## Module Adoption Progression

```mermaid
graph LR
    subgraph "Minimal Install"
        A[Core Instructions]
        B[Security Defaults]
        C[Memory Policy]
        D[Module Manifest]
        E[Basic Validation]
        F[Changelogs]
    end
    
    subgraph "Team Mode"
        G[Agents]
        H[Skills]
        I[Prompt Files]
        J[Hook Policy]
        K[CI Validation]
        L[Runbooks]
    end
    
    subgraph "Advanced Mode"
        M[Approval-Gated Handoffs]
        N[MCP Templates]
        O[Eval Harness]
        P[Tool-Surface Matrix]
        Q[Memory Policy Examples]
    end
    
    subgraph "Enterprise Mode"
        R[Org Instruction Overlays]
        S[Private Shared Skills]
        T[Centralized Policy Review]
        U[Security & Audit Requirements]
        V[Periodic Evals]
    end
    
    A --> G
    B --> H
    C --> I
    D --> J
    E --> K
    F --> L
    G --> M
    H --> N
    I --> O
    J --> P
    K --> Q
    L --> R
    M --> S
    N --> T
    O --> U
    P --> V
```

## File Organization Structure

```mermaid
graph TB
    Root[Repository Root]
    
    Root --> GH[.github/]
    Root --> Docs[docs/]
    Root --> Evals[evals/]
    Root --> VSCode[.vscode/]
    
    GH --> Copilot[copilot-instructions.md]
    GH --> Instructions[instructions/]
    GH --> Prompts[prompts/]
    GH --> Agents[agents/]
    GH --> Skills[skills/]
    GH --> Hooks[hooks/]
    GH --> Scripts[scripts/]
    GH --> Workflows[workflows/]
    GH --> Examples[examples/]
    GH --> Manifest[starter-modules.json]
    
    Instructions --> Core[core.instructions.md]
    Instructions --> Security[security.instructions.md]
    Instructions --> Memory[memory.instructions.md]
    Instructions --> Stack[Stack-specific overlays]
    
    Hooks --> Policy[policy-rules.tsv]
    Hooks --> HookScripts[scripts/]
    
    Docs --> ADR[adr/]
    Docs --> Runbooks[runbooks/]
    
    Evals --> Tasks[tasks/]
    Evals --> Expected[expected/]
    Evals --> Runner[run-evals.sh]
    
    VSCode --> MCP[mcp.json]
    VSCode --> Tasks[tasks.json]
```

## CI/CD Pipeline

```mermaid
graph LR
    A[Push to Repository] --> B{Trigger Workflow}
    B --> C[validation.yml]
    
    C --> D[validate job]
    C --> E[markdown job]
    C --> F[hooks job]
    C --> G[skills job]
    
    D --> H[check-starter-workflow.sh]
    E --> I[check-markdown-quality.sh]
    F --> J[check-hook-policy.sh]
    G --> K[check-starter-skills.sh]
    
    H --> L{All Checks Pass?}
    I --> L
    J --> L
    K --> L
    
    L -->|Yes| M[Success]
    L -->|No| N[Failure]
    
    M --> O[Allow Merge]
    N --> P[Block Merge]
```

## Security Layers

```mermaid
graph TB
    subgraph "Layer 1: Input Validation"
        A[Boundary Checks]
        B[Input Sanitization]
        C[Authorization]
    end
    
    subgraph "Layer 2: Hook Guardrails"
        D[Pre-Tool Policy]
        E[Destructive Command Blocking]
        F[Secret Detection]
        G[Path Validation]
    end
    
    subgraph "Layer 3: MCP Safety"
        H[Disabled by Default]
        I[Review Required]
        J[Permission Scoping]
    end
    
    subgraph "Layer 4: Memory Safety"
        K[No Secrets in Memory]
        L[Scoped Memory]
        M[Reviewable Storage]
    end
    
    subgraph "Layer 5: Supply Chain"
        N[Version Pinning]
        O[Lockfiles]
        P[Dependency Audits]
    end
    
    A --> D
    B --> E
    C --> F
    D --> H
    E --> I
    F --> J
    H --> K
    I --> L
    J --> M
    K --> N
    L --> O
    M --> P
```

## Usage Examples

### Viewing Diagrams

These diagrams use Mermaid syntax. To view them:

1. **In VS Code**: Install the "Markdown Preview Mermaid Support" extension
2. **On GitHub**: Mermaid diagrams render automatically in Markdown files
3. **Online**: Use [Mermaid Live Editor](https://mermaid.live/)

### Customizing Diagrams

You can customize these diagrams by:
- Editing the Mermaid syntax directly
- Using the Mermaid Live Editor to experiment
- Adding new diagrams for your specific use cases

### Adding New Diagrams

When adding new diagrams:
1. Follow the existing Mermaid syntax
2. Keep diagrams focused and readable
3. Update this document's table of contents
4. Test rendering in your target platform
