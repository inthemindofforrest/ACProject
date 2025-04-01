local toolbar = plugin:CreateToolbar("Unlock Tools")
local button = toolbar:CreateButton("Export Unlocks", "Generate Unlock Data", "rbxassetid://93092767517598")

local moduleName = "UnlockData2"
local tileSize = 4 -- Adjust this based on your grid size

-- Function to get the unlock type and value from the text
local function getUnlockData(text)
	if tonumber(text) then
		print("[DEBUG] Found LevelUnlock with value:", text)
		return "LevelUnlocks", tonumber(text)
	elseif text:sub(1, 1) == "g" then
		print("[DEBUG] Found GemPurchase with value:", text:sub(2))
		return "GemPurchase", tonumber(text:sub(2))
	elseif text:sub(1, 1) == "r" then
		print("[DEBUG] Found RebirthUnlock with value:", text:sub(2))
		return "RebirthUnlocks", tonumber(text:sub(2))
	else
		print("[DEBUG] Invalid unlock text:", text)
		return nil, nil
	end
end

-- Function to calculate grid position based on world position
local function calculateGridPosition(position, minX, minZ)
	local gridX = math.round((position.X - minX) / tileSize) + 1
	local gridY = math.round((position.Z - minZ) / tileSize) + 1
	return gridX, gridY
end

-- Function to generate the unlock data
local function generateUnlockData()
	local map = workspace:FindFirstChild("MapLevels")
	if not map then
		warn("[ERROR] No 'MapLevels' model found in Workspace!")
		return
	end

	print("[DEBUG] Starting to generate unlock data...")

	-- Calculate grid bounds
	local minX, minZ = math.huge, math.huge
	local maxX, maxZ = -math.huge, -math.huge

	for _, tile in pairs(map:GetChildren()) do
		if tile:IsA("Part") then
			local pos = tile.Position
			minX = math.min(minX, pos.X)
			minZ = math.min(minZ, pos.Z)
			maxX = math.max(maxX, pos.X)
			maxZ = math.max(maxZ, pos.Z)
		end
	end

	print("[DEBUG] Grid bounds - minX:", minX, "minZ:", minZ, "maxX:", maxX, "maxZ:", maxZ)

	local LevelUnlocks = {}
	local RebirthUnlocks = {}
	local GemPurchase = {}
	local OverallCategory = {} -- New: Maps grid positions to their unlock type and value

	for _, tile in pairs(map:GetChildren()) do
		if tile:IsA("Part") and tile:FindFirstChild("Level") then
			local surfaceGui = tile:FindFirstChild("Level")
			local textBox = surfaceGui:FindFirstChildOfClass("TextLabel")
			if textBox then
				local text = textBox.Text
				print("[DEBUG] Processing tile at position:", tile.Position, "with text:", text)

				local unlockType, value = getUnlockData(text)
				if unlockType and value then
					local gridX, gridY = calculateGridPosition(tile.Position, minX, minZ)
					tile.Name = gridX .. "," .. gridY
					print("[DEBUG] Grid position for tile:", gridX, gridY)

					-- Add to the specific unlock table
					if unlockType == "LevelUnlocks" then
						if not LevelUnlocks[value] then
							LevelUnlocks[value] = {}
						end
						table.insert(LevelUnlocks[value], {gridX, gridY})
						print("[DEBUG] Added to LevelUnlocks:", value, "at", gridX, gridY)
					elseif unlockType == "GemPurchase" then
						if not GemPurchase[value] then
							GemPurchase[value] = {}
						end
						table.insert(GemPurchase[value], {gridX, gridY})
						print("[DEBUG] Added to GemPurchase:", value, "at", gridX, gridY)
					elseif unlockType == "RebirthUnlocks" then
						if not RebirthUnlocks[value] then
							RebirthUnlocks[value] = {}
						end
						table.insert(RebirthUnlocks[value], {gridX, gridY})
						print("[DEBUG] Added to RebirthUnlocks:", value, "at", gridX, gridY)
					end

					-- Add to the overall category
					OverallCategory[gridX .. "," .. gridY] = {unlockType, value}
					print("[DEBUG] Added to OverallCategory:", unlockType, value, "at", gridX, gridY)
				else
					print("[DEBUG] Skipping tile due to invalid unlock data.")
				end
			else
				print("[DEBUG] Tile has no TextLabel in Level GUI.")
			end
		else
			print("[DEBUG] Skipping non-Part or Part without Level GUI.")
		end
	end

	print("[DEBUG] Finished generating unlock data.")
	return {
		LevelUnlocks = LevelUnlocks,
		RebirthUnlocks = RebirthUnlocks,
		GemPurchase = GemPurchase,
		OverallCategory = OverallCategory -- New: Include the overall category
	}
end

-- Function to convert the unlock data to a module string
local function unlockDataToModuleString(data)
	print("[DEBUG] Converting unlock data to module string...")
	local result = "return {\n"
	result = result .. "    LevelUnlocks = {\n"
	for level, unlocks in pairs(data.LevelUnlocks) do
		result = result .. "        [" .. level .. "] = {\n"
		for _, pos in ipairs(unlocks) do
			result = result .. "            {" .. pos[1] .. ", " .. pos[2] .. "},\n"
		end
		result = result .. "        },\n"
	end
	result = result .. "    },\n"

	result = result .. "    RebirthUnlocks = {\n"
	for rebirth, unlocks in pairs(data.RebirthUnlocks) do
		result = result .. "        [" .. rebirth .. "] = {\n"
		for _, pos in ipairs(unlocks) do
			result = result .. "            {" .. pos[1] .. ", " .. pos[2] .. "},\n"
		end
		result = result .. "        },\n"
	end
	result = result .. "    },\n"

	result = result .. "    GemPurchase = {\n"
	for gem, unlocks in pairs(data.GemPurchase) do
		result = result .. "        [" .. gem .. "] = {\n"
		for _, pos in ipairs(unlocks) do
			result = result .. "            {" .. pos[1] .. ", " .. pos[2] .. "},\n"
		end
		result = result .. "        },\n"
	end
	result = result .. "    },\n"

	-- Add the OverallCategory to the module string
	result = result .. "    OverallCategory = {\n"
	for gridPos, unlockData in pairs(data.OverallCategory) do
		result = result .. "        [\"" .. gridPos .. "\"] = {\"" .. unlockData[1] .. "\", " .. unlockData[2] .. "},\n"
	end
	result = result .. "    },\n"

	result = result .. "}"
	print("[DEBUG] Module string generated.")
	return result
end

-- Function to write the unlock data to a ModuleScript
local function writeToModuleScript()
	print("[DEBUG] Starting to write unlock data to ModuleScript...")
	local ServerStorage = game:GetService("ServerStorage")
	local existingModule = ServerStorage:FindFirstChild(moduleName)

	if not existingModule then
		print("[DEBUG] Creating new ModuleScript:", moduleName)
		existingModule = Instance.new("ModuleScript")
		existingModule.Name = moduleName
		existingModule.Parent = ServerStorage
	else
		print("[DEBUG] Found existing ModuleScript:", moduleName)
	end

	local unlockData = generateUnlockData()
	if not unlockData then
		print("[ERROR] Failed to generate unlock data.")
		return
	end

	existingModule.Source = unlockDataToModuleString(unlockData)
	print("[DEBUG] Unlock data successfully exported to", moduleName)
end

-- Function to create the GUI
local function createGUI()
	print("[DEBUG] Creating GUI...")
	local widget = plugin:CreateDockWidgetPluginGui(
		"UnlockSettings",
		DockWidgetPluginGuiInfo.new(
			Enum.InitialDockState.Float, -- Default dock state
			true, -- Whether the widget is initially enabled
			false, -- Whether the widget should override the previous state
			300, -- Default width
			300, -- Default height
			300, -- Minimum width
			200 -- Minimum height
		)
	)
	widget.Title = "Unlock Settings"
	widget.Name = "UnlockSettingsWidget" -- Unique name for the widget
	widget.Enabled = true -- Ensure the widget is enabled

	-- Add a Generate File button
	local generateButton = Instance.new("TextButton")
	generateButton.Size = UDim2.new(1, -10, 0, 30)
	generateButton.Position = UDim2.new(0, 5, 1, -35)
	generateButton.Text = "Generate File"
	generateButton.Parent = widget

	generateButton.MouseButton1Click:Connect(function()
		print("[DEBUG] Generate File button clicked.")
		writeToModuleScript()
	end)

	print("[DEBUG] GUI created.")
	return widget
end

-- Create the GUI when the plugin starts
print("[DEBUG] Initializing plugin...")
local widget = createGUI()
widget.Enabled = false

-- Toggle the GUI visibility when the toolbar button is clicked
button.Click:Connect(function()
	print("[DEBUG] Toolbar button clicked. Toggling GUI visibility.")
	widget.Enabled = not widget.Enabled
end)