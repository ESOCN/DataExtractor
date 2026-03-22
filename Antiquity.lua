-- 解析奖励ID，提取奖励类型及对应的收藏品/物品信息。
local function ResolveReward(rewardId)
    if not rewardId or rewardId == 0 then return nil end
    local info = {}
    info.rewardId = rewardId
    local rewardType = GetRewardType(rewardId)
    info.rewardEntryType = rewardType

    if rewardType == REWARD_ENTRY_TYPE_COLLECTIBLE then
        -- 收藏品类奖励（家具、坐骑、宠物、音乐盒等）。
        local collectibleId = GetCollectibleRewardCollectibleId(rewardId)
        if collectibleId and collectibleId > 0 then
            info.collectibleId = collectibleId
            info.collectibleName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetCollectibleName(collectibleId))
            info.collectibleCategoryType = GetCollectibleCategoryType(collectibleId)
        end
    elseif rewardType == REWARD_ENTRY_TYPE_ITEM then
        -- 物品类奖励（装备套装等）。
        local itemId = GetItemRewardItemId(rewardId)
        if itemId and itemId > 0 then
            info.itemId = itemId
        end
        local itemLink = GetItemRewardItemLink(rewardId, 1, REWARD_DISPLAY_FLAGS_NONE, LINK_STYLE_DEFAULT)
        if itemLink and itemLink ~= '' then
            info.itemLink = itemLink
            info.itemTypeId, info.itemSpecializedTypeId = GetItemLinkItemType(itemLink)
            info.itemTypeName = GetString("SI_ITEMTYPE", info.itemTypeId)
            info.itemSpecializedTypeName = GetString("SI_SPECIALIZEDITEMTYPE", info.itemSpecializedTypeId)
        end
    end

    return info
end

-- 处理单个古物线索，写入 dataAntiquities。
-- antiquityId - (int) 古物线索ID。
local function AddAntiquity(antiquityId)
    local name = GetAntiquityName(antiquityId)
    if not name or name == '' then
        return
    end

    local data = DataExtractor.dataAntiquities

    data[antiquityId] = {}
    local item = data[antiquityId]

    item.id = antiquityId
    item.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, name)
    item.icon = GetAntiquityIcon(antiquityId)
    item.quality = GetAntiquityQuality(antiquityId)
    item.difficulty = GetAntiquityDifficulty(antiquityId)
    item.repeatable = IsAntiquityRepeatable(antiquityId)
    item.requiresLead = DoesAntiquityRequireLead(antiquityId)
    item.needsCombination = DoesAntiquityNeedCombination(antiquityId)

    -- 地区信息。
    local zoneId = GetAntiquityZoneId(antiquityId)
    item.zoneId = zoneId
    if zoneId and zoneId > 0 then
        item.zoneName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetZoneNameById(zoneId))
    end

    -- 分类信息。
    local categoryId = GetAntiquityCategoryId(antiquityId)
    item.categoryId = categoryId
    if categoryId and categoryId > 0 then
        item.categoryName = GetAntiquityCategoryName(categoryId)
        local parentId = GetAntiquityCategoryParentId(categoryId)
        if parentId and parentId > 0 then
            item.parentCategoryId = parentId
            item.parentCategoryName = GetAntiquityCategoryName(parentId)
        end
        local icon, iconSelected, iconHover = GetAntiquityCategoryKeyboardIcons(categoryId)
        item.categoryIcon = icon
        item.categoryIconSelected = iconSelected
        item.categoryIconHover = iconHover
    end

    -- 套装信息。
    local setId = GetAntiquitySetId(antiquityId)
    if setId and setId > 0 then
        item.setId = setId
        item.setName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetAntiquitySetName(setId))
        item.setIcon = GetAntiquitySetIcon(setId)
        item.setQuality = GetAntiquitySetQuality(setId)
        local numSetPieces = GetNumAntiquitySetAntiquities(setId)
        item.setNumAntiquities = numSetPieces
        -- 套装奖励类型解析。
        local setRewardId = GetAntiquitySetRewardId(setId)
        if setRewardId and setRewardId > 0 then
            item.setReward = ResolveReward(setRewardId)
        end
    end

    -- 单件奖励类型解析。
    local rewardId = GetAntiquityRewardId(antiquityId)
    if rewardId and rewardId > 0 then
        item.reward = ResolveReward(rewardId)
    end

    -- 知识条目（Lore）。
    local numLoreEntries = GetNumAntiquityLoreEntries(antiquityId)
    if numLoreEntries and numLoreEntries > 0 then
        item.numLoreEntries = numLoreEntries
        item.loreEntries = {}
        for loreIndex = 1, numLoreEntries do
            local loreName, loreDescription = GetAntiquityLoreEntry(antiquityId, loreIndex)
            table.insert(item.loreEntries, {
                name = loreName or '',
                description = loreDescription or '',
            })
        end
    end

    -- 目标与恢复进度。
    item.totalGoals = GetTotalNumGoalsForAntiquity(antiquityId)
    item.numRecovered = GetNumAntiquitiesRecovered(antiquityId)

    -- 掉落信息（来自 locationsdata_zh.lua 的 RDL.Locations 表）。
    if RDL and RDL.Locations and RDL.Locations[antiquityId] then
        local loc = RDL.Locations[antiquityId]
        -- loc 格式: {longDesc, type, shortDesc, "TRUE"/"FALSE"}
        item.dropHint = loc[1] or ''
        item.dropType = loc[2] or ''
        item.dropShort = loc[3] or ''
    end

    DataExtractor.dataAntiquitiesCounter = DataExtractor.dataAntiquitiesCounter + 1
end

-- 抓取游戏中所有古物线索数据（使用 GetNextAntiquityId 遍历）。
function DataExtractor.GetAllAntiquities()
    -- 避免重复运行。
    if DataExtractor.scrapingAntiquities == true then
        d('|cFFFFFFDataExtractor:|r 古物线索遍历已在进行!')
        return
    end
    DataExtractor.scrapingAntiquities = true

    -- 收集所有古物线索ID。
    local antiquityIds = {}
    local currentId = GetNextAntiquityId(nil)
    while currentId ~= nil do
        table.insert(antiquityIds, currentId)
        currentId = GetNextAntiquityId(currentId)
    end

    -- 分批异步处理以避免卡顿。
    local chunk = 50 -- 每批处理的古物线索数。
    local totalItems = #antiquityIds
    local chunks = math.ceil(totalItems / chunk)
    local delay = 20 -- 每批之间的毫秒延迟。

    for t = 1, chunks do
        zo_callLater(function()
            local startIdx = 1 + chunk * (t - 1)
            local endIdx = math.min(chunk * t, totalItems)

            for i = startIdx, endIdx do
                AddAntiquity(antiquityIds[i])
            end

            -- 最后一批完成时打印汇总。
            if t == chunks then
                d(string.format(
                    '|cFFFFFFDataExtractor:|r 完工! 古物线索: %s. (使用 %s 指令来保存数据!)',
                    DataExtractor.dataAntiquitiesCounter, DataExtractor.slashSave))
                DataExtractor.scrapingAntiquities = false
            end
        end, delay * t)
    end

    d(string.format('|cFFFFFFDataExtractor:|r 抓取古物线索数据中, 共 %s 条, 请稍候...', totalItems))
end
