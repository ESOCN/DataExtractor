-- 将回调更新至下一个：技能、技能线、技能类型或完成。
-- 添加 GetPowerTypes 方法，由 @Chicor 贡献 ---------
local powerTypeCache = {}

local function GetPowerTypes(abilityId)
    local lastPowerType
    if powerTypeCache[abilityId] == nil then
        local newData = {}
        for i = 1, 4 do
            local powerType = GetNextAbilityMechanicFlag(abilityId, lastPowerType)
            if powerType and
                (powerType == COMBAT_MECHANIC_FLAGS_HEALTH or powerType == COMBAT_MECHANIC_FLAGS_MAGICKA or powerType ==
                    COMBAT_MECHANIC_FLAGS_STAMINA) then
                newData[powerType] = GetAbilityCost(abilityId, powerType, nil, MAX_RANKS_PER_ABILITY) -- add cost over time ??
                lastPowerType = powerType
            elseif powerType == nil then
                break
            end
        end
        powerTypeCache[abilityId] = newData
    end
    return powerTypeCache[abilityId]
end
-----------------------------------------

-- 新增：缓存 progressionId -> collectibleId 列表，避免重复遍历
local styleCache = {}

-- 获取某个技能的所有可能技能样式 collectibleId 列表（全局完整，包括未解锁的）
local function GetAllStyleCollectibleIdsForSkill(progressionId)
    if progressionId == 0 or progressionId == nil then
        return {}
    end

    if styleCache[progressionId] then
        return styleCache[progressionId]
    end

    local styleIds = {}

    -- 使用全局迭代器（可靠，不依赖 category）
    for _, collectibleData in ZO_COLLECTIBLE_DATA_MANAGER:CollectibleIterator() do
        if collectibleData then
            -- 过滤：只处理 ABILITY_FX_OVERRIDE 分类的 collectible
            local catType = collectibleData:GetCategoryType()
            if catType == COLLECTIBLE_CATEGORY_TYPE_ABILITY_FX_OVERRIDE then
                -- 匹配 progressionId
                local skillProgId = collectibleData:GetSkillStyleProgressionId()
                if skillProgId == progressionId then
                    local cid = collectibleData:GetId()
                    if cid and cid > 0 then
                        table.insert(styleIds, cid)
                    end
                end
            end
        end
    end

    -- 按 ID 排序，保持稳定顺序
    table.sort(styleIds)

    styleCache[progressionId] = styleIds
    return styleIds
end



local function UpdateSkillsPosition(i, j, line, k, skillsLimit, linesLimit)
    -- 该技能线的所有技能已完成！也处理空技能线的情况。
    if k == skillsLimit or k == -1 then
        -- 该类型所有技能线的所有技能均已完成！切换到下一类型。也处理空类型的情况。
        if j == linesLimit or j == -1 then
            -- 所有类型的所有技能线的所有技能均已完成！大功告成。
            if i == SKILL_TYPE_MAX_VALUE then
                -- 打印汇总信息。
                d(string.format(
                    '|cFFFFFFDataExtractor:|r 完工! 类别: %s 技能线: %s 技能: %s. (使用 %s 指令来保存数据!)',
                    SKILL_TYPE_MAX_VALUE, DataExtractor.dataSkillLinesCounter, DataExtractor.dataSkillsCounter,
                    DataExtractor.slashSave))
                -- 更新追踪状态。
                DataExtractor.scrapingSkills = false
            else
                -- d('finished type ' .. DataExtractor['currentType'])
                DataExtractor.currentType = DataExtractor.currentType + 1
            end
        else
            -- 切换到下一技能线。
            -- d('finished line ' .. DataExtractor['currentLine'])
            DataExtractor.currentLine = DataExtractor.currentLine + 1
        end
    else
        DataExtractor.currentSkill = DataExtractor.currentSkill + 1
    end
end

local scripts
local function AddCraftedSkill(i, j, k, skill)
    -- First run
    if not scripts then
        scripts = {}
        for i = 1, #SCRIBING_DATA_MANAGER.craftedAbilityScriptObjects do
            scripts[i] = {
                ["id"] = i,
                ["name"] = GetCraftedAbilityScriptDisplayName(i),
                ["description"] = GetCraftedAbilityScriptGeneralDescription(i),
                ["icon"] = GetCraftedAbilityScriptIcon(i)
            }
        end
        DataExtractor.dataSkills.scriptList = scripts
    end

    local craftAbilityList = SCRIBING_DATA_MANAGER.sortedCraftedAbilityTable

    local craftAbilityId = GetCraftedAbilitySkillCraftedAbilityId(i, j, k)
    local craftAbilityName = GetCraftedAbilityDisplayName(craftAbilityId)
    local craftAbilityDescription = GetCraftedAbilityDescription(craftAbilityId)
    local craftAbilityIcon = GetCraftedAbilityIcon(craftAbilityId)
    skill["id"] = craftAbilityId
    skill["name"] = craftAbilityName
    skill["description"] = craftAbilityDescription
    skill["icon"] = craftAbilityIcon

    local fScripts = craftAbilityList[craftAbilityId]["scribingSlotTable"][1]
    local sScripts = craftAbilityList[craftAbilityId]["scribingSlotTable"][2]
    local tScripts = craftAbilityList[craftAbilityId]["scribingSlotTable"][3]

    for k, primary in pairs(fScripts) do
        for k, secondary in pairs(sScripts) do
            for k, tertiary in pairs(tScripts) do
                if IsScribableScriptCombinationForCraftedAbility(craftAbilityId, primary, secondary, tertiary) then
                    SetCraftedAbilityScriptSelectionOverride(craftAbilityId, primary, secondary, tertiary)
                    local abilityId = GetCraftedAbilityRepresentativeAbilityId(craftAbilityId)

                    local subSkill = {
                        ["id"] = abilityId,
                        ["parentAbilityId"] = craftAbilityId,
                        ["scripts"] = {primary, secondary, tertiary},
                        ["name"] = GetAbilityName(abilityId),
                        ["description"] = GetAbilityDescription(abilityId) .. "\r\n\r\n" ..
                            GenerateCraftedAbilityScriptSlotDescriptionForAbilityDescription(abilityId, 1) .. "\r\n\r\n" ..
                            GenerateCraftedAbilityScriptSlotDescriptionForAbilityDescription(abilityId, 2) .. "\r\n\r\n" ..
                            GenerateCraftedAbilityScriptSlotDescriptionForAbilityDescription(abilityId, 3),
                        ["icon"] = GetAbilityIcon(abilityId),
                        ["isTank"] = select(1, GetAbilityRoles(abilityId)),
                        ["isHealer"] = select(2, GetAbilityRoles(abilityId)),
                        ["isDamage"] = select(3, GetAbilityRoles(abilityId)),
                        ["ultimate"] = IsAbilityUltimate(abilityId),
                        ["isChanneled"] = select(1, GetAbilityCastInfo(abilityId)),
                        ["castTime"] = select(2, GetAbilityCastInfo(abilityId)),
                        ["passive"] = IsAbilityPassive(abilityId),
                        ["IsCrafted"] = true,
                        ["earnedRank"] = 0,
                        ["cost"] = GetAbilityCost(abilityId),
                        ["costPerTick"] = {GetAbilityCostPerTick(GetCurrentChainedAbility(abilityId)),
                                           GetAbilityFrequencyMS(abilityId)},
                        ["minRange"] = select(1, GetAbilityRange(abilityId)),
                        ["maxRange"] = select(2, GetAbilityRange(abilityId)),
                        ["powerTypes"] = GetPowerTypes(abilityId),
                        ["radius"] = GetAbilityRadius(abilityId),
                        ["distance"] = GetAbilityAngleDistance(abilityId),
                        ["duration"] = GetAbilityDuration(abilityId),
                        ["target"] = GetAbilityTargetDescription(abilityId),
                        ["descHeader"] = GetAbilityDescriptionHeader(abilityId)
                    }

                    -- 新增：尝试为 Scribing 组合的代表 ability 添加样式 collectibleId 列表
                    local progressionId = GetProgressionSkillProgressionId(i, j, k) -- 可能为 0 或 nil
                    subSkill.styleCollectibleIds = GetAllStyleCollectibleIdsForSkill(progressionId)

                    table.insert(skill, subSkill)

                    ResetCraftedAbilityScriptSelectionOverride()
                end
            end
        end
    end

    return skill
end

-- 获取单个技能。
local function AddSkill(i, j, line, k, skillsLimit, linesLimit)
    -- 等待直到准备好调用。
    if DataExtractor.currentSkill ~= k then
        -- 如果已切换到下一类型或技能线，则停止等待。
        if DataExtractor.currentType == i and DataExtractor.currentLine == j then
            zo_callLater(function()
                AddSkill(i, j, line, k, skillsLimit, linesLimit)
            end, 100)
        end
        return
    end

    local skills = line.skills -- Reference
    skills[k] = {}
    local skill = skills[k] -- Reference

    if IsCraftedAbilitySkill(i, j, k) then
        skill.IsCrafted = true
        skill = AddCraftedSkill(i, j, k, skill)
        DataExtractor.dataSkillsCounter = DataExtractor.dataSkillsCounter + 1
        UpdateSkillsPosition(i, j, line, k, skillsLimit, linesLimit)
        return
    else
        skill.IsCrafted = false
    end

    -- 仅基础技能，下方包含被动升级和主动变体。
    local name, icon, earnedRank, passive, ultimate, purchased, progressionIndex, rank = GetSkillAbilityInfo(i, j, k)

    -- 只有有变体的技能才有此字段。
    local pid = GetProgressionSkillProgressionId(i, j, k)

    if pid == 0 then
        -- 无变体，例如被动技能。
        local abilityId = GetSkillAbilityId(i, j, k, false)

        skill.name = zo_strformat(SI_ABILITY_NAME, name)

        skill.id = abilityId
        local aid = skill.id -- Reference.

        skill.description = GetAbilityDescription(aid, MAX_RANKS_PER_ABILITY)

        skill.icon = icon
        skill.passive = passive
        skill.ultimate = ultimate

        -- 属性名保持一致。对于被动技能，此处表示解锁所需的技能等级。
        skill.earnedRank = earnedRank

        -- 添加 GetPowerTypes 方法，由 @Chicor 贡献 ---------
        skill.powerTypes = GetPowerTypes(aid)
        -----------------------------------------
        skill.cost = GetAbilityCost(aid, MAX_RANKS_PER_ABILITY)
        skill.costPerTick = {GetAbilityCostPerTick(GetCurrentChainedAbility(aid)), GetAbilityFrequencyMS(aid)}
        skill.duration = GetAbilityDuration(aid, MAX_RANKS_PER_ABILITY)
        skill.radius = GetAbilityRadius(aid, MAX_RANKS_PER_ABILITY)
        skill.distance = GetAbilityAngleDistance(aid)
        skill.minRange, skill.maxRange = GetAbilityRange(aid, MAX_RANKS_PER_ABILITY)
        skill.isChanneled, skill.castTime = GetAbilityCastInfo(aid, MAX_RANKS_PER_ABILITY)
        skill.isTank, skill.isHealer, skill.isDamage = GetAbilityRoles(aid)
        skill.target = GetAbilityTargetDescription(aid, MAX_RANKS_PER_ABILITY)
        skill.descHeader = GetAbilityDescriptionHeader(aid, MAX_RANKS_PER_ABILITY)

        -- 新增：被动技能一般没有样式，但仍尝试添加（通常为空）
        skill.styleCollectibleIds = GetAllStyleCollectibleIdsForSkill(pid)

        -- 获取被动技能的升级信息。
        if passive then
            local mapped = SKILLS_DATA_MANAGER.abilityIdToProgressionDataMap[aid]
            local skillData = mapped.skillData
            -- 存放所有技能等级。
            local skillProgressions = skillData.skillProgressions

            local upgrades = GetNumPassiveSkillRanks(i, j, k)
            -- 获取所有后续升级。
            for x = 2, upgrades do
                skill[x] = {}
                local s = skill[x] -- Reference.

                s.id = skillProgressions[x].abilityId
                s.name = zo_strformat(SI_ABILITY_NAME, GetAbilityName(s.id))

                s.description = GetAbilityDescription(s.id)

                -- 属性名保持一致。对于被动技能，此处表示解锁所需的技能等级。
                s.earnedRank = skillProgressions[x].lineRankNeededToUnlock

                -- 添加 GetPowerTypes 方法，由 @Chicor 贡献 ---------
                s.powerTypes = GetPowerTypes(aid)
                -----------------------------------------
                s.cost = GetAbilityCost(aid, MAX_RANKS_PER_ABILITY)
                s.costPerTick = {GetAbilityCostPerTick(GetCurrentChainedAbility(aid)), GetAbilityFrequencyMS(aid)}
                s.duration = GetAbilityDuration(aid, MAX_RANKS_PER_ABILITY)
                s.radius = GetAbilityRadius(aid, MAX_RANKS_PER_ABILITY)
                s.distance = GetAbilityAngleDistance(aid)
                s.minRange, s.maxRange = GetAbilityRange(aid, MAX_RANKS_PER_ABILITY)
                s.isChanneled, s.castTime = GetAbilityCastInfo(aid, MAX_RANKS_PER_ABILITY)
                s.isTank, s.isHealer, s.isDamage = GetAbilityRoles(aid)
                s.target = GetAbilityTargetDescription(aid, MAX_RANKS_PER_ABILITY)
                s.descHeader = GetAbilityDescriptionHeader(aid, MAX_RANKS_PER_ABILITY)

                -- 新增：被动升级也尝试添加样式（通常为空）
                s.styleCollectibleIds = GetAllStyleCollectibleIdsForSkill(pid)

                s.parentAbilityId = skill.id
            end
        end
    else
        -- 有变体的技能：极限技能和战斗技能。
        -- 基础技能及两个变体：0、1、2。
        for x = MORPH_SLOT_MIN_VALUE, MORPH_SLOT_MAX_VALUE do
            local s
            if x == MORPH_SLOT_MIN_VALUE then
                -- 基础技能数据保存在 skill 表本身。
                s = skill
            else
                -- 变体数据保存在子表中。
                skill[x] = {}
                s = skill[x]
            end

            s.id = GetProgressionSkillMorphSlotAbilityId(pid, x)
            local aid = s.id -- Reference.

            s.name = zo_strformat(SI_ABILITY_NAME, GetAbilityName(aid))

            s.description = GetAbilityDescription(aid, MAX_RANKS_PER_ABILITY)

            s.icon = GetAbilityIcon(aid)
            s.passive = false
            s.ultimate = ultimate

            s.earnedRank = earnedRank -- 仅适用于基础技能。
            -- 添加 GetPowerTypes 方法，由 @Chicor 贡献 ---------
            s.powerTypes = GetPowerTypes(aid)
            -----------------------------------------
            s.cost = GetAbilityCost(aid, MAX_RANKS_PER_ABILITY)
            s.costPerTick = {GetAbilityCostPerTick(GetCurrentChainedAbility(aid)), GetAbilityFrequencyMS(aid)}
            s.duration = GetAbilityDuration(aid, MAX_RANKS_PER_ABILITY)
            s.radius = GetAbilityRadius(aid, MAX_RANKS_PER_ABILITY)
            s.distance = GetAbilityAngleDistance(aid)
            s.minRange, s.maxRange = GetAbilityRange(aid, MAX_RANKS_PER_ABILITY)
            s.isChanneled, s.castTime = GetAbilityCastInfo(aid, MAX_RANKS_PER_ABILITY)
            s.isTank, s.isHealer, s.isDamage = GetAbilityRoles(aid)
            s.target = GetAbilityTargetDescription(aid, MAX_RANKS_PER_ABILITY)
            s.descHeader = GetAbilityDescriptionHeader(aid, MAX_RANKS_PER_ABILITY)

            -- 新增：为每个 morph 添加样式 collectibleId 列表（大多数情况下基础和 morph 共享同一个 progressionId 的样式）
            s.styleCollectibleIds = GetAllStyleCollectibleIdsForSkill(pid)

            if x > MORPH_SLOT_MIN_VALUE then
                -- 变体专有字段。
                s.parentAbilityId = skill.id
                s.newEffect = GetAbilityNewEffectLines(aid)
            end
        end
    end

    DataExtractor.dataSkillsCounter = DataExtractor.dataSkillsCounter + 1

    UpdateSkillsPosition(i, j, line, k, skillsLimit, linesLimit)
end

-- 获取一条技能线并继续获取其下所有技能。
local function AddLine(data, i, j, linesLimit)
    -- 等待直到准备好调用。
    if DataExtractor.currentLine ~= j then
        -- 如果已切换到下一类型，则停止等待。
        if DataExtractor.currentType == i then
            zo_callLater(function()
                AddLine(data, i, j, linesLimit)
            end, 200)
        end
        return
    end

    local name, rank, unlocked, notid, a, unlock, b, c = GetSkillLineInfo(i, j)

    data[j] = {}
    local line = data[j] -- Reference.

    line.skills = {} -- 存放该技能线下的所有技能。

    line.name = name
    line.id = notid

    DataExtractor.dataSkillLinesCounter = DataExtractor.dataSkillLinesCounter + 1

    -- 获取该技能线下的所有技能。
    local skillsLimit = GetNumSkillAbilities(i, j)
    DataExtractor.currentSkill = 1

    -- 该技能线没有技能。
    if skillsLimit == 0 then
        -- 让迭代结束。
        UpdateSkillsPosition(i, j, line, -1)
        return
    end

    for k = 1, skillsLimit do
        AddSkill(i, j, line, k, skillsLimit, linesLimit)
    end
end

-- 获取某技能类型下的所有技能线，
-- 并继续获取每条技能线的所有技能。
local function AddType(i)
    -- 等待直到准备好调用。
    if DataExtractor.currentType ~= i then
        zo_callLater(function()
            AddType(i)
        end, 500)
        return
    end

    local typeName = GetString("SI_SKILLTYPE", i)

    -- 类型为空，跳过，处理下一个！
    if typeName == '' then
        DataExtractor.currentType = DataExtractor.currentType + 1
        return
    end

    DataExtractor.dataSkills[i] = {}
    local data = DataExtractor.dataSkills[i]

    data.name = typeName

    -- 获取该类型下的所有技能线。
    local linesLimit = GetNumSkillLines(i)
    DataExtractor.currentLine = 1

    -- 该类型没有技能线。
    if linesLimit == 0 then
        -- 结束迭代。
        UpdateSkillsPosition(i, -1, nil, -1)
        return
    end

    for j = 1, linesLimit do
        AddLine(data, i, j, linesLimit)
    end
end

-- 抓取游戏中所有技能数据。
function DataExtractor.GetAllSkills()
    -- 避免重复运行。
    if DataExtractor.scrapingSkills == true then
        d('|cFFFFFFDataExtractor:|r 技能遍历已在进行!')
        return
    end
    -- 追踪状态。
    DataExtractor.scrapingSkills = true

    d('|cFFFFFFDataExtractor:|r 抓取技能数据，请等待...')

    -- 获取所有类型。每个类型获取所有技能线，每条技能线获取所有技能。
    DataExtractor.currentType = SKILL_TYPE_MIN_VALUE
    for i = SKILL_TYPE_MIN_VALUE, SKILL_TYPE_MAX_VALUE do
        AddType(i)
    end
end
