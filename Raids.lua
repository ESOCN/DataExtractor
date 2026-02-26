--[[
* GetCategoryInfoFromAchievementId(*integer* _achievementId_)
** _返回值:_ *luaindex:nilable* _topLevelIndex_, *luaindex:nilable* _categoryIndex_, *luaindex:nilable* _achievementIndex_（顶级索引、分类索引、成就索引）

* GetAchievementCategoryInfo(*luaindex* _topLevelIndex_)
** _返回值:_ *string* _name_, *integer* _numSubCatgories_, *integer* _numAchievements_, *integer* _earnedPoints_, *integer* _totalPoints_, *bool* _hidesPoints_（名称、子分类数、成就数、已获积分、总积分、是否隐藏积分）

* GetAchievementSubCategoryInfo(*luaindex* _topLevelIndex_, *luaindex* _subCategoryIndex_)
** _返回值:_ *string* _name_, *integer* _numAchievements_, *integer* _earnedPoints_, *integer* _totalPoints_, *bool* _hidesPoints_（名称、成就数、已获积分、总积分、是否隐藏积分）

* GetFastTravelNodeInfo(*luaindex* _nodeIndex_)
** _返回值:_ *bool* _known_, *string* _name_, *number* _normalizedX_, *number* _normalizedY_, *textureName* _icon_, *textureName:nilable* _glowIcon_, *[PointOfInterestType|#PointOfInterestType]* _poiType_, *bool* _isShownInCurrentMap_, *bool* _linkedCollectibleIsLocked_（是否已知、名称、X坐标、Y坐标、图标、发光图标、兴趣点类型、是否在当前地图显示、关联收藏品是否锁定）

* GetRequiredActivityCollectibleId(*integer* _activityId_)
** _返回值:_ *integer* _collectibleId_（所需DLC收藏品ID）
]]
local zoneName2Id
local zoneName2ActivityId

local function GetRaidPlace(zoneId, list)
  local parentZoneId = GetParentZoneId(zoneId)
  table.insert(list, zoneId)
  if parentZoneId == zoneId then
    for k, v in pairs(list) do
      list[k] = GetZoneNameById(v)
    end
    return list
  else
    return GetRaidPlace(parentZoneId, list)
  end
end

function DataExtractor.GetAllRaids()
  local PAT = PITHKA.data.achievements
  
  if not PAT then
    d('|cFFFFFFDataExtractor:|r 缺少PAT提供副本信息！')
    return
  end
  
  if not zoneName2Id then
    zoneName2Id = {}
    for i = 1, 10000 do
      local zoneId = GetZoneId(i)
      local zoneName = GetZoneNameByIndex(i)
      if zoneId == 0 then break end
      if zoneName ~= "" then
        zoneName2Id[zoneName] = zoneId
      end
    end
  end
  
  if not zoneName2ActivityId then
    zoneName2ActivityId = {}
    for i = 1, 10000 do
      local activityName = GetActivityInfo(i)
      if activityName ~= "" then
        zoneName2ActivityId[activityName] = i
      end
    end
  end

  local result = {}
  for k, v in pairs(PAT) do
    local raidName = select(2, GetFastTravelNodeInfo(v.portID))
    raidName = raidName:gsub(".+：", ""):gsub(".+: ", "")
    local raidZoneId = zoneName2Id[raidName]
    local raidPlace = GetRaidPlace(raidZoneId, {})
    local raidAbbreviation = PAT.ABBV
    local isRequiredDLC = GetRequiredActivityCollectibleId(zoneName2ActivityId[raidName]) > 0
    local function table2Achievements(t)
      local dict = {
        VET = "VET", PHM1 = "midHM1", PHM2 = "midHM2", HM = "HM",
        TRI = "TRI", EXT = "EX", SR = "SR", ND = "ND",
        CHA = "fakeTRI",
      }
      local tep = {}
      for k, v in pairs(dict) do
        if t[k] then
          tep[v] = t[k]
        end
      end
      return tep
    end
    local raidAchievements = table2Achievements(v)
    local raidType
    if v.TYPE == "triDungeon" or v.TYPE == "baseDungeon-wI" then
      raidType = "dungeon"
    else
      raidType = v.TYPE
    end
    
    table.insert(result,{
      ["name"] = raidName,
      ["zoneId"] = raidZoneId,
      ["place"] = raidPlace,
      ["type"] = raidType,
      ["abbreviation"] = raidAbbreviation,
      ["isRequiredDLC"] = isRequiredDLC,
      ["achievements"] = raidAchievements,
    })
  end
  
  DataExtractor.dataRaids = result
  d('|cFFFFFFDataExtractor:|r 完工! 副本信息已抓取 (使用 /scrapesave 指令来保存数据!)')
end