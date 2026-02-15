# Idea to design brainstorming process

**Session ID:** ses_3a8f57adbffe7K8A4UmH4OY8LV
**Created:** 2/13/2026, 1:47:13 PM
**Updated:** 2/13/2026, 2:25:36 PM

---

## User

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

## The Process

**Understanding the idea:**
- Check out the current project state first (files, docs, recent commits)
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**
- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**
- Once you believe you understand what you're building, present the design
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

## After the Design

**Documentation:**
- Write the validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Use elements-of-style:writing-clearly-and-concisely skill if available
- Commit the design document to git

**Implementation (if continuing):**
- Ask: "Ready to set up for implementation?"
- Use superpowers:using-git-worktrees to create isolated workspace
- Use superpowers:writing-plans to create detailed implementation plan

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense

---

## Assistant

I'll start by understanding the current project context.

**Tool: bash**

**Tool: glob**

**Tool: glob**

---

## Assistant

**Tool: read**

**Tool: read**

---

## Assistant

This is a fresh Phoenix project called "vibex" with LiveView, PostgreSQL, and user authentication set up. No custom features have been added yet.

What would you like to build?

---

## User

I'd like this to be a simple settlement management game. the user should be able to
- build buildings (production and special)
- recruit armies
- send heroes and armies for missions
I'd also like there to be some kind of progression to this game - new paths and features should open in the game as the user progresses.

---

## Assistant

**Tool: question**

---

## Assistant

**Tool: question**

---

## Assistant

**Tool: question**

---

## Assistant

**Tool: question**

---

## Assistant

**Tool: question**

---

## Assistant

**Tool: question**

---

## Assistant

I have a good picture. Before presenting the design, let me propose architecture approaches:

---

**Approach 1: Event-sourced with GenServer (Recommended)**

Each settlement runs as a GenServer process, calculating resource production on-demand from timestamps. Progression is tracked as events. Clean separation, easy to extend to multiple settlements later, natural fit for Elixir.

**Approach 2: Polling with database state**

Resources update on a timer (every minute). Simpler to understand, but creates database load and makes "catch-up" calculations when player returns after absence.

**Approach 3: Pure LiveView with ETS**

State lives in ETS, LiveView processes read/write directly. Fast but loses durability - game state lost on server restart. Good for prototypes, bad for production.

---

I recommend **Approach 1** because:
- Idle games need accurate "time since last visit" calculations
- GenServer per settlement is natural for eventual multi-settlement
- Event sourcing gives an audit trail (useful for progression unlocks)
- Fits Phoenix/BEAM philosophy well

Does this direction work for you?

---

## User

yeah, 1 sounds great

---

## Assistant

## Section 1: Core Data Model

**Settlement**
The central entity. Each user has one settlement (extendable later). Stores:
- `resources` map: `%{gold: 1500, wood: 800, stone: 600, food: 400, iron: 200, crystal: 50}`
- `last_calculated_at`: timestamp for resource catch-up
- `progression_stage`: integer (1-10) tracking unlocked features

**Buildings**
Two categories:
- **Production buildings**: Farm, Lumber Mill, Quarry, Mine, Iron Forge, Crystal Refinery. Each produces one resource type. Level 1-10, cost scales exponentially.
- **Special buildings**: Barracks (unlocks units), Town Hall (unlocks progression), Tavern (unlocks heroes), Watchtower (unlocks missions)

**Resources**
Six types: Gold, Wood, Stone, Food, Iron, Crystal. First four available from stage 1. Iron unlocks at stage 3, Crystal at stage 5.

**Progression**
Stages unlock via conditions (e.g., "reach 500 gold production" → stage 2). Each stage unlocks:
- New building types
- New unit types  
- New mission tiers
- Resource types (iron, crystal)

The `progression_stage` field drives conditional UI rendering and feature availability checks throughout the codebase.

---

Does this foundation look right?

---

## User

sounds reasonable

---

## Assistant

## Section 2: GenServer Architecture & Resource Calculation

**SettlementServer (GenServer)**
Each settlement spawns a GenServer process on first access (via Registry lookup). The server:
- Holds current state in memory for fast reads
- Calculates resources on-demand using `last_calculated_at`
- Handles building construction, upgrades, and purchases
- Persists state to database after each meaningful action

**Resource Calculation Formula**
```
current_amount = stored_amount + (production_rate × elapsed_seconds)
```

Production rate is derived from all production buildings:
```elixir
def production_rate(settlement, :wood) do
  settlement.buildings
  |> Enum.filter(&(&1.type == :lumber_mill))
  |> Enum.map(&building_production/1)
  |> Enum.sum()
end

def building_production(%{type: type, level: level}) do
  base = @base_production[type]  # e.g., 10 wood/sec at level 1
  base * :math.pow(1.5, level - 1)  # 50% increase per level
end
```

**Offline Progress**
When a player returns after hours away, resources are calculated from `last_calculated_at`. No timer needed - calculation happens at read time. A cap prevents infinite accumulation (e.g., max 24 hours worth).

**State Sync Strategy**
- Read: from GenServer memory (instant)
- Write: update GenServer state, then async persist to DB
- On server restart: load from DB on first access

---

Does this architecture make sense?

---

## User

sounds good

---

## Assistant

## Section 3: Buildings & Progression Mechanics

**Building Schema**
```elixir
%Building{
  settlement_id: ...,
  type: :farm | :lumber_mill | :quarry | :mine | :iron_forge | :crystal_refinery | 
         :barracks | :town_hall | :tavern | :watchtower,
  level: 1..10,
  position: 1..36  # 6x6 grid for visual placement
}
```

**Construction Rules**
- Each building type has max instances (production: 6 each, special: 1 each)
- Build time: instant for MVP (could add timer later)
- Cost formula: `base_cost × 1.8^(level - 1)`
- Example: Farm level 1 costs 100 food, level 5 costs ~1,000 food

**Progression Triggers**
Stage advancement checked after each building completion:
```elixir
def check_progression(settlement) do
  conditions = %{
    2 => fn s -> production_rate(s, :food) >= 50 end,
    3 => fn s -> total_production(s) >= 200 && has_building?(s, :town_hall) end,
    # ...
  }
  
  if conditions[settlement.progression_stage + 1].(settlement) do
    {:advance, settlement.progression_stage + 1}
  else
    :no_change
  end
end
```

**Stage Unlocks**
- Stage 1: Food, Wood, Stone, Gold + Farm, Lumber Mill, Quarry
- Stage 2: Barracks + Militia unit
- Stage 3: Iron + Mine + Iron Forge
- Stage 4: Tavern + Hero recruitment
- Stage 5: Crystal + Crystal Refinery + Watchtower + Missions

---

Does this progression flow work?

---

## User

mosty, but move stage 2 after stage 4 (units after heroes)

---

## Assistant

## Section 3 (Revised): Buildings & Progression Mechanics

**Building Schema**
```elixir
%Building{
  settlement_id: ...,
  type: :farm | :lumber_mill | :quarry | :mine | :iron_forge | :crystal_refinery | 
         :barracks | :town_hall | :tavern | :watchtower,
  level: 1..10,
  position: 1..36  # 6x6 grid for visual placement
}
```

**Construction Rules**
- Each building type has max instances (production: 6 each, special: 1 each)
- Build time: instant for MVP (could add timer later)
- Cost formula: `base_cost × 1.8^(level - 1)`

**Progression Triggers**
Stage advancement checked after each building completion. Conditions evaluate production rates and building presence.

**Stage Unlocks (Revised)**
- Stage 1: Food, Wood, Stone, Gold + Farm, Lumber Mill, Quarry
- Stage 2: Iron + Mine + Iron Forge
- Stage 3: Crystal + Crystal Refinery + Watchtower + Missions
- Stage 4: Tavern + Hero recruitment
- Stage 5: Barracks + Militia unit

This creates a natural flow: establish economy → unlock rare resources → discover missions → recruit heroes → build armies for those missions.

---

Does this revised order work better?

---

## User

you know what? scratch heroes for now, we'll ad them later. also, crystal (with rafinery) should be at the end, so: 1) basic resources, 2) iron, 3) barracks + basic units, 4) watchtower + missions, 5) crystal + mages (advanced units)

---

## Assistant

## Section 3 (Revised): Buildings & Progression Mechanics

**Building Schema**
```elixir
%Building{
  settlement_id: ...,
  type: :farm | :lumber_mill | :quarry | :mine | :iron_forge | :crystal_refinery | 
         :barracks | :town_hall | :watchtower,
  level: 1..10,
  position: 1..36
}
```

**Construction Rules**
- Each building type has max instances (production: 6 each, special: 1 each)
- Build time: instant for MVP
- Cost formula: `base_cost × 1.8^(level - 1)`

**Stage Unlocks (MVP)**
- Stage 1: Food, Wood, Stone, Gold + Farm, Lumber Mill, Quarry
- Stage 2: Iron + Mine + Iron Forge
- Stage 3: Barracks + Militia (basic melee unit)
- Stage 4: Watchtower + Missions
- Stage 5: Crystal + Crystal Refinery + Mages (advanced ranged unit)

Heroes deferred to post-MVP. This creates a clear military progression: basic economy → advanced economy → basic army → missions → elite forces.

---

Ready for Section 4 (Units & Missions)?

---

## User

maybe we should also move iron after basic militia? so we'd unlock advanced units with/after iron

---

## Assistant

That makes sense - basic militia costs just gold/food, then iron unlocks armored/advanced units:

**Stage Unlocks (Revised)**
- Stage 1: Food, Wood, Stone, Gold + Farm, Lumber Mill, Quarry
- Stage 2: Barracks + Militia (basic unit, costs gold/food)
- Stage 3: Iron + Mine + Iron Forge + Armored units
- Stage 4: Watchtower + Missions
- Stage 5: Crystal + Crystal Refinery + Mages

This creates a nice military tier: militia → iron units → mage elites.

Sound right?

---

## User

sounds perfect

---

## Assistant

## Section 4: Units & Missions

**Unit Schema**
```elixir
%Unit{
  settlement_id: ...,
  type: :militia | :swordsman | :archer | :mage,
  count: integer  # units stack by type
}
```

**Unit Stats**
```elixir
@units %{
  militia:    %{attack: 5,  defense: 3,  cost: %{gold: 50, food: 20}},
  swordsman:  %{attack: 15, defense: 12, cost: %{gold: 80, iron: 30}},
  archer:     %{attack: 12, defense: 5,  cost: %{gold: 60, iron: 20, wood: 15}},
  mage:       %{attack: 25, defense: 8,  cost: %{gold: 150, crystal: 40}}
}
```

**Mission Schema**
```elixir
%Mission{
  id: ...,
  name: "Patrol the Woods",
  tier: 1..5,  # unlocks with stage
  min_units: 5,
  duration_seconds: 300,  # 5 minutes
  rewards: %{gold: 200, experience: 50},
  difficulty: 1.0,  # multiplier for combat calculation
  type: :story | :generated
}
```

**Mission Flow**
1. Player selects units and assigns to mission
2. Timer starts (units unavailable during mission)
3. On completion: combat calculation, rewards granted
4. Units return (some may be lost based on difficulty)

**Combat (Simplified for MVP)**
```
player_power = sum(unit.attack × count for all assigned units)
success_chance = player_power / (player_power + mission_difficulty × 100)
```

Roll RNG. On success: full rewards. On failure: partial rewards, 10-30% unit losses.

---

Does this unit/mission system work?

---

## User

sounds good for now

---

## Assistant

## Section 5: LiveView UI & User Flow

**Main Layout**
Single LiveView with tabbed navigation:
- **Overview**: Resource bars, production rates, current stage
- **Buildings**: 6x6 grid, click empty slot to build, click building to upgrade
- **Units**: Recruitment panel, current army display
- **Missions**: Available missions list, active missions with timers

**Core LiveView Module**
```elixir
defmodule VibexWeb.Live.SettlementLive do
  use VibexWeb, :live_view
  
  def mount(_params, _session, socket) do
    settlement = SettlementServer.get_or_create(user_id)
    {:ok, assign(socket, :settlement, settlement)}
  end
  
  def handle_info(:tick, socket) do
    # Refresh settlement state every second for live updates
    {:noreply, assign(socket, :settlement, SettlementServer.state(socket.assigns.settlement.id))}
  end
end
```

**Real-time Updates**
- `Process.send_after(self(), :tick, 1000)` for resource counters
- Mission timers count down visually
- Construction/upgrade animations on completion

**Visual Feedback**
- Resource bars show current/max (cap at 24h production)
- Building slots show construction cost on hover
- Mission cards show success probability before committing
- Notifications for stage advancement

---

This covers the MVP scope. Ready for me to write the full design document?

---

## User

sounds good, except the cap - resource cap should be determined by a storage building level (+ some base capacity until 1st lvl), not 24h production

---

## Assistant

## Section 5 (Revised): LiveView UI & User Flow

**Main Layout**
Single LiveView with tabbed navigation:
- **Overview**: Resource bars, production rates, current stage
- **Buildings**: 6x6 grid, click empty slot to build, click building to upgrade
- **Units**: Recruitment panel, current army display
- **Missions**: Available missions list, active missions with timers

**Resource Storage**
Each resource has a storage cap determined by:
- Base capacity: 500 per resource (until storage built)
- Storage buildings increase cap by level:
  - **Granary**: +500 food per level
  - **Warehouse**: +500 wood/stone per level
  - **Treasury**: +500 gold per level
  - **Armory**: +500 iron per level (unlocks with iron)
  - **Vault**: +500 crystal per level (unlocks with crystal)

**Real-time Updates**
- `Process.send_after(self(), :tick, 1000)` for resource counters
- Mission timers count down visually
- Construction/upgrade animations on completion

---

This covers the MVP scope. Ready for the full design document?

---

## User

armory doesn't sound right as a storage building, I'd rather reserve that for some army equipment (tbd later). vault should probably be "crystal vault"

---

## Assistant

**Tool: question**

---

## Assistant

## Section 5 (Revised): LiveView UI & User Flow

**Main Layout**
Single LiveView with tabbed navigation:
- **Overview**: Resource bars, production rates, current stage
- **Buildings**: 6x6 grid, click empty slot to build, click building to upgrade
- **Units**: Recruitment panel, current army display
- **Missions**: Available missions list, active missions with timers

**Resource Storage**
Each resource has a storage cap determined by:
- Base capacity: 500 per resource (until storage built)
- Storage buildings increase cap by level:
  - **Granary**: +500 food per level
  - **Warehouse**: +500 wood/stone/iron per level
  - **Treasury**: +500 gold per level
  - **Crystal Vault**: +500 crystal per level (unlocks with crystal)

**Real-time Updates**
- `Process.send_after(self(), :tick, 1000)` for resource counters
- Mission timers count down visually
- Construction/upgrade animations on completion

---

This covers the MVP scope. Ready for the full design document?

---

## User

also, storage capacity should increase progressively, not linearly

---

## Assistant

## Section 5 (Revised): LiveView UI & User Flow

**Main Layout**
Single LiveView with tabbed navigation:
- **Overview**: Resource bars, production rates, current stage
- **Buildings**: 6x6 grid, click empty slot to build, click building to upgrade
- **Units**: Recruitment panel, current army display
- **Missions**: Available missions list, active missions with timers

**Resource Storage**
Each resource has a storage cap determined by:
- Base capacity: 500 per resource (no storage building)
- Storage buildings increase cap progressively:
  - Level 1: +500 (total 1,000)
  - Level 2: +750 (total 1,750)
  - Level 3: +1,125 (total 2,875)
  - Formula: `+500 × 1.5^(level - 1)`
  
Storage buildings:
- **Granary**: Food storage
- **Warehouse**: Wood, Stone, Iron storage
- **Treasury**: Gold storage
- **Crystal Vault**: Crystal storage (unlocks with crystal)

**Real-time Updates**
- `Process.send_after(self(), :tick, 1000)` for resource counters
- Mission timers count down visually
- Construction/upgrade animations on completion

---

This covers the MVP scope. Ready for the full design document?

---

## User

sounds good

---

## Assistant

**Tool: bash**

---

## Assistant

**Tool: write**

---

## Assistant

**Tool: bash**

---

## Assistant

**Tool: bash**

---

## Assistant

Design document written to `docs/plans/2026-02-13-settlement-game-design.md` and committed.

Ready to set up for implementation?

---

## User

create a PRD for this plan

---

## Assistant

**Tool: skill**

---

## Assistant

I have the design document. A few clarifying questions:

1. What's the primary delivery approach?
   A. Implement all stories in sequence, then test the full game
   B. Implement and verify each story independently before moving to next
   C. Group related stories into milestones, verify each milestone

2. What quality commands must pass for each story?
   A. `mix test` (tests must pass)
   B. `mix test && mix format --check-formatted`
   C. `mix test && mix credo --strict`
   D. Other: [specify]

3. Should UI stories include browser verification?
   A. Yes, verify visually that LiveView renders correctly
   B. No, automated tests are sufficient for MVP

---

## User

1B 2C 3A (but mostly smoke tests of the correct items/values being present in the UI, not detailed specs)

---

## Assistant

[PRD]
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
[/PRD]

---

## User

now, persist this PRD in a file

---

## Assistant

**Tool: write**

---

## Assistant

PRD saved to `tasks/prd-settlement-management-game.md`.

---

## User

good, now also store the agreed-upon implementation details and learnings so that we don't loose anything important from this session

---

## Assistant

**Tool: write**

---

## Assistant

**Tool: bash**

---

## Assistant

**Tool: bash**

---

## Assistant

Created three documents:
- `docs/plans/2026-02-13-settlement-game-design.md` - Full design document
- `docs/plans/2026-02-13-settlement-game-notes.md` - Decision history and implementation details
- `tasks/prd-settlement-management-game.md` - PRD with 20 user stories

All committed with jj.

---

