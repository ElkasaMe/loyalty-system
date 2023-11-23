function GetPlayerLoyalPoints(player)
    local accountId = player:GetAccountId()
    local query = AuthDBQuery("SELECT balance_loyal_point FROM player_points WHERE account_id = " .. accountId)

    if query then
        local balance = query:GetUInt32(0)
        print("Извлеченный баланс из БД: " .. balance)
        return balance
    else
        return 0
    end
end


function AddOneLoyalPoint(player)
    local accountId = player:GetAccountId()
    local currentBalance = GetPlayerLoyalPoints(player)
    local newBalance = currentBalance + 1
    AuthDBQuery("UPDATE player_points SET balance_loyal_point = " .. newBalance .. " WHERE account_id = " .. accountId)
end


local function AddHourlyLoyalPoints()
    local onlinePlayers = GetPlayersInWorld()

    for _, player in pairs(onlinePlayers) do
        local accountId = player:GetAccountId()
        local lastCheckTime = player:GetData("lastHourlyCheck") or 0
        local currentTime = os.time()

        if currentTime - lastCheckTime >= 3600 then
            local query = CharDBQuery("SELECT totaltime FROM characters WHERE guid = " .. player:GetGUIDLow())
            if query then
                local totalTime = query:GetUInt32(0)
                local hoursPlayed = math.floor(totalTime / 3600)

                if hoursPlayed > lastCheckTime then
                    -- Начисление очка за каждый час игрового времени
                     local currentPoints = GetPlayerLoyalPoints(player)
					 UpdatePlayerLoyalPoints(player, currentPoints + 1)
                    player:SendBroadcastMessage("Вам начислено 1 очко лояльности за игровое время.")
					AddOneLoyalPoint(player)
                end
            end

            player:SetData("lastHourlyCheck", hoursPlayed)
        end
    end
end

-- Вызов функции AddHourlyLoyalPoints каждый час
CreateLuaEvent(AddHourlyLoyalPoints, 3600000, 0)  -- 3600000 мс = 1 час


function AddLoyalPointsForTotalTime(player)
    local accountId = player:GetAccountId()
    local totalTimeQuery = CharDBQuery("SELECT SUM(totaltime) FROM characters WHERE account = " .. accountId)
    local totalTime = 0

    if totalTimeQuery then
        totalTime = totalTimeQuery:GetUInt32(0)
    end

    -- Рассчитываем очки (1 час = 1 очко)
    local pointsToAdd = math.floor(totalTime / 3600)

    -- Проверяем, существует ли запись в player_points
    local existQuery = AuthDBQuery("SELECT 1 FROM player_points WHERE account_id = " .. accountId)
    if not existQuery then
        -- Если запись не существует, создаем новую с начальными значениями
        AuthDBQuery("INSERT INTO player_points (account_id, balance_loyal_point, balance_donate_point, all_player_points_reward) VALUES (" .. accountId .. ", 0, 0, 0)")
    end

    -- Проверяем, были ли уже начислены очки
    local rewardQuery = AuthDBQuery("SELECT all_player_points_reward FROM player_points WHERE account_id = " .. accountId)
    if rewardQuery and rewardQuery:GetUInt32(0) == 0 then
        -- Обновляем баланс и устанавливаем all_player_points_reward в 1
        AuthDBQuery("UPDATE player_points SET balance_loyal_point = balance_loyal_point + " .. pointsToAdd .. ", all_player_points_reward = 1 WHERE account_id = " .. accountId)
        player:SendBroadcastMessage("Вам начислено " .. pointsToAdd .. " поинтов за игровое время.")
    end
end




function UpdatePlayerLoyalPoints(player, newBalance)
    local accountId = player:GetAccountId()
    -- Запрос на получение текущих значений других полей
    local query = AuthDBQuery("SELECT balance_donate_point, all_player_points_reward FROM player_points WHERE account_id = " .. accountId)
    if query then
        local donatePoints = query:GetUInt32(0)
        local allPlayerPointsReward = query:GetUInt32(1)

    end
end

function ProcessPurchase(player, cost)
    local accountId = player:GetAccountId()
    local currentBalance = GetPlayerLoyalPoints(player)

    if currentBalance < cost then
        player:SendBroadcastMessage("Недостаточно очков лояльности для совершения покупки.")
        return false
    end

    local newBalance = currentBalance - cost
    AuthDBQuery("UPDATE player_points SET balance_loyal_point = " .. newBalance .. " WHERE account_id = " .. accountId)
    return true
end



local function ChangeName(player)
    -- Проверяем, мертв ли игрок
    if player:IsDead() then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, будучи мертвым.")
        return
    end

    -- Проверяем, находится ли игрок в бою
    if player:IsInCombat() then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, будучи в бою.")
        return
    end

    local cost = 5  -- Стоимость смены имени
    local success = ProcessPurchase(player, cost)

    if success then
        player:SetAtLoginFlag(1)
        player:SendBroadcastMessage("Успешная покупка! Вы сможете сменить имя при следующем входе в игру.")
    end
end


local function ChangeFaction(player)

		-- Проверяем, есть ли GUID персонажа в столбце loser_guid таблицы duel_statistics
    local accountId = player:GetAccountId()
    local characterGuid = player:GetGUIDLow()
    local duelQuery = CharDBQuery("SELECT loser_guid FROM duel_statistics WHERE loser_guid = " .. characterGuid)
    
    if duelQuery then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, так как ваш персонаж проиграл Мак'Гора!")
        return
    end
		
    -- Проверяем, мертв ли игрок
    if player:IsDead() then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, будучи мертвым.")
        return
    end

    -- Проверяем, находится ли игрок в бою
    if player:IsInCombat() then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, будучи в бою.")
        return
    end

    local cost = 10  -- Стоимость смены имени
    local success = ProcessPurchase(player, cost)

    if success then
        player:SetAtLoginFlag(64)
        player:SendBroadcastMessage("Успешная покупка! Вы сможете сменить фракцию при следующем входе в игру.")
    end
end


local function ChangeLevel(player)

		-- Проверяем, есть ли GUID персонажа в столбце loser_guid таблицы duel_statistics
    local accountId = player:GetAccountId()
    local characterGuid = player:GetGUIDLow()
    local duelQuery = CharDBQuery("SELECT loser_guid FROM duel_statistics WHERE loser_guid = " .. characterGuid)
    
    if duelQuery then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, так как ваш персонаж проиграл Мак'Гора!")
        return
    end
		
    -- Проверяем, мертв ли игрок
    if player:IsDead() then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, будучи мертвым.")
        return
    end

    -- Проверяем, находится ли игрок в бою
    if player:IsInCombat() then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, будучи в бою.")
        return
    end
	-- Проверяем на хк режим
	if player:HasAura(36945) then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, будучи в Хардкор режиме")
        return
    end

    local cost = 35  -- Стоимость смены имени
    local success = ProcessPurchase(player, cost)

if success then
        local currentLevel = player:GetLevel()
        player:SetLevel(currentLevel + 1)  -- Увеличиваем текущий уровень на 1
        player:SendBroadcastMessage("Успешная покупка! Ваш уровень увеличен на 1.")
    end
end



local function ChangeRace(player)
		-- Проверяем, есть ли GUID персонажа в столбце loser_guid таблицы duel_statistics
    local accountId = player:GetAccountId()
    local characterGuid = player:GetGUIDLow()
    local duelQuery = CharDBQuery("SELECT loser_guid FROM duel_statistics WHERE loser_guid = " .. characterGuid)
    
    if duelQuery then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, так как ваш персонаж проиграл Мак'Гора!")
        return
    end


    -- Проверяем, мертв ли игрок
    if player:IsDead() then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, будучи мертвым.")
        return
    end

    -- Проверяем, находится ли игрок в бою
    if player:IsInCombat() then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, будучи в бою.")
        return
    end

    local cost = 5  -- Стоимость смены имени
    local success = ProcessPurchase(player, cost)

    if success then
        player:SetAtLoginFlag(128)
        player:SendBroadcastMessage("Успешная покупка! Вы сможете сменить расу при следующем входе в игру.")
    end
end

local function ChangeCosmetic(player)
	-- Проверяем, есть ли GUID персонажа в столбце loser_guid таблицы duel_statistics
    local accountId = player:GetAccountId()
    local characterGuid = player:GetGUIDLow()
    local duelQuery = CharDBQuery("SELECT loser_guid FROM duel_statistics WHERE loser_guid = " .. characterGuid)
    
    if duelQuery then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, так как ваш персонаж проиграл Мак'Гора!")
        return
    end


    -- Проверяем, мертв ли игрок
    if player:IsDead() then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, будучи мертвым.")
        return
    end

    -- Проверяем, находится ли игрок в бою
    if player:IsInCombat() then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, будучи в бою.")
        return
    end

    local cost = 5  -- Стоимость смены имени
    local success = ProcessPurchase(player, cost)

    if success then
        player:SetAtLoginFlag(128)
        player:SendBroadcastMessage("Успешная покупка! Вы сможете сменить внешность при следующем входе в игру.")
    end
end


local function TeleHome(player)
    -- Проверяем, мертв ли игрок
    if player:IsDead() then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, будучи мертвым.")
        return
    end

    -- Проверяем, находится ли игрок в бою
    if player:IsInCombat() then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, будучи в бою.")
        return
    end

    local cost = 3  -- Стоимость телепортации

    -- Проверяем, есть ли GUID персонажа в столбце loser_guid таблицы duel_statistics
    local accountId = player:GetAccountId()
    local characterGuid = player:GetGUIDLow()
    local duelQuery = CharDBQuery("SELECT loser_guid FROM duel_statistics WHERE loser_guid = " .. characterGuid)
    
    if duelQuery then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, так как ваш персонаж проиграл Мак'Гора!")
        return
    end

    -- Если проверки пройдены успешно, телепортируем игрока
    local race = player:GetRace()
    player:SendBroadcastMessage("Ваша раса: " .. race)  -- Отправляем результат в чат
    if race == 1 or race == 3 or race == 4 or race == 7 or race == 11 then
        player:Teleport(0, -8913.23, 554.633, 94.7944, 0)
    else
        player:Teleport(1, 1629.849976, -4373.640137, 31.557262, 3.697620)
    end

    -- Вычитаем стоимость телепортации из баланса
    local success = ProcessPurchase(player, cost)

    if success then
        player:SendBroadcastMessage("Успешная покупка! Вы телепортированы по ХС.")
    end
end




local function ChangeDebuff(player)
    -- Проверяем, мертв ли игрок
    if player:IsDead() then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, будучи мертвым.")
        return
    end

    -- Проверяем, находится ли игрок в бою
    if player:IsInCombat() then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, будучи в бою.")
        return
    end
	
	-- Проверяем, есть ли GUID персонажа в столбце loser_guid таблицы duel_statistics
    local accountId = player:GetAccountId()
    local characterGuid = player:GetGUIDLow()
    local duelQuery = CharDBQuery("SELECT loser_guid FROM duel_statistics WHERE loser_guid = " .. characterGuid)
    
    if duelQuery then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, так как ваш персонаж проиграл Мак'Гора!")
        return
    end

    local cost = 2  -- Стоимость смены имени
    local success = ProcessPurchase(player, cost)

    if success then
        player:RemoveAura(15007)
        player:SendBroadcastMessage("Успешная покупка! Маска слабости была удалена!")
    end
end

local function ChangeRev(player)
    -- Проверяем, мертв ли игрок
    if not player:IsDead() then
        player:SendBroadcastMessage("Эту функцию можно использовать только будучи мертвым.")
        return
    end
	
	-- Проверяем, есть ли GUID персонажа в столбце loser_guid таблицы duel_statistics
    local accountId = player:GetAccountId()
    local characterGuid = player:GetGUIDLow()
    local duelQuery = CharDBQuery("SELECT loser_guid FROM duel_statistics WHERE loser_guid = " .. characterGuid)
    
    if duelQuery then
        player:SendBroadcastMessage("Вы не можете использовать эту функцию, так как ваш персонаж проиграл Мак'Гора!")
        return
    end

    local cost = 3  -- Стоимость удаления маски смерти
    local success = ProcessPurchase(player, cost)

    if success then
        player:ResurrectPlayer()  -- Воскрешаем игрока
        player:SendBroadcastMessage("Успешная покупка! Вы воскрешены!")
    end
end

local function OnPlayerLevelUp(event, player, oldLevel)
    local newLevel = player:GetLevel()
    
    if newLevel % 5 == 0 then -- Проверяем, делится ли уровень на 5 без остатка
        local currentPoints = GetPlayerLoyalPoints(player)
        UpdatePlayerLoyalPoints(player, currentPoints + 1)
		player:SendBroadcastMessage("|cFFFF0000BladeFall:|r |cFF00FF00Поздравляем с достижением уровня " .. newLevel .. "! Вам начислено 1 дополнительное очко лояльности.|r")
		AddOneLoyalPoint(player)
    end
end


local function MenuCommand(event, player, command)
    if command == "menu" then
        local loyalPoints = GetPlayerLoyalPoints(player)
        player:GossipClearMenu()
        player:GossipMenuAddItem(1, "Баланс: " .. loyalPoints .. " поинтов", 1, 1)
        player:GossipMenuAddItem(0, "Сменить имя: 10 поинтов", 1, 2)
        player:GossipMenuAddItem(0, "Сменить фракцию: 15 поинтов", 1, 3)
        player:GossipMenuAddItem(0, "Сменить расу: 5 поинтов", 1, 4)
        player:GossipMenuAddItem(0, "Сменить пол: 5 поинтов", 1, 5)
        player:GossipMenuAddItem(0, "Воскреснуть: 3 поинта", 1, 6)
		player:GossipMenuAddItem(0, "Телепорт в столицу: 3 поинта", 1, 7)
        player:GossipMenuAddItem(0, "Снять маску смерти: 2 поинта", 1, 8)
        player:GossipMenuAddItem(0, "Повысить уровень на 1: 35 поинтов", 1, 10)
        player:GossipMenuAddItem(4, "Ввести промокод:", 1, 9)
        player:GossipSendMenu(1, player, 1000)
        return false
    end
end

local function OnGossipSelect(event, player, object, sender, intid, code, menuid)
    if intid == 2 then -- Смена имени
        ChangeName(player)
        player:GossipComplete()
    elseif intid == 3 then 
		ChangeFaction(player)
		player:GossipComplete()
	elseif intid == 4 then 
		ChangeRace(player)
		player:GossipComplete()
	elseif intid == 5 then 
		ChangeCosmetic(player)
		player:GossipComplete()
	elseif intid == 6 then 
		ChangeRev(player)
		player:GossipComplete()
	elseif intid == 7 then 
		TeleHome(player)
	elseif intid == 8 then
		ChangeDebuff(player)
		player:GossipComplete()
	elseif intid == 9 then
		player:GossipMenuAddItem(0, "Введите промокод:", 1, 400, true) -- Добавляем codebox
		player:GossipSendMenu(1, player, 1000) -- Где 1000 - это номер вашего интерфейсного меню
	elseif (intid == 400) then -- обработка ввода промокода
    local characterId = player:GetGUIDLow() -- Получаем ID персонажа
    local promoCodeQuery = CharDBQuery("SELECT item_reward, uses_left, gold_reward, loyalty_points_reward, reward_type FROM characters_promocode WHERE code = '" .. code .. "' AND uses_left > 0")
    local usedPromoQuery = CharDBQuery("SELECT * FROM character_used_promocodes WHERE character_id = " .. characterId .. " AND promo_code = '" .. code .. "'")

		if promoCodeQuery and not usedPromoQuery then
        -- Добавляем запись о том, что персонаж использовал промокод
        CharDBQuery("INSERT INTO character_used_promocodes (character_id, promo_code) VALUES (" .. characterId .. ", '" .. code .. "')")

        local itemReward = promoCodeQuery:GetUInt32(0)
        local usesLeft = promoCodeQuery:GetUInt32(1) - 1
        local goldReward = promoCodeQuery:GetUInt32(2)
        local loyaltyPoints = promoCodeQuery:GetUInt32(3)
        local rewardType = promoCodeQuery:GetString(4)

        if rewardType == "item" then
            player:AddItem(itemReward, 1)
        elseif rewardType == "gold" then
            player:ModifyMoney(goldReward)
        elseif rewardType == "loyalty_points" then
            -- Здесь добавляем бонусные очки лояльности к счету игрока
            -- Пример запроса, который нужно адаптировать к вашей системе
            AuthDBQuery("UPDATE player_points SET balance_loyal_point = balance_loyal_point + " .. loyaltyPoints .. " WHERE account_id = " .. player:GetAccountId())
        end

        CharDBQuery("UPDATE characters_promocode SET uses_left = " .. usesLeft .. " WHERE code = '" .. code .. "'")
        player:SendBroadcastMessage("|cff00ff00BladeFall|r: |cffffffffПромокод использован успешно!|r")
    else
        player:SendBroadcastMessage("|cff00ff00BladeFall|r: |cffff0000Вы уже использовали этот промокод!|r")
    end
		player:GossipComplete()
	elseif intid == 10 then
	ChangeLevel(player)
		player:GossipComplete()
	end
end




local function OnPlayerLogin(event, player)
    AddLoyalPointsForTotalTime(player)
end

RegisterPlayerEvent(42, MenuCommand)
RegisterPlayerGossipEvent(1000, 2, OnGossipSelect)
RegisterPlayerEvent(3, OnPlayerLogin)
RegisterPlayerEvent(13, OnPlayerLevelUp) -- 13 - это идентификатор события повышения уровня

