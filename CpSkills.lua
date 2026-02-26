--[[
GetChampionDisciplineId(luaindex disciplineIndex)
  返回值: integer disciplineId（冠军学科ID）

GetChampionDisciplineName(integer disciplineId)
  返回值: string name（冠军学科名称）

GetChampionSkillId(luaindex disciplineIndex, luaindex championSkillIndex)
  返回值: integer championSkillId（冠军技能ID）

GetChampionSkillJumpPoints(integer championSkillId)
  使用可变数量返回值...
  返回值: integer jumpPoint（技能跳跃点数）
  
GetChampionSkillCurrentBonusText(integer championSkillId, integer numPendingPoints)
  返回值: string currentBonus（当前加成文本）

CanChampionSkillTypeBeSlotted(ChampionSkillType championSkillType)
  返回值: bool isSlottable（是否可插槽）

GetChampionClusterSkillIds(integer rootChampionSkillId)
  使用可变数量返回值...
  返回值: integer championSkillIds（群集技能ID列表）
]]

function DataExtractor.GetAllCpSkills()
  local T0 = {}
  --群集CP技能
  local clusters = {}
  for i = 1, 1000 do
    if GetChampionClusterName(i) ~= "" then
      for k, v in ipairs({GetChampionClusterSkillIds(i)}) do
        clusters[v] = i
      end
    end
  end
  --单体CP技能
  for i = 1, 10 do
    local disciplineId = GetChampionDisciplineId(i)
    if disciplineId > 0 then
      local T1 = {
        ["index"] = i,
        ["id"] = disciplineId,
        ["name"] = GetChampionDisciplineName(disciplineId),
        ["skills"] = {},
      }
      for j = 1, 100 do
        local championSkillId = GetChampionSkillId(i, j)
        if championSkillId > 0 then
          local T2 = {
            ["index"] = j,
            ["id"] = championSkillId,
            ["name"] = GetChampionSkillName(championSkillId),
            ["type"] = GetChampionSkillType(championSkillId),
            ["description"] = GetChampionSkillDescription(championSkillId),
            ["bounsText"] = {},
            ["isSlottable"] = CanChampionSkillTypeBeSlotted(GetChampionSkillType(championSkillId)),
            ["isInCluster"] = clusters[championSkillId] and true or false,
            ["clusterName"] = GetChampionClusterName(clusters[championSkillId]),
          }
          if #{GetChampionSkillJumpPoints(championSkillId)} > 2 then
            for k, v in ipairs({GetChampionSkillJumpPoints(championSkillId)}) do
              T2.bounsText[v] = GetChampionSkillCurrentBonusText(championSkillId, v)
            end
          end
          table.insert(T1.skills, T2)
        end
      end
      table.insert(T0, T1)
    end
  end
  DataExtractor.dataCpSkills = T0
  d('|cFFFFFFDataExtractor:|r 完工! CP技能已抓取 (使用 /scrapesave 指令来保存数据!)')
end