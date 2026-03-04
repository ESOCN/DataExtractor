--[[
    提取时装幻化外观样式（Outfit Style）数据。
    
    时装幻化样式属于收藏品体系（CollectibleCategoryType = OUTFIT_STYLE）。
    每个外观样式对应一个 collectibleId，可被装备到人物时装的各个槽位（头、肩、胸…武器等）。

    数据结构（存储于 DataExtractor.dataOutfitStyles）：
    [*integer* collectibleId] = {
        ["id"]           = *integer* collectibleId,
        ["name"]         = *string*  外观样式名称,
        ["description"]  = *string*  描述文本（可能为空，不包含时省略），
        ["hint"]         = *string*  获取途径提示（可能为空，不包含时省略），
        ["icon"]         = *textureName* 图标路径,
        ["unlocked"]     = *bool*    当前角色/账号是否已解锁,
        ["categoryName"] = *string*  顶级分类名（如 "盔甲外观" / "武器外观"）,
        ["slotId"]       = *integer* OUTFIT_SLOT_* 枚举值（时装槽位ID，可能为 nil）,
        ["slot"]         = *string*  时装槽位本地化名称（可能为 nil）,
    }

    使用 GetCollectibleIdFromType 遍历所有 OUTFIT_STYLE 类型收藏品，
    分批使用 zo_callLater 异步处理，避免游戏卡顿。
]]

-- 提取游戏内所有时装幻化外观样式数据。
function DataExtractor.GetAllOutfitStyles()
    -- 避免重复运行。
    if DataExtractor.scrapingOutfitStyles == true then
        d('|cFFFFFFDataExtractor:|r 时装幻化遍历已在进行!')
        return
    end
    DataExtractor.scrapingOutfitStyles = true

    d('|cFFFFFFDataExtractor:|r 正在收集时装幻化ID列表...')

    -- 第一步：同步收集所有 OUTFIT_STYLE 类型的收藏品 ID 列表。
    -- GetCollectibleIdFromType 返回 0 表示该索引处无数据，即终止。
    local ids = {}
    for i = 1, 100000 do
        local collectibleId = GetCollectibleIdFromType(COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE, i)
        if not collectibleId or collectibleId == 0 then
            break
        end
        table.insert(ids, collectibleId)
    end

    local total = #ids
    if total == 0 then
        d('|cFFFFFFDataExtractor:|r 未找到任何时装幻化数据。')
        DataExtractor.scrapingOutfitStyles = false
        return
    end

    -- 每批处理数量与延迟（毫秒）。
    local chunk = 200
    local chunks = math.ceil(total / chunk)
    local delay = 20

    d(string.format('|cFFFFFFDataExtractor:|r 抓取 %s 个时装幻化外观，请等待约 %s 秒...',
        total, math.floor((chunks * delay) / 1000)))

    -- 重置数据表与计数器。
    DataExtractor.dataOutfitStyles = {}
    DataExtractor.dataOutfitStylesCounter = 0

    -- 第二步：分批异步处理每个收藏品，填充数据表。
    for t = 1, chunks do
        zo_callLater(function()
            local startIdx = 1 + chunk * (t - 1)
            local endIdx   = math.min(chunk * t, total)

            for i = startIdx, endIdx do
                local collectibleId = ids[i]

                -- 返回值: name, description, icon, notificationIcon,
                --         isUnlocked, isActive, isBrokenContent, categoryType, hint
                local name, description, icon, _, unlocked, _, _, _, hint =
                    GetCollectibleInfo(collectibleId)

                -- 跳过无名称的条目。
                if name and name ~= '' then
                    local style = {}

                    style.id   = collectibleId
                    style.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, name)
                    style.icon = icon
                    style.unlocked = unlocked

                    -- 可选字段：描述、获取提示（空字符串则不写入）。
                    if description and description ~= '' then
                        style.description = description
                    end
                    if hint and hint ~= '' then
                        style.hint = hint
                    end

                    -- 顶级分类名称（如"盔甲样式"、"武器样式"等）。
                    style.categoryName = GetCollectibleCategoryNameByCollectibleId(collectibleId)

                    -- 该外观适用的时装槽位（头部/肩部/胸部…主手武器/…服装等）。
                    -- 返回 OUTFIT_SLOT_* 枚举整数，0 表示无对应槽位。
                    local slot = GetEligibleOutfitSlotsForCollectible(collectibleId)
                    if slot and slot ~= 0 then
                        style.slotId = slot
                        -- SI_OUTFITSLOT{N} 为对应槽位的本地化字符串。
                        style.slot = GetString("SI_OUTFITSLOT", slot)
                    end

                    DataExtractor.dataOutfitStyles[collectibleId] = style
                    DataExtractor.dataOutfitStylesCounter = DataExtractor.dataOutfitStylesCounter + 1
                end
            end

            -- 最后一批：打印汇总并重置状态。
            if t == chunks then
                d(string.format(
                    '|cFFFFFFDataExtractor:|r 完工! 总时装幻化外观: %s. (使用 %s 指令来保存数据!)',
                    DataExtractor.dataOutfitStylesCounter, DataExtractor.slashSave
                ))
                DataExtractor.scrapingOutfitStyles = false
            end
        end, delay * t)
    end
end
