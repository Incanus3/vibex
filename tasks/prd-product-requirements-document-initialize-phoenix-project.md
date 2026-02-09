# Product Requirements Document: Initialize Phoenix Project

## Context
The user desires to bootstrap a new Elixir Phoenix application within the current working directory (`vibex`). The project should utilize standard defaults including LiveView for the frontend and PostgreSQL for the database.

## Goals
1.  Initialize a robust Phoenix application skeleton in the current directory.
2.  Ensure the generated codebase meets standard quality checks immediately after generation.

## User Stories

### Story 1: Generate Phoenix Application
**As a** developer
**I want to** generate the Phoenix application structure in the current directory
**So that** I have the foundation for the `vibex` project without creating a nested directory.

*   **Description:** Execute the Phoenix generator configured for a full HTML/LiveView app with PostgreSQL, targeting the current directory (`.`).
*   **Technical Notes:** Use `mix phx.new . --app vibex`.
*   **Acceptance Criteria:**
    *   `mix.exs` is created in the project root.
    *   `lib/vibex` and `lib/vibex_web` directories exist.
    *   `assets` directory exists.
    *   PostgreSQL is configured as the database adapter in `config/`.

### Story 2: Verify Project Health
**As a** developer
**I want to** run the standard test and format checks
**So that** I know the generated project is healthy and ready for development.

*   **Description:** Install dependencies and run the project's verification commands.
*   **Acceptance Criteria:**
    *   `mix deps.get` runs successfully.
    *   `mix test` passes with 0 failures.
    *   `mix format --check-formatted` exits successfully (code is formatted).