local toolbar = plugin:CreateToolbar("Map Tools")
local button = toolbar:CreateButton("Export Map", "Generate 2D Array", "rbxassetid://93092767517598")

local tileSize = 4
local moduleName = "MapData2"

-- Table to store color-value mappings
local colorValueMappings = {
	[Color3.fromRGB(239, 184, 56)] = -1,
	[Color3.fromRGB(0, 255, 0)] = 0,
	[Color3.fromRGB(255, 85, 127)] = 0,
	[Color3.fromRGB(255, 85, 0)] = 0,
	[Color3.fromRGB(85, 170, 255)] = -1,
}

-- Function to get the tile value based on color
local function getTileValue(tile)
	if not (tile and tile:IsA("Part")) then return 0 end
	local color = tile.Color

	-- Check if the color exists in the mappings
	for col, val in pairs(colorValueMappings) do
		if col == color then
			return val
		end
	end

	return 0 -- Default to walkable
end

-- Function to generate the map data
local function generateMapData()
	local map = workspace:FindFirstChild("Map")
	if not map then
		warn("No 'Map' model found in Workspace!")
		return
	end

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

	-- Calculate grid dimensions
	local gridWidth = math.ceil((maxX - minX) / tileSize) + 1
	local gridHeight = math.ceil((maxZ - minZ) / tileSize) + 1

	-- Preprocess tiles into a dictionary
	local tileDict = {}
	for _, tile in pairs(map:GetChildren()) do
		if tile:IsA("Part") then
			local gridX = math.round((tile.Position.X - minX) / tileSize) + 1
			local gridZ = math.round((tile.Position.Z - minZ) / tileSize) + 1
			tileDict[gridX .. "," .. gridZ] = tile
			tile.Name = gridX .. "," .. gridZ
			
			for _, v in pairs(tile:GetChildren()) do
				v:Destroy()
			end
			
			if tile:FindFirstChild("GridPositon") == nil then
				local gridPosition = Instance.new("Vector3Value", tile)
				gridPosition.Parent = tile
				gridPosition.Name = "GridPosition"
				gridPosition.Value = Vector3.new(gridX, gridZ, 0)
				continue
			end
			
			tile:FindFirstChild("GridPosition").Value = Vector3.new(gridX, gridZ, 0)
			print("Test")
		end
	end

	-- Build 2D array
	local mapArray = {}
	for z = 1, gridHeight do
		local row = {}
		for x = 1, gridWidth do
			local tile = tileDict[x .. "," .. z]
			table.insert(row, getTileValue(tile))
		end
		table.insert(mapArray, row)
	end

	return mapArray
end

-- Function to convert the array to a module string
local function arrayToModuleString(array)
	local result = "return {\n"
	for _, row in ipairs(array) do
		result = result .. "    {" .. table.concat(row, ", ") .. "},\n"
	end
	result = result .. "}"
	return result
end

-- Function to write the map data to a ModuleScript
local function writeToModuleScript()
	local ServerStorage = game:GetService("ServerStorage")
	local existingModule = ServerStorage:FindFirstChild(moduleName)

	if not existingModule then
		existingModule = Instance.new("ModuleScript")
		existingModule.Name = moduleName
		existingModule.Parent = ServerStorage
	end

	local mapData = generateMapData()
	if not mapData then return end

	existingModule.Source = arrayToModuleString(mapData)
	print("Map data successfully exported to " .. moduleName)
end

-- Function to create the GUI
local function createGUI()
	local widget = plugin:CreateDockWidgetPluginGui(
		"ColorValueSettings",
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
	widget.Title = "Color-Value Settings"
	widget.Name = "ColorValueSettingsWidget" -- Unique name for the widget
	widget.Enabled = true -- Ensure the widget is enabled

	-- Create a ScrollingFrame to hold the UI elements
	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Size = UDim2.new(1, 0, 1, -40) -- Leave space for the Generate button
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
	scrollingFrame.ScrollBarThickness = 8
	scrollingFrame.Parent = widget

	-- Create a UIListLayout to organize the elements
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Padding = UDim.new(0, 5)
	uiListLayout.Parent = scrollingFrame

	-- Function to add a new color-value pair
	local function addColorValuePair(color, value)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, -10, 0, 30)
		frame.BackgroundTransparency = 1
		frame.Parent = scrollingFrame

		-- ColorPicker
		local colorPicker = Instance.new("TextButton")
		colorPicker.Size = UDim2.new(0.5, -5, 1, 0)
		colorPicker.Position = UDim2.new(0, 0, 0, 0)
		colorPicker.BackgroundColor3 = color
		colorPicker.Text = "Pick Color"
		colorPicker.Parent = frame

		-- TextBox for value
		local valueBox = Instance.new("TextBox")
		valueBox.Size = UDim2.new(0.5, -5, 1, 0)
		valueBox.Position = UDim2.new(0.5, 5, 0, 0)
		valueBox.Text = tostring(value)
		valueBox.Parent = frame

		-- Update the colorValueMappings table when the value changes
		valueBox:GetPropertyChangedSignal("Text"):Connect(function()
			local newValue = tonumber(valueBox.Text)
			if newValue then
				colorValueMappings[color] = newValue
			end
		end)

		-- Custom color picker
		colorPicker.MouseButton1Click:Connect(function()
			-- Create a popup GUI for color selection
			local popup = Instance.new("Frame")
			popup.Size = UDim2.new(0, 200, 0, 150)
			popup.Position = UDim2.new(0.5, -100, 0.5, -75)
			popup.BackgroundColor3 = Color3.new(1, 1, 1)
			popup.BorderSizePixel = 1
			popup.Parent = widget

			-- Create a color picker using TextBoxes for RGB values
			local redBox = Instance.new("TextBox")
			redBox.Size = UDim2.new(0.8, 0, 0, 30)
			redBox.Position = UDim2.new(0.1, 0, 0.1, 0)
			redBox.Text = "Red (0-255)"
			redBox.Parent = popup

			local greenBox = Instance.new("TextBox")
			greenBox.Size = UDim2.new(0.8, 0, 0, 30)
			greenBox.Position = UDim2.new(0.1, 0, 0.4, 0)
			greenBox.Text = "Green (0-255)"
			greenBox.Parent = popup

			local blueBox = Instance.new("TextBox")
			blueBox.Size = UDim2.new(0.8, 0, 0, 30)
			blueBox.Position = UDim2.new(0.1, 0, 0.7, 0)
			blueBox.Text = "Blue (0-255)"
			blueBox.Parent = popup

			-- Apply button
			local applyButton = Instance.new("TextButton")
			applyButton.Size = UDim2.new(0.8, 0, 0, 30)
			applyButton.Position = UDim2.new(0.1, 0, 0.9, 0)
			applyButton.Text = "Apply"
			applyButton.Parent = popup

			applyButton.MouseButton1Click:Connect(function()
				local r = tonumber(redBox.Text) or 0
				local g = tonumber(greenBox.Text) or 0
				local b = tonumber(blueBox.Text) or 0

				-- Clamp RGB values to 0-255
				r = math.clamp(r, 0, 255)
				g = math.clamp(g, 0, 255)
				b = math.clamp(b, 0, 255)

				-- Update the color
				local newColor = Color3.fromRGB(r, g, b)
				colorPicker.BackgroundColor3 = newColor
				colorValueMappings[newColor] = colorValueMappings[color]
				colorValueMappings[color] = nil
				color = newColor

				-- Close the popup
				popup:Destroy()
			end)
		end)
	end

	-- Add existing color-value pairs to the GUI
	for color, value in pairs(colorValueMappings) do
		addColorValuePair(color, value)
	end

	-- Add a button to add new color-value pairs
	local addButton = Instance.new("TextButton")
	addButton.Size = UDim2.new(1, -10, 0, 30)
	addButton.Position = UDim2.new(0, 5, 0, 0)
	addButton.Text = "Add New Color-Value Pair"
	addButton.Parent = scrollingFrame

	addButton.MouseButton1Click:Connect(function()
		addColorValuePair(Color3.new(1, 1, 1), 0) -- Default: White, value 0
	end)

	-- Update the ScrollingFrame's CanvasSize based on the UIListLayout
	uiListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, uiListLayout.AbsoluteContentSize.Y)
	end)

	-- Add a Generate File button at the bottom
	local generateButton = Instance.new("TextButton")
	generateButton.Size = UDim2.new(1, -10, 0, 30)
	generateButton.Position = UDim2.new(0, 5, 1, -35)
	generateButton.Text = "Generate File"
	generateButton.Parent = widget

	generateButton.MouseButton1Click:Connect(function()
		writeToModuleScript()
	end)

	return widget
end

-- Create the GUI when the plugin starts
local widget = createGUI()
widget.Enabled = false

-- Toggle the GUI visibility when the toolbar button is clicked
button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)