local Library = {}

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

--// Init
local LocalPlayer = Players.LocalPlayer
local NameID = (LocalPlayer and LocalPlayer.Name) or "Unknown"
local GameName = "Unknown Game"
pcall(function()
	GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
end)

--// Theme: White/Blue border + Black glass inside
local Theme = {
	BorderA = Color3.fromRGB(255, 255, 255),
	BorderB = Color3.fromRGB(0, 145, 255),
	BorderC = Color3.fromRGB(0, 190, 255),

	Glass   = Color3.fromRGB(0, 0, 0),
	GlassT  = 0.30, -- main glass transparency
	Panel   = Color3.fromRGB(14, 14, 18),
	PanelT  = 0.20, -- panel transparency

	Item    = Color3.fromRGB(18, 18, 22),
	ItemT   = 0.20,
	HoverT  = 0.08,

	Text    = Color3.fromRGB(245, 245, 255),
	Muted   = Color3.fromRGB(190, 200, 225),

	Stroke  = Color3.fromRGB(0, 160, 255),
	StrokeSoft = Color3.fromRGB(70, 150, 255),

	Active  = Color3.fromRGB(0, 170, 255),
	Danger  = Color3.fromRGB(255, 80, 80),
}

--// Tween helper
local utility = {}
function utility:Tween(instance, properties, duration, ...)
	local t = TweenService:Create(instance, TweenInfo.new(duration, ...), properties)
	t:Play()
	return t
end

--// Connections manager (avoid duplicate connects/leaks)
local Connections = {}
local function TrackConnection(key, conn)
	if Connections[key] then
		pcall(function() Connections[key]:Disconnect() end)
	end
	Connections[key] = conn
	return conn
end

--// Config (toggle persistence)
local CONFIG_FILE = "BTConfig.json"
local SettingToggle = {}

local function LoadConfig()
	pcall(function()
		if not (isfile and isfile(CONFIG_FILE)) then
			if writefile then
				writefile(CONFIG_FILE, HttpService:JSONEncode({}))
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

--// UI helpers
local function AddCorner(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = obj
	return c
end

local function AddStroke(obj, thickness, transparency, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1
	s.Transparency = (transparency ~= nil) and transparency or 0.25
	s.Color = color or Theme.StrokeSoft
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end

local function AddGradient(obj, c1, c2, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(1, c2),
	})
	g.Rotation = rot or 0
	g.Parent = obj
	return g
end

local function AddPadding(obj, l, r, t, b)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, l or 0)
	p.PaddingRight = UDim.new(0, r or 0)
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.Parent = obj
	return p
end

--// Dragify (smooth + safe)
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

	TrackConnection(key .. "_Began", frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			local endConn
			endConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if endConn then endConn:Disconnect() end
				end
			end)
		end
	end))

	TrackConnection(key .. "_Changed", frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))

	TrackConnection(key .. "_UIS", UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			update(input)
		end
	end))
end

--// Gui name
local LibName = "BCWB_" .. tostring(math.random(10000, 99999))

function Library:ToggleUI()
	local parent = (gethui and gethui()) or game.CoreGui
	local g = parent:FindFirstChild(LibName)
	if g then
		g.Enabled = not g.Enabled
	end
end

function Library:DestroyGui()
	local parent = (gethui and gethui()) or game.CoreGui
	local g = parent:FindFirstChild(LibName)
	if g then g:Destroy() end
end

--=========================================================
-- CreateWindow
--=========================================================
function Library:CreateWindow(hubname)
	hubname = tostring(hubname or "Hub")

	-- destroy previous same name
	local parent = (gethui and gethui()) or game.CoreGui
	for _, v in pairs(parent:GetChildren()) do
		if v:IsA("ScreenGui") and v.Name == LibName then
			pcall(function() v:Destroy() end)
		end
	end

	-- ScreenGui
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = LibName
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	ScreenGui.Parent = parent

	-- Outer border frame (gradient border)
	local Border = Instance.new("Frame")
	Border.Name = "Border"
	Border.Parent = ScreenGui
	Border.Size = UDim2.new(0, 860, 0, 460)
	Border.Position = UDim2.new(0.5, -430, 0.5, -230)
	Border.BorderSizePixel = 0
	Border.BackgroundColor3 = Color3.new(1, 1, 1)
	AddCorner(Border, 14)
	AddGradient(Border, Theme.BorderA, Theme.BorderB, 0)

	-- Inner body (black glass)
	local Body = Instance.new("Frame")
	Body.Name = "Body"
	Body.Parent = Border
	Body.Size = UDim2.new(1, -3, 1, -3)
	Body.Position = UDim2.new(0, 1.5, 0, 1.5)
	Body.BorderSizePixel = 0
	Body.BackgroundColor3 = Theme.Glass
	Body.BackgroundTransparency = Theme.GlassT
	AddCorner(Body, 13)
	AddStroke(Body, 1, 0.65, Theme.Stroke)

	-- Top bar
	local Top = Instance.new("Frame")
	Top.Name = "TopBar"
	Top.Parent = Body
	Top.Size = UDim2.new(1, 0, 0, 44)
	Top.BorderSizePixel = 0
	Top.BackgroundColor3 = Theme.Panel
	Top.BackgroundTransparency = Theme.PanelT
	AddCorner(Top, 13)
	AddStroke(Top, 1, 0.55, Theme.StrokeSoft)

	-- Top gradient strip (white->blue)
	local TopStrip = Instance.new("Frame")
	TopStrip.Parent = Top
	TopStrip.BorderSizePixel = 0
	TopStrip.Size = UDim2.new(1, 0, 0, 3)
	TopStrip.Position = UDim2.new(0, 0, 0, 0)
	TopStrip.BackgroundColor3 = Theme.BorderB
	TopStrip.BackgroundTransparency = 0.05
	AddGradient(TopStrip, Theme.BorderC, Theme.BorderB, 0)

	local Title = Instance.new("TextLabel")
	Title.Parent = Top
	Title.BackgroundTransparency = 1
	Title.Position = UDim2.new(0, 14, 0, 0)
	Title.Size = UDim2.new(1, -120, 1, 0)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 15
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextColor3 = Theme.Text
	Title.Text = hubname .. " - " .. GameName

	-- Minimize button
	local MinBtn = Instance.new("TextButton")
	MinBtn.Parent = Top
	MinBtn.BackgroundTransparency = 1
	MinBtn.Position = UDim2.new(1, -50, 0, 6)
	MinBtn.Size = UDim2.new(0, 38, 0, 32)
	MinBtn.Font = Enum.Font.GothamBold
	MinBtn.TextSize = 20
	MinBtn.Text = "—"
	MinBtn.TextColor3 = Theme.Text
	MinBtn.AutoButtonColor = false

	-- Close (destroy) button
	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Parent = Top
	CloseBtn.BackgroundTransparency = 1
	CloseBtn.Position = UDim2.new(1, -88, 0, 6)
	CloseBtn.Size = UDim2.new(0, 38, 0, 32)
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextSize = 18
	CloseBtn.Text = "×"
	CloseBtn.TextColor3 = Theme.Text
	CloseBtn.AutoButtonColor = false

	-- Content area
	local Content = Instance.new("Frame")
	Content.Parent = Body
	Content.BackgroundTransparency = 1
	Content.Position = UDim2.new(0, 0, 0, 52)
	Content.Size = UDim2.new(1, 0, 1, -92)

	-- Left sidebar
	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.Parent = Content
	Sidebar.BorderSizePixel = 0
	Sidebar.Size = UDim2.new(0, 260, 1, 0)
	Sidebar.BackgroundColor3 = Theme.Panel
	Sidebar.BackgroundTransparency = Theme.PanelT
	AddCorner(Sidebar, 12)
	AddStroke(Sidebar, 1, 0.55, Theme.StrokeSoft)
	AddPadding(Sidebar, 12, 12, 12, 12)

	-- Sidebar search
	local Search = Instance.new("TextBox")
	Search.Parent = Sidebar
	Search.BorderSizePixel = 0
	Search.Size = UDim2.new(1, 0, 0, 34)
	Search.BackgroundColor3 = Theme.Item
	Search.BackgroundTransparency = Theme.ItemT
	Search.ClearTextOnFocus = false
	Search.PlaceholderText = "Search section or Function..."
	Search.PlaceholderColor3 = Theme.Muted
	Search.Text = ""
	Search.TextColor3 = Theme.Text
	Search.TextSize = 13
	Search.Font = Enum.Font.Gotham
	Search.TextXAlignment = Enum.TextXAlignment.Left
	AddCorner(Search, 10)
	AddStroke(Search, 1, 0.60, Theme.StrokeSoft)
	AddPadding(Search, 34, 10, 0, 0)

	local SearchIcon = Instance.new("ImageLabel")
	SearchIcon.Parent = Search
	SearchIcon.BackgroundTransparency = 1
	SearchIcon.Size = UDim2.new(0, 18, 0, 18)
	SearchIcon.Position = UDim2.new(0, 10, 0.5, -9)
	SearchIcon.Image = "rbxassetid://3926305904"
	SearchIcon.ImageRectOffset = Vector2.new(964, 324)
	SearchIcon.ImageRectSize = Vector2.new(36, 36)
	SearchIcon.ImageColor3 = Theme.Muted

	-- Tab list scroll
	local TabList = Instance.new("ScrollingFrame")
	TabList.Parent = Sidebar
	TabList.BackgroundTransparency = 1
	TabList.BorderSizePixel = 0
	TabList.Position = UDim2.new(0, 0, 0, 42)
	TabList.Size = UDim2.new(1, 0, 1, -42)
	TabList.ScrollBarThickness = 3
	TabList.ScrollBarImageColor3 = Theme.BorderB
	TabList.CanvasSize = UDim2.new(0, 0, 0, 0)

	local TabLayout = Instance.new("UIListLayout")
	TabLayout.Parent = TabList
	TabLayout.Padding = UDim.new(0, 6)
	TabLayout.SortOrder = Enum.SortOrder.LayoutOrder

	TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabList.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 6)
	end)

	-- Right main
	local Main = Instance.new("Frame")
	Main.Name = "Main"
	Main.Parent = Content
	Main.BorderSizePixel = 0
	Main.Position = UDim2.new(0, 270, 0, 0)
	Main.Size = UDim2.new(1, -270, 1, 0)
	Main.BackgroundColor3 = Theme.Panel
	Main.BackgroundTransparency = Theme.PanelT
	AddCorner(Main, 12)
	AddStroke(Main, 1, 0.55, Theme.StrokeSoft)
	AddPadding(Main, 12, 12, 12, 12)

	-- Right header
	local RightHeader = Instance.new("TextLabel")
	RightHeader.Parent = Main
	RightHeader.BackgroundTransparency = 1
	RightHeader.Size = UDim2.new(1, 0, 0, 26)
	RightHeader.Font = Enum.Font.GothamBold
	RightHeader.TextSize = 15
	RightHeader.TextColor3 = Theme.Text
	RightHeader.TextXAlignment = Enum.TextXAlignment.Left
	RightHeader.Text = "Home"

	-- Pages container
	local Pages = Instance.new("Folder")
	Pages.Parent = Main
	Pages.Name = "Pages"

	-- Bottom info bar
	local BottomBar = Instance.new("Frame")
	BottomBar.Parent = Body
	BottomBar.BorderSizePixel = 0
	BottomBar.Size = UDim2.new(1, -24, 0, 28)
	BottomBar.Position = UDim2.new(0, 12, 1, -36)
	BottomBar.BackgroundColor3 = Theme.Panel
	BottomBar.BackgroundTransparency = Theme.PanelT
	AddCorner(BottomBar, 10)
	AddStroke(BottomBar, 1, 0.65, Theme.StrokeSoft)

	local ServerTime = Instance.new("TextLabel")
	ServerTime.Parent = BottomBar
	ServerTime.BackgroundTransparency = 1
	ServerTime.Position = UDim2.new(0, 10, 0, 0)
	ServerTime.Size = UDim2.new(0.5, -10, 1, 0)
	ServerTime.Font = Enum.Font.Gotham
	ServerTime.TextSize = 12
	ServerTime.TextColor3 = Theme.Muted
	ServerTime.TextXAlignment = Enum.TextXAlignment.Left
	ServerTime.Text = ""

	local UserInfo = Instance.new("TextLabel")
	UserInfo.Parent = BottomBar
	UserInfo.BackgroundTransparency = 1
	UserInfo.Position = UDim2.new(0.5, 0, 0, 0)
	UserInfo.Size = UDim2.new(0.5, -10, 1, 0)
	UserInfo.Font = Enum.Font.Gotham
	UserInfo.TextSize = 12
	UserInfo.TextColor3 = Theme.Muted
	UserInfo.TextXAlignment = Enum.TextXAlignment.Right
	UserInfo.Text = "User : " .. NameID

	local function UpdateTime()
		local gt = math.floor(workspace.DistributedGameTime + 0.5)
		local h = math.floor(gt / 3600) % 24
		local m = math.floor(gt / 60) % 60
		local s = math.floor(gt) % 60
		ServerTime.Text = ("Game Time : %02d:%02d:%02d"):format(h, m, s)
	end

	task.spawn(function()
		while ScreenGui.Parent do
			UpdateTime()
			task.wait(0.25)
		end
	end)

	-- Floating toggle button
	local Floating = Instance.new("Frame")
	Floating.Name = "FloatingToggle"
	Floating.Parent = ScreenGui
	Floating.BackgroundColor3 = Theme.Glass
	Floating.BackgroundTransparency = Theme.GlassT
	Floating.BorderSizePixel = 0
	Floating.Position = UDim2.new(0.05, 0, 0.08, 0)
	Floating.Size = UDim2.new(0, 44, 0, 44)
	Floating.Active = true
	AddCorner(Floating, 14)
	AddStroke(Floating, 1, 0.55, Theme.StrokeSoft)

	local FloatBtn = Instance.new("ImageButton")
	FloatBtn.Parent = Floating
	FloatBtn.BackgroundTransparency = 1
	FloatBtn.Size = UDim2.new(1, 0, 1, 0)
	FloatBtn.Image = "http://www.roblox.com/asset/?id=75774010417827"
	FloatBtn.AutoButtonColor = false

	local uiVisible = true
	FloatBtn.MouseButton1Click:Connect(function()
		uiVisible = not uiVisible
		Border.Visible = uiVisible
	end)

	Floating.MouseEnter:Connect(function()
		utility:Tween(Floating, { BackgroundTransparency = math.clamp(Theme.GlassT - 0.12, 0, 1) }, .12)
	end)
	Floating.MouseLeave:Connect(function()
		utility:Tween(Floating, { BackgroundTransparency = Theme.GlassT }, .12)
	end)

	-- Drag main + floating
	Dragify(Border, "Dragify_Border")
	Dragify(Floating, "Dragify_Floating")

	-- Ctrl toggle
	TrackConnection("Keybind_ToggleUI", UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.LeftControl then
			Library:ToggleUI()
		end
	end))

	-- Close/Destroy
	CloseBtn.MouseButton1Click:Connect(function()
		Library:DestroyGui()
	end)

	-- Minimize (collapse content area)
	local minimized = false
	MinBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			utility:Tween(Border, { Size = UDim2.new(0, 860, 0, 56) }, .20)
			Content.Visible = false
			BottomBar.Visible = false
		else
			utility:Tween(Border, { Size = UDim2.new(0, 860, 0, 460) }, .20)
			Content.Visible = true
			BottomBar.Visible = true
		end
	end)

	--=========================================================
	-- Tabs API object
	--=========================================================
	local Tabs = {}
	local tabButtons = {}
	local pages = {}
	local currentTabName = nil

	local function SetTabActive(tabName)
		currentTabName = tabName
		RightHeader.Text = tabName

		for name, page in pairs(pages) do
			page.Visible = (name == tabName)
		end
		for _, btn in ipairs(tabButtons) do
			local active = (btn:GetAttribute("TabName") == tabName)
			if active then
				utility:Tween(btn, { BackgroundTransparency = 0.10 }, .12)
				btn.TextColor3 = Theme.BorderC
				btn.LeftMark.Visible = true
			else
				utility:Tween(btn, { BackgroundTransparency = 0.45 }, .12)
				btn.TextColor3 = Theme.Text
				btn.LeftMark.Visible = false
			end
		end
	end

	-- Sidebar search filter (tabs only)
	Search:GetPropertyChangedSignal("Text"):Connect(function()
		local q = string.lower(Search.Text or "")
		for _, btn in ipairs(tabButtons) do
			local label = string.lower(btn:GetAttribute("TabName") or "")
			btn.Visible = (q == "" or string.find(label, q, 1, true) ~= nil)
		end
	end)

	-- Build config key
	local function MakeKey(tabName, menuTitle, itemTitle)
		return tostring(tabName) .. ">" .. tostring(menuTitle) .. ">" .. tostring(itemTitle)
	end

	-- Tab creator
	function Tabs:addTab(title_tab)
		title_tab = tostring(title_tab or "Tab")

		-- Sidebar button
		local TabBtn = Instance.new("TextButton")
		TabBtn.Parent = TabList
		TabBtn.Name = "TabBtn"
		TabBtn:SetAttribute("TabName", title_tab)
		TabBtn.Size = UDim2.new(1, 0, 0, 36)
		TabBtn.BackgroundColor3 = Theme.Item
		TabBtn.BackgroundTransparency = 0.45
		TabBtn.BorderSizePixel = 0
		TabBtn.AutoButtonColor = false
		TabBtn.Font = Enum.Font.GothamSemibold
		TabBtn.TextSize = 13
		TabBtn.TextXAlignment = Enum.TextXAlignment.Left
		TabBtn.TextColor3 = Theme.Text
		TabBtn.Text = "   " .. title_tab
		AddCorner(TabBtn, 10)
		AddStroke(TabBtn, 1, 0.60, Theme.StrokeSoft)

		local LeftMark = Instance.new("Frame")
		LeftMark.Parent = TabBtn
		LeftMark.Name = "LeftMark"
		LeftMark.Size = UDim2.new(0, 3, 0, 18)
		LeftMark.Position = UDim2.new(0, 8, 0.5, -9)
		LeftMark.BorderSizePixel = 0
		LeftMark.BackgroundColor3 = Theme.BorderC
		LeftMark.Visible = false
		AddCorner(LeftMark, 4)
		TabBtn.LeftMark = LeftMark

		TabBtn.MouseEnter:Connect(function()
			if currentTabName ~= title_tab then
				utility:Tween(TabBtn, { BackgroundTransparency = 0.30 }, .10)
			end
		end)
		TabBtn.MouseLeave:Connect(function()
			if currentTabName ~= title_tab then
				utility:Tween(TabBtn, { BackgroundTransparency = 0.45 }, .10)
			end
		end)

		table.insert(tabButtons, TabBtn)

		-- Page for this tab (inside right main)
		local Page = Instance.new("Frame")
		Page.Parent = Pages
		Page.Name = "Page_" .. title_tab
		Page.BackgroundTransparency = 1
		Page.Position = UDim2.new(0, 0, 0, 30)
		Page.Size = UDim2.new(1, 0, 1, -30)
		Page.Visible = false
		pages[title_tab] = Page

		-- Keep your old behavior: tab content is horizontal scrolling sections
		local ScrollingFrame = Instance.new("ScrollingFrame")
		ScrollingFrame.Parent = Page
		ScrollingFrame.Name = "ScrollingFrame"
		ScrollingFrame.Active = true
		ScrollingFrame.BackgroundTransparency = 1
		ScrollingFrame.BorderSizePixel = 0
		ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
		ScrollingFrame.ScrollBarThickness = 3
		ScrollingFrame.ScrollBarImageColor3 = Theme.BorderB
		ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

		local Scrolling_Layout = Instance.new("UIListLayout")
		Scrolling_Layout.Parent = ScrollingFrame
		Scrolling_Layout.FillDirection = Enum.FillDirection.Horizontal
		Scrolling_Layout.SortOrder = Enum.SortOrder.LayoutOrder
		Scrolling_Layout.Padding = UDim.new(0, 14)

		Scrolling_Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ScrollingFrame.CanvasSize = UDim2.new(0, Scrolling_Layout.AbsoluteContentSize.X + 14, 0, 0)
		end)

		TabBtn.MouseButton1Click:Connect(function()
			SetTabActive(title_tab)
		end)

		-- First tab auto select
		if not currentTabName then
			SetTabActive(title_tab)
		end

		-- Section API
		local Section = {}
		function Section:addSection()
			local SectionScroll = Instance.new("ScrollingFrame")
			SectionScroll.Name = "SectionScroll"
			SectionScroll.Parent = ScrollingFrame
			SectionScroll.BackgroundTransparency = 1
			SectionScroll.BorderSizePixel = 0
			SectionScroll.Size = UDim2.new(0, 320, 1, 0)
			SectionScroll.ScrollBarThickness = 3
			SectionScroll.ScrollBarImageColor3 = Theme.BorderB
			SectionScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

			local UIListLayout_Section = Instance.new("UIListLayout")
			UIListLayout_Section.Parent = SectionScroll
			UIListLayout_Section.HorizontalAlignment = Enum.HorizontalAlignment.Center
			UIListLayout_Section.SortOrder = Enum.SortOrder.LayoutOrder
			UIListLayout_Section.Padding = UDim.new(0, 8)

			UIListLayout_Section:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				SectionScroll.CanvasSize = UDim2.new(0, 0, 0, UIListLayout_Section.AbsoluteContentSize.Y + 10)
			end)

			local Menus = {}
			function Menus:addMenu(title_menu)
				title_menu = tostring(title_menu or "Menu")

				-- Group card
				local Card = Instance.new("Frame")
				Card.Parent = SectionScroll
				Card.BackgroundColor3 = Theme.Glass
				Card.BackgroundTransparency = Theme.GlassT
				Card.BorderSizePixel = 0
				Card.Size = UDim2.new(1, 0, 0, 36)
				AddCorner(Card, 12)
				AddStroke(Card, 1, 0.55, Theme.StrokeSoft)
				AddPadding(Card, 12, 12, 10, 12)

				-- Card header
				local Header = Instance.new("TextLabel")
				Header.Parent = Card
				Header.BackgroundTransparency = 1
				Header.Size = UDim2.new(1, 0, 0, 18)
				Header.Font = Enum.Font.GothamBold
				Header.TextSize = 13
				Header.TextColor3 = Theme.BorderC
				Header.TextXAlignment = Enum.TextXAlignment.Left
				Header.Text = title_menu

				local Divider = Instance.new("Frame")
				Divider.Parent = Card
				Divider.BorderSizePixel = 0
				Divider.Size = UDim2.new(1, 0, 0, 2)
				Divider.BackgroundColor3 = Theme.BorderB
				Divider.BackgroundTransparency = 0.25
				AddCorner(Divider, 2)
				AddGradient(Divider, Theme.BorderC, Theme.BorderB, 0)

				local Layout = Instance.new("UIListLayout")
				Layout.Parent = Card
				Layout.SortOrder = Enum.SortOrder.LayoutOrder
				Layout.Padding = UDim.new(0, 8)

				local function ResizeCard()
					Card.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + 8)
				end
				Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(ResizeCard)
				ResizeCard()

				--=======================
				-- Items API
				--=======================
				local Menu_Item = {}

				local function MakeRow(height)
					local Row = Instance.new("Frame")
					Row.Parent = Card
					Row.BackgroundColor3 = Theme.Item
					Row.BackgroundTransparency = Theme.ItemT
					Row.BorderSizePixel = 0
					Row.Size = UDim2.new(1, 0, 0, height or 30)
					AddCorner(Row, 10)
					AddStroke(Row, 1, 0.65, Theme.StrokeSoft)

					Row.MouseEnter:Connect(function()
						utility:Tween(Row, { BackgroundTransparency = Theme.HoverT }, .10)
					end)
					Row.MouseLeave:Connect(function()
						utility:Tween(Row, { BackgroundTransparency = Theme.ItemT }, .10)
					end)
					return Row
				end

				function Menu_Item:addButton(button_tile, callback)
					callback = callback or function() end
					button_tile = tostring(button_tile or "Button")

					local Row = MakeRow(32)

					local Txt = Instance.new("TextButton")
					Txt.Parent = Row
					Txt.BackgroundTransparency = 1
					Txt.BorderSizePixel = 0
					Txt.Size = UDim2.new(1, 0, 1, 0)
					Txt.AutoButtonColor = false
					Txt.Font = Enum.Font.GothamSemibold
					Txt.TextSize = 12
					Txt.TextXAlignment = Enum.TextXAlignment.Left
					Txt.TextColor3 = Theme.Text
					Txt.Text = "  " .. button_tile

					local Arrow = Instance.new("ImageLabel")
					Arrow.Parent = Row
					Arrow.BackgroundTransparency = 1
					Arrow.Size = UDim2.new(0, 18, 0, 18)
					Arrow.Position = UDim2.new(1, -26, 0.5, -9)
					Arrow.Image = "rbxassetid://3926307971"
					Arrow.ImageRectOffset = Vector2.new(324, 364)
					Arrow.ImageRectSize = Vector2.new(36, 36)
					Arrow.ImageColor3 = Theme.Muted

					Txt.MouseButton1Click:Connect(function()
						pcall(callback)
					end)
				end

				function Menu_Item:addToggle(toggle_title, default, callback)
					callback = callback or function(Value) end
					default = default or false
					toggle_title = tostring(toggle_title or "Toggle")

					local key = MakeKey(title_tab, title_menu, toggle_title)
					if SettingToggle[key] ~= nil then
						default = SettingToggle[key]
					end

					local Row = MakeRow(32)

					local Label = Instance.new("TextLabel")
					Label.Parent = Row
					Label.BackgroundTransparency = 1
					Label.BorderSizePixel = 0
					Label.Position = UDim2.new(0, 10, 0, 0)
					Label.Size = UDim2.new(1, -52, 1, 0)
					Label.Font = Enum.Font.GothamSemibold
					Label.TextSize = 12
					Label.TextXAlignment = Enum.TextXAlignment.Left
					Label.TextColor3 = Theme.Text
					Label.Text = toggle_title

					-- BananaCat-like square toggle at right
					local Box = Instance.new("Frame")
					Box.Parent = Row
					Box.BorderSizePixel = 0
					Box.Size = UDim2.new(0, 20, 0, 20)
					Box.Position = UDim2.new(1, -30, 0.5, -10)
					Box.BackgroundTransparency = 1
					AddCorner(Box, 4)
					AddStroke(Box, 2, 0.0, Theme.BorderC)

					local Fill = Instance.new("Frame")
					Fill.Parent = Box
					Fill.BorderSizePixel = 0
					Fill.Size = UDim2.new(1, -6, 1, -6)
					Fill.Position = UDim2.new(0, 3, 0, 3)
					Fill.BackgroundColor3 = Theme.Active
					Fill.Visible = false
					AddCorner(Fill, 3)

					local state = (default == true)
					local function Apply(v)
						state = v
						Fill.Visible = v
						if v then
							utility:Tween(Label, { TextColor3 = Theme.Active }, .10)
						else
							utility:Tween(Label, { TextColor3 = Theme.Text }, .10)
						end
						SettingToggle[key] = v
						SaveConfig()
						pcall(function() callback(v) end)
					end

					Row.InputBegan:Connect(function(inp)
						if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
							Apply(not state)
						end
					end)

					Apply(state)
				end

				function Menu_Item:addDropdown(dropdown_tile, default, list, callback)
					default = default or ""
					list = list or {}
					callback = callback or function(Value) end
					dropdown_tile = tostring(dropdown_tile or "Dropdown")

					local Row = MakeRow(32)

					local Label = Instance.new("TextLabel")
					Label.Parent = Row
					Label.BackgroundTransparency = 1
					Label.BorderSizePixel = 0
					Label.Position = UDim2.new(0, 10, 0, 0)
					Label.Size = UDim2.new(1, -52, 1, 0)
					Label.Font = Enum.Font.GothamSemibold
					Label.TextSize = 12
					Label.TextXAlignment = Enum.TextXAlignment.Left
					Label.TextColor3 = Theme.Text
					Label.Text = dropdown_tile .. (default ~= "" and (" : " .. tostring(default)) or "")

					local Icon = Instance.new("ImageLabel")
					Icon.Parent = Row
					Icon.BackgroundTransparency = 1
					Icon.Size = UDim2.new(0, 18, 0, 18)
					Icon.Position = UDim2.new(1, -26, 0.5, -9)
					Icon.Image = "rbxassetid://3926307971"
					Icon.ImageRectOffset = Vector2.new(324, 364)
					Icon.ImageRectSize = Vector2.new(36, 36)
					Icon.ImageColor3 = Theme.Muted

					local Drop = Instance.new("Frame")
					Drop.Parent = Card
					Drop.BackgroundColor3 = Theme.Glass
					Drop.BackgroundTransparency = Theme.GlassT
					Drop.BorderSizePixel = 0
					Drop.ClipsDescendants = true
					Drop.Size = UDim2.new(1, 0, 0, 0)
					AddCorner(Drop, 10)
					AddStroke(Drop, 1, 0.60, Theme.StrokeSoft)
					AddPadding(Drop, 8, 8, 8, 8)

					local DropList = Instance.new("ScrollingFrame")
					DropList.Parent = Drop
					DropList.BackgroundTransparency = 1
					DropList.BorderSizePixel = 0
					DropList.Size = UDim2.new(1, 0, 1, 0)
					DropList.ScrollBarThickness = 3
					DropList.ScrollBarImageColor3 = Theme.BorderB
					DropList.CanvasSize = UDim2.new(0, 0, 0, 0)

					local DropLayout = Instance.new("UIListLayout")
					DropLayout.Parent = DropList
					DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
					DropLayout.Padding = UDim.new(0, 4)

					DropLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
						DropList.CanvasSize = UDim2.new(0, 0, 0, DropLayout.AbsoluteContentSize.Y + 6)
					end)

					local opened = false
					local function SetOpen(v)
						opened = v
						if v then
							utility:Tween(Drop, { Size = UDim2.new(1, 0, 0, math.min(180, DropLayout.AbsoluteContentSize.Y + 18)) }, .12)
							utility:Tween(Label, { TextColor3 = Theme.Active }, .12)
						else
							utility:Tween(Drop, { Size = UDim2.new(1, 0, 0, 0) }, .12)
							utility:Tween(Label, { TextColor3 = Theme.Text }, .12)
						end
					end

					local function AddOption(opt)
						local Btn = Instance.new("TextButton")
						Btn.Parent = DropList
						Btn.BackgroundColor3 = Theme.Item
						Btn.BackgroundTransparency = Theme.ItemT
						Btn.BorderSizePixel = 0
						Btn.Size = UDim2.new(1, 0, 0, 28)
						Btn.AutoButtonColor = false
						Btn.Font = Enum.Font.GothamSemibold
						Btn.TextSize = 12
						Btn.TextXAlignment = Enum.TextXAlignment.Left
						Btn.TextColor3 = Theme.Text
						Btn.Text = "  " .. tostring(opt)
						AddCorner(Btn, 8)
						AddStroke(Btn, 1, 0.70, Theme.StrokeSoft)

						Btn.MouseEnter:Connect(function()
							utility:Tween(Btn, { BackgroundTransparency = Theme.HoverT }, .10)
							utility:Tween(Btn, { TextColor3 = Theme.Active }, .10)
						end)
						Btn.MouseLeave:Connect(function()
							utility:Tween(Btn, { BackgroundTransparency = Theme.ItemT }, .10)
							utility:Tween(Btn, { TextColor3 = Theme.Text }, .10)
						end)

						Btn.MouseButton1Click:Connect(function()
							Label.Text = dropdown_tile .. " : " .. tostring(opt)
							pcall(function() callback(opt) end)
							SetOpen(false)
						end)
					end

					Row.InputBegan:Connect(function(inp)
						if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
							SetOpen(not opened)
						end
					end)

					for _, v in pairs(list) do
						AddOption(v)
					end

					if default and default ~= "" then
						pcall(function() callback(default) end)
					end

					local updatedropfunc = {}
					function updatedropfunc:Clear()
						for _, ch in pairs(DropList:GetChildren()) do
							if ch:IsA("TextButton") then ch:Destroy() end
						end
						Label.Text = dropdown_tile
						SetOpen(false)
					end

					function updatedropfunc:Refresh(newlist)
						newlist = newlist or {}
						self:Clear()
						for _, v in pairs(newlist) do
							AddOption(v)
						end
					end

					return updatedropfunc
				end

				function Menu_Item:addTextbox(text_tile, default, callback)
					callback = callback or function(Value) end
					text_tile = tostring(text_tile or "Textbox")

					local Row = MakeRow(32)

					local Label = Instance.new("TextLabel")
					Label.Parent = Row
					Label.BackgroundTransparency = 1
					Label.BorderSizePixel = 0
					Label.Position = UDim2.new(0, 10, 0, 0)
					Label.Size = UDim2.new(1, -120, 1, 0)
					Label.Font = Enum.Font.GothamSemibold
					Label.TextSize = 12
					Label.TextXAlignment = Enum.TextXAlignment.Left
					Label.TextColor3 = Theme.Text
					Label.Text = text_tile

					local Box = Instance.new("TextBox")
					Box.Parent = Row
					Box.BorderSizePixel = 0
					Box.Size = UDim2.new(0, 86, 0, 22)
					Box.Position = UDim2.new(1, -96, 0.5, -11)
					Box.BackgroundColor3 = Theme.Glass
					Box.BackgroundTransparency = 0.35
					Box.ClearTextOnFocus = false
					Box.Font = Enum.Font.GothamSemibold
					Box.TextSize = 12
					Box.TextColor3 = Theme.Text
					Box.Text = tostring(default or "")
					Box.PlaceholderText = "Type"
					Box.PlaceholderColor3 = Theme.Muted
					AddCorner(Box, 8)
					AddStroke(Box, 1, 0.70, Theme.StrokeSoft)
					AddPadding(Box, 8, 8, 0, 0)

					Box.FocusLost:Connect(function(enter)
						if enter then
							pcall(function() callback(Box.Text) end)
							utility:Tween(Label, { TextColor3 = Theme.Active }, .10)
							task.wait(0.08)
							utility:Tween(Label, { TextColor3 = Theme.Text }, .25)
						end
					end)
				end

				function Menu_Item:addKeybind(keybind_tile, preset, callback)
					callback = callback or function(Value) end
					keybind_tile = tostring(keybind_tile or "Keybind")
					preset = preset or Enum.KeyCode.Unknown

					local Row = MakeRow(32)

					local Label = Instance.new("TextLabel")
					Label.Parent = Row
					Label.BackgroundTransparency = 1
					Label.BorderSizePixel = 0
					Label.Position = UDim2.new(0, 10, 0, 0)
					Label.Size = UDim2.new(1, -120, 1, 0)
					Label.Font = Enum.Font.GothamSemibold
					Label.TextSize = 12
					Label.TextXAlignment = Enum.TextXAlignment.Left
					Label.TextColor3 = Theme.Text
					Label.Text = keybind_tile

					local Btn = Instance.new("TextButton")
					Btn.Parent = Row
					Btn.BorderSizePixel = 0
					Btn.Size = UDim2.new(0, 86, 0, 22)
					Btn.Position = UDim2.new(1, -96, 0.5, -11)
					Btn.BackgroundColor3 = Theme.Glass
					Btn.BackgroundTransparency = 0.35
					Btn.AutoButtonColor = false
					Btn.Font = Enum.Font.GothamSemibold
					Btn.TextSize = 12
					Btn.TextColor3 = Theme.Text
					Btn.Text = preset.Name
					AddCorner(Btn, 8)
					AddStroke(Btn, 1, 0.70, Theme.StrokeSoft)

					Btn.MouseButton1Click:Connect(function()
						Btn.Text = ". . ."
						local inputwait = UserInputService.InputBegan:Wait()
						local key = inputwait.KeyCode
						if key and key ~= Enum.KeyCode.Unknown then
							Btn.Text = key.Name
							pcall(function() callback(key.Name) end)
							utility:Tween(Label, { TextColor3 = Theme.Active }, .10)
							task.wait(0.08)
							utility:Tween(Label, { TextColor3 = Theme.Text }, .25)
						else
							Btn.Text = "Invalid"
							pcall(function() callback(nil) end)
							utility:Tween(Label, { TextColor3 = Theme.Danger }, .10)
							task.wait(0.08)
							utility:Tween(Label, { TextColor3 = Theme.Text }, .25)
						end
					end)
				end

				function Menu_Item:addLabel(label_text)
					local LabelFunc = {}
					local L = Instance.new("TextLabel")
					L.Parent = Card
					L.BackgroundTransparency = 1
					L.BorderSizePixel = 0
					L.Size = UDim2.new(1, 0, 0, 16)
					L.Font = Enum.Font.Gotham
					L.TextSize = 12
					L.TextXAlignment = Enum.TextXAlignment.Left
					L.TextColor3 = Theme.Muted
					L.Text = tostring(label_text or "")

					function LabelFunc:Refresh(newLabel)
						newLabel = tostring(newLabel or "")
						if L.Text ~= newLabel then
							L.Text = newLabel
						end
					end
					return LabelFunc
				end

				function Menu_Item:addChangelog(text)
					local ChangelogFunc = {}
					local L = Instance.new("TextLabel")
					L.Parent = Card
					L.BackgroundTransparency = 1
					L.BorderSizePixel = 0
					L.Size = UDim2.new(1, 0, 0, 16)
					L.Font = Enum.Font.GothamSemibold
					L.TextSize = 12
					L.TextXAlignment = Enum.TextXAlignment.Left
					L.TextColor3 = Theme.BorderC
					L.Text = tostring(text or "")

					function ChangelogFunc:Refresh(v)
						v = tostring(v or "")
						if L.Text ~= v then
							L.Text = v
						end
					end
					return ChangelogFunc
				end

				function Menu_Item:addLog(text)
					local LogFunc = {}
					local L = Instance.new("TextLabel")
					L.Parent = Card
					L.BackgroundTransparency = 1
					L.BorderSizePixel = 0
					L.Size = UDim2.new(1, 0, 0, 18)
					L.Font = Enum.Font.GothamSemibold
					L.TextSize = 12
					L.TextXAlignment = Enum.TextXAlignment.Left
					L.TextYAlignment = Enum.TextYAlignment.Top
					L.TextColor3 = Theme.BorderB
					L.TextWrapped = true
					L.Text = tostring(text or "")

					local function Resize()
						L.Size = UDim2.new(1, 0, 0, math.max(18, L.TextBounds.Y + 4))
					end
					Resize()
					L:GetPropertyChangedSignal("Text"):Connect(Resize)

					function LogFunc:Refresh(v)
						v = tostring(v or "")
						if L.Text ~= v then
							L.Text = v
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
