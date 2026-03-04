-- 抓取游戏中所有玩家住房数据。
-- 通过 COLLECTIBLE_CATEGORY_TYPE_HOUSE 枚举所有住房收藏品，
-- 再用 GetCollectibleReferenceId 反查 houseId 获取住房详细信息。
function DataExtractor.GetAllHouses()
    -- 避免重复运行。
    if DataExtractor.scrapingHouses == true then
        d('|cFFFFFFDataExtractor:|r 住房遍历已在进行!')
        return
    end
    DataExtractor.scrapingHouses = true

    local data = DataExtractor.dataHouses
    local totalHouses = GetTotalCollectiblesByCategoryType(COLLECTIBLE_CATEGORY_TYPE_HOUSE)

    for index = 1, totalHouses do
        local collectibleId = GetCollectibleIdFromType(COLLECTIBLE_CATEGORY_TYPE_HOUSE, index)

        if collectibleId and collectibleId > 0 then
            local houseId = GetCollectibleReferenceId(collectibleId)

            if houseId and houseId > 0 then
                -- 通过收藏品获取名称、描述、图标等。
                local name = GetCollectibleName(collectibleId)

                if name and name ~= '' then
                    data[houseId] = {}
                    local item = data[houseId]

                    item.id = houseId
                    item.collectibleId = collectibleId
                    item.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, name)
                    item.description = GetCollectibleDescription(collectibleId)
                    item.hint = GetCollectibleHint(collectibleId)
                    item.icon = GetCollectibleIcon(collectibleId)
                    item.image = GetHousePreviewBackgroundImage(houseId)

                    -- 房屋分类：Staple(1)/主要 Classic(2)/经典 Notable(3)/著名
                    local categoryType = GetHouseCategoryType(houseId)
                    item.categoryType = categoryType
                    item.categoryTypeName = GetString('SI_HOUSECATEGORYTYPE', categoryType)

                    -- 房屋所处的真实世界区域（如 奥里顿、格伦布拉）。
                    local foundInZoneId = GetHouseFoundInZoneId(houseId)
                    item.zoneId = foundInZoneId
                    item.zone = GetZoneNameById(foundInZoneId)

                    -- 房屋自身的 zone（传送进入的目标）。
                    item.houseZoneId = GetHouseZoneId(houseId)

                    -- 家具放置上限（4 种类型）。
                    item.furnishingLimits = {
                        itemLow         = GetHouseFurnishingPlacementLimit(houseId, HOUSING_FURNISHING_LIMIT_TYPE_LOW_IMPACT_ITEM),
                        itemHigh        = GetHouseFurnishingPlacementLimit(houseId, HOUSING_FURNISHING_LIMIT_TYPE_HIGH_IMPACT_ITEM),
                        collectibleLow  = GetHouseFurnishingPlacementLimit(houseId, HOUSING_FURNISHING_LIMIT_TYPE_LOW_IMPACT_COLLECTIBLE),
                        collectibleHigh = GetHouseFurnishingPlacementLimit(houseId, HOUSING_FURNISHING_LIMIT_TYPE_HIGH_IMPACT_COLLECTIBLE),
                    }

                    -- 玩家是否已拥有。
                    local unlockState = GetCollectibleUnlockStateById(collectibleId)
                    item.unlocked = (unlockState ~= COLLECTIBLE_UNLOCK_STATE_LOCKED)

                    DataExtractor.dataHousesCounter = DataExtractor.dataHousesCounter + 1
                end
            end
        end
    end

    d(string.format('|cFFFFFFDataExtractor:|r 完工! 住房: %s. (使用 %s 指令来保存数据!)',
        DataExtractor.dataHousesCounter, DataExtractor.slashSave))
    DataExtractor.scrapingHouses = false
end
