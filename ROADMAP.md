# Echoes in the Dark - Development Roadmap

Transforming the roguelike tutorial base into a mining-themed dungeon crawler.

## Current State (from Tutorial Base)

### ✅ Complete Systems
- Turn-based combat (queue-based, player → enemies)
- FOV/Vision (shadowcasting, fixed 10-tile radius)
- Procedural dungeon generation (rooms + corridors)
- Entity-Component architecture with message passing
- Combat mechanics (HP, attack, defense)
- Inventory system (24 slots)
- Equipment system (weapon, armor slots)
- XP/Leveling (+HP/Power/Defense choices)
- Items (potions, scrolls with targeting)
- Enemy AI (modular: patrol, chase, melee)
- Depth-based difficulty scaling
- Save/Load system

---

## Phase 1: Core Mining Mechanics

### 1.1 Dynamic Light System ✅ DONE
- [x] Modify `FovComponent` base radius to 2 (near-blind without light)
- [x] Create `LightRadiusEquippableEffect` for light bonus
- [x] Add `LightSource` equipment slot (slot 7)
- [x] Implement torch entity (+5 radius, yellow tint)
- [x] Implement lantern entity (+8 radius, brighter)
- [x] Player starts with equipped torch
- [x] Add torch/lantern to dungeon loot tables
- [x] Add light duration system (torches: 100 turns, lanterns: 200 turns)
- [x] Light sources burn out and stop providing light
- [x] HUD shows remaining light duration
- [ ] Add darkness penalties (accuracy, enemy visibility) (future)

### 1.2 Mining System ✅ DONE
- [x] Create `MineableComponent` for ore deposits
- [x] Create `MineAction` (press M to select direction)
- [x] Add ore deposit entities: Copper, Iron, Silver, Gold, Mithril
- [x] Ore deposits spawn along room walls (depth-based rarity)
- [x] Mining yields 1-3 ore, depletes deposit visually
- [ ] Create `PickaxeComponent` (mining speed modifier) - future
- [ ] Implement carry weight/capacity system - future

### 1.3 Economy System ✅ DONE
- [x] Add `GoldComponent` to player (starts with 10g)
- [x] Add `ValueComponent` for sellable items  
- [x] Ore auto-sells when picked up
- [x] Gold display in HUD side panel
- [ ] Full merchant buy/sell system - needs town

---

## Phase 2: Hub Town

### 2.1 Town Scene
- [ ] Create town tileset/map
- [ ] Mine entrance (dungeon gateway)
- [ ] Basic navigation between town and mine

### 2.2 Merchants
- [ ] General Store (food, torches, oil, bandages)
- [ ] Blacksmith (weapons, armor, upgrades)
- [ ] Mining Supply (pickaxes, ore satchels)
- [ ] Alchemist (magical light sources, potions)

### 2.3 Town Services
- [ ] Inn (healing, saving)
- [ ] Town Hall (quest board)
- [ ] Storage depot (bulk ore storage)

---

## Phase 3: Content Expansion

### 3.1 Enemy Variety
- [ ] Tier 1 (Levels 1-3): Rats, bats, giant spiders
- [ ] Tier 2 (Levels 4-7): Goblins, cave trolls, undead miners
- [ ] Tier 3 (Levels 8-12): Wraiths, dark spawn, corrupted elementals
- [ ] Tier 4 (Levels 13+): Eldritch horrors, ancient guardians
- [ ] Boss encounters every 5 levels

### 3.2 Mine Biomes
- [ ] Early levels: Stone tunnels with wooden supports
- [ ] Mid levels: Abandoned shafts with water hazards
- [ ] Deep levels: Ancient crypts with eldritch corruption

### 3.3 Equipment Progression
- [ ] Weapons: Dagger → Short Sword → Longsword → Enchanted
- [ ] Armor: Cloth → Leather → Chainmail → Plate
- [ ] Pickaxes: Rusty → Iron → Steel → Diamond → Enchanted
- [ ] Light: Torch → Lantern → Enchanted Lantern → Magical Orb

---

## Phase 4: Advanced Features

### 4.1 Survival Mechanics
- [ ] Hunger system
- [ ] Stamina system
- [ ] Environmental hazards (flooding, cave-ins, gas)

### 4.2 Progression Systems
- [ ] Town upgrades (invest gold to improve buildings)
- [ ] Unlockable starting equipment
- [ ] Crafting system
- [ ] Enchanting system

### 4.3 Narrative
- [ ] Quest system
- [ ] Lore tablets (discoverable story)
- [ ] Multiple endings

---

## Technical Notes

### New Components Needed
```
LightSourceComponent    - radius, duration, fuel_type
MineableComponent       - ore_type, mining_time, yield
PickaxeComponent        - mining_speed_modifier
CarryCapacityComponent  - max_weight, current_weight
GoldComponent           - gold_amount
MerchantComponent       - inventory, prices
```

### New Actions Needed
```
MineAction              - Extract ore from deposit
BuyAction               - Purchase from merchant
SellAction              - Sell items to merchant
RefuelAction            - Add oil to lantern
ToggleLightAction       - Turn light source on/off
```

### Architecture Pattern
Follow existing message-passing pattern:
```gdscript
# Example: Mining affects FOV radius via light duration
func process_message_precalculate(message: Message) -> void:
    match message.type:
        "recalculate_fov":
            var radius_calc = message.get_calculation("radius")
            radius_calc.terms.append(light_bonus)
```
