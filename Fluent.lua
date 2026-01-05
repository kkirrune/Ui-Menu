local Library = {}

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

--// Init
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local NameID = LocalPlayer.Name
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

local utility = {}
function utility:Tween(instance, properties, duration, ...)
	TweenService:Create(instance, TweenInfo.new(duration, ...), properties):Play()
end

--// Simple connection manager (chống connect lặp)
local Connections = {}
local function TrackConnection(key, conn)
	if Connections[key] then
		pcall(function() Connections[key]:Disconnect() end)
	end
	Connections[key] = conn
	return conn
end

--// Settings (FIX)
local SettingToggle = {}
local CONFIG_FILE = "BTConfig.json"

local function LoadConfig()
	pcall(function()
		if not (isfile and isfile(CONFIG_FILE)) then
			if writefile then
				writefile(CONFIG_FILE, HttpService:JSONEncode(SettingToggle))
			end
			return
		end

		local raw = readfile(CONFIG_FILE)
		if type(raw) == "string" and #raw > 0 then
			local ok, decoded = pcall(function()
				return HttpService:JSONDecode(raw)
			end)
			if ok and type(decoded) == "table" then
				SettingToggle = decoded
			end
		end
	end)
end

local function SaveConfig()
	pcall(function()
		if writefile then
			writefile(CONFIG_FILE, HttpService:JSONEncode(SettingToggle))
		end
	end)
end

LoadConfig()

--// Dragify (FIX - mượt, không leak)
local function Dragify(frame, key)
	key = key or ("Dragify_" .. frame:GetDebugId())

	local dragging = false
	local dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	TrackConnection(key, UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			update(input)
		end
	end))
end

--// UI Name
local LibName = tostring(math.random(1, 100)) .. tostring(math.random(1, 50)) .. tostring(math.random(1, 100))

function Library:ToggleUI()
	local g = game.CoreGui:FindFirstChild(LibName)
	if g then
		g.Enabled = not g.Enabled
	end
end

function Library:DestroyGui()
	local g = game.CoreGui:FindFirstChild(LibName)
	if g then
		g:Destroy()
	end
end

function Library:CreateWindow(hubname)
	table.insert(Library, hubname)

	-- destroy previous with same hubname (giữ behavior cũ)
	for _, v in pairs(game.CoreGui:GetChildren()) do
		if v:IsA("ScreenGui") and v.Name == hubname then
			v:Destroy()
		end
	end

	-- Instances:
	local ScreenGui = Instance.new("ScreenGui")
	local Body = Instance.new("Frame")
	local Body_Corner = Instance.new("UICorner")
	local Title_Hub = Instance.new("TextLabel")
	local MInimize_Button = Instance.new("TextButton")
	local Discord = Instance.new("TextButton")
	local UICorner = Instance.new("UICorner")
	local Disc_Logo = Instance.new("ImageLabel")
	local Disc_Title = Instance.new("TextLabel")
	local Server_Time = Instance.new("TextLabel")
	local Server_ID = Instance.new("TextLabel")
	local List_Tile = Instance.new("Frame")
	local Tile_Gradient = Instance.new("UIGradient")

	-- Properties:
	ScreenGui.Name = LibName
	ScreenGui.Parent = game.CoreGui
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	ScreenGui.ResetOnSpawn = false

	-- Ctrl toggle (FIX - không connect lặp)
	TrackConnection("Keybind_ToggleUI", UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.LeftControl then
			Library:ToggleUI()
		end
	end))

	Body.Name = "Body"
	Body.Parent = ScreenGui
	Body.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	Body.BorderSizePixel = 0
	Body.Position = UDim2.new(0.258427024, 0, 0.217948765, 0)
	Body.Size = UDim2.new(0, 600, 0, 350)
	Body.ClipsDescendants = true
	Body.Active = true

	Body_Corner.CornerRadius = UDim.new(0, 5)
	Body_Corner.Name = "Body_Corner"
	Body_Corner.Parent = Body

	Title_Hub.Name = "Title_Hub"
	Title_Hub.Parent = Body
	Title_Hub.BackgroundTransparency = 1
	Title_Hub.BorderSizePixel = 0
	Title_Hub.Position = UDim2.new(0, 5, 0, 0)
	Title_Hub.Size = UDim2.new(0, 558, 0, 30)
	Title_Hub.Font = Enum.Font.SourceSansBold
	Title_Hub.Text = hubname .. " - " .. GameName
	Title_Hub.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title_Hub.TextSize = 15
	Title_Hub.TextXAlignment = Enum.TextXAlignment.Left

	MInimize_Button.Name = "MInimize_Button"
	MInimize_Button.Parent = Body
	MInimize_Button.BackgroundTransparency = 1
	MInimize_Button.BorderSizePixel = 0
	MInimize_Button.Position = UDim2.new(0, 570, 0, 0)
	MInimize_Button.Rotation = -315
	MInimize_Button.Size = UDim2.new(0, 30, 0, 30)
	MInimize_Button.AutoButtonColor = false
	MInimize_Button.Font = Enum.Font.SourceSans
	MInimize_Button.Text = "+"
	MInimize_Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	MInimize_Button.TextSize = 40
	MInimize_Button.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)

	Discord.Name = "Discord"
	Discord.Parent = Body
	Discord.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	Discord.BorderSizePixel = 0
	Discord.Position = UDim2.new(0, 5, 0, 320)
	Discord.Size = UDim2.new(0, 85, 0, 25)
	Discord.AutoButtonColor = false
	Discord.Font = Enum.Font.SourceSans
	Discord.Text = ""
	Discord.TextSize = 14

	UICorner.CornerRadius = UDim.new(0, 5)
	UICorner.Parent = Discord

	Disc_Logo.Name = "Disc_Logo"
	Disc_Logo.Parent = Discord
	Disc_Logo.BackgroundTransparency = 1
	Disc_Logo.BorderSizePixel = 0
	Disc_Logo.Position = UDim2.new(0, 5, 0, 1)
	Disc_Logo.Size = UDim2.new(0, 23, 0, 23)
	Disc_Logo.Image = "http://www.roblox.com/asset/?id=12058969086"

	Disc_Title.Name = "Disc_Title"
	Disc_Title.Parent = Discord
	Disc_Title.BackgroundTransparency = 1
	Disc_Title.BorderSizePixel = 0
	Disc_Title.Position = UDim2.new(0, 35, 0, 0)
	Disc_Title.Size = UDim2.new(0, 40, 0, 25)
	Disc_Title.Font = Enum.Font.SourceSansSemibold
	Disc_Title.Text = "Discord"
	Disc_Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Disc_Title.TextSize = 14
	Disc_Title.TextXAlignment = Enum.TextXAlignment.Left

	Discord.MouseEnter:Connect(function()
		utility:Tween(Discord, { BackgroundColor3 = Color3.fromRGB(30, 30, 30) }, .15)
		utility:Tween(Disc_Logo, { ImageTransparency = 0.7 }, .15)
		utility:Tween(Disc_Title, { TextTransparency = 0.7 }, .15)
	end)

	Discord.MouseLeave:Connect(function()
		utility:Tween(Discord, { BackgroundColor3 = Color3.fromRGB(40, 40, 40) }, .15)
		utility:Tween(Disc_Logo, { ImageTransparency = 0 }, .15)
		utility:Tween(Disc_Title, { TextTransparency = 0 }, .15)
	end)

	Discord.MouseButton1Click:Connect(function()
		(setclipboard or toclipboard)("https://discord.gg/AkDgH65MUF")
		task.wait(.1)
		StarterGui:SetCore("SendNotification", {
			Title = "Discord",
			Text = "Đã Copy Link Discord",
			Button1 = "Okay",
			Duration = 20
		})
	end)

	Server_Time.Name = "Server_Time"
	Server_Time.Parent = Body
	Server_Time.BackgroundTransparency = 1
	Server_Time.BorderSizePixel = 0
	Server_Time.Position = UDim2.new(0, 100, 0, 320)
	Server_Time.Size = UDim2.new(0, 140, 0, 25)
	Server_Time.Font = Enum.Font.SourceSansSemibold
	Server_Time.Text = ""
	Server_Time.TextColor3 = Color3.fromRGB(255, 255, 255)
	Server_Time.TextSize = 14
	Server_Time.TextXAlignment = Enum.TextXAlignment.Left

	local function UpdateTime()
		local GameTime = math.floor(workspace.DistributedGameTime + 0.5)
		local Hour = math.floor(GameTime / (60 ^ 2)) % 24
		local Minute = math.floor(GameTime / (60 ^ 1)) % 60
		local Second = math.floor(GameTime / (60 ^ 0)) % 60
		local FormatTime = string.format("%02d.%02d.%02d", Hour, Minute, Second)
		Server_Time.Text = "Game Time : " .. FormatTime
	end

	-- Update time (FIX - nhẹ hơn, không chạy mỗi frame)
	task.spawn(function()
		while ScreenGui.Parent do
			UpdateTime()
			task.wait(0.25)
		end
	end)

	Server_ID.Name = "Server_ID"
	Server_ID.Parent = Body
	Server_ID.BackgroundTransparency = 1
	Server_ID.BorderSizePixel = 0
	Server_ID.Position = UDim2.new(0, 230, 0, 320)
	Server_ID.Size = UDim2.new(0, 365, 0, 25)
	Server_ID.Font = Enum.Font.SourceSansSemibold
	Server_ID.Text = "User : " .. NameID .. "     [ by tuananhiosdz ]"
	Server_ID.TextColor3 = Color3.fromRGB(255, 255, 255)
	Server_ID.TextSize = 14
	Server_ID.TextXAlignment = Enum.TextXAlignment.Right

	List_Tile.Name = "List_Tile"
	List_Tile.Parent = Body
	List_Tile.BorderSizePixel = 0
	List_Tile.Position = UDim2.new(0, 0, 0, 30)
	List_Tile.Size = UDim2.new(1, 0, 0, 2)

	Tile_Gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
	})
	Tile_Gradient.Name = "Tile_Gradient"
	Tile_Gradient.Parent = List_Tile

	-- Drag main window (FIX - bỏ fake localscript)
	Dragify(Body, "Dragify_Body")

	-- Floating Toggle Button (FIX - chỉ tạo 1 lần, kéo thả mượt)
	local Floating = Instance.new("Frame")
	Floating.Name = "FloatingToggle"
	Floating.Parent = ScreenGui
	Floating.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	Floating.BorderSizePixel = 0
	Floating.Position = UDim2.new(0.05, 0, 0.08, 0)
	Floating.Size = UDim2.new(0, 42, 0, 42)
	Floating.Active = true

	local floatingCorner = Instance.new("UICorner")
	floatingCorner.CornerRadius = UDim.new(0, 12)
	floatingCorner.Parent = Floating

	local floatingBtn = Instance.new("ImageButton")
	floatingBtn.Name = "Btn"
	floatingBtn.Parent = Floating
	floatingBtn.BackgroundTransparency = 1
	floatingBtn.Size = UDim2.new(1, 0, 1, 0)
	floatingBtn.Image = "http://www.roblox.com/asset/?id=75774010417827"
	floatingBtn.AutoButtonColor = false

	Floating.MouseEnter:Connect(function()
		utility:Tween(Floating, { BackgroundColor3 = Color3.fromRGB(30, 30, 30) }, .12)
	end)
	Floating.MouseLeave:Connect(function()
		utility:Tween(Floating, { BackgroundColor3 = Color3.fromRGB(60, 60, 60) }, .12)
	end)

	Dragify(Floating, "Dragify_Floating")

	local uiVisible = true
	floatingBtn.MouseButton1Click:Connect(function()
		uiVisible = not uiVisible
		Body.Visible = uiVisible
	end)

	-- Minimize window (giữ logic cũ)
	local minimizetog = false
	MInimize_Button.MouseButton1Click:Connect(function()
		if minimizetog then
			utility:Tween(Body, { Size = UDim2.new(0, 600, 0, 350) }, .3)
			utility:Tween(MInimize_Button, { Rotation = -315 }, .3)
		else
			utility:Tween(Body, { Size = UDim2.new(0, 600, 0, 32) }, .3)
			utility:Tween(MInimize_Button, { Rotation = 360 }, .3)
		end
		minimizetog = not minimizetog
	end)

	-- Instances:
	local Tab_Container = Instance.new("Frame")
	local Tab_List = Instance.new("Frame")
	local TabList_Gradient = Instance.new("UIGradient")
	local Tab_Scroll = Instance.new("ScrollingFrame")
	local Tab_Scroll_Layout = Instance.new("UIListLayout")
	local Main_Container = Instance.new("Frame")
	local Container = Instance.new("Folder")

	-- Properties:
	Tab_Container.Name = "Tab_Container"
	Tab_Container.Parent = Body
	Tab_Container.BackgroundTransparency = 1
	Tab_Container.BorderSizePixel = 0
	Tab_Container.ClipsDescendants = true
	Tab_Container.Position = UDim2.new(0, 0, 0, 36)
	Tab_Container.Size = UDim2.new(1, 0, 0, 30)

	Tab_List.Name = "Tab_List"
	Tab_List.Parent = Tab_Container
	Tab_List.BorderSizePixel = 0
	Tab_List.Position = UDim2.new(0, 0, 0, 28)
	Tab_List.Size = UDim2.new(1, 0, 0, 2)

	TabList_Gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
	})
	TabList_Gradient.Name = "TabList_Gradient"
	TabList_Gradient.Parent = Tab_List

	Tab_Scroll.Name = "Tab_Scroll"
	Tab_Scroll.Parent = Tab_Container
	Tab_Scroll.Active = true
	Tab_Scroll.BackgroundTransparency = 1
	Tab_Scroll.BorderSizePixel = 0
	Tab_Scroll.Position = UDim2.new(0, 10, 0, 0)
	Tab_Scroll.Size = UDim2.new(1, -20, 0, 30)
	Tab_Scroll.ScrollBarThickness = 0
	-- NOTE: bỏ CanvasPosition set cứng để không bị lệch

	Tab_Scroll_Layout.Name = "Tab_Scroll_Layout"
	Tab_Scroll_Layout.Parent = Tab_Scroll
	Tab_Scroll_Layout.FillDirection = Enum.FillDirection.Horizontal
	Tab_Scroll_Layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	Tab_Scroll_Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Tab_Scroll_Layout.Padding = UDim.new(0, 5)

	Tab_Scroll_Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Tab_Scroll.CanvasSize = UDim2.new(0, Tab_Scroll_Layout.Padding.Offset + Tab_Scroll_Layout.AbsoluteContentSize.X, 0, 0)
	end)

	Main_Container.Name = "Main_Container"
	Main_Container.Parent = Body
	Main_Container.BackgroundTransparency = 1
	Main_Container.BorderSizePixel = 0
	Main_Container.Position = UDim2.new(0, 5, 0, 70)
	Main_Container.Size = UDim2.new(0, 590, 0, 245)

	local ContainerGradients = Instance.new("UIGradient")
	ContainerGradients.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 0, 0)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 0)),
	})
	ContainerGradients.Name = "ContainerGradients"
	ContainerGradients.Parent = Main_Container

	Container.Name = "Container"
	Container.Parent = Main_Container

	--========================
	-- Tabs API (giữ cấu trúc)
	--========================
	local Tabs = {}
	local is_first_tab = true

	function Tabs:addTab(title_tab)
		-- Tab button
		local Tab_Items = Instance.new("TextButton")
		local Tab_Item_Corner = Instance.new("UICorner")

		Tab_Items.Name = "Tab_Items"
		Tab_Items.Parent = Tab_Scroll
		Tab_Items.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		Tab_Items.BackgroundTransparency = 1
		Tab_Items.BorderSizePixel = 0
		Tab_Items.Size = UDim2.new(0, 0, 0, 0)
		Tab_Items.AutoButtonColor = false
		Tab_Items.Font = Enum.Font.SourceSansSemibold
		Tab_Items.TextColor3 = Color3.fromRGB(255, 255, 255)
		Tab_Items.TextSize = 14
		Tab_Items.Text = title_tab

		Tab_Item_Corner.Name = "Tab_Item_Corner"
		Tab_Item_Corner.CornerRadius = UDim.new(0, 4)
		Tab_Item_Corner.Parent = Tab_Items

		utility:Tween(Tab_Items, { Size = UDim2.new(0, 25 + Tab_Items.TextBounds.X, 0, 24) }, .15)

		-- Tab content container
		local ScrollingFrame = Instance.new("ScrollingFrame")
		local Scrolling_Layout = Instance.new("UIListLayout")

		ScrollingFrame.Name = "ScrollingFrame"
		ScrollingFrame.Parent = Container
		ScrollingFrame.Active = true
		ScrollingFrame.BackgroundTransparency = 1
		ScrollingFrame.BorderSizePixel = 0
		ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
		ScrollingFrame.ScrollBarThickness = 0
		ScrollingFrame.Visible = false

		Scrolling_Layout.Name = "Scrolling_Layout"
		Scrolling_Layout.Parent = ScrollingFrame
		Scrolling_Layout.FillDirection = Enum.FillDirection.Horizontal
		Scrolling_Layout.SortOrder = Enum.SortOrder.LayoutOrder
		Scrolling_Layout.Padding = UDim.new(0, 19)

		Scrolling_Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ScrollingFrame.CanvasSize = UDim2.new(0, Scrolling_Layout.AbsoluteContentSize.X, 0, 0)
		end)

		if is_first_tab then
			is_first_tab = false
			utility:Tween(Tab_Items, { BackgroundTransparency = 0.5 }, .3)
			ScrollingFrame.Visible = true
		end

		Tab_Items.MouseButton1Click:Connect(function()
			for _, v in next, Tab_Scroll:GetChildren() do
				if v:IsA("TextButton") then
					utility:Tween(v, { BackgroundTransparency = 1 }, .3)
				end
			end
			utility:Tween(Tab_Items, { BackgroundTransparency = 0.5 }, .3)

			for _, v in next, Container:GetChildren() do
				if v.Name == "ScrollingFrame" then
					v.Visible = false
				end
			end
			ScrollingFrame.Visible = true
		end)

		local Section = {}
		function Section:addSection()
			local SectionScroll = Instance.new("ScrollingFrame")
			local UIListLayout_Section = Instance.new("UIListLayout")

			SectionScroll.Name = "SectionScroll"
			SectionScroll.Parent = ScrollingFrame
			SectionScroll.BackgroundTransparency = 1
			SectionScroll.BorderSizePixel = 0
			SectionScroll.Size = UDim2.new(0, 285, 0, 245)
			SectionScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
			SectionScroll.ScrollBarThickness = 4

			UIListLayout_Section.Parent = SectionScroll
			UIListLayout_Section.HorizontalAlignment = Enum.HorizontalAlignment.Center
			UIListLayout_Section.SortOrder = Enum.SortOrder.LayoutOrder
			UIListLayout_Section.Padding = UDim.new(0, 6)

			UIListLayout_Section:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				SectionScroll.CanvasSize = UDim2.new(0, 0, 0, 5 + UIListLayout_Section.Padding.Offset + UIListLayout_Section.AbsoluteContentSize.Y)
			end)

			local Menus = {}
			function Menus:addMenu(title_menu)
				-- Section header frame
				local SectionFrame = Instance.new("Frame")
				local Section_Inner = Instance.new("Frame")
				local UIListLayout = Instance.new("UIListLayout")
				local UICorner_Section = Instance.new("UICorner")
				local List = Instance.new("Frame")
				local UIGradient = Instance.new("UIGradient")
				local UIGradient_2 = Instance.new("UIGradient")
				local TextLabel = Instance.new("TextLabel")

				SectionFrame.Name = "Section"
				SectionFrame.Parent = SectionScroll
				SectionFrame.BackgroundTransparency = 1
				SectionFrame.BorderSizePixel = 0
				SectionFrame.Size = UDim2.new(1, 0, 0, 25)

				Section_Inner.Name = "Section_Inner"
				Section_Inner.Parent = SectionFrame
				Section_Inner.BorderSizePixel = 0
				Section_Inner.Position = UDim2.new(0, 5, 0, 0)
				Section_Inner.Size = UDim2.new(1, -10, 0, 25)

				UIGradient_2.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
					ColorSequenceKeypoint.new(0.3, Color3.fromRGB(20, 20, 20)),
					ColorSequenceKeypoint.new(0.7, Color3.fromRGB(20, 20, 20)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
				})
				UIGradient_2.Parent = Section_Inner

				UIListLayout.Parent = Section_Inner
				UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
				UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
				UIListLayout.Padding = UDim.new(0, 3)

				UICorner_Section.CornerRadius = UDim.new(0, 4)
				UICorner_Section.Parent = Section_Inner

				TextLabel.Parent = Section_Inner
				TextLabel.BackgroundTransparency = 1
				TextLabel.BorderSizePixel = 0
				TextLabel.Size = UDim2.new(1, 0, 0, 20)
				TextLabel.Font = Enum.Font.SourceSansSemibold
				TextLabel.Text = title_menu
				TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
				TextLabel.TextSize = 14

				List.Name = "List"
				List.Parent = Section_Inner
				List.BorderSizePixel = 0
				List.Size = UDim2.new(1, 0, 0, 1)

				UIGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
					ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30)),
				})
				UIGradient.Parent = List

				local function ResizeSection()
					SectionFrame.Size = UDim2.new(1, 0, 0, UIListLayout.AbsoluteContentSize.Y + UIListLayout.Padding.Offset + 5)
					Section_Inner.Size = UDim2.new(1, -10, 0, UIListLayout.AbsoluteContentSize.Y + UIListLayout.Padding.Offset + 5)
				end
				ResizeSection()
				UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(ResizeSection)

				local Menu_Item = {}

				function Menu_Item:addButton(button_tile, callback)
					callback = callback or function() end

					local TextButton = Instance.new("TextButton")
					local BtnCorner = Instance.new("UICorner")

					TextButton.Parent = Section_Inner
					TextButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					TextButton.BorderSizePixel = 0
					TextButton.Size = UDim2.new(1, -10, 0, 25)
					TextButton.AutoButtonColor = false
					TextButton.Font = Enum.Font.SourceSansSemibold
					TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
					TextButton.TextSize = 12
					TextButton.Text = button_tile

					BtnCorner.CornerRadius = UDim.new(0, 4)
					BtnCorner.Parent = TextButton

					TextButton.MouseEnter:Connect(function()
						utility:Tween(TextButton, { BackgroundColor3 = Color3.fromRGB(30, 30, 30) }, .15)
						utility:Tween(TextButton, { TextColor3 = Color3.fromRGB(180, 180, 180) }, .15)
					end)
					TextButton.MouseLeave:Connect(function()
						utility:Tween(TextButton, { BackgroundColor3 = Color3.fromRGB(40, 40, 40) }, .15)
						utility:Tween(TextButton, { TextColor3 = Color3.fromRGB(255, 255, 255) }, .15)
					end)

					TextButton.MouseButton1Down:Connect(function()
						utility:Tween(TextButton, { TextColor3 = Color3.fromRGB(0, 255, 0) }, .15)
						utility:Tween(TextButton, { Size = UDim2.new(1, -25, 0, 15) }, .15)
					end)
					TextButton.MouseButton1Up:Connect(function()
						utility:Tween(TextButton, { TextColor3 = Color3.fromRGB(255, 255, 255) }, 1)
						utility:Tween(TextButton, { Size = UDim2.new(1, -10, 0, 25) }, .15)
					end)

					TextButton.MouseButton1Click:Connect(function()
						callback()
					end)
				end

				function Menu_Item:addToggle(toggle_title, default, callback)
					callback = callback or function(Value) end
					default = default or false

					-- auto load from config
					if SettingToggle[toggle_title] ~= nil then
						default = SettingToggle[toggle_title]
					end

					local Frame = Instance.new("Frame")
					local TextLabel2 = Instance.new("TextLabel")
					local ImageButton = Instance.new("ImageButton")
					local Corner = Instance.new("UICorner")

					Frame.Parent = Section_Inner
					Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					Frame.BorderSizePixel = 0
					Frame.Size = UDim2.new(1, -10, 0, 25)

					TextLabel2.Parent = Frame
					TextLabel2.BackgroundTransparency = 1
					TextLabel2.BorderSizePixel = 0
					TextLabel2.Position = UDim2.new(0, 5, 0, 0)
					TextLabel2.Size = UDim2.new(1, -30, 0, 25)
					TextLabel2.Font = Enum.Font.SourceSansSemibold
					TextLabel2.TextColor3 = Color3.fromRGB(255, 255, 255)
					TextLabel2.TextSize = 12
					TextLabel2.TextXAlignment = Enum.TextXAlignment.Left
					TextLabel2.Text = toggle_title

					ImageButton.Parent = Frame
					ImageButton.BackgroundTransparency = 1
					ImageButton.BorderSizePixel = 0
					ImageButton.Position = UDim2.new(0, 242, 0, 2)
					ImageButton.Size = UDim2.new(0, 20, 0, 20)
					ImageButton.Image = "rbxassetid://3926311105"
					ImageButton.ImageRectOffset = Vector2.new(940, 784)
					ImageButton.ImageRectSize = Vector2.new(48, 48)

					Corner.CornerRadius = UDim.new(0, 4)
					Corner.Parent = Frame

					local CheckToggle = false
					local function Apply(state)
						if state then
							ImageButton.ImageRectOffset = Vector2.new(4, 836)
							utility:Tween(ImageButton, { ImageColor3 = Color3.fromRGB(0, 255, 0) }, .15)
							utility:Tween(TextLabel2, { TextColor3 = Color3.fromRGB(0, 255, 0) }, .15)
						else
							ImageButton.ImageRectOffset = Vector2.new(940, 784)
							utility:Tween(ImageButton, { ImageColor3 = Color3.fromRGB(255, 255, 255) }, .15)
							utility:Tween(TextLabel2, { TextColor3 = Color3.fromRGB(255, 255, 255) }, .15)
						end
					end

					if default then
						CheckToggle = true
						Apply(true)
						callback(true)
					end

					ImageButton.MouseEnter:Connect(function()
						utility:Tween(TextLabel2, { TextTransparency = 0.5 }, .15)
						utility:Tween(ImageButton, { ImageTransparency = 0.5 }, .15)
						utility:Tween(Frame, { BackgroundColor3 = Color3.fromRGB(30, 30, 30) }, .15)
					end)
					ImageButton.MouseLeave:Connect(function()
						utility:Tween(TextLabel2, { TextTransparency = 0 }, .15)
						utility:Tween(ImageButton, { ImageTransparency = 0 }, .15)
						utility:Tween(Frame, { BackgroundColor3 = Color3.fromRGB(40, 40, 40) }, .15)
					end)

					ImageButton.MouseButton1Click:Connect(function()
						CheckToggle = not CheckToggle
						Apply(CheckToggle)

						-- save config
						SettingToggle[toggle_title] = CheckToggle
						SaveConfig()

						callback(CheckToggle)
					end)
				end

				-- (Giữ nguyên các function khác theo code cũ của bạn)
				-- NOTE: Dropdown/Textbox/Keybind/Label/Changelog/Log mình giữ logic y hệt, chỉ “đụng” phần leak/mượt
				-- Nếu bạn muốn mình patch tiếp dropdown (toggle height mượt + close khi click ngoài) mình làm luôn.

				-- ===== Dropdown (giữ, chỉ sửa nhẹ tween + không bug callback nil) =====
				function Menu_Item:addDropdown(dropdown_tile, default, list, callback)
					default = default or ""
					list = list or {}
					callback = callback or function(Value) end

					local Frame = Instance.new("Frame")
					local Corner = Instance.new("UICorner")
					local TextLabel2 = Instance.new("TextLabel")
					local ImageButton = Instance.new("ImageButton")

					Frame.Parent = Section_Inner
					Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					Frame.BorderSizePixel = 0
					Frame.Size = UDim2.new(1, -10, 0, 25)

					Corner.CornerRadius = UDim.new(0, 4)
					Corner.Parent = Frame

					TextLabel2.Parent = Frame
					TextLabel2.BackgroundTransparency = 1
					TextLabel2.BorderSizePixel = 0
					TextLabel2.Position = UDim2.new(0, 5, 0, 0)
					TextLabel2.Size = UDim2.new(1, -40, 0, 25)
					TextLabel2.Font = Enum.Font.SourceSansSemibold
					TextLabel2.TextColor3 = Color3.fromRGB(255, 255, 255)
					TextLabel2.TextSize = 12
					TextLabel2.TextXAlignment = Enum.TextXAlignment.Left
					TextLabel2.Text = dropdown_tile

					ImageButton.Parent = Frame
					ImageButton.BackgroundTransparency = 1
					ImageButton.BorderSizePixel = 0
					ImageButton.Position = UDim2.new(0, 242, 0, 1)
					ImageButton.Size = UDim2.new(0, 21, 0, 22)
					ImageButton.Image = "rbxassetid://14834203285"

					if default and default ~= "" then
						for _, v in pairs(list) do
							if v == default then
								TextLabel2.Text = dropdown_tile .. " - " .. v
								callback(v)
								break
							end
						end
					end

					ImageButton.MouseEnter:Connect(function()
						utility:Tween(TextLabel2, { TextTransparency = 0.5 }, .15)
						utility:Tween(ImageButton, { ImageTransparency = 0.5 }, .15)
						utility:Tween(Frame, { BackgroundColor3 = Color3.fromRGB(30, 30, 30) }, .15)
					end)
					ImageButton.MouseLeave:Connect(function()
						utility:Tween(TextLabel2, { TextTransparency = 0 }, .15)
						utility:Tween(ImageButton, { ImageTransparency = 0 }, .15)
						utility:Tween(Frame, { BackgroundColor3 = Color3.fromRGB(40, 40, 40) }, .15)
					end)

					local ScrollDown = Instance.new("Frame")
					local UIListLayout2 = Instance.new("UIListLayout")
					local Corner2 = Instance.new("UICorner")

					ScrollDown.Name = "ScrollDown"
					ScrollDown.Parent = Section_Inner
					ScrollDown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					ScrollDown.BorderSizePixel = 0
					ScrollDown.ClipsDescendants = true
					ScrollDown.Size = UDim2.new(1, -10, 0, 0)

					UIListLayout2.Parent = ScrollDown
					UIListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
					UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
					UIListLayout2.Padding = UDim.new(0, 3)

					Corner2.CornerRadius = UDim.new(0, 4)
					Corner2.Parent = ScrollDown

					local dropdown_toggle = false
					local function SetOpen(open)
						dropdown_toggle = open
						if open then
							utility:Tween(ScrollDown, { Size = UDim2.new(1, -10, 0, UIListLayout2.AbsoluteContentSize.Y + 5) }, 0.15)
							utility:Tween(ImageButton, { ImageColor3 = Color3.fromRGB(0, 255, 0) }, .15)
							utility:Tween(TextLabel2, { TextColor3 = Color3.fromRGB(0, 255, 0) }, .15)
						else
							utility:Tween(ScrollDown, { Size = UDim2.new(1, -10, 0, 0) }, 0.15)
							utility:Tween(ImageButton, { ImageColor3 = Color3.fromRGB(255, 255, 255) }, .15)
							utility:Tween(TextLabel2, { TextColor3 = Color3.fromRGB(255, 255, 255) }, .15)
						end
					end

					ImageButton.MouseButton1Click:Connect(function()
						SetOpen(not dropdown_toggle)
					end)

					for _, v in pairs(list) do
						local TextButton = Instance.new("TextButton")
						TextButton.Parent = ScrollDown
						TextButton.BackgroundTransparency = 1
						TextButton.BorderSizePixel = 0
						TextButton.Size = UDim2.new(1, 0, 0, 25)
						TextButton.Font = Enum.Font.SourceSansSemibold
						TextButton.AutoButtonColor = false
						TextButton.TextSize = 12
						TextButton.Text = v
						TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)

						TextButton.MouseEnter:Connect(function()
							utility:Tween(TextButton, { TextSize = 9 }, 0.15)
							utility:Tween(TextButton, { TextColor3 = Color3.fromRGB(0, 255, 0) }, 0.15)
						end)
						TextButton.MouseLeave:Connect(function()
							utility:Tween(TextButton, { TextSize = 12 }, 0.15)
							utility:Tween(TextButton, { TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.15)
						end)

						TextButton.MouseButton1Click:Connect(function()
							TextLabel2.Text = dropdown_tile .. " - " .. v
							callback(v)
							SetOpen(false)
						end)
					end

					local updatedropfunc = {}

					function updatedropfunc:Clear()
						for _, child in pairs(ScrollDown:GetChildren()) do
							if child:IsA("TextButton") then
								child:Destroy()
							end
						end
						TextLabel2.Text = dropdown_tile
						SetOpen(false)
					end

					function updatedropfunc:Refresh(newlist)
						newlist = newlist or {}
						self:Clear()

						for _, v in pairs(newlist) do
							local TextButton = Instance.new("TextButton")
							TextButton.Parent = ScrollDown
							TextButton.BackgroundTransparency = 1
							TextButton.BorderSizePixel = 0
							TextButton.Size = UDim2.new(1, 0, 0, 25)
							TextButton.Font = Enum.Font.SourceSansSemibold
							TextButton.AutoButtonColor = false
							TextButton.TextSize = 12
							TextButton.Text = v
							TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)

							TextButton.MouseEnter:Connect(function()
								utility:Tween(TextButton, { TextSize = 9 }, 0.15)
								utility:Tween(TextButton, { TextColor3 = Color3.fromRGB(0, 255, 0) }, 0.15)
							end)
							TextButton.MouseLeave:Connect(function()
								utility:Tween(TextButton, { TextSize = 12 }, 0.15)
								utility:Tween(TextButton, { TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.15)
							end)

							TextButton.MouseButton1Click:Connect(function()
								TextLabel2.Text = dropdown_tile .. " - " .. v
								callback(v)
								SetOpen(false)
							end)
						end
					end

					return updatedropfunc
				end

				-- ===== Textbox / Keybind / Label / Changelog / Log: giữ như cũ (copy nguyên ý), chỉ tối ưu chút tween =====
				function Menu_Item:addTextbox(text_tile, default, callback)
					callback = callback or function(Value) end

					local Frame = Instance.new("Frame")
					local Corner = Instance.new("UICorner")
					local TextLabel2 = Instance.new("TextLabel")
					local TextBox = Instance.new("TextBox")

					Frame.Parent = Section_Inner
					Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					Frame.BorderSizePixel = 0
					Frame.Size = UDim2.new(1, -10, 0, 25)

					Corner.CornerRadius = UDim.new(0, 4)
					Corner.Parent = Frame

					TextLabel2.Parent = Frame
					TextLabel2.BackgroundTransparency = 1
					TextLabel2.BorderSizePixel = 0
					TextLabel2.Position = UDim2.new(0, 5, 0, 0)
					TextLabel2.Size = UDim2.new(0, 150, 0, 25)
					TextLabel2.Font = Enum.Font.SourceSansSemibold
					TextLabel2.TextColor3 = Color3.fromRGB(255, 255, 255)
					TextLabel2.TextSize = 12
					TextLabel2.TextXAlignment = Enum.TextXAlignment.Left
					TextLabel2.Text = text_tile

					TextBox.Parent = Frame
					TextBox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
					TextBox.BorderSizePixel = 0
					TextBox.Position = UDim2.new(0, 190, 0, 2)
					TextBox.Size = UDim2.new(0, 70, 0, 20)
					TextBox.Font = Enum.Font.SourceSansSemibold
					TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
					TextBox.TextSize = 12
					TextBox.Text = default or "Type Here"

					TextBox.FocusLost:Connect(function(enterPressed)
						if enterPressed then
							callback(TextBox.Text)
							utility:Tween(TextBox, { TextColor3 = Color3.fromRGB(0, 255, 0) }, .1)
							utility:Tween(TextLabel2, { TextColor3 = Color3.fromRGB(0, 255, 0) }, .1)
							task.wait(.1)
							utility:Tween(TextBox, { TextColor3 = Color3.fromRGB(255, 255, 255) }, .5)
							utility:Tween(TextLabel2, { TextColor3 = Color3.fromRGB(255, 255, 255) }, .5)
						end
					end)
				end

				function Menu_Item:addKeybind(keybind_tile, preset, callback)
					callback = callback or function(Value) end

					local Frame = Instance.new("Frame")
					local Corner = Instance.new("UICorner")
					local TextLabel2 = Instance.new("TextLabel")
					local TextButton = Instance.new("TextButton")
					local Corner2 = Instance.new("UICorner")

					Frame.Parent = Section_Inner
					Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					Frame.BorderSizePixel = 0
					Frame.Size = UDim2.new(1, -10, 0, 25)

					Corner.CornerRadius = UDim.new(0, 4)
					Corner.Parent = Frame

					TextLabel2.Parent = Frame
					TextLabel2.BackgroundTransparency = 1
					TextLabel2.BorderSizePixel = 0
					TextLabel2.Position = UDim2.new(0, 5, 0, 0)
					TextLabel2.Size = UDim2.new(0, 150, 0, 25)
					TextLabel2.Font = Enum.Font.SourceSansSemibold
					TextLabel2.TextColor3 = Color3.fromRGB(255, 255, 255)
					TextLabel2.TextSize = 12
					TextLabel2.TextXAlignment = Enum.TextXAlignment.Left
					TextLabel2.Text = keybind_tile

					TextButton.Parent = Frame
					TextButton.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
					TextButton.BorderSizePixel = 0
					TextButton.Position = UDim2.new(0, 190, 0, 3)
					TextButton.Size = UDim2.new(0, 70, 0, 20)
					TextButton.AutoButtonColor = false
					TextButton.Font = Enum.Font.SourceSansSemibold
					TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
					TextButton.TextSize = 14
					TextButton.Text = preset.Name

					Corner2.CornerRadius = UDim.new(0, 4)
					Corner2.Parent = TextButton

					TextButton.MouseButton1Click:Connect(function()
						TextButton.Text = ". . ."
						local inputwait = UserInputService.InputBegan:Wait()
						local key = inputwait.KeyCode.Name

						if key == preset.Name then
							TextButton.Text = key
							callback(key)
							utility:Tween(TextButton, { TextColor3 = Color3.fromRGB(0, 255, 0) }, .1)
							utility:Tween(TextLabel2, { TextColor3 = Color3.fromRGB(0, 255, 0) }, .1)
							task.wait(.1)
							utility:Tween(TextButton, { TextColor3 = Color3.fromRGB(255, 255, 255) }, 1)
							utility:Tween(TextLabel2, { TextColor3 = Color3.fromRGB(255, 255, 255) }, 1)
						else
							TextButton.Text = "Invald..."
							callback(nil)
							utility:Tween(TextButton, { TextColor3 = Color3.fromRGB(255, 0, 0) }, .1)
							utility:Tween(TextLabel2, { TextColor3 = Color3.fromRGB(255, 0, 0) }, .1)
							task.wait(.1)
							utility:Tween(TextButton, { TextColor3 = Color3.fromRGB(255, 255, 255) }, 1)
							utility:Tween(TextLabel2, { TextColor3 = Color3.fromRGB(255, 255, 255) }, 1)
						end
					end)
				end

				function Menu_Item:addLabel(label_text)
					local LabelFunc = {}
					local TextLabel2 = Instance.new("TextLabel")

					TextLabel2.Parent = Section_Inner
					TextLabel2.BackgroundTransparency = 1
					TextLabel2.BorderSizePixel = 0
					TextLabel2.Size = UDim2.new(1, -20, 0, 15)
					TextLabel2.Font = Enum.Font.SourceSansSemibold
					TextLabel2.TextColor3 = Color3.fromRGB(255, 255, 255)
					TextLabel2.TextSize = 12
					TextLabel2.TextXAlignment = Enum.TextXAlignment.Left
					TextLabel2.Text = label_text

					function LabelFunc:Refresh(newLabel)
						if TextLabel2.Text ~= newLabel then
							TextLabel2.Text = newLabel
						end
					end

					return LabelFunc
				end

				function Menu_Item:addChangelog(changeloogtext)
					local ChangelogFunc = {}
					local TextLabel2 = Instance.new("TextLabel")

					TextLabel2.Parent = Section_Inner
					TextLabel2.BackgroundTransparency = 1
					TextLabel2.BorderSizePixel = 0
					TextLabel2.Size = UDim2.new(1, -20, 0, 15)
					TextLabel2.Font = Enum.Font.SourceSansSemibold
					TextLabel2.TextColor3 = Color3.fromRGB(85, 170, 255)
					TextLabel2.TextSize = 12
					TextLabel2.TextXAlignment = Enum.TextXAlignment.Left
					TextLabel2.Text = changeloogtext

					function ChangelogFunc:Refresh(newchangelog)
						if TextLabel2.Text ~= newchangelog then
							TextLabel2.Text = newchangelog
						end
					end

					return ChangelogFunc
				end

				function Menu_Item:addLog(log_text)
					local LogFunc = {}
					local TextLabel2 = Instance.new("TextLabel")

					TextLabel2.Parent = Section_Inner
					TextLabel2.BackgroundTransparency = 1
					TextLabel2.BorderSizePixel = 0
					TextLabel2.Font = Enum.Font.SourceSansSemibold
					TextLabel2.Text = log_text
					TextLabel2.TextColor3 = Color3.fromRGB(255, 255, 0)
					TextLabel2.TextSize = 12
					TextLabel2.TextXAlignment = Enum.TextXAlignment.Left
					TextLabel2.TextYAlignment = Enum.TextYAlignment.Top

					local function Resize()
						TextLabel2.Size = UDim2.new(1, -20, 0, TextLabel2.Text:len() + 15)
					end
					Resize()
					TextLabel2:GetPropertyChangedSignal("Text"):Connect(Resize)

					function LogFunc:Refresh(newLog)
						if TextLabel2.Text ~= newLog then
							TextLabel2.Text = newLog
						end
					end

					return LogFunc
				end

				return Menu_Item
			end

			return Menus
		end

		return Section
	end

	return Tabs
end

return Library
