# Settlement Game - Implementation Notes

## Session: 2026-02-13

### Decision History

#### Play Style
- **Decision**: Idle/incremental game
- **Rationale**: Good for casual play, fits Phoenix LiveView well, resources accumulate while away

#### Progression System
- **Decision**: Hybrid of tech tree and mission-based
- **Rationale**: Unlocks new building/unit types as settlement grows AND through mission completion

#### Resource System
- **Decision**: Extended (6+) resources: Gold, Wood, Stone, Food, Iron, Crystal
- **Rationale**: More depth, staged unlock creates progression feel
- **Note**: Basic 4 (gold, wood, stone, food) available from start; Iron unlocks stage 3, Crystal stage 5

#### Settlement Scope
- **Decision**: Single settlement for MVP, architecture open to multi-settlement later
- **Rationale**: Simpler initial implementation, GenServer-per-settlement scales naturally

#### Mission System
- **Decision**: Hybrid - predetermined story missions early, procedural later
- **Rationale**: Story missions provide structure for new players, procedural adds replayability post-MVP

#### Scope
- **Decision**: MVP scope - get it playable first
- **Deferred**: Heroes system (explicitly pushed to post-MVP during discussion)

---

### Stage Unlock Iterations

We went through several iterations on the stage unlock order:

**Initial Proposal:**
1. Basic resources
2. Barracks + Militia
3. Iron + Iron Forge
4. Tavern + Heroes
5. Crystal + Mages

**Revision 1** (user feedback: units after heroes):
1. Basic resources
2. Iron
3. Crystal + Watchtower + Missions
4. Tavern + Heroes
5. Barracks + Militia

**Revision 2** (user feedback: remove heroes for MVP):
1. Basic resources
2. Iron
3. Crystal + Watchtower + Missions
4. Tavern + Heroes
5. Barracks + Militia

**Final** (user feedback: basic militia before iron, crystal at end):
1. Basic resources (Food, Wood, Stone, Gold + production buildings)
2. Barracks + Militia (basic unit)
3. Iron + Mine + Iron Forge + Swordsman, Archer
4. Watchtower + Missions
5. Crystal + Crystal Refinery + Crystal Vault + Mage

**Rationale for final order**: Creates natural military progression: militia → iron units → mage elites. Basic units cost only gold/food, iron unlocks armored units, crystal unlocks elite magic units.

---

### Storage System Evolution

**Initial**: 24-hour production cap
**User feedback**: Resource cap should be from storage buildings, not arbitrary time

**Revision**: Storage buildings with progressive capacity
- Base capacity: 500 per resource (no storage building)
- Level 1: +500 (total 1,000)
- Formula: `+500 × 1.5^(level - 1)`

**Storage Building Names**:
- Granary → Food
- Warehouse → Wood, Stone, Iron
- Treasury → Gold
- Crystal Vault → Crystal

**Naming iterations**:
- "Armory" for iron storage → rejected (reserved for future equipment system)
- "Vault" → renamed to "Crystal Vault" for clarity
- Iron storage → simplified to Warehouse (already stores wood/stone)

---

### Architecture Decisions

#### GenServer Pattern (Approach 1)
**Chosen approach**: Event-sourced with GenServer

**Why not Approach 2 (Polling with DB state)**:
- Creates database load with constant updates
- "Catch-up" calculations complex when player returns

**Why not Approach 3 (Pure LiveView with ETS)**:
- No durability - game state lost on server restart
- Only good for prototypes

**Benefits of chosen approach**:
- Accurate "time since last visit" calculations (essential for idle games)
- GenServer per settlement naturally supports multi-settlement future
- Event sourcing provides audit trail for debugging
- Fits Phoenix/BEAM philosophy

---

### Technical Details

#### Resource Production Formula
```
production = base_rate × 1.5^(level - 1)
```
- 50% increase per level
- Example: Farm level 1 = 10 food/sec, level 5 = ~50 food/sec

#### Building Cost Formula
```
cost = base_cost × 1.8^(level - 1)
```
- 80% increase per level
- Creates meaningful upgrade decisions

#### Combat Resolution (Simplified for MVP)
```
player_power = sum(unit.attack × count for all assigned units)
success_chance = player_power / (player_power + mission_difficulty × 100)
```
- Roll RNG for success
- On failure: 10-30% unit losses, partial rewards

---

### Unit Design

| Unit | Attack | Defense | Cost | Unlocks |
|------|--------|---------|------|---------|
| Militia | 5 | 3 | 50 gold, 20 food | Stage 2 |
| Swordsman | 15 | 12 | 80 gold, 30 iron | Stage 3 |
| Archer | 12 | 5 | 60 gold, 20 iron, 15 wood | Stage 3 |
| Mage | 25 | 8 | 150 gold, 40 crystal | Stage 5 |

**Design note**: Units stack by type (stored as count), not individual entities - simplifies database and UI.

---

### Building Grid

- 6x6 grid (36 slots)
- Position 1-36 stored in database
- Click empty slot → building selection modal
- Click occupied slot → upgrade options

---

### UI Tab Structure

Single LiveView with tabs:
1. **Overview** - Resource bars, production rates, stage
2. **Buildings** - 6x6 grid, construction/upgrade
3. **Units** - Current army, recruitment panel
4. **Missions** - Available missions, active timers

**Real-time updates**: `:tick` message every 1 second for resource counters and mission timers

---

### Explicitly Deferred (Post-MVP)

1. **Heroes system** - User explicitly said "scratch heroes for now, we'll add them later"
2. **Procedurally generated missions**
3. **Multiple settlements**
4. **Building construction timers**
5. **Unit upgrades and equipment**
6. **Armory** - Building name reserved for equipment system (TBD)
7. **PvP/combat missions**
8. **Trading/markets**

---

### Quality Gates Agreed

Per user story:
- `mix test` - tests must pass
- `mix credo --strict` - strict linting

For UI stories:
- Smoke test in browser: verify correct elements/values present (not detailed specs)

---

### Router Placement

SettlementLive should be at root path `/` in `live_session :require_authenticated_user`:
- Unauthenticated users → redirect to login
- Authenticated users → see their settlement immediately

---

### New Player Initialization

New users automatically get:
- Settlement created
- 500 of each basic resource (gold, wood, stone, food)
- Progression stage 1
- Base storage capacity (500 each resource)

---

### Key Constraints

1. No heroes in MVP (explicit user decision)
2. Storage determined by buildings, not time cap
3. Architecture must support future multi-settlement
4. Iron unlocks armored units, not basic militia
5. Crystal is end-game resource (stage 5)
