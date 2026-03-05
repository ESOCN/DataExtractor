-- 处理单个收藏品，写入 dataCollectibles。
-- collectibleId  - (int) 收藏品ID。
-- categoryName   - (string) 顶级分类名。
-- subCategoryName - (string|nil) 子分类名，顶级直属收藏品为 nil。
-- categoryIcon   - (string) 顶级分类图标。
-- categoryIconSelected - (string) 顶级分类选中图标。
-- categoryIconHover - (string) 顶级分类悬停图标。
local function AddCollectible(collectibleId, categoryName, subCategoryName, categoryIcon, categoryIconSelected, categoryIconHover)
    local collectibleName = GetCollectibleName(collectibleId)
    if collectibleName == '' then
        return
    end

    local data = DataExtractor.dataCollectibles

    data[collectibleId] = {}
    local item = data[collectibleId]

    item.id = collectibleId
    item.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, collectibleName)
    item.description = GetCollectibleDescription(collectibleId)
    item.hint = GetCollectibleHint(collectibleId)
    item.category = categoryName
    item.subcategory = subCategoryName
    item.categoryType = GetCollectibleCategoryType(collectibleId)
    item.furnitureId = GetCollectibleFurnitureDataId(collectibleId)
    item.sortOrder = GetCollectibleSortOrder(collectibleId)
    item.icon = GetCollectibleIcon(collectibleId)
    item.cooldown, item.duration = GetCollectibleCooldownAndDuration(collectibleId)
    item.linkedAchievement = GetCollectibleLinkedAchievement(collectibleId)
    item.achievementName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetAchievementInfo(item.linkedAchievement))
    item.link = GetCollectibleLink(collectibleId, LINK_STYLE_DEFAULT)
    item.categoryIcon = categoryIcon
    item.categoryIconSelected = categoryIconSelected
    item.categoryIconHover = categoryIconHover

    local numTags = GetNumCollectibleTags(collectibleId)
    if numTags > 0 then
        item.tags = {}
        for tagIndex = 1, numTags do
            local tagName, tagCategory = GetCollectibleTagInfo(collectibleId, tagIndex)
            if tagName ~= '' then
                table.insert(item.tags, tagName)
            end
        end
    end

    DataExtractor.dataCollectiblesCounter = DataExtractor.dataCollectiblesCounter + 1
end

-- 处理某个分类（或子分类）下的所有收藏品。
local function ProcessCollectibles(topLevelIndex, subCategoryIndex, categoryName, subCategoryName)
    local numCollectibles = GetNumCollectiblesInCollectibleCategory(topLevelIndex, subCategoryIndex)
    local categoryIcon, categoryIconSelected, categoryIconHover, _ = GetCollectibleCategoryKeyboardIcons(topLevelIndex)
    for collectibleIndex = 1, numCollectibles do
        local collectibleId = GetCollectibleId(topLevelIndex, subCategoryIndex, collectibleIndex)
        if collectibleId and collectibleId > 0 then
            AddCollectible(collectibleId, categoryName, subCategoryName, categoryIcon, categoryIconSelected, categoryIconHover)
        end
    end
end

-- 抓取游戏中所有收藏品数据（按分类遍历）。
function DataExtractor.GetAllCollectibles()
    -- 避免重复运行。
    if DataExtractor.scrapingCollectibles == true then
        d('|cFFFFFFDataExtractor:|r 收藏品遍历已在进行!')
        return
    end
    DataExtractor.scrapingCollectibles = true

    -- 收集所有待处理的 (topLevelIndex, subCategoryIndex, categoryName, subCategoryName) 任务。
    local tasks = {}
    local numCategories = GetNumCollectibleCategories()

    for topLevelIndex = 1, numCategories do
        local categoryName, numSubCategories, numCollectibles = GetCollectibleCategoryInfo(topLevelIndex)

        -- 顶级分类直属的收藏品。
        if numCollectibles > 0 then
            table.insert(tasks, {topLevelIndex, nil, categoryName, nil})
        end

        -- 子分类下的收藏品。
        for subCategoryIndex = 1, numSubCategories do
            local subCategoryName = GetCollectibleSubCategoryInfo(topLevelIndex, subCategoryIndex)
            table.insert(tasks, {topLevelIndex, subCategoryIndex, categoryName, subCategoryName})
        end
    end

    -- 分批异步处理以避免卡顿。
    local chunk = 5 -- 每批处理的分类数。
    local totalTasks = #tasks
    local chunks = math.ceil(totalTasks / chunk)
    local delay = 20 -- 每批之间的毫秒延迟。

    for t = 1, chunks do
        zo_callLater(function()
            local startIdx = 1 + chunk * (t - 1)
            local endIdx = math.min(chunk * t, totalTasks)

            for i = startIdx, endIdx do
                local task = tasks[i]
                ProcessCollectibles(task[1], task[2], task[3], task[4])
            end

            -- 最后一批完成时打印汇总。
            if t == chunks then
                d(string.format(
                    '|cFFFFFFDataExtractor:|r 完工! 分类: %s 收藏品: %s. (使用 %s 指令来保存数据!)',
                    totalTasks, DataExtractor.dataCollectiblesCounter, DataExtractor.slashSave))
                DataExtractor.scrapingCollectibles = false
            end
        end, delay * t)
    end

    d(string.format('|cFFFFFFDataExtractor:|r 抓取收藏品数据中, 共 %s 个分类, 请稍候...', totalTasks))
end
