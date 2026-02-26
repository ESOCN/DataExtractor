local function ToLink(Id)
  if not Id then return "" end
  return "|H0:item:"..tostring(Id)..":30:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
end

local function RealName(Id)
  local link = ToLink(Id)
  return zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(link))
end

local function GetEncode(String)
  local NumString = ""
  for word in string.gmatch(String, "%d+|") do
    NumString = string.gsub(word, "|", "",1)
  end
  return tonumber(NumString)
end

local function GetDescription(link)
  local list = {}
  for i = 1, 10 do
    text = select(2, GetItemLinkTraitOnUseAbilityInfo(link, i))
    if text ~= "" then
      table.insert(list, text)
    else 
      break
    end
  end
  return list
end

--需要解锁所有词条以及背包中备齐所有种类材料后运行
local Reagents = {
  77587,  --尸蝇幼虫              64
  30148,  --蓝柄菇               66
  30162,  --龙刺草               66
  30154,  --白盖菇               68
  30159,  --艾草                 75
  30155,  --发光红菇             79
  77584,  --蜘蛛卵               79
  30166,  --水风信子             81
  30165,  --宁根草               81
  30157,  --蓟草                 82
  30153,  --纳米拉腐草           84
  30158,  --淑女衣草             88
  77585,  --蝴蝶翅膀             90
  30149,  --臭角菇               94
  30156,  --阻燃菇               108
  150789, --龙胆                 113
  77590,  --曼陀罗花             118
  30151,  --催吐红菇             124
  30161,  --矢车菊               134
  77583,  --甲虫壳               176
  30163,  --山花                 231
  30160,  --牛舌草               295
  77589,  --石蛾虫液             410
  150672, --深红宁根草           523
  150670, --恶浊凝结物           626
  77591,  --螃蟹甲               658
  77581,  --火虫胸腔             726
  139020, --蛤蜊胆汁             791
  150669, --虫卵                 825

  30152,  --紫头菇               1019
  30164,  --耧斗菜               1651
  139019, --珍珠母粉             2016

  150731, --龙血                 3809
  150671, --龙黏液               7793
}

function DataExtractor.GetAllPotions()
  d("|cFFFFFFDataExtractor:|r 请确保已解锁所有炼金材料的所有词条，且制作背包中存在所有种类的炼金材料")
  local LinkList = {}
  --记录所有2种材料药水的链接
  for a = 1, 34 do
    for b = a + 1 , 34 do
      local Link1 = GetAlchemyResultingItemLink(5, 75365, 5, Reagents[a], 5, Reagents[b])
      LinkList[Link1] = LinkList[Link1] or {}
      table.insert(LinkList[Link1], {RealName(Reagents[a]), RealName(Reagents[b])})
      local Link2 = GetAlchemyResultingItemLink(5, 64501, 5, Reagents[a], 5, Reagents[b])
      LinkList[Link2] = LinkList[Link2] or {}
      table.insert(LinkList[Link2], {RealName(Reagents[a]), RealName(Reagents[b])})
    end
  end
  --记录所有3种材料药水的链接
  for a = 1, 34 do
    for b = a + 1 , 34 do
      for c = b + 1 , 34 do
        local Link1 = GetAlchemyResultingItemLink(5, 75365, 5, Reagents[a], 5, Reagents[b], 5, Reagents[c])
        LinkList[Link1] = LinkList[Link1] or {}
        table.insert(LinkList[Link1], {RealName(Reagents[a]), RealName(Reagents[b]), RealName(Reagents[c])})
        local Link2 = GetAlchemyResultingItemLink(5, 64501, 5, Reagents[a], 5, Reagents[b], 5, Reagents[c])
        LinkList[Link2] = LinkList[Link2] or {}
        table.insert(LinkList[Link2], {RealName(Reagents[a]), RealName(Reagents[b]), RealName(Reagents[c])})
      end
    end
  end
  --链接转列表
  local T0 = {}
  for k, v in pairs(LinkList) do
    local link = k
    local itemType = GetItemLinkItemType(link)
    local item = {
      ["id"] = GetItemLinkItemId(link),
      ["encode"] = GetEncode(link) or 0,
      ["name"] = GetItemLinkName(link),
      ["quality"] = GetString("SI_ITEMQUALITY", GetItemLinkQuality(link)),
      ["icon"] = GetItemLinkIcon(link),
      ["itemTypeText"] = GetString("SI_ITEMTYPE", itemType),
      ["description"] = GetDescription(link),
      ["canBeCrafted"] = true,
      ["recipes"] = v,
    }
    T0[item.id] = T0[item.id] or {}
    T0[item.id][item.encode] = item
  end
  --其他药水
  for i = 1, DataExtractor.itemScanLimit do
    if not T0[i] then
      local link = ToLink(i)
      local itemType = GetItemLinkItemType(link)
      if IsItemLinkConsumable(link) and (itemType == ITEMTYPE_POTION or itemType == ITEMTYPE_POISON) then
        local item = {
          ["id"] = GetItemLinkItemId(link),
          ["encode"] = GetEncode(link) or 0,
          ["name"] = GetItemLinkName(link),
          ["quality"] = GetString("SI_ITEMQUALITY", GetItemLinkQuality(link)),
          ["icon"] = GetItemLinkIcon(link),
          ["itemTypeText"] = GetString("SI_ITEMTYPE", itemType),
          ["description"] = select(3, GetItemLinkOnUseAbilityInfo(link)),
          ["canBeCrafted"] = false,
        }
        T0[item.id] = T0[item.id] or {}
        T0[item.id][item.encode] = item
      end
    end
  end
  DataExtractor.dataPotions = T0
  d('|cFFFFFFDataExtractor:|r 完工! 药水已抓取 (使用 /scrapesave 指令来保存数据!)')
end