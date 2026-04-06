# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DataExtractor is an Elder Scrolls Online (ESO) addon that extracts comprehensive game data (skills, items, achievements, collectibles, etc.) and saves it to SavedVariables for external use. This is a Chinese-localized fork with enhanced features.

**Language**: Lua (ESO addon API)
**Target Game**: Elder Scrolls Online (API Version 101047)
**Dependencies**: LibAddonMenu-2.0, LibSets, PithkaAchievementTracker

## Architecture

### Entry Point & Initialization
- [DataExtractor.txt](DataExtractor.txt): Addon manifest defining load order
- [Init.lua](Init.lua): Data structure schemas (commented documentation for all output formats)
- [DataExtractor.lua](DataExtractor.lua): Main initialization, event handlers, slash commands, and SaveData() function

### Data Extraction Modules
Each module follows the pattern: `GetAll{Category}()` function that iterates game API and populates `DataExtractor.data{Category}` tables.

- [Skills.lua](Skills.lua): Regular skills, Champion Points (CP) skills, crafted/scribed abilities with style collectibles
- [Items.lua](Items.lua): Item sets, furniture, recipes, foods. Includes antiquity-to-zone mapping logic
- [Potions.lua](Potions.lua): Algorithmic potion/poison generation from reagent combinations (no inventory required)
- [Achievements.lua](Achievements.lua): Achievement categories, subcategories, rewards (items, titles, dyes)
- [Collectibles.lua](Collectibles.lua): Mounts, pets, furniture collectibles, etc.
- [Antiquity.lua](Antiquity.lua): Antiquity leads with drop sources and lore entries
- [Houses.lua](Houses.lua): Player housing data
- [Dyes.lua](Dyes.lua): Dye colors, rarity, hue categories
- [Styles.lua](Styles.lua): Crafting style materials
- [Outfits.lua](Outfits.lua): Outfit style collectibles
- [Raids.lua](Raids.lua): Trial/dungeon data with achievement mappings

### Supporting Files
- [Settings.lua](Settings.lua): LibAddonMenu2 UI with extraction buttons and language toggle
- [locationsdata_zh.lua](locationsdata_zh.lua): Chinese zone name mappings
- [potionData/](potionData/): Static data for potion calculation (PotionEffectData.lua, ReagentData.lua, SolventData.lua)

## Key Workflows

### Data Extraction Flow
1. User triggers extraction via Settings UI button or slash command (e.g., `/scrapeskills`)
2. Module's `GetAll{Category}()` function iterates game API with async callbacks to prevent UI freezing
3. Data populates `DataExtractor.data{Category}` in-memory tables
4. User clicks "保存所有数据" (Save All Data) button or runs `/scrapesave`
5. `SaveData()` copies all in-memory tables to `DataExtractor.savedVariables`
6. `ReloadUI()` forces ESO to write SavedVariables to disk at: `Documents\Elder Scrolls Online\live\SavedVariables\DataExtractor.lua`

### Async Pattern (Skills Example)
Skills extraction uses `zo_callLater()` callbacks to process one skill at a time, updating `DataExtractor.currentType`, `currentLine`, `currentSkill` position trackers. See `UpdateSkillsPosition()` in [Skills.lua](Skills.lua).

### Potion Generation Algorithm
[Potions.lua](Potions.lua) doesn't scan inventory. Instead:
1. Generates all 2-reagent and 3-reagent combinations
2. Applies alchemy rules (effects must appear in ≥2 reagents, opposite effects cancel)
3. Encodes effects as `potionData = effect1*256² + effect2*256 + effect3`
4. Constructs item links: `|H1:item:{itemId}:{intType}:{intLevel}:0:...:0:{potionData}|h|h`
5. Queries game API for descriptions via `GetItemLinkOnUseAbilityInfo()`

### Antiquity-to-Zone Mapping
[Items.lua](Items.lua) builds `antiquityItems` table on first run, mapping set item IDs to zone IDs by:
1. Iterating `GetAntiquitySetRewardId()` to find set rewards
2. For each set, collecting all fragment leads and their dig zones
3. If all leads share one zone, use that; otherwise, fallback to antiquity category name → zone name lookup

## Common Commands

### In-Game Slash Commands
- `/scrapeskills` - Extract all skills (requires Scribing UI opened once to unlock button)
- `/scrapecpskills` - Extract Champion Points skills
- `/scrapeitems` - Extract sets, furniture, foods, recipes
- `/scrapepotions` - Generate all potion/poison combinations
- `/scrapeachievs` - Extract achievements
- `/scrapestyles` - Extract crafting styles
- `/scrapeoutfitstyles` - Extract outfit styles
- `/scrapeantiquities` - Extract antiquity leads
- `/scrapehouses` - Extract housing data
- `/scrapedyes` - Extract dyes
- `/scrapecollectibles` - Extract collectibles
- `/scrapesave` - Save all extracted data and reload UI

### Development Notes
- **No build/test system**: This is a live addon loaded directly by ESO client
- **Testing**: Copy addon folder to `Documents\Elder Scrolls Online\live\AddOns\`, launch game, open Settings > Addons > Data Extractor
- **Output location**: `Documents\Elder Scrolls Online\live\SavedVariables\DataExtractor.lua` (Lua table format)
- **Language toggle**: Settings UI has "中英文切换" button to switch between Chinese/English client language

## Data Structure Reference

All output schemas are documented in [Init.lua](Init.lua) with detailed field comments. Key structures:

- `dataSkills`: Nested by skill type → skill line → skills, with morphs/passives/crafted abilities
- `dataItems.Sets`: Item sets with bonuses, slots, acquisition zones, antiquity leads
- `dataPotions`: Indexed by itemId, contains effect combinations and descriptions
- `dataAchievs`: Categories → subcategories → achievements with rewards
- `dataAntiquities`: Antiquity leads with drop sources, lore, difficulty

## Important Constraints

- **Crafted skills requirement**: Must open Scribing UI once per session to populate `SCRIBING_DATA_MANAGER.sortedCraftedAbilityTable` before extraction
- **Async processing**: All extraction functions use callbacks to avoid freezing the game client
- **Chinese localization**: UI text and some logic (zone mappings) are Chinese-specific
- **SavedVariables format**: Output is Lua table syntax, not JSON
