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
    
    DataExtractor.savedVariables.dataStyles = DataExtractor.dataStyles
    DataExtractor.savedVariables.dataAchievs = DataExtractor.dataAchievs
    DataExtractor.savedVariables.dataRaids = DataExtractor.dataRaids

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
          DataExtractor.GetAllRaids()
          DataExtractor.GetAllItems()
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
        name = "药水",
        func = function() DataExtractor.GetAllPotions() end,
        tooltip = "需要解锁所有炼金材料的4个词条，且当前每种炼金材料持有至少1个，才可以获得所有的药水配方",
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
        name = "副本",
        tooltip = "需要 Pithka's Achievement Tracker 插件",
        func = function() DataExtractor.GetAllRaids() end,
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