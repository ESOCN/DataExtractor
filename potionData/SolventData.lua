--[[
    溶剂数据 (SolventData.lua)
    由 solvent.json 转换而来
    包含药水溶剂(isPoison=false)和毒药溶剂(isPoison=true)
    internalLevel 和 internalType 用于构造物品链接
]]

DataExtractor.SolventList = {
    -- ===== 药水溶剂 (isPoison = false) =====
    [1]  = { name = "天然水",     level = 3,  itemId = 883,   internalLevel = 3,  internalType = 30,  isPoison = false },
    [2]  = { name = "清水",       level = 10, itemId = 1187,  internalLevel = 10, internalType = 30,  isPoison = false },
    [3]  = { name = "纯净水",     level = 20, itemId = 4570,  internalLevel = 20, internalType = 30,  isPoison = false },
    [4]  = { name = "净化水",     level = 30, itemId = 23265, internalLevel = 30, internalType = 30,  isPoison = false },
    [5]  = { name = "过滤水",     level = 40, itemId = 23266, internalLevel = 40, internalType = 30,  isPoison = false },
    [6]  = { name = "纯化水",     level = 51, itemId = 23267, internalLevel = 50, internalType = 125, isPoison = false },
    [7]  = { name = "云雾溶剂",   level = 55, itemId = 23268, internalLevel = 50, internalType = 129, isPoison = false },
    [8]  = { name = "星露",       level = 60, itemId = 64500, internalLevel = 50, internalType = 134, isPoison = false },
    [9]  = { name = "洛克汗之泪", level = 65, itemId = 64501, internalLevel = 50, internalType = 308, isPoison = false },

    -- ===== 毒药溶剂 (isPoison = true) =====
    [10] = { name = "油脂",       level = 3,  itemId = 75357, internalLevel = 3,  internalType = 30,  isPoison = true },
    [11] = { name = "脓血",       level = 10, itemId = 75358, internalLevel = 10, internalType = 30,  isPoison = true },
    [12] = { name = "黏液",       level = 20, itemId = 75359, internalLevel = 20, internalType = 30,  isPoison = true },
    [13] = { name = "胆汁",       level = 30, itemId = 75360, internalLevel = 30, internalType = 30,  isPoison = true },
    [14] = { name = "松节油",     level = 40, itemId = 75361, internalLevel = 40, internalType = 30,  isPoison = true },
    [15] = { name = "漆黑胆汁",   level = 51, itemId = 75362, internalLevel = 50, internalType = 125, isPoison = true },
    [16] = { name = "焦油",       level = 55, itemId = 75363, internalLevel = 50, internalType = 129, isPoison = true },
    [17] = { name = "夜油",       level = 60, itemId = 75364, internalLevel = 50, internalType = 134, isPoison = true },
    [18] = { name = "万能溶剂",   level = 65, itemId = 75365, internalLevel = 50, internalType = 308, isPoison = true },
}

-- 最高等级的药水溶剂（洛克汗之泪）
DataExtractor.MaxPotionSolvent = DataExtractor.SolventList[9]

-- 最高等级的毒药溶剂（万能溶剂）
DataExtractor.MaxPoisonSolvent = DataExtractor.SolventList[18]
