--[[
    按需扫描游戏数据并保存至存档变量。
    可用数据：技能、套装、家具物品、配方。
    使用分层回调以降低CPU占用（避免卡顿或崩溃）。
--]]

local DataExtractorDetails = {
    name            = "DataExtractor",          -- 与文件夹名和清单文件名一致。
    author          = "phuein",
    color           = "DDFFEE",                 -- 用于菜单标题等处的颜色。
    menuName        = "Data Extractor",         -- 菜单对象的唯一标识符。
    -- 默认设置。
    savedVariables = {
        FirstLoad = true,                       -- 插件首次加载标志。
        -- 抓取类别。TODO
        scrapeSkills = true,
        scrapeItems = true,
        scrapeAchievs = true,
        -- 抓取子类别。TODO
        scrapeSets = true,
        scrapeFurniture = true,
        scrapeRecipes = true,
        -- 已保存的数据。注意：内容长度可能很长！
        dataSkills = {},
        dataItems = {
            Sets = {},
            Furniture = {},
            CollectibleFurniture = {},
            Recipes = {},
        },
        dataAchievs = {},
        dataStyles = {},
        dataOutfitStyles = {},
    },
    -- 选项。
    itemScanLimit       = 500000,               -- 扫描的物品ID数量上限。注意：最大值大约在20万左右。
    -- 数据。
    dataSkills      = {},                       -- 技能数据。
    dataCpSkills    = {},
    dataSets        = {},                       -- 存放所有套装的引用。
    dataFurniture   = {},                       -- 家具数据。
    dataCollectibleFurniture = {},              -- 家具收藏品数据。
    dataFoods       = {},
    dataPotions     = {},
    dataRecipes     = {},                       -- 配方数据。
    dataAchievs     = {},                       -- 成就数据。
    dataStyles      = {},                       -- 物品外观数据。
    dataOutfitStyles = {},                      -- 时装幻化外观样式数据。
    -- 计数器。
    dataSkillLinesCounter = 0,
    dataSkillsCounter = 0,
    
    dataSetsCounter = 0,
    dataFurnitureCounter = 0,
    dataFoodsCounter = 0,
    dataRecipesCounter = 0,

    dataAchievsCounter = 0,
    dataAchievsCatCounter = 0,
    dataAchievsSubcatCounter = 0,

    dataStylesCounter = 0,
    dataOutfitStylesCounter = 0,
    -- 追踪。
    scrapingSkills = false,                     -- 避免同一抓取器同时运行超过一次。
    scrapingItems = false,
    scrapingAchievs = false,
    scrapingStyles = false,
    scrapingOutfitStyles = false,
    -- 异步追踪技能进度。
    currentType = nil,
    currentLine = nil,
    currentSkill = nil,
    -- 斜杠命令（小写，带斜杠）。
    slashSkills = '/scrapeskills',
    slashCpSkills = '/scrapecpskills',
    slashItems = '/scrapeitems',
    slashAchievs = '/scrapeachievs',
    slashStyles = '/scrapestyles',
    slashOutfitStyles = '/scrapeoutfitstyles',
    slashPotions = '/scrapepotions',
    
    slashSave = '/scrapesave',
}

-- 将详细信息添加到全局变量中。
for k, v in pairs(DataExtractorDetails) do
    DataExtractor[k] = v
end

-- 用指定颜色包裹文本。
function DataExtractor.Colorize(text, color)
    -- 默认使用插件自身的 .color 颜色。
    if not color then color = DataExtractor.color end

    text = string.format('|c%s%s|r', color, text)

    return text
end

-- 将所有表中抓取到的数据保存至存档变量，
-- 并执行 /reloadui 强制写入文件。
local function SaveData()
    -- 更新存档变量。
    DataExtractor.savedVariables.dataSkills = DataExtractor.dataSkills
    DataExtractor.savedVariables.dataCpSkills = DataExtractor.dataCpSkills
    DataExtractor.savedVariables.dataPotions = DataExtractor.dataPotions
    
    DataExtractor.savedVariables.dataItems.Sets = DataExtractor.dataSets
    DataExtractor.savedVariables.dataItems.Foods = DataExtractor.dataFoods
    DataExtractor.savedVariables.dataItems.Furniture = DataExtractor.dataFurniture
    DataExtractor.savedVariables.dataItems.CollectibleFurniture = DataExtractor.dataCollectibleFurniture
    DataExtractor.savedVariables.dataItems.Recipes = DataExtractor.dataRecipes

    DataExtractor.savedVariables.dataAchievs = DataExtractor.dataAchievs

    ReloadUI("ingame")
end

-- 仅在首次加载时显示欢迎消息。
function DataExtractor.Activated(e)
    EVENT_MANAGER:UnregisterForEvent(DataExtractor.name, EVENT_PLAYER_ACTIVATED)

    if DataExtractor.savedVariables.FirstLoad then
        DataExtractor.savedVariables.FirstLoad = false
    end
end
-- 玩家准备就绪后（所有内容加载完毕后）触发。
EVENT_MANAGER:RegisterForEvent(DataExtractor.name, EVENT_PLAYER_ACTIVATED, DataExtractor.Activated)

function DataExtractor.OnAddOnLoaded(event, addonName)
    if addonName ~= DataExtractor.name then return end
    EVENT_MANAGER:UnregisterForEvent(DataExtractor.name, EVENT_ADD_ON_LOADED)

    DataExtractor.savedVariables = ZO_SavedVars:NewAccountWide("DataExtractorSavedVariables", 1, nil, DataExtractor.savedVariables)

    -- 设置菜单在 Settings.lua 中定义。
    -- DataExtractor.LoadSettings()

    SLASH_COMMANDS[DataExtractor.slashSkills] = DataExtractor.GetAllSkills
    SLASH_COMMANDS[DataExtractor.slashCpSkills] = DataExtractor.GetAllCpSkills
    SLASH_COMMANDS[DataExtractor.slashItems] = DataExtractor.GetAllItems
    SLASH_COMMANDS[DataExtractor.slashAchievs] = DataExtractor.GetAllAchievs
    SLASH_COMMANDS[DataExtractor.slashStyles] = DataExtractor.GetAllStyles
    SLASH_COMMANDS[DataExtractor.slashOutfitStyles] = DataExtractor.GetAllOutfitStyles
    SLASH_COMMANDS[DataExtractor.slashPotions] = DataExtractor.GetAllPotions

    SLASH_COMMANDS[DataExtractor.slashSave] = SaveData
    
    DataExtractor.LoadSettings()
end
-- 任意插件加载时触发（在UI聊天界面加载前）。
EVENT_MANAGER:RegisterForEvent(DataExtractor.name, EVENT_ADD_ON_LOADED, DataExtractor.OnAddOnLoaded)