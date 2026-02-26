-- #，表示该变量可能不存在。

--[[ CP技能
["dataCpSkills"] = {
  [*integer* lineIndex] = {
    ["name"] = *string* lineName,
    ["id"] = *integer* lineId,
    ["index"] = *integer* index,
    ["skills"] = {
      [*integer* skillIndex] = {
        ["name"] = *string* cpSkillName,
        ["id"] = *integer* cpSkillId,
        ["index"] = *integer* index,
        ["type"] = *integer* cpSkillType,
        ["description"] = *string* cpSkillDescription,
        ["clusterName"] = *string* clusterName,
        ["isInCluster"] = *bool*,
        ["isSlottable"] = *bool*,
        ["bounsText"] = {
          [*integer* jumpPoints] = *string* bonesText,
          ...
        }
      },
      ...
    }
  },
  ...
}
]]

--[[ 技能
["dataSkills"] = {
  ["scriptList"] = {
    [*integer* scriptIndex] = {
      ["id"] = *integer* scriptId,
      ["name"] = *string* scriptName,
      ["description"] = *string* scriptDescription,
      ["icon"] = *string* iconPath,
    },
    ...
  },
  [*integer* skillTypeIndex] = {
    ["name"] = *string* skillTypeName,
    [*integer* skillLineIndex] = {
      ["id"] = *integer* skillLineId,
      ["name"] = *string* skillLineName,
      ["skills"] = {
        [*integer* skillIndex] = { 普通技能
          ["passive"] = *bool*,
          ["IsCrafted"] = *bool*,
          ["name"] = *string* skillName,
          ["id"] = *integer* abilityId,
          ["description"] = *string* skillDescription,
          ["earnedRank"] = *integer* earnedLevel,
          ["icon"] = *string* iconPath,
          ["ultimate"] = *bool*,
          ["castTime"] = *integer* castTimeMS,
          ["target"] = *string* targetName,
          ["minRange"] = *integer* rangeCM,
          ["maxRange"] = *integer* rangeCM,
          ["radius"] = *integer* radiusCM,
          ["distance"] = *integer* halfDistanceCM, --AoE技能水平探测范围的一半
          ["duration"] = *integer* durationTimeMS,
          ["powerTypes"] = { 
            #[*integer* resourceType] = *integer* resourceCost,
            #...
          },
          ["cost"] = *integer* resourceCost,
          ["costPerTick"] = {*integer* resourceCostPerTick, *integer* frequencyMS},
          ["isChanneled"] = *bool*,
          ["isTank"] = *bool*,
          ["isHealer"] = *bool*,
          ["isDamage"] = *bool*,
          
          --主动技能专有字段
          #[1] = { 变体1
            ["parentAbilityId"] = *integer* abilityId,
            ["newEffect"] = *string* effectText,
            ... 与普通技能字段相同
          }
          #[2] = { 变体2}
          
          --被动技能专有字段
          #[*integer* skillLevel] = { 从2级起
            ... 与普通技能字段相同
          }
        },

        [*integer* skillIndex] = { 篆刻技能
          ["IsCrafted"] = *bool*,
          ["name"] = *string* craftedAbilityBasicName,
          ["id"] = *integer* craftedAbilityId,
          ["description"] = *string* craftedAbilityBasicDescription,
          ["icon"] = *string* craftedAbilityIconPath,
          
          [*integer* craftedSkillIndex] = {
            ["parentAbilityId"] = *integer* craftedAbilityId,
            ["scripts"] = {*integer* primaryScriptId, *integer* secondaryScriptId, *integer* tertiaryScriptId},
            ... 与普通技能字段相同
          }
          ...
        },
        ...
      }
    },
    ...
  },
  ...
}
]]

--[[ 药水
["dataPotions"] = {
  [*integer* itemId] = {
    [*integer* encodeId] = {
      ["name"] = *string* itemName,
      ["id"] = *integer* itemId,
      ["encode"] = *integer* encodeId,
      ["itemTypeText"] = *string* itemType,
      ["quality"] = *string* qualityType,
      ["description"] = {
        [*integer* descriptionIndex] = *string* effectDescription,
        ...
      },
      ["icon"] = *string* iconPath,
      ["canBeCrafted"] = *bool*,
      #["recipes"] = {
        [*integer* recipeIndex] = {*string* reagentName, *string* reagentName, #*string* reagentName},
        ...
      }
    },
    ...
  },
  ...
}
]]

--[[ 副本
["dataRaids"] = {
  [*integer* raidIndex] = {
    ["name"] = *string* raidName,
    ["zoneId"] = *integer* raidZoneId,
    ["place"] = {*string* raidZoneName, *string* raidParentZoneName},
    ["type"] = *string* raidtype,
    ["isRequiredDLC"] = *bool*,
    ["achievements"] = {
      #["VET"] = *integer* achievementId,
      #["midHM1"] = *integer* achievementId,
      #["midHM2"] = *integer* achievementId,
      #["HM"] = *integer* achievementId,
      #["SR"] = *integer* achievementId,
      #["ND"] = *integer* achievementId,
      #["fakeTRI"] = *integer* achievementId,
      #["TRI"] = *integer* achievementId,
      #["EX"] = *integer* achievementId,
    },
  },
  ...
}
]]

--[[ 外观样式
["dataStyles"] = {
  [*integer* sytleIndex] = {
    ["name"] = *string* styleName,
    ["id"] = *integer* styleId,
    ["materialName"] = *string* styleMaterialName,
    ["materialId"] = *integer* styleMaterialId,
    ["icon"] = *string* styleMaterialIconPath,
  },
  ...
}
]]

--[[ 成就
["dataAchievs"] = {
  [*integer* categoryIndex] = {
    ["name"] = *string* categoryName,
    ["totalpoints"] = *integer* points,
    [*integer* subCategoryIndex] = {
      ["name"] = *string* subCategoryName,
      [*integer* ahievementId] = {
        ["category"] = *string* categoryName,
        ["subcategory"] = *string* subCategoryName,
        ["name"] = *string* achievementName,
        ["description"] = *string* achievementDescription,
        ["icon"] = *string* iconPath,
        ["points"] = *integer* points,
        #["criterion"] = {
          [*integer* criterionIndex] = *string* criterionText,
          ...
        },
        #["rewards"] = {
          #["dye"] = {
            ["name"] = *string* dyeName,
            ["id"] = *integer* dyeId,
            ["rarity"] = *integer* rarity,
            ["r"] = *number*,
            ["g"] = *number*,
            ["b"] = *number*,
          }
          #["title"] = {["name"] = *string* titleName},
          #["collectible"] = {
            ["name"] = *string* collectibleName,
            ["id"] = *integer* collectibleId,
            ["prefix"] = *string* prefix,
          },
          #["item"] = {
            ["name"] = *string* itemName,
            ["icon"] = *string* iconPath,
            ["quality"] = *integer* quality,
          }
        },
        #["line"] = {
          [*integer* subAhievementId] = {
            ... 与上方成就字段相同
          }
          ...
        },
      }
    },
    ...
  },
  ...
}
]]

--[[ 物品
["dataItems"] = {
  ["CollectibleFurniture"] = {
    [*integer* collectibleID] = {
      ["name"] = *string* collectibleName,
      ["id"] = *integer* collectibleID,
      ["category"] = *string* categoryName,
      ["hint"] = *string* hintText,
      ["description"] = *string* collectibleDescription,
      ["icon"] = *string* iconPath,
      ["furnitureId"] = *integer* furnitureDataId,
    },
    ...
  },
  ["Furniture"] = {
    [*integer* itemId] = {
      ["name"] = *string* furnitureName,
      ["id"] = *integer* itemId,
      ["category"] = *string* categoryName,
      ["subcategory"] = *string* subCategoryName,
      ["quality"] = *string* quality,
      ["description"] = *string* itemDescription,
      ["icon"] = *string* iconPath,
      ["tags"] = *string* tagsText,
    },
    ...
  },
  ["Foods"] = {
    [*integer* itemId] = {
      ["name"] = *string* foodName,
      ["id"] = *integer* itemId,
      ["itemTypeText"] = *string* itemTypeText,
      ["specializedItemTypeText"] = *string* specializedItemTypeText,
      ["quality"] = *string* quality,
      ["description"] = *string* itemDescription,
      ["icon"] = *string* iconPath,
      ["canBeCrafted"] = *bool*,
      ["ingredients"] = *string* ingredients,
    },
    ...
  },
  ["Recipes"] = {
    [*integer* itemId] = {
      ["name"] = *string* recipeName,
      ["id"] = *integer* itemId,
      ["type"] = *string* craftType,
      ["skills"] = *string* requiredCraftSkills,
      ["quality"] = *string* quality,
      ["ingredients"] = *string* ingredients,
    },
    ...
  },
  ["Sets"] = {
    [*integer* setId] = {
      ["name"] = *string* setName,
      ["id"] = *integer* setId,
      ["type"] = *integer* type,
      ["classRestriction"] = *bool*,
      ["categoryName"] = *string* categoryName,
      ["zoneId"] = *integer* zoneId,
      ["place"] = {*string* zoneName, #*string* parentZoneName, #*string* parentParentZoneName},
      #["leads"] = {
        [*integer* leadIndex] = {*string* leadName, *string* digZoneName},
        ...
      }
      ["bonuses"] = {
        [*integer* quality] = { 5 = gold
          [*integer* bonuseIndex] = *string* bonuseText,
          ...
        },
        ...
      },
      ["itemIDs"] = {
        [*integer* itemID] = {*integer* armorType, *integer* equipType, *integer* weaponType},
          armorType   0 无; 1 轻甲; 2 中甲; 3 重甲;
          equipType   1 头部; 4 肩部; 3 胸部; 13 手部; 8 腰部; 9 腿部; 10 脚部;
                      2 项链; 12 戒指;
                      5 单手; 6 双手; 7 盾牌;
          weaponType  单手: 1 斧; 2 锤; 3 剑; 11 匕首;
                      双手: 4 剑; 5 斧; 6 锤;
                      法杖: 9 治疗; 12 火焰; 13 冰霜; 15 闪电;
                      弓: 8
                      盾牌: 14
        ...
      },
      ["styles"] = {
        [*string* itemType] = {
          [*string* equipType] = {
            [*string* specificType] = {
              ["style"] = *string* styleName,
              ["styleId"] = *integer* styleId,
              ["icon"] = *string* iconPath,
            },
            ...
          },
          ...
        },
        ...
      },
    },
    ...
  },
}
]]

-- 初始化全局变量，供所有模块访问。
DataExtractor = {}