local FirebaseService = require(game:GetService("ServerScriptService"):WaitForChild("Firebase"):WaitForChild('FirebaseService'))
local database = FirebaseService:GetFirebase("ACProject");
local triggerGetDataEvent = game:GetService("ServerScriptService"):WaitForChild("Firebase"):WaitForChild("Events"):WaitForChild("TriggerGetData")
local GetDataEvent = game:GetService("ServerScriptService"):WaitForChild("Firebase"):WaitForChild("Events"):WaitForChild("GetData")
local SetDataEvent = game:GetService("ServerScriptService"):WaitForChild("Firebase"):WaitForChild("Events"):WaitForChild("SetData")

local FirebaseLoadedEvent = game:GetService("ReplicatedStorage"):WaitForChild("LoadingEvents"):WaitForChild("FirebaseDataLoaded")

local gridData = require(game:GetService("ServerScriptService"):WaitForChild("LayoutMap"))

local playerData = {}
local gameData = {}

local function GetGameData()
	local getData = database:GetAsync("GameData")
	if getData == nil then
		return nil
	end
	local decode = game:GetService("HttpService"):JSONDecode(getData)
	return decode
end

game:GetService("Players").PlayerAdded:Connect(function(p)
	local getData = database:GetAsync(p.UserId)
	gameData = GetGameData()
	
	if getData == nil then
		print('No Data!')
		playerData[p] = {
			["GameData"] = gameData,
			["FTPE"] = false,
			["Currency"] = {
				["SoftCurrency"] = 10000,
				["HardCurrency"] = 0,
				["Energy"] = {
					["Amount"] = 50,
					["Time"] = os.time()
				}
			},
			["MapData"] = gridData,
			["Crates"] = {
				["Amount"] = 999,
				["Time"] = os.time()
			},
			["LevelData"] = {
				["Level"] = 10,
				["Exp"] = 0,
				["Rebirth"] = 0
			},
			["Unlocks"] = {
				["GemPurchase"] = {},
				["RebirthUnlocks"] = {},
				["LevelUnlocks"] = {1, 2, 3, 4, 5}
			},
			["Inventory"] = {
				
			}
		}
	elseif getData ~= nil then
		local decode = game:GetService("HttpService"):JSONDecode(getData)
		playerData[p] = decode
		playerData[p]["GameData"] = gameData
	end
	
	FirebaseLoadedEvent:FireClient(p)
end)

local function IsDataLoaded(p)
	if gameData[p] ~= nil then
		FirebaseLoadedEvent:FireClient(p)
	end
end

game:GetService("Players").PlayerRemoving:Connect(function(p)
	
	local sendData = {
		FTPE = playerData[p]["FTPE"],
		Currency = playerData[p]["Currency"],
		MapData = playerData[p]["MapData"],
		Crates = playerData[p]["Crates"],
		LevelData = playerData[p]["LevelData"],
		Unlocks = playerData[p]["Unlocks"],
		Inventory = playerData[p]["Inventory"]
	}
	database:SetAsync(p.UserId, game.HttpService:JSONEncode(sendData))
	playerData[p] = nil	
	print('Data saved.')
end)

triggerGetDataEvent.Event:Connect(function(p, ExtraData)
	local breakout = 20
	while playerData[p] == nil and breakout ~= 0 do
		wait(1)
		breakout -= 1
	end
	
	GetDataEvent:Fire(p, playerData[p], ExtraData)
end)

SetDataEvent.Event:Connect(function(p, name, data)
	playerData[p][name] = data
end)

FirebaseLoadedEvent.OnServerEvent:Connect(IsDataLoaded)
