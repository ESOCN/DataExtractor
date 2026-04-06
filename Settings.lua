local function SaveData()
    -- 更新存档变量。
    DataExtractor.savedVariables.dataCpSkills = DataExtractor.dataCpSkills
    DataExtractor.savedVariables.dataSkills = DataExtractor.dataSkills
    DataExtractor.savedVariables.dataPotions = DataExtractor.dataPotions

    DataExtractor.savedVariables.dataItems.Sets = DataExtractor.dataSets
    DataExtractor.savedVariables.dataItems.Foods = DataExtractor.dataFoods
    DataExtractor.savedVariables.dataItems.Furniture = DataExtractor.dataFurniture
    DataExtractor.savedVariables.dataItems.CollectibleFurniture = DataExtractor.dataCollectibleFurniture
    DataExtractor.savedVariables.dataItems.Recipes = DataExtractor.dataRecipes
    DataExtractor.savedVariables.dataCollectibles = DataExtractor.dataCollectibles
    DataExtractor.savedVariables.dataHouses = DataExtractor.dataHouses

    DataExtractor.savedVariables.dataStyles = DataExtractor.dataStyles
    DataExtractor.savedVariables.dataOutfitStyles = DataExtractor.dataOutfitStyles
    DataExtractor.savedVariables.dataDyes = DataExtractor.dataDyes
    DataExtractor.savedVariables.dataAchievs = DataExtractor.dataAchievs
    DataExtractor.savedVariables.dataAntiquities = DataExtractor.dataAntiquities
    DataExtractor.savedVariables.dataRaids = DataExtractor.dataRaids
    DataExtractor.savedVariables.dataAllItems = DataExtractor.dataAllItems

    ReloadUI("ingame")
end

local function CraftedSkillCheck()
  if not SCRIBING_DATA_MANAGER.sortedCraftedAbilityTable[1] then 
    return true
  else
    return false 
  end
end

-- 设置菜单。
function DataExtractor.LoadSettings()
    local LAM = LibAddonMenu2

    local panelData = {
        type = "panel",
        name = DataExtractor.menuName.." 数据提取器",
        displayName = DataExtractor.Colorize(DataExtractor.menuName),
        author = DataExtractor.Colorize(DataExtractor.author..", Chicer, MelanAster", "AAF0BB"),
        -- version = DataExtractor.Colorize(DataExtractor.version, "AA00FF"),（版本号字段，暂时注释）
        -- slashCommand = "/dataextractor",（斜杠命令字段，暂时注释）
        registerForRefresh = true,
        registerForDefaults = true,
    }
    LAM:RegisterAddonPanel(DataExtractor.menuName, panelData)

    local optionsTable = {
      {
        type = "button",
        name = "以下所有",
        tooltip = "将会产生一定卡顿，需要解锁技能按钮条件",
        func = function() 
          DataExtractor.GetAllSkills() 
          DataExtractor.GetAllCpSkills()
          DataExtractor.GetAllPotions()
          DataExtractor.GetAllAchievs()
          DataExtractor.GetAllStyles()
          DataExtractor.GetAllOutfitStyles()
          DataExtractor.GetAllRaids()
          DataExtractor.GetAllAntiquities()
          DataExtractor.GetAllItems()
          DataExtractor.GetAllCollectibles()
          DataExtractor.GetAllHouses()
          DataExtractor.GetAllDyes()
        end,
        disabled = CraftedSkillCheck,
        width = "full",
      },
      {
        type = "button",
        name = "技能",
        tooltip = "打开【技能 - 篆刻】界面，使游戏生成篆刻信息后，解锁该按钮",
        func = function() DataExtractor.GetAllSkills() end,
        disabled = CraftedSkillCheck,
        width = "half",
      },
      {
        type = "button",
        name = "CP技能",
        func = function() DataExtractor.GetAllCpSkills() end,
        width = "half",
      },
      {
        type = "button",
        name = "物品",
        tooltip = "包含 套装、家具、食物、配方",
        func = function() DataExtractor.GetAllItems() end,
        width = "half",
      },
      {
        type = "button",
        name = "收藏品",
        tooltip = "提取所有收藏品（坐骑、宠物、家具收藏品等）",
        func = function() DataExtractor.GetAllCollectibles() end,
        width = "half",
      },
      {
        type = "button",
        name = "住房",
        tooltip = "提取所有玩家住房数据",
        func = function() DataExtractor.GetAllHouses() end,
        width = "half",
      },
      {
        type = "button",
        name = "药水",
        func = function() DataExtractor.GetAllPotions() end,
        tooltip = "基于静态数据计算所有药水/毒药组合，无需持有炼金材料",
        width = "half",
      },
      {
        type = "button",
        name = "成就",
        func = function() DataExtractor.GetAllAchievs() end,
        width = "half",
      },
      {
        type = "button",
        name = "样式",
        func = function() DataExtractor.GetAllStyles() end,
        width = "half",
      },
      {
        type = "button",
        name = "染料",
        tooltip = "提取所有染料数据（名称、颜色、稀有度、色调分类等）",
        func = function() DataExtractor.GetAllDyes() end,
        width = "half",
      },
      {
        type = "button",
        name = "时装幻化",
        tooltip = "提取所有时装幻化外观样式（Outfit Style）收藏品",
        func = function() DataExtractor.GetAllOutfitStyles() end,
        width = "half",
      },
      {
        type = "button",
        name = "副本",
        tooltip = "需要 Pithka's Achievement Tracker 插件",
        func = function() DataExtractor.GetAllRaids() end,
        width = "half",
      },
      {
        type = "button",
        name = "古物线索",
        tooltip = "提取所有古物线索数据（含掉落信息、知识条目等）",
        func = function() DataExtractor.GetAllAntiquities() end,
        width = "half",
      },
      {
        type = "divider",
      },
      {
        type = "button",
        name = "中英文切换",
        func = function()
          if GetCVar("language.2") == "zh" then
            SetCVar("language.2","en")
          else
            SetCVar("language.2","zh")
          end
        end,
        warning = "将会自动重载UI",
        width = "half",
      },
      {
        type = "button",
        name = "保存所有数据",
        func = function() SaveData() end,
        width = "half",
        warning = "将会自动重载UI",
      },
    }
    LAM:RegisterOptionControls(DataExtractor.menuName, optionsTable)
end