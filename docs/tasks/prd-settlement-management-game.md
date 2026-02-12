# PRD: Vibex Settlement Management Game

## Overview

Vibex is an idle/incremental settlement management game built with Phoenix LiveView. Players build a settlement, recruit armies, and send them on missions while progressing through stages that unlock new features. The game uses a GenServer-based architecture for real-time resource calculation and state management.

## Goals

- Create a playable idle settlement game with resource accumulation
- Implement building construction with production bonuses
- Build a unit recruitment and mission system
- Deliver stage-based progression that unlocks new content
- Support future expansion to multiple settlements and heroes

## Quality Gates

These commands must pass for every user story:
- `mix test` - All tests must pass
- `mix credo --strict` - Strict linting

For UI stories, also include:
- Smoke test in browser: verify correct elements/values are present (not detailed specs)

## User Stories

### US-001: Create Settlement Context and Schema
**Description:** As a developer, I want a Settlement schema with resources and storage fields so that player state can be persisted.

**Acceptance Criteria:**
- [ ] Create `Vibex.Settlements.Settlement` schema with `user_id`, `resources` (map), `storage_capacity` (map), `last_calculated_at`, `progression_stage`
- [ ] Create `Vibex.Settlements` context module
- [ ] Add migration for `settlements` table
- [ ] `mix test && mix credo --strict` pass

### US-002: Create Building Schema and Context
**Description:** As a developer, I want a Building schema so that settlement structures can be stored.

**Acceptance Criteria:**
- [ ] Create `Vibex.Buildings.Building` schema with `settlement_id`, `type`, `level`, `position`
- [ ] Create `Vibex.Buildings` context module
- [ ] Add migration for `buildings` table
- [ ] Building type is an Ecto enum with all building types defined
- [ ] `mix test && mix credo --strict` pass

### US-003: Create Unit Schema and Context
**Description:** As a developer, I want a Unit schema so that player armies can be stored.

**Acceptance Criteria:**
- [ ] Create `Vibex.Units.Unit` schema with `settlement_id`, `type`, `count`
- [ ] Create `Vibex.Units` context module
- [ ] Add migration for `units` table
- [ ] Unit type is an Ecto enum with militia, swordsman, archer, mage
- [ ] `mix test && mix credo --strict` pass

### US-004: Create Mission and MissionAssignment Schemas
**Description:** As a developer, I want Mission schemas so that missions and player progress can be stored.

**Acceptance Criteria:**
- [ ] Create `Vibex.Missions.Mission` schema with `name`, `tier`, `min_units`, `duration_seconds`, `rewards`, `difficulty`, `type`
- [ ] Create `Vibex.Missions.MissionAssignment` schema with `settlement_id`, `mission_id`, `units`, `started_at`, `completes_at`, `status`
- [ ] Create `Vibex.Missions` context module
- [ ] Add migrations for `missions` and `mission_assignments` tables
- [ ] `mix test && mix credo --strict` pass

### US-005: Implement SettlementServer GenServer
**Description:** As a developer, I want a GenServer to manage settlement state so that resources can be calculated in real-time.

**Acceptance Criteria:**
- [ ] Create `Vibex.SettlementServer` GenServer
- [ ] Implement `get_or_create/1` that spawns or returns existing server
- [ ] Implement `state/1` to get current calculated state
- [ ] Server uses Registry for process lookup by user_id
- [ ] Server loads state from database on start
- [ ] `mix test && mix credo --strict` pass

### US-006: Implement Resource Calculation
**Description:** As a developer, I want resources to accumulate over time based on production buildings.

**Acceptance Criteria:**
- [ ] Implement `production_rate/2` function calculating rate from buildings
- [ ] Implement `current_resources/1` calculating accumulated resources from `last_calculated_at`
- [ ] Resources cap at `storage_capacity`
- [ ] `last_calculated_at` updates on resource fetch
- [ ] Production formula: `base × 1.5^(level - 1)`
- [ ] `mix test && mix credo --strict` pass

### US-007: Implement Building Construction
**Description:** As a player, I want to construct buildings so that my settlement grows.

**Acceptance Criteria:**
- [ ] Add `build/3` to SettlementServer (user_id, building_type, position)
- [ ] Construction deducts resources from settlement
- [ ] Construction fails if insufficient resources
- [ ] Construction fails if position already occupied
- [ ] Building persists to database
- [ ] `mix test && mix credo --strict` pass

### US-008: Implement Building Upgrades
**Description:** As a player, I want to upgrade buildings so that production increases.

**Acceptance Criteria:**
- [ ] Add `upgrade/2` to SettlementServer (user_id, building_id)
- [ ] Upgrade cost formula: `base_cost × 1.8^(level - 1)`
- [ ] Upgrade deducts resources
- [ ] Upgrade fails if insufficient resources or at max level (10)
- [ ] `mix test && mix credo --strict` pass

### US-009: Implement Unit Recruitment
**Description:** As a player, I want to recruit units so that I can build an army.

**Acceptance Criteria:**
- [ ] Add `recruit/3` to SettlementServer (user_id, unit_type, count)
- [ ] Recruitment deducts resources per unit cost
- [ ] Recruitment fails if insufficient resources
- [ ] Recruitment fails if unit type not unlocked
- [ ] Units stack by type (increment count, not new records)
- [ ] `mix test && mix credo --strict` pass

### US-010: Implement Progression System
**Description:** As a developer, I want a progression system so that features unlock as the player advances.

**Acceptance Criteria:**
- [ ] Create `Vibex.Progression` module
- [ ] Implement stage unlock conditions for stages 2-5
- [ ] `check_progression/1` returns `{:advance, new_stage}` or `:no_change`
- [ ] Stage 2: total production >= 100
- [ ] Stage 3: has barracks AND militia count >= 10
- [ ] Stage 4: has iron forge AND iron production >= 20
- [ ] Stage 5: completed missions >= 5
- [ ] `mix test && mix credo --strict` pass

### US-011: Implement Mission System
**Description:** As a player, I want to send units on missions so that I earn rewards.

**Acceptance Criteria:**
- [ ] Add `start_mission/3` to SettlementServer (user_id, mission_id, units)
- [ ] Mission assignment creates MissionAssignment record
- [ ] Units become unavailable during mission
- [ ] `resolve_mission/2` calculates success/failure based on attack power
- [ ] On success: full rewards granted
- [ ] On failure: partial rewards, 10-30% unit losses
- [ ] `mix test && mix credo --strict` pass

### US-012: Seed Story Missions
**Description:** As a developer, I want predetermined missions so players have early-game content.

**Acceptance Criteria:**
- [ ] Create priv/repo/seeds.exs with 10 story missions
- [ ] Missions span tiers 1-5
- [ ] Each mission has name, tier, duration, rewards, difficulty
- [ ] `mix run priv/repo/seeds.exs` populates missions table
- [ ] `mix test && mix credo --strict` pass

### US-013: Create SettlementLive Overview Tab
**Description:** As a player, I want to see my settlement overview so that I understand my current state.

**Acceptance Criteria:**
- [ ] Create `VibexWeb.SettlementLive` LiveView
- [ ] Display resource bars with current amount and capacity
- [ ] Display production rates per resource
- [ ] Display current progression stage
- [ ] Resources update every second via `:tick` message
- [ ] Smoke test: verify resource bars, production rates, stage are visible
- [ ] `mix test && mix credo --strict` pass

### US-014: Create Buildings Tab
**Description:** As a player, I want to see and manage buildings so that I can grow my settlement.

**Acceptance Criteria:**
- [ ] Display 6x6 building grid
- [ ] Click empty slot opens building selection modal
- [ ] Building selection shows cost and unlocks available buildings
- [ ] Click existing building shows upgrade option with cost
- [ ] Building actions update UI immediately
- [ ] Smoke test: verify grid renders, building selection works
- [ ] `mix test && mix credo --strict` pass

### US-015: Create Units Tab
**Description:** As a player, I want to see and recruit units so that I can build my army.

**Acceptance Criteria:**
- [ ] Display current unit counts by type
- [ ] Display recruitment panel with available unit types
- [ ] Show unit cost and stats on hover/click
- [ ] Recruit buttons disabled for locked unit types
- [ ] Recruitment updates unit counts immediately
- [ ] Smoke test: verify unit display, recruitment panel
- [ ] `mix test && mix credo --strict` pass

### US-016: Create Missions Tab
**Description:** As a player, I want to see and start missions so that I can earn rewards.

**Acceptance Criteria:**
- [ ] Display available missions list with name, tier, duration, rewards
- [ ] Display active missions with countdown timers
- [ ] Mission selection shows unit assignment interface
- [ ] Unit assignment validates minimum units required
- [ ] Completed missions show resolution (success/failure, rewards)
- [ ] Smoke test: verify mission list, timer countdown, assignment interface
- [ ] `mix test && mix credo --strict` pass

### US-017: Add Tab Navigation
**Description:** As a player, I want to navigate between tabs so that I can access all game features.

**Acceptance Criteria:**
- [ ] Add tab bar with Overview, Buildings, Units, Missions
- [ ] Active tab is visually highlighted
- [ ] Tab state persists in LiveView assigns
- [ ] Navigation works without page reload
- [ ] Smoke test: verify all tabs are clickable and switch content
- [ ] `mix test && mix credo --strict` pass

### US-018: Add Stage Advancement Notifications
**Description:** As a player, I want to be notified when I advance stages so that I know what I unlocked.

**Acceptance Criteria:**
- [ ] Display notification modal when stage advances
- [ ] Modal shows new stage number and unlocked features
- [ ] Modal dismissable by user action
- [ ] Smoke test: verify notification appears on stage advancement
- [ ] `mix test && mix credo --strict` pass

### US-019: Route SettlementLive with Authentication
**Description:** As a player, I want the game to be at the root path so that I can start playing immediately after login.

**Acceptance Criteria:**
- [ ] Add SettlementLive to router at `/`
- [ ] Place in `live_session :require_authenticated_user`
- [ ] Unauthenticated users redirected to login
- [ ] Authenticated users see their settlement
- [ ] Smoke test: verify redirect for unauthenticated, game loads for authenticated
- [ ] `mix test && mix credo --strict` pass

### US-020: Initialize New Player Settlement
**Description:** As a new player, I want a starter settlement so that I can begin playing.

**Acceptance Criteria:**
- [ ] New users get settlement created automatically
- [ ] Settlement starts with 500 of each basic resource (gold, wood, stone, food)
- [ ] Settlement starts at progression stage 1
- [ ] Settlement starts with base storage capacity (500 each)
- [ ] `mix test && mix credo --strict` pass

## Functional Requirements

- FR-1: Resources must accumulate in real-time based on production buildings
- FR-2: Resource accumulation must be calculated from last_calculated_at timestamp
- FR-3: Resources must not exceed storage capacity
- FR-4: Building costs must follow formula: `base_cost × 1.8^(level - 1)`
- FR-5: Production rates must follow formula: `base × 1.5^(level - 1)`
- FR-6: Unit recruitment must deduct correct resource costs
- FR-7: Mission success must be calculated from attack power vs difficulty
- FR-8: Stage progression must be checked after building completion
- FR-9: Locked features (buildings, units) must not be accessible
- FR-10: SettlementServer must persist state after each action

## Non-Goals

- Heroes system (post-MVP)
- Procedurally generated missions (post-MVP)
- Multiple settlements (post-MVP)
- Building construction timers
- Unit upgrades and equipment
- PvP or combat missions
- Trading/markets
- Sound or music
- Mobile-specific UI

## Technical Considerations

- GenServer processes are keyed by user_id via Registry
- Settlement state loads from database on first access
- Async persistence after state changes
- LiveView uses `:tick` message every 1 second for updates
- Storage capacity determined by storage building levels
- Progression stages unlock building types, unit types, resource types

## Success Metrics

- Player can construct buildings and see resources accumulate
- Player can recruit units and send them on missions
- Progression stages unlock correctly
- Game is playable end-to-end from new user to stage 5
- All tests pass and code passes credo strict

## Open Questions

- Should we add a tutorial/onboarding flow in a future iteration?
- What should the visual theme of the game be?
- Should we add sound effects post-MVP?
