# Vibex: Settlement Management Game - Design Document

## Overview

Vibex is an idle/incremental settlement management game built with Phoenix LiveView. Players build a settlement, recruit armies, and send them on missions while progressing through stages that unlock new features.

## Core Design Principles

- **Idle mechanics**: Resources accumulate over time; players return to make decisions
- **Stage-based progression**: New building types, units, and mechanics unlock as settlement grows
- **Mission-driven gameplay**: Predetermined story missions early, procedural missions later
- **Single settlement focus**: Design supports future multi-settlement expansion

## Stage Unlocks

| Stage | Buildings | Units | Resources | Requirements |
|-------|-----------|-------|-----------|--------------|
| 1 | Town Hall, Farm, Lumber Mill, Quarry, Granary, Warehouse, Treasury | - | Gold, Wood, Stone, Food | Starting stage |
| 2 | Barracks | Militia | - | Town Hall level 2, total production >= 50 |
| 3 | Mine, Iron Forge | Swordsman, Archer | Iron | Town Hall level 3, Barracks built, 10+ militia |
| 4 | Watchtower | - | - | Town Hall level 4, Iron Forge built, iron production >= 20 |
| 5 | Crystal Refinery, Crystal Vault | Mage | Crystal | Town Hall level 5, 5+ completed missions |

## Town Hall

The Town Hall is the main settlement building and progression gateway:
- **Building level cap**: Other buildings capped at `Town Hall level + 2`
- **Upgrade prerequisites**: Tied to stage unlock conditions (see table above)
- **Central role**: Town Hall level gates access to new building types

### Town Hall Upgrade Prerequisites

| Town Hall Level | Prerequisites to Upgrade |
|-----------------|--------------------------|
| 1 → 2 | Total production >= 50, 500 gold, 200 wood, 200 stone |
| 2 → 3 | Barracks built, 10+ militia |
| 3 → 4 | Iron Forge built, iron production >= 20 |
| 4 → 5 | Watchtower built, 5+ completed missions |

## Building Instances

No limits on building instances per type for MVP. Players may build freely within the 36-slot grid. Constraints can be added post-MVP based on player behavior.

---

## Architecture

### Event-Sourced GenServer Pattern

Each settlement runs as a GenServer process:

- **On-demand resource calculation**: Uses timestamps to compute accumulated resources
- **State persistence**: Async writes to database after meaningful actions
- **Offline progress**: Players gain resources while away (calculated at read time)
- **Registry lookup**: Settlements spawn on first access, keyed by user ID

### Process Flow

```
User action → LiveView → SettlementServer (GenServer) → State update → Async DB persist
                                    ↓
                          Resource calculation from timestamp
```

---

## Data Model

### Settlement

```elixir
%Settlement{
  id: ...,
  user_id: ...,
  resources: %{
    gold: 1500,
    wood: 800,
    stone: 600,
    food: 400,
    iron: 200,
    crystal: 50
  },
  storage_capacity: %{
    gold: 1000,
    wood: 1750,
    stone: 1750,
    food: 1000,
    iron: 1750,
    crystal: 500
  },
  last_calculated_at: ~U[2026-02-13 10:00:00Z],
  progression_stage: 1..5
}
```

### Building

```elixir
%Building{
  settlement_id: ...,
  type: :town_hall | :farm | :lumber_mill | :quarry | :mine | :iron_forge | :crystal_refinery |
         :barracks | :watchtower |
         :granary | :warehouse | :treasury | :crystal_vault,
  level: 1..10,
  position: {row, col}  # e.g., {1, 1} for top-left, {6, 6} for bottom-right
}
```

**Position System:**
- Grid is 6x6 (36 slots)
- Position stored as `{row, col}` tuple where row and col are 1-6
- More readable for debugging and extensible for future grid sizes

### Unit

```elixir
%Unit{
  settlement_id: ...,
  type: :militia | :swordsman | :archer | :mage,
  count: integer
}
```

### Mission

```elixir
%Mission{
  id: ...,
  name: "Patrol the Woods",
  tier: 1..5,
  min_units: 5,
  duration_seconds: 300,
  rewards: %{gold: 200, experience: 50},
  difficulty: 1.0,
  type: :story | :generated
}
```

### Mission Assignment

```elixir
%MissionAssignment{
  settlement_id: ...,
  mission_id: ...,
  units: %{militia: 10, swordsman: 5},
  started_at: ~U[2026-02-13 10:00:00Z],
  completes_at: ~U[2026-02-13 10:05:00Z]
}
```

---

## Resources

### Resource Types

| Resource | Unlocks | Primary Use |
|----------|---------|-------------|
| Gold | Stage 1 | Unit recruitment, building construction |
| Food | Stage 1 | Unit recruitment, population |
| Wood | Stage 1 | Building construction |
| Stone | Stage 1 | Building construction |
| Iron | Stage 3 | Advanced units, upgrades |
| Crystal | Stage 5 | Elite units (mages) |

### Production Calculation

```elixir
def production_rate(settlement, resource) do
  settlement.buildings
  |> Enum.filter(&produces_resource?(&1.type, resource))
  |> Enum.map(&building_production/1)
  |> Enum.sum()
end

def building_production(%{type: type, level: level}) do
  base = @base_production[type]  # e.g., 10 food/sec for farm level 1
  base * :math.pow(1.5, level - 1)  # 50% increase per level
end

def current_resources(settlement) do
  elapsed = DateTime.diff(DateTime.utc_now(), settlement.last_calculated_at)
  
  settlement.resources
  |> Enum.map(fn {resource, amount} ->
    production = production_rate(settlement, resource)
    max = settlement.storage_capacity[resource]
    new_amount = min(amount + (production * elapsed), max)
    {resource, new_amount}
  end)
  |> Map.new()
end
```

### Storage Capacity

Base capacity: 500 per resource (no storage building)

Storage buildings increase capacity progressively:
- Level 1: +500 (total 1,000)
- Level 2: +750 (total 1,750)
- Level 3: +1,125 (total 2,875)
- Formula: `+500 × 1.5^(level - 1)`

---

## Buildings

### Main Building

| Building | Purpose | Unlocks Stage |
|----------|---------|---------------|
| Town Hall | Progression gateway, caps other building levels | 1 |

### Production Buildings

| Building | Produces | Unlocks Stage |
|----------|----------|---------------|
| Farm | Food | 1 |
| Lumber Mill | Wood | 1 |
| Quarry | Stone | 1 |
| Mine | Iron | 3 |
| Iron Forge | Iron bonus | 3 |
| Crystal Refinery | Crystal | 5 |

### Special Buildings

| Building | Purpose | Unlocks Stage |
|----------|---------|---------------|
| Barracks | Unit recruitment | 2 |
| Watchtower | Missions | 4 |

### Storage Buildings

| Building | Stores | Unlocks Stage |
|----------|--------|---------------|
| Granary | Food | 1 |
| Warehouse | Wood, Stone, Iron | 1 |
| Treasury | Gold | 1 |
| Crystal Vault | Crystal | 5 |

### Construction Rules

- Cost formula: `base_cost × 1.8^(level - 1)`
- Build time: instant for MVP
- Grid: 6x6 (36 slots)
- Building level cap: `Town Hall level + 2` (except Town Hall itself)
- No limits on building instances per type for MVP

---

## Progression System

### Stage Unlocks

| Stage | Buildings | Units | Resources | Requirements |
|-------|-----------|-------|-----------|--------------|
| 1 | Town Hall, Farm, Lumber Mill, Quarry, Granary, Warehouse, Treasury | - | Gold, Wood, Stone, Food | Starting stage |
| 2 | Barracks | Militia | - | Town Hall level 2, total production >= 50 |
| 3 | Mine, Iron Forge | Swordsman, Archer | Iron | Town Hall level 3, Barracks built, 10+ militia |
| 4 | Watchtower | - | - | Town Hall level 4, Iron Forge built, iron production >= 20 |
| 5 | Crystal Refinery, Crystal Vault | Mage | Crystal | Town Hall level 5, 5+ completed missions |

### Progression Conditions

Stage advancement checked after each building completion:

```elixir
@progression_conditions %{
  2 => fn s -> town_hall_level(s) >= 2 && total_production(s) >= 50 end,
  3 => fn s -> town_hall_level(s) >= 3 && has_building?(s, :barracks) && unit_count(s, :militia) >= 10 end,
  4 => fn s -> town_hall_level(s) >= 4 && has_building?(s, :iron_forge) && production_rate(s, :iron) >= 20 && has_building?(s, :watchtower) end,
  5 => fn s -> town_hall_level(s) >= 5 && completed_missions(s) >= 5 end
}
```

### Town Hall Level Cap

Other buildings are capped at `Town Hall level + 2`. This creates a natural progression where players must upgrade the Town Hall before advancing other buildings further.

---

## Units

### Unit Types

| Unit | Attack | Defense | Cost | Unlocks Stage |
|------|--------|---------|------|---------------|
| Militia | 5 | 3 | 50 gold, 20 food | 2 |
| Swordsman | 15 | 12 | 80 gold, 30 iron | 3 |
| Archer | 12 | 5 | 60 gold, 20 iron, 15 wood | 3 |
| Mage | 25 | 8 | 150 gold, 40 crystal | 5 |

### Recruitment

- Units recruited from Barracks
- Recruitment is instant for MVP
- Units stack by type (stored as count, not individual entities)

---

## Missions

### Mission Structure

- **Story missions**: Predetermined, fixed requirements and rewards
- **Generated missions**: Procedurally created based on player progress (post-MVP)

### Mission Flow

1. Player selects mission from available list
2. Player assigns units (minimum required shown)
3. Mission starts, units become unavailable
4. Timer runs (visible countdown)
5. On completion: combat resolution, rewards granted
6. Units return (possible losses on failure)

### Combat Resolution

```elixir
def resolve_mission(assignment, mission) do
  player_power = 
    assignment.units
    |> Enum.map(fn {type, count} -> @unit_stats[type].attack * count end)
    |> Enum.sum()
  
  difficulty_power = mission.difficulty * 100
  success_chance = player_power / (player_power + difficulty_power)
  
  if :rand.uniform() < success_chance do
    {:success, mission.rewards, 0}  # full rewards, no losses
  else
    loss_rate = 0.1 + (:rand.uniform() * 0.2)  # 10-30% losses
    partial_rewards = map_values(mission.rewards, &(&1 * 0.5))
    {:failure, partial_rewards, loss_rate}
  end
end
```

---

## User Interface

### Main Layout

Single LiveView with tabbed navigation:

- **Overview**: Resource bars, production rates, current stage, stage progress
- **Buildings**: 6x6 grid with building selection panel
- **Units**: Current army display, recruitment panel
- **Missions**: Available missions, active missions with timers

### LiveView Structure

```elixir
defmodule VibexWeb.Live.SettlementLive do
  use VibexWeb, :live_view
  
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    settlement = SettlementServer.get_or_create(user_id)
    
    if connected?(socket) do
      Process.send_after(self(), :tick, 1000)
    end
    
    {:ok, assign(socket, :settlement, settlement)}
  end
  
  def handle_info(:tick, socket) do
    settlement = SettlementServer.state(socket.assigns.settlement.id)
    Process.send_after(self(), :tick, 1000)
    {:noreply, assign(socket, :settlement, settlement)}
  end
end
```

### Real-time Updates

- Resource counters update every second
- Mission timers count down visually
- Building construction animations
- Stage advancement notifications

---

## GenServer Implementation

### SettlementServer

```elixir
defmodule Vibex.SettlementServer do
  use GenServer
  
  def start_link(user_id) do
    GenServer.start_link(__MODULE__, user_id, name: via_tuple(user_id))
  end
  
  def get_or_create(user_id) do
    case Registry.lookup(Vibex.SettlementRegistry, user_id) do
      [] -> start_link(user_id)
      [{pid, _}] -> pid
    end
    state(user_id)
  end
  
  def state(user_id) do
    GenServer.call(via_tuple(user_id), :state)
  end
  
  def build(user_id, building_type, position) do
    GenServer.call(via_tuple(user_id), {:build, building_type, position})
  end
  
  # ... more actions
  
  def handle_call(:state, _from, state) do
    {:reply, calculate_current_state(state), state}
  end
  
  defp calculate_current_state(state) do
    # Apply resource accumulation from last_calculated_at
  end
end
```

---

## Database Schema

### Tables

```sql
CREATE TABLE settlements (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users NOT NULL,
  resources JSONB NOT NULL DEFAULT '{}',
  storage_capacity JSONB NOT NULL DEFAULT '{}',
  last_calculated_at TIMESTAMP NOT NULL,
  progression_stage INTEGER NOT NULL DEFAULT 1,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE buildings (
  id UUID PRIMARY KEY,
  settlement_id UUID REFERENCES settlements NOT NULL,
  type TEXT NOT NULL,
  level INTEGER NOT NULL DEFAULT 1,
  position_row INTEGER NOT NULL,
  position_col INTEGER NOT NULL,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  UNIQUE(settlement_id, position_row, position_col)
);

CREATE TABLE units (
  id UUID PRIMARY KEY,
  settlement_id UUID REFERENCES settlements NOT NULL,
  type TEXT NOT NULL,
  count INTEGER NOT NULL DEFAULT 0,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE missions (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  tier INTEGER NOT NULL,
  min_units INTEGER NOT NULL,
  duration_seconds INTEGER NOT NULL,
  rewards JSONB NOT NULL,
  difficulty FLOAT NOT NULL,
  type TEXT NOT NULL,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE mission_assignments (
  id UUID PRIMARY KEY,
  settlement_id UUID REFERENCES settlements NOT NULL,
  mission_id UUID REFERENCES missions NOT NULL,
  units JSONB NOT NULL,
  started_at TIMESTAMP NOT NULL,
  completes_at TIMESTAMP NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

---

## MVP Scope

### Included

- Settlement with GenServer-based resource system
- 6 production buildings + 4 storage buildings + 3 special buildings
- 4 unit types across 5 progression stages
- Story missions (5-10 predetermined)
- Basic combat resolution
- Single LiveView UI with tabs

### Deferred to Post-MVP

- Heroes system
- Procedurally generated missions
- Multiple settlements
- Building construction timers
- Unit upgrades and equipment
- PvP/combat missions
- Trading/markets

---

## File Structure

```
lib/vibex/
├── settlement_server.ex       # GenServer for settlement state
├── settlement.ex              # Settlement schema/context
├── buildings/
│   ├── building.ex            # Building schema
│   └── buildings.ex           # Buildings context
├── units/
│   ├── unit.ex                # Unit schema
│   └── units.ex               # Units context
├── missions/
│   ├── mission.ex             # Mission schema
│   ├── mission_assignment.ex  # Mission assignment schema
│   └── missions.ex            # Missions context
└── progression.ex             # Progression logic

lib/vibex_web/
├── live/
│   └── settlement_live.ex     # Main game LiveView
└── components/
    └── game_components.ex     # Building grid, resource bars, etc.
```

---

## Next Steps

1. Create database migrations for core tables
2. Implement SettlementServer GenServer
3. Build core schemas and contexts
4. Create SettlementLive with Overview tab
5. Implement Buildings tab and construction
6. Add Units tab and recruitment
7. Add Missions tab and mission system
8. Polish UI and add progression notifications
