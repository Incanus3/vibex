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

---

## Implementation Phases

```
PHASE 1: UI MOCKUP (all visual, no persistence)
    └── Checkpoint 1: Can see all UI with mock data, click around tabs

PHASE 2: CORE BACKEND (persistence + live resources)
    └── Checkpoint 2: Overview tab shows real resources, live tick

PHASE 3: INTERACTIVITY (building/unit/mission mechanics)
    └── Checkpoint 3: All tabs functional, can build, recruit, do missions

PHASE 4: POLISH (new player experience + notifications)
    └── Done: Fully playable end-to-end
```

---

## Phase 1: UI Mockup

Goal: Create all visual components with hardcoded mock data. No database, no GenServer, just static UI that can be navigated.

### US-013: Create SettlementLive Overview Tab (Mock)
**Order: 1**
**Description:** As a player, I want to see my settlement overview so that I understand my current state.

**Acceptance Criteria:**
- [ ] Create `VibexWeb.SettlementLive` LiveView
- [ ] Display resource bars with mock amounts and capacities
- [ ] Display mock production rates per resource
- [ ] Display mock progression stage
- [ ] Use hardcoded assigns (no backend integration)
- [ ] Smoke test: verify resource bars, production rates, stage are visible
- [ ] `mix test && mix credo --strict` pass

**Mock Data:**
```elixir
%{
  resources: %{gold: 500, wood: 300, stone: 200, food: 400, iron: 0, crystal: 0},
  storage: %{gold: 1000, wood: 1000, stone: 1000, food: 1000, iron: 500, crystal: 500},
  production: %{gold: 5, wood: 10, stone: 8, food: 12, iron: 0, crystal: 0},
  stage: 1
}
```

### US-014: Create Buildings Tab (Mock)
**Order: 2**
**Description:** As a player, I want to see a building grid so that I can visualize my settlement layout.

**Acceptance Criteria:**
- [ ] Display 6x6 building grid in SettlementLive
- [ ] Empty slots show placeholder
- [ ] Occupied slots show building type and level (from mock data)
- [ ] Click handlers log to console (no real actions yet)
- [ ] Smoke test: verify grid renders with mock buildings
- [ ] `mix test && mix credo --strict` pass

**Mock Data:**
```elixir
%{
  buildings: [
    %{id: 1, type: :farm, level: 2, position: 1},
    %{id: 2, type: :lumber_mill, level: 1, position: 7},
    %{id: 3, type: :quarry, level: 1, position: 13}
  ],
  grid_size: 36
}
```

### US-015: Create Units Tab (Mock)
**Order: 3**
**Description:** As a player, I want to see my army so that I know what units I have.

**Acceptance Criteria:**
- [ ] Display current mock unit counts by type
- [ ] Display mock recruitment panel with unit types
- [ ] Show unit cost and stats (hardcoded)
- [ ] Recruit buttons visible but non-functional (log to console)
- [ ] Smoke test: verify unit display, recruitment panel
- [ ] `mix test && mix credo --strict` pass

**Mock Data:**
```elixir
%{
  units: %{militia: 10, swordsman: 0, archer: 0, mage: 0},
  unit_stats: %{
    militia: %{attack: 5, defense: 3, cost: %{gold: 50, food: 20}},
    swordsman: %{attack: 15, defense: 12, cost: %{gold: 80, iron: 30}},
    archer: %{attack: 12, defense: 5, cost: %{gold: 60, iron: 20, wood: 15}},
    mage: %{attack: 25, defense: 8, cost: %{gold: 150, crystal: 40}}
  }
}
```

### US-016: Create Missions Tab (Mock)
**Order: 4**
**Description:** As a player, I want to see available missions so that I can plan my activities.

**Acceptance Criteria:**
- [ ] Display mock available missions list with name, tier, duration, rewards
- [ ] Display mock active missions with countdown timers (static)
- [ ] Mission selection shows mock unit assignment interface
- [ ] Start mission button logs to console (no real actions)
- [ ] Smoke test: verify mission list, assignment interface
- [ ] `mix test && mix credo --strict` pass

**Mock Data:**
```elixir
%{
  available_missions: [
    %{id: 1, name: "Patrol the Woods", tier: 1, duration_seconds: 300, rewards: %{gold: 200}, min_units: 5, difficulty: 1.0},
    %{id: 2, name: "Clear the Mine", tier: 1, duration_seconds: 420, rewards: %{gold: 150, iron: 50}, min_units: 8, difficulty: 1.2}
  ],
  active_missions: [
    %{id: 3, name: "Scout the Hills", tier: 1, completes_at: ~U[2026-02-13 12:00:00Z], units: %{militia: 5}}
  ]
}
```

### US-017: Add Tab Navigation
**Order: 5**
**Description:** As a player, I want to navigate between tabs so that I can access all game features.

**Acceptance Criteria:**
- [ ] Add tab bar with Overview, Buildings, Units, Missions
- [ ] Active tab is visually highlighted
- [ ] Tab state persists in LiveView assigns
- [ ] Navigation works without page reload
- [ ] Smoke test: verify all tabs are clickable and switch content
- [ ] `mix test && mix credo --strict` pass

**Checkpoint 1 Reached:** All UI visible with mock data, can navigate between tabs.

---

## Phase 2: Core Backend

Goal: Add persistence and real-time resource calculation. Overview tab becomes "live" with actual data.

### US-001: Create Settlement Context and Schema
**Order: 6**
**Description:** As a developer, I want a Settlement schema with resources and storage fields so that player state can be persisted.

**Acceptance Criteria:**
- [ ] Create `Vibex.Settlements.Settlement` schema with `user_id`, `resources` (map), `storage_capacity` (map), `last_calculated_at`, `progression_stage`
- [ ] Create `Vibex.Settlements` context module
- [ ] Add migration for `settlements` table
- [ ] `mix test && mix credo --strict` pass

### US-005: Implement SettlementServer GenServer
**Order: 7**
**Description:** As a developer, I want a GenServer to manage settlement state so that resources can be calculated in real-time.

**Acceptance Criteria:**
- [ ] Create `Vibex.SettlementServer` GenServer
- [ ] Implement `get_or_create/1` that spawns or returns existing server
- [ ] Implement `state/1` to get current calculated state
- [ ] Server uses Registry for process lookup by user_id
- [ ] Server loads state from database on start
- [ ] Add SettlementRegistry to application supervision tree
- [ ] `mix test && mix credo --strict` pass

### US-006: Implement Resource Calculation
**Order: 8**
**Description:** As a developer, I want resources to accumulate over time based on production buildings.

**Acceptance Criteria:**
- [ ] Implement `production_rate/2` function calculating rate from buildings
- [ ] Implement `current_resources/1` calculating accumulated resources from `last_calculated_at`
- [ ] Resources cap at `storage_capacity`
- [ ] `last_calculated_at` updates on resource fetch
- [ ] Production formula: `base × 1.5^(level - 1)`
- [ ] `mix test && mix credo --strict` pass

### US-019: Route SettlementLive with Authentication
**Order: 9**
**Description:** As a player, I want the game to be at the root path so that I can start playing immediately after login.

**Acceptance Criteria:**
- [ ] Add SettlementLive to router at `/`
- [ ] Place in `live_session :require_authenticated_user`
- [ ] Unauthenticated users redirected to login
- [ ] Authenticated users see their settlement
- [ ] Wire Overview tab to real SettlementServer state
- [ ] Resources update every second via `:tick` message
- [ ] Smoke test: verify redirect for unauthenticated, game loads for authenticated
- [ ] `mix test && mix credo --strict` pass

**Checkpoint 2 Reached:** Overview tab shows real resources with live tick updates.

---

## Phase 3: Interactivity

Goal: Add building construction, unit recruitment, and mission systems. All tabs become functional.

### US-002: Create Building Schema and Context
**Order: 10**
**Description:** As a developer, I want a Building schema so that settlement structures can be stored.

**Acceptance Criteria:**
- [ ] Create `Vibex.Buildings.Building` schema with `settlement_id`, `type`, `level`, `position`
- [ ] Create `Vibex.Buildings` context module
- [ ] Add migration for `buildings` table
- [ ] Building type is an Ecto enum with all building types defined
- [ ] `mix test && mix credo --strict` pass

### US-003: Create Unit Schema and Context
**Order: 11**
**Description:** As a developer, I want a Unit schema so that player armies can be stored.

**Acceptance Criteria:**
- [ ] Create `Vibex.Units.Unit` schema with `settlement_id`, `type`, `count`
- [ ] Create `Vibex.Units` context module
- [ ] Add migration for `units` table
- [ ] Unit type is an Ecto enum with militia, swordsman, archer, mage
- [ ] `mix test && mix credo --strict` pass

### US-004: Create Mission and MissionAssignment Schemas
**Order: 12**
**Description:** As a developer, I want Mission schemas so that missions and player progress can be stored.

**Acceptance Criteria:**
- [ ] Create `Vibex.Missions.Mission` schema with `name`, `tier`, `min_units`, `duration_seconds`, `rewards`, `difficulty`, `type`
- [ ] Create `Vibex.Missions.MissionAssignment` schema with `settlement_id`, `mission_id`, `units`, `started_at`, `completes_at`, `status`
- [ ] Create `Vibex.Missions` context module
- [ ] Add migrations for `missions` and `mission_assignments` tables
- [ ] `mix test && mix credo --strict` pass

### US-007: Implement Building Construction
**Order: 13**
**Description:** As a player, I want to construct buildings so that my settlement grows.

**Acceptance Criteria:**
- [ ] Add `build/3` to SettlementServer (user_id, building_type, position)
- [ ] Construction deducts resources from settlement
- [ ] Construction fails if insufficient resources
- [ ] Construction fails if position already occupied
- [ ] Building persists to database
- [ ] Wire Buildings tab to real construction actions
- [ ] `mix test && mix credo --strict` pass

### US-008: Implement Building Upgrades
**Order: 14**
**Description:** As a player, I want to upgrade buildings so that production increases.

**Acceptance Criteria:**
- [ ] Add `upgrade/2` to SettlementServer (user_id, building_id)
- [ ] Upgrade cost formula: `base_cost × 1.8^(level - 1)`
- [ ] Upgrade deducts resources
- [ ] Upgrade fails if insufficient resources or at max level (10)
- [ ] Wire Buildings tab upgrade modal to real actions
- [ ] `mix test && mix credo --strict` pass

### US-009: Implement Unit Recruitment
**Order: 15**
**Description:** As a player, I want to recruit units so that I can build an army.

**Acceptance Criteria:**
- [ ] Add `recruit/3` to SettlementServer (user_id, unit_type, count)
- [ ] Recruitment deducts resources per unit cost
- [ ] Recruitment fails if insufficient resources
- [ ] Recruitment fails if unit type not unlocked
- [ ] Units stack by type (increment count, not new records)
- [ ] Wire Units tab to real recruitment actions
- [ ] `mix test && mix credo --strict` pass

### US-012: Seed Story Missions
**Order: 16**
**Description:** As a developer, I want predetermined missions so players have early-game content.

**Acceptance Criteria:**
- [ ] Create priv/repo/seeds.exs with 10 story missions
- [ ] Missions span tiers 1-5
- [ ] Each mission has name, tier, duration, rewards, difficulty
- [ ] `mix run priv/repo/seeds.exs` populates missions table
- [ ] `mix test && mix credo --strict` pass

### US-011: Implement Mission System
**Order: 17**
**Description:** As a player, I want to send units on missions so that I earn rewards.

**Acceptance Criteria:**
- [ ] Add `start_mission/3` to SettlementServer (user_id, mission_id, units)
- [ ] Mission assignment creates MissionAssignment record
- [ ] Units become unavailable during mission
- [ ] `resolve_mission/2` calculates success/failure based on attack power
- [ ] On success: full rewards granted
- [ ] On failure: partial rewards, 10-30% unit losses
- [ ] Wire Missions tab to real mission actions
- [ ] `mix test && mix credo --strict` pass

### US-010: Implement Progression System
**Order: 18**
**Description:** As a developer, I want a progression system so that features unlock as the player advances.

**Acceptance Criteria:**
- [ ] Create `Vibex.Progression` module
- [ ] Implement stage unlock conditions for stages 2-5
- [ ] `check_progression/1` returns `{:advance, new_stage}` or `:no_change`
- [ ] Stage 2: total production >= 100
- [ ] Stage 3: has barracks AND militia count >= 10
- [ ] Stage 4: has iron forge AND iron production >= 20
- [ ] Stage 5: completed missions >= 5
- [ ] Lock/unlock UI elements based on stage
- [ ] `mix test && mix credo --strict` pass

**Checkpoint 3 Reached:** All tabs functional, can build, recruit, and complete missions.

---

## Phase 4: Polish

Goal: Complete new player experience and add stage advancement notifications.

### US-020: Initialize New Player Settlement
**Order: 19**
**Description:** As a new player, I want a starter settlement so that I can begin playing.

**Acceptance Criteria:**
- [ ] New users get settlement created automatically on first login
- [ ] Settlement starts with 500 of each basic resource (gold, wood, stone, food)
- [ ] Settlement starts at progression stage 1
- [ ] Settlement starts with base storage capacity (500 each)
- [ ] `mix test && mix credo --strict` pass

### US-018: Add Stage Advancement Notifications
**Order: 20**
**Description:** As a player, I want to be notified when I advance stages so that I know what I unlocked.

**Acceptance Criteria:**
- [ ] Display notification modal when stage advances
- [ ] Modal shows new stage number and unlocked features
- [ ] Modal dismissable by user action
- [ ] Smoke test: verify notification appears on stage advancement
- [ ] `mix test && mix credo --strict` pass

**Done:** Fully playable end-to-end from new user to stage 5.

---

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

---

## Implementation Order Summary

| Order | Phase | US# | Description | Checkpoint |
|-------|-------|-----|-------------|------------|
| 1 | 1 | US-013 | Overview Tab (mock) | |
| 2 | 1 | US-014 | Buildings Tab (mock) | |
| 3 | 1 | US-015 | Units Tab (mock) | |
| 4 | 1 | US-016 | Missions Tab (mock) | |
| 5 | 1 | US-017 | Tab Navigation | **Checkpoint 1** |
| 6 | 2 | US-001 | Settlement Schema | |
| 7 | 2 | US-005 | SettlementServer GenServer | |
| 8 | 2 | US-006 | Resource Calculation | |
| 9 | 2 | US-019 | Auth Routing | **Checkpoint 2** |
| 10 | 3 | US-002 | Building Schema | |
| 11 | 3 | US-003 | Unit Schema | |
| 12 | 3 | US-004 | Mission Schemas | |
| 13 | 3 | US-007 | Building Construction | |
| 14 | 3 | US-008 | Building Upgrades | |
| 15 | 3 | US-009 | Unit Recruitment | |
| 16 | 3 | US-012 | Seed Missions | |
| 17 | 3 | US-011 | Mission System | |
| 18 | 3 | US-010 | Progression System | **Checkpoint 3** |
| 19 | 4 | US-020 | New Player Init | |
| 20 | 4 | US-018 | Stage Notifications | **Done** |
