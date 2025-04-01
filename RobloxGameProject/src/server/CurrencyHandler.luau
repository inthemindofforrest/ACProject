local FirebaseService = require(game:GetService("ServerScriptService"):WaitForChild("Firebase"):WaitForChild('FirebaseService'))
local database = FirebaseService:GetFirebase("ACProject");
local triggerGetDataEvent = game:GetService("ServerScriptService"):WaitForChild("Firebase"):WaitForChild("Events"):WaitForChild("TriggerGetData")
local GetDataEvent = game:GetService("ServerScriptService"):WaitForChild("Firebase"):WaitForChild("Events"):WaitForChild("GetData")
local SetDataEvent = game:GetService("ServerScriptService"):WaitForChild("Firebase"):WaitForChild("Events"):WaitForChild("SetData")
local ModifyCurrencyEvent = game:GetService("ServerScriptService"):WaitForChild("Events"):WaitForChild("ModifyCurrency")
local GetCurrencyDataEvent = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("GetCurrencyData")

local ModifyCurrencyEvents = {}

local function ModifyCurrency(p, data, extraData)
	if ModifyCurrencyEvents[p] then
		ModifyCurrencyEvents[p]:Disconnect()
	end
	
	if extraData == nil then
		warn("Currency cannot be modified as extraData is nil")
		return
	end
	
	if extraData["Type"] == nil then
		warn("Currency cannot be modified as the Type is nil")
		return
	end
	
	if extraData["Amount"] == nil then
		warn("Currency cannot be modified as the Amount is nil")
		return
	end
	
	local type = extraData["Type"]
	local amount = extraData["Amount"]
	
	data["Currency"][type] = data["Currency"][type] + amount
	
	SetDataEvent:Fire(p, "Currency", data["Currency"])
	GetCurrencyDataEvent:FireClient(p, data)
end

ModifyCurrencyEvent.Event:Connect(function(p, CurrencyType, CurrencyAmount)
	ModifyCurrencyEvents[p] = GetDataEvent.Event:Connect(ModifyCurrency)
	triggerGetDataEvent:Fire(p, {Type = CurrencyType, Amount = CurrencyAmount})
end)