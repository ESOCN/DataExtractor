-- 抓取游戏内所有外观样式。
function DataExtractor.GetAllStyles()
    -- 避免重复运行。
    if DataExtractor.scrapingStyles == true then
        d('|cFFFFFFDataExtractor:|r 样式遍历已在进行!')
        return
    end
    -- 追踪状态。
    DataExtractor.scrapingStyles = true

    d(string.format('|cFFFFFFDataExtractor:|r 抓取样式数据，请等待...'))
    
    DataExtractor.dataStyles = {}
    
    -- 遍历所有样式。
    for i = 1, GetNumValidItemStyles() do
        local vId = GetValidItemStyleId(i)
        if vId > 0 then
            local styleName = GetItemStyleName(vId)
            local styleItemLink = GetItemStyleMaterialLink(vId)
            local styleItemId = GetItemLinkItemId(styleItemLink)
            local styleItemName = GetItemLinkName(styleItemLink)
            local icon, sellPrice, meetsUsageRequirement = GetItemLinkInfo(styleItemLink)
            
            local style = {}
            style.id = vId
            style.name = styleName
            style.materialId = styleItemId
            style.materialName = styleItemName
            style.icon = icon
            
            DataExtractor.dataStyles[vId] = style
            DataExtractor.dataStylesCounter = DataExtractor.dataStylesCounter + 1
        end
    end

    d(
        string.format(
            '|cFFFFFFDataExtractor:|r 完工! 总样式: %s. (使用 %s 指令来保存数据!)',
            DataExtractor.dataStylesCounter, DataExtractor.slashSave
        )
    )
    -- 重置追踪状态。
    DataExtractor.scrapingStyles = false
end