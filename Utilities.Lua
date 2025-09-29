local UtilitiesModule = {}

-- Dirs
--local InfoModulesFolder = game:GetService("ReplicatedStorage"):WaitForChild("Replicated"):WaitForChild("Assets")["InfoModules"]
--local ModulesFolder = game:GetService("ReplicatedStorage"):WaitForChild("Replicated")["Assets"]["Modules"]

-- Info Modules
--local FpsInfoModule = require(InfoModulesFolder["Fps"])

-- Modules
local CharSetModule = require(script["Data"]["CharSet"])
local BrickColorsModule = require(script["Data"]["BrickColors"])
--local DebugModule = require(ModulesFolder["Debug"])

-- CORE
local RequiredModules = {}

-- Services
local HttpService = game:GetService("HttpService")
local GroupService = game:GetService("GroupService")
local SocialService = game:GetService("SocialService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ExperienceNotificationService = game:GetService("ExperienceNotificationService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local StarterGuiService = game:GetService("StarterGui")
local AdService = game:GetService("AdService")

-- Functions
-- MECHANICS
local function FormatToDoubleDigit(Time)
	-- Functions
	-- INIT
	if string.len(Time) < 2 then
		return "0".. tostring(Time)
	end
	
	return tostring(Time)
end

-- DIRECT
function UtilitiesModule.CanWatchAd()
	-- CORE
	local INELIGIBLE_RESULTS = {
		Enum.AdAvailabilityResult.PlayerIneligible,
		Enum.AdAvailabilityResult.DeviceIneligible,
		Enum.AdAvailabilityResult.PublisherIneligible,
		Enum.AdAvailabilityResult.ExperienceIneligible,
	}
	
	-- Functions
	-- INIT	
	local isSuccess, result = UtilitiesModule:TryFor(1, function()
		return AdService:GetAdAvailabilityNowAsync(Enum.AdFormat.RewardedVideo)
	end)

	if isSuccess and result.AdAvailabilityResult == Enum.AdAvailabilityResult.IsAvailable then
		return true
	end
	
	local Found = table.find(INELIGIBLE_RESULTS, result)
	
	return (typeof(Found) == "number")
end

function UtilitiesModule.CheckForAds(NilParam, CallbackFunction, ...) -- CALL BACK TO SERVER (SERVER SHOWS ADS ONLY!)
	-- Functions
	-- INIT
	if not UtilitiesModule:CanWatchAd() then
		return nil
	end
	
	return CallbackFunction(...)
end


local function Color3FromRGB(RGBValue)
	return Color3.fromRGB(RGBValue.R, RGBValue.G, RGBValue.B)
end

local function Color3ToRGB(Color3Value)
	return {R = Color3Value.r * 255, G = Color3Value.g * 255, B = Color3Value.b * 255}
end

local function GetPointBetweenColours(Color3Value1,Color3Value2, Point)
	-- Functions
	-- INIT
	--[[local RGB1 = Color3ToRGB(Color3Value1)
	local RGB2 = Color3ToRGB(Color3Value2)


	local R = (RGB1.R + RGB2.R) * Point
	local G = (RGB1.G + RGB2.G) * Point
	local B = (RGB1.B + RGB2.B) * Point
	
	return Color3.fromRGB(R, G, B)]]
	
	return Color3Value1:Lerp(Color3Value2, Point)
end

function UtilitiesModule.GetChild(NilParam, Parent)
	-- Functions
	-- INIT
	return Parent:GetChildren()[1]
end

function UtilitiesModule.GetSearchFilter(NilParam, TextBox)
	-- CORE
	local SearchFilter = nil
	
	-- Functions
	-- INIT
	if TextBox.Text ~= "" then
		SearchFilter = string.lower(TextBox.Text)
	end
	
	return SearchFilter
end

function UtilitiesModule.GetClientOrServer()
	-- Functions
	-- INIT
	if RunService:IsServer() then
		return "Server"
	elseif RunService:IsClient() then
		return "Client"
	end
end

function UtilitiesModule.ToggleResetButton(NilParam, Toggle)
	-- Functions
	-- INIT
	local Success, Error = UtilitiesModule:TryFor(3, function()
		return game:GetService("StarterGui"):SetCore("ResetButtonCallback", Toggle)
	end)
end

function UtilitiesModule.SendNotification(NilParam, Title, Text, IconImageId, Duration)
	-- Functions
	-- INIT
	StarterGuiService:SetCore("SendNotification", 
	{
		["Title"] = Title;
		["Text"] = Text;
		["Icon"] = IconImageId,
  		["Duration"] = Duration or 5
	})
end

function UtilitiesModule.Tween(NilParam, Element, EffectInfo, tweeningInfo)
	-- CORE
	local FPS = EffectInfo["FPS"] or 60
	
	local StartTime = UtilitiesModule:GetTick()
	local Duration = EffectInfo["Duration"]
	
	local StartValues = {}
	
	-- Functions
	-- INIT
	for PropertyName, _ in pairs(tweeningInfo) do
		if not UtilitiesModule:HasProperty(Element, PropertyName) then
			continue
		end
		
		StartValues[PropertyName] = Element[PropertyName]
	end
	
	-- DIRECT
	local Connection1 = nil
	
	Connection1 = UtilitiesModule:RenderSteppedFPSLock(FPS, function()
		-- CORE
		local TimeNow = UtilitiesModule:GetTick()
		local TimeSpan = TimeNow - StartTime
		local Percentage = math.clamp(TimeSpan / Duration, 0, 1)
		
		-- Functions
		-- INIT
		Percentage = UtilitiesModule:GetLerpEasing()[EffectInfo["Style"].Name][EffectInfo["Direction"].Name](Percentage)
		
		for PropertyName, PropertyStartValue in pairs(StartValues) do
			local PropertyEndValue = tweeningInfo[PropertyName]
			
			Element[PropertyName] = UtilitiesModule:Lerp(PropertyStartValue, PropertyEndValue, Percentage)
		end
		
		if TimeSpan >= Duration then
			return UtilitiesModule:DisconnectConnections({Connection1})
		end
	end)
	
	return Connection1
end

function UtilitiesModule.LoadedCallback(NilParam, Element, CallbackFunction, ...)
	-- CORE
	local Args = {...}
	local Connection1 = nil
	local CallbackCalled = false
	
	-- Functions
	-- DIRECT
	Connection1 = UtilitiesModule:RenderSteppedFPSLock(30, function()
		if not Element then
			return UtilitiesModule:DisconnectConnections({Connection1})
		end
		
		if not Connection1.Connected or not Element:GetAttributes()["Loaded"] then
			return nil
		end
		
		if CallbackCalled then
			return nil
		end
		
		CallbackCalled = true
		
		UtilitiesModule:DisconnectConnections({Connection1})
		
		return CallbackFunction(unpack(Args))
	end)
end

function UtilitiesModule.GetChangedSignal(NilParam, Element, PropertiesOrAttributes, Callback, ...)
	-- CORE
	local Args = {...}
	local _Connections = {}
	
	-- Functions
	-- INIT
	for i, PropertyName in pairs(PropertiesOrAttributes) do
		local Connection = nil
		
		if UtilitiesModule:HasProperty(Element, PropertyName) then
			Connection = Element:GetPropertyChangedSignal(PropertyName):Connect(function()
				return Callback(PropertyName, unpack(Args))
			end)
		else
			Connection = Element:GetAttributeChangedSignal(PropertyName):Connect(function()
				return Callback(PropertyName, unpack(Args))
			end)
		end
		
		UtilitiesModule:AddToTable(_Connections, Connection)
	end
	
	return _Connections
end

function UtilitiesModule.FindAndRemove(NilParam, Table, ...)
	-- CORE
	local Found, ToReturn = false, nil
	
	-- Functions
	-- INIT
	for i, Needle in pairs({...}) do
		local FoundIndex = table.find(Table, Needle)
		
		if FoundIndex then
			Found = true
			ToReturn = table.remove(Table, FoundIndex)
		end
	end
	
	return Found, ToReturn
end

function UtilitiesModule.ResizeCanvas(NilParam, ScrollingFrame)
	-- CORE
	local ListOrGrid = ScrollingFrame:FindFirstChildOfClass("UIListLayout") or ScrollingFrame:FindFirstChildOfClass("UIGridLayout")
	
	-- Functions
	-- INIT
	if not ListOrGrid then
		return nil
	end
	
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, ListOrGrid.AbsoluteContentSize.Y)
end

function UtilitiesModule.HandleResize(NilParam, ScrollingFrame)
	if not ScrollingFrame:IsA("ScrollingFrame") then
		return nil
	end
	
	-- CORE
	local ListOrGrid = ScrollingFrame:FindFirstChildOfClass("UIListLayout") or ScrollingFrame:FindFirstChildOfClass("UIGridLayout")

	-- Functions
	-- INIT
	if not ListOrGrid then
		return nil
	end
	
	-- MECHANICS
	local function Update()
		ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, ListOrGrid.AbsoluteContentSize.Y)
	end
	
	-- DIRECT
	local Connection1 = ListOrGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Update)

	-- INIT
	Update()

	return Connection1
end


function UtilitiesModule.ChildRemovedOfClass(NilParam, Element, ClassName, CallbackFunction, ...)
	-- CORE
	local Args = {...}

	-- Functions
	-- DIRECT
	local Connection1 = Element.ChildRemoved:Connect(function(Child)
		if Child.ClassName ~= ClassName then
			return nil
		end

		return CallbackFunction(Child, unpack(Args))
	end)

	return Connection1
end

function UtilitiesModule.ChildAddedOfClass(NilParam, Element, ClassName, CallbackFunction, ...)
	-- CORE
	local Args = {...}
	
	-- Functions
	-- DIRECT
	local Connection1 = Element.ChildAdded:Connect(function(Child)
		if Child.ClassName ~= ClassName then
			return nil
		end
		
		return CallbackFunction(Child, unpack(Args))
	end)
	
	return Connection1
end

function UtilitiesModule.ChildAddedRemoved(NilParam, Element, Function, ...)
	-- CORE
	local Args = {...}
	
	-- Functions
	-- DIRECT
	local Connection1 = Element.ChildAdded:Connect(function()
		return Function(unpack(Args))
	end)
	
	local Connection2 = Element.ChildRemoved:Connect(function()
		return Function(unpack(Args))
	end)
	
	return {Connection1, Connection2}
end

function UtilitiesModule.TryFor(NilParam, MaxTries, Function, ...)
	-- CORE
	local Args = {...}
	
	local Tries = 0
	local Success, ToReturn = false, nil
	
	-- Functions
	-- INIT
	while not Success and Tries < MaxTries do
		Tries += 1

		Success, ToReturn = pcall(function()
			return Function(unpack(Args))
		end)
		
		if not Success and Tries < MaxTries then
			task.wait(math.random(50, 100) / 100)
		end
	end
	
	return Success, ToReturn
end

function UtilitiesModule.IsGamepadConnected()
	-- Functions
	-- INIT
	for i = 0, 7 do
		local Success, Response = pcall(function()
			return UserInputService:IsGamepadConnected(Enum.UserInputType["Gamepad" .. i])
		end)
		
		if Success and Response then
			return true
		end
	end
	
	return false
end

function UtilitiesModule.GetPosition(NilParam, Part)
	-- Functions
	-- INIT
	if Part:IsA("Model") then
		return Part:GetPivot().p
	else
		return Part.Position
	end
end

function UtilitiesModule.GetUTCTimeNow()
	-- Functions
	-- INIT
	
	return os.time(os.date("!*t")) -- Convert Time to UTC to seconds
end


function UtilitiesModule.GetCanvasPosition(NilParam, Element, ScrollingFrame)
	-- CORE
	local ElementPosition = Element.Position
	local CanvasPosition = ScrollingFrame.CanvasPosition
	
	-- Functions
	-- INIT
	local RelativePosition = ElementPosition + UDim2.new(0, -CanvasPosition.X, 0, -CanvasPosition.Y)
	
	return RelativePosition
end

function UtilitiesModule.FireClientsExcept(NilParam, Remote, ExceptionTable, ...)
	-- Functions
	-- INIT	
	for i, Player in pairs(game.Players:GetPlayers()) do
		if table.find(ExceptionTable, Player) ~= nil then
			continue
		end
		
		Remote:FireClient(Player, ...)
	end
end

function UtilitiesModule.ClearChildrenOfType(NilParam, Parent, ClassName)
	-- Functions
	-- INIT
	for i, Child in pairs(Parent:GetChildren()) do
		if Child.ClassName ~= ClassName then
			continue
		end
		
		Child:Destroy()
	end
end

function UtilitiesModule.GetLongestLengthOfCube(NilParam, Part)
	-- CORE
	local Size = UtilitiesModule:GetSize(Part)
	
	-- Functions
	-- INIT
	--[[if Part:IsA("Model") then
		Size = Part:GetExtentsSize()
	else
		Size = Part.Size
	end]]
	
	return math.sqrt(Size.X^2 + Size.Y^2 + Size.Z^2)
end

function UtilitiesModule.GetSize(NilParam, _Instance)
	-- Functions
	-- INIT
	if _Instance:IsA("Model") then
		--local _CFrame, _Size = _Instance:GetBoundingBox()
		
		return _Instance:GetExtentsSize()
	else
		return _Instance.Size
	end
end

function UtilitiesModule.PivotTo(NilParam, _Instance, TargetCFrame)
	-- Functions
	-- INIT
	if _Instance:IsA("Model") then
		_Instance:PivotTo(TargetCFrame)
	else
		_Instance.CFrame = TargetCFrame
	end
end

function UtilitiesModule.GetCFrame(NilParam, _Instance)
	-- Functions
	-- INIT
	if _Instance:IsA("Model") then
		return _Instance:GetPivot()
	else
		return _Instance.CFrame
	end
end

function UtilitiesModule.TweenScale(NilParam, model, tweenInfo, startScale, endScale, _Wait, startTime)
	-- CORE	
	--local Elapsed = 0
	local startTime = startTime or time()
	
	local Scale = 0
	local TweenConnection = nil

	-- FUNCTIONS
	-- MECHANICS
	local function onStep(deltaTime)
		--Elapsed = math.min(Elapsed + deltaTime, tweenInfo.Time)
		local TimeNow = time()
		local Elapsed = math.clamp(TimeNow - startTime, 0, tweenInfo.Time)

		local alpha = TweenService:GetValue(Elapsed / tweenInfo.Time, tweenInfo.EasingStyle, tweenInfo.EasingDirection)

		Scale = UtilitiesModule:Lerp(startScale, endScale, alpha) --startScale + alpha * (endScale - startScale)

		model:ScaleTo(Scale)
 
		if Elapsed == tweenInfo.Time then
			TweenConnection:Disconnect()
		end
	end


	TweenConnection = UtilitiesModule:RenderSteppedFPSLock(30, onStep) --RunService.Heartbeat:Connect(onStep)
	
	if _Wait then
		repeat
			task.wait()
		until not TweenConnection.Connected or not model
	end
	
	return TweenConnection
end

function UtilitiesModule.SetPropertiesOfChildren(NilParam, Element, Properties, ParentInclusive)
	-- CORE
	local ToLoopThrough = Element:GetChildren()
	
	-- Functions
	-- INIT
	if ParentInclusive then
		table.insert(ToLoopThrough, Element)
	end
	
	for i, Child in pairs(ToLoopThrough) do
		for PropertyName, PropertyValue in pairs(Properties) do
			if not UtilitiesModule:HasProperty(Child, PropertyName) then
				continue
			end
			
			Child[PropertyName] = PropertyValue
		end
	end
end

function UtilitiesModule.AttributeRemoved(NilParam, Element, CallbackFunction, ...)
	-- CORE
	local AttributeNames = Element:GetAttributes()
	local Args = {...}

	-- Functions
	-- INIT
	local Connection1 = RunService.Stepped:Connect(function()
		local _AttributeNames = Element:GetAttributes()

		for Name, Value in pairs(AttributeNames) do
			if _AttributeNames[Name] == nil then
				coroutine.wrap(function()
					CallbackFunction(unpack(Args))
				end)()

				break
			end
		end

		AttributeNames = _AttributeNames
	end)

	return Connection1
end

function UtilitiesModule.AttributeAdded(NilParam, Element, CallbackFunction, ...)
	-- CORE
	local AttributeNames = Element:GetAttributes()
	local Args = {...}
	
	-- Functions
	-- INIT
	local Connection1 = RunService.Stepped:Connect(function()
		local _AttributeNames = Element:GetAttributes()
		
		for Name, Value in pairs(_AttributeNames) do
			if AttributeNames[Name] == nil then
				coroutine.wrap(function()
					CallbackFunction(unpack(Args))
				end)()
				
				break
			end
		end
		
		AttributeNames = _AttributeNames
	end)
	
	return Connection1
end

function UtilitiesModule.RenderSteppedFPSLock(NilParam, FPS, CallBackFunction, ...)
	-- CORE
	local Args = {...}
	local Connection1 = nil
	local StartTime = time()
	
	-- Functions
	-- INIT
	local Frames = 0
	local DeltaTime = 0
	local AverageDelta = 1 / FPS

	local function OnRenderStep(Time, Delta, Force)	
		-- CORE
		DeltaTime = DeltaTime + Delta
				
		if (DeltaTime < AverageDelta) and not Force then
			return nil
		end
		
		local _DeltaTime = DeltaTime
		DeltaTime = 0
		
		CallBackFunction(_DeltaTime, unpack(Args))
	end

	-- DIRECT
	if RunService:IsClient() then
		Connection1 = RunService.Stepped:Connect(OnRenderStep)
	elseif RunService:IsServer() then
		Connection1 = RunService.Heartbeat:Connect(function(Delta)
			return OnRenderStep(time() - StartTime, Delta)
		end)
	end
	
	-- INIT
	coroutine.wrap(function()
		local Success, Error = pcall(function()
			return OnRenderStep(0, 0, true) -- First call, so 0 for both timers
		end)
	end)()

	return Connection1
end

function UtilitiesModule.ToggleParticles(NilParam, Particle, ToggleValue)
	-- CORE
	local TableOfParticles = nil
	
	-- Functions
	-- INIT
	if typeof(Particle) == "Instance" then
		TableOfParticles = {Particle, unpack(Particle:GetDescendants())}
	else
		TableOfParticles = Particle -- Assume it's a table
	end

	for i, ParticleEmitter in pairs(TableOfParticles) do
		if not ParticleEmitter:IsA("ParticleEmitter") then
			continue
		end
		
		ParticleEmitter.Enabled = ToggleValue
	end
end

function UtilitiesModule.GetScreenSize(NilParam, FullScreen)
	-- Functions
	-- INIT
	--[[if game:GetService("RunService"):IsStudio() then 
		warn("Call of GetScreenSize() inside studio returns the viewport dimensions, not the actual screen dimensions!")
	end]]

	if FullScreen then 
		local GameSettings = UserSettings().GameSettings 
		if not GameSettings:InFullScreen() then 
			GameSettings.FullscreenChanged:Wait() 
		end
	end 

	-- Instancing
	local UI = Instance.new("ScreenGui")
	UI.ScreenInsets = Enum.ScreenInsets.None 
	UI.Parent = game.Players.LocalPlayer.PlayerGui
	local size = UI.AbsoluteSize 
	
	--
	UI:Destroy() 

	return size*3
end

function UtilitiesModule.GetInitials(NilParam, String)
	-- Functions
	-- INIT
	local FinalString = ""
	
	for i, Word in pairs(string.split(String, " ")) do
		FinalString = FinalString.. string.upper(string.sub(Word, 1, 1))
	end
	
	return FinalString
end

function UtilitiesModule.MatchString(NilParam, VariableLengthString, FullString, CaseSensitive)
	-- CORE
	if not CaseSensitive then
		VariableLengthString = string.lower(VariableLengthString)
		FullString = string.lower(FullString)
	end
	
	-- Functions
	-- INIT
	if string.sub(FullString, 1, string.len(VariableLengthString)) == VariableLengthString then
		return true
	end
	
	return false
end

function UtilitiesModule.AddToTable(NilParam, Table, ...)
	-- Functions
	-- INIT
	for i, Value in pairs({...}) do
		table.insert(Table, Value)
	end
end

function UtilitiesModule.AddToColor3(NilParam, RGBValue, Amplifier, DontClamp)
	RGBValue = Color3ToRGB(RGBValue)
	
	local NewR = nil
	local NewG = nil
	local NewB = nil
	
	if not DontClamp then
		NewR = RGBValue.R + Amplifier
		NewG = RGBValue.G + Amplifier
		NewB = RGBValue.B + Amplifier
	else
		NewR = math.clamp(RGBValue.R + Amplifier, 0, 255)
		NewG = math.clamp(RGBValue.G + Amplifier, 0, 255)
		NewB = math.clamp(RGBValue.B + Amplifier, 0, 255)
	end

	return Color3FromRGB({R = NewR, G = NewG, B = NewB})

	--return {R = RGBValue.R + Amplifier, G = RGBValue.G + Amplifier, B = RGBValue.B + Amplifier}
end

function UtilitiesModule.EndSubModulesCoroutine(NilParam, RequiredModules, ...)
	-- CORE
	local Args = {...}
	
	-- Functions
	-- INIT	
	if typeof(RequiredModules) == "Instance" then
		RequiredModules = UtilitiesModule:RunSubModules(RequiredModules, true)
	end
	
	for ModuleName, Module in pairs(RequiredModules or {}) do
		coroutine.wrap(function()
			local Success, Error = pcall(function()
				if Module and Module.End ~= nil then
					return Module:End(unpack(Args))
				end
			end)

			if not Success then
				print(script.Name.. " | EndSubModules | ModuleName: ".. tostring(ModuleName).. " | Module: ".. tostring(Module).. " | Args: ".. tostring(Args).. " | Error: ".. tostring(Error))
			end
		end)()
	end
end

function UtilitiesModule.LoadSubModules(NilParam, Parent)
	if typeof(Parent) == "table" then
		return Parent
	end

	-- CORE
	local Dict = {}

	local PriorityFolder = Parent:FindFirstChild("Priority")

	-- Functions
	-- INIT
	--[[if PriorityFolder and PriorityFolder:IsA("Folder") then
		UtilitiesModule:RunSubModules(PriorityFolder)
	end]]

	for i, Module in pairs(UtilitiesModule:GetChildrenOfClass(Parent, "ModuleScript")) do
		if not Module:IsA("ModuleScript") then
			continue
		end

		local RequiredModule = nil

		local Success, Error = pcall(function()
			RequiredModule = require(Module)			
		end)

		if not Success then
			print(script.Name.. " | RunSubModules | Parent: ".. tostring(Parent).. " | Module: ".. tostring(Module).. " | Error: ".. tostring(Error))
			continue
		end

		Dict[Module.Name] = RequiredModule
	end

	return Dict
end

function UtilitiesModule.EndSubModules(NilParam, RequiredModules, ...)
	-- CORE
	local Args = {...}
	
	-- Functions
	-- INIT
	if typeof(RequiredModules) == "Instance" then
		RequiredModules = UtilitiesModule:RunSubModules(RequiredModules, true)
	end
	
	for ModuleName, Module in pairs(RequiredModules or {}) do
		local Success, Error = pcall(function()
			if Module and Module.End ~= nil then
				return Module:End(unpack(Args))
			end
		end)
		
		if not Success then
			print(script.Name.. " | EndSubModules | ModuleName: ".. tostring(ModuleName).. " | Module: ".. tostring(Module).. " | Args: ".. tostring(Args).. " | Error: ".. tostring(Error))
		end
	end
end

function UtilitiesModule.RunSubModulesCoroutine(NilParam, Parent, IgnoreInitialise, ...)
	-- CORE
	local Dict = {}
	local Args = {...}	
	
	local Goal = #Parent:GetChildren()
	local Current = 0
	
	local PriorityFolder = Parent:FindFirstChild("Priority")
	
	-- Functions
	-- INIT
	if PriorityFolder and PriorityFolder:IsA("Folder") then
		UtilitiesModule:RunSubModulesCoroutine(PriorityFolder, IgnoreInitialise, ...)
	end
	
	for i, Module in pairs(Parent:GetChildren()) do
		if not Parent or not Module then
			continue
		end
		
		if not Module:IsA("ModuleScript") then
			continue
		end
		
		task.spawn(function()
			local Success, Error = UtilitiesModule:RunModule(Module, IgnoreInitialise, unpack(Args))

			if not Success then
				print(script.Name.. " | RunSubModules | Parent: ".. tostring(Parent).. " | Module: ".. tostring(Module).. " | Error: ".. tostring(Error))
			else
				Dict[Module.Name] = Error
			end
			
			Current += 1
		end)
	end
	
	repeat
		task.wait()
	until Current >= Goal
	
	return Dict
end

function UtilitiesModule.RunModule(NilParam, Module, IgnoreInitialise, ...)
	-- CORE
	local Dict = {}
	local Args = {...}	

	-- Functions
	-- INIT
	local Success, RequiredModule = pcall(function()
		local _RequiredModule = require(Module)

		if not IgnoreInitialise then
			if _RequiredModule and _RequiredModule.Initialise ~= nil then
				_RequiredModule:Initialise(unpack(Args))
			end
		end
		
		return _RequiredModule

		--return true, _RequiredModule
	end)
	
	if not Success then
		return print(script.Name.. " | RunModule | Module: ".. tostring(Module).. " | IgnoreInitialise: ".. tostring(IgnoreInitialise).. " | Args: ".. tostring(Args).. " | Error: ".. tostring(RequiredModule))
	end 

	return Success, RequiredModule
end

function UtilitiesModule.RunSubModules(NilParam, Parent, IgnoreInitialise, ...)
	-- CORE
	local Dict = {}
	local Args = {...}	
	
	local PriorityFolder = Parent:FindFirstChild("Priority")

	-- Functions
	-- INIT
	if PriorityFolder and PriorityFolder:IsA("Folder") then
		UtilitiesModule:RunSubModules(PriorityFolder, IgnoreInitialise, ...)
	end
	
	for i, Module in pairs(Parent:GetChildren()) do
		if not Module:IsA("ModuleScript") then
			continue
		end
		
		local Success, Error = UtilitiesModule:RunModule(Module, IgnoreInitialise, ...)

		if not Success then
			--print(script.Name.. " | RunSubModules | Parent: ".. tostring(Parent).. " | Module: ".. tostring(Module).. " | Error: ".. tostring(Error))
		else
			Dict[Module.Name] = Error
		end
	end
	
	return Dict
end

function UtilitiesModule.DestroyAllSounds(NilParam, Sounds)
	-- Fuunctions
	-- INIT
	for i, Sound in pairs(Sounds) do
		if not Sound then
			continue
		end
		
		if Sound.IsPlaying then
			Sound:Stop()
		end
		
		Sound:Destroy()
	end
end


function UtilitiesModule.GetRootModel(NilParam, Model)
	-- Functions
	-- INIT
	local Root = Model
	local CurrentRoot = Root

	while CurrentRoot --[[and task.wait()]] do
		CurrentRoot = CurrentRoot:FindFirstAncestorOfClass("Model")

		if CurrentRoot then
			Root = CurrentRoot
		else
			break
		end
	end

	return Root
end

function UtilitiesModule.GetTotalMass(NilParam, _Instance)
	-- CORE
	local RunningTotal = 0
	
	-- Functions
	-- INIT
	if _Instance:IsA("Model") then
		for i, Part in pairs(_Instance:GetDescendants()) do
			if not Part:IsA("BasePart") then
				continue
			end
			
			RunningTotal += Part:GetMass()
		end
	else
		RunningTotal = _Instance:GetMass()
	end
	
	return RunningTotal
end

function UtilitiesModule.RoundNumber(NilParam, Number, Decimals)
	-- Functions
	-- INIT
	local mult = 10^(Decimals or 0)
	return math.floor(Number * mult + 0.5) / mult
end

function UtilitiesModule.Lerp(NilParam, StartNumber, EndNumber, Percentage)
	-- Functions
	-- INIT
	return StartNumber + (EndNumber - StartNumber) * Percentage
end

function UtilitiesModule.FindFirstAncestorOfClass(NilParam, Element, Classes)
	-- CORE
	local Response = nil
	
	-- Functions
	-- INIT
	if typeof(Classes) == "string" then
		Classes = {Classes}
	end
	
	local CurrentParent = {["Parent"] = Element}	
	local Success, Error = true, nil

	repeat
		Success, Error = pcall(function()
			CurrentParent = CurrentParent.Parent

			if table.find(Classes, CurrentParent.ClassName) ~= nil then
				Response = CurrentParent
			end
		end)
	until not Element or not Success or Response

	return Response
end

function UtilitiesModule.RoundVector3(NilParam, _Vector3, Decimals)
	-- Functions
	-- INIT
	local Order = {"X", "Y", "Z"}
	local Components = {}
	
	for _, PropertyName in pairs(Order) do
		local StringNumber = tostring(_Vector3[PropertyName])
		
		local FoundDecimal = string.find(StringNumber, ".") or string.len(StringNumber)
		
		table.insert(Components, tonumber(string.sub(StringNumber, 1, FoundDecimal + Decimals)))
	end
	
	return Vector3.new(unpack(Components))
end

function UtilitiesModule.FlipVector3(NilParam, _Vector3)
	-- CORE
	local newTable = {}
	
	-- Functions
	-- INIT
	local Order = {"X", "Y", "Z"}
	
	for i, PropertyName in pairs(Order) do
		if _Vector3[PropertyName] == 1 then
			newTable[PropertyName] = 0
		else
			newTable[PropertyName] = 1
		end
	end
	
	return Vector3.new(unpack(newTable))
end

function UtilitiesModule.SetCollisionGroup(NilParam, Model, Name)
	-- Functions
	-- INIT
	local Descendants = Model:GetDescendants()
	
	if Model:IsA("BasePart") then
		Model.CollisionGroup = Name
	end
	
	for i, Part in pairs(Descendants) do
		if Part:IsA("BasePart") then
			Part.CollisionGroup = Name
		end
	end
end

function UtilitiesModule.MapValue(NilParam, n, start, stop, newStart, newStop)
	return ((n - start) / (stop - start)) * (newStop - newStart) + newStart
end

function UtilitiesModule.Colour3ToRGB(NilParam, Color3Value)
	return {R = Color3Value.r * 255, G = Color3Value.g * 255, B = Color3Value.b * 255}
end

function UtilitiesModule.TypeToColor3(NilParam, _Value)
	-- CORE
	local TypeToColor3 = 
	{
		["string"] = function(Value)
			return BrickColor.new(Value).Color
		end,
		["BrickColor"] = function(Value)
			return Value.Color
		end,
		["Color3"] = function(Value)
			return Value
		end,
	}

	-- Functions
	-- INIT
	return TypeToColor3[typeof(_Value)](_Value)
end

function UtilitiesModule.GetAllPartsIncludingParent(NilParam, Part)
	-- Core
	local Parts = {}
	
	-- Functions
	-- INIT
	for i, _Part in pairs(Part:GetDescendants()) do
		if not _Part:IsA("BasePart") then
			continue
		end
		
		table.insert(Parts, _Part)
	end
	
	if Part:IsA("BasePart") then
		table.insert(Parts, Part)
	end
	
	return Parts
end

function UtilitiesModule.GetClasses()
	return RequiredModules["Data"]["Classes"]
end

function UtilitiesModule.GetLerpEasing()
	return RequiredModules["Data"]["LerpEasing"]
end

function UtilitiesModule.GetSpringModule()
	return RequiredModules["Service"]["Spring"]
end

function UtilitiesModule.SecondsToMilliseconds(NilParam, Seconds)
	return (Seconds * 1000)
end

function UtilitiesModule.SecondsToMinutes(NilParam, Seconds, Round)
	-- Functions
	-- INIT
	if not Round then
		return (Seconds / 60)
	else
		return math.floor(Seconds / 60)
	end
end

function UtilitiesModule.GetServerRegion()
	-- Functions
	-- INIT
	local Success, Response = pcall(function()
		return HttpService:GetAsync("http://ip-api.com/json/")
	end)

	if Success then
		Response = HttpService:JSONDecode(Response)
		return Response["country"]
	end
end

function UtilitiesModule.ClearTable(NilParam, Table)
	-- Functions
	-- INIT
	for key, val in pairs(Table) do
		if val and typeof(val) == "Instance" then
			val:Destroy()
		end
		
		--
		if typeof(val) == "table" then
			UtilitiesModule:ClearTable(val)
		end
		--
		
		Table[key] = nil
	end
	
	return Table
end

function UtilitiesModule.SetNetworkOwner(NilParam, Model, Owner)
	-- Functions
	-- INIT
	for i, Part in pairs({Model, unpack(Model:GetDescendants())}) do
		if not Part:IsA("BasePart") then
			continue
		end
		
		local Success, Error = pcall(function()
			return Part:SetNetworkOwner(Owner)
		end)
		
		if not Success then
			print(script.Name.. " | SetNetworkOwner | Model: ".. tostring(Model).. " | Owner: ".. tostring(Owner).. " | Part: ".. tostring(Part).. " | Error: ".. tostring(Error))
		end
	end
end

function UtilitiesModule.CheckTableType(NilParam, Table)
	-- CORE
	local IsArray = true
	
	-- Functions
	-- INIT
	for Key, _ in pairs(Table) do
		if type(Key) ~= "number" or Key % 1 ~= 0 then
			IsArray = false
			break
		end
	end
	
	if IsArray then
		return "Array"
	else
		return "Dictionary"
	end
end

function UtilitiesModule.CombineTables(NilParam, ...)
	-- Functions
	-- INIT
	local JointTable = {}
	
	for i, Table in pairs({...}) do
		for Key, Element in pairs(Table) do
			if UtilitiesModule:CheckTableType(Table) == "Array" then
				table.insert(JointTable, Element)
			else
				JointTable[Key] = Element
			end
		end
	end
	
	return JointTable
end

function UtilitiesModule.UnpackConnectionsToLargeTable(NilParam, ...)
	-- Functions
	-- INIT
	local LargeTable = {}
	
	for i, ConnectionTable in pairs({...}) do
		for x, Connection in pairs(ConnectionTable) do
			table.insert(LargeTable, Connection)
		end
	end
	
	return LargeTable
end

function UtilitiesModule.ChooseRandomFromArray(NilParam, Array)
	-- Functions
	-- INIT
	return Array[math.random(1, #Array)]
end

function UtilitiesModule.HasProperty(NilParam, _Instance, PropertyName)
	-- Functions
	-- INIT
	local Success, Error = pcall(function()
		local Result = _Instance[PropertyName]
	end)
	
	return Success
end

function UtilitiesModule.FormatNumber(NilParam, Number)
	-- Functions
	-- INIT
	
	Number = tonumber(Number)
	
	if Number == nil then
		return "nil"
	end
	
	if Number <= 1000 then
		return Number
	end
	
	local n = Number
	
	--local suffixes = {"K", "M", "B", "T", "Q"} -- numbers don't go higher than 'Q' in Lua.
	
	local T = {"K","M","B","T","q","Q","s","S","O","N","d","U","D"}
	
	if not tonumber(n) then return n end
	if n < 10000 then return math.floor(n) end
	local d = math.floor(math.log10(n)/3)*3
	local s = tostring(n/(10^d)):sub(1,5)
	return s.." "..tostring(T[math.floor(d/3)])
end

function UtilitiesModule.FormatTime(NilParam, Seconds)
	-- Functions
	-- INIT
	if Seconds == nil then
		return "nil"
	end
	
	local TimeInHours = math.floor(Seconds / 3600)
	Seconds = Seconds - (TimeInHours * 3600)	
	local TimeInMinutes = math.floor(Seconds / 60)
	Seconds = math.floor(Seconds - (TimeInMinutes * 60))
	
	return FormatToDoubleDigit(TimeInHours).. " : ".. FormatToDoubleDigit(TimeInMinutes).. " : ".. FormatToDoubleDigit(Seconds)
end

function UtilitiesModule.PromptSetFavourite()
	-- Functions
	-- INIT
	AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
end

function UtilitiesModule.PromptPushNotifications()
	-- Functions
	-- INIT
	if UtilitiesModule:CanPromptPushNotifications() then
		local Success, Error = pcall(function()
			ExperienceNotificationService:PromptOptIn()
		end)
		
		if not Success then
			print(script.Name.. " | PromptPushNotifications | Error: ".. tostring(Error))
		end
	end
end

function UtilitiesModule.CanPromptPushNotifications()
	-- Functions
	-- INIT
	local Success, CanPrompt = pcall(function()
		return ExperienceNotificationService:CanPromptOptInAsync()
	end)
	
	if not Success then
		print(script.Name.. " | CanPromptPushNotifications | Error: ".. tostring(CanPrompt))
	end
	
	return Success and CanPrompt
end

function UtilitiesModule.OpenGameInvites(NilParam, TargetPlayer, Force)
	-- Functions
	-- INIT
	if not Force then
		if UtilitiesModule:CanSendGameInvite(TargetPlayer) then
			local Success, Error = pcall(function()
				return SocialService:PromptGameInvite(TargetPlayer)
			end)
		end
	else
		local Success, Error = pcall(function()
			return SocialService:PromptGameInvite(TargetPlayer)
		end)
	end
end

function UtilitiesModule.CanSendGameInvite(NilParam, TargetPlayer)
	-- Functions
	-- INIT
	local Success, CanInvite = UtilitiesModule:TryFor(1, function()
		return SocialService:CanSendGameInviteAsync(TargetPlayer)
	end)
	
	return Success and CanInvite
end

function UtilitiesModule.PackSavableValue(NilParam, Value)
	-- Functions
	-- INIT
	if typeof(Value) == "Color3" then
		return UtilitiesModule:Color3ToTable(Value)
	elseif typeof(Value) == "BrickColor" then
		return Value.Name
	else
		return Value
	end
end

function UtilitiesModule.UnPackSavableValue(NilParam, Value)
	-- Functions
	-- INIT
	if typeof(Value) == "table" and Value.Type ~= nil and Value.Type == "Color3" then
		return Color3.fromRGB(Value.R, Value.G, Value.B)
	elseif typeof(Value) == "string" and UtilitiesModule:DoesBrickColourExist(Value) then
		return BrickColor.new(Value)
	else
		return Value
	end
end

function UtilitiesModule.DoesBrickColourExist(NilParam, ColourName)
	-- Functions
	-- INIT
	if table.find(BrickColorsModule:GetBrickColourNames(), ColourName) then
		return true
	else
		local Success, Error = pcall(function()
			return BrickColor.new(ColourName)
		end)
		
		if Success then
			return true
		end
		
		print("Utilities | BrickColour: ".. tostring(ColourName).. " doesn't exist!")
		return false
	end
end

function UtilitiesModule.IsCharacterDead(NilParam, Character)
	-- Functions
	-- INIT
	if not Character then
		return nil
	end

	local Humanoid = UtilitiesModule:WaitForChildOfClass(Character, "Humanoid")

	if Humanoid.Health <= 0 then
		return true
	end
end

function UtilitiesModule.IsPlayerTouching(NilParam, Player, Part)
	-- Functions	
	-- INIT
	if not Part then
		return nil
	end

	local Character = UtilitiesModule:GetCharacter(Player, true)

	if not Character then
		return nil
	end

	local HumanoidRootPart = Character.PrimaryPart

	if not HumanoidRootPart then
		return nil
	end

	local Distance = (UtilitiesModule:GetCFrame(HumanoidRootPart).p - UtilitiesModule:GetCFrame(Part).p).Magnitude

	if Distance > (UtilitiesModule:GetLongestLengthOfCube(Part) / 2) then
		return nil
	end

	local Response = false

	local Connection1 = Part.Touched:Connect(function()
		return nil
	end)

	for i, HitPart in pairs(Part:GetTouchingParts()) do
		if HitPart:IsDescendantOf(Character) then
			Response = true
			break
		end
	end

	UtilitiesModule:DisconnectConnections({Connection1})

	return Response
end

function UtilitiesModule.IsPlayerDead(NilParam, Player)
	-- CORE
	local Character = UtilitiesModule:GetCharacter(Player, true)
	
	-- Functions
	-- INIT
	return UtilitiesModule:IsCharacterDead(Character)
end

function UtilitiesModule.IsPrivateServer()
	-- Functions
	-- INIT
	if game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0 then
		return nil
	end
end

function UtilitiesModule.GetNumberFromSequence(NilParam, _NumberSequence, Time)
	-- Functions
	-- INIT
	if not _NumberSequence or typeof(NumberSequence) == "number" then
		return _NumberSequence
	end

	if Time == 0 then
		return _NumberSequence.Keypoints[1].Value
	elseif Time == 1 then
		return _NumberSequence.Keypoints[#_NumberSequence.Keypoints].Value
	end

	if not _NumberSequence.Keypoints then
		return _NumberSequence
	end

	for i = 1, #_NumberSequence.Keypoints - 1 do
		local ThisNumber = _NumberSequence.Keypoints[i]
		local NextNumber = _NumberSequence.Keypoints[i + 1]

		if Time > ThisNumber.Time and Time < NextNumber.Time then
			local Alpha = (Time - ThisNumber.Time) / (NextNumber.Time - ThisNumber.Time)

			return (NextNumber.Value - ThisNumber.Value) * Alpha + ThisNumber.Value
		end
	end
end

function UtilitiesModule.GetColourFromSequence(NilParam, ColourSequence, Time)
	-- Functions
	-- INIT
	if not ColourSequence or typeof(ColorSequence) == "Color3" then
		return ColourSequence
	end
	
	if Time == 0 then
		return ColourSequence.Keypoints[1].Value
	elseif Time == 1 then
		return ColourSequence.Keypoints[#ColourSequence.Keypoints].Value
	end
	
	if not ColourSequence.Keypoints then
		return ColourSequence.Color
	end
	
	for i = 1, #ColourSequence.Keypoints - 1 do
		local ThisColour = ColourSequence.Keypoints[i]
		local NextColour = ColourSequence.Keypoints[i + 1]
		
		if Time > ThisColour.Time and Time < NextColour.Time then
			local Alpha = (Time - ThisColour.Time) / (NextColour.Time - ThisColour.Time)
			
			return Color3.new(
				(NextColour.Value.R - ThisColour.Value.R) * Alpha + ThisColour.Value.R,
				(NextColour.Value.G - ThisColour.Value.G) * Alpha + ThisColour.Value.G,
				(NextColour.Value.B - ThisColour.Value.B) * Alpha + ThisColour.Value.B
			)
		end
	end
end

function UtilitiesModule.DescendantAddedOfClass(NilParam, Parent, ClassName, CallbackFunction, ...)
	-- CORE
	local Args = {...}
	
	-- Functions
	-- DIRECT
	local Connection1 = Parent.DescendantAdded:Connect(function(Child)
		if Child.ClassName ~= ClassName then
			return nil
		end
		
		return CallbackFunction(unpack(Args))
	end)
	
	return Connection1
end

function UtilitiesModule.GetDescendantsOfClass(NilParam, Parent, ClassName)
	-- CORE
	local Descendants = {}
	
	-- Functions
	-- INIT
	for i, Descendant in pairs(Parent:GetDescendants()) do
		if Descendant.ClassName ~= ClassName then
			continue
		end
		
		UtilitiesModule:AddToTable(Descendants, Descendant)
	end
	
	return Descendants
end

function UtilitiesModule.GetChildrenMatchingProperties(NilParam, Parent, Properties)
	-- CORE
	local Children = {}

	-- Functions
	-- INIT
	for i, Child in pairs(Parent:GetChildren()) do
		local Skip = false

		local Attributes = Child:GetAttributes() or {}
	
		for PropertyName, PropertyValue in pairs(Properties) do
			if UtilitiesModule:HasProperty(Child, PropertyName) then
				if Child[PropertyName] ~= PropertyValue then
					Skip = true
					break
				end
			else
				if Attributes[PropertyName] ~= PropertyValue then
					Skip = true
					break
				end
			end
		end
		
		if not Skip then
			UtilitiesModule:AddToTable(Children, Child)
		end
	end
	
	return Children
end

function UtilitiesModule.GetChildrenOfClass(NilParam, Parent, ClassName)
	--
	if typeof(ClassName) == "table" then
		local Children = {}
		
		for i, _ClassName in pairs(ClassName) do
			UtilitiesModule:AddToTable(Children, unpack(UtilitiesModule:GetChildrenOfClass(Parent, _ClassName)))
		end
		
		return Children
	end
	
	
	-- CORE
	local Children = {}
	
	-- Functions
	-- INIT
	for i, Child in pairs(Parent:GetChildren()) do
		if Child.ClassName ~= ClassName then
			continue
		end
		
		table.insert(Children, Child)
	end
	
	return Children
end

function UtilitiesModule.GetChildrenNames(NilParam, Parent)
	-- CORE
	local ChildrenNames = {}
	
	-- Functions
	-- INIT
	for i, Child in pairs(Parent:GetChildren()) do
		if not Child then
			continue
		end
		
		table.insert(ChildrenNames, Child.Name)
	end
	
	return ChildrenNames
end

function UtilitiesModule.GetFPS()
	return RequiredModules["Service"]["FPS"]:GetFPS()
end

function UtilitiesModule.LoadAnimations(NilParam, Animations, AnimationInstancesTable, AnimationToLoadDict, Animator, WaitTilFinished, AttributesToSet)
	-- CORE
	AttributesToSet = AttributesToSet or {}
	
	-- Functions
	-- INIT
	local NeedToLoad = UtilitiesModule:GetSizeOfDict(Animations)
	local Loaded = 0
	local MaxAttempts = 20
	
	local PreWaitTimeOut = 15 -- Seconds to wait for world-based descendant
	
	if not Animator then
		print(script.Name.. " | LoadAnimations | No animator given!")
		return nil
	end
	
	coroutine.wrap(function()
		local PreWaitStartTime = UtilitiesModule:GetTick()
		local PreWaitTimeSpan = 0
		local PassedWait = false
		
		repeat
			PreWaitTimeSpan = (UtilitiesModule:GetTick() - PreWaitStartTime)
			task.wait()
			
			if UtilitiesModule:IsDescendantOfClass(Animator, {"WorldModel", "Workspace"}) then
				PassedWait = true
			end
		until PreWaitTimeSpan > PreWaitTimeOut or PassedWait or not Animator
		
		if not PassedWait then
			return nil
		end
		
		for InstanceName, AnimationInfo in pairs(Animations) do
			-- Instancing		
			coroutine.wrap(function()
				local Attempts = 0
				local Success, Error = false, nil

				local Animation = Instance.new("Animation")
				Animation.AnimationId = AnimationInfo.Id
				
				if AnimationInstancesTable then
					table.insert(AnimationInstancesTable, Animation)
				end
				
				repeat
					Success, Error = pcall(function()
						RunService.Stepped:Wait()
						AnimationToLoadDict[InstanceName] = Animator:LoadAnimation(Animation)
						--AnimationToLoadDict[InstanceName]:AdjustWeight(1)
						
						--[[if FpsInfoModule:GetFpsInfo("AnimationPriorities")[InstanceName] then
							AnimationToLoadDict[InstanceName].Priority = FpsInfoModule:GetFpsInfo("AnimationPriorities")[InstanceName] --Enum.AnimationPriority.Action4
						end]]
					end)
					
					if not Success then
						--warn("Retrying to load animation: '".. tostring(InstanceName).. "' | Error: ".. tostring(Error))
						task.wait(.05)
						Attempts += 1
					else
						for AttributeName, AttributeValue in pairs(AttributesToSet) do
							AnimationToLoadDict[InstanceName]:SetAttribute(AttributeName, AttributeValue)
						end
					end
				until Success or not Animator or Attempts >= MaxAttempts
				
				if Success and Animator then
					repeat
						task.wait()
					until AnimationToLoadDict[InstanceName].Length > 0
				end
				
				Loaded += 1
			end)()
		end
	end)()
	
	if WaitTilFinished then
		repeat
			task.wait()
		until Loaded >= NeedToLoad
	end
end

function UtilitiesModule.GetHumanoidFromHit(NilParam, HitPart)
	-- Functions
	-- INIT
	if not HitPart then
		return nil
	end
	
	local LastParent = HitPart
	
	local Humanoid = LastParent:FindFirstChildOfClass("Humanoid")	

	--pcall(function()		
			
	--[[if not Humanoid then
		for i = 1, 5 do
			if Humanoid then
				break --return Humanoid
			end
		
			LastParent = LastParent:FindFirstAncestorOfClass("Model")
				
			if not LastParent then
				break --return Humanoid
			end
			
			Humanoid = LastParent:FindFirstChildOfClass("Humanoid")
		end
	end
	--end)[[]]
	
	local RootModel = UtilitiesModule:GetRootModel(HitPart)
	
	if RootModel then
		Humanoid = RootModel:FindFirstChildOfClass("Humanoid")
	else
		Humanoid = HitPart:FindFirstChildofClass("Humanoid")
	end
	
	return Humanoid
end

function UtilitiesModule.WaitUntilLoaded(NilParam, Model)
	-- Functions
	-- INIT
	for i, _Model in pairs({Model, unpack(Model:GetChildren())}) do
		-- CORE
		local StartTime = UtilitiesModule:GetTick()
		local Logged = false
		
		-- Functions
		-- INIT
		repeat
			local TimeNow = UtilitiesModule:GetTick()
			local TimeSpan = TimeNow - StartTime
			
			if TimeSpan > 5 and not Logged then
				Logged = true
				print(script.Name.. " | WaitUntilLoaded | Model: ".. tostring(Model).. " | MIGHT INFINITE YIELD")
			end
			
			task.wait()
		until _Model 
	end
	
	task.wait()
end

function UtilitiesModule.GetPartToShift(NilParam, Model)
	-- Functions
	-- INIT
	if Model == nil or typeof(Model) ~= "Instance" then
		return nil
	end
	
	if Model:IsA("Model") then
		if Model.PrimaryPart then
			return Model.PrimaryPart
		else
			return Model:FindFirstChild("Base")
		end
	else
		return Model
	end
end

function UtilitiesModule.GetPlayerCharacterModule(NilParam, Player, ModuleType, ModuleName)
	-- CORE
	local Character = UtilitiesModule:GetCharacter(Player)
	local CharacterGameFolder = UtilitiesModule:WaitForChildTimed(Character, "Game")
	local CharacterModulesFolder = UtilitiesModule:WaitForChildTimed(CharacterGameFolder, "Modules")
	local CharacterModuleTypeFolder = UtilitiesModule:WaitForChildTimed(CharacterModulesFolder, ModuleType)

	-- Functions
	-- INIT
	return CharacterModuleTypeFolder:FindFirstChild(ModuleName) --UtilitiesModule:WaitForChildTimed(UtilitiesModule:WaitForChildTimed(UtilitiesModule:WaitForChildTimed(Character, "Game"):WaitForChild("Modules"), ModuleType), ModuleName)
end

function UtilitiesModule.GetPlayerCharacterClientRemote(NilParam, Player, RemoteName)
	-- CORE
	local Character = UtilitiesModule:GetCharacter(Player)
	
	-- Elements
	-- FOLDERS
	local CharacterGameFolder = UtilitiesModule:WaitForChildTimed(Character, "Game")
	local GeneralCharacterRemotesFolder = UtilitiesModule:WaitForChildTimed(CharacterGameFolder, "Remotes")
	local CharacterClientRemotesFolder = UtilitiesModule:WaitForChildTimed(GeneralCharacterRemotesFolder, "Client")
	--
	local CharacterRemotesFolder = UtilitiesModule:WaitForChildTiemd(CharacterClientRemotesFolder, "Remotes")
	
	--local CharacterClientRemotesFolder = UtilitiesModule:WaitForChildTimed(UtilitiesModule:WaitForChildTimed(UtilitiesModule:WaitForChildTimed(Character, "Game"):WaitForChild("Remotes"), "Client"), "Remotes")
	
	-- Functions
	-- INIT
	return UtilitiesModule:WaitForChildTimed(CharacterRemotesFolder, RemoteName)
end

function UtilitiesModule.GetPlayerCharacterRemote(NilParam, Player, RemoteName)
	-- CORE
	local Character = UtilitiesModule:GetCharacter(Player)

	-- Elements
	-- FOLDERS
	local CharacterGameFolder = UtilitiesModule:WaitForChildTimed(Character, "Game")
	local GeneralCharacterRemotesFolder = UtilitiesModule:WaitForChildTimed(CharacterGameFolder, "Remotes")
	local CharacterClientServerRemotesFolder = UtilitiesModule:WaitForChildTimed(GeneralCharacterRemotesFolder, "ClientServer")
	--
	local CharacterRemotesFolder = UtilitiesModule:WaitForChildTiemd(CharacterClientServerRemotesFolder, "Remotes")
	
	-- Functions
	-- INIT
	return UtilitiesModule:WaitForChildTimed(CharacterRemotesFolder, RemoteName)
end

function UtilitiesModule.GetPlayerCharacterSignal(NilParam, Player, SignalName)
	-- CORE
	local Character = UtilitiesModule:GetCharacter(Player)

	-- Elements
	-- FOLDERS
	local CharacterGameFolder = UtilitiesModule:WaitForChildTimed(Character, "Game")
	local GeneralCharacterRemotesFolder = UtilitiesModule:WaitForChildTimed(CharacterGameFolder, "Remotes")
	local CharacterClientServerRemotesFolder = UtilitiesModule:WaitForChildTimed(GeneralCharacterRemotesFolder, "ClientServer")
	--
	local CharacterSignalsFolder = UtilitiesModule:WaitForChildTimed(CharacterClientServerRemotesFolder, "Signals")

	-- Functions
	-- INIT
	return UtilitiesModule:WaitForChildTimed(CharacterSignalsFolder, SignalName)
end

function UtilitiesModule.RemoveElementCache(NilParam, Child, Properties, Cache)
	-- Functions
	-- INIT
	if not Cache[Child] then
		return nil
	end
	
	for i, Property in pairs(Properties) do
		Cache[Child][Property] = nil
	end
	
	if UtilitiesModule:GetSizeOfDict(Cache[Child]) <= 0 then
		Cache[Child] = nil
	end
end

function UtilitiesModule.CreateCustomConnection(NilParam, CustomConnections)
	-- Functions
	-- INSTANCING
	local CustomConnection = Instance.new("BoolValue")
	CustomConnection.Value = true
	
	if CustomConnections then
		table.insert(CustomConnections, CustomConnection)	
	end

	return CustomConnection 
end

function UtilitiesModule.WeldAccessory(NilParam, Character, Accessory)
	-- Functions
	-- INIT	
	local Handle = Accessory:FindFirstChild("Handle")
	local AccessoryAttachment = Accessory:FindFirstChildOfClass("Attachment") or Handle:FindFirstChildOfClass("Attachment")
	local SpecialMesh = Handle:FindFirstChildOfClass("SpecialMesh")

	--print(Accessory:GetChildren())

	if not AccessoryAttachment then
		--DebugModule:print(script.Name.. " | WeldAccessory | No AccessoryAttachment")
		return nil
	end

	local FoundToAttach = Character["Head"]:FindFirstChild(AccessoryAttachment.Name)

	if not FoundToAttach then
		local ToLoop = Character:GetChildren()

		table.remove(ToLoop, table.find(ToLoop, Character["Head"]))

		for i, Part in pairs(ToLoop) do
			FoundToAttach = Part:FindFirstChild(AccessoryAttachment.Name)

			if FoundToAttach then
				break
			end
		end
	end

	if not FoundToAttach then
		--DebugModule:print(script.Name.. " | WeldAccessory | No FoundToAttach")
		return nil
	end

	--Handle.Anchored = true
	
	if SpecialMesh then
		local OriginalScale = SpecialMesh:GetAttributes()["OriginalScale"]
		local CharacterScale = Character:GetScale()
		
		if not OriginalScale then
			OriginalScale = SpecialMesh.Scale
			SpecialMesh:SetAttribute("OriginalScale", OriginalScale)
		end
		
		SpecialMesh.Scale = Vector3.new(OriginalScale.X * CharacterScale, OriginalScale.Y * CharacterScale, OriginalScale.Z * CharacterScale)
	end
	
	Handle.CFrame = FoundToAttach.WorldCFrame * AccessoryAttachment.CFrame:Inverse()
	UtilitiesModule:WeldParts(Handle, Character["Head"])
end

function UtilitiesModule.GetAttributeChangedSignal(NilParam, Element, Attributes, Function)
	-- CORE
	local Connections = {}
	
	-- Functions
	-- INIT
	for i, AttributeName in pairs(Attributes) do
		table.insert(Connections, Element:GetAttributeChangedSignal(AttributeName):Connect(Function))
	end
	
	return Connections
end

function UtilitiesModule.GetBaseParts(NilParm, Model)
	-- CORE
	local Parts = {}
	
	-- Functions
	-- INIT
	for i, Part in pairs({Model, unpack(Model:GetDescendants())}) do
		if not Part:IsA("BasePart") then
			continue
		end
		
		table.insert(Parts, Part)
	end
	
	return Parts
end

function UtilitiesModule.WeldParts(NilParam, Part1, Part2, IgnoreCs)
	-- CORE
	local RootModel = UtilitiesModule:GetRootModel(Part2)
	
	-- Functions
	-- INIT
	local WeldConstraint = Instance.new("ManualWeld")
	WeldConstraint.Part0 = Part1
	WeldConstraint.Part1 = Part2
	
	if not IgnoreCs then
		local ConstraintJoint = CFrame.new(Part1.Position)

		local C0 = (Part1.CFrame:Inverse() * ConstraintJoint)
		local C1 = (Part2.CFrame:Inverse() * ConstraintJoint)

		WeldConstraint.C0 = C0
		WeldConstraint.C1 = C1
	end

	WeldConstraint.Parent = Part1
	Part1.Anchored = false
	
	return WeldConstraint
end

function UtilitiesModule.WeightedRandom(NilParam, ChanceTable)
	-- Functions
	-- INIT
	local SumOfWeights = 0
	
	--[[for Name, Weight in pairs(ChanceTable) do
		SumOfWeights += Weight
	end]]
	
	for Weight, Info in pairs(ChanceTable) do
		SumOfWeights += Weight
	end
	
	local randomNumber = math.clamp(math.random(0, SumOfWeights * 100) / 100, 0, SumOfWeights)
	
	for Weight, Info in pairs(ChanceTable) do
		if randomNumber < Weight then
			return Weight, Info
		end

		randomNumber -= Weight
	end
	
	return UtilitiesModule:WeightedRandom(ChanceTable)
end

function UtilitiesModule.UnloadAnimations(NilParam, AnimationLoads)
	-- Functions
	-- INIT
	for i, AnimationLoad in pairs(AnimationLoads) do
		AnimationLoad:Stop()
		AnimationLoad:Destroy()
	end
end

function UtilitiesModule.GenerateRandomString(NilParam, Length)
	-- CORE
	local String = ""
	
	-- Functions
	-- INIT
	for i = 1, Length do
		String = String.. CharSetModule[math.random(1, #CharSetModule)]
	end
	
	return String
end

function UtilitiesModule.TableToVector3(NilParam, _Dict)
	-- Functions
	-- INIT
	return Vector3.new(_Dict["X"], _Dict["Y"], _Dict["Z"])
end

function UtilitiesModule.GetPointBetweenColours(NilParam, ...)
	return GetPointBetweenColours(...)
end

function UtilitiesModule.Color3ToTable(NilParam, _Color3)
	-- Functions
	-- INIT
	return {R = _Color3.R * 255, G = _Color3.G * 255, B = _Color3.B *  255, Type = "Color3"}
end

function UtilitiesModule.Color3ToVector3(NilParma, _Color3)
	-- Functions
	-- INIT
	return Vector3.new(_Color3.R * 255, _Color3.G * 255, _Color3.B * 255)
end

function UtilitiesModule.GetCharacters(NilParam, Loaded)
	-- Functions
	-- INIT
	local Characters = {}
	
	for i, Player in pairs(game.Players:GetPlayers()) do
		local Character = UtilitiesModule:GetCharacter(Player, true)
		
		if not Character or not Character.Parent then
			continue
		end
		
		if not Loaded then
			table.insert(Characters, Character)
		else
			if Character:GetAttributes()["Loaded"] then
				local Humanoid = Character:FindFirstChildOfClass("Humanoid")
				
				if Humanoid and Humanoid.Health > 0 then
					table.insert(Characters, Character)
				end
			end
		end
	end
	
	return Characters
end

function UtilitiesModule.GetCharacter(NilParam, Player, StopWait)
	-- Functions
	-- INIT
	if Player then		
		if not StopWait then
			return Player.Character or Player:GetPropertyChangedSignal("Character"):Wait() --Player.CharacterAdded:Wait()
		else
			return Player.Character
		end	
	end
end

function UtilitiesModule.RemoveKeys(NilParam, Dict, Keys)
	-- Functions
	-- INIT
	if typeof(Keys) == "table" then
		for i, Key in pairs(Keys) do
			Dict[Key] = nil
		end
	else
		Dict[Keys] = nil
	end
end

function UtilitiesModule.RemoveProperties(NilParam, Element, PropertyNames)
	-- Functions
	-- MECHANICS
	local function RemoveProperty(PropertyName)
		-- Functions
		-- INIT
		local Success, Error = UtilitiesModule:TryFor(1, function()
			if UtilitiesModule:HasProperty(Element, PropertyName) then
				Element[PropertyName] = nil
			else
				Element:SetAttribute(PropertyName, nil)
			end
		end)

		if not Success then
			print(script.Name.. " | RemoveProperties | Element: ".. tostring(Element).. " | PropertyName: ".. PropertyName.. " | Error: Unable to set property!")
		end
	end
	
	-- INIT
	if typeof(PropertyNames) == "table" then
		for i, PropertyName in pairs(PropertyNames) do
			RemoveProperty(PropertyName)
		end
	else
		RemoveProperty(PropertyNames)
	end
end

function UtilitiesModule.ApplyProperties(NilParam, Element, Properties)
	-- Functions
	-- MECAHNICS
	local function ApplyProperty(PropertyName, PropertyValue)
		-- Functions
		-- INIT
		local Success, Error = UtilitiesModule:TryFor(1, function()
			if UtilitiesModule:HasProperty(Element, PropertyName) then
				Element[PropertyName] = PropertyValue
			else
				Element:SetAttribute(PropertyName, PropertyValue)
			end
		end)

		if not Success then
			print(script.Name.. " | ApplyProperties | Element: ".. tostring(Element).. " | PropertyName: ".. PropertyName.. " | PropertyValue: ".. tostring(PropertyValue).. " | Error: Unable to set property!")
		end
	end
	
	-- INIT
	for PropertyName, PropertyValue in pairs(Properties) do
		if typeof(PropertyName) == "table" then
			for x, _PropertyName in pairs(PropertyName) do
				ApplyProperty(_PropertyName, PropertyValue)
			end
		else
			ApplyProperty(PropertyName, PropertyValue)
		end
	end
end

function UtilitiesModule.ApplyPropertiesIfNotAlreadySet(NilParam, Element, Properties)
	-- Functions
	-- MECHANICS
	local function CheckAndApplyProperty(PropertyName, PropertyValue)
		-- Functions
		-- INIT
		local Success, Error = UtilitiesModule:TryFor(1, function()
			if UtilitiesModule:HasProperty(Element, PropertyName) and Element[PropertyName] == nil then
				UtilitiesModule:ApplyProperties(Element, 
				{
					[PropertyName] = PropertyValue
				})
			else
				if Element:GetAttributes()[PropertyName] == nil then
					UtilitiesModule:ApplyProperties(Element, 
					{
						[PropertyName] = PropertyValue
					})
				end
			end
		end)

		if not Success then
			print(script.Name.. " | ApplyPropertiesIfNotAlreadySet | Element: ".. tostring(Element).. " | PropertyName: ".. PropertyName.. " | PropertyValue: ".. tostring(PropertyValue).. " | Error: Unable to check and set property!")
		end
	end
	
	-- INIT
	for PropertyName, PropertyValue in pairs(Properties) do
		if typeof(PropertyName) == "table" then
			for x, _PropertyName in pairs(PropertyName) do
				CheckAndApplyProperty(_PropertyName, PropertyValue)
			end
		else
			CheckAndApplyProperty(PropertyName, PropertyValue)
		end
	end
end

function UtilitiesModule.CreateElementCache(NilParam, Element, Properties, Cache)
	-- Functions
	-- INIT
	if Cache[Element] == nil then
		Cache[Element] = {}
	end
	
	for i, PropertyName in pairs(Properties) do
		if Cache[Element][PropertyName] == nil then
			if UtilitiesModule:HasProperty(Element, PropertyName) then
				Cache[Element][PropertyName] = Element[PropertyName]
			else
				Cache[Element][PropertyName] = Element:GetAttributes()[PropertyName]
			end
		end
	end
	
	return Cache[Element]
end

function UtilitiesModule.MinutesToSeconds(NilParam, Minutes)
	-- Functions
	-- INIT
	return Minutes * 60
end

function UtilitiesModule.BetterCountdown(NilParam, From, CustomConnection, Replication)
	-- CORE
	local Difference = 0
	local TimeNow = UtilitiesModule:GetTick()
	local LocalCustomConnection = false
	
	if not CustomConnection then
		LocalCustomConnection = true
		CustomConnection = UtilitiesModule:CreateCustomConnection()
	end
		
	-- Functions
	-- INIT
	repeat
		Difference = UtilitiesModule:GetTick() - TimeNow
		
		if Replication then
			if Replication.Attribute ~= nil then
				Replication.Attribute.Instance:SetAttribute(Replication.Attribute.Name, math.floor(From - Difference))
			end
		end
		
		task.wait()
	until Difference >= From or not CustomConnection or not CustomConnection.Value
	
	if LocalCustomConnection then
		UtilitiesModule:DisconnectCustomConnections({CustomConnection})
	end
end

function UtilitiesModule.DisconnectCustomConnections(NilParam, ...)
	-- CORE
	local DisconnectPerTask = 200
	local Args = {...}
	
	-- Functions
	-- INIT
	if #Args < 1 then
		return nil
	end
		
	--coroutine.wrap(function()
		local done = 0
		
		--local IndexsToRemove = {}
		for x, CustomConnections in pairs(Args) do
			if not CustomConnections then
				continue
			end
			
			if typeof(CustomConnections) == "table" then
				--local ShallowClone = UtilitiesModule:CloneDict(CustomConnections)

				for i, CustomConnection in pairs(CustomConnections) do
					if not CustomConnection then
						continue
					end
					
					pcall(function()
						CustomConnection.Value = false
						CustomConnection:Destroy()
						CustomConnection = nil
					end)
					
					CustomConnections[i] = nil
					done += 1
					
					--table.insert(IndexsToRemove, i)
					
					if done % DisconnectPerTask == 0 then
						task.wait(.0025)
					end
				end
				
				--ShallowClone = nil
			elseif typeof(CustomConnections) == "Instance" then
				CustomConnections.Value = false
				CustomConnections:Destroy()
				CustomConnections = nil
			end
		end

		
		--[[table.sort(IndexsToRemove, function(a, b)
			return a > b 
		end)
		
		for i = 1, #IndexsToRemove do
			local index = IndexsToRemove[i]
			table.remove(CustomConnections, index)
		end]]
		
		--IndexsToRemove = nil
	--end)()
end

function UtilitiesModule.DisconnectConnections(NilParam, ...)
	-- Functions
	-- INIT
	--[[if not Connections then
		--print("NO CONNECTIONS | Connections: ")
		--print(Connections)
		return nil
	end]]
	
	-- CORE
	local Args = {...}
	local DisconnectPerTask = 200

	--local TotalNumberOfConnection = #Connections
	--local CloneDict = UtilitiesModule:CloneDict(Connections)
	
	--print("To disconnect: ".. tostring(DisconnectPerTask))
	
	-- Functions
	-- INIT
	if #Args < 1 then
		return nil
	end
	
	--coroutine.wrap(function()
		--local IndexsToRemove = {}
		local done = 0

		for x, Connections in pairs(Args) do
			--local ShallowClone = UtilitiesModule:CloneDict(Connections)
			
			for i, Connection in pairs(Connections) do
				if Connection and Connection.Connected then
					pcall(function()
						Connection:Disconnect()
					end)

					--[[local FoundInConnections = table.find(Connections, Connection)
					
					if FoundInConnections ~= nil then
						table.remove(Connections, FoundInConnections)
					end]]
				end
				
				Connections[i] = nil
				done += 1
				
				if done % DisconnectPerTask == 0 then
					task.wait(.0025)
				end
			end
			
			--ShallowClone = nil
		end
		
		--[[table.sort(IndexsToRemove, function(a, b)
			return a > b 
		end)

		for i = 1, #IndexsToRemove do
			local index = IndexsToRemove[i]
			table.remove(Connections, index)
		end]]
		
		--IndexsToRemove = nil
	--end)()
	--Connections = {}]]
end

function UtilitiesModule.CancelTween(NilParam, TweenElement, TweenDict)
	-- Functions
	-- INIT
	local Success, Error = pcall(function()
		if TweenElement and TweenDict and TweenDict[TweenElement] ~= nil then
			TweenDict[TweenElement]:Cancel()
			TweenDict[TweenElement]:Destroy()
			TweenDict[TweenElement] = nil
		end
	end)
end

function UtilitiesModule.CompleteTween(NilParam, TweenElement, TweenDict)
	-- CORE
	if not TweenElement or not TweenDict or TweenDict[TweenElement] == nil then
		return nil
	end
	
	local Connection1 = nil

	Connection1 = TweenDict[TweenElement].Completed:Once(function(PlaybackStatus)
		Connection1:Disconnect()

		if PlaybackStatus ~= Enum.PlaybackState.Completed then
			return nil
		end

		local Success, Error = UtilitiesModule:TryFor(1, function()
			if TweenDict[TweenElement] == nil then
				return nil
			end

			return TweenDict[TweenElement]:Destroy()
		end)

		UtilitiesModule:RemoveKeys(TweenDict, {TweenElement})	
	end)
end

function UtilitiesModule.DecimalToPercentage(NilParam, Decimal)
	return Decimal * 100
end

function UtilitiesModule.GetGroupsFromUserId(NilParam, UserId)
	-- Functions
	-- INIT
	local Groups = GroupService:GetGroupsAsync(UserId)

	return Groups
end

function UtilitiesModule.HoursToSeconds(NilParam, Hours)
	return Hours * 3600
end

function UtilitiesModule.SecondsToHours(NilParam, Seconds)
	return math.floor(Seconds / 3600)
end

function UtilitiesModule.GetDictValues(NilParam, Dict)
	-- CORE
	local Array = {}

	-- Functions
	-- INIT
	for i, v in pairs(Dict) do
		table.insert(Array, v)
	end

	return Array
end

function UtilitiesModule.GetDictKeys(NilParam, Dict)
	-- CORE
	local Array = {}

	-- Functions
	-- INIT
	for i, v in pairs(Dict) do
		table.insert(Array, i)
	end 

	return Array
end

function UtilitiesModule.DictToArray(NilParam, Dict)
	-- CORE
	local Array = {}
	
	-- Functions
	-- INIT
	for i, v in pairs(Dict) do
		table.insert(Array, v)
	end
	
	return Array
end

function UtilitiesModule.CloneDict(NilParam, Dict)
	if not Dict then
		return nil
	end
	
	-- CORE
	local NewDict = {}
	
	-- Functions
	-- INIT
	for i, v in pairs(Dict) do
		if typeof(v) == "table" then
			NewDict[i] = UtilitiesModule:CloneDict(v)
		else
			NewDict[i] = v
		end
	end
	
	return NewDict
end

function UtilitiesModule.GetParentStack(NilParam, Parent)
	-- CORE
	local Parents = {Parent}
	
	-- Functions
	-- INIT
	local Success, Error = true, nil
	
	while Success do
		Success, Error = pcall(function()
			Parent = Parent.Parent
		end)
		
		if Success then
			table.insert(Parents, Parent)
		end
	end
	
	return Parents
end

function UtilitiesModule.WaitForChildCallback(NilParam, Parent, ChildName, TimeOut, CallbackFunction, ...)
	-- CORE
	local Args = {...}
	
	local CalledBack = false
	local StartTime = time()
	
	local Connection1 = nil
	
	if not TimeOut then
		TimeOut = math.huge
	end
	
	-- Functions
	-- MECHANICS
	local function Render()
		-- CORE
		local TimeNow = time()
		local TimeSpan = TimeNow - StartTime
		
		-- Functions
		-- INIT
		if CalledBack then
			return UtilitiesModule:DisconnectConnections({Connection1})
		end
		
		if not Parent or TimeSpan > TimeOut then
			return UtilitiesModule:DisconnectConnections({Connection1})
		end
		
		local FoundChild = Parent:FindFirstChild(ChildName)
		
		if not FoundChild then
			return nil
		end
		
		return CallbackFunction(FoundChild, unpack(Args))
	end
	
	-- INIT
	Connection1 = UtilitiesModule:RenderSteppedFPSLock(30, Render)
end

function UtilitiesModule.WaitForChildTimed(NilParam, Parent, Child, Tries)
	if not Parent then
		return nil
	end
	
	-- Core
	local FoundChild = nil
	local StartTime = UtilitiesModule:GetTick()
	
	local Logged = false
	local Success, Error = true, nil
	
	-- Functions
	-- INIT
	while not FoundChild and Success do
		local TimeNow = UtilitiesModule:GetTick()
		local TimeSpan = TimeNow - StartTime
				
		if TimeSpan > 3 and not Logged then
			Logged = true
			print(script.Name.. " | WaitForChildTimed | Parent: ".. tostring(Parent).. " | Child: ".. tostring(Child).. " | Might infinite yield!")
			print("Parent Stack: ")
			print(UtilitiesModule:GetParentStack(Parent))
		end
				
		if _G["GameEnded"] then
			return nil
		end
			
		Success, Error = pcall(function()
			FoundChild = Parent:FindFirstChild(Child)
		end)
			
		if not FoundChild and Success then
			task.wait()
		end
	end
	
	return FoundChild
end

function UtilitiesModule.IsDescendantOfClass(NilParam, Element, PossibleClasses)
	-- Functions
	-- INIT
	if not Element then
		return nil
	end
	
	if typeof(PossibleClasses) == "string" then
		PossibleClasses = {PossibleClasses}
	end
	
	local Success, Error = true, nil
	local Result = false
	local CurrentParent = Element
	
	repeat
		Success, Error = pcall(function()
			local Parent = CurrentParent.Parent 
			
			if table.find(PossibleClasses, Parent.ClassName) ~= nil then
				Result = true
			end
			
			CurrentParent = Parent
		end)
	until not Success or Result
	
	return Result
end

function UtilitiesModule.WaitForChildOfClass(NilParam, Parent, ClassName)
	if not Parent then
		return nil
	end
	
	-- CORE
	local TimeNow = UtilitiesModule:GetTick()
	local FoundElement = Parent:FindFirstChildOfClass(ClassName)
	local Logged = false
	
	-- Functions
	-- INIT
	if not FoundElement then
		repeat
			local TimeSpan = UtilitiesModule:GetTick() - TimeNow
			
			if TimeSpan > 3 and not Logged then
				Logged = true
				print(script.Name.. " | WaitForChildOfClass | Parent: ".. tostring(Parent).. " | Class: ".. tostring(ClassName).. " | Might infinite yield!")
				print("Parent Stack: ")
				print(UtilitiesModule:GetParentStack(Parent))	
			end
			
			task.wait(.1)
			FoundElement = Parent:FindFirstChildOfClass(ClassName)
		until FoundElement
	end
	
	return FoundElement
end

function UtilitiesModule.GetTick()
	-- Functions
	-- INIT
	return time()
end

function UtilitiesModule.ArrayToString(NilParam, Array)
	-- CORE
	local String = ""
	
	-- Functions
	-- INIT
	for i, Element in pairs(Array) do
		String = String.. tostring(Element)
		
		if i ~= #Array then
			String = String.. ", "
		end
	end
	
	return String
end

function UtilitiesModule.GetElementFromPath(NilParam, Root, Path)
	-- Functions
	-- INIT
	local LastItem = nil
	
	for i, ElementName in pairs(Path) do
		if LastItem then
			LastItem = LastItem[ElementName]
		else
			LastItem = Root[ElementName]
		end
	end
	
	return LastItem
end

function UtilitiesModule.Map(NilParam, Dir, Function, ClassName, ArgsBefore, ...)
	-- Functions
	-- INIT
	for i, v in pairs(Dir:GetChildren()) do
		if v:IsA(ClassName) then
			if not ArgsBefore then
				Function(v, ...)
			else
				Function(..., v)
			end
		end
	end
end

function UtilitiesModule.FindCharacterInString(NilParam, String, Sub)
	-- Functions
	-- INIT
	for i = 1, string.len(String) do
		if string.sub(String, i, i) == Sub then
			return i
		end
	end
end

function UtilitiesModule.CropNumberToDecimalPlaces(NilParam, Number, PlaceValueNumber)
	-- Functions
	-- INIT
	local NumberString = tostring(Number)
	
	local DecimalPointIndex = UtilitiesModule:FindCharacterInString(NumberString, ".") --string.find(NumberString, '.')
	--local FinalNumber = string.sub(NumberString, DecimalPointIndex + Number, DecimalPointIndex + PlaceValueNumber)
	
	if DecimalPointIndex ~= nil then
		return string.sub(NumberString, 1, DecimalPointIndex + PlaceValueNumber)
	else
		return tostring(Number)
	end
end

function UtilitiesModule.GetSizeOfDict(NilParam, Dict)
	-- CORE
	local Size = 0
	
	-- Functions
	-- INIT
	if Dict and typeof(Dict) == "table" then
		for i, v in pairs(Dict) do
			if v == nil then
				continue
			end
			
			Size += 1
		end
	else
		print("Utilities | Table doesn't exist: ".. tostring(Dict))
	end
	
	return Size
end

function UtilitiesModule.CreateRegion3FromPart(NilParam, obj)
	local abs = math.abs

	local cf = obj.CFrame -- this causes a LuaBridge invocation + heap allocation to create CFrame object - expensive! - but no way around it. we need the cframe
	local size = obj.Size -- this causes a LuaBridge invocation + heap allocation to create Vector3 object - expensive! - but no way around it
	local sx, sy, sz = size.X, size.Y, size.Z -- this causes 3 Lua->C++ invocations

	local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:components() -- this causes 1 Lua->C++ invocations and gets all components of cframe in one go, with no allocations

	-- https://zeuxcg.org/2010/10/17/aabb-from-obb-with-component-wise-abs/
	local wsx = 0.5 * (abs(R00) * sx + abs(R01) * sy + abs(R02) * sz) -- this requires 3 Lua->C++ invocations to call abs, but no hash lookups since we cached abs value above; otherwise this is just a bunch of local ops
	local wsy = 0.5 * (abs(R10) * sx + abs(R11) * sy + abs(R12) * sz) -- same
	local wsz = 0.5 * (abs(R20) * sx + abs(R21) * sy + abs(R22) * sz) -- same

	-- just a bunch of local ops
	local minx = x - wsx
	local miny = y - wsy
	local minz = z - wsz

	local maxx = x + wsx
	local maxy = y + wsy
	local maxz = z + wsz

	local minv, maxv = Vector3.new(minx, miny, minz), Vector3.new(maxx, maxy, maxz)
	return Region3.new(minv, maxv)
end

-- INIT
--RunSubModules()

RequiredModules = 
{
	["Data"] = UtilitiesModule:RunSubModules(script["Data"], true),
	["Service"]	= UtilitiesModule:RunSubModules(script["Service"], true)
}

return UtilitiesModule
