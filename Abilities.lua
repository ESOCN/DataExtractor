-- 提取游戏内所有技能数据（通过 DoesAbilityExist 遍历 ID 范围，涵盖玩家/NPC/怪物技能）
-- 注：ESO API 中 GetNumAbilities() 仅返回约 523 条玩家可学技能，
--    无法枚举 NPC/怪物技能，因此改用暴力扫描 ID 1..MAX_ABILITY_ID
local function GetPowerTypes(abilityId)
    local powerTypes = {}
    local lastPowerType
    for i = 1, 4 do
        local mechanicFlag = GetNextAbilityMechanicFlag(abilityId, lastPowerType)
        if mechanicFlag == nil then
            break
        end
        if mechanicFlag == COMBAT_MECHANIC_FLAGS_MAGICKA or mechanicFlag == COMBAT_MECHANIC_FLAGS_STAMINA or
            mechanicFlag == COMBAT_MECHANIC_FLAGS_ULTIMATE or mechanicFlag == COMBAT_MECHANIC_FLAGS_HEALTH then
            local cost = GetAbilityCost(abilityId, mechanicFlag, nil, MAX_RANKS_PER_ABILITY)
            if cost and cost > 0 then
                local resName
                if mechanicFlag == COMBAT_MECHANIC_FLAGS_MAGICKA then
                    resName = "Magicka"
                elseif mechanicFlag == COMBAT_MECHANIC_FLAGS_STAMINA then
                    resName = "Stamina"
                elseif mechanicFlag == COMBAT_MECHANIC_FLAGS_ULTIMATE then
                    resName = "Ultimate"
                elseif mechanicFlag == COMBAT_MECHANIC_FLAGS_HEALTH then
                    resName = "Health"
                end
                powerTypes[resName] = cost
            end
        end
        lastPowerType = mechanicFlag
    end
    if next(powerTypes) then
        return powerTypes
    end
    return nil
end

local function AddAbility(abilityId)
    local name = GetAbilityName(abilityId)
    if not name or name == "" then
        return
    end

    local ability = {}

    ability.id = abilityId
    ability.name = zo_strformat(SI_ABILITY_NAME, name)
    ability.icon = GetAbilityIcon(abilityId)
    ability.description = GetAbilityDescription(abilityId)

    ability.passive = IsAbilityPassive(abilityId)
    ability.ultimate = IsAbilityUltimate(abilityId)
    ability.isPermanent = IsAbilityPermanent(abilityId)

    ability.isChanneled, ability.castTime = GetAbilityCastInfo(abilityId, MAX_RANKS_PER_ABILITY)

    ability.isTank, ability.isHealer, ability.isDamage = GetAbilityRoles(abilityId)

    ability.minRange, ability.maxRange = GetAbilityRange(abilityId, MAX_RANKS_PER_ABILITY)
    ability.target = GetAbilityTargetDescription(abilityId, MAX_RANKS_PER_ABILITY)
    ability.duration = GetAbilityDuration(abilityId, MAX_RANKS_PER_ABILITY)
    ability.radius = GetAbilityRadius(abilityId, MAX_RANKS_PER_ABILITY)
    ability.distance = GetAbilityAngleDistance(abilityId)
    ability.descHeader = GetAbilityDescriptionHeader(abilityId, MAX_RANKS_PER_ABILITY)

    ability.cost = GetAbilityCost(abilityId, nil, MAX_RANKS_PER_ABILITY)

    local freqMS = GetAbilityFrequencyMS(abilityId)
    if freqMS and freqMS > 0 then
        ability.frequencyMS = freqMS
        ability.costPerTick = GetAbilityCostPerTick(abilityId, nil, MAX_RANKS_PER_ABILITY)
    end

    local powerTypes = GetPowerTypes(abilityId)
    if powerTypes then
        ability.powerTypes = powerTypes
    end

    local buffType = GetAbilityBuffType(abilityId)
    if buffType and buffType > 0 then
        ability.buffType = buffType
    end

    local upgrade1, upgrade2, upgrade3 = GetAbilityUpgradeLines(abilityId)
    if upgrade1 and upgrade1 ~= "" then
        ability.upgradeLines = {}
        ability.upgradeLines[1] = upgrade1
        if upgrade2 and upgrade2 ~= "" then
            ability.upgradeLines[2] = upgrade2
        end
        if upgrade3 and upgrade3 ~= "" then
            ability.upgradeLines[3] = upgrade3
        end
    end

    local newEffect = GetAbilityNewEffectLines(abilityId)
    if newEffect and newEffect ~= "" then
        ability.newEffect = newEffect
    end

    table.insert(DataExtractor.dataAbilities, ability)
end

DataExtractor.MAX_ABILITY_ID = 400000

local function ProcessAbilityIdBatch(startId)
    if not DataExtractor.scrapingAbilities then
        return
    end

    local batchSize = 500
    local endId = math.min(startId + batchSize - 1, DataExtractor.MAX_ABILITY_ID)

    for id = startId, endId do
        if DoesAbilityExist(id) then
            local name = GetAbilityName(id, "player")
            if name and name ~= "" then
                AddAbility(id)
            end
        end
        DataExtractor.currentAbilityIndex = id
    end

    local progress = string.format("%.1f", DataExtractor.currentAbilityIndex / DataExtractor.MAX_ABILITY_ID * 100)
    d(string.format('%s 技能提取进度: %s%% (%d/%d) (已提取: %d)', DataExtractor.Colorize('DataExtractor:'),
        progress, DataExtractor.currentAbilityIndex, DataExtractor.MAX_ABILITY_ID, #DataExtractor.dataAbilities))

    if DataExtractor.currentAbilityIndex < DataExtractor.MAX_ABILITY_ID then
        zo_callLater(function()
            ProcessAbilityIdBatch(DataExtractor.currentAbilityIndex + 1)
        end, 25)
    else
        d(string.format('%s 所有技能数据提取完成! 共 %d 个技能. 使用 %s 保存数据',
            DataExtractor.Colorize('DataExtractor:'), #DataExtractor.dataAbilities, DataExtractor.slashSave))
        DataExtractor.scrapingAbilities = false
    end
end

function DataExtractor.GetAllAbilities()
    if DataExtractor.scrapingAbilities then
        d('|cFFFFFFDataExtractor:|r 技能遍历已在进行!')
        return
    end

    DataExtractor.scrapingAbilities = true
    DataExtractor.dataAbilities = {}

    DataExtractor.currentAbilityIndex = 1

    d(string.format('%s 开始提取所有技能数据... 扫描范围: 1-%d (包含玩家/NPC/怪物技能)',
        DataExtractor.Colorize('DataExtractor:'), DataExtractor.MAX_ABILITY_ID))
    d('|cFFFFFFDataExtractor:|r 提示: 此过程较慢，请耐心等待（约需数分钟）')

    ProcessAbilityIdBatch(1)
end
