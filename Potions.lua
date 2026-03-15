--[[
    药水数据提取模块 (Potions.lua)

    基于炼金模拟器的静态数据（效果、试剂、溶剂），预计算所有可能的
    药水/毒药组合，生成对应的游戏物品链接，然后通过游戏 API
    读取完整信息（名称、图标、描述等）。只处理可炼金制作的药水。

    核心算法：
    1. 遍历所有 2 试剂和 3 试剂组合
    2. 按照炼金规则计算激活效果（≥2 个试剂共有且未被对立效果抵消）
    3. 对激活效果按 index 排序，最多保留 3 个
    4. 编码 potionData = effect1 * 256² + effect2 * 256 + effect3
    5. 从首个效果获取 potionBaseId / poisonBaseId 作为物品 ID
    6. 结合溶剂的 internalLevel 和 internalType 构造完整物品链接
    7. 使用游戏 API (GetItemLinkOnUseAbilityInfo) 读取药水效果描述

    链接格式：|H1:item:{itemId}:{intType}:{intLevel}:0:...(17个0)...:0:{potionData}|h|h

    优势：无需在背包中持有试剂，无需解锁词条，纯静态数据计算。
]] -- =============================================
-- 数据引用（由 potionData/*.lua 预加载）
-- =============================================
local PotionEffects -- DataExtractor.PotionEffects
local ReagentList -- DataExtractor.ReagentList
local SolventList -- DataExtractor.SolventList

-- =============================================
-- 炼金计算核心函数
-- =============================================

--- 合并多个试剂的效果
--- 规则：效果必须在至少 2 个试剂中出现才能激活；对立效果相互抵消
--- @param effects1 table 试剂1的效果ID列表
--- @param effects2 table 试剂2的效果ID列表
--- @param effects3 table 试剂3的效果ID列表（可为空表）
--- @return table 激活的效果ID列表（按 index 排序，最多3个）
local function CombineReagentEffects(effects1, effects2, effects3)
    local effectCounts = {}

    -- 统计每个效果在多少个试剂中出现
    local function countEffects(effects)
        for _, effectId in ipairs(effects) do
            if effectId and effectId > 0 then
                effectCounts[effectId] = (effectCounts[effectId] or 0) + 1
            end
        end
    end
    countEffects(effects1)
    countEffects(effects2)
    countEffects(effects3)

    local combinedEffects = {}

    -- 检查每个效果是否激活
    for effectId, count in pairs(effectCounts) do
        local effectData = PotionEffects[effectId]
        if effectData then
            local finalCount = count
            -- 对立效果抵消
            if effectData.oppositeId > 0 and effectCounts[effectData.oppositeId] then
                finalCount = finalCount - effectCounts[effectData.oppositeId]
            end
            -- 至少 2 个试剂共有才能激活
            if finalCount >= 2 then
                table.insert(combinedEffects, effectId)
            end
        end
    end

    -- 按照 index 字段排序
    table.sort(combinedEffects, function(a, b)
        local effA = PotionEffects[a]
        local effB = PotionEffects[b]
        if not effA or not effB then
            return false
        end
        return effA.index < effB.index
    end)

    -- 最多保留 3 个效果
    while #combinedEffects > 3 do
        table.remove(combinedEffects)
    end

    return combinedEffects
end

--- 编码药水数据
--- potionData = effect1 * 256² + effect2 * 256 + effect3
--- @param effectIds table 效果ID列表（已排序）
--- @return number 编码后的 potionData
local function EncodePotionData(effectIds)
    local potionData = 0
    for i = 1, math.min(#effectIds, 3) do
        potionData = potionData * 256 + effectIds[i]
    end
    return potionData
end

--- 构造药水物品链接
--- 链接格式: |H1:item:{itemId}:{intType}:{intLevel}:0:0:...:0:{potionData}|h|h
--- @param itemId number 物品ID
--- @param internalType number 溶剂内部类型
--- @param internalLevel number 溶剂内部等级
--- @param potionData number 编码后的药水数据
--- @return string 游戏物品链接
local function BuildPotionLink(itemId, internalType, internalLevel, potionData)
    return string.format("|H1:item:%d:%d:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:%d|h|h", itemId, internalType,
        internalLevel, potionData)
end

-- =============================================
-- 数据提取函数
-- =============================================

--- 从物品链接提取药水信息
--- @param link string 物品链接
--- @return table|nil 药水信息，如果链接无效则返回 nil
local function ExtractPotionInfo(link)
    local name = GetItemLinkName(link)
    if not name or name == "" then
        return nil
    end

    name = zo_strformat(SI_TOOLTIP_ITEM_NAME, name)
    local icon = GetItemLinkIcon(link)
    local quality = GetString("SI_ITEMQUALITY", GetItemLinkQuality(link))
    local itemType = GetItemLinkItemType(link)
    local itemTypeText = GetString("SI_ITEMTYPE", itemType)

    -- 通过 API 获取药水使用效果描述
    -- GetItemLinkOnUseAbilityInfo 用于消耗品（药水/毒药）的使用效果
    -- GetItemLinkTraitOnUseAbilityInfo 是装备词条效果，不适用于药水
    local description = ""
    local traitAbilityCount = 0
    local cooldown = 0
    for i = 1, GetMaxTraits() do
        local hasTraitAbility, traitAbilityDescription, traitCooldown = GetItemLinkTraitOnUseAbilityInfo(link, i)

        if (hasTraitAbility) then
            traitAbilityCount = traitAbilityCount + 1
            if traitAbilityDescription and traitAbilityDescription ~= "" then
                description = description .. zo_strformat(SI_TOOLTIP_ITEM_NAME, traitAbilityDescription) .. "\n"
            end
        end
        cooldown = traitCooldown or 0
    end

    return {
        name = name,
        icon = icon,
        quality = quality,
        itemTypeText = itemTypeText,
        description = description,
        cooldown = cooldown
    }
end

-- =============================================
-- 主函数
-- =============================================

--- 提取所有药水/毒药数据
function DataExtractor.GetAllPotions()
    -- 加载静态数据引用
    PotionEffects = DataExtractor.PotionEffects
    ReagentList = DataExtractor.ReagentList
    SolventList = DataExtractor.SolventList

    if not PotionEffects or not ReagentList or not SolventList then
        d("|cFFFFFFDataExtractor:|r |cFF0000错误: 药水静态数据未加载! 请检查 potionData 文件夹。|r")
        return
    end

    d("|cFFFFFFDataExtractor:|r 开始提取药水数据...")

    local numReagents = #ReagentList

    -- =========================================
    -- 阶段 1: 枚举所有试剂组合，计算效果
    -- =========================================
    -- effectCombinations[potionData] = { effects = {}, recipes = {} }
    local effectCombinations = {}
    local totalCombos = 0

    for i = 1, numReagents do
        for j = i + 1, numReagents do
            -- 2 试剂组合
            local effects2 = CombineReagentEffects(ReagentList[i].effects, ReagentList[j].effects, {})
            if #effects2 > 0 then
                local pd = EncodePotionData(effects2)
                if not effectCombinations[pd] then
                    effectCombinations[pd] = {
                        effects = effects2,
                        recipes = {}
                    }
                end
                table.insert(effectCombinations[pd].recipes, {ReagentList[i].name, ReagentList[j].name})
                totalCombos = totalCombos + 1
            end

            -- 3 试剂组合
            for k = j + 1, numReagents do
                local effects3 = CombineReagentEffects(ReagentList[i].effects, ReagentList[j].effects,
                    ReagentList[k].effects)
                if #effects3 > 0 then
                    local pd = EncodePotionData(effects3)
                    if not effectCombinations[pd] then
                        effectCombinations[pd] = {
                            effects = effects3,
                            recipes = {}
                        }
                    end
                    table.insert(effectCombinations[pd].recipes,
                        {ReagentList[i].name, ReagentList[j].name, ReagentList[k].name})
                    totalCombos = totalCombos + 1
                end
            end
        end
    end

    d(string.format("|cFFFFFFDataExtractor:|r 效果组合枚举完毕: %d 个组合 -> %d 种独立效果组",
        totalCombos, (function()
            local count = 0
            for _ in pairs(effectCombinations) do
                count = count + 1
            end
            return count
        end)()))

    -- =========================================
    -- 阶段 2: 生成链接并读取 Tooltip
    -- =========================================
    local result = {}
    local potionCount = 0
    local poisonCount = 0

    for pd, combo in pairs(effectCombinations) do
        local firstEffect = PotionEffects[combo.effects[1]]
        if firstEffect then
            -- 药水：遍历所有药水溶剂（不同等级/类型）
            local potionItemId = firstEffect.potionBaseId
            if potionItemId and potionItemId > 0 then
                for si = 1, #SolventList do
                    local solvent = SolventList[si]
                    if not solvent.isPoison then
                        local link = BuildPotionLink(potionItemId, solvent.internalType, solvent.internalLevel, pd)
                        local info = ExtractPotionInfo(link)
                        if info then
                            result[potionItemId] = result[potionItemId] or {}
                            table.insert(result[potionItemId], {
                                id = potionItemId,
                                potionData = pd,
                                internalType = solvent.internalType,
                                internalLevel = solvent.internalLevel,
                                effectIds = combo.effects,
                                isPoison = false,
                                name = info.name,
                                quality = info.quality,
                                icon = info.icon,
                                itemTypeText = info.itemTypeText,
                                description = info.description,
                                canBeCrafted = true
                            })
                            potionCount = potionCount + 1
                        end
                    end
                end
            end

            -- 毒药：遍历所有毒药溶剂（不同等级/类型）
            local poisonItemId = firstEffect.poisonBaseId
            if poisonItemId and poisonItemId > 0 then
                for si = 1, #SolventList do
                    local solvent = SolventList[si]
                    if solvent.isPoison then
                        local link = BuildPotionLink(poisonItemId, solvent.internalType, solvent.internalLevel, pd)
                        local info = ExtractPotionInfo(link)
                        if info then
                            result[poisonItemId] = result[poisonItemId] or {}
                            table.insert(result[poisonItemId], {
                                id = poisonItemId,
                                potionData = pd,
                                internalType = solvent.internalType,
                                internalLevel = solvent.internalLevel,
                                effectIds = combo.effects,
                                isPoison = true,
                                name = info.name,
                                quality = info.quality,
                                icon = info.icon,
                                itemTypeText = info.itemTypeText,
                                description = info.description,
                                canBeCrafted = true
                            })
                            poisonCount = poisonCount + 1
                        end
                    end
                end
            end
        end -- if firstEffect
    end

    DataExtractor.dataPotions = result
    d(string.format("|cFFFFFFDataExtractor:|r 完工! 药水: %d 种, 毒药: %d 种 (使用 %s 保存数据!)",
        potionCount, poisonCount, DataExtractor.slashSave))
end
