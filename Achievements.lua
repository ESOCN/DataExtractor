-- 返回去除所有0值后的成就ID表。
local function CleanupAchievs(ids)
    local t = {}
    for i = 1, #ids do
        if ids[i] ~= 0 then
            table.insert(t, ids[i])
        end
    end
    return t
end

-- 获取成就的奖励内容并添加到其数据表中。
local function AddAchievRewards(id, t)
    -- 获取物品奖励
    local hasRewardItem, itemName, iconTextureName, quality = GetAchievementRewardItem(id)
    if hasRewardItem then
        t.item = {}
        local item = t.item

        item.name = itemName
        item.icon = iconTextureName
        item.quality = quality
    end

    -- 获取头衔奖励
    local hasRewardTitle, titleName = GetAchievementRewardTitle(id)
    if hasRewardTitle then
        t.title = {}
        local title = t.title

        title.name = titleName
    end

    -- 获取染料奖励
    local hasRewardDye, dyeId = GetAchievementRewardDye(id)
    if hasRewardDye then
        t.dye = {}
        local dye = t.dye

        dye.id = dyeId

        local dyeName, known, rarity, hueCategory, achievementId, r, g, b, sortKey = GetDyeInfoById(dyeId)

        dye.name = dyeName
        dye.rarity = rarity
        -- dye.hue = hueCategory
        dye.r = r
        dye.g = g
        dye.b = b
        -- dye.sortKey = sortKey
    end

    -- 获取收藏品奖励
    local hasRewardCollectible, collectibleId = GetAchievementRewardCollectible(id)
    if hasRewardCollectible then
        t.collectible = {}
        local collectible = t.collectible

        collectible.id = collectibleId

        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)

        collectible.name = collectibleData:GetFormattedName()
        collectible.prefix = zo_strformat(SI_ACHIEVEMENTS_COLLECTIBLE_CATEGORY, collectibleData:GetCategoryTypeDisplayName())
    end
end

-- 将成就添加到数据库。
local function AddAchievs(i, j, subCategoryName)
    -- ZO_GetAchievementIds(categoryIndex, subcategoryIndex, numAchievements, considerSearchResults)
    local idsRaw = ZO_GetAchievementIds(i, j, 100, false)

    local ids = CleanupAchievs(idsRaw)

    -- 子类别中没有成就，跳过。注意：一般子类别的检查会触发此处。
    if #ids == 0 then return end

    DataExtractor.dataAchievsSubcatCounter = DataExtractor.dataAchievsSubcatCounter + 1

    -- d(ids)
    -- d(#ids .. ' ' .. subCategoryName)

    -- 将"一般"子类别视为ID 0。
    if j == nil then j = 0 end

    local data = DataExtractor.dataAchievs

    data[i][j] = {} -- 子类别。
    local subcat = data[i][j]

    subcat.name = subCategoryName

    for k = 1, #ids do
        local id = ids[k]

        -- 如果该成就有连锁，则找到最后一个来代表数据库中的该成就。
        local nextId = GetFirstAchievementInLine(id)

        local counter = 100 -- 调试用：防止代码错误导致死循环的安全措施。
        local lastId = id
        while nextId ~= 0 and counter > 0 do
            -- 找到最后一个ID，用于在数据库中代表该成就。
            lastId = nextId

            nextId = GetNextAchievementInLine(nextId)

            -- 调试用。
            counter = counter - 1
            if counter <= 0 then d('DataExtractor: Bug! Overload in AddAchievs() 1st.') end
        end

        -- 用连锁中的最后一个成就ID覆盖当前ID。
        id = lastId

        local achievementName, description, points, icon, completed, date, time = GetAchievementInfo(id)

        subcat[id] = {}
        local achiev = subcat[id]

        achiev.category = data[i].name
        achiev.subcategory = subcat.name

        achiev.name = achievementName
        achiev.description = description
        achiev.points = points
        achiev.icon = icon

        local hasReward = GetAchievementNumRewards(id) > 1

        if hasReward then
            achiev.rewards = {}
            AddAchievRewards(id, achiev.rewards)
        end

        -- 完成成就所需的目标条件。
        local numCriterion = GetAchievementNumCriteria(id)

        if numCriterion > 1 then
            achiev.criterion = {}
            for m = 1, numCriterion do
                local description, numCompleted, numRequired = GetAchievementCriterion(id, m)
                achiev.criterion[m] = description
            end
        end

        -- 完成最终成就任务所需的前置成就。
        local nextId = GetFirstAchievementInLine(id)

        if nextId ~= 0 then
            achiev.line = {}
        end

        local counter = 100 -- 调试用：防止代码错误导致死循环的安全措施。
        while nextId ~= 0 and counter > 0 do
            local curId = nextId

            nextId = GetNextAchievementInLine(nextId)

            -- 连锁中最后一个是主条目，此处不重复添加。
            if nextId ~= 0 then
                achiev.line[curId] = {}
                local ach = achiev.line[curId]

                local achievementName, description, points, icon, completed, date, time = GetAchievementInfo(curId)

                ach.name = achievementName
                ach.description = description
                ach.points = points
                ach.icon = icon

                ach.category = data[i].name
                ach.subcategory = subcat.name

                local hasReward = GetAchievementNumRewards(curId) > 1

                if hasReward then
                    ach.rewards = {}
                    AddAchievRewards(curId, ach.rewards)
                end
            end

            -- 调试用。
            counter = counter - 1
            if counter <= 0 then d('DataExtractor: Bug! Overload in AddAchievs() 2nd.') end
        end

        -- 只统计连锁中最后一个成就。
        DataExtractor.dataAchievsCounter = DataExtractor.dataAchievsCounter + 1
    end
end

-- 抓取游戏中所有成就数据。
function DataExtractor.GetAllAchievs()
    -- 避免重复运行。
    if DataExtractor.scrapingAchievs == true then
        d('|cFFFFFFDataExtractor:|r 成就遍历已在进行!')
        return
    end
    -- 追踪状态。
    DataExtractor.scrapingAchievs = true

    d(string.format('|cFFFFFFDataExtractor:|r 抓取成就数据中，请等待...'))

    -- 遍历所有大类。
    for i = 1, 100 do
        local categoryName, numSubCategories, numAchievements, earnedPoints, totalPoints, hidesPoints = GetAchievementCategoryInfo(i)
        local categoryIcon, categoryIconSelected, categoryIconHover = GetAchievementCategoryKeyboardIcons(i)
        if categoryName ~= '' then
            local data = DataExtractor.dataAchievs
            data[i] = {}
            local category = data[i]

            category.name = categoryName
            category.totalpoints = totalPoints
            category.icon = categoryIcon
            category.iconSelected = categoryIconSelected
            category.iconHover = categoryIconHover
            -- 注意：不要使用 numSubCategories 和 numAchievements！请改用计数器。

            DataExtractor.dataAchievsCatCounter = DataExtractor.dataAchievsCatCounter + 1

            -- 遍历所有子类别。
            for j = 1, 100 do
                -- 在第一次迭代时添加"一般"子类别。
                -- 其 ID 为 nil —— 官方定义中它是一个"虚拟"子类别。
                if j == 1 then
                    local subCategoryName = "General"

                    AddAchievs(i, nil, subCategoryName)
                end

                local subCategoryName, subNumAchievements = GetAchievementSubCategoryInfo(i, j)

                if subCategoryName ~= '' then
                    AddAchievs(i, j, subCategoryName)

                    DataExtractor.dataAchievsSubcatCounter = DataExtractor.dataAchievsSubcatCounter + 1
                end
            end
        end
    end

    d(
        string.format(
            '|cFFFFFFDataExtractor:|r 完工! 总成就: %s 大类: %s 小类: %s. (使用 %s 指令来保存数据!)',
            DataExtractor.dataAchievsCounter, DataExtractor.dataAchievsCatCounter, DataExtractor.dataAchievsSubcatCounter,
            DataExtractor.slashSave
        )
    )
    -- 更新追踪状态。
    DataExtractor.scrapingAchievs = false
end