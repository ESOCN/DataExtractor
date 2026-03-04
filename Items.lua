-- 根据给定的物品ID向数据库添加物品（适用于链接对象）。
-- i - (int) 物品ID。
-- 成功时返回 true。
--[[
* GetAntiquitySetRewardId(*integer* _antiquitySetId_)
** _Returns:_ *integer* _rewardId_

* GetItemRewardItemId(*integer* _rewardId_)
** _Returns:_ *integer* _itemId_

* GetAntiquitySetAntiquityId(*integer* _antiquitySetId_, *luaindex* _antiquityIndex_)
** _Returns:_ *integer* _antiquityId_

* GetAntiquityCategoryId(*integer* _antiquityId_)
** _Returns:_ *integer* _categoryId_

* GetAntiquityCategoryName(*integer* _antiquityCategoryId_)
** _Returns:_ *string* _name_

* GetAntiquityZoneId(*integer* _antiquityId_)
** _Returns:_ *integer* _zoneId_

* GetZoneNameById(*integer* _zoneId_)
** _Returns:_ *string* _name_

/script d(GetZoneNameById(GetAntiquityZoneId(GetAntiquitySetAntiquityId(9,1))))
]] local zoneName2Id
local antiquityItems
local Recipes = {}
local RecipesLinks = {}

local function RaidCategoryToZoneId(categoryId)
    local zoneName = GetItemSetCollectionCategoryName(categoryId)
    local zoneId = zoneName2Id[zoneName]
    if zoneId then
        return zoneId
    end
    local parentCategoryId = GetItemSetCollectionCategoryParentId(categoryId)
    if parentCategoryId == 0 then
        return nil
    else
        return RaidCategoryToZoneId(parentCategoryId)
    end
end

local function CategroyToZoneId(categoryId, itemId, item)
    -- 首次运行时初始化
    if not zoneName2Id then
        zoneName2Id = {}
        for i = 1, 10000 do
            local zoneId = GetZoneId(i)
            local zoneName = GetZoneNameByIndex(i)
            if zoneId == 0 then
                break
            end
            if zoneName ~= "" then
                zoneName2Id[zoneName] = zoneId
            end
        end
    end

    if not antiquityItems then
        antiquityItems = {}
        for i = 1, 10000 do
            local rewardId = GetAntiquitySetRewardId(i)
            local itemId = GetItemRewardItemId(rewardId)
            if rewardId > 0 and itemId > 0 then
                antiquityItems[itemId] = {
                    ["zoneId"] = 0,
                    ["leads"] = {}
                }
                for j = 1, 20 do
                    local antiquityFragmentId = GetAntiquitySetAntiquityId(i, j)
                    if antiquityFragmentId > 0 then
                        local fragmentZoneId = GetAntiquityZoneId(antiquityFragmentId)
                        table.insert(antiquityItems[itemId]["leads"], {
                            [1] = GetAntiquityName(antiquityFragmentId),
                            [2] = GetZoneNameById(fragmentZoneId)
                        })
                        if antiquityItems[itemId]["zoneId"] == 0 or antiquityItems[itemId]["zoneId"] == fragmentZoneId then
                            antiquityItems[itemId]["zoneId"] = fragmentZoneId
                        else
                            antiquityItems[itemId]["zoneId"] = -1
                        end
                    end
                end
                if antiquityItems[itemId]["zoneId"] < 0 then
                    local AntiquityCategoryName = GetAntiquityCategoryName(GetAntiquityCategoryId(
                        GetAntiquitySetAntiquityId(i, 1)))
                    antiquityItems[itemId]["zoneId"] = zoneName2Id[AntiquityCategoryName]
                end
            end
        end
    end

    -- Raid switch
    local raidZoneId = RaidCategoryToZoneId(categoryId)
    if raidZoneId then
        return raidZoneId
    end

    -- Antiquity switch
    local antiquityItem = antiquityItems[itemId]
    if antiquityItem then
        item["leads"] = antiquityItem.leads
        return antiquityItem.zoneId
    end

    -- Battleground switch
    if GetItemSetCollectionCategoryName(categoryId) == GetString(SI_ACTIVITY_FINDER_CATEGORY_BATTLEGROUNDS) then
        return -1
    end

    return nil
end

local function GetZoneIdList(zoneId, list)
    local parentZoneId = GetParentZoneId(zoneId)
    table.insert(list, zoneId)
    if parentZoneId == zoneId then
        return list
    else
        return GetZoneIdList(parentZoneId, list)
    end
end

local function AddItemFromID(i)
    -- 首次运行时构建配方索引
    if not Recipes[33526] then
        for x = 1, 40 do
            for y = 1, 1000 do
                local TargetId = select(8, GetRecipeInfo(x, y))
                if TargetId == 0 then
                    break
                else
                    Recipes[TargetId] = {x, y}
                end
            end
        end
    end

    -- 无文字的物品链接。
    -- 364, 50 为最大等级。
    -- 10000 表示完全修复（倒数第二个参数，可能不是必要的）。
    local link = ZO_LinkHandler_CreateLink('', nil, ITEM_LINK_TYPE, i, 364, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0)

    local itemName = GetItemLinkName(link)

    -- 无匹配，跳过。
    if itemName == '' then
        return
    end

    -- 仅匹配：套装、家具和配方。
    -- 以下变量将在后文中使用！
    local hasSet, setName, setNumBonuses, setNumEquipped, setMaxEquipped, setID = GetItemLinkSetInfo(link)
    local itemType, specializedItemType = GetItemLinkItemType(link)
    local itemTypeName = GetString("SI_ITEMTYPE", itemType)
    local itemStyle = GetItemLinkItemStyle(link)
    local itemStyleName = GetItemStyleName(itemStyle)
    local itemIcon = GetItemLinkIcon(link)

    -- Format.
    itemName = zo_strformat(SI_TOOLTIP_ITEM_NAME, itemName)

    -- Sets.
    if hasSet then
        local data = DataExtractor.dataSets

        local itemEquipType = GetItemLinkEquipType(link)
        local itemEquipTypeName = GetString("SI_EQUIPTYPE", itemEquipType)

        -- Either armor or weapon.
        local itemTypeSpecificName
        if itemType == ITEMTYPE_ARMOR then
            local armorType = GetItemLinkArmorType(link)
            itemTypeSpecificName = GetString("SI_ARMORTYPE", armorType)
        else
            local weaponType = GetItemLinkWeaponType(link)
            itemTypeSpecificName = GetString("SI_WEAPONTYPE", weaponType)
        end

        -- 该套装已记录过。
        if data[setID] then
            local item = data[setID] -- 引用。
            -- 添加物品外观样式。
            item.styles[itemTypeName] = item.styles[itemTypeName] or {}
            item.styles[itemTypeName][itemEquipTypeName] = item.styles[itemTypeName][itemEquipTypeName] or {}
            item.styles[itemTypeName][itemEquipTypeName][itemTypeSpecificName] = {}
            item.styles[itemTypeName][itemEquipTypeName][itemTypeSpecificName].styleId = itemStyle
            item.styles[itemTypeName][itemEquipTypeName][itemTypeSpecificName].style = itemStyleName
            item.styles[itemTypeName][itemEquipTypeName][itemTypeSpecificName].icon = itemIcon
            return
        end

        data[setID] = {}
        local item = data[setID] -- 引用。

        item.id = setID
        item.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, setName)

        -- Add some setInfo by @Chicor, @MelanAster ---------
        local setInfo = LibSets.setInfo[item.id]

        if setInfo then
            item["type"] = setInfo.setType
            item["classRestriction"] = GetItemSetClassRestrictions(setID)
            local zoneIds = setInfo.zoneIds or {}
            local categoryId = GetItemSetCollectionCategoryId(setID)

            if GetItemSetCollectionCategoryParentId(categoryId) ~= 0 then
                -- 已收录于合集中，覆盖 zoneIds
                local categoryName = GetItemSetCollectionCategoryName(categoryId)
                item["categoryName"] = categoryName
                local zoneId = CategroyToZoneId(categoryId, i, item)
                if zoneId then
                    item["zoneId"] = zoneId
                    zoneIds = GetZoneIdList(zoneId, {})
                end
            else
                -- 不在合集中
                item["categoryName"] = GetString(SI_SPECIALIZEDITEMTYPE213)
            end

            -- 去重
            local fixIds, existingId = {}, {}
            for k, v in pairs(zoneIds) do
                if v ~= 0 and not existingId[v] then
                    table.insert(fixIds, v)
                    existingId[v] = true
                end
            end
            zoneIds = fixIds
            -- 重新排序
            local function ZoneIdDepth(zoneId, depth)
                local parentZoneId = GetParentZoneId(zoneId)
                if zoneId == parentZoneId then
                    return depth
                else
                    return ZoneIdDepth(parentZoneId, depth + 1)
                end
            end
            table.sort(zoneIds, function(a, b)
                local dA, dB = ZoneIdDepth(a, 1), ZoneIdDepth(b, 1)
                if dA == dB then
                    return a < b
                else
                    return dA < dB
                end
            end)
            -- ID 转换为名称
            for k, v in pairs(zoneIds) do
                if v == -1 then
                    zoneIds = {GetString(SI_ACTIVITY_FINDER_CATEGORY_BATTLEGROUNDS)}
                    break
                end
                zoneIds[k] = GetZoneNameById(v)
            end
            item["place"] = zoneIds
        end

        if not item["itemIDs"] then
            item["itemIDs"] = LibSets.GetSetItemIds(item.id) or {}
            for itemId, v in pairs(item["itemIDs"]) do
                local itemLink = LibSets.buildItemLink(itemId)

                local armorType = GetItemLinkArmorType(itemLink)
                -- 0 无; 1 轻甲; 2 中甲; 3 重甲;

                local equipType = GetItemLinkEquipType(itemLink)
                -- 1 头部; 4 肩部; 3 胸部; 13 手部; 8 腰部; 9 腿部; 10 脚部;
                -- 2 项链; 12 戒指;
                -- 5 单手; 6 双手; 7 盾牌;

                local weaponType = GetItemLinkWeaponType(itemLink)
                -- 单手: 1 斧; 2 锤; 3 剑; 11 匕首;
                -- 双手: 4 剑; 5 斧; 6 锤;
                -- 法杖: 9 治疗; 12 火焰; 13 冰霜; 15 闪电;
                -- 弓: 8
                -- 盾牌: 14

                item["itemIDs"][itemId] = {armorType, equipType, weaponType}
            end
        end
        -----------------------------------------
        item.styles = {}
        item.styles[itemTypeName] = {}
        item.styles[itemTypeName][itemEquipTypeName] = {}
        item.styles[itemTypeName][itemEquipTypeName][itemTypeSpecificName] = {}
        item.styles[itemTypeName][itemEquipTypeName][itemTypeSpecificName].styleId = itemStyle
        item.styles[itemTypeName][itemEquipTypeName][itemTypeSpecificName].style = itemStyleName
        item.styles[itemTypeName][itemEquipTypeName][itemTypeSpecificName].icon = itemIcon

        -- 由 @Chicor, @MelanAster 添加套装信息 ---------
        -- 获取套装加成信息。
        if not item["bonuses"] then
            item["bonuses"] = {}
            local pieceId = GetItemSetCollectionPieceInfo(setID, 1)
            if pieceId > 0 then
                -- 不可制作
                local startItemLink = GetItemSetCollectionPieceItemLink(pieceId)
                local startQuality = GetItemLinkFunctionalQuality(startItemLink)
                for j = startQuality, 5 do
                    local itemLink = GetItemSetCollectionPieceItemLink(pieceId, 0, 0, j)
                    item["bonuses"][j] = {}
                    for l = 1, setNumBonuses do
                        local numRequired, bonusDescription = GetItemLinkSetBonusInfo(itemLink, false, l)
                        table.insert(item["bonuses"][j], bonusDescription)
                    end
                end
            else
                -- 可制作
                for j = 366, 370 do
                    local itemLink = "|H1:item:" .. i .. ":" .. j .. ":50:0:0:0:0:0:0:0:0:0:0:0:0:8:1:0:0:10000:0|h|h"
                    local quality = GetItemLinkFunctionalQuality(itemLink)
                    item["bonuses"][quality] = {}
                    for l = 1, setNumBonuses do
                        local numRequired, bonusDescription = GetItemLinkSetBonusInfo(itemLink, false, l)
                        table.insert(item["bonuses"][quality], bonusDescription)
                    end
                end
            end
        end

        -----------------------------------------

        DataExtractor.dataSetsCounter = DataExtractor.dataSetsCounter + 1

        return true
    end

    -- 家具。
    if itemType == ITEMTYPE_FURNISHING then
        local data = DataExtractor.dataFurniture

        data[i] = {}
        local item = data[i] -- 引用。

        item.id = i -- 物品ID。
        item.name = itemName

        local quality = GetItemLinkQuality(link)
        quality = GetString("SI_ITEMQUALITY", quality)
        item.quality = quality

        local flavor = GetItemLinkFlavorText(link)
        if flavor ~= '' then
            item.description = flavor
        end

        item.icon = itemIcon

        local dataId = GetItemLinkFurnitureDataId(link)
        item.furnitureId = furnitureId

        -- Category.
        local categoryId, subcategoryId = GetFurnitureDataCategoryInfo(dataId)
        item.category = GetFurnitureCategoryName(categoryId)
        item.subcategory = GetFurnitureCategoryName(subcategoryId)

        -- 标签。"家具行为"。
        local numTags = GetItemLinkNumItemTags(link)
        local tagStrings = {}
        for j = 1, numTags do
            local tagDescription, tagCategory = GetItemLinkItemTagInfo(link, j)

            if tagDescription ~= '' then
                table.insert(tagStrings, zo_strformat(SI_TOOLTIP_ITEM_TAG_FORMATER, tagDescription))
            end
        end
        if #tagStrings > 0 then
            item.tags = table.concat(tagStrings, ', ')
        end

        DataExtractor.dataFurnitureCounter = DataExtractor.dataFurnitureCounter + 1

        return true
    end

    -- 食物。
    if (itemType == ITEMTYPE_DRINK or itemType == ITEMTYPE_FOOD) and IsItemLinkConsumable(link) then
        local item = {
            ["id"] = i,
            ["name"] = itemName,
            ["quality"] = GetString("SI_ITEMQUALITY", GetItemLinkQuality(link)),
            ["icon"] = itemIcon,
            ["itemTypeText"] = itemTypeName,
            ["specializedItemTypeText"] = GetString("SI_SPECIALIZEDITEMTYPE", specializedItemType),
            ["description"] = select(3, GetItemLinkOnUseAbilityInfo(link)),
            ["canBeCrafted"] = Recipes[i] and true or false,
            ["ingredients"] = ""
        }
        DataExtractor.dataFoods[i] = item
        DataExtractor.dataFoodsCounter = DataExtractor.dataFoodsCounter + 1
        return true
    end

    -- 配方。
    if itemType == ITEMTYPE_RECIPE then
        local data = DataExtractor.dataRecipes

        data[i] = {}
        local item = data[i] -- 引用。

        item.id = i
        item.name = itemName

        local quality = GetItemLinkQuality(link)
        quality = GetString("SI_ITEMQUALITY", quality)
        item.quality = quality

        local recipeType = GetItemLinkRecipeCraftingSkillType(link)
        recipeType = GetCraftingSkillName(recipeType)
        item.type = recipeType

        local recipeItemLink = GetItemLinkRecipeResultItemLink(link)
        local hasAbility, abilityHeader, abilityDescription, cooldown, hasScaling, minLevel, maxLevel, isChampionPoints,
            remainingCooldown = GetItemLinkOnUseAbilityInfo(recipeItemLink)
        if hasAbility then
            item.description = abilityDescription

            if hasScaling then
                local champ = ''
                if isChampionPoints then
                    champ = 'cp'
                end
                item.scales = string.format('Scales from level %s%s to %s%s.', champ, minLevel, champ, maxLevel)
            end
        end

        RecipesLinks[GetItemLinkItemId(recipeItemLink)] = link

        -- 食材。
        local ingredients = {}
        local numIngredients = GetItemLinkRecipeNumIngredients(link)
        for j = 1, numIngredients do
            local ingredientName, numOwned, numRequired = GetItemLinkRecipeIngredientInfo(link, j)
            table.insert(ingredients, string.format('%s (%s)', ingredientName, numRequired))
        end
        item.ingredients = table.concat(ingredients, ', ')

        -- 所需技能。
        local skills = {}
        local numSkillsReq = GetItemLinkRecipeNumTradeskillRequirements(link)
        for j = 1, numSkillsReq do
            local skill, lvl = GetItemLinkRecipeTradeskillRequirement(link, j)

            local skillid = GetTradeskillLevelPassiveAbilityId(skill)
            local skillName = GetAbilityName(skillid)

            table.insert(skills, string.format('%s %s', skillName, lvl))
        end
        item.skills = table.concat(skills, ', ')

        DataExtractor.dataRecipesCounter = DataExtractor.dataRecipesCounter + 1

        return true
    end
end

-- 向数据库添加收藏品（仅限可用作家具的收藏品）。
-- i - (int) 收藏品ID。
-- 成功时返回 true。
local function AddCollectibleFromID(i)
    -- 收藏品——部分可用作家具。
    local collectibleName = GetCollectibleName(i)

    -- 无匹配，跳过。
    if collectibleName == '' then
        return
    end

    local furnitureId = GetCollectibleFurnitureDataId(i)

    -- 不是家具，跳过。
    if furnitureId == 0 then
        return
    end

    local collectibleDescription = GetCollectibleDescription(i)

    local data = DataExtractor.dataCollectibleFurniture

    data[i] = {}
    local item = data[i] -- 引用。

    item.id = i -- 收藏品ID。
    item.furnitureId = furnitureId
    item.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, collectibleName) -- Format.

    item.description = collectibleDescription
    item.hint = GetCollectibleHint(i) -- 获取该收藏品的途径。
    item.category = GetCollectibleCategoryNameByCollectibleId(i)
    item.categoryType = GetCollectibleCategoryType(i)
    item.categoryId = GetCollectibleCategoryId(i)
    item.icon = GetCollectibleIcon(i)

    DataExtractor.dataFurnitureCounter = DataExtractor.dataFurnitureCounter + 1

    return true
end

-- 抓取游戏中所有物品数据。
function DataExtractor.GetAllItems()
    -- 避免重复运行。
    if DataExtractor.scrapingItems == true then
        d('|cFFFFFFDataExtractor:|r 物品遍历已在进行!')
        return
    end
    -- 追踪状态。
    DataExtractor.scrapingItems = true

    -- 遍历游戏中的所有物品。
    local limit = DataExtractor.itemScanLimit

    local chunk = 100 -- 分批处理以避免游戏崩溃。
    local chunks = limit / chunk -- 总批次数。
    local delay = 20 -- 每批之间的毫秒延迟。

    for t = 1, chunks do
        zo_callLater(function()
            local x = 1 + (chunk * (t - 1)) -- Start.
            local y = chunk * t -- End.

            for i = x, y do
                AddItemFromID(i)
                AddCollectibleFromID(i)
            end

            -- 全部完成。最后一批打印汇总信息。
            if t == chunks then

                -- 食物食材。
                for k, v in pairs(DataExtractor.dataFoods) do
                    if v.canBeCrafted then
                        local link = RecipesLinks[k]
                        local ingredients = {}
                        local numIngredients = GetItemLinkRecipeNumIngredients(link)
                        for j = 1, numIngredients do
                            local ingredientName, numOwned, numRequired = GetItemLinkRecipeIngredientInfo(link, j)
                            table.insert(ingredients, string.format('%s (%s)', ingredientName, numRequired))
                        end
                        v.ingredients = table.concat(ingredients, ', ')
                    end
                end

                d(string.format(
                    '|cFFFFFFDataExtractor:|r 完工! 总IDs: %s 套装: %s 家具: %s 配方: %s 食物: %s. (使用 %s 指令来保存数据!)',
                    limit, DataExtractor.dataSetsCounter, DataExtractor.dataFurnitureCounter,
                    DataExtractor.dataRecipesCounter, DataExtractor.dataFoodsCounter, DataExtractor.slashSave))
                -- 更新追踪状态。
                DataExtractor.scrapingItems = false
            end
        end, delay * t)
    end

    d(string.format('|cFFFFFFDataExtractor:|r 抓取物品数据中, 请等待约 %s 秒...',
        math.floor((chunks * delay) / 1000)))
end
