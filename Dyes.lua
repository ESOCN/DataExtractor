-- 抓取游戏中所有染料数据。
-- 通过 GetNumDyes() + GetDyeInfo(dyeIndex) 遍历。
function DataExtractor.GetAllDyes()
    -- 避免重复运行。
    if DataExtractor.scrapingDyes == true then
        d('|cFFFFFFDataExtractor:|r 染料遍历已在进行!')
        return
    end
    DataExtractor.scrapingDyes = true

    local data = DataExtractor.dataDyes
    local numDyes = GetNumDyes()

    for dyeIndex = 1, numDyes do
        local dyeName, known, rarity, hueCategory, achievementId, r, g, b, sortKey, dyeId = GetDyeInfo(dyeIndex)

        if dyeName and dyeName ~= '' and dyeId and dyeId > 0 then
            data[dyeId] = {}
            local item = data[dyeId]

            item.id = dyeId
            item.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, dyeName)
            item.known = known

            -- 稀有度：Common(0) / Uncommon(1) / Rare(2) / Material(3)
            item.rarity = rarity
            item.rarityName = GetString('SI_DYERARITY', rarity)

            -- 色调分类：Red(0) / Yellow(1) / Green(2) / Blue(3) / Purple(4) / Brown(5) / Grey(6) / Mixed(7) / Iridescent(8)
            item.hueCategory = hueCategory
            item.hueCategoryName = GetString('SI_DYEHUECATEGORY', hueCategory)

            -- RGB 颜色值（0~1 浮点数）。
            item.r = r
            item.g = g
            item.b = b

            item.sortKey = sortKey

            -- 关联成就 ID（解锁该染料所需的成就；0 表示无）。
            if achievementId and achievementId > 0 then
                item.achievementId = achievementId
                item.achievementName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetAchievementInfo(achievementId))
            end

            DataExtractor.dataDyesCounter = DataExtractor.dataDyesCounter + 1
        end
    end

    d(string.format('|cFFFFFFDataExtractor:|r 完工! 染料: %s. (使用 %s 指令来保存数据!)',
        DataExtractor.dataDyesCounter, DataExtractor.slashSave))
    DataExtractor.scrapingDyes = false
end
