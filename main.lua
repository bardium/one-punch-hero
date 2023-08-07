--[[
CREDITS:
UI Library: Inori & wally
Script: goosebetter
]]

repeat
	task.wait()
until game:IsLoaded()

local start = tick()
local client = game:GetService('Players').LocalPlayer;
local executor = identifyexecutor and identifyexecutor() or 'Unknown'

local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/bardium/LinoriaLib/main/Library.lua'))()
local themeManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/bardium/LinoriaLib/main/addons/ThemeManager.lua'))()

local metadata = loadstring(game:HttpGet('https://raw.githubusercontent.com/bardium/one-punch-hero/main/metadata.lua'))()
local httpService = game:GetService('HttpService')

local runService = game:GetService('RunService')
local repStorage = game:GetService('ReplicatedStorage')
local tpService = game:GetService('TeleportService')
local virtualInputManager = game:GetService('VirtualInputManager')

local knitServices, mobs, knitShared
local counter = 0

while true do
	if typeof(knitServices) ~= 'Instance' then
		for _, obj in next, repStorage:GetChildren() do
			if obj.Name == 'Packages' and obj:FindFirstChild('Knit') and obj.Knit:IsA('ModuleScript') then 
				if obj.Knit:FindFirstChild('Services') and obj.Knit.Services:FindFirstChild('MoveService') and obj.Knit.Services:FindFirstChild('QuestService') and obj.Knit.Services:FindFirstChild('InventoryService') and obj.Knit.Services:FindFirstChild('DataService') then
					if obj.Knit.Services.MoveService:FindFirstChild('RF') and obj.Knit.Services.QuestService:FindFirstChild('RE') then
						knitServices = obj.Knit.Services
					end
				end
			end
		end
	end

	if typeof(mobs) ~= 'Instance' then
		for _, obj in next, workspace:GetChildren() do
			if obj.Name == 'NPC' and obj:IsA('Folder') and obj:FindFirstChild('Enemy') then 
				mobs = obj.Enemy
			end
		end
	end

	if typeof(knitShared) ~= 'Instance' then
		for _, obj in next, repStorage:GetChildren() do
			if obj.Name == 'Shared' and obj:IsA('Folder') and obj:FindFirstChild('QuestData') then 
				knitShared = obj
			end
		end
	end

    if (typeof(knitServices) == 'Instance' and typeof(mobs) == 'Instance' and typeof(knitShared) == 'Instance') then
        break
    end

    counter = counter + 1
    if counter > 6 then
        client:Kick(string.format('Failed to load game dependencies. Details: %s, %s, %s', typeof(knitServices), typeof(mobs), typeof(knitShared)))
    end
    task.wait(1)
end

do
	if shared._unload then
		pcall(shared._unload)
	end

	function shared._unload()
		if shared._id then
			pcall(runService.UnbindFromRenderStep, runService, shared._id)
		end

		UI:Unload()

		for i = 1, #shared.threads do
			coroutine.close(shared.threads[i])
		end

		for i = 1, #shared.callbacks do
			task.spawn(shared.callbacks[i])
		end
	end

	shared.threads = {}
	shared.callbacks = {}

	shared._id = httpService:GenerateGUID(false)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.KillAura) and (Toggles.KillAura.Value)) then
				if client.Character:IsDescendantOf(workspace) and knitServices.MoveService.RF:FindFirstChild('MoveStart') and client.Character.PrimaryPart ~= nil then
					local closestMobs = {client.Character.PrimaryPart}
					for _, v in next, mobs:GetChildren() do
						if v:FindFirstChildOfClass('Humanoid') and v:FindFirstChildOfClass('Humanoid').Health > 0 and (client.Character:GetPivot().Position - v:GetPivot().Position).Magnitude < 50 then
							table.insert(closestMobs, {Parent = v})
						end
					end
					if #closestMobs > 1 then
						knitServices.MoveService.RF.MoveStart:InvokeServer('M1', closestMobs)
					end
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.AutoAbilities) and (Toggles.AutoAbilities.Value)) then
				if client.Character:IsDescendantOf(workspace) and knitServices.MoveService.RF:FindFirstChild('MoveStart') and knitServices.MoveService.RF:FindFirstChild('MoveEnd') and client.Character.PrimaryPart ~= nil then
					local closestMob = nil
					for _, v in next, mobs:GetChildren() do
						if v:FindFirstChildOfClass('Humanoid') and v:FindFirstChildOfClass('Humanoid').Health > 0 then
							if closestMob == nil then
								closestMob = v
							else
								if (client.Character:GetPivot().Position - v:GetPivot().Position).Magnitude < (closestMob:GetPivot().Position - client.Character:GetPivot().Position).Magnitude then
									closestMob = v
								end
							end
						end
					end
					if closestMob ~= nil and closestMob:IsDescendantOf(mobs) and closestMob:FindFirstChildOfClass('Humanoid') and typeof(closestMob:GetPivot()) == 'CFrame' then
						local desiredMove = 'Input' .. tostring(math.random(1, 4))
						if closestMob:FindFirstChild('HumanoidRootPart') then
							knitServices.MoveService.RF.MoveStart:InvokeServer(desiredMove, closestMob.HumanoidRootPart.Position)
							task.wait(.25)
							pcall(function()
								knitServices.MoveService.RF.MoveEnd:InvokeServer(desiredMove, closestMob.HumanoidRootPart.Position)
							end)
						else
							knitServices.MoveService.RF.MoveStart:InvokeServer(desiredMove, closestMob:GetPivot().Position)
							task.wait(.25)
							pcall(function()
								knitServices.MoveService.RF.MoveEnd:InvokeServer(desiredMove, closestMob:GetPivot().Position)
							end)
						end
					end
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

local questData = require(knitShared.QuestData)
local questsInfo = {}
local quests = {'Highest level possible quest'}
for i, v in next, questData do
	if v.Type == 'Enemy' then
		questsInfo[#questsInfo + 1] = {i, v.Requirements.Level, v.Enemy.Name}
	end
end
table.sort(questsInfo, function(quest1, quest2)
	return tonumber(quest1[2]) < tonumber(quest2[2])
end)
for i = 1, #questsInfo do
	table.insert(quests, questsInfo[i][1])
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.TeleportToMobs) and (Toggles.TeleportToMobs.Value)) then
				if client.Character:IsDescendantOf(workspace) then
					local closestMob = nil
					if (Options.TargetMobs.Value) == 'Closest mob' then
						closestMob = nil
						for _, v in next, mobs:GetChildren() do
							if v:FindFirstChildOfClass('Humanoid') and v:FindFirstChildOfClass('Humanoid').Health > 0 then
								if closestMob == nil then
									closestMob = v
								else
									if (client.Character:GetPivot().Position - v:GetPivot().Position).Magnitude < (closestMob:GetPivot().Position - client.Character:GetPivot().Position).Magnitude then
										closestMob = v
									end
								end
							end
						end
					elseif (Options.TargetMobs.Value) == 'Quest mob' then
						local mobName = 'x'
						pcall(function()
							if Options.TargetQuest.Value == 'Highest level possible quest' then
								local highestLevelQuest = 'Thugs'
								local highestLevel = questsInfo[table.find(quests, highestLevelQuest)][2]
								for _, quest in next, quests do
									if questsInfo[table.find(quests, quest) - 1] ~= nil then
										if questsInfo[table.find(quests, quest) - 1][2] < tonumber(client.PlayerGui.MainUI.InfoFrame.LevelFrame.LevelLabel.Text) and questsInfo[table.find(quests, quest) - 1][2] > highestLevel then
											highestLevelQuest = quest
											highestLevel = questsInfo[table.find(quests, quest) - 1][2]
										end
									end
								end
								mobName = questsInfo[table.find(quests, highestLevelQuest) - 1 ][3]
							else
								if client.Character:IsDescendantOf(workspace) and type(Options.TargetQuest.Value) == 'string' then
									mobName = questsInfo[table.find(quests, Options.TargetQuest.Value) - 1][3]
								end
							end
						end)

						for _, v in next, mobs:GetChildren() do
							if v.Name == tostring(mobName) and v:FindFirstChildOfClass('Humanoid') and v:FindFirstChildOfClass('Humanoid').Health > 0 then
								closestMob = v
							end
						end
					else
						for _, v in next, mobs:GetChildren() do
							if v.Name == tostring(Options.TargetMobs.Value) and v:FindFirstChildOfClass('Humanoid') and v:FindFirstChildOfClass('Humanoid').Health > 0 then
								closestMob = v
							end
						end
					end
					if closestMob ~= nil and closestMob:IsDescendantOf(mobs) and closestMob:FindFirstChildOfClass('Humanoid') and typeof(closestMob:GetPivot()) == 'CFrame' then
						if closestMob:FindFirstChild('HumanoidRootPart') then
							local offset = Vector3.new(Options.XOffset.Value, Options.YOffset.Value, Options.ZOffset.Value)
							client.Character:PivotTo(CFrame.new(closestMob.HumanoidRootPart.Position + offset))
							client.Character:PivotTo(CFrame.new(closestMob.HumanoidRootPart.Position + offset, closestMob.HumanoidRootPart.Position))
						else
							local offset = Vector3.new(Options.XOffset.Value, Options.YOffset.Value, Options.ZOffset.Value)
							client.Character:PivotTo(CFrame.new(closestMob:GetPivot().Position + offset))
							client.Character:PivotTo(CFrame.new(closestMob:GetPivot().Position + offset, closestMob:GetPivot().Position))
						end
					end
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.AutoQuests) and (Toggles.AutoQuests.Value)) then
				if Options.TargetQuest.Value == 'Highest level possible quest' then
					local highestLevelQuest = 'Thugs'
					local highestLevel = questsInfo[table.find(quests, highestLevelQuest)][2]
					for _, quest in next, quests do
						if questsInfo[table.find(quests, quest) - 1] ~= nil then
							if questsInfo[table.find(quests, quest) - 1][2] < tonumber(client.PlayerGui.MainUI.InfoFrame.LevelFrame.LevelLabel.Text) and questsInfo[table.find(quests, quest) - 1][2] > highestLevel then
								highestLevelQuest = quest
								highestLevel = questsInfo[table.find(quests, quest) - 1][2]
							end
						end
					end
					knitServices.QuestService.RE.GetQuest:FireServer(highestLevelQuest)
				else
					if client.Character:IsDescendantOf(workspace) and type(Options.TargetQuest.Value) == 'string' then
						knitServices.QuestService.RE.GetQuest:FireServer(Options.TargetQuest.Value)
					end
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.AutoStats) and (Toggles.AutoStats.Value)) then
				if knitServices.DataService:FindFirstChild('RF') and knitServices.DataService.RF:FindFirstChild('AddStat') then
					knitServices.DataService.RF.AddStat:InvokeServer(Options.TargetStat.Value, '1')
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

local function addRichText(label)
	label.TextLabel.RichText = true
end

local Window = UI:CreateWindow({
	Title = string.format('one punch hero - version %s | updated: %s', metadata.version, metadata.updated),
	AutoShow = true,

	Center = true,
	Size = UDim2.fromOffset(550, 567),
})

local Tabs = {}
local Groups = {}

Tabs.Main = Window:AddTab('Main')
Tabs.UISettings = Window:AddTab('UI Settings')

Groups.Main = Tabs.Main:AddLeftGroupbox('Main')
Groups.Main:AddToggle('KillAura', { Text = 'Kill aura', Callback = function(killAuraValue)
	if killAuraValue == true then
		local weldConstraints = 0
		local buttonToPress = 'One'
		pcall(function()
			for _, v in next, client.Character:GetDescendants() do
				if v:IsA('WeldConstraint') and not v.Name:match('Sheath') then
					weldConstraints += 1
				end
			end
		end)
		pcall(function()
			if ((#client.Character:FindFirstChildOfClass('Humanoid'):FindFirstChildOfClass('Animator'):GetPlayingAnimationTracks()) <= 1) and (weldConstraints < 1) and not client.Character:FindFirstChild('CyborgArm_Left') then
				for _, v in next, client.PlayerGui.MainUI.Hotbar:GetChildren() do
					if v:FindFirstChild('Icon') and tostring(v.Icon.Image) ~= '' then
						local isArmor = false
						local armorImages = {'14260753286', '14260756951', '14260751556', '14260794023', '14260778199', '14262595536', '14260760723', '12781506160'}
						local wordMap = {
							[1] = "One",
							[2] = "Two",
							[3] = "Three",
							[4] = "Four",
							[5] = "Five"
						}
						for _, armor in next, armorImages do
							if tostring(v.Icon.Image):match(armor) then
								isArmor = true
							end
						end
						if not isArmor then
							buttonToPress = wordMap[(tonumber((string.gsub(v.Name, 'Slot', ''))))]
						end
					end
				end
			end
		end)
		pcall(function()
			if ((#client.Character:FindFirstChildOfClass('Humanoid'):FindFirstChildOfClass('Animator'):GetPlayingAnimationTracks()) <= 1) and (weldConstraints < 1) and not client.Character:FindFirstChild('CyborgArm_Left') then
				virtualInputManager:SendKeyEvent(true, Enum.KeyCode[buttonToPress], false, nil)
				task.wait()
				virtualInputManager:SendKeyEvent(false, Enum.KeyCode[buttonToPress], false, nil)
			end
		end)
	end
end
})
Groups.Main:AddToggle('AutoAbilities', { Text = 'Auto abilities', Callback = function(autoAbilitesValue)
	if autoAbilitesValue == true then
		local weldConstraints = 0
		local buttonToPress = 'One'
		pcall(function()
			for _, v in next, client.Character:GetDescendants() do
				if v:IsA('WeldConstraint') and not v.Name:match('Sheath') then
					weldConstraints += 1
				end
			end
		end)
		pcall(function()
			if ((#client.Character:FindFirstChildOfClass('Humanoid'):FindFirstChildOfClass('Animator'):GetPlayingAnimationTracks()) <= 1) and (weldConstraints < 1) and not client.Character:FindFirstChild('CyborgArm_Left') then
				for _, v in next, client.PlayerGui.MainUI.Hotbar:GetChildren() do
					if v:FindFirstChild('Icon') and tostring(v.Icon.Image) ~= '' then
						local isArmor = false
						local armorImages = {'14260753286', '14260756951', '14260751556', '14260794023', '14260778199', '14262595536', '14260760723', '12781506160'}
						local wordMap = {
							[1] = "One",
							[2] = "Two",
							[3] = "Three",
							[4] = "Four",
							[5] = "Five"
						}
						for _, armor in next, armorImages do
							if tostring(v.Icon.Image):match(armor) then
								isArmor = true
							end
						end
						if not isArmor then
							buttonToPress = wordMap[(tonumber((string.gsub(v.Name, 'Slot', ''))))]
						end
					end
				end
			end
		end)
		pcall(function()
			if ((#client.Character:FindFirstChildOfClass('Humanoid'):FindFirstChildOfClass('Animator'):GetPlayingAnimationTracks()) <= 1) and (weldConstraints < 1) and not client.Character:FindFirstChild('CyborgArm_Left') then
				virtualInputManager:SendKeyEvent(true, Enum.KeyCode[buttonToPress], false, nil)
				task.wait()
				virtualInputManager:SendKeyEvent(false, Enum.KeyCode[buttonToPress], false, nil)
			end
		end)
	end
end
})
Groups.Main:AddToggle('TeleportToMobs', { Text = 'Teleport to mob' })
local function GetMobsString()
	local MobList = {}

	for _, v in next, mobs:GetChildren() do
		if v:IsA('Model') and v:FindFirstChildOfClass('Humanoid') and v.Name ~= 'Dummy' then
			table.insert(MobList, v)
		end
	end

	local uniqueMobs = {}
	local finalMobList = {}

	for _, v in next, MobList do
		local mobString = tostring(v)
		if not uniqueMobs[mobString] then
			table.insert(finalMobList, v)
			uniqueMobs[mobString] = true
		end
	end

	MobList = finalMobList

	table.sort(MobList, function(mob1, mob2)
		return mob1:FindFirstChildOfClass('Humanoid').Health < mob2:FindFirstChildOfClass('Humanoid').Health
	end)

	for i, v in next, MobList do
		MobList[i] = tostring(v)
	end
	local newValues = { 'Quest mob', 'Closest mob' }

	for i, v in next, MobList do
		newValues[#newValues + 1] = MobList[i]
	end

	MobList = newValues

	return MobList
end

Groups.Main:AddDropdown('TargetMobs', {
	Text = 'Target mob',
	Compact = false,
	Values = GetMobsString(),
	Default = 1
})
Groups.Main:AddButton('Update target mobs', function()
	local TargetMobs = GetMobsString()

	Options.TargetMobs:SetValues(TargetMobs)
end)
Groups.Main:AddDivider()
Groups.Main:AddSlider('YOffset', { Text = 'Height offset', Min = -20, Max = 20, Default = -7, Suffix = ' studs', Rounding = 1, Compact = true, Tooltip = 'Height offset when teleporting to mobs' })
Groups.Main:AddSlider('XOffset', { Text = 'X position offset', Min = -20, Max = 20, Default = 0, Suffix = ' studs', Rounding = 1, Compact = true, Tooltip = 'X offset when teleporting to mobs' })
Groups.Main:AddSlider('ZOffset', { Text = 'Z position offset', Min = -20, Max = 20, Default = 0, Suffix = ' studs', Rounding = 1, Compact = true, Tooltip = 'Z offset when teleporting to mobs' })
Groups.Main:AddDivider()
Groups.Main:AddToggle('AutoQuests', { Text = 'Auto quests' })
Groups.Main:AddDropdown('TargetQuest', {
	Text = 'Target quest',
	Compact = false,
	Values = quests,
	Default = 1,
	Callback = function(quest)
		pcall(function()
			if questsInfo[table.find(quests, quest) - 1][2] > tonumber(client.PlayerGui.MainUI.InfoFrame.LevelFrame.LevelLabel.Text) then
				UI:Notify('Your level is too low for this quest!\nYour level: ' .. tostring(client.PlayerGui.MainUI.InfoFrame.LevelFrame.LevelLabel.Text) .. '\nQuest level requirement: ' .. tostring(questsInfo[table.find(quests, quest) - 1][2]), 5)
				Options.TargetQuest:SetValue(quests[1])
			end
		end)
	end
})
Groups.Main:AddDivider()
Groups.Main:AddToggle('AutoStats', { Text = 'Auto stats' })

Groups.Main:AddDropdown('TargetStat', {
	Text = 'Target stat',
	Compact = false,
	Values = {'Strength', 'Defense', 'Stamina', 'Speed'},
	Default = 1
})
Groups.Main:AddDivider()
local guiNames = {}
if client:FindFirstChild('PlayerGui') and client.PlayerGui:FindFirstChild('MainUI') and client.PlayerGui.MainUI:FindFirstChild('UIs') then
	guiNames = client.PlayerGui.MainUI.UIs:GetChildren()
	table.sort(guiNames, function(guiName1, guiName2)
		if guiName1:IsA('Frame') and guiName2:IsA('ImageLabel') then
			return tostring(guiName1) > tostring(guiName2)
		end
		if guiName1:IsA('ImageLabel') and guiName2:IsA('Frame') then
			return tostring(guiName1) < tostring(guiName2)
		end
		return tostring(guiName1) < tostring(guiName2)
	end)
	for i, v in next, guiNames do
		guiNames[i] = v.Name
	end
end
Groups.Main:AddDropdown('ShowGui', {
	Text = 'Show gui',
	Compact = false,
	Values = guiNames,
	AllowNull = true,
	Callback = function(guiName)
		pcall(function()
			if client.PlayerGui.MainUI.UIs:FindFirstChild(guiName) then
				client.PlayerGui.MainUI.UIs:FindFirstChild(guiName).Position = UDim2.new(0.5, 0, 0.5, 0)
				client.PlayerGui.MainUI.UIs:FindFirstChild(guiName).Visible = true
			end
		end)
	end
})

Groups.Main:AddDropdown('HideGui', {
	Text = 'Hide gui',
	Compact = false,
	Values = guiNames,
	AllowNull = true,
	Callback = function(guiName)
		pcall(function()
			if client.PlayerGui.MainUI.UIs:FindFirstChild(guiName) then
				client.PlayerGui.MainUI.UIs:FindFirstChild(guiName).Position = UDim2.new(-0.5, 0, 0.5, 0)
				client.PlayerGui.MainUI.UIs:FindFirstChild(guiName).Visible = true
			end
		end)
	end
})

Groups.Credits = Tabs.UISettings:AddRightGroupbox('Credits')

addRichText(Groups.Credits:AddLabel('<font color="#0bff7e">Goose Better</font> - script'))
addRichText(Groups.Credits:AddLabel('<font color="#3da5ff">wally & Inori</font> - ui library'))

Groups.UISettings = Tabs.UISettings:AddRightGroupbox('UI Settings')
Groups.UISettings:AddLabel('Changelogs:\n' .. metadata.message or 'no message found!', true)
Groups.UISettings:AddDivider()
Groups.UISettings:AddButton('Unload Script', function() pcall(shared._unload) end)
Groups.UISettings:AddButton('Copy Discord', function()
	if pcall(setclipboard, "https://discord.gg/hSm6DyF6X7") then
		UI:Notify('Successfully copied discord link to your clipboard!', 5)
	end
end)
if game.PlaceId ~= 14136710162 and game.PlaceId ~= 12826178482 then
	Groups.UISettings:AddButton('Return To Lobby', function()
		tpService:Teleport(12826178482, client)
	end)
end

Groups.UISettings:AddLabel('Menu toggle'):AddKeyPicker('MenuToggle', { Default = 'Delete', NoUI = true })

UI.ToggleKeybind = Options.MenuToggle

themeManager:SetLibrary(UI)
themeManager:ApplyToGroupbox(Tabs.UISettings:AddLeftGroupbox('Themes'))

UI:Notify(string.format('Loaded script in %.4f second(s)!', tick() - start), 3)
if executor ~= 'Electron' and executor ~= 'Valyse' then
	UI:Notify(string.format('You may experience problems with the script/UI because you are using %s', executor), 30)
	task.wait()
	UI:Notify(string.format('Exploits this script works well with: Electron and Valyse'), 30)
end
