
����轱���SpectatorCamera_READMEZ��-- SpectatorCamera_README.lua
-- README
-- Created by Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)
-- Last Updated: August 28, 2020

--[[

	Hello, everyone!

	Simple Spectator Camera is an easy drag-and-drop component that will handle spectator UI, bindings,
	teams, and the entire spectator system for you.

	Editing the component is very easy: there are several custom properties within the root folder.

	For the best experience, make sure the Respawn Mode in Respawn Settings are set to None and the
	Respawn Delay is set to 0.

	If there is a spectator team, then the player will be assigned to that team when they die and based
	on that team will be shown the Spectator Camera or not. If there is no spectator team, then it'll be
	shown any time the player dies and hidden any time they respawn.

	Thank you,
	Nicholas Foreman

--]]
����������PlayerStagePositionTemplateb�
� ��ڃ����e*���ڃ����ePlayerStagePositionTemplate"  �?  �?  �?(����ƴ��2
��䯩����z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��((-  ��:

mc:euianchor:middlecenter�
   �?  �?  �?%  �? �;


mc:euianchor:middleright

mc:euianchor:bottomleft*���䯩����
PlayerName"
    �?  �?  �?(��ڃ����ez(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent���(%  ��:

mc:euianchor:middlecenter�Q
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWW  �?  �?  �?%  �?"
mc:etextjustify:right�;


mc:euianchor:bottomright

mc:euianchor:bottomleft
NoneNone
�Ÿ������8"Celestial Journey" Music Construction Kit (Sections) 01
R@
AudioBlueprintAssetRef&abp_celestial_journey_sections_kit_ref
�����濳��	Red Trailb�
� �ߦ��ޝ*��ߦ��ޝ	Red Trail"  �?  �?  �?(�����BZ�
#
bp:Particle Scale Multipliere  @@
!
bp:color��g?��e=e=%  �?
"
	bp:ColorB��g?��e=e=%  �?
"
	bp:ColorC��g?��e=e=%  �?

bp:Emissive Booste  �@

bp:Lifee  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
���Ǆ��� �
NoneNone
^���Ǆ���Basic Projectile Trail VFXR3
VfxBlueprintAssetReffxbp_basic_projectile_trail
�7��閆����Leaderboard_WorldZ�7�7--[[
	Leaderboards - World (Client)
	1.0.0 - 2020/10/05
	Contributors
		Nicholas Foreman (META) (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)
--]]

local EntryTemplate = script:GetCustomProperty("EntryTemplate")
local Leaderboard = script:GetCustomProperty("Leaderboard"):WaitForObject()

local LeaderboardReference = Leaderboard:GetCustomProperty("LeaderboardReference")
assert(LeaderboardReference.isAssigned, "The NetReference provided is not properly set for LeaderboardReference.")

local Entries = script:GetCustomProperty("Entries"):WaitForObject()
local Title = script:GetCustomProperty("Title"):WaitForObject()
local UpdateTimer = script:GetCustomProperty("UpdateTimer"):WaitForObject()

local LEADERBOARD_TYPE = Leaderboard:GetCustomProperty("LeaderboardType")
local LEADERBOARD_STAT = Leaderboard:GetCustomProperty("LeaderboardStat")
local LEADERBOARD_PERSISTENCE = Leaderboard:GetCustomProperty("LeaderboardPersistence")

-- Only applicable if LEADERBOARD_STAT is RESOURCE
local RESOURCE_NAME = Leaderboard:GetCustomProperty("ResourceName")

local DISPLAY_AS_INTEGER = Leaderboard:GetCustomProperty("DisplayAsInteger")

local UPDATE_ON_ROUND_ENDED = Leaderboard:GetCustomProperty("UpdateOnRoundEnded")
local UPDATE_ON_EVENT = Leaderboard:GetCustomProperty("UpdateOnEvent")
local UPDATE_TIMER = math.abs(Leaderboard:GetCustomProperty("UpdateTimer"))

local FIRST_PLACE_COLOR = Leaderboard:GetCustomProperty("FirstPlaceColor")
local SECOND_PLACE_COLOR = Leaderboard:GetCustomProperty("SecondPlaceColor")
local THIRD_PLACE_COLOR = Leaderboard:GetCustomProperty("ThirdPlaceColor")
local NO_PODIUM_PLACEMENT_COLOR = Leaderboard:GetCustomProperty("NoPodiumPlacementColor")
local USERNAME_COLOR = Leaderboard:GetCustomProperty("UsernameColor")
local SCORE_COLOR = Leaderboard:GetCustomProperty("ScoreColor")

local LEADERBOARD_TYPES = { "GLOBAL", "MONTHLY", "WEEKLY", "DAILY" }
local LEADERBOARD_STATS = { "RESOURCE", "KDR", "KILLS", "DEATHS", "DAMAGE_DEALT" }
local LEADERBOARD_PERSISTENCES = { "TOTAL", "ROUND" }

local SCORE_SUFFIXES = {"K", "M", "B", "T", "Q", "Qu", "S", "Se", "O", "N", "D"}

local currentEntries = {}
local lastUpdate = time()

local function GetTime(delta)
	delta = tonumber(delta)

	if delta <= 0 then
		return 0, 0, 0
	else
		local minutes = math.floor(delta / 60)
		local seconds = math.floor(delta - (minutes * 60))
		local milliseconds = math.floor(math.ceil((delta - (minutes * 60) - seconds) * 10000) / 10)

		return minutes, seconds, milliseconds
	end
end

local function GetFormattedTime(delta)
	local minutes, seconds, milliseconds = GetTime(delta)

	return string.format("%002i:%002i.%003i", tostring(minutes), tostring(seconds), tostring(milliseconds))
end

local function toSuffixString(num)
	for index = #SCORE_SUFFIXES, 1, -1 do
		local value = 10 ^ (index * 3)
		if num >= value then
			return string.format("%.1f", num / value) .. SCORE_SUFFIXES[index]
		end
	end
	return string.format("%.1f", num)
end

local function getShouldUpdate(newEntries, currentEntries)
	if(#newEntries ~= #currentEntries) then return true end

	for index, newEntry in ipairs(newEntries) do
		if(index > 10) then break end

		local currentEntry = currentEntries[index]
		if(not currentEntry) then return true end

		if(newEntry.id ~= currentEntry.id) then
			return true
		elseif(newEntry.score ~= currentEntry.score) then
			return true
		end
	end

	return false
end

local function getFirstTenEntries(entries)
	local newEntries = {}

	for index, entry in ipairs(entries) do
		if(index > 10) then break end

		newEntries[index] = entries[index]
	end

	return newEntries
end

local function clearEntries()
	for _, child in pairs(Entries:GetChildren()) do
		child:Destroy()
	end
end

local function getProperty(value, options)
	value = string.upper(value)

	for _, option in pairs(options) do
		if(value == option) then return value end
	end

	return options[1]
end

function Update(id)
	if(not Leaderboards.HasLeaderboards()) then return end

	if(id) then
		if(id ~= Leaderboard.id) then return end
	end

	local newEntries = Leaderboards.GetLeaderboard(LeaderboardReference, LeaderboardType[LEADERBOARD_TYPE])
	if(not newEntries) then Task.Wait() return Update() end
	newEntries = getFirstTenEntries(newEntries)

	local shouldUpdate = getShouldUpdate(newEntries, currentEntries)
	if(not shouldUpdate) then return end

	clearEntries()
	currentEntries = newEntries

	for index, entry in ipairs(newEntries) do
		local leaderboardEntry = World.SpawnAsset(EntryTemplate, {
			parent = Entries,
		})
		leaderboardEntry.name = entry.name

		local playerPosition, playerName, playerScore =
			leaderboardEntry:GetCustomProperty("Rank"):WaitForObject(),
			leaderboardEntry:GetCustomProperty("Name"):WaitForObject(),
			leaderboardEntry:GetCustomProperty("Score"):WaitForObject()

		playerPosition.text = string.format("%002i", index)
		if(index == 1) then
			playerPosition:SetColor(FIRST_PLACE_COLOR)
		elseif(index == 2) then
			playerPosition:SetColor(SECOND_PLACE_COLOR)
		elseif(index == 3) then
			playerPosition:SetColor(THIRD_PLACE_COLOR)
		else
			playerPosition:SetColor(NO_PODIUM_PLACEMENT_COLOR)
		end

		playerName.text = string.sub(entry.name, 1, 23)
		playerName:SetColor(USERNAME_COLOR)

		if(RESOURCE_NAME == "HighScore") then
			playerScore.text = GetFormattedTime(entry.score / 1000)
		elseif(DISPLAY_AS_INTEGER) then
			playerScore.text = tostring(math.ceil(entry.score))
		else
			playerScore.text = toSuffixString(entry.score)
		end
		playerScore:SetColor(SCORE_COLOR)

		leaderboardEntry:SetPosition(Vector3.New(0, 0, -30 * (index - 1)))
	end
end

function Tick()
	if((time() - lastUpdate) < UPDATE_TIMER) then
		local timeLeft = math.ceil((lastUpdate + UPDATE_TIMER) - time())
		UpdateTimer.text = string.format("UPDATES IN %s SECONDS", timeLeft)
	else
		lastUpdate = time()

		Update()
	end
end

Events.Connect("LDT_Update", Update)

if(UPDATE_ON_ROUND_ENDED) then
	Game.roundEndEvent:Connect(Update)
end

if(#UPDATE_ON_EVENT > 0) then
	Events.Connect(UPDATE_ON_EVENT, Update)
end

LEADERBOARD_TYPE = getProperty(LEADERBOARD_TYPE, LEADERBOARD_TYPES)
LEADERBOARD_STAT = getProperty(LEADERBOARD_STAT, LEADERBOARD_STATS)
LEADERBOARD_PERSISTENCE = getProperty(LEADERBOARD_PERSISTENCE, LEADERBOARD_PERSISTENCES)

if(UPDATE_TIMER <= 0) then
	UPDATE_TIMER = 0
end

if(UPDATE_TIMER <= 0) then
	UPDATE_TIMER = 0
end

Title.text = "FASTEST TIMES"
--[[if(LEADERBOARD_STAT == "RESOURCE") then
	local resourceName = string.upper(RESOURCE_NAME)
	if(resourceName == "HIGHSCORE") then
		resourceName = "FASTEST TIME"
	end

	Title.text = string.format("%s %s %s", LEADERBOARD_TYPE, LEADERBOARD_PERSISTENCE, resourceName)
else
	Title.text = string.format("%s %s %s", LEADERBOARD_TYPE, LEADERBOARD_PERSISTENCE, LEADERBOARD_STAT)
end]]

while(not Leaderboards.HasLeaderboards()) do
	Task.Wait()
end
Task.Wait()
Update()
������̴��TimerZ��local GameScript = script:GetCustomProperty("Game"):WaitForObject()
local timerLabel = script:GetCustomProperty("Timer"):WaitForObject()
local multiplierLabel = script:GetCustomProperty("Multiplier"):WaitForObject()

local function setTimer()
	local totalSeconds = math.floor(GameScript:GetCustomProperty("Timer"))

	local minutes = math.floor(totalSeconds / 60)
	local seconds = math.floor(totalSeconds - (60 * minutes))

	timerLabel.text = string.format("%002i:%002i", tostring(minutes), tostring(seconds))
end

local function setMultiplier()
	local multiplier = GameScript:GetCustomProperty("Multiplier")

	if(multiplier == 1) then
		multiplierLabel.text = ""
	else
		multiplierLabel.text = string.format("x%s", multiplier)
	end
end

function Tick(deltaTime)
	setTimer()
	setMultiplier()
end
��ǃ�Գ���Yellow Trailb�
� ��ׅ��ᔹ*���ׅ��ᔹYellow Trail"  �?  �?  �?(�����BZ�
#
bp:Particle Scale Multipliere  @@
!
bp:color�  �?Y�T?�#3=%  �?
"
	bp:ColorB�  �?Y�T?�#3=%  �?
"
	bp:ColorC�  �?Y�T?�#3=%  �?

bp:Emissive Booste  �@

bp:Lifee  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
���Ǆ��� �
NoneNone
�������Õ�LeaderboardZ��--[[
	Leaderboards - Handler (Server)
	1.0.0 - 2020/10/05
	Contributors
		Nicholas Foreman (META) (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)
--]]

-- Make sure Leaderboard_DataTracker is in the hierarchy and we have access to the ResourcesToTrack global table
do local startTime = time()
	while(not (type(_G.ResourcesToTrack) == "table")) do
		Task.Wait()

		if((time() - startTime) > 3) then
			error("An instance of Leaderboard_DataTracker is not in the hierarchy")
		end
	end
end

local Leaderboard = script:GetCustomProperty("Leaderboard"):WaitForObject()

local LeaderboardReference = Leaderboard:GetCustomProperty("LeaderboardReference")
assert(LeaderboardReference.isAssigned, "The NetReference provided is not properly set for LeaderboardReference.")

local LEADERBOARD_TYPE = Leaderboard:GetCustomProperty("LeaderboardType")
local LEADERBOARD_STAT = Leaderboard:GetCustomProperty("LeaderboardStat")
local LEADERBOARD_PERSISTENCE = Leaderboard:GetCustomProperty("LeaderboardPersistence")

-- Only applicable if LEADERBOARD_STAT is RESOURCE
local RESOURCE_NAME = Leaderboard:GetCustomProperty("ResourceName")

local UPDATE_ON_RESOURCE_CHANGED = Leaderboard:GetCustomProperty("UpdateOnResourceChanged")
local UPDATE_ON_PLAYER_DIED = Leaderboard:GetCustomProperty("UpdateOnPlayerDied")
local UPDATE_ON_DAMAGE_DEALT = Leaderboard:GetCustomProperty("UpdateOnDamageDealt")
local UPDATE_ON_EVENT = Leaderboard:GetCustomProperty("UpdateOnEvent")

local LEADERBOARD_TYPES = { "GLOBAL", "MONTHLY", "WEEKLY", "DAILY" }
local LEADERBOARD_STATS = { "RESOURCE", "KDR", "KILLS", "DEATHS", "DAMAGE_DEALT" }
local LEADERBOARD_PERSISTENCES = { "TOTAL", "ROUND" }

local function updated(leaderboardPersistence, leaderboardStat, player, score, resourceName)
	if(leaderboardPersistence ~= LEADERBOARD_PERSISTENCE) then return end

	local count = 0
	while(not Leaderboards.HasLeaderboards()) do
		Task.Wait()
		count = count + 1
		if(count > 10) then return end
	end

	if(leaderboardStat == "KDR") then
		if(LEADERBOARD_STAT ~= "KDR") then return end

		Leaderboards.SubmitPlayerScore(LeaderboardReference, player, score)

		if(UPDATE_ON_PLAYER_DIED) then
			Update()
		end
	elseif(leaderboardStat == "KILLS") then
		if(LEADERBOARD_STAT ~= "KILLS") then return end

		Leaderboards.SubmitPlayerScore(LeaderboardReference, player, score)

		if(UPDATE_ON_PLAYER_DIED) then
			Update()
		end
	elseif(leaderboardStat == "DEATHS") then
		if(LEADERBOARD_STAT ~= "DEATHS") then return end

		Leaderboards.SubmitPlayerScore(LeaderboardReference, player, score)

		if(UPDATE_ON_PLAYER_DIED) then
			Update()
		end
	elseif(leaderboardStat == "DAMAGE_DEALT") then
		if(LEADERBOARD_STAT ~= "DAMAGE_DEALT") then return end

		Leaderboards.SubmitPlayerScore(LeaderboardReference, player, score)

		if(UPDATE_ON_DAMAGE_DEALT) then
			Update()
		end
	else
		if(LEADERBOARD_STAT ~= "RESOURCE") then return end
		if(#RESOURCE_NAME <= 0) then return end
		if(resourceName ~= RESOURCE_NAME) then return end

		Leaderboards.SubmitPlayerScore(LeaderboardReference, player, score)

		if(UPDATE_ON_RESOURCE_CHANGED) then
			Update()
		end
	end
end

local function getProperty(value, options)
	value = string.upper(value)

	for _, option in pairs(options) do
		if(value == option) then return value end
	end

	return options[1]
end

function Update()
	while(Events.BroadcastToAllPlayers("LDT_Update", Leaderboard.id) == BroadcastEventResultCode.EXCEEDED_RATE_LIMIT) do
		Task.Wait()
	end
end

LEADERBOARD_TYPE = getProperty(LEADERBOARD_TYPE, LEADERBOARD_TYPES)
LEADERBOARD_STAT = getProperty(LEADERBOARD_STAT, LEADERBOARD_STATS)
LEADERBOARD_PERSISTENCE = getProperty(LEADERBOARD_PERSISTENCE, LEADERBOARD_PERSISTENCES)

if((LEADERBOARD_STAT == "RESOURCE") and (#RESOURCE_NAME > 0)) then
	_G.ResourcesToTrack[RESOURCE_NAME] = true
end

Events.Connect("LDT_Update", updated)

if(#UPDATE_ON_EVENT > 0) then
	Events.Connect(UPDATE_ON_EVENT, Update)
end
�>�ꕓ��Ц�SpectatorCameraClientZ�>�:-- SpectatorCameraClient.lua
-- Handles the spectator camera on the client
-- Created by Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

local Root = script:GetCustomProperty("Root"):WaitForObject()
local Camera = script:GetCustomProperty("Camera"):WaitForObject()
local SpectatorUI = script:GetCustomProperty("SpectatorUI"):WaitForObject()
local SpectatingName = script:GetCustomProperty("SpectatingName"):WaitForObject()
local PreviousImage = script:GetCustomProperty("PreviousImage"):WaitForObject()
local PreviousButton = script:GetCustomProperty("PreviousButton"):WaitForObject()
local NextImage = script:GetCustomProperty("NextImage"):WaitForObject()
local NextButton = script:GetCustomProperty("NextButton"):WaitForObject()

local SPECTATOR_TEAM = Root:GetCustomProperty("SpectatorTeam")
local WAIT_TIME_AFTER_DEATH = Root:GetCustomProperty("WaitTimeAfterDeath")

local SHOW_CURSOR_BINDING = Root:GetCustomProperty("ShowCursorBinding")
local PREVIOUS_PLAYER_BINDING = Root:GetCustomProperty("PreviousPlayerBinding")
local NEXT_PLAYER_BINDING = Root:GetCustomProperty("NextPlayerBinding")

local BUTTON_UNHOVERED_COLOR = Root:GetCustomProperty("ButtonUnhoveredColor")
local BUTTON_HOVERED_COLOR = Root:GetCustomProperty("ButtonHoveredColor")
local BUTTON_PRESSED_COLOR = Root:GetCustomProperty("ButtonPressedColor")




local LocalPlayer = Game.GetLocalPlayer()

local States = {
	NONE = 1,
	HOVERED = 2,
	PRESSED = 3
}

local buttonStates = {
	PreviousButton = States.NONE,
	NextButton = States.NONE
}

local players = Game.GetPlayers({ignorePlayers = {LocalPlayer}})
local lpCursorVisible, lpIsDead, lpTeam = false, false, 0

local debounce = false
local currentlySpectating

local function getCurrentPlayerIndex()
	if(not currentlySpectating) then return end

	for index, player in ipairs(players) do
		if(player == currentlySpectating) then
			return index
		end
	end
end

local function spectateNextPlayer()
	local currentPlayerIndex = getCurrentPlayerIndex()
	if(not currentPlayerIndex) then return end

	local numberOfPlayers = #players

	local nextPlayerIndex = currentPlayerIndex + 1
	if(nextPlayerIndex > numberOfPlayers) then
		nextPlayerIndex = 1
	end

	local newPlayer = players[nextPlayerIndex]
	if(not newPlayer) then return end

	Spectate(newPlayer)
end

local function spectatePreviousPlayer()
	local currentPlayerIndex = getCurrentPlayerIndex()
	if(not currentPlayerIndex) then return end

	local numberOfPlayers = #players

	local previousPlayerIndex = currentPlayerIndex - 1
	if(previousPlayerIndex < 1) then
		previousPlayerIndex = numberOfPlayers
	end

	local newPlayer = players[previousPlayerIndex]
	if(not newPlayer) then return end

	Spectate(newPlayer)
end

local function spectateFirstPlayer()
	local newPlayer
	for _, player in pairs(players) do
		newPlayer = player
		break
	end
	if(not newPlayer) then return Unspectate() end

	Spectate(newPlayer)
end

local function playerJoined(player)
	players = Game.GetPlayers({ignorePlayers = {LocalPlayer}})
	if((not lpIsDead) or (currentlySpectating)) then return end

	spectateFirstPlayer()
end

local function playerLeft(player)
	players = Game.GetPlayers({ignorePlayers = {LocalPlayer, player}})
	if(currentlySpectating ~= player) then return end

	spectateFirstPlayer()
end

local function died()
	lpIsDead = true

	Task.Spawn(function()
		Task.Wait(WAIT_TIME_AFTER_DEATH)
		if(not lpIsDead) then return end

		spectateFirstPlayer()
	end)
end

local function respawned()
	lpIsDead = false
	Unspectate()
end

local function changeCursorVisibility(visibile)
	lpCursorVisible = visibile

	UI.SetCursorVisible(visibile)
	UI.SetCanCursorInteractWithUI(visibile)
end

local function bindingReleased(player, binding)
	if(not currentlySpectating) then
		if(binding == "ability_extra_25") then -- Y https://docs.coregames.com/api/ability_bindings/#ability-binding-list
			print("Spectating")
			spectateFirstPlayer()
		end
		return
	else
		if(binding == "ability_extra_25") then -- Y https://docs.coregames.com/api/ability_bindings/#ability-binding-list
			print("Unspectating")
			Unspectate()
		end
	end

	if(binding == SHOW_CURSOR_BINDING) then
		changeCursorVisibility(not lpCursorVisible)
	elseif(binding == PREVIOUS_PLAYER_BINDING) then
		spectateNextPlayer()



	elseif(binding == NEXT_PLAYER_BINDING) then
		spectatePreviousPlayer()
	end
end

local function getImageFromButton(button)
	if(button == PreviousButton) then
		return PreviousImage
	elseif(button == NextButton) then
		return NextImage
	end
end

local function hovered(button)
	local image = getImageFromButton(button)
	if(not image) then return end

	buttonStates[button] = States.HOVERED
	image:SetColor(BUTTON_HOVERED_COLOR)
end

local function unhovered(button)
	local image = getImageFromButton(button)
	if(not image) then return end

	buttonStates[button] = States.NONE
	image:SetColor(BUTTON_UNHOVERED_COLOR)
end

local function pressed(button)
	local image = getImageFromButton(button)
	if(not image) then return end

	buttonStates[button] = States.PRESSED
	image:SetColor(BUTTON_PRESSED_COLOR)
end

local function released(button)
	local image = getImageFromButton(button)
	if(not image) then return end
	if(buttonStates[button] == States.NONE) then return end

	buttonStates[button] = States.HOVERED
	image:SetColor(BUTTON_HOVERED_COLOR)
end

function Spectate(player)
	if((SPECTATOR_TEAM > 0) and (player.team ~= SPECTATOR_TEAM)) then return end
	if(Camera.followPlayer == player) then return end
	if((LocalPlayer:GetActiveCamera() ~= LocalPlayer:GetDefaultCamera()) and (LocalPlayer:GetActiveCamera() ~= Camera)) then return end

	if(debounce) then return end
	debounce = true
	currentlySpectating = player

	LocalPlayer:SetOverrideCamera(Camera)
	Camera.followPlayer = player

	SpectatingName.text = player.name
	SpectatorUI.visibility = Visibility.FORCE_ON

	debounce = false
end

function Unspectate()
	if(LocalPlayer:GetActiveCamera() ~= Camera) then return end
	currentlySpectating = nil

	SpectatorUI.visibility = Visibility.FORCE_OFF
	SpectatingName.text = ""

	Camera.followPlayer = nil
	LocalPlayer:ClearOverrideCamera()

	changeCursorVisibility(false)
end

function Tick(deltaTime)
	local dead = LocalPlayer.isDead
	if(dead and (not lpIsDead)) then
		died()
	elseif((not dead) and lpIsDead) then
		respawned()
	end

	local team = LocalPlayer.team
	if(team == lpTeam) then return end
	lpTeam = team

	if(SPECTATOR_TEAM <= 0) then return end

	if(lpTeam == SPECTATOR_TEAM) then
		if(currentlySpectating) then return end

		spectateFirstPlayer()
	else
		Unspectate()
	end
end






Game.playerJoinedEvent:Connect(playerJoined)
Game.playerLeftEvent:Connect(playerLeft)
LocalPlayer.bindingReleasedEvent:Connect(bindingReleased)

PreviousButton.hoveredEvent:Connect(hovered)
PreviousButton.unhoveredEvent:Connect(unhovered)
PreviousButton.pressedEvent:Connect(pressed)
PreviousButton.releasedEvent:Connect(released)
PreviousButton.clickedEvent:Connect(spectatePreviousPlayer)

NextButton.hoveredEvent:Connect(hovered)
NextButton.unhoveredEvent:Connect(unhovered)
NextButton.pressedEvent:Connect(pressed)
NextButton.releasedEvent:Connect(released)
NextButton.clickedEvent:Connect(spectateNextPlayer)�
7
cs:Root�+ง�əƕ���������`�ə������ ���Ľ썇�
9
	cs:Camera�+�����ͧ�኷������ə������ ���Ľ썇�
>
cs:SpectatorUI�+����Ӑ��P���ɭ���ə������ ���Ľ썇�
A
cs:SpectatingName�+���������������ə������ ���Ľ썇�
@
cs:PreviousImage�+Ħ�����;��������ə������ ���Ľ썇�
A
cs:PreviousButton�+ȁ������𐵠���ə������ ���Ľ썇�
<
cs:NextImage�+�������������ƫ��]�ə������ ���Ľ썇�
=
cs:NextButton�+��ߘ����Q��θ��ô�ə������ ���Ľ썇�
�ɟ�؀��UserInterfaceZ��local UserInterface = script:GetCustomProperty("UserInterface"):WaitForObject()

for _, container in pairs(UserInterface:GetChildren()) do
    if(container:IsA(("UIContainer"))) then
        container.visibility = Visibility.FORCE_ON
    end
end
������䴛�TimerZ��local timerLabel = script:GetCustomProperty("Timer"):WaitForObject()
local roundgoing = false
local totalSeconds = math.floor(0)
local milseconds = math.floor(0)
local realtime = 0

local function setTimer()

    
    local minutes = math.floor(totalSeconds / 60)
    local seconds = math.floor(totalSeconds - (60 * minutes))
    local milseconds = milseconds
    milseconds = milseconds * 1.6666
    milseconds = math.floor(milseconds)
    local oldString = string.format("%002i:%002i.%002i", tostring(minutes), tostring(seconds), tostring(milseconds))

   timerLabel.text = oldString
end


function Tick(deltaTime)
    if roundgoing == true then
        setTimer()
    end
end

function startcourse()
    
    roundgoing = true
    milseconds = 0
    realtime = 0
    totalSeconds = 0

end    
local UpdatesecondTask = Task.Spawn(function()
    if roundgoing == true then
        totalSeconds = totalSeconds + 1
        milseconds = 0
    end
end)
UpdatesecondTask.repeatInterval = 1
UpdatesecondTask.repeatCount = -1



local Realtime = Task.Spawn(function()
    if roundgoing == true then
        realtime = realtime + 1
    end
end)
Realtime.repeatInterval = 0.01
Realtime.repeatCount = -1

local UpdatemilsecondTask = Task.Spawn(function()
        milseconds = milseconds + 1
end)
UpdatemilsecondTask.repeatInterval = 0.01
UpdatemilsecondTask.repeatCount = -1

function endcourse(coursenum)

    roundgoing = false
    local newMinutes = math.floor(totalSeconds / 60)
    local newSeconds = math.floor(totalSeconds - (60 * newMinutes))
    milseconds = milseconds * 1.6666
    milseconds = math.floor(milseconds)

    local oldString = string.format("%002i:%002i.%002i", tostring(newMinutes), tostring(newSeconds), tostring(milseconds))

    timerLabel.text = oldString

    Events.BroadcastToServer("endcourseserver", coursenum, totalSeconds, milseconds)

end    

Events.Connect("startcourse", startcourse)
Events.Connect("endcourse", endcourse)
�S�՛¯����FluidUIZ�S�S-- FluidUI.lua
-- Dynamic UI: Scaling, Positioning, Max Size, Aspect Ratio, GridLayout, ListLayout
-- Scripted by Nicholas Foreman (nforeman)
-- Logo contributed by John Shoff (FearTheDev)

--[[

        Hello! Nicholas Foreman here. First of all, I want to say thank you for looking into this content! I
    really appreciate it. This was a project I really wanted to work on for Core as it's something I believe
    EVERYONE could use.

        FluidUI is a responsive User Interface Framework that allows you to design your interface
    dynamically without having to worry about the screen resolution of the users playing your games. With
    many powerful features such as screen-size scaling, grids/lists, and aspect ratios, you will have nearly
    full control over the presentation of your game.

        Getting the framework to work itself is simple. You only need one instance of this script inside of
    of a ClientContext. Any additional copies of this script will conflict with each other and you will not
    get the intended goal.

        However, utilizing the script is slightly more complicated. Each "component" utilizes Custom
    Properties that you insert into each UIComponent (ex. UITextBox). The datatypes are as follows:



    Vector4 Position: Overrides position on the screen
        X: Scale on the X Axis (0 -> 1)
        Y: Scale on the Y Axis (0 -> 1)
        Z: Pixels on the X Axis (any)
        W: Pixels on the Y Axis (any)

    Vector4 Size: Overrides size on the screen
        X: Scale on the X Axis (0 -> 1)
        Y: Scale on the Y Axis (0 -> 1)
        Z: Pixels on the X Axis (any)
        W: Pixels on the Y Axis (any)

    Vector2 MaxSize: Sets the maximum number of pixels the component can be
        X: Pixels on the X Axis
        Y: Pixels on the Y Axis

    Boolean ScaleText: If enabled and the UIComponent is a UITextBox, the text will scale with the Size property



    Float AspectRatio: Multiplier for non-dominant axis based on size of dominant axis
    Boolean AspectRatioYAxisDominant: Sets dominant axis to the Y axis instead of X axis



    Vector2 ListSize: Sets how large each component within the list is
        X: Scale on the dominant axis (0 -> 1)
        Y: Pixels on the dominant axis (any)

    Float ListGap: Pixels on the dominant axis

    Boolean ListFillHorizontal: Fills side-by-side instead of top-bottom



    Vector2 GridCount: Setting scale of grid
        X: Number of columns (side-by-side)
        Y: Number of rows (top-down)

    Vector2 GridGap: Pixels between grid members
        X: Pixels between each column
        Y: Pixels between each row

    Vector4 GridPadding: Additional pixels along the edges of the grid
        X: Pixels to the left
        Y: Pixels to the top
        Z: Pixels to the right

        W: Pixels to the bottom
    Boolean GridFillVertical: Fills top-down instead of side-to-side
--]]

--[[
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    BE CAREFUL WHEN EDITTING BELOW
    //////////////////////////////

    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    BE CAREFUL WHEN EDITTING BELOW
    //////////////////////////////

    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    BE CAREFUL WHEN EDITTING BELOW
    //////////////////////////////

    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    BE CAREFUL WHEN EDITTING BELOW
    //////////////////////////////

    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    BE CAREFUL WHEN EDITTING BELOW
    //////////////////////////////

    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    BE CAREFUL WHEN EDITTING BELOW
    //////////////////////////////

    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    BE CAREFUL WHEN EDITTING BELOW
    //////////////////////////////
--]]

local HelpfulFunctions = require(script:GetCustomProperty("HelpfulFunctions"))

local worldRootObject = World.GetRootObject()

local screenSize = UI.GetScreenSize()

local function updateSize(uiControl, Size, parentSize)
    if((Size.x ~= 0) or (Size.z ~= 0)) then
        uiControl.width = math.floor(parentSize.x * Size.x) + Size.z
    end
    if((Size.y ~= 0) or (Size.w ~= 0)) then
        uiControl.height = math.floor(parentSize.y * Size.y) + Size.w
    end
end

local function updatePosition(uiControl, Position, parentSize)
    uiControl.x = math.floor(parentSize.x * Position.x) + Position.z
    uiControl.y = math.floor(parentSize.y * Position.y) + Position.w
end

local function updateMaxSize(uiControl, MaxSize)
    if((MaxSize.x ~= 0) and (uiControl.width > MaxSize.x)) then
        uiControl.width = MaxSize.x
    end

    if((MaxSize.y ~= 0) and (uiControl.height > MaxSize.y)) then
        uiControl.height = MaxSize.y
    end
end

local function updateList(uiControl, ListSize, ListGap, ListFillHorizontal, parentSize)
    local xSize, ySize = 0, 0
    local gridGapX, gridGapY = 0, 0

    if(ListGap) then
        if(ListFillHorizontal) then
			ySize = parentSize.y
            gridGapX = ListGap

            local totalSizeX = parentSize.x - (gridGapX * ((1 / ListSize.x) - 1))

            xSize = totalSizeX / (1 / ListSize.x)
        else
            xSize = parentSize.x
            gridGapY = ListGap

			--local totalSizeY = parentSize.y - (gridGapY * ((1 / ListSize.y) - 1))

			ySize = ListSize.y--totalSizeY / (1 / ListSize.y)
        end
    else
        if(ListFillHorizontal) then
            xSize = math.floor(parentSize.x * ListSize.x) + ListSize.y
            ySize = parentSize.y
        else
            xSize = parentSize.x
            ySize = math.floor(parentSize.y * ListSize.x) + ListSize.y
        end
    end

    for index, child in ipairs(uiControl:GetChildren()) do
		child.width = math.floor(xSize)
        child.height = math.floor(ySize)

        local row = (index - 1)

        if(ListFillHorizontal) then
            child.x = math.ceil((xSize * row) + (gridGapX * row))
        else
            child.y = math.ceil((ySize * row) + (gridGapY * row))
        end
    end
end

local function updateGrid(uiControl, GridCount, GridGap, GridPadding, GridFillVertical, parentSize)
    local columns, rows = GridCount.x, GridCount.y

    local parentSizeX = parentSize.x
    local parentSizeY = parentSize.y

    if(GridPadding) then
        parentSizeX = parentSizeX - GridPadding.x - GridPadding.z
        parentSizeY = parentSizeY - GridPadding.y - GridPadding.w
    end

    local xSize, ySize
    local gridGapX, gridGapY = 0, 0
    if(GridGap) then
        gridGapX = GridGap.x
        gridGapY = GridGap.y

        local totalSizeX = parentSizeX - (gridGapX * (columns - 1))
        local totalSizeY = parentSizeY - (gridGapY * (rows - 1))

        xSize = totalSizeX / columns
        ySize = totalSizeY / rows
    else
        xSize = parentSizeX / columns
        ySize = parentSizeY / rows
    end

    for index, child in ipairs(uiControl:GetChildren()) do
        child.width = math.floor(xSize)
        child.height = math.floor(ySize)

        local column, row
        if(GridFillVertical) then
            column = math.floor((index - 1) / columns)
            row = (index - 1) % columns
        else
            column = (index - 1) % columns
            row = math.floor((index - 1) / columns)
        end

        child.x = math.ceil((xSize * column) + (gridGapX * column))
        child.y = math.ceil((ySize * row) + (gridGapY * row))
        if(GridPadding) then
            child.x = child.x + GridPadding.x
            child.y = child.y + GridPadding.y
        end
    end
end

local function updateAspectRatio(uiControl, aspectRatio, yDominantAxis)
    if(yDominantAxis) then
        uiControl.width = math.floor(uiControl.height * aspectRatio)
    else
        uiControl.height = math.floor(uiControl.width * aspectRatio)
    end
end

local function updateText(uiControl)
    uiControl.fontSize = math.floor(uiControl.height / 2)
end

local function updateUIControl(uiControl)
    if(not uiControl:IsA("UIControl")) then return end
    if(uiControl:IsA("UIContainer")) then return end

    local parent = uiControl.parent

    local parentSize
    if((not parent:IsA("UIControl")) or parent:IsA("UIContainer")) then
        parentSize = screenSize
    else
        parentSize = Vector2.New(parent.width, parent.height)
    end

	local Position = uiControl:GetCustomProperty("Position")
    if(Position) then
        updatePosition(uiControl, Position, parentSize)
    end

    local Size = uiControl:GetCustomProperty("Size")
    if(Size) then
        updateSize(uiControl, Size, parentSize)
    end

    local MaxSize = uiControl:GetCustomProperty("MaxSize")
    if(MaxSize) then
        updateMaxSize(uiControl, MaxSize)
    end

    local AspectRatio = uiControl:GetCustomProperty("AspectRatio")
    local AspectRatioYAxisDomiant = uiControl:GetCustomProperty("AspectRatioYAxisDominant")
    if(AspectRatio) then
        updateAspectRatio(uiControl, AspectRatio, AspectRatioYAxisDomiant)
    end

    local ScaleText = uiControl:GetCustomProperty("ScaleText")
    if(ScaleText and (uiControl:IsA("UIText") or uiControl:IsA("UIButton"))) then
        updateText(uiControl)
    end

    local ListSize = uiControl:GetCustomProperty("ListSize")
	local ListGap = uiControl:GetCustomProperty("ListGap")
    local ListFillHorizontal = uiControl:GetCustomProperty("ListFillHorizontal") or false
    if(ListSize) then
        updateList(uiControl, ListSize, ListGap, ListFillHorizontal, Vector2.New(uiControl.width, uiControl.height))
    end

    local GridCount = uiControl:GetCustomProperty("GridCount")
    local GridGap = uiControl:GetCustomProperty("GridGap")
    local GridPadding = uiControl:GetCustomProperty("GridPadding")
    local GridFillVertical = uiControl:GetCustomProperty("GridFillVertical")
    if(GridCount) then
        updateGrid(uiControl, GridCount, GridGap, GridPadding, GridFillVertical, Vector2.New(uiControl.width, uiControl.height))
    end
end

local function scanDescendants()
    for _, descendant in pairs(HelpfulFunctions:GetDescendants(worldRootObject)) do
        updateUIControl(descendant)
    end
end

local function descendantAdded(ancestor, descendant)
    updateUIControl(descendant)
    updateUIControl(descendant.parent)
end

function Tick(deltaTime)
    local newScreenSize = UI.GetScreenSize()
    if(newScreenSize == screenSize) then return end
    screenSize = newScreenSize

    scanDescendants()
end

worldRootObject.descendantAddedEvent:Connect(descendantAdded)
scanDescendants()
����؟����Purple Trailb�
� Üĳ��ʽJ*�Üĳ��ʽJPurple Trail"  �?  �?  �?(�����BZ�
#
bp:Particle Scale Multipliere  @@
!
bp:color�x�
>�N-=�r�>%  �?
"
	bp:ColorB�x�
>�N-=�r�>%  �?
"
	bp:ColorC�x�
>�N-=�r�>%  �?

bp:Emissive Booste  �@

bp:Lifee  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
���Ǆ��� �
NoneNone
?���������	Sun LightR%
BlueprintAssetRefCORESKY_SunLight
�L��������Easy3b�K
�K �Ҝ���ʟ�*��Ҝ���ʟ�Easy3"  �?  �?  �?(�����B29�׉�֐���׏��ҟ��y�����߈ن����ݓ���ȿ�����$���Ԫ����Z#
!
cs:Color���>  �?-� ?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*��׉�֐���Music"
  �C   HB  HB   A(�Ҝ���ʟ�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*�׏��ҟ��y
Checkpoint"

 0�  �B    @33�A   @(�Ҝ���ʟ�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*������߈نTransitionPlatform"

 0� �sD    @33�A   ?(�Ҝ���ʟ�Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����ݓ��Top"
  zD   HB  HB  �?(�Ҝ���ʟ�Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z
mc:ecollisionsetting:forceoff� 
mc:evisibilitysetting:forceoff�
��������08�
 *��ȿ�����$Walls"
  �C   �?  �?  �?(�Ҝ���ʟ�2M�������������̳��ڊ����׮�ɳ��C����=��ݢ�����갂���ț��Ś�й��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*����������Wall"

  �  HB   �?  �A   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�43�>  �?   ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����̳�Wall"

  E  HB   �?  �A   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�43�>  �?   ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��ڊ���Wall"

  E  HB   �A  �?   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�43�>  �?   ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��׮�ɳ��CWall"

 �  HB   �A  �?   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�43�>  �?   ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����=Wall")
.���*���  HB��3B  �?  �A   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�43�>  �?   ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���ݢ����Wall")
+���.��D  HB��3B  �A  �?   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�43�>  �?   ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��갂���țWall")
-��D+��D  HB��3B  �?  �A   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�43�>  �?   ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���Ś�й��Wall")
+��D.���  HB��3B  �A  �?   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����Ԫ����	Obstacles"
    �?  �?  �?(�Ҝ���ʟ�2����������������y���忪������ĉ孱����ǚ�ہ���������U���ؘ�ۖ��舛竒�4џ�ɡ���{ʢ���ơ�����م��n���ֻҹ���������� ���ک������ω�����׼َ۲�������ͪ�����霊����ި��ȣ�ص�����kz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*����������Platform"

 @��  a�   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�������yPlatform"$
 @�� ��� HB   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����忪���Platform"$
  a�  �����B   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����ĉ孱�Platform"$
  �� �����C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����ǚ�ہ�Platform"$
  HB �����GC   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���������UPlatform"$
 �	D ��� zC   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����ؘ�ۖ�Platform"$
  zD ���  �C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��舛竒�4Platform"$
  �D  �� �C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�џ�ɡ���{Platform"

 @�D �C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�ʢ���ơ��Platform"$
 ��D  �C �C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����م��nPlatform"$
  /D  aD�	D   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����ֻҹ��Platform"$
  �C  �C  D   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��������� Platform"$
  �� �;D /D   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����ک����Platform"$
  H� @�D�;D   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���ω����Platform"$
  �  HC �"D   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��׼َ۲��Platform"$
  �D �m����C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *������ͪ��Platform"$
 �"�  �D��GD   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����霊���Platform"$
 ��� @�D�TD   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ި��ȣPlatform"$
 ��� @�D��`D   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ص�����kPlatform"$
 ��� �	D�mD   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���>  �?-� ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 
NoneNone
CÅɂ���ʴBase�-��������� 

color�  �>  �>  �>%  �?
L���������Basic MaterialR-
MaterialAssetRefmi_basic_pbr_material_001
6��������CubeR!
StaticMeshAssetRefsm_cube_002
�������ٗ�PlayerStageTemplateb�
� �����ĕ�*������ĕ�PlayerStageTemplate"  �?  �?  �?(����ƴ��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�s�:

mc:euianchor:middlecenterP�
 %  �? �>


mc:euianchor:bottomcenter

mc:euianchor:bottomcenter
NoneNone
���������Orange Trailb�
� �ț��Ȧ�*��ț��Ȧ�Orange Trail"  �?  �?  �?(�����BZ�
#
bp:Particle Scale Multipliere  @@

bp:color�  �?"à>%  �?

	bp:ColorB�  �?"à>%  �?

	bp:ColorC�  �?"à>%  �?

bp:Emissive Booste  �@

bp:Lifee  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
���Ǆ��� �
NoneNone
�P����Ś���GameZ�P�Plocal Scenes = script:GetCustomProperty("Scenes"):WaitForObject()
local SceneStages = Scenes:FindChildByName("Stages")
local ThunderSquids = script:GetCustomProperty("ThunderSquids"):WaitForObject()

local NormalPlayerSettings = script:GetCustomProperty("PlayerSettings"):WaitForObject()
local FrozenPlayerSettings = script:GetCustomProperty("Frozen"):WaitForObject()

local WAIT_TIME = script:GetCustomProperty("DefaultTime")
local TIME_KEY = "time"

local Stages = {
	Easy = {},
	Medium = {},
	Hard = {}
}

local winners = {}

local order = {}
local checkpoints = {}
local playerCheckpoints = {}

local isActive = false

local beginning, ending =
	Scenes:FindChildByName("Beginning"),
	Scenes:FindChildByName("Ending")

local endingCheckpoint = ending:FindChildByName("Checkpoint")

local function GetTime(delta)
	delta = tonumber(delta)

	if delta <= 0 then
		return 0, 0, 0
	else
		local minutes = math.floor(delta / 60)
		local seconds = math.floor(delta - (minutes * 60))
		local milliseconds = math.floor(math.ceil((delta - (minutes * 60) - seconds) * 10000) / 10)

		return minutes, seconds, milliseconds
	end
end

local function GetFormattedTime(delta)
	local minutes, seconds, milliseconds = GetTime(delta)

	return string.format("%002i:%002i.%003i", tostring(minutes), tostring(seconds), tostring(milliseconds))
end

local function reachedEnd(trigger, player)
	if(not isActive) then return end
	if(not player:IsA("Player")) then return end

	playerCheckpoints[player] = "End"
end

local function enteredCheckpoint(trigger, player)
	if(not isActive) then return end
	if(not player:IsA("Player")) then return end

	for index, stageName in pairs(order) do
		if(index ~= 1) then
			if(trigger.parent.name == stageName) then
				if(type(playerCheckpoints[player]) == "number" and (index > playerCheckpoints[player])) then
					playerCheckpoints[player] = index
					Events.BroadcastToPlayer(player, "Message", "You reached a new checkpoint!")
				elseif(not playerCheckpoints[player]) then
					playerCheckpoints[player] = index
					Events.BroadcastToPlayer(player, "Message", "You reached a new checkpoint!")
				end
			end
		end
	end
end

local function goToCheckpoint(player)
	if(script:GetCustomProperty("Timer") <= 1) then return end

	local index = playerCheckpoints[player]
	if(not index) then return end

	if((type(index) == "string") and (index == "End")) then
		player:SetWorldPosition(endingCheckpoint:GetWorldPosition())
	else
		player:SetWorldPosition(checkpoints[index]:GetWorldPosition())
	end
	player:SetWorldRotation(Rotation.New(0, 0, -90))
	Events.BroadcastToPlayer(player, "ResetCamera")
end

local function hasPlayerWon(player)
	for _, playerName in pairs(winners) do
		if(player.name == playerName) then
			return true
		end
	end

	return false
end

local function playerJoined(player)
	if(not isActive) then
		FrozenPlayerSettings:ApplyToPlayer(player)
	end

	player.respawnedEvent:Connect(goToCheckpoint)

	local playerData = Storage.GetPlayerData(player)
	--print(playerData[TIME_KEY])
	player:SetResource("HighScore", (playerData[TIME_KEY] and math.floor(playerData[TIME_KEY] * 1000)) or (script:GetCustomProperty("DefaultTime") * 1000))
	--print(player:GetResource("HighScore"))
	player:SetResource("Coins", playerData.coins or 0)
	player:SetResource("Wins", playerData.wins or 0)

	Task.Wait(1)
	Events.BroadcastToPlayer(player, "UpdateStages", order)

	-- if(player.name ~= "NicholasForeman") then return end
	-- local task = Task.Spawn(function()
	-- 	local pd = Storage.GetPlayerData(player)
	-- 	Events.BroadcastToPlayer(player, "Draw", pd.time)
	-- 	Task.Wait(2.885)
	-- end)
	-- task.repeatCount = -1
	-- task.repeatInterval = -1
end

local function someoneWon(trigger, player)
	if(not isActive) then return end
	if(not player:IsA("Player")) then return end
	if(hasPlayerWon(player)) then return end

	table.insert(winners, player.name)
	script:SetNetworkedCustomProperty("Multiplier", script:GetCustomProperty("Multiplier") * 2)

	local numberOfWinners = CoreMath.Clamp(#winners, 0, 3) - 1

	local playerData = Storage.GetPlayerData(player)
	playerData.wins = (playerData.wins or 0) + 1
	playerData.coins = (playerData.coins or 0) + (20 - (5 * numberOfWinners))
	player:SetResource("Coins", playerData.coins or 0)
	player:SetResource("Wins", playerData.wins or 0)

	local difference = script:GetCustomProperty("DefaultTime") - script:GetCustomProperty("Timer")
	local playerTime = playerData[TIME_KEY] or -1
	if(playerTime == 0) then
		playerTime = -1
	end
	if(difference == 0) then
		difference = script:GetCustomProperty("DefaultTime")
	end

	local beatHighScore = false
	if(playerTime == -1) then
		playerData[TIME_KEY] = difference
		beatHighScore = true
	elseif(difference < playerTime) then
		playerData[TIME_KEY] = difference
		beatHighScore = true
	end

	Storage.SetPlayerData(player, playerData)
	if(beatHighScore) then
		player:SetResource("HighScore", math.floor(playerData[TIME_KEY] * 1000))
		--print(player:GetResource("HighScore"))
	end

	local newString = GetFormattedTime(difference)

	if(#Game.GetPlayers() == 1) then
		Game.EndRound()
	end

	if(not beatHighScore) then
		return Events.BroadcastToAllPlayers("Message", string.format("%s beat the tower (%s)!", player.name, newString))
	end

	if(playerTime == -1) then
		playerTime = script:GetCustomProperty("DefaultTime")
	end

	local oldString = GetFormattedTime(playerTime)

	local message = string.format("%s beat their highscore (%s -> %s)!", player.name, oldString, newString)
	Events.BroadcastToAllPlayers("Message", message)
end

local function spawnMap(difficulty, muid, lastStage)
	local stage
	for _, possibleStage in pairs(Stages[difficulty]) do
		if(possibleStage == muid) then
			stage = possibleStage
			break
		end
	end

	local data = {
		parent = SceneStages,
		position = lastStage:FindChildByName("Top"):GetWorldPosition()
	}

	lastStage = World.SpawnAsset(stage, data)
	Events.Broadcast("UpdateKillStages", lastStage)

	table.insert(checkpoints, lastStage:FindChildByName("Checkpoint"))
	table.insert(order, lastStage.name)

	return lastStage, lastStage:FindChildByName("Top"):GetWorldPosition()
end

local function generateCategory(difficulty, stages, lastStage, highestPoint)
	local previousNumbers = {}

	local numberOfStages = 0
	if(difficulty == "Easy") then
		numberOfStages = 3
	elseif(difficulty == "Medium") then
		numberOfStages = 2
	elseif(difficulty == "Hard") then
		numberOfStages = 1
	end
	if(numberOfStages == 0) then return end

	for index = 1, numberOfStages do
		local randomNumber = math.random(#stages)
		while(previousNumbers[randomNumber]) do
			randomNumber = math.random(#stages)
		end
		previousNumbers[randomNumber] = true

		local randomStage = stages[randomNumber]
		local data = {
			parent = SceneStages,
			position = lastStage:FindChildByName("Top"):GetWorldPosition()
		}

		lastStage = World.SpawnAsset(randomStage, data)
		highestPoint = lastStage:FindChildByName("Top"):GetWorldPosition()
		Events.Broadcast("UpdateKillStages", lastStage)

		table.insert(checkpoints, lastStage:FindChildByName("Checkpoint"))
		table.insert(order, lastStage.name)
	end

	return lastStage, highestPoint
end

local function generateStages()
	math.randomseed(time())

	local lastStage = beginning
	local highestPoint = lastStage:FindChildByName("Top"):GetWorldPosition()

	--lastStage, highestPoint = spawnMap("Easy", "C3C208D25820C462:Easy1", lastStage)
	--lastStage, highestPoint = spawnMap("Easy", "DA0AEDB6DF816E44:Easy2", lastStage)
	--lastStage, highestPoint = spawnMap("Easy", "E9FFCBB28F76C766:Easy3", lastStage)
	--lastStage, highestPoint = spawnMap("Medium", "5A719A063479A2D6:Medium2", lastStage)
	--lastStage, highestPoint = spawnMap("Medium", "890AB7BEB4050E20:Medium3", lastStage)
	--lastStage, highestPoint = spawnMap("Hard", "0FE6D88DC116F89C:Hard1", lastStage)
	lastStage, highestPoint = generateCategory("Easy", Stages.Easy, lastStage, highestPoint)
	lastStage, highestPoint = generateCategory("Medium", Stages.Medium, lastStage, highestPoint)
	lastStage, highestPoint = generateCategory("Hard", Stages.Hard, lastStage, highestPoint)

	ending:SetWorldPosition(highestPoint)
	script:SetNetworkedCustomProperty("HighestPoint", highestPoint)

	Events.BroadcastToAllPlayers("UpdateStages", order)

	for _, checkpoint in pairs(checkpoints) do
		if(checkpoint:IsA("Trigger")) then
			checkpoint.beginOverlapEvent:Connect(enteredCheckpoint)
		end
	end
end

local function clearStages()
	for _, stage in pairs(SceneStages:GetChildren()) do
		stage:Destroy()
	end
end

local function roundStarted()
	Events.BroadcastToAllPlayers("Message", "Generating Stages...")
	script:SetNetworkedCustomProperty("Timer", WAIT_TIME)

	clearStages()
	generateStages()

	Task.Wait(2)

	for _, player in pairs(Game.GetPlayers()) do
		NormalPlayerSettings:ApplyToPlayer(player)
	end

	isActive = true
end

local function roundEnded()
	isActive = false
	winners = {}
	checkpoints = {}
	playerCheckpoints = {}
	order = {}

	for _, player in pairs(Game.GetPlayers()) do
		FrozenPlayerSettings:ApplyToPlayer(player)
		player:Die()
	end

	script:SetNetworkedCustomProperty("Multiplier", 1)
	Game.StartRound()
end

local function populateStages()
	for name, property in pairs(script:GetCustomProperties()) do
		for categoryName, _ in pairs(Stages) do
			if(string.sub(name, 1, #categoryName) == categoryName) then
				table.insert(Stages[categoryName], property)
			end
		end
	end
end

function Tick(deltaTime)
	if(not isActive) then return end
	script:SetNetworkedCustomProperty("Timer", script:GetCustomProperty("Timer") - (deltaTime * script:GetCustomProperty("Multiplier")))

	if(script:GetCustomProperty("Timer") > 0) then return end
	Game.EndRound()
end

Game.roundStartEvent:Connect(roundStarted)
Game.roundEndEvent:Connect(roundEnded)

populateStages()

Game.StartRound()

ThunderSquids.beginOverlapEvent:Connect(someoneWon)
endingCheckpoint.beginOverlapEvent:Connect(reachedEnd)

Game.playerJoinedEvent:Connect(playerJoined)
���������Green Trailb�
� ��۫����*���۫����Green Trail"  �?  �?  �?(�����BZ�
#
bp:Particle Scale Multipliere  @@
!
bp:color�C�=T}�>KJ�=%  �?
"
	bp:ColorB�C�=T}�>KJ�=%  �?
"
	bp:ColorC�C�=T}�>KJ�=%  �?

bp:Emissive Booste  �@

bp:Lifee  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
���Ǆ��� �
NoneNone
�U�܅������Easy2b�U
�U �Ҝ���ʟ�*��Ҝ���ʟ�Easy2"  �?  �?  �?(ܭܛ�����28ٌ����Ⱦ����Ϫ��~�����߈ن����ݓ���ȿ�����$���Ԫ����Z#
!
cs:Color����>  �?���>%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*�ٌ����ȾMusic"
  �C   HB  HB   A(�Ҝ���ʟ�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*�����Ϫ��~
Checkpoint"

 0�  �B    @33�A   @(�Ҝ���ʟ�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*������߈نTransitionPlatform"

 0� �sD    @33�A   ?(�Ҝ���ʟ�Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����ݓ��Top"
  zD   HB  HB  �?(�Ҝ���ʟ�Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z
mc:ecollisionsetting:forceoff� 
mc:evisibilitysetting:forceoff�
��������08�
 *��ȿ�����$Walls"
  �C   �?  �?  �?(�Ҝ���ʟ�2M�������������̳��ڊ����׮�ɳ��C����=��ݢ�����갂���ț��Ś�й��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*����������Wall"

  �  HB   �?  �A   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����̳�Wall"

  E  HB   �?  �A   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��ڊ���Wall"

  E  HB   �A  �?   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��׮�ɳ��CWall"

 �  HB   �A  �?   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����=Wall")
.���*���  HB��3B  �?  �A   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���ݢ����Wall")
+���.��D  HB��3B  �A  �?   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��갂���țWall")
-��D+��D  HB��3B  �?  �A   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���Ś�й��Wall")
+��D.���  HB��3B  �A  �?   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����Ԫ����	Obstacles"
    �?  �?  �?(�Ҝ���ʟ�2�ի��ۉ��f�҈�ĕ�6��⠽������������0��Փɯ������ʂ�ɥ_��僁��RԬ����ڼi�����������Ɍ����l��Ҏ���9��������(�������Oʭ������;���ڻ�������Ó���W読���謏宥���ֳ�������Ϯ�������ꩰ�����֎��������􍮈������Ւ�]z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*�ի��ۉ��fPlatform"$
 �E ��C8\C   �?  @A   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��҈�ĕ�6Platform"

 ���  �   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���⠽����Platform".
x�EQ��DT�C
  4�� �7  �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���������0Platform".
X��D�@�D G�C
  4�� �7  �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���Փɯ���Platform".
8�D}ZE5��C
  4�� �7  �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����ʂ�ɥ_Platform")
�!0D pE���C� �7  @@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���僁��RPlatform")
 &\C pE�B�C� �7  @@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�Ԭ����ڼiPlatform")
`w�� pE D� �7  @@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����������Platform".
�����#EBB#D
��3B� �7   @   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���Ɍ����lPlatform")
��@� pE�$D� �7  @@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���Ҏ���9Platform".
 8��0��D�1D
��3B� �7   @   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���������(Platform".
���H.�D�9<D
��3B� �7   @   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��������OPlatform".
H�����D��HD
��3B� �7   @   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�ʭ������;Platform".
�����G�DT�UD
��3B� �7   @   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����ڻ����Platform".
,�	����D�3dD
��3B� �7   @   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����Ó���WPlatform"

 ��� �T�   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�読���Platform"

 ���  ��   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�謏宥���Platform"

  /�  H�   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�ֳ�����Platform"

  z�  �   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���Ϯ����Platform"$
  HC  ��  HB   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����ꩰ��Platform"$
 �"D  H�  �B   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����֎����Platform"$
 ��D  ��  C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����􍮈�Platform"$
 ��D  ��  C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *������Ւ�]Platform"$
   E  � C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 
NoneNone
������ׇ�WelcomeScreenZ��local WelcomeScreen = script:GetCustomProperty("Welcome"):WaitForObject()

local LocalPlayer = Game.GetLocalPlayer()

local mKeyBind = "ability_extra_45"

local function hideScreen(player, binding)
    if(player ~= LocalPlayer) then return end
    if(binding ~= mKeyBind) then return end

    if(WelcomeScreen.visibility == Visibility.FORCE_OFF) then
        WelcomeScreen.visibility = Visibility.FORCE_ON
    elseif(WelcomeScreen.visibility == Visibility.FORCE_ON) then
        WelcomeScreen.visibility = Visibility.FORCE_OFF
    end
end

LocalPlayer.bindingReleasedEvent:Connect(hideScreen)


cs:Welcome�
������W
�"�������Leaderboard_DataTrackerZ�"�!--[[
	Leaderboards - Data Tracker (Server)
	1.0.0 - 2020/10/05
	Contributors
		Nicholas Foreman (META) (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)
--]]

local TRACK_KILLS = script:GetCustomProperty("TrackKills")
local TRACK_DEATHS = script:GetCustomProperty("TrackDeaths")
local TRACK_DAMAGE_DEALT = script:GetCustomProperty("TrackDamageDealt")
local TRACK_RESOURCES = script:GetCustomProperty("TrackResources")

local cache = {}
local inRound = false

local function addToPlayerData(player, dataType, value)
	local playerData = Storage.GetPlayerData(player)

	if(type(playerData[dataType]) == "number") then
		playerData[dataType] = playerData[dataType] + value
	else
		playerData[dataType] = value
	end

	Storage.SetPlayerData(player, playerData)
	Events.Broadcast("LDT_Update", "TOTAL", string.upper(dataType), player, playerData[dataType])
end

local function updateKDR(player)
	local playerData = Storage.GetPlayerData(player)

	local kills, deaths = playerData.kills, playerData.deaths
	if(type(playerData.kills) ~= "number") then
		playerData.kills = 0
		kills = 0
	end
	if(type(playerData.deaths) ~= "number") then
		playerData.deaths = 0
		deaths = 0
	end

	if(deaths == 0) then
		deaths = 1
	end

	playerData.kdr = kills / deaths
	Storage.SetPlayerData(player, playerData)

	Events.Broadcast("LDT_Update", "TOTAL", "KDR", player, playerData.kdr)
end

local function updateRoundData(player)
	if(not cache[player]) then return end

	for dataType, value in pairs(cache[player]) do
		Events.Broadcast("LDT_Update", "ROUND", string.upper(dataType), player, value)
	end

	cache[player] = {}
end

local function roundStarted()
	inRound = true

	for player, _ in pairs(cache) do
		cache[player] = {}
	end
end

local function roundEnded()
	inRound = false

	for player, _ in pairs(cache) do
		updateRoundData(player)
	end
end

local function getRoundKDR(player)
	local kills, deaths = player.kills, player.deaths

	if(deaths == 0) then
		deaths = 1
	end

	return kills / deaths
end

local function playerDied(player, damage)
	if(TRACK_DEATHS) then
		addToPlayerData(player, "deaths", 1)
		updateKDR(player)

		if(inRound) then
			cache[player].deaths = player.deaths
			cache[player].kdr = getRoundKDR(player)
		end
	end

	if(TRACK_KILLS) then
		local killer = damage.sourcePlayer
		if(Object.IsValid(killer) and killer:IsA("Player")) then
			addToPlayerData(killer, "kills", 1)
			updateKDR(killer)

			if(inRound) then
				cache[killer].kills = killer.kills
				cache[killer].kdr = getRoundKDR(killer)
			end
		end
	end
end

local function playerDamaged(player, damage)
	if(not TRACK_DAMAGE_DEALT) then return end

	local killer = damage.sourcePlayer
	if(not killer:IsA("Player")) then return end

	addToPlayerData(killer, "damageDealt", damage.amount)
	if(inRound) then
		cache[killer].damageDealt = (cache[killer].damageDealt or 0) + damage.amount
	end
end

local function playerResourceChanged(player, resourceName, value)
	if(not TRACK_RESOURCES) then return end
	if(not _G.ResourcesToTrack[resourceName]) then return end

	Events.Broadcast("LDT_Update", "TOTAL", "RESOURCE", player, value, resourceName)
	if(inRound) then
		cache[player][resourceName] = player:GetResource(resourceName)
	end
end

local function playerJoined(player)
	cache[player] = {}

	player.diedEvent:Connect(playerDied)
	player.damagedEvent:Connect(playerDamaged)
	player.resourceChangedEvent:Connect(playerResourceChanged)
end

-- Realized that most people would not want resource data (like Currency) overriden
--[[function UpdateResource(player, resourceName, value)
	local playerData = Storage.GetPlayerData(player)

	if(type(playerData[resourceName]) == "number") then
		if(value <= playerData[resourceName]) then return end
	end

	playerData[resourceName] = value

	Storage.SetPlayerData(player, playerData)
	Events.Broadcast("LDT_Update", "TOTAL", "RESOURCE", player, value, resourceName)
end]]

Game.playerJoinedEvent:Connect(playerJoined)
Game.playerLeftEvent:Connect(updateRoundData)

Game.roundStartEvent:Connect(roundStarted)
Game.roundEndEvent:Connect(roundEnded)

_G.ResourcesToTrack = {}W

cs:TrackKillsP

cs:TrackDeathsP

cs:TrackDamageDealtP

cs:TrackResourcesP
���������saveZ��function OnResourceChanged(player, resName, resValue)
    
    local data = Storage.GetPlayerData(player)
    data[resName] = resValue
    Storage.SetPlayerData(player, data)
     local resultCode,errorMessage = Storage.SetPlayerData(player, data)
end
 
function OnPlayerJoined(player)
    local data = Storage.GetPlayerData(player)
    player.resourceChangedEvent:Connect(OnResourceChanged)
    local i1 = data["1"] or 0
    local a1 = data["1mil"] or 0

    player:SetResource("1", i1)
    player:SetResource("1mil", a1)


   
end
 
Game.playerJoinedEvent:Connect(OnPlayerJoined)
��ﳘ�����
Grid Childb�
� ٘������)*�٘������)
Grid Child"  �?  �?  �?(��類����Z z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�y��:

mc:euianchor:middlecenter�
 ?  �?���>%  �? �4


mc:euianchor:topleft

mc:euianchor:topleft
NoneNone
����������@"Dark Cryptic Ambient Horror" Music Construction Kit (Layers) 01
RH
AudioBlueprintAssetRef.abp_dark_cryptic_ambient_horror_layers_kit_ref
6��������PipeR!
StaticMeshAssetRefsm_pipe_001
�K∃������Easy1b�K
�K �Ҝ���ʟ�*��Ҝ���ʟ�Easy1"  �?  �?  �?(�����B27�����Ң�����ݓ��🾥֪��E������״Y�ȿ�����$���Ԫ����Z#
!
cs:Color����>n{3?  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*������Ң�Music"
  �C   HB  HB   A(�Ҝ���ʟ�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*�����ݓ��Top"
  zD   HB  HB   ?(�Ҝ���ʟ�Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>n{3?  �?%  �?z
mc:ecollisionsetting:forceoff� 
mc:evisibilitysetting:forceoff�
��������08�
 *�🾥֪��E
Checkpoint"

 0�  �B    @33�A   @(�Ҝ���ʟ�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*�������״YTransitionPlatform"

 0� �sD    @33�A   ?(�Ҝ���ʟ�Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>n{3?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��ȿ�����$Walls"
  �C   �?  �?  �?(�Ҝ���ʟ�2M�������������̳��ڊ����׮�ɳ��C����=��ݢ�����갂���ț��Ś�й��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*����������Wall"
  �   �?  �A   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����̳�Wall"
  E   �?  �A   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��ڊ���Wall"
  E   �A  �?   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��׮�ɳ��CWall"
 �   �A  �?   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����=Wall"$

0���*�����3B  �?  �A   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���ݢ����Wall"$

,���.��D��3B  �A  �?   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��갂���țWall"$

,��D+��D��3B  �?  �A   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���Ś�й��Wall"$

,��D.�����3B  �A  �?   A(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����Ԫ����	Obstacles"
    �?  �?  �?(�Ҝ���ʟ�2����������Ҫ��鏾�t������̿������쵚��������f������������Ξ���㉠��Ə�y��說���G�흈ٶݸ�������ǆ�����ک�c�ɉ��˭�0�짶ő������������У��������ح���¿����ڊ�����������ˡ��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*����������Platform"$
 @��  �  HB   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�Ҫ��鏾�tPlatform"$
  �� �;�  �B   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�������̿Platform"$
  z� �m�  C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�������쵚Platform"$
 �	�  �  HC   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���������fPlatform"$
  � �m�  zC   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����������Platform"$
  HC ���  �C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����Ξ���Platform"$
 �	D @��  �C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�㉠��Ə�yPlatform"$
  �D  /�  �C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���說���GPlatform"$
 ��D  ��  �C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��흈ٶݸPlatform"$
  �D  �B �C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��������ǆPlatform"$
 ��D �	D �	D   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *������ک�cPlatform"$
 @�D �mD  D   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ɉ��˭�0Platform"$
  /D  �D �"D   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��짶ő�Platform"$
  �C ��D  /D   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����������Platform"$
  � ��D �;D   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���У���Platform"$
  �� ��D  aD   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *������ح��Platform"$
 @��  aD �mD   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��¿����Platform"$
 �	�  �D  HD   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�ڊ�������Platform"$
  z� ��D �TD   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����ˡ��Platform"$
  zD �m�  �C   @@  @@   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>333?  �?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 
NoneNone
��Ț������timetestZ��local COMPONENT_ROOT = script:GetCustomProperty("ComponentRoot"):WaitForObject()
local PANEL = script:GetCustomProperty("Panel"):WaitForObject()
local PROGRESS_BAR = script:GetCustomProperty("ProgressBar"):WaitForObject()
local TEXT_BOX = script:GetCustomProperty("TextBox"):WaitForObject()

-- User exposed properties
local RESOURCE_NAME = COMPONENT_ROOT:GetCustomProperty("ResourceName")
local ALWAYS_SHOW = COMPONENT_ROOT:GetCustomProperty("AlwaysShow")
local POPUP_DURATION = COMPONENT_ROOT:GetCustomProperty("PopupDuration")
local MAX_VALUE = COMPONENT_ROOT:GetCustomProperty("MaxValue")
local SHOW_PROGRESS_BAR = COMPONENT_ROOT:GetCustomProperty("ShowProgressBar")
local SHOW_TEXT = COMPONENT_ROOT:GetCustomProperty("ShowText")
local SHOW_MAX_IN_TEXT = COMPONENT_ROOT:GetCustomProperty("ShowMaxInText")

-- Check user properties
if RESOURCE_NAME == "" then
    error("ResourceName required")
end

if SHOW_PROGRESS_BAR and MAX_VALUE == 0 then
    warn("MaxValue (non-zero) required for ShowProgressBar")
    SHOW_PROGRESS_BAR = false
end

if SHOW_MAX_IN_TEXT and (not SHOW_TEXT or MAX_VALUE == 0) then
    warn("ShowMaxInText requires both ShowText and non-zero MaxValue")
    SHOW_MAX_IN_TEXT = false
end

-- Constants
local LOCAL_PLAYER = Game.GetLocalPlayer()

-- Variables
local lastChangeTime = 0.0
local lastResource = 0

-- nil Tick(float)
-- Check for changes to our resource and update UI
function Tick(deltaTime)
    local resource = LOCAL_PLAYER:GetResource(RESOURCE_NAME)

    -- Update things if our resource changed
    if resource ~= lastResource then
        lastChangeTime = time()
        lastResource = resource
        PANEL.visibility = Visibility.INHERIT

        if SHOW_PROGRESS_BAR then
            PROGRESS_BAR.progress = resource / MAX_VALUE
        end

        if SHOW_TEXT then
            if SHOW_MAX_IN_TEXT then
                TEXT_BOX.text = string.format("%d / %d", resource, MAX_VALUE)
            else
                local newMinutes = math.floor(resource / 60)
                local newSeconds = math.floor(resource - (60 * newMinutes))
                local newMilliseconds = (newSeconds * 100) - newSeconds
                local milsecondsr = string.format(RESOURCE_NAME .. "mil")
                local milseconds = LOCAL_PLAYER:GetResource(milsecondsr)
                TEXT_BOX.text = string.format("%002i:%002i.%002i", tostring(newMinutes), tostring(newSeconds), tostring(milseconds))
            end
        end
    end

    -- Hide the ui if it's been long enough and we aren't always showing
    if not ALWAYS_SHOW then
        if time() > lastChangeTime + POPUP_DURATION then
            PANEL.visibility = Visibility.FORCE_OFF
        end
    end
end

-- Initialize
if not SHOW_PROGRESS_BAR then
    PROGRESS_BAR.visibility = Visibility.FORCE_OFF
end

if not SHOW_TEXT then
    TEXT_BOX.visibility = Visibility.FORCE_OFF
end

if not ALWAYS_SHOW then
    PANEL.visibility = Visibility.FORCE_OFF
end

if ALWAYS_SHOW then
    PROGRESS_BAR.progress = 0.0
    TEXT_BOX.text = "0"
end

O�������Wood Planks DarkR.
MaterialAssetRefmi_wood_planks_dark_001_uv
����ߏ���
Store Itemb�
� ��������P*���������P
Store Item"  �?  �?  �?(�����B2������؉]�򝄜�Պ�����˻GZ pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�y��:

mc:euianchor:middlecenter�
   �?  �?  �?%  �? �4


mc:euianchor:topleft

mc:euianchor:topleft*�������؉]ItemName"
    �?  �?  �?(��������PZ*

cs:Size�
  �?333?

cs:ScaleTextP pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent���<:

mc:euianchor:middlecenter�:
Test���<���<���<%  �?"
mc:etextjustify:center(�8


mc:euianchor:topcenter

mc:euianchor:topcenter*��򝄜�Պ	ItemPrice"
    �?  �?  �?(��������P2
���թ���Z

cs:Size�
  �?���>pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent����:

mc:euianchor:middlecenter�
   �?�e�>w-�=%  �? �>


mc:euianchor:bottomcenter

mc:euianchor:bottomcenter*����թ���Price"
    �?  �?  �?(�򝄜�ՊZ*

cs:Size�
  �?  �?

cs:ScaleTextPpz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent���<:

mc:euianchor:middlecenter�=
0 Coins  �?  �?  �?%  �?"
mc:etextjustify:center0�>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*������˻GButton"
    �?  �?  �?(��������Ppz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��d:

mc:euianchor:middlecenterPX�[%  �?"  �?  �?  �?*  �?  �?  �?2  �?  �?  �?:  �?  �?  �?B
��������H�>


mc:euianchor:middlecenter

mc:euianchor:middlecenter
NoneNone
�7�������һEasingEquationsZ�7�7-- EasingEquations.lua
-- Lua implementation of easing equations
-- Created by Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

--[[
	References:
		https://www.gizma.com/easing/
		https://easings.net/
		https://github.com/kikito/tween.lua/blob/master/tween.lua
--]]

--[[
	Enums:
		EaseUI.EasingEquation.LINEAR
		EaseUI.EasingEquation.QUADRATIC
		EaseUI.EasingEquation.CUBIC
		EaseUI.EasingEquation.QUARTIC
		EaseUI.EasingEquation.QUINTIC
		EaseUI.EasingEquation.SINE
		EaseUI.EasingEquation.EXPONENTIAL
		EaseUI.EasingEquation.CIRCULAR
		EaseUI.EasingEquation.ELASTIC
		EaseUI.EasingEquation.BACK
		EaseUI.EasingEquation.BOUNCE

		EaseUI.EasingDirection.IN
		EaseUI.EasingDirection.OUT
		EaseUI.EasingDirection.INOUT
--]]

local function calculatePAS(p, a, c, d)
	p, a = p or d * 0.3, a or 0
	if a < math.abs(c) then return p, c, p / 4 end -- p, a, s
	return p, a, p / (2 * math.pi) * math.asin(c/a) -- p, a, s
end

local Module = {}

function Module.GetEasingEquationFormula(easingEquation, easingDirection)
	local easingEquationName
	for name, equation in pairs(Module.EasingEquation) do
		if(easingEquation == equation) then
			easingEquationName = name
			break
		end
	end
	if(not easingEquationName) then return end

	local easingDirectionName
	for name, direction in pairs(Module.EasingDirection) do
		if(easingDirection == direction) then
			easingDirectionName = name
			break
		end
	end
	if(not easingDirectionName) then return end

	local equation = Module.Equation[easingEquationName]
	if(not equation) then return end

	return equation[easingDirectionName]
end

Module.EasingEquation = {
	LINEAR = 1,
	QUADRATIC = 2,
	CUBIC = 3,
	QUARTIC = 4,
	QUINTIC = 5,
	SINE = 6,
	EXPONENTIAL = 7,
	CIRCULAR = 8,
	ELASTIC = 9,
	BACK = 10,
	BOUNCE = 11,
}

Module.EasingDirection = {
	IN = 1,
	OUT = 2,
	INOUT = 3,
}

Module.Equation = {
	--[[EQUATION = {
		IN = function(t, b, c, d)

		end,
		OUT = function(t, b, c, d)

		end,
		INOUT = function(t, b, c, d)

		end,
	},]]
	LINEAR = {
		IN = function(t, b, c, d)
			return c*t/d + b
		end,
		OUT = function(t, b, c, d)
			return c*t/d + b
		end,
		INOUT = function(t, b, c, d)
			return c*t/d + b
		end,
	},
	QUADRATIC = {
		IN = function(t, b, c, d)
			t = t/d
			return c*t*t + b
		end,
		OUT = function(t, b, c, d)
			t = t/d
			return -c * t*(t-2) + b
		end,
		INOUT = function(t, b, c, d)
			t = t/(d/2)
			if (t < 1) then
				return c/2*t*t + b
			else
				t = t - 1
				return -c/2 * (t*(t-2) - 1) + b
			end
		end,
	},
	CUBIC = {
		IN = function(t, b, c, d)
			t = t/d
			return (c*t*t*t) + b
		end,
		OUT = function(t, b, c, d)
			t = t/d
			t = t - 1
			return c*(t*t*t + 1) + b
		end,
		INOUT = function(t, b, c, d)
			t = t/(d/2)
			if(t < 1) then
				return c/2*t*t*t + b
			else
				t = t-2
				return c/2*(t*t*t + 2) + b
			end
		end,
	},
	QUARTIC = {
		IN = function(t, b, c, d)
			t = t/d
			return c*t*t*t*t + b
		end,
		OUT = function(t, b, c, d)
			t = t/d;
			t = t - 1
			return -c * (t*t*t*t - 1) + b;
		end,
		INOUT = function(t, b, c, d)
			t = t/(d/2)
			if (t < 1) then
				return c/2*t*t*t*t + b
			else
				t = t - 2
				return -c/2 * (t*t*t*t - 2) + b
			end
		end,
	},
	QUINTIC = {
		IN = function(t, b, c, d)
			t = t/d
			return c*t*t*t*t*t + b
		end,
		OUT = function(t, b, c, d)
			t = t/d;
			t = t -1
			return c*(t*t*t*t*t + 1) + b
		end,
		INOUT = function(t, b, c, d)
			t = t/(d/2)
			if (t < 1) then
				return c/2*t*t*t*t*t + b
			else
				t = t - 2
				return c/2*(t*t*t*t*t + 2) + b
			end
		end,
	},
	SINE = {
		IN = function(t, b, c, d)
			return -c * math.cos(t/d * (math.pi/2)) + c + b
		end,
		OUT = function(t, b, c, d)
			return c * math.sin(t/d * (math.pi/2)) + b
		end,
		INOUT = function(t, b, c, d)
			return -c/2 * (math.cos(math.pi*t/d) - 1) + b
		end,
	},
	EXPONENTIAL = {
		IN = function(t, b, c, d)
			return c * (2 ^ (10 * (t/d - 1))) + b
		end,
		OUT = function(t, b, c, d)
			return c * (-(2 ^ (-10 * t/d)) + 1) + b
		end,
		INOUT = function(t, b, c, d)
			t = t/(d/2)
			if (t < 1) then
				return c/2 * (2 ^ (10 * (t - 1))) + b
			else
				t = t - 1
				return c/2 * (-(2 ^ (-10 * t)) + 2) + b
			end
		end,
	},
	CIRCULAR = {
		IN = function(t, b, c, d)
			t = t/d
			return -c * (math.sqrt(1 - t*t) - 1) + b;
		end,
		OUT = function(t, b, c, d)
			t = t/d;
			t = t - 1
			return c * math.sqrt(1 - t*t) + b;
		end,
		INOUT = function(t, b, c, d)
			t = t/(d/2)
			if (t < 1) then
				return c/2 * (2 ^ (10 * (t - 1))) + b
			else
				t = t/(d/2)
				if (t < 1) then
					return -c/2 * (math.sqrt(1 - t*t) - 1) + b
				else
					t = t- 2;
					return c/2 * (math.sqrt(1 - t*t) + 1) + b
				end
			end
		end,
	},
	ELASTIC = {
		IN = function(t, b, c, d)
			local a, p = 1, 1

			local s
			if t == 0 then return b end
			t = t / d
			if t == 1  then return b + c end
			p, a, s = calculatePAS(p, a, c, d)
			t = t - 1
			return -(a * (2 ^ (10 * t)) * math.sin((t * d - s) * (2 * math.pi) / p)) + b
		end,
		OUT = function(t, b, c, d)
			local a, p = 1, 1

			local s
			if t == 0 then return b end
			t = t / d
			if t == 1 then return b + c end
			p, a, s = calculatePAS(p, a, c, d)
			return a * (2 ^ (-10 * t)) * math.sin((t * d - s) * (2 * math.pi) / p) + c + b
		end,
		INOUT = function(t, b, c, d)
			local a, p = 1, 1

			local s
			if t == 0 then return b end
			t = t / d * 2
			if t == 2 then return b + c end
			p, a, s = calculatePAS(p,a,c,d)
			t = t - 1
			if t < 0 then return -0.5 * (a * (2 ^ (10 * t)) * math.sin((t * d - s) * (2 * math.pi) / p)) + b end
			return a * (2 ^ (-10 * t)) * math.sin((t * d - s) * (2 * math.pi) / p ) * 0.5 + c + b
		end,
	},
	BACK = {
		IN = function(t, b, c, d)
			local s = 1.70158

			t = t / d
			return c * t * t * ((s + 1) * t - s) + b
		end,
		OUT = function(t, b, c, d)
			local s = 1.70158

			t = t / d - 1
 			return c * (t * t * ((s + 1) * t + s) + 1) + b
		end,
		INOUT = function(t, b, c, d)
			local s = 1.70158 * 1.525

			t = t / d * 2
			if t < 1 then return c / 2 * (t * t * ((s + 1) * t - s)) + b end
			t = t - 2
			return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
		end,
	},
	BOUNCE = {
		IN = function(t, b, c, d)
			return c - Module.Equation.BOUNCE.OUT(d - t, 0, c, d) + b
		end,
		OUT = function(t, b, c, d)
			t = t / d
			if t < 1 / 2.75 then return c * (7.5625 * t * t) + b end
			if t < 2 / 2.75 then
				t = t - (1.5 / 2.75)
				return c * (7.5625 * t * t + 0.75) + b
			elseif t < 2.5 / 2.75 then
				t = t - (2.25 / 2.75)
				return c * (7.5625 * t * t + 0.9375) + b
			end
			t = t - (2.625 / 2.75)
			return c * (7.5625 * t * t + 0.984375) + b
		end,
		INOUT = function(t, b, c, d)
			if t < d / 2 then return Module.Equation.BOUNCE.IN(t * 2, 0, c, d) * 0.5 + b end
  			return Module.Equation.BOUNCE.OUT(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
		end,
	},
}

return Module
�
�������ԹTrailsClientZ�
�
local ShopData = require(script:GetCustomProperty("ShopData"))

local trails = {}

local function getTrail(trailId)
	for _, trail in pairs(ShopData.Trails) do
		if(trail.id == trailId) then
			return trail
		end
	end
end

local function equipTrail(player, trailId)
	local trail = getTrail(trailId)
	if(trailId ~= 0) then
		if(not trail) then return end
	end

	if(trails[player]) then
		trails[player]:Destroy()
		trails[player] = nil
	end

	if(trailId == 0) then return end

	local attachedTrail = World.SpawnAsset(trail.template)
	attachedTrail.name = "Trail"
	attachedTrail:AttachToPlayer(player, "root")
	attachedTrail:SetPosition(Vector3.New(0, 0, 150))
	trails[player] = attachedTrail
end

local function resourceChanged(player, resourceName, resourceValue)
	if(resourceName ~= "CurrentTrail") then return end

	equipTrail(player, resourceValue)
end

local function playerJoined(player)
	player.resourceChangedEvent:Connect(resourceChanged)

	local currentTrailId = player:GetResource("CurrentTrail")
	equipTrail(player, currentTrailId)
end

local function playerLeft(player)
	if(not trails[player]) then return end

	trails[player]:Destroy()
	trails[player] = nil
end

Game.playerJoinedEvent:Connect(playerJoined)
Game.playerLeftEvent:Connect(playerLeft)

cs:ShopData������
������ShopDataZ��local Game = script:GetCustomProperty("Game"):WaitForObject()

local trails = {
	white = script:GetCustomProperty("WhiteTrail"),
	teal = script:GetCustomProperty("TealTrail"),
	red = script:GetCustomProperty("RedTrail"),
	magenta = script:GetCustomProperty("MagentaTrail"),
	purple = script:GetCustomProperty("PurpleTrail"),
	blue = script:GetCustomProperty("BlueTrail"),
	green = script:GetCustomProperty("GreenTrail"),
	yellow = script:GetCustomProperty("YellowTrail"),
	orange = script:GetCustomProperty("OrangeTrail"),
	rgb = script:GetCustomProperty("RGBTrail"),
}

return {
    Modifiers = {
        {
            name = "Increase Multiplier (Global)",
            price = 40,
            func = function(player)
                Game:SetNetworkedCustomProperty("Multiplier", Game:GetCustomProperty("Multiplier") * 2)
                Events.BroadcastToAllPlayers("Message", string.format("%s has increased the multiplier!", player.name))

                return true
            end
        },
        {
            name = "Decrease Multiplier (Global)",
            price = 40,
            func = function(player)
				if(Game:GetCustomProperty("Multiplier") < 1) then return false end

                Game:SetNetworkedCustomProperty("Multiplier", Game:GetCustomProperty("Multiplier") / 2)
                Events.BroadcastToAllPlayers("Message", string.format("%s has decreased the multiplier!", player.name))

                return true
            end
        }
    },
    Trails = {
		{
			id = 1,
			name = "White Trail",
			price = 60,
			template = trails.white
		},
		{
			id = 2,
			name = "Teal Trail",
			price = 60,
			template = trails.teal
		},
		{
			id = 3,
			name = "Red Trail",
			price = 60,
			template = trails.red
		},
		{
			id = 4,
			name = "Magenta Trail",
			price = 60,
			template = trails.magenta
		},
		{
			id = 5,
			name = "Purple Trail",
			price = 60,
			template = trails.purple
		},
		{
			id = 6,
			name = "Blue Trail",
			price = 60,
			template = trails.blue
		},
		{
			id = 7,
			name = "Green Trail",
			price = 60,
			template = trails.green
		},
		{
			id = 8,
			name = "Yellow Trail",
			price = 60,
			template = trails.yellow
		},
		{
			id = 9,
			name = "Orange Trail",
			price = 60,
			template = trails.orange
		},
		{
			id = 10,
			name = "RGB Trail",
			price = 300,
			template = trails.rgb,
		},
	},
}�

cs:Game��ڢ������

cs:WhiteTrail������ð�

cs:YellowTrail��ǃ�Գ���

cs:RedTrail�����濳��

cs:PurpleTrail����؟����

cs:MagentaTrail��󈤴�

cs:GreenTrail���������

cs:BlueTrail��͑ױ����

cs:TealTrail������ױ��

cs:OrangeTrail���������

cs:RGBTrail�
����Մ��&
�����Մ��&	RGB Trailb�
� �괢ӷ���*��괢ӷ���	RGB Trail"  �?  �?  �?(�����BZ�
#
bp:Particle Scale Multipliere  @@
!
bp:color��g?��e=e=%  �?

bp:Emissive Booste  �@

bp:Lifee  �?
"
	bp:ColorB��0�>��?H>�=%  �?
"
	bp:ColorC�"-y<N'�>�qe?%  �?

bp:Sort Priority AdjustmentX pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
���Ǆ��� �
NoneNone
������ױ��
Teal Trailb�
� �������*��������
Teal Trail"  �?  �?  �?(�����BZ�
#
bp:Particle Scale Multipliere  @@

bp:color�H�z?I�p?%  �?

	bp:ColorB�H�z?I�p?%  �?

	bp:ColorC�H�z?I�p?%  �?

bp:Emissive Booste  �@

bp:Lifee  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
���Ǆ��� �
NoneNone
��͑ױ����
Blue Trailb�
� �ӯ����v*��ӯ����v
Blue Trail"  �?  �?  �?(�����BZ�
#
bp:Particle Scale Multipliere  @@
!
bp:color�"-y<N'�>�qe?%  �?
"
	bp:ColorB�"-y<N'�>�qe?%  �?
"
	bp:ColorC�"-y<N'�>�qe?%  �?

bp:Emissive Booste  �@

bp:Lifee  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
���Ǆ��� �
NoneNone
��󈤴�Magenta Trailb�
� �����̐��*������̐��Magenta Trail"  �?  �?  �?(�����BZ�
#
bp:Particle Scale Multipliere  @@
!
bp:color�͙P?ʶT<a��=%  �?
"
	bp:ColorB�͙P?ʶT<a��=%  �?
"
	bp:ColorC�͙P?ʶT<a��=%  �?

bp:Emissive Booste  �@

bp:Lifee  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
���Ǆ��� �
NoneNone
������ð�White Trailb�
� մ�ɿ⻬�*�մ�ɿ⻬�White Trail"  �?  �?  �?(�����BZr
#
bp:Particle Scale Multipliere  @@
!
bp:color�  �?  �?  �?%  �?

bp:Emissive Booste  �@

bp:Lifee  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
���Ǆ��� �
NoneNone
J��ί�߲ضIcon Leaderboard	R)
PlatformBrushAssetRefIcon_Leaderboard
Mܑ���ࢂ�Emissive Glow OpaqueR(
MaterialAssetReffxma_opaque_emissive
�����܄�
PrefixTagsZ��local Module = {}

local prefixes = {
    Developer = {
        text = "Game Creator",
        color = Color.New(0, 0.5, 1, 1),
        isModerator = true,
        players = {
            "NicholasForeman",
        },
    },
    TournamentHost = {
        text = "Tournament Host",
        isModerator = true,
        color = Color.New(1, 0.1, 0.1, 1),
        players = {
            "Devoun",
        },
    },
    Moderator = {
        text = "Moderator",
        isModerator = true,
        color = Color.New(0, 0.5, 0, 1),
        players = {

        },
    },
    FirstWinner = {
        text = "First Winner",
        color = Color.New(1, 0.2, 1, 1),
        players = {
            "SnoFlak"
        },
    },
    ContentCreator = {
        text = "Content Creator",
        color = Color.New(0.13, 0.05, 0.38, 1),
        players = {
            "JymbowSlice",
            "SirBaker",
            "Stokki",
            "Tianlein",
            "gothix",
            "chip228",
            "ZulZorander",
            "TigressX",
            "Fufumii",

            "FearTheDev",
            "LiaTheKoalaBear",
            "AphrimCreates",
            "Daddio",
            "MetsuRjKen",
            "Morticai"
        }
    },
    Waffle = {
        text = "Waffle",
        color = Color.New(1, 0.8, 0.15, 1),
        players = {
            "Waffle"
        },
    },
    Manticore = {
        text = "Manticore",
        color = Color.New(229/255, 130/255, 0, 1),
        isModerator = true,
        players = {
            "Basilisk",
            "Bigglebuns",
            "Chris",
            "Depp",
            "featurecreeper",
            "Holy",
            "lodle",
            "lokii",
            "max",
            "rbrown",
            "Stanzilla",
            "Stephano",
            "Turbo",
            "Buckmonster",
            "deadlyfishesMC",
            "coreslinkous",
            "Dracowolfie",
            "JayDee",
            "Poippels",
            "Scav",
            "zurishmi",
            "aBomb",
            "Anna",
            "Bumblebear",
            "Gabunir",
            "Griffin",
            "Mehaji",
            "pchiu",
            "qualispec",
            "Robotron",
            "Sobchak",
            "Tobs",
            "standardcombo",
            "mrbigfists",
            "kytsu"
        },
    },
}

function Module:GetPrefix(prefixName)
    return prefixes[prefixName]
end

function Module:GetPlayerPrefix(player)
    for prefixName, prefix in pairs(prefixes) do
        for _, possiblePlayer in pairs(prefix.players) do
            if(player.name == possiblePlayer) then
                return prefix
            end
        end
    end
end

return Module
��������KillTriggerTemplateb�
� ��������x*���������xKillTriggerTemplate"   ?  �?  �?(�����Bpz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box
NoneNone
�Z���������Medium1b�Z
�Y �Ҝ���ʟ�*��Ҝ���ʟ�Medium1"  �?  �?  �?(�����B2A�����ޗ�����ݓ����������������״Y���������ȿ�����$���Ԫ����Z#
!
cs:Color�  �?��>?�K=%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*������ޗ�Music"
 �;D   HB  HB  pA(�Ҝ���ʟ�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*�����ݓ��Top"
 ��D   HB  HB   ?(�Ҝ���ʟ�Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z
mc:ecollisionsetting:forceoff� 
mc:evisibilitysetting:forceoff�
��������08�
 *���������
Checkpoint"

 0�  �B    @33�A   @(�Ҝ���ʟ�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*�������״YTransitionPlatform"

 0� `�D    @33�A   ?(�Ҝ���ʟ�Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��>?�K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���������KillTriggers"
    �?  �?  �?(�Ҝ���ʟ�2{Դ򗛿˙��ч�����w�ӗޗ̡�J�������������Ġ˷���K�닰�߻����̰���Ց�Ǽ��譱����ս��N���Ю����Ի�����0�������0z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*�Դ򗛿˙�Kill"$
 ���  H�  pB    ?   ?��L>(��������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
�������� �
 *��ч�����wKill")
  ��  H�  HC �A   ?   ?��L>(��������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
�������� �
 *��ӗޗ̡�JKill")
 �� �n� ��C����   ?   ?��L>(��������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
�������� �
 *��������Kill"3
���Ö�Y@�C �A������4   ?   ?��L>(��������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
�������� �
 *�������Kill")
L��Cŀ�� ��C �A   ?   ?��L>(��������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
�������� �
 *�Ġ˷���KKill".
 �hD �Y��D
 �A 4B   ?   ?��L>(��������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
�������� �
 *��닰�߻��Kill"$
 @�D ��� �7D    ?   ?��L>(��������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
�������� �
 *���̰���ՑKill")
 ��D  MC �7D��3B   ?   ?��L>(��������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
�������� �
 *��Ǽ��譱Kill"3
&�D�DH�PD�.e7
 �B����   ?   ?��L>(��������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
�������� �
 *�����ս��NKill"3
���@!�:D �iD�.�7 �B�59   ?   ?��L>(��������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
�������� �
 *����Ю���Kill"3
3���TD)߂D   � �B`���   ?   ?��L>(��������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
�������� �
 *��Ի�����0Kill"3
  �� �TD  �D   � �Ba(�9   ?   ?��L>(��������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
�������� �
 *��������0Kill"3
�+�� �TD|��D  �� �B���   ?   ?��L>(��������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
�������� �
 *��ȿ�����$Walls"
 �;D   �?  �?  �?(�Ҝ���ʟ�2M�������������̳��ڊ����׮�ɳ��C����=��ݢ�����갂���ț��Ś�й��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*����������Wall"
  �   �?  �A  pA(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?/=? �K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����̳�Wall"
  E   �?  �A  pA(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?/=? �K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��ڊ���Wall"
  E   �A  �?  pA(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��>?�K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��׮�ɳ��CWall"
  �   �A  �?  pA(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?/=? �K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����=Wall"$

0���0�����3B  �?  �A  pA(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?/=? �K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���ݢ����Wall"$

,���0��D��3B  �A  �?  pA(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?/=? �K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��갂���țWall"$

0��D0��D��3B  �?  �A  pA(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?/=? �K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���Ś�й��Wall"$

0��D0�����3B  �A  �?  pA(�ȿ�����$Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?/=? �K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����Ԫ����	Obstacles"
    �?  �?  �?(�Ҝ���ʟ�2|���͎��G����������ĝ������Ȼ���������ނ����ཱི�©g��������ػ�骨�������㝒������Ĵ߄2���������ϵ�װ񦘉��䥋���z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*����͎��GPlatform"$
 ���  H�  �A   �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��>?�K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���������Platform")
 ���  H�  C �A  �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��>?�K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���ĝ�����Platform")
 �	� �m���yC����  �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��>?�K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��Ȼ�����Platform".
  H�  ��  �C
 �A����  �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��>?�K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����ނ��Platform"3
  �C ���  �C�.�6���AAae6  �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��>?�K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���ཱི�©gPlatform"3
 �mD �T� �	D �A��3B��6  �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��>?�K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���������Platform"3
 @�D  ��  /D�.�6���B�'7  �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��>?�K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�ػ�骨���Platform"3
 @�D  HC  /D�.�6��C��b7  �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��>?�K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����㝒��Platform"3
  D �	D  HD �A�C�:7  �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��>?�K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����Ĵ߄2Platform")

 �;D  aD
�C2{5  �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��>?�K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����������Platform"3
  � �TD  zD �A��3C"$�6  �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��>?�K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�ϵ�װ񦘉Platform"3
  �� �TD ��D�.�6��3C�ܽ6  �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��>?�K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���䥋���Platform"3
  �� �TD ��D �A��3C���6  �@   ?   ?(���Ԫ����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��>?�K=%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 
NoneNone
���ч�ͬ��Leaderboards_READMEZ��--[[
	Leaderboards - README
	1.0.0 - 2020/10/05
	Contributors
		Nicholas Foreman (META) (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

	1.	Description
		Leaderboards is a component that simplifies the process of adding a global leaderboard to a game. It is as simple as dragging
		and dropping a leaderboard template into the hierarchy and adjusting to meet your needs.

	2.	Setup
		1)	Drag and drop "Leaderboard Dependencies" into the hierarchy
		Note: Make sure this is the only version in the hierarchy
		2)	Drag and drop either a "World Leaderboard" or "Interface Leaderboard" into the hierarchy
		3)	Drag the global leaderboard created beforehand (see 3b) into the LeaderboardReference
		custom property of the World/Interface Leaderboard
		4)	Alter custom properties for each template as needed.
	2b.	Creating a Global Leaderboard
		1)	Go to the "Global Leaderboards" tab in the editor: View > Global Leaderboards
		2)	Click "Create New Leaderboard"
		3)	Follow the prompt to create your leaderboard

	3.	Usage
		The most basic usage includes KDR, Kills, and Deaths by dragging the template (world or interface) into the hierarchy and
		adjusting LeaderboardStat to be KDR, KILLS, or DEATHS. However, more advanced usage includes Resources in which you can
		set LeaderboardStat to be RESOURCE and change ResourceName to any resource of your choosing, such as "Money".

	4.	Leaderboard Dependencies
		"Leaderboard Dependencies" is a single template that must be in the hierarchy and remain in the hierarchy. There should
		only be one of this template in the hierarchy. It handles the persistent tracking of resources, kills, deaths, and kdr.
		Having multiple of this in the hierarchy can cause unwanted bugs and possible corruption. Not including it in the hierarchy
		will make each of the leaderboard template not function, either.
	4b.	World Leaderboard
		A "World Leaderboard" is a physical panel in the world utilizing WorldText to display rankings.
	4b.	Interface Leaderboard
		An "Interface Leaderboard" is a UI panel utilizing UI elements to display rankings on the player's screen. With slightly
		more customization, included is the ability to toggle and ease in/out the UI.

	5.	Discord
		If you have any questions, feel free to join the Core Hub Discord server:
			discord.gg/core-creators
		We are a friendly group of creators and players interested in the games and community on Core. Open to everyone,
		regardless of your level of experience or interests.
--]]
��𨸗��ResetCameraZ��local LocalPlayer = Game.GetLocalPlayer()

local function resetCameraView()
	local view = LocalPlayer:GetViewWorldRotation()
	LocalPlayer:SetLookWorldRotation(Rotation.New(view.x, view.y, LocalPlayer:GetWorldRotation().z))
end

Events.Connect("ResetCamera", resetCameraView)
��é���PlayerListPlayerTemplateb�
� �����ݮ�*������ݮ�PlayerListPlayerTemplate"  �?  �?  �?(�����è�I2%����Ƿ��l�������<���ӥ���
�����ˏ�Z z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�m -   @:

mc:euianchor:middlecenterP�
 %   ? �4


mc:euianchor:topleft

mc:euianchor:topleft*�����Ƿ��lIcon"
    �?  �?  �?(�����ݮ�ZJ

cs:Size�  �?

cs:AspectRatioe  �?

cs:AspectRatioYAxisDomiantPz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�w  :

mc:euianchor:middlecenter�
   �?  �?  �?%  �? �4


mc:euianchor:topleft

mc:euianchor:topleft*��������<Name"
    �?  �?  �?(�����ݮ�Z

cs:ScaleTextPz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��� %  B:

mc:euianchor:middlecenter�R
abcdefghijklmnopqrstuvwxyz1234  �?  �?  �?%  �?"
mc:etextjustify:left0�4


mc:euianchor:topleft

mc:euianchor:topleft*����ӥ���
FastestTime"
    �?  �?  �?(�����ݮ�Z

cs:ScaleTextPz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��d %  ��:

mc:euianchor:middlecenter�;
00:00.00  �?�Hs?  �>%  �?"
mc:etextjustify:right�<


mc:euianchor:bottomright

mc:euianchor:bottomright*������ˏ�Button"
    �?  �?  �?(�����ݮ�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��:

mc:euianchor:middlecenterPX�w
	DEVELOPER  �?  �?  �?"  �?  �?  �?%2�<*  �?  �?  �?2  �?  �?  �?:  �?  �?  �?B
��������HP�4


mc:euianchor:topleft

mc:euianchor:topleft
NoneNone
����ЦԽ��PlayerNameplatesZ��local NameplateTemplate = script:GetCustomProperty("NameplateTemplate")
local PrefixTags = require(script:GetCustomProperty("PrefixTags"))

local LocalPlayer = Game.GetLocalPlayer()

local nameplates = {}

local function playerJoined(player)
    local nameplate = World.SpawnAsset(NameplateTemplate)
    nameplates[player] = nameplate

    local nameplateName, nameplatePrefix = 
        nameplate:FindChildByName("Name"),
        nameplate:FindChildByName("Prefix")
    
    nameplateName.text = player.name

    local playerPrefix = PrefixTags:GetPlayerPrefix(player)
    if(playerPrefix) then
        nameplatePrefix.text = playerPrefix.text
        nameplatePrefix:SetColor(playerPrefix.color)
    end
    
	nameplate:AttachToPlayer(player, "Nameplate")
end

local function playerLeft(player)
    local nameplate = nameplates[player]
    if(not nameplate) then return end

    nameplate:Destroy()
	nameplates[player] = nil
end

local function rotateNameplate(nameplate)
	local quat = Quaternion.New(LocalPlayer:GetViewWorldRotation())
	quat = quat * Quaternion.New(Vector3.UP, 180.0)
	nameplate:SetWorldRotation(Rotation.New(quat))
end

function Tick(deltaTime)
    for _, nameplate in pairs(nameplates) do
        if(Object.IsValid(nameplate)) then
            rotateNameplate(nameplate)
        end
    end
end

Game.playerJoinedEvent:Connect(playerJoined)
Game.playerLeftEvent:Connect(playerLeft)
��ʘ��ڐ�
PrefixTagsZ��local Module = {}

local prefixes = {
    Developer = {
        text = "Game Creator",
        color = Color.New(0, 0.5, 1, 1),
        isModerator = true,
        players = {
            "NicholasForeman"
        },
    },
    Moderator = {
        text = "Moderator",
        isModerator = true,
        color = Color.New(0, 0.5, 0, 1),
        players = {
            
        },
    },
    FirstWinner = {
        text = "First Winner",
        color = Color.New(1, 0.2, 1, 1),
        players = {
            "SnoFlak"
        },
    },
    ContentCreator = {
        text = "Content Creator",
        color = Color.New(0.13, 0.05, 0.38, 1),
        players = {
            "JymbowSlice",
            "SirBaker",
            "Stokki",
            "Tianlein",
            "gothix",
            "chip228",
            "ZulZorander",
            "TigressX",
            "Fufumii",
            
            "FearTheDev",
            "LiaTheKoalaBear",
            "AphrimCreates",
            "Daddio",
            "MetsuRjKen",
            "Morticai"
        }
    },
    Waffle = {
        text = "Waffle",
        color = Color.New(1, 0.8, 0.15, 1),
        players = {
            "Waffle"
        },
    },
    Manticore = {
        text = "Manticore",
        color = Color.New(229/255, 130/255, 0, 1),
        isModerator = true,
        players = {
            "Basilisk",
            "Bigglebuns",
            "Chris",
            "Depp",
            "featurecreeper",
            "Holy",
            "lodle",
            "lokii",
            "max",
            "rbrown",
            "Stanzilla",
            "Stephano",
            "Turbo",
            "Buckmonster",
            "deadlyfishesMC",
            "coreslinkous",
            "Dracowolfie",
            "JayDee",
            "Poippels",
            "Scav",
            "zurishmi",
            "aBomb",
            "Anna",
            "Bumblebear",
            "Gabunir",
            "Griffin",
            "Mehaji",
            "pchiu",
            "qualispec",
            "Robotron",
            "Sobchak",
            "Tobs",
            "standardcombo",
            "mrbigfists",
            "kytsu"
        },
    },
}

function Module:GetPrefix(prefixName)
    return prefixes[prefixName]
end

function Module:GetPlayerPrefix(player)
    for prefixName, prefix in pairs(prefixes) do
        for _, possiblePlayer in pairs(prefix.players) do
            if(player.name == possiblePlayer) then
                return prefix
            end
        end
    end
end

return Module
>�����SkylightR%
BlueprintAssetRefCORESKY_Skylight
F���Ʊ����Market	R/
PlatformBrushAssetRefUI_Fantasy_icon_Market
@͛������Icon Trophy	R$
PlatformBrushAssetRefIcon_Trophy
>��歪���
Icon Clock	R#
PlatformBrushAssetRef
Icon_Clock
�Y��睼����Leaderboard_InterfaceZ�Y�Y--[[
	Leaderboards - Interface (Client)
	1.0.0 - 2020/10/05
	Contributors
		Nicholas Foreman (META) (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)
--]]

local EaseUI = require(script:GetCustomProperty("EaseUI"))

local LocalPlayer = Game.GetLocalPlayer()

local EntryTemplate = script:GetCustomProperty("EntryTemplate")
local Leaderboard = script:GetCustomProperty("Leaderboard"):WaitForObject()

local LeaderboardReference = Leaderboard:GetCustomProperty("LeaderboardReference")
assert(LeaderboardReference.isAssigned, "The NetReference provided is not properly set for LeaderboardReference.")

local LeaderboardPanel = script:GetCustomProperty("LeaderboardPanel"):WaitForObject()
local Entries = script:GetCustomProperty("Entries"):WaitForObject()
local Title = script:GetCustomProperty("Title"):WaitForObject()
local UpdateTimer = script:GetCustomProperty("UpdateTimer"):WaitForObject()

local LEADERBOARD_TYPE = Leaderboard:GetCustomProperty("LeaderboardType")
local LEADERBOARD_STAT = Leaderboard:GetCustomProperty("LeaderboardStat")
local LEADERBOARD_PERSISTENCE = Leaderboard:GetCustomProperty("LeaderboardPersistence")

-- Only applicable if LEADERBOARD_STAT is RESOURCE
local RESOURCE_NAME = Leaderboard:GetCustomProperty("ResourceName")

local DISPLAY_AS_INTEGER = Leaderboard:GetCustomProperty("DisplayAsInteger")

local UPDATE_ON_ROUND_ENDED = Leaderboard:GetCustomProperty("UpdateOnRoundEnded")
local UPDATE_ON_EVENT = Leaderboard:GetCustomProperty("UpdateOnEvent")
local UPDATE_TIMER = math.abs(Leaderboard:GetCustomProperty("UpdateTimer"))

local FIRST_PLACE_COLOR = Leaderboard:GetCustomProperty("FirstPlaceColor")
local SECOND_PLACE_COLOR = Leaderboard:GetCustomProperty("SecondPlaceColor")
local THIRD_PLACE_COLOR = Leaderboard:GetCustomProperty("ThirdPlaceColor")
local NO_PODIUM_PLACEMENT_COLOR = Leaderboard:GetCustomProperty("NoPodiumPlacementColor")
local USERNAME_COLOR = Leaderboard:GetCustomProperty("UsernameColor")
local SCORE_COLOR = Leaderboard:GetCustomProperty("ScoreColor")

local TOGGLE_BINDING = Leaderboard:GetCustomProperty("ToggleBinding")
local TOGGLE_EVENT = Leaderboard:GetCustomProperty("ToggleEvent")
local FORCE_ON_EVENT = Leaderboard:GetCustomProperty("ForceOnEvent")
local FORCE_OFF_EVENT = Leaderboard:GetCustomProperty("ForceOffEvent")

local EASE_TOGGLE = Leaderboard:GetCustomProperty("EaseToggle")
local EASE_BEGINNING = Leaderboard:GetCustomProperty("EaseBeginning")
local EASING_DURATION = Leaderboard:GetCustomProperty("EasingDuration")
local EASING_EQUATION_IN = Leaderboard:GetCustomProperty("EasingEquationIn")
local EASING_DIRECTION_IN = Leaderboard:GetCustomProperty("EasingDirectionIn")
local EASING_EQUATION_OUT = Leaderboard:GetCustomProperty("EasingEquationOut")
local EASING_DIRECTION_OUT = Leaderboard:GetCustomProperty("EasingDirectionOut")

local LEADERBOARD_TYPES = { "GLOBAL", "MONTHLY", "WEEKLY", "DAILY" }
local LEADERBOARD_STATS = { "RESOURCE", "KDR", "KILLS", "DEATHS", "DAMAGE_DEALT" }
local LEADERBOARD_PERSISTENCES = { "TOTAL", "ROUND" }
local EASE_BEGINNINGS = { "UP", "DOWN", "LEFT", "RIGHT" }

local SCORE_SUFFIXES = { "K", "M", "B", "T", "Q", "Qu", "S", "Se", "O", "N", "D" }

local currentEntries = {}
local lastUpdate = time()
local isVisible = false

local lastTask

local isCursorVisible, canCursorInteractWithUI =
	UI.IsCursorVisible(), UI.CanCursorInteractWithUI()

local function GetTime(delta)
	delta = tonumber(delta)

	if delta <= 0 then
		return 0, 0, 0
	else
		local minutes = math.floor(delta / 60)
		local seconds = math.floor(delta - (minutes * 60))
		local milliseconds = math.floor(math.ceil((delta - (minutes * 60) - seconds) * 10000) / 10)

		return minutes, seconds, milliseconds
	end
end

local function GetFormattedTime(delta)
	local minutes, seconds, milliseconds = GetTime(delta)

	return string.format("%002i:%002i.%003i", tostring(minutes), tostring(seconds), tostring(milliseconds))
end

local function toSuffixString(num)
	for index = #SCORE_SUFFIXES, 1, -1 do
		local value = 10 ^ (index * 3)
		if num >= value then
			return string.format("%.1f", num / value) .. SCORE_SUFFIXES[index]
		end
	end
	return string.format("%.1f", num)
end

local function getShouldUpdate(newEntries, currentEntries)
	if(#newEntries ~= #currentEntries) then return true end

	for index, newEntry in ipairs(newEntries) do
		if(index > 10) then break end

		local currentEntry = currentEntries[index]
		if(not currentEntry) then return true end

		if(newEntry.id ~= currentEntry.id) then
			return true
		elseif(newEntry.score ~= currentEntry.score) then
			return true
		end
	end

	return false
end

local function getFirstTenEntries(entries)
	local newEntries = {}

	for index, entry in ipairs(entries) do
		if(index > 100) then break end

		newEntries[index] = entries[index]
	end

	return newEntries
end

local function clearEntries()
	for _, child in pairs(Entries:GetChildren()) do
		child:Destroy()
	end
end

local function getProperty(value, options)
	value = string.upper(value)

	for _, option in pairs(options) do
		if(value == option) then return value end
	end

	return options[1]
end

local function bindingReleased(player, binding)
	if(binding ~= TOGGLE_BINDING) then return end

	ForceToggle()
end

function ForceOn()
	isVisible = true

	isCursorVisible, canCursorInteractWithUI =
		UI.IsCursorVisible(), UI.CanCursorInteractWithUI()

	UI.SetCursorVisible(true)
	UI.SetCanCursorInteractWithUI(true)

	LeaderboardPanel.visibility = Visibility.FORCE_ON
	if(EASE_TOGGLE) then
		local vertical = (EASE_BEGINNING == "UP") or (EASE_BEGINNING == "DOWN")
		if(vertical) then
			EaseUI.EaseY(LeaderboardPanel, 0, EASING_DURATION, EASING_EQUATION_IN, EASING_DIRECTION_IN)
		else
			EaseUI.EaseX(LeaderboardPanel, 0, EASING_DURATION, EASING_EQUATION_IN, EASING_DIRECTION_IN)
		end
	end
end

function ForceOff()
	isVisible = false

	UI.SetCursorVisible(isCursorVisible)
	UI.SetCanCursorInteractWithUI(canCursorInteractWithUI)

	isCursorVisible = nil
	canCursorInteractWithUI = nil

	if(EASE_TOGGLE) then
		if(EASE_BEGINNING == "UP") then
			EaseUI.EaseY(LeaderboardPanel, -1500, EASING_DURATION, EASING_EQUATION_OUT, EASING_DIRECTION_OUT)
		elseif(EASE_BEGINNING == "DOWN") then
			EaseUI.EaseY(LeaderboardPanel, 1500, EASING_DURATION, EASING_EQUATION_OUT, EASING_DIRECTION_OUT)
		elseif(EASE_BEGINNING == "LEFT") then
			EaseUI.EaseX(LeaderboardPanel, -1500, EASING_DURATION, EASING_EQUATION_OUT, EASING_DIRECTION_OUT)
		elseif(EASE_BEGINNING == "RIGHT") then
			EaseUI.EaseX(LeaderboardPanel, 1500, EASING_DURATION, EASING_EQUATION_OUT, EASING_DIRECTION_OUT)
		end

		local task
		task = Task.Spawn(function()
			Task.Wait(EASING_DURATION)

			if((not lastTask) or (lastTask ~= task)) then return end
			lastTask = nil

			if(not isVisible) then
				LeaderboardPanel.visibility = Visibility.FORCE_OFF
			end
		end)
		lastTask = task
	else
		LeaderboardPanel.visibility = Visibility.FORCE_OFF
	end
end

function ForceToggle()
	if(isVisible) then
		ForceOff()
	else
		ForceOn()
	end
end

function Toggle(id)
	if(id) then
		if(id ~= Leaderboard.id) then return end
	end

	ForceToggle()
end

function Update(id)
	if(not Leaderboards.HasLeaderboards()) then return end

	if(id) then
		if(id ~= Leaderboard.id) then return end
	end

	local newEntries = Leaderboards.GetLeaderboard(LeaderboardReference, LeaderboardType[LEADERBOARD_TYPE])
	if(not newEntries) then return end
	newEntries = getFirstTenEntries(newEntries)

	local shouldUpdate = getShouldUpdate(newEntries, currentEntries)
	if(not shouldUpdate) then return end

	clearEntries()
	currentEntries = newEntries

	local count = #newEntries
	for index, entry in ipairs(newEntries) do
		local leaderboardEntry = World.SpawnAsset(EntryTemplate, {
			parent = Entries,
		})
		leaderboardEntry.name = entry.name

		local playerPosition, playerName, playerScore =
			leaderboardEntry:GetCustomProperty("Rank"):WaitForObject(),
			leaderboardEntry:GetCustomProperty("Name"):WaitForObject(),
			leaderboardEntry:GetCustomProperty("Score"):WaitForObject()

		playerPosition.text = string.format("%002i", index)
		if(index == 1) then
			playerPosition:SetColor(FIRST_PLACE_COLOR)
		elseif(index == 2) then
			playerPosition:SetColor(SECOND_PLACE_COLOR)
		elseif(index == 3) then
			playerPosition:SetColor(THIRD_PLACE_COLOR)
		else
			playerPosition:SetColor(NO_PODIUM_PLACEMENT_COLOR)
		end

		playerName.text = string.sub(entry.name, 1, 30)
		playerName:SetColor(USERNAME_COLOR)

		if(RESOURCE_NAME == "HighScore") then
			playerScore.text = GetFormattedTime(entry.score / 1000)
		elseif(DISPLAY_AS_INTEGER) then
			playerScore.text = tostring(math.ceil(entry.score))
		else
			playerScore.text = toSuffixString(entry.score)
		end
		playerScore:SetColor(SCORE_COLOR)

		leaderboardEntry.y = (leaderboardEntry.height * (index - 1)) + (5 * (index - 1))

		if(count >= 8) then
			leaderboardEntry.width = leaderboardEntry.width - 20
		end
	end
end

function Tick()
	if((time() - lastUpdate) < UPDATE_TIMER) then
		local timeLeft = math.ceil((lastUpdate + UPDATE_TIMER) - time())
		UpdateTimer.text = string.format("UPDATES IN %s SECONDS", timeLeft)
	else
		lastUpdate = time()

		Update()
	end
end

Events.Connect("LDT_Update", Update)
Events.Connect("TDT_Toggle", Toggle)

if(UPDATE_ON_ROUND_ENDED) then
	Game.roundEndEvent:Connect(Update)
end

if(#UPDATE_ON_EVENT > 0) then
	Events.Connect(UPDATE_ON_EVENT, Update)
end

if(#TOGGLE_EVENT > 0) then
	Events.Connect(TOGGLE_EVENT, ForceToggle)
end

if(#FORCE_ON_EVENT > 0) then
	Events.Connect(FORCE_ON_EVENT, ForceOn)
end

if(#FORCE_OFF_EVENT > 0) then
	Events.Connect(TOGGLE_EVENT, ForceOff)
end

if(TOGGLE_BINDING) then
	LocalPlayer.bindingReleasedEvent:Connect(bindingReleased)
end

LEADERBOARD_TYPE = getProperty(LEADERBOARD_TYPE, LEADERBOARD_TYPES)
LEADERBOARD_STAT = getProperty(LEADERBOARD_STAT, LEADERBOARD_STATS)
LEADERBOARD_PERSISTENCE = getProperty(LEADERBOARD_PERSISTENCE, LEADERBOARD_PERSISTENCES)
EASE_BEGINNING = getProperty(EASE_BEGINNING, EASE_BEGINNINGS)

EASING_EQUATION_IN = EaseUI.EasingEquation[EASING_EQUATION_IN]
EASING_DIRECTION_IN = EaseUI.EasingEquation[EASING_DIRECTION_IN]
EASING_EQUATION_OUT = EaseUI.EasingEquation[EASING_EQUATION_OUT]
EASING_DIRECTION_OUT = EaseUI.EasingEquation[EASING_DIRECTION_OUT]

if(UPDATE_TIMER <= 0) then
	UPDATE_TIMER = 0
end

Title.text = "FASTEST TIMES"
--[[if(LEADERBOARD_STAT == "RESOURCE") then
	local resourceName = string.upper(RESOURCE_NAME)
	if(resourceName == "HIGHSCORE") then
		resourceName = "FASTEST TIME"
	end

	Title.text = string.format("%s %s %s", LEADERBOARD_TYPE, LEADERBOARD_PERSISTENCE, resourceName)
else
	Title.text = string.format("%s %s %s", LEADERBOARD_TYPE, LEADERBOARD_PERSISTENCE, LEADERBOARD_STAT)
end]]

if(EASE_TOGGLE) then
	if(EASE_BEGINNING == "UP") then
		LeaderboardPanel.y = -1500
	elseif(EASE_BEGINNING == "DOWN") then
		LeaderboardPanel.y = 1500
	elseif(EASE_BEGINNING == "LEFT") then
		LeaderboardPanel.x = -1500
	elseif(EASE_BEGINNING == "RIGHT") then
		LeaderboardPanel.x = 1500
	end
end

while(not Leaderboards.HasLeaderboards()) do
	Task.Wait()
end
Task.Wait()
Update()
�����вߍMusicZ��local MusicFolder = script:GetCustomProperty("Music"):WaitForObject()
local StagesFolder = script:GetCustomProperty("Stages"):WaitForObject()

local LocalPlayer = Game.GetLocalPlayer()

local currentSong = "None"

local triggers = {}

local function playerEnteredTrigger(trigger, player)
    if(not player:IsA("Player")) then return end
    if(player ~= LocalPlayer) then return end

    local isEasy, isMedium, isHard =
        string.sub(trigger.parent.name, 1, 4)  == "Easy",
        string.sub(trigger.parent.name, 1, 6)  == "Medium",
        string.sub(trigger.parent.name, 1, 4)  == "Hard"
    
    if((not isEasy) and (not isMedium) and (not isHard)) then return end
    
    if(isEasy and (currentSong == "Easy")) then return end
    if(isMedium and (currentSong == "Medium")) then return end
    if(isHard and (currentSong == "Hard")) then return end

    if(isEasy) then
        currentSong = "Easy"
        MusicFolder:FindChildByName(currentSong):FadeIn(1)
    elseif(isMedium) then
        currentSong = "Medium"
        MusicFolder:FindChildByName(currentSong):FadeIn(1)
    elseif(isHard) then
        currentSong = "Hard"
        MusicFolder:FindChildByName(currentSong):FadeIn(1)
    end

    for _, song in pairs(MusicFolder:GetChildren()) do
        if(song.name ~= currentSong) then
            song:FadeOut(1)
        end
    end
end

local function childAdded(parent, child)
    local isEasy, isMedium, isHard =
        string.sub(child.name, 1, 4)  == "Easy",
        string.sub(child.name, 1, 6)  == "Medium",
        string.sub(child.name, 1, 4)  == "Hard"
    
    if((not isEasy) and (not isMedium) and (not isHard)) then return end

    local musicTrigger = child:FindChildByName("Music")
    if(not musicTrigger) then
        while(not musicTrigger) do
            musicTrigger = child:FindChildByName("Music")
            Task.Wait()
        end
    end

    table.insert(triggers, musicTrigger)
    musicTrigger.destroyEvent:Connect(function()
        for index, trigger in pairs(triggers) do
            if(trigger == musicTrigger) then
                table.remove(triggers, index)
            end
        end
    end)
end

function Tick()
    local activeTrigger, activeType = nil, 0
    for _, trigger in pairs(triggers) do
        if(trigger:IsOverlapping(LocalPlayer)) then
            local isEasy, isMedium, isHard =
                string.sub(trigger.parent.name, 1, 4)  == "Easy",
                string.sub(trigger.parent.name, 1, 6)  == "Medium",
                string.sub(trigger.parent.name, 1, 4)  == "Hard"
            
            local difficulty = (isEasy and 1) or (isMedium and 2) or (isHard and 3)

            if(activeType) then
                if(difficulty > activeType) then
                    activeTrigger = trigger
                    activeType = difficulty
                end
            else
                activeTrigger = trigger
                activeType = difficulty
            end
        end
    end
    if(not activeTrigger) then return end

    playerEnteredTrigger(activeTrigger, LocalPlayer)
end

StagesFolder.childAddedEvent:Connect(childAdded)
for _, child in pairs(StagesFolder:GetChildren()) do
    childAdded(StagesFolder, child)
end
�����������Medium3b��
�� ���������*����������Medium3"  �?  �?  �?(���δ2C������� �܎��ƚ�0�ɔ�����������ޟ�����������톳���x�������ΩZ#
!
cs:Color�  �?��&?=ˎ>%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*�������� Music"
 �;D   HB  HB  pA(���������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*��܎��ƚ�0Top"
 ��D   HB  HB  �?(���������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z
mc:ecollisionsetting:forceoff� 
mc:evisibilitysetting:forceoff�
��������08�
 *��ɔ�����
Checkpoint"

 0�  �B    @33�A   @(���������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*�������ޟTransitionPlatform"

 0� `�D    @33�A   ?(���������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����������KillTriggers"
  ��   �?  �?  �?(���������2������;�ϾƄ�����ę��އ���ƴ��ƾ����̎����n��ץ���f�Ҽ���ʋH���������媚�����fǅ���������阇������������������D�݈�����w��ؾ�����z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*������;Kill"$
   � �Z�  �B    @�r @  �>(���������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��ϾƄ����Kill"$
   � ���  �B    @�r @  �>(���������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��ę��އ��Kill"$
 @�� �"�  �B    @   @  �>(���������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��ƴ��ƾ��Kill"$
 @�� �"�  �B    @   @  �>(���������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���̎����nKill"$
 @�� ���  �B    @�r @  �>(���������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���ץ���fKill"$
 @�� �Z�  �B    @�r @  �>(���������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��Ҽ���ʋHKill"$
 �T� �Z�  �B    @�r @  �>(���������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����������Kill"$
 @�� ���  �B    @�r @  �>(���������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�媚�����fKill"$
 @�� �"�  �B    @   @  �>(���������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�ǅ������Kill"$
 �"� �"�  �B    @   @  �>(���������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����阇���Kill"$
 �T� ���  �B    @�r @  �>(���������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��������Kill"$
 @�� �Z�  �B    @�r @  �>(���������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���������DKill"$
  �� ���  �B    @�r @  �>(���������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��݈�����wKill"$
  �� �Z�  �B    @�r @  �>(���������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���ؾ�����Kill"$
  z� �"�  �B    @   @  �>(���������ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���톳���xWalls"
 �;D   �?  �?  �?(���������2N�����������ɢۑ�����ʬ���w�������������箴�p�赂���֨���тŉ�������摥�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*����������Wall"
  �   �?  �A  pA(��톳���xZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���ɢۑ��Wall"
  E   �?  �A  pA(��톳���xZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����ʬ���wWall"
  E   �A  �?  pA(��톳���xZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����������Wall"
  �   �A  �?  pA(��톳���xZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����箴�pWall"$

0���0�����3B  �?  �A  pA(��톳���xZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��赂���֨Wall"$

(���0��D��3B  �A  �?  pA(��톳���xZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����тŉ��Wall")
���D0��D p�>��3B  �?  �A  pA(��톳���xZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *������摥�Wall"$

(��D0�����3B  �A  �?  pA(��톳���xZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��������Ω	Obstacles"
  ��   �?  �?  �?(���������2������ۤE���̕�����Ūủ��݌��Ҟ��������跇ȴ�����������ن��͛������Ƨ��Ѵ����˙���ؘ���Ö�����㩄ߑ�Z뜔��ݟ�h�����ﻱ�������������نȕ�n��Ҍ�����������ℊѡ҃�������ѿ��������΋����˯�Ѽt�얪�Į�=��������������й$�������M������,����で�(���̂�����������$���������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�	Obstacles*������ۤEPlatform"$
 ��� �"�   B   �A  �@   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����̕���Platform"$
  4B  u�  �B    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���Ūủ��Platform"$
 ��C  ��  �B    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�݌��Ҟ���Platform"$
 @ID @��  %C    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *������跇Platform"$
 ��D ���  WC    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�ȴ�����Platform"$
 ��D �����C    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�������ن�Platform"$
 ��D �;���C    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��͛�����Platform"$
 ��D  ����C    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��Ƨ��Ѵ��Platform"$
  �D  H���C    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���˙���ؘPlatform"$
 ��D  �C ��C    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����Ö���Platform"$
  �D �"D� D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���㩄ߑ�ZPlatform"$
 ��D �mD @D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�뜔��ݟ�hPlatform"$
 �mD @�D �D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *������ﻱ�Platform"$
 �TD �"D @&D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����������Platform"$
  /D  �C �2D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����نȕ�nPlatform"$
  �C  zC @?D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���Ҍ�����Platform"$
  HB �"D �KD    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�������ℊPlatform"$
  �� �mD @XD    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�ѡ҃����Platform"$
  �� ��D �dD    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����ѿ����Platform"$
 �"�  �D @qD    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����΋�Platform"$
  z� @�D �}D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����˯�ѼtPlatform"$
  z�  zD  �D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��얪�Į�=Platform"$
  H� �	D `�D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���������Platform"$
  z�  C ��D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�������й$Platform"$
  ��  �C ��D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��������MPlatform"$
 @�� �;D  �D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�������,Platform"$
 @�� ��D `�D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����で�(Platform"$
 ���  �D ��D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����̂���Platform"$
 @�� ��D �D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���������$Platform"$
  �� �TD  �D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����������Platform"$
  �� �	D `�D    @   @   ?(�������ΩZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�  �?��&?=ˎ>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 
NoneNone
�
��ɷ޺���
Course EndZ�
�
local trigger = script.parent
local coursenum = script:GetCustomProperty("coursenum")

function OnBeginOverlap(whichTrigger, other)
	if other:IsA("Player") then
		print(whichTrigger.name .. ": Begin Trigger Overlap with " .. other.name)
	end
end

function OnEndOverlap(whichTrigger, other)
	if other:IsA("Player") then
		print(whichTrigger.name .. ": End Trigger Overlap with " .. other.name)
	end
end

function OnInteracted(whichTrigger, other)
	if other:IsA("Player") then
		print(whichTrigger.name .. ": Trigger Interacted " .. other.name)
        Events.BroadcastToPlayer(other,"endcourse", coursenum)
    
		
	end
end

function endcourse(player, coursenum, totalseconds, milseconds)
	coursename = tostring(coursenum)
	local preseconds = player:GetResource(coursename)
	if preseconds == 0 then
		preseconds = 9999999
		print "a"
	end	
	print (preseconds)	
	if preseconds >= totalseconds then 
		coursenamemil = string.format(coursename .. "mil")
		print "b"
    	print (coursenamemil)
    	player:SetResource(coursename, totalseconds)
    	player:SetResource(coursenamemil, milseconds)
	end
end    

Events.ConnectForPlayer("endcourseserver", endcourse)
trigger.beginOverlapEvent:Connect(OnBeginOverlap)
trigger.endOverlapEvent:Connect(OnEndOverlap)
trigger.interactedEvent:Connect(OnInteracted)

`�������Cone - Truncated Hollow ThickR2
StaticMeshAssetRefsm_cone_truncated_hollow_002
������Ŧ��KillTriggersZ��local Stages = script:GetCustomProperty("Stages"):WaitForObject()
local KillTriggerTemplate = script:GetCustomProperty("KillTriggerTemplate")
local KillTriggersFolder = script:GetCustomProperty("KillTriggersFolder"):WaitForObject()

local function killPlayer(trigger, player)
	if(not player:IsA("Player")) then return end
	if(player.isDead) then return end

	player:EnableRagdoll()
	Task.Wait(3)
	if Object.IsValid(player) then
		player:Die()
	end
end

local function createTrigger(parent, triggerDescendant)
	local trigger = World.SpawnAsset(KillTriggerTemplate, {
		parent = parent,
		position = triggerDescendant:GetWorldPosition(),
		scale = triggerDescendant:GetWorldScale(),
		rotation = triggerDescendant:GetWorldRotation()
	})
	trigger.name = "KillTrigger"

	trigger.beginOverlapEvent:Connect(killPlayer)

	return trigger
end

local function descendantAdded(stage)
	if(not Object.IsValid(stage)) then return end
	local killTriggers = stage:FindChildByName("KillTriggers")
	if(not Object.IsValid(killTriggers)) then return end

	local children = killTriggers:GetChildren()
	killTriggers.descendantAddedEvent:Connect(function(p, triggerDescendant)
		if(triggerDescendant.name ~= "Kill") then return end
		local trigger = createTrigger(KillTriggersFolder, triggerDescendant)
		triggerDescendant.destroyEvent:Connect(function()
			trigger:Destroy()
		end)
	end)
	for _, child in pairs(children) do
		if(child.name == "Kill") then
			local trigger = createTrigger(KillTriggersFolder, child)
			child.destroyEvent:Connect(function()
				trigger:Destroy()
			end)
		end
	end
end

Events.Connect("UpdateKillStages", descendantAdded)
�����鷟�{DebugZ��-- local LocalPlayer = Game.GetLocalPlayer()
-- if(LocalPlayer.name ~= "NicholasForeman") then return end

-- Events.Connect("Draw", function()
-- 	UI.PrintToScreen(tostring(LocalPlayer:GetResource("HighScore")))
-- end)
�ً�Ѻ���v
ShopServerZ��local ShopData = require(script:GetCustomProperty("ShopData"))

local function getModifier(modifierName)
	for _, modifier in pairs(ShopData.Modifiers) do
		if(modifier.name == modifierName) then
			return modifier
		end
	end
end

local function getTrail(trailId)
	for _, trail in pairs(ShopData.Trails) do
		if(trail.id == trailId) then
			return trail
		end
	end
end

local function purchaseModifier(player, modifierName)
	local modifier = getModifier(modifierName)
	if(not modifier) then return end

	local playerData = Storage.GetPlayerData(player)
	if not playerData.coins then return end
	if(playerData.coins < modifier.price) then return end

	local success = modifier.func(player)
	if(not success) then return end

	playerData.coins = playerData.coins - modifier.price
	player:SetResource("Coins", playerData.coins)
	Storage.SetPlayerData(player, playerData)
end

local function purchaseTrail(player, trailId)
	local trail = getTrail(trailId)
	if(not trail) then return end

	local playerData = Storage.GetPlayerData(player)
	if(playerData.coins < trail.price) then return end

	if(not playerData.trails) then
		playerData.trails = {}
	end

	for _, trailid in pairs(playerData.trails) do
		if(trailid == trailId) then return end
	end
	table.insert(playerData.trails, trailId)

	playerData.coins = playerData.coins - trail.price
	player:SetResource("Coins", playerData.coins)
	Storage.SetPlayerData(player, playerData)

	Events.Broadcast("EquipTrail", player, trailId)
	Events.BroadcastToPlayer(player, "SetTrails", playerData.trails)
end

Events.ConnectForPlayer("PurchaseModifier", purchaseModifier)
Events.ConnectForPlayer("PurchaseTrail", purchaseTrail)
�4������uModified Spectator Camerab�4
�4 ��������`*�
��������`Spectator Camera"  �?  �?  �?(�����B2��Ï���ȁ�����ۑ�3�̍���ǔ�Z�

cs:SpectatorTeamX 

cs:WaitTimeAfterDeathe   @
$
cs:ShowCursorBindingjability_feet
,
cs:PreviousPlayerBindingjability_extra_20
(
cs:NextPlayerBindingjability_extra_22
0
cs:ButtonUnhoveredColor�  �?  �?  �?%  �?
.
cs:ButtonHoveredColor�   ?   ?   ?%  �?
.
cs:ButtonPressedColor�  �>  �>  �>%  �?
�
cs:SpectatorTeam:tooltipj�The team players will be assigned to when they die. Set to 0 if you don't want the player to be assigned a team when they die; the spectator camera will still work
�
cs:WaitTimeAfterDeath:tooltipjeThe amount of time the player will see their ragdolled character before switching to spectator camera
i
cs:ShowCursorBinding:tooltipjIThe binding players can press to see their cursor to interact with the UI
]
cs:ButtonUnhoveredColor:tooltipj:The color that will be shown for the previous/next buttons
q
cs:ButtonHoveredColor:tooltipjPThe color that will be shown for the previous/next buttons when they are hovered
}
cs:ButtonPressedColor:tooltipj\The color that will be shown for the previous/next buttons when the mouse is pressed on themz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�Spectator Camera*���Ï���ȁREADME"
    �?  �?  �?(��������`z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
���轱���*������ۑ�3ServerContext"
    �?  �?  �?(��������`2	�����ר�zz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*������ר�zSpectatorCameraServer"
    �?  �?  �?(�����ۑ�3Z

cs:Root�
��������`z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�

������߱P*��̍���ǔ�ClientContext"
    �?  �?  �?(��������`2򽔡��Կ��኷��������ɭ��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent� *�򽔡��Կ�SpectatorCameraClient"
    �?  �?  �?(�̍���ǔ�Z�

	cs:Camera��኷�����

cs:SpectatorUI����ɭ��
!
cs:SpectatingName����������
 
cs:PreviousImage��������
!
cs:PreviousButton����𐵠��

cs:NextImage�
����ƫ��]

cs:NextButton���θ��ô

cs:Root�
��������`z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
�ꕓ��Ц�*��኷�����SpectatorCamera"
  �C   �?  �?  �?(�̍���ǔ�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�L%  �C(5  C=  �DB J ]  �Be  �Dz
mc:erotationmode:default�  �  �B�*����ɭ��SpectatorUI"
    �?  �?  �?(�̍���ǔ�2
�������z(
&mc:ecollisionsetting:inheritfromparent� 
mc:evisibilitysetting:forceoff�Y:

mc:euianchor:middlecenter� �4


mc:euianchor:topleft

mc:euianchor:topleft*��������CurrentlySpectating"
    �?  �?  �?(���ɭ��2㝜���Һ������������ƫ��]z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�m�}-   �:

mc:euianchor:middlecenter� �>


mc:euianchor:bottomcenter

mc:euianchor:bottomcenter*�㝜���Һ�	Nameplate"
    �?  �?  �?(�������2𬩛�̇�8���������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent������������:

mc:euianchor:middlecenterHX�
 ʶT<ʶT<ʶT<%  �? �>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*�𬩛�̇�8Outline"
    �?  �?  �?(㝜���Һ�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��:

mc:euianchor:middlecenterHPX�
 ʶT<ʶT<ʶT<%��L? �>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*����������
PlayerName"
    �?  �?  �?(㝜���Һ�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��������������������-   �:

mc:euianchor:middlecenterHPX�A
Player Name  �?  �?  �?%  �?*"
mc:etextjustify:center0�>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*��������Previous"
    �?  �?  �?(�������2�������ů��Ǩ܂�ۍ���𐵠��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent������������:

mc:euianchor:middlecenterHX�
   �?  �?  �?%  �? �:


mc:euianchor:middleleft

mc:euianchor:middleleft*��������ůOutline"
    �?  �?  �?(�������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��:

mc:euianchor:middlecenterHPX�
 ʶT<ʶT<ʶT<%��L? �>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*���Ǩ܂�ۍText"
    �?  �?  �?(�������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��������������������-  ��:

mc:euianchor:middlecenterHPX�5
Q  �?  �?  �?%  �?d"
mc:etextjustify:center�>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*����𐵠��Button"
    �?  �?  �?(�������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��:

mc:euianchor:middlecenterPX�]%  �?"  �?  �?  �?*  �?  �?  �?2  �?  �?  �?:  �?  �?  �?B
��������HP�>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*�����ƫ��]Next"
    �?  �?  �?(�������2���Ŋ�����̩�����θ��ôz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent������������:

mc:euianchor:middlecenterHX�
   �?  �?  �?%  �? �<


mc:euianchor:middleright

mc:euianchor:middleright*����Ŋ���Outline"
    �?  �?  �?(����ƫ��]z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��:

mc:euianchor:middlecenterHPX�
 ʶT<ʶT<ʶT<%��L? �>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*���̩���Text"
    �?  �?  �?(����ƫ��]z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��������������������-  ��:

mc:euianchor:middlecenterHPX�5
E  �?  �?  �?%  �?d"
mc:etextjustify:center�>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*���θ��ôButton"
    �?  �?  �?(����ƫ��]z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��:

mc:euianchor:middlecenterPX�]%  �?"  �?  �?  �?*  �?  �?  �?2  �?  �?  �?:  �?  �?  �?B
��������HP�>


mc:euianchor:middlecenter

mc:euianchor:middlecenter
NoneNone
����鏙��uInterface Leaderboard Entryb�
� ����ʶ��*�����ʶ��Interface Leaderboard Entry"  �?  �?  �?(���������21������ݿ��΂����������k����֢����׶��̹��ZK

cs:Rank�������ݿ�

cs:Name�
����k

cs:Score��׶��̹��pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�j2:

mc:euianchor:middlecenterHP�
 %���> �4


mc:euianchor:topleft

mc:euianchor:topleft*�������ݿ�Position"
    �?  �?  �?(����ʶ��pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��(%  pA:

mc:euianchor:middlecenterHX�6
00�H?n{3?C?%  �?"
mc:etextjustify:center�:


mc:euianchor:middleleft

mc:euianchor:middleleft*��΂������	Seperator"
    �?  �?  �?(����ʶ��pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��%  �B:

mc:euianchor:middlecenterX�
   �?  �?  �?%  �? �:


mc:euianchor:middleleft

mc:euianchor:middleleft*�����kUsername"
    �?  �?  �?(����ʶ��pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�����������%  �B:

mc:euianchor:middlecenterHPX�R
LONGNAMEWITHINTHIRTYCHARACTERS  �?  �?  �?%  �?"
mc:etextjustify:left0�:


mc:euianchor:middleleft

mc:euianchor:middleleft*�����֢���	Seperator"
    �?  �?  �?(����ʶ��pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��%  k�:

mc:euianchor:middlecenterX�
   �?  �?  �?%  �? �<


mc:euianchor:middleright

mc:euianchor:middleright*��׶��̹��Score"
    �?  �?  �?(����ʶ��pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent���%  ��:

mc:euianchor:middlecenterHX�6
000.0Mn�>  �?%  �?"
mc:etextjustify:right0�<


mc:euianchor:middleright

mc:euianchor:middleright
NoneNone
���џ��q
PlayerListZ��local GameScript = script:GetCustomProperty("Game"):WaitForObject()
local PlayersFrame = script:GetCustomProperty("Players"):WaitForObject()
local PlayerEditorFrame = script:GetCustomProperty("PlayerEditor"):WaitForObject()
local PlayerListPlayerTemplate = script:GetCustomProperty("PlayerListPlayerTemplate")
local PrefixTags = require(script:GetCustomProperty("PrefixTags"))

local LocalPlayer = Game.GetLocalPlayer()

local players = Game.GetPlayers()

local localPlayerPrefix = PrefixTags:GetPlayerPrefix(LocalPlayer)
local isModerator = (localPlayerPrefix and localPlayerPrefix.isModerator) or false

local function GetTime(delta)
	delta = tonumber(delta)

	if delta <= 0 then
		return 0, 0, 0
	else
		local minutes = math.floor(delta / 60)
		local seconds = math.floor(delta - (minutes * 60))
		local milliseconds = math.floor(math.ceil((delta - (minutes * 60) - seconds) * 10000) / 10)

		return minutes, seconds, milliseconds
	end
end

local function GetFormattedTime(delta)
	local minutes, seconds, milliseconds = GetTime(delta)

	return string.format("%002i:%002i.%003i", tostring(minutes), tostring(seconds), tostring(milliseconds))
end

local currentlyEditing = ""
local function showPlayerEditor(button)
	local playerFrame = button.parent

	if(playerFrame.name == currentlyEditing) then
		PlayerEditorFrame.visibility = Visibility.FORCE_OFF
		currentlyEditing = ""
		return
	end

	PlayerEditorFrame.visibility = Visibility.FORCE_ON
	currentlyEditing = playerFrame.name
	PlayerEditorFrame.y = 52 + playerFrame.y
end

local function editPlayer(button)
	if(currentlyEditing == "") then return end
	local playerFrame = button.parent

	Events.BroadcastToServer("EditPlayer", playerFrame.name, currentlyEditing)
end

local function refreshPlayerList()
	for _, frame in pairs(PlayersFrame:GetChildren()) do
		frame:Destroy()
	end

	for index, player in pairs(players) do
		local highScore = player:GetResource("HighScore")

		local playerFrame = World.SpawnAsset(PlayerListPlayerTemplate, {parent = PlayersFrame})

		local playerNameText, playerIconImage, playerFastestTimeText = 
			playerFrame:FindChildByName("Name"),
			playerFrame:FindChildByName("Icon"),
			playerFrame:FindChildByName("FastestTime")

		playerFrame.name = player.name
		playerNameText.text = player.name
		playerIconImage:SetImage(player)

		local playerPrefix = PrefixTags:GetPlayerPrefix(player)
		if(playerPrefix) then
			playerNameText:SetColor(playerPrefix.color)
		end

		if(highScore <= 0) then
			highScore = GameScript:GetCustomProperty("DefaultTime") * 1000
		end

		playerFastestTimeText.text = GetFormattedTime(highScore / 1000)

		if(isModerator) then
			local playerButton = playerFrame:FindChildByName("Button")
			playerButton.clickedEvent:Connect(showPlayerEditor)
		end
	end
end

local function playerJoined(player)
	players = Game.GetPlayers()

	player.resourceChangedEvent:Connect(function(p, name, newAmount)
		if(name ~= "HighScore") then return end
		refreshPlayerList()
	end)
	refreshPlayerList()
end

local function playerLeft(player)
	for index, otherPlayer in pairs(players) do
		if(player.name == otherPlayer.name) then
			table.remove(players, index)
		end
	end

	if(player.name == currentlyEditing) then
		PlayerEditorFrame.visibility = Visibility.FORCE_OFF
		currentlyEditing = ""
	end

	refreshPlayerList()
end

Game.playerJoinedEvent:Connect(playerJoined)
Game.playerLeftEvent:Connect(playerLeft)
Events.Connect("Message", refreshPlayerList)

if(not isModerator) then return end

for _, frame in pairs(PlayerEditorFrame:GetChildren()) do
	local button = frame:FindChildByName("Button")
	button.clickedEvent:Connect(editPlayer)
end
��ê���ÎoRotatingKillTriggersZ��local KillTriggerTemplate = script:GetCustomProperty("KillTriggerTemplate")
local RotatingTriggersGroupTemplate = script:GetCustomProperty("RotatingTriggersGroupTemplate")

local function killPlayer(trigger, player)
	if(not player:IsA("Player")) then return end
	if(player.isDead) then return end

	player:EnableRagdoll()
	Task.Wait(3)
	player:Die()
end

local function createTrigger(parent, triggerDescendant)
	local trigger = World.SpawnAsset(KillTriggerTemplate, {
		parent = parent,
		position = triggerDescendant:GetPosition(),
		scale = triggerDescendant:GetScale(),
		rotation = triggerDescendant:GetRotation()
	})
	trigger.name = "RotatingKillTrigger"

	local c_b = trigger.beginOverlapEvent:Connect(killPlayer)

	local c
	c = trigger.destroyEvent:Connect(function()
		c_b:Disconnect()
		c:Disconnect()
	end)
end

local function descendantAdded(stage)
	if(not Object.IsValid(stage)) then return end
	local rotatingKillTriggers = stage:FindChildByName("RotatingKillTriggers")
	if(not Object.IsValid(rotatingKillTriggers)) then return end

	Task.Wait(1)

	local group = World.SpawnAsset(RotatingTriggersGroupTemplate, {
		parent = rotatingKillTriggers,
		--position = rotatingKillTriggers:GetWorldPosition(),
		--rotation = rotatingKillTriggers:GetWorldRotation()
	})
	group.name = "Group"

	local children = rotatingKillTriggers:GetChildren()
	rotatingKillTriggers.descendantAddedEvent:Connect(function(p, triggerDescendant)
		if(triggerDescendant.name ~= "RotateKill") then return end
		createTrigger(group, triggerDescendant)
	end)
	for _, child in pairs(children) do
		if(child.name == "RotateKill") then
			createTrigger(group, child)
		end
	end

	--[[rotatingKillTriggers.destroyEvent:Connect(function()
		group:Destroy()
	end)]]

	rotatingKillTriggers:RotateContinuous(Rotation.New(0, 0, -180), 0.05, false)
end

Events.Connect("UpdateKillStages", descendantAdded)
��������nHelpful Functionsbe
U 骭�����*H骭�����TemplateBundleDummy"
    �?  �?  �?�Z

������ʷ

NoneNone��
 899989a202d343b69837232b04791066 f9df3457225741c89209f6d484d0eba8NicholasForeman"1.2.0*�Includes two very useful functions relating to the world:

funciton Module:FindPlayerByName(playerName)
function Module:WaitForChild(parent, childName, timeout)
function Module:GetDescendants(parent)
�������ʷ
HelpfulFunctionsZ��local Module = {}

function Module:FindPlayerByName(playerName)
    for _, player in pairs(Game.GetPlayers()) do
        if(player.name == playerName) then
            return player
        end
    end
end

function Module:WaitForChild(parent, childName, timeout)
    assert(Object.IsValid(parent), "Parent is not a valid Object")

    local child, connection
    connection = parent.childAddedEvent:Connect(function(_, newChild)
        if(newChild.name ~= childName) then return end

        child = newChild
        connection:Disconnect()
    end)

    child = parent:FindChildByName(childName)
    if(child) then
        connection:Disconnect()
        return child
    end

    local startTime = time()
    local runTime = 0
    if(not timeout) then
        timeout = 60
    end

    while(not child) do
        Task.Wait()
        runTime = time() - startTime

        if(runTime > timeout) then connection:Disconnect() return end
    end

    return child
end

local function scanParent(parent, descendants)
    for _, child in pairs(parent:GetChildren()) do
        table.insert(descendants, child)
        descendants = scanParent(child, descendants)
    end

    return descendants
end

function Module:GetDescendants(parent)
    assert(Object.IsValid(parent), "Parent is not a valid Object")

    return scanParent(parent, {})
end

return Module��*�Includes two very useful functions relating to the world:

function Module:WaitForChild(parent, childName, timeout)
function Module:GetDescendants(parent)�
8�����ƺmSky DomeR 
BlueprintAssetRefCORESKY_Sky
���������lFluidUIb�
� �����â��*������â��FluidUI"  �?  �?  �?(�����B2����������ث���hZ z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent� *��������Fluid UI Demo"
    �?  �?  �?(�����â��2ِ��������ץ�̠��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent� *�ِ������TestUI"
    �?  �?  �?(�������Z7

cs:Grid���Û�����

cs:GridChild��ﳘ�����z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�

����ʮ�*���ץ�̠��	Container"
    �?  �?  �?(�������2	������ؿCz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�Y:

mc:euianchor:middlecenter� �4


mc:euianchor:topleft

mc:euianchor:topleft*�������ؿCContent"
    �?  �?  �?(��ץ�̠��2ƚ��̇��!��Û�����簢������ZP

cs:Size�
  �C%  �C

cs:AspectRatioeff�?

cs:AspectRatioYAxisDominantPz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�t��:

mc:euianchor:middlecenter�
 %S�~? �>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*�ƚ��̇��!List"
    �?  �?  �?(������ؿCZd
 
cs:Size�  �?  �?  ��%  ��

cs:ListSize����=


cs:ListGapX

cs:ListFillHorizontalP z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�i��:

mc:euianchor:middlecenter� �>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*���Û�����Grid"
    �?  �?  �?(������ؿCZ�
 
cs:Size�  �?  �?  ��%  ��

cs:Position�   @

cs:GridCount�
  �@  �@


cs:GridGap�
   A   A

cs:GridPadding�  �A

cs:GridFillVerticalP z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�i��:

mc:euianchor:middlecenter� �>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*�簢������TestText"
    �?  �?  �?(������ؿCZ

cs:Size�  �?  �>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent���(:

mc:euianchor:middlecenter�:
Text  �?  �?  �?%  �?"
mc:etextjustify:center(�>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*����ث���hScripts"
    �?  �?  �?(�����â��2	��ۼ����nz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent� *���ۼ����nFluidUI"
    �?  �?  �?(���ث���hZ$
"
cs:HelpfulFunctions�
������ʷ
z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�

��Ý���(
NoneNone��*�FluidUI, created by Nicholas Foreman (nforeman)
Thumbnail created by John Shoff (FearTheDev)

FluidUI is a responsive User Interface Framework that allows you to design your interface dynamically without having to worry about the screen resolution of the users playing your games. With many powerful features such as screen-size scaling, grids/lists, and aspect ratios, you will have nearly full control over the presentation of your game.

Getting the framework to work itself is simple. You only need one instance of this script inside of of a ClientContext. Any additional copies of this script will conflict with each other and you will not get the intended goal.

Within the FluidUI.lua script is some very important documentation on how to utilize the system.�
�S��Ý���(FluidUIZ�S�S-- FluidUI.lua
-- Dynamic UI: Scaling, Positioning, Max Size, Aspect Ratio, GridLayout, ListLayout
-- Scripted by Nicholas Foreman (nforeman)
-- Logo contributed by John Shoff (FearTheDev)

--[[

        Hello! Nicholas Foreman here. First of all, I want to say thank you for looking into this content! I
    really appreciate it. This was a project I really wanted to work on for Core as it's something I believe
    EVERYONE could use.

        FluidUI is a responsive User Interface Framework that allows you to design your interface
    dynamically without having to worry about the screen resolution of the users playing your games. With
    many powerful features such as screen-size scaling, grids/lists, and aspect ratios, you will have nearly
    full control over the presentation of your game.

        Getting the framework to work itself is simple. You only need one instance of this script inside of
    of a ClientContext. Any additional copies of this script will conflict with each other and you will not
    get the intended goal.

        However, utilizing the script is slightly more complicated. Each "component" utilizes Custom
    Properties that you insert into each UIComponent (ex. UITextBox). The datatypes are as follows:



    Vector4 Position: Overrides position on the screen
        X: Scale on the X Axis (0 -> 1)
        Y: Scale on the Y Axis (0 -> 1)
        Z: Pixels on the X Axis (any)
        W: Pixels on the Y Axis (any)

    Vector4 Size: Overrides size on the screen
        X: Scale on the X Axis (0 -> 1)
        Y: Scale on the Y Axis (0 -> 1)
        Z: Pixels on the X Axis (any)
        W: Pixels on the Y Axis (any)

    Vector2 MaxSize: Sets the maximum number of pixels the component can be
        X: Pixels on the X Axis
        Y: Pixels on the Y Axis

    Boolean ScaleText: If enabled and the UIComponent is a UITextBox, the text will scale with the Size property



    Float AspectRatio: Multiplier for non-dominant axis based on size of dominant axis
    Boolean AspectRatioYAxisDominant: Sets dominant axis to the Y axis instead of X axis



    Vector2 ListSize: Sets how large each component within the list is
        X: Scale on the dominant axis (0 -> 1)
        Y: Pixels on the dominant axis (any)

    Float ListGap: Pixels on the dominant axis

    Boolean ListFillHorizontal: Fills side-by-side instead of top-bottom



    Vector2 GridCount: Setting scale of grid
        X: Number of columns (side-by-side)
        Y: Number of rows (top-down)

    Vector2 GridGap: Pixels between grid members
        X: Pixels between each column
        Y: Pixels between each row

    Vector4 GridPadding: Additional pixels along the edges of the grid
        X: Pixels to the left
        Y: Pixels to the top
        Z: Pixels to the right

        W: Pixels to the bottom
    Boolean GridFillVertical: Fills top-down instead of side-to-side
--]]

--[[
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    BE CAREFUL WHEN EDITTING BELOW
    //////////////////////////////

    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    BE CAREFUL WHEN EDITTING BELOW
    //////////////////////////////

    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    BE CAREFUL WHEN EDITTING BELOW
    //////////////////////////////

    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    BE CAREFUL WHEN EDITTING BELOW
    //////////////////////////////

    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    BE CAREFUL WHEN EDITTING BELOW
    //////////////////////////////

    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    BE CAREFUL WHEN EDITTING BELOW
    //////////////////////////////

    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    BE CAREFUL WHEN EDITTING BELOW
    //////////////////////////////
--]]

local HelpfulFunctions = require(script:GetCustomProperty("HelpfulFunctions"))

local worldRootObject = World.GetRootObject()

local screenSize = UI.GetScreenSize()

local function updateSize(uiControl, Size, parentSize)
    if((Size.x ~= 0) or (Size.z ~= 0)) then
        uiControl.width = math.floor(parentSize.x * Size.x) + Size.z
    end
    if((Size.y ~= 0) or (Size.w ~= 0)) then
        uiControl.height = math.floor(parentSize.y * Size.y) + Size.w
    end
end

local function updatePosition(uiControl, Position, parentSize)
    uiControl.x = math.floor(parentSize.x * Position.x) + Position.z
    uiControl.y = math.floor(parentSize.y * Position.y) + Position.w
end

local function updateMaxSize(uiControl, MaxSize)
    if((MaxSize.x ~= 0) and (uiControl.width > MaxSize.x)) then
        uiControl.width = MaxSize.x
    end

    if((MaxSize.y ~= 0) and (uiControl.height > MaxSize.y)) then
        uiControl.height = MaxSize.y
    end
end

local function updateList(uiControl, ListSize, ListGap, ListFillHorizontal, parentSize)
    local xSize, ySize
    local gridGapX, gridGapY = 0, 0

    if(ListGap) then
        if(ListFillHorizontal) then
            ySize = parentSize.y
            gridGapX = ListGap

            local totalSizeX = parentSize.x - (gridGapX * ((1 / ListSize.x) - 1))

            xSize = totalSizeX / (1 / ListSize.x)
        else
            xSize = parentSize.x
            gridGapY = ListGap

            local totalSizeY = parentSize.y - (gridGapY * ((1 / ListSize.x) - 1))

            ySize = totalSizeY / (1 / ListSize.x)
        end
    else
        if(ListFillHorizontal) then
            xSize = math.floor(parentSize.x * ListSize.x) + ListSize.y
            ySize = parentSize.y
        else
            xSize = parentSize.x
            ySize = math.floor(parentSize.y * ListSize.x) + ListSize.y
        end
    end

    for index, child in ipairs(uiControl:GetChildren()) do
        child.width = math.floor(xSize)
        child.height = math.floor(ySize)

        local row = (index - 1)

        if(ListFillHorizontal) then
            child.x = math.ceil((xSize * row) + (gridGapX * row))
        else
            child.y = math.ceil((ySize * row) + (gridGapY * row))
        end
    end
end

local function updateGrid(uiControl, GridCount, GridGap, GridPadding, GridFillVertical, parentSize)
    local columns, rows = GridCount.x, GridCount.y

    local parentSizeX = parentSize.x
    local parentSizeY = parentSize.y

    if(GridPadding) then
        parentSizeX = parentSizeX - GridPadding.x - GridPadding.z
        parentSizeY = parentSizeY - GridPadding.y - GridPadding.w
    end

    local xSize, ySize
    local gridGapX, gridGapY = 0, 0
    if(GridGap) then
        gridGapX = GridGap.x
        gridGapY = GridGap.y

        local totalSizeX = parentSizeX - (gridGapX * (columns - 1))
        local totalSizeY = parentSizeY - (gridGapY * (rows - 1))

        xSize = totalSizeX / columns
        ySize = totalSizeY / rows
    else
        xSize = parentSizeX / columns
        ySize = parentSizeY / rows
    end

    for index, child in ipairs(uiControl:GetChildren()) do
        child.width = math.floor(xSize)
        child.height = math.floor(ySize)

        local column, row
        if(GridFillVertical) then
            column = math.floor((index - 1) / columns)
            row = (index - 1) % columns
        else
            column = (index - 1) % columns
            row = math.floor((index - 1) / columns)
        end

        child.x = math.ceil((xSize * column) + (gridGapX * column))
        child.y = math.ceil((ySize * row) + (gridGapY * row))
        if(GridPadding) then
            child.x = child.x + GridPadding.x
            child.y = child.y + GridPadding.y
        end
    end
end

local function updateAspectRatio(uiControl, aspectRatio, yDominantAxis)
    if(yDominantAxis) then
        uiControl.width = math.floor(uiControl.height * aspectRatio)
    else
        uiControl.height = math.floor(uiControl.width * aspectRatio)
    end
end

local function updateText(uiControl)
    uiControl.fontSize = math.floor(uiControl.height / 2)
end

local function updateUIControl(uiControl)
    if(not uiControl:IsA("UIControl")) then return end
    if(uiControl:IsA("UIContainer")) then return end

    local parent = uiControl.parent

    local parentSize
    if((not parent:IsA("UIControl")) or parent:IsA("UIContainer")) then
        parentSize = screenSize
    else
        parentSize = Vector2.New(parent.width, parent.height)
    end

    local Position = uiControl:GetCustomProperty("Position")
    if(Position) then
        updatePosition(uiControl, Position, parentSize)
    end

    local Size = uiControl:GetCustomProperty("Size")
    if(Size) then
        updateSize(uiControl, Size, parentSize)
    end

    local MaxSize = uiControl:GetCustomProperty("MaxSize")
    if(MaxSize) then
        updateMaxSize(uiControl, MaxSize)
    end

    local AspectRatio = uiControl:GetCustomProperty("AspectRatio")
    local AspectRatioYAxisDomiant = uiControl:GetCustomProperty("AspectRatioYAxisDominant")
    if(AspectRatio) then
        updateAspectRatio(uiControl, AspectRatio, AspectRatioYAxisDomiant)
    end

    local ScaleText = uiControl:GetCustomProperty("ScaleText")
    if(ScaleText and (uiControl:IsA("UIText") or uiControl:IsA("UIButton"))) then
        updateText(uiControl)
    end

    local ListSize = uiControl:GetCustomProperty("ListSize")
    local ListGap = uiControl:GetCustomProperty("ListGap")
    local ListFillHorizontal = uiControl:GetCustomProperty("ListFillHorizontal")
    if(ListSize) then
        updateList(uiControl, ListSize, ListGap, ListFillHorizontal, Vector2.New(uiControl.width, uiControl.height))
    end

    local GridCount = uiControl:GetCustomProperty("GridCount")
    local GridGap = uiControl:GetCustomProperty("GridGap")
    local GridPadding = uiControl:GetCustomProperty("GridPadding")
    local GridFillVertical = uiControl:GetCustomProperty("GridFillVertical")
    if(GridCount) then
        updateGrid(uiControl, GridCount, GridGap, GridPadding, GridFillVertical, Vector2.New(uiControl.width, uiControl.height))
    end
end

local function scanDescendants()
    for _, descendant in pairs(HelpfulFunctions:GetDescendants(worldRootObject)) do
        updateUIControl(descendant)
    end
end

local function descendantAdded(ancestor, descendant)
    updateUIControl(descendant)
    updateUIControl(descendant.parent)
end

function Tick(deltaTime)
    local newScreenSize = UI.GetScreenSize()
    if(newScreenSize == screenSize) then return end
    screenSize = newScreenSize

    scanDescendants()
end

worldRootObject.descendantAddedEvent:Connect(descendantAdded)
scanDescendants()
�6����ʮ�
ShopClientZ�6�6local Content = script:GetCustomProperty("Content"):WaitForObject()
local CategoriesContainer = script:GetCustomProperty("Categories"):WaitForObject()
local CategoryContent = script:GetCustomProperty("CategoryContent"):WaitForObject()
local ToggleButton = script:GetCustomProperty("Toggle"):WaitForObject()
local GridChildTemplate = script:GetCustomProperty("GridChild")
local ShopData = require(script:GetCustomProperty("ShopData"))

local LocalPlayer = Game.GetLocalPlayer()

local activeCategory = "Modifiers"

local trails

local function changeCategory(button)
	local categoryLabel = button.parent
	activeCategory = categoryLabel.name

	for _, child in pairs(CategoryContent:GetChildren()) do
		if(child.name == categoryLabel.name) then
			child.visibility = Visibility.FORCE_ON
		else
			child.visibility = Visibility.FORCE_OFF
		end
	end

	categoryLabel:SetColor(Color.New(0.031, 0.031, 0.031, 1))
	button:SetFontColor(Color.New(1, 1, 1, 1))

	for _, otherCategoryLabel in pairs(CategoriesContainer:GetChildren()) do
		if(otherCategoryLabel.name ~= "Split") then
			if(otherCategoryLabel.name ~= categoryLabel.name) then
				local otherButton = otherCategoryLabel:FindChildByName("Button")

				otherCategoryLabel:SetColor(Color.New(1, 1, 1, 1))
				otherButton:SetFontColor(Color.New(0.031, 0.031, 0.031, 1))
			end
		end
	end
end

local function buttonHovered(button)
	local categoryLabel = button.parent
	if(categoryLabel.name == activeCategory) then return end

	categoryLabel:SetColor(Color.New(0.031 * 2, 0.031 *2, 0.031 * 2, 1))
	button:SetFontColor(Color.New(1, 1, 1, 1))
end

local function buttonUnhovered(button)
	local categoryLabel = button.parent
	if(categoryLabel.name == activeCategory) then return end

	categoryLabel:SetColor(Color.New(1, 1, 1, 1))
	button:SetFontColor(Color.New(0.031 * 2, 0.031 * 2, 0.031 * 2, 1))
end

local function hasTrail(trailId)
	for _, trail in pairs(trails) do
		if(trail == trailId) then
			return true
		end
	end

	return false
end

local function setupCategory(categoryLabel)
	local button = categoryLabel:FindChildByName("Button")
	if(not Object.IsValid(button)) then return end
	if(not button:IsA("UIButton")) then return end

	local categoryGrid = CategoryContent:FindChildByName(categoryLabel.name)
	if(not Object.IsValid(categoryGrid)) then return end

	button.hoveredEvent:Connect(buttonHovered)
	button.unhoveredEvent:Connect(buttonUnhovered)
	button.clickedEvent:Connect(changeCategory)

	for _, child in pairs(categoryGrid:GetChildren()) do
		if(child:IsA("UIImage")) then
			child:Destroy()
		end
	end

	local currentTrail = LocalPlayer:GetResource("CurrentTrail")

	if(categoryLabel.name == "Trails") then
		local none = World.SpawnAsset(GridChildTemplate, {parent = categoryGrid})
		none.name = "None"

		local buttonZ, itemNameText, itemPriceImage =
			none:FindChildByName("Button"),
			none:FindChildByName("ItemName"),
			none:FindChildByName("ItemPrice")

		itemNameText.text = "None"

		local equipped = false

		local itemPriceText = itemPriceImage:FindChildByName("Price")
		if(currentTrail == 0) then
			itemPriceText.text = "Equipped"
			itemPriceImage:SetColor(Color.New(0.01, 0.01, 0.01))
			equipped = true
		else
			itemPriceText.text = "Equip"
			itemPriceImage:SetColor(Color.New(0.072272, 0.428691, 0.06022))
		end

		buttonZ.hoveredEvent:Connect(function()
			none:SetColor(Color.New(100/255, 100/255, 100/255, 1))
		end)
		buttonZ.unhoveredEvent:Connect(function()
			none:SetColor(Color.New(1, 1, 1, 1))
		end)
		buttonZ.clickedEvent:Connect(function(buttonClicked)
			if(equipped) then return end

			Events.BroadcastToServer("EquipTrail", 0)
		end)
	end

	local categoryData = ShopData[categoryLabel.name]
	for index, item in ipairs(categoryData) do
		local child = World.SpawnAsset(GridChildTemplate, {parent = categoryGrid})
		child.name = item.name

		local buttonZ, itemNameText, itemPriceImage =
			child:FindChildByName("Button"),
			child:FindChildByName("ItemName"),
			child:FindChildByName("ItemPrice")

		itemNameText.text = item.name

		local doesHaveTrail = ((categoryLabel.name == "Trails") and hasTrail(item.id)) or false

		local equipped = false

		local itemPriceText = itemPriceImage:FindChildByName("Price")
		if(categoryLabel.name == "Modifiers") then
			itemPriceText.text = string.format("%s Coins", item.price)
		elseif(item.id == currentTrail) then
			itemPriceText.text = "Equipped"
			itemPriceImage:SetColor(Color.New(0.01, 0.01, 0.01))
			equipped = true
		elseif(doesHaveTrail) then
			itemPriceText.text = "Equip"
			itemPriceImage:SetColor(Color.New(0.072272, 0.428691, 0.06022))
		else
			itemPriceText.text = string.format("%s Coins", item.price)
		end

		buttonZ.hoveredEvent:Connect(function()
			child:SetColor(Color.New(100/255, 100/255, 100/255, 1))
		end)
		buttonZ.unhoveredEvent:Connect(function()
			child:SetColor(Color.New(1, 1, 1, 1))
		end)
		buttonZ.clickedEvent:Connect(function(buttonClicked)
			if(categoryLabel.name == "Modifiers") then
				Events.BroadcastToServer("PurchaseModifier", item.name)
			elseif(categoryLabel.name == "Trails") then
				if(doesHaveTrail) then
					if(not equipped) then
						Events.BroadcastToServer("EquipTrail", item.id)
					end
				else
					Events.BroadcastToServer("PurchaseTrail", item.id)
				end
			end
		end)
	end
end

local function toggleShop()
	local camera = LocalPlayer:GetActiveCamera()

	if(Content.visibility == Visibility.FORCE_ON) then
		Content.visibility = Visibility.FORCE_OFF
		UI.SetCursorVisible(false)
		UI.SetCanCursorInteractWithUI(false)

		camera.followPlayer = LocalPlayer
		camera.rotationMode = RotationMode.LOOK_ANGLE
		camera.isDistanceAdjustable = true
	elseif(Content.visibility == Visibility.FORCE_OFF) then
		Content.visibility = Visibility.FORCE_ON
		UI.SetCursorVisible(true)
		UI.SetCanCursorInteractWithUI(true)

		camera.followPlayer = nil
		camera.rotationMode = RotationMode.CAMERA
		camera.isDistanceAdjustable = false
	end
end

local function generateShop()
	for _, categoryLabel in pairs(CategoriesContainer:GetChildren()) do
		if(categoryLabel.name ~= "Split") then
			setupCategory(categoryLabel)
		end
	end
end

local function setTrails(newTrails)
	trails = newTrails
	generateShop()
end

local function updateShop(player, resourceName, resourceValue)
	if(resourceName ~= "CurrentTrail") then return end

	generateShop()
end

Events.Connect("SetTrails", setTrails)

ToggleButton.clickedEvent:Connect(toggleShop)
LocalPlayer.bindingReleasedEvent:Connect(function(player, binding)
	if(binding ~= "ability_extra_40") then return end

	toggleShop()
end)
LocalPlayer.resourceChangedEvent:Connect(updateShop)

while(not trails) do
	Events.BroadcastToServer("GetTrails")
	Task.Wait(1)
end
���������hRotatingTriggersGroupTemplateb�
� ���������*����������RotatingTriggersGroupTemplate"  �?  �?  �?(�����Bpz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
NoneNone
����麅hTabZ��local PrefixTags = require(script:GetCustomProperty("PrefixTags"))

local LocalPlayer = Game.GetLocalPlayer()

local tabKeyBinding = "ability_extra_19"

local function tab(player, binding)
    if(player ~= LocalPlayer) then return end
    if(binding ~= tabKeyBinding) then return end

    local playerPrefix = PrefixTags:GetPlayerPrefix(player)
    if(not playerPrefix) then return end

    if(not playerPrefix.isModerator) then return end

    local camera = LocalPlayer:GetActiveCamera()
    if(UI.IsCursorVisible()) then
        UI.SetCursorVisible(false)
        UI.SetCanCursorInteractWithUI(false)

        --[[camera.rotationMode = RotationMode.CAMERA
        camera.isDistanceAdjustable = true
        camera.hasFreeControl = true]]
    else
        UI.SetCursorVisible(true)
        UI.SetCanCursorInteractWithUI(true)

        --[[camera.rotationMode = RotationMode.LOOK_ANGLE
        camera.isDistanceAdjustable = false
        camera.hasFreeControl = false]]
    end
end

LocalPlayer.bindingReleasedEvent:Connect(tab)
���ˣ����gLeaderboard Dependenciesb�
� ������ԙ:*�������ԙ:Leaderboard Dependencies"  �?  �?  �?(��Ҙѩ��J2	����οҚhz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*�����οҚhLeaderboard_DataTracker"
    �?  �?  �?(������ԙ:z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
�������
NoneNone
��������aTrail Templateb�
� ���ֿ��ݣ*����ֿ��ݣTrail Template"  �?  �?  �?(���δZH
#
bp:Particle Scale Multipliere  �@
!
bp:color�  �?  �?  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
���Ǆ��� �
NoneNone
�z������ZMedium2b�z
�y �Ҝ���ʟ�*��Ҝ���ʟ�Medium2"  �?  �?  �?(�����B2B�������������ݓ����ы̔١=�����߈نܵ������t�ȿ�����$���Ԫ����Z

cs:Color���>?�r�>%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*����������Music"
 �;D   HB  HB  pA(�Ҝ���ʟ�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*�����ݓ��Top"
 ��D   HB  HB  �?(�Ҝ���ʟ�Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z
mc:ecollisionsetting:forceoff� 
mc:evisibilitysetting:forceoff�
��������08�
 *���ы̔١=
Checkpoint"

 0�  �B    @33�A   @(�Ҝ���ʟ�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*������߈نTransitionPlatform"

 0� `�D    @33�A   ?(�Ҝ���ʟ�Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�ܵ������tKillTriggers"
  ��   �?  �?  �?(�Ҝ���ʟ�2^�܋����IҔ������3�������1��������%��潝��������������̧�����Е�ɪ�f��ޝػ��ɀ�����z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*��܋����IKill"$
 ��� �-�  �B   PA �@   ?(ܵ������tZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�Ҕ������3Kill"$
 ������  �B   �@  @   ?(ܵ������tZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��������1Kill"$
 ���Z���  �B   �@��,@   ?(ܵ������tZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���������%Kill"$
@��  u�  �B   �@  �@   ?(ܵ������tZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���潝����Kill"$
  ��  M�  �B de�@  `@   ?(ܵ������tZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��������Kill"$
@uYC  u�  �B   �@  �@��L>(ܵ������tZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����̧���Kill"$
�U�C�\��  �B   �?   A��L>(ܵ������tZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���Е�ɪ�fKill"$
�ID�\��  �B   �?   A��L>(ܵ������tZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���ޝػ�Kill"$
Z�D�\��  �B   �?   A��L>(ܵ������tZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ɀ�����Kill"$
T?�D�\��  �B   �?   A��L>(ܵ������tZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ȿ�����$Walls"
 �;D   �?  �?  �?(�Ҝ���ʟ�2M�������������̳��ڊ����׮�ɳ��C����=��ݢ�����갂���ț��Ś�й��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*����������Wall"
  �   �?  �A  pA(�ȿ�����$Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����̳�Wall"
  E   �?  �A  pA(�ȿ�����$Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��ڊ���Wall"
  E   �A  �?  pA(�ȿ�����$Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��׮�ɳ��CWall"
  �   �A  �?  pA(�ȿ�����$Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����=Wall"$

0���0�����3B  �?  �A  pA(�ȿ�����$Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���ݢ����Wall"$

(���0��D��3B  �A  �?  pA(�ȿ�����$Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��갂���țWall")
���D0��D p�>��3B  �?  �A  pA(�ȿ�����$Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���Ś�й��Wall"$

(��D0�����3B  �A  �?  pA(�ȿ�����$Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����Ԫ����	Obstacles"
  ��   �?  �?  �?(�Ҝ���ʟ�2���̻���ܒ�޼������Ӈý���p��������	�Ȏ���ѕ�����ߘ��`�����������␣©�������|�񯻳�������Ȉ������������ϔ������)ᶎ�������̣���������ӡ��ꙕ����������q킾Ĺѫ�U�ӋÍ����޷Ө�🛜����Ь�C������Ӹ�����������կն�������̶����Б�uͳ���ՠۿ�������و���ܯ�X�������pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�	Obstacles*���̻���ܒPlatform"$
 ��� ���  �A   �A   A   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��޼�����Platform"$
 �TD ���  �A   �A   A   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��Ӈý���pPlatform"$
  �D  a�  �B    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���������	Platform"$
 `E  �  �B    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��Ȏ���ѕ�Platform"$
 �E  ��  %C    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����ߘ��`Platform"$
 �E  ��  WC    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����������Platform"$
 �	E  HC��C    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���␣©��Platform"$
 `E  �C ��C    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *������|Platform"$
   E  HD ��C    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��񯻳����Platform"$
  �D  zD ��C    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����Ȉ����Platform"$
 ��D �;D ��C    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���������Platform"$
 @�D  D � D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�ϔ������)Platform"$
 @�D �TD @D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�ᶎ���Platform"$
 �;D �;D �D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����̣���Platform"$
  �C  �C��2D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�������ӡPlatform"$
  C  HC @?D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���ꙕ����Platform"$
  H�  �C �KD    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�������qPlatform"$
  � �;D @XD    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�킾Ĺѫ�UPlatform"$
  H� @�D �dD    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ӋÍ����Platform"$
  �� ��D @qD    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�޷Ө�🛜Platform"$
  � ��D �}D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����Ь�CPlatform"$
 �m� ��D  �D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�������ӸPlatform"$
  �� ��D `�D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����������Platform"$
 @��  zD ��D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���կն��Platform"$
  ��  D  �D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *������̶�Platform"$
 ��� �"D `�D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����Б�uPlatform"$
 @�� �mD ��D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�ͳ���ՠۿPlatform"$
 ��� ��D �D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��������Platform"$
 ��� �;D  �D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�و���ܯ�XPlatform"$
  ��  �C `�D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��������pPlatform"$
 �m�  /D ��D    @   @   ?(���Ԫ����Z]
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
0
ma:Shared_BaseMaterial:color���>?�r�>%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 
NoneNone
�<���䍙�ZEasy4b�<
�< ��������*���������Easy4"  �?  �?  �?(�����B29�������ܫ������̥�덟����"��մ����$�ۜ��ᬎ9����܅���Z#
!
cs:Color�g��>  �??%,?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*��������ܫMusic"
  �C   HB  HB   A(��������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*�������̥Top"
  zD   HB  HB   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?z
mc:ecollisionsetting:forceoff� 
mc:evisibilitysetting:forceoff�
��������08�
 *��덟����"
Checkpoint"

 0�  �B    @33�A   @(��������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*���մ����$TransitionPlatform"

 0� �sD    @33�A   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�g��>  �??%,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��ۜ��ᬎ9Walls"
  �C   �?  �?  �?(��������2L��������~����������υ��������π�����󱘎���ٹ�ɹ���Oʀ�������²�Ҹ��rz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*���������~Wall"
  �   �?  �A   A(�ۜ��ᬎ9Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����������Wall"
  E   �?  �A   A(�ۜ��ᬎ9Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��υ������Wall"
  E   �A  �?   A(�ۜ��ᬎ9Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���π����Wall"
 �   �A  �?   A(�ۜ��ᬎ9Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��󱘎���Wall"$

0���*�����3B  �?  �A   A(�ۜ��ᬎ9Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�ٹ�ɹ���OWall"$

,���.��D��3B  �A  �?   A(�ۜ��ᬎ9Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�ʀ������Wall"$

,��D+��D��3B  �?  �A   A(�ۜ��ᬎ9Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��²�Ҹ��rWall"$

,��D.�����3B  �A  �?   A(�ۜ��ᬎ9Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�����܅���	Obstacles"
    �?  �?  �?(��������2zޖǿ����F������ې�����Ĥ��X��񝥗��\��չ�ȗ�𻗇ɏ�r������ü_���Š��ւ��¾�p���������Ѭ��ׁ����޾֊P�ɖ������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*�ޖǿ����FPlatform"$
 ���  H�  �A   �@   ?   ?(����܅���Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�������ې�Platform")
 ���  H�  C �A  �@   ?   ?(����܅���Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����Ĥ��XPlatform")
 �	� �m���yC����  �@   ?   ?(����܅���Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���񝥗��\Platform".
  H�  ��  �C
 �A����  �@   ?   ?(����܅���Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���չ�ȗPlatform"3
  �C ���  �C�.�6���ACae6  �@   ?   ?(����܅���Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��𻗇ɏ�rPlatform"3
  zD  H�  �C�.�6��3B��6  �@   ?   ?(����܅���Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�������ü_Platform"3
 @�D  ��  �C�.�6���B�'7  �@   ?   ?(����܅���Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����Š�Platform"3
 @�D  HC  �C�.�6��C��b7  �@   ?   ?(����܅���Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ւ��¾�pPlatform"3
  D �	D �	D �A�C؏h7  �@   ?   ?(����܅���Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�������Platform")

 �;D �"D
�C2{5  �@   ?   ?(����܅���Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����Ѭ��ׁPlatform"3
  � �TD �;D �A��3C"$�6  �@   ?   ?(����܅���Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����޾֊PPlatform"3
  �� �TD  aD�.�6��3C�ܽ6  �@   ?   ?(����܅���Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ɖ������Platform"3
  �� �TD �mD�.�6��3C�ܽ6  �@   ?   ?(����܅���Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ff�>  �?X,?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 
NoneNone
�������ƁT
SnapCameraZ��local camera = script.parent
local playerSettings = script:GetCustomProperty("PlayerSettings")

local LocalPlayer = Game.GetLocalPlayer()

function Tick(deltaTime)
    if(not camera.isDistanceAdjustable) then return end

    local distance = camera.currentDistance

    if(distance <= 0) then
		--camera.useCameraSocket = true
		LocalPlayer.isVisibleToSelf = false
    else
        --camera.useCameraSocket = false
		LocalPlayer.isVisibleToSelf = true
    end
end
��х�挨�OPlayerEditorZ��local PrefixTags = require(script:GetCustomProperty("PrefixTags"))
local HelpfulFunctions = require(script:GetCustomProperty("HelpfulFunctions"))
local TeleportGameId = script:GetCustomProperty("TeleportGameId")

local fly_bind = "ability_extra_42"

local function kickPlayer(player, playerToEdit)
	local playerToEditGroup = PrefixTags:GetPlayerPrefix(playerToEdit)
	if(playerToEditGroup and playerToEditGroup.isModerator) then return end

	playerToEdit:TransferToGame("071216/land-of-bans")
	--playerToEdit:TransferToGame(TeleportGameId)
end

local function flyPlayer(player, playerToEdit)
	if(playerToEdit.isFlying) then
		playerToEdit:ActivateWalking()
	else
		playerToEdit:ActivateFlying()
	end
end

local function killPlayer(player, playerToEdit)
	if(playerToEdit.isDead) then return end

	playerToEdit:EnableRagdoll()
	Task.Wait(3)
	playerToEdit:Die()
end

local function teleportToPlayer(player, playerToEdit)
	player:SetWorldPosition(playerToEdit:GetWorldPosition())
end

local function bringPlayer(player, playerToEdit)
	playerToEdit:SetWorldPosition(player:GetWorldPosition())
end

local function editPlayer(player, editType, playerToEditName)
	local playerGroup = PrefixTags:GetPlayerPrefix(player)
	if(not playerGroup) then return end
	if(not playerGroup.isModerator) then return end

	local playerToEdit = HelpfulFunctions:FindPlayerByName(playerToEditName)

	if(editType == "Kick") then
		kickPlayer(player, playerToEdit)
	elseif(editType == "Fly") then
		flyPlayer(player, playerToEdit)
	elseif(editType == "Kill") then
		killPlayer(player, playerToEdit)
	elseif(editType == "TeleportTo") then
		teleportToPlayer(player, playerToEdit)
	elseif(editType == "Bring") then
		bringPlayer(player, playerToEdit)
	end
end

local function bindingReleased(player, binding)
	if(binding ~= fly_bind) then return end
	local playerGroup = PrefixTags:GetPlayerPrefix(player)
	if(not playerGroup) then return end
	if(not playerGroup.isModerator) then return end

	flyPlayer(player, player)
end

local function playerJoined(player)
	local playerGroup = PrefixTags:GetPlayerPrefix(player)
	if(not playerGroup) then return end
	if(not playerGroup.isModerator) then return end

	player.bindingReleasedEvent:Connect(bindingReleased)
end

Events.ConnectForPlayer("EditPlayer", editPlayer)
Game.playerJoinedEvent:Connect(playerJoined)
�����ՐǩLWorld Leaderboard Entryb�
� ��������Q*���������QWorld Leaderboard Entry"  �?  �?  �?(���������2��ð�ֹ͕ض���͢�L��و���bZJ

cs:Rank���ð�ֹ͕

cs:Name�
ض���͢�L

cs:Score�
��و���bpz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*���ð�ֹ͕Position"
  9���3Cfff?33s?  �?(��������Qpz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�l
01�H?n{3?C?%  �?%  �?-  �?2"
 mc:ecoretexthorizontalalign:left:"
 mc:ecoretextverticalalign:center*�ض���͢�LName"
  ���3Cfff?33s?  �?(��������Qpz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��
abcdefghijklmnopqrstuvw  �?  �?  �?%  �?%  �?-  �?2"
 mc:ecoretexthorizontalalign:left:"
 mc:ecoretextverticalalign:center*���و���bScore"
  9C��3Cfff?33s?  �?(��������Qpz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�l
999.9Mn�>  �?%  �?%  �?-  �?2#
!mc:ecoretexthorizontalalign:right:"
 mc:ecoretextverticalalign:center
NoneNone
���ؕ����IVoidZ��local Void = script:GetCustomProperty("Trigger"):WaitForObject()

local function enteredVoid(trigger, player)
	if(not player:IsA("Player")) then return end
	
	player:Die()
end

Void.beginOverlapEvent:Connect(enteredVoid)
=��������HEye	R*
PlatformBrushAssetRefUI_SciFI_Icon_042
�׶��ݜ��GPlayerStagePositionsZ��local GameServer = script:GetCustomProperty("Game"):WaitForObject()
local PlayerStagePositionTemplate = script:GetCustomProperty("PlayerStagePositionTemplate")
local PlayerStageTemplate = script:GetCustomProperty("PlayerStageTemplate")
local StagesFolder = script:GetCustomProperty("StagesFolder"):WaitForObject()
local BackgroundFrame = script:GetCustomProperty("BackgroundFrame"):WaitForObject()
local PlayersFrame = script:GetCustomProperty("PlayersFrame"):WaitForObject()
local StagesFrame = script:GetCustomProperty("StagesFrame"):WaitForObject()
local PrefixTags = require(script:GetCustomProperty("PrefixTags"))
local HelpfulFunctions = require(script:GetCustomProperty("HelpfulFunctions"))

local function updateStages(order)
    if(not order) then return end

    for _, child in pairs(StagesFrame:GetChildren()) do
        child:Destroy()
    end

    local highestPoint = GameServer:GetCustomProperty("HighestPoint")

    repeat Task.Wait() until #StagesFolder:GetChildren() >= 6

    local lastPercent = 0
    for index, stageName in ipairs(order) do
        local stage = HelpfulFunctions:WaitForChild(StagesFolder, stageName)

        local top = HelpfulFunctions:WaitForChild(stage, "Top")

        local color = stage:GetCustomProperty("Color")
        local percent = CoreMath.Round(top:GetWorldPosition().z / highestPoint.z, 3)

        local frame = World.SpawnAsset(PlayerStageTemplate, {parent = StagesFrame})
        frame:SetColor(color)
        frame.height = math.ceil((BackgroundFrame.height * percent) - (BackgroundFrame.height * lastPercent))
        frame.y = frame.height - math.ceil(BackgroundFrame.height * percent)
        frame.name = stage.name
        
        lastPercent = percent
    end
end

local function updatePlayerPosition(player, highestPoint)
    local difference = highestPoint - player:GetWorldPosition()
    
    local percent = CoreMath.Round(1 - (difference.z / highestPoint.z), 2)
    
    local playerFrame = PlayersFrame:FindChildByName(player.name)
    if(not playerFrame) then return end

    playerFrame.y = CoreMath.Clamp((BackgroundFrame.height - (BackgroundFrame.height * percent)) - BackgroundFrame.height, -BackgroundFrame.height, 0) - (playerFrame.height / 2)
end

function Tick()
    local highestPoint = GameServer:GetCustomProperty("HighestPoint") 
    for _, player in pairs(Game.GetPlayers()) do
        updatePlayerPosition(player, highestPoint)
    end
end

local function playerJoined(player)    
    local playerFrame = World.SpawnAsset(PlayerStagePositionTemplate, {
        parent = PlayersFrame
    })

    playerFrame.name = player.name
    playerFrame:SetImage(player)
    local nameText = playerFrame:FindChildByName("PlayerName")
    nameText.text = player.name
        
    local playerPrefix = PrefixTags:GetPlayerPrefix(player)
    if(playerPrefix) then
        nameText:SetColor(playerPrefix.color)
    end
end

local function playerLeft(player)
    local playerFrame = PlayersFrame:FindChildByName(player.name)
    if(playerFrame) then
        playerFrame:Destroy()
    end
end

Game.playerJoinedEvent:Connect(playerJoined)
Game.playerLeftEvent:Connect(playerLeft)

Events.Connect("UpdateStages", updateStages)
��涅����@start timerZ��local trigger = script.parent
local coursenum = script:GetCustomProperty("coursenum")

function OnBeginOverlap(whichTrigger, other)
	if other:IsA("Player") then
		print(whichTrigger.name .. ": Begin Trigger Overlap with " .. other.name)
	end
end

function OnEndOverlap(whichTrigger, other)
	if other:IsA("Player") then
		print(whichTrigger.name .. ": End Trigger Overlap with " .. other.name)
	end
end

function OnInteracted(whichTrigger, player)
	if player:IsA("Player") then
		print(whichTrigger.name .. ": Trigger Interacted " .. player.name)
		Events.BroadcastToPlayer(player,"startcourse")
		
	end
end

trigger.beginOverlapEvent:Connect(OnBeginOverlap)
trigger.endOverlapEvent:Connect(OnEndOverlap)
trigger.interactedEvent:Connect(OnInteracted)
������6PlayerCapsuleb�
� ����ۿ��*�����ۿ��Capsule"  �?  �?  �?(���δZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color�ʶT<ʶT<ʶT<%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 
NoneNone
<��������CapsuleR$
StaticMeshAssetRefsm_capsule_001
�F�ڒ��֍�2Interface Leaderboardb�E
�E ���и����*�"���и����Interface Leaderboard"  �?  �?  �?(��Ҙѩ��J2�̈����������ͧݚZ�!
<
cs:LeaderboardReference� 
mc:enetreferencetype:unknown

cs:LeaderboardTypejGLOBAL

cs:LeaderboardStatjDEATHS
"
cs:LeaderboardPersistencejTOTAL

cs:ResourceNamej 

cs:DisplayAsIntegerP 

cs:UpdateTimere  �A
&
cs:UpdateOnEventjUpdateLeaderboards

cs:UpdateOnResourceChangedP 

cs:UpdateOnPlayerDiedP 

cs:UpdateOnDamageDealtP 

cs:UpdateOnRoundEndP 
&
cs:FirstPlaceColor�  �?��-?%  �?
,
cs:SecondPlaceColor��?�?�?%  �?
+
cs:ThirdPlaceColor�sI?SY>l�=%  �?
2
cs:NoPodiumPlacementColor��H?n{3?C?%  �?
)
cs:UsernameColor�  �?  �?  �?%  �?
!
cs:ScoreColor�n�>  �?%  �?
$
cs:ToggleBindingjability_extra_40

cs:ToggleEventj 

cs:ForceOnEventj 

cs:ForceOffEventj 

cs:EaseToggleP

cs:EaseBeginningjUP

cs:EasingDuratione   ?

cs:EasingEquationInjLINEAR

cs:EasingDirectionInjIN

cs:EasingEquationOutjLINEAR

cs:EasingDirectionOutjOUT
p
cs:LeaderboardType:tooltipjRThe LeaderboardType for the leaderboard referenced | GLOBAL, MONTLY, WEEKLY, DAILY
s
cs:LeaderboardStat:tooltipjUWhat is being tracked by the leaderboard | RESOURCE, KDR, KILLS, DEATHS, DAMAGE_DEALT
e
cs:UpdateTimer:tooltipjKThe seconds for the leaderboard to update naturally; must be greater than 0
w
cs:ResourceName:tooltipj\The name of the resource that will be monitored; only applies if LeaderboardStat is RESOURCE
c
cs:DisplayAsInteger:tooltipjDDetermines if the score is shown as an interger (1) or a float (1.0)
S
cs:UpdateOnEvent:tooltipj7The leaderboard will update upon this event being fired
�
"cs:UpdateOnResourceChanged:tooltipj�The leaderboard will update upon a player's resource changing that corresponds to this leaderboard's ResourceName; does not apply if LeaderboardStat is not RESOURCE
�
cs:UpdateOnPlayerDied:tooltipjoThe leaderboard will update upon a player dying; does not apply if LeaderboardStat is not KDR, KILLS, or DEATHS
�
cs:UpdateOnDamageDealt:tooltipjnThe leaderboard will update upon a player being damaged; does not apply if LeaderboardStat is not DAMAGE_DEALT
R
cs:UpdateOnRoundEnd:tooltipj3The leaderboard will update upon Game.roundEndEvent
1
!cs:LeaderboardPersistence:tooltipjTOTAL, ROUND
�
cs:EaseBeginning:tooltipjxThe location that the leaderboard should ease from and to; does not apply if EaseToggle is false | UP, DOWN, LEFT, RIGHT
e
cs:LeaderboardReference:tooltipjBThe NetReference for the Leaderboard (View -> Global Leaderboards)
[
cs:FirstPlaceColor:tooltipj=The color for the person in the first place on the leaderbard
]
cs:SecondPlaceColor:tooltipj>The color for the person in the second place on the leaderbard
[
cs:ThirdPlaceColor:tooltipj=The color for the person in the third place on the leaderbard
]
!cs:NoPodiumPlacementColor:tooltipj8The color for the everyone not on the podium (not top 3)
@
cs:UsernameColor:tooltipj$The color for each player's username
:
cs:ScoreColor:tooltipj!The color for each player's score
Y
cs:ToggleBinding:tooltipj=The binding that someone presses to show/hide the leaderboard
R
cs:ToggleEvent:tooltipj8The event that will toggle the visibility of leaderboard
q
cs:EaseToggle:tooltipjXDetermines if the leaderboard should just pop in/out of place, or ease/tween/interpolate
a
cs:EasingDuration:tooltipjDThe amount of time for easing; does not apply if EaseToggle is false
�
cs:EasingEquationIn:tooltipj�The easing equation that will be used to ease in; does not apply if EaseToggle is false | LINEAR, QUADRATIC, CUBIC, QUARTIC, QUINTIC, SINE, EXPONENTIAL, CIRCULAR, ELASTIC, BACK, BOUNCE
�
cs:EasingDirectionIn:tooltipjiThe easing direction that will be used to ease in; does not apply if EaseToggle is false | IN, OUT, INOUT
�
cs:EasingEquationOut:tooltipj�The easing equation that will be used to ease out; does not apply if EaseToggle is false | LINEAR, QUADRATIC, CUBIC, QUARTIC, QUINTIC, SINE, EXPONENTIAL, CIRCULAR, ELASTIC, BACK, BOUNCE
�
cs:EasingDirectionOut:tooltipjjThe easing direction that will be used to ease out; does not apply if EaseToggle is false | IN, OUT, INOUT
V
cs:ForceOnEvent:tooltipj;The event that will force the leaderboard to become visible
Y
cs:ForceOffEvent:tooltipj=The event that will force the leaderboard to become invisiblez(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*��̈������Leaderboard"
    �?  �?  �?(���и����Z 

cs:Leaderboard����и����z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
������Õ�*�����ͧݚClientContext"
    �?  �?  �?(���и����2���ß���������Ez
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent� *����ß���Leaderboard_Interface"
    �?  �?  �?(����ͧݚZ�

cs:EntryTemplate�
���鏙��u

	cs:EaseUI�
�؋�ﲂ�

cs:Leaderboard����и����
#
cs:LeaderboardPanel��ھ���韐


cs:Entries�
��ۛ�年

cs:Title�
��������E

cs:UpdateTimer�Ū�жޞ��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��睼����*�������E	Container"
    �?  �?  �?(����ͧݚ2�ھ���韐�������Ez(
&mc:ecollisionsetting:inheritfromparent�
mc:evisibilitysetting:forceon�Y:

mc:euianchor:middlecenter� �4


mc:euianchor:topleft

mc:euianchor:topleft*��ھ���韐Leaderboard"
    �?  �?  �?(������E2��Ρ������߱��������ۛ�年z(
&mc:ecollisionsetting:inheritfromparent� 
mc:evisibilitysetting:forceoff�i��:

mc:euianchor:middlecenter� �>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*���Ρ�����
Background"
    �?  �?  �?(�ھ���韐z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�t��:

mc:euianchor:middlecenter�
 %   ? �>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*��߱������Header"
    �?  �?  �?(�ھ���韐2�����涫���������EŪ�жޞ��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�d�:

mc:euianchor:middlecenterHP� �8


mc:euianchor:topcenter

mc:euianchor:topcenter*������涫�
Background"
    �?  �?  �?(�߱������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�h:

mc:euianchor:middlecenterPX�
 %   ? �4


mc:euianchor:topleft

mc:euianchor:topleft*���������ETitle"
    �?  �?  �?(�߱������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�����������d:

mc:euianchor:middlecenterHP�F
LEADERBOARD NAME  �?  �?  �?%  �?2"
mc:etextjustify:center0�8


mc:euianchor:topcenter

mc:euianchor:topcenter*�Ū�жޞ��UpdateTimer"
    �?  �?  �?(�߱������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�����������(-  p�:

mc:euianchor:middlecenterHP�K
UPDATES IN 30 SECONDS���>���>���>%  �?"
mc:etextjustify:center0�>


mc:euianchor:bottomcenter

mc:euianchor:bottomcenter*���ۛ�年Entries"
    �?  �?  �?(�ھ���韐z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��������������������-   �:

mc:euianchor:middlecenterHPX� �>


mc:euianchor:bottomcenter

mc:euianchor:bottomcenter*��������EDisplay"
    �?  �?  �?(������E2��ߚ�Ɠ�i������������������z(
&mc:ecollisionsetting:inheritfromparent�
mc:evisibilitysetting:forceon�o��%  �A-  ��:

mc:euianchor:middlecenter� �:


mc:euianchor:bottomleft

mc:euianchor:bottomleft*���ߚ�Ɠ�iIcon"
    �?  �?  �?(�������E2
�߂�����z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�rdd:

mc:euianchor:middlecenter�
 %   ? �>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*��߂�����Leaderboard Icon"
    �?  �?  �?(��ߚ�Ɠ�iz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��������������������:

mc:euianchor:middlecenterHPX�%
��ί�߲ض  �?  �?  �?%  �? �>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*����������Name"
    �?  �?  �?(�������Ez(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��(:

mc:euianchor:middlecenterP�C
Global Deaths  �?  �?  �?%  �?"
mc:etextjustify:center0�8


mc:euianchor:topcenter

mc:euianchor:topcenter*����������Binding"
    �?  �?  �?(�������Ez(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��-:

mc:euianchor:middlecenterP�9
[X]  �?  �?  �?%  �?"
mc:etextjustify:center(�>


mc:euianchor:bottomcenter

mc:euianchor:bottomcenter
NoneNone
�7�؋�ﲂ�EaseUIZ�7�7-- EaseUI.lua
-- Handles easing (interpolation) of UI, interactable with FluidUI.
-- Created by Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

--[[
	Hello, everyone! Another day, another utility! Today is sponsored by... myself!

	EaseUI is a utility that allows for both simple and advanced UI animations! Full customizability to you, the creator!

	If you need any assistance, feel free to join the Core Discord server (https://discord.gg/core-creators) and ping me (@Nicholas Foreman#0001)
	in #lua-help or #core-help! I will happily assist you. :)

	Usage:
		1) Do not put this script in the hierarchy; keep it in `Project Content` > `Scripts`
		2) Drag and drop this script into the custom properties of any script you want to use it with
		3) Inside the script that you are using EaseUI in, insert this line at the top:
			local EaseUI = require(script:GetCustomProperty("EaseUI"))
		4) Congratulations, you can proceed to use EaseUI!

	Video Tutorial: https://www.youtube.com/watch?v=TVbHI8zE9J4
	Core Forum Post: https://forums.coregames.com/t/video-easeui/424
--]]

--[[
	Enums:
		EaseUI.EasingEquation.LINEAR
		EaseUI.EasingEquation.QUADRATIC
		EaseUI.EasingEquation.CUBIC
		EaseUI.EasingEquation.QUARTIC
		EaseUI.EasingEquation.QUINTIC
		EaseUI.EasingEquation.SINE
		EaseUI.EasingEquation.EXPONENTIAL
		EaseUI.EasingEquation.CIRCULAR
		EaseUI.EasingEquation.ELASTIC
		EaseUI.EasingEquation.BACK
		EaseUI.EasingEquation.BOUNCE

		EaseUI.EasingDirection.IN
		EaseUI.EasingDirection.OUT
		EaseUI.EasingDirection.INOUT

	Functions:
		EaseUI.Ease(uiElement, property, goal, [easeDuration], [easingEquation], [easingDirection])
			uiElement
				the UI Element that you are easing

			property
				the property of the UI Element that you are easing

			goal
				the value for the property you want the UI Element that you are easing to become

			easeDuration [optional, default 1]
				the amount of time you want the ease to last

			easingEquation [optional, default LINEAR]
				the easing equation that you want to use for easing the property

			easingDirection [optional, default INOUT]
				the easing direction that you want to use for easing the property

		EaseUI.EaseX(uiElement, goal, [easeDuration], [easingEquation], [easingDirection])
		EaseUI.EaseY(uiElement, goal, [easeDuration], [easingEquation], [easingDirection])
		EaseUI.EaseWidth(uiElement, goal, [easeDuration], [easingEquation], [easingDirection])
		EaseUI.EaseHeight(uiElement, goal, [easeDuration], [easingEquation], [easingDirection])
		EaseUI.EaseRotation(uiElement, goal, [easeDuration], [easingEquation], [easingDirection])
--]]

--[[
	\\\\\\\\\\\\\\\\\
	DO NOT EDIT BELOW
	/////////////////
	\\\\\\\\\\\\\\\\\\\\\\\\\\\
	I URGE YOU SAVE YOUR SANITY
	///////////////////////////
	\\\\\\\\\\\\\\\\\\\
	STUFF CAN GET MESSY
	///////////////////
	\\\\\\\\\\\\\\\\\\
	PLEASE, JUST DON'T
	//////////////////
	\\\\\\\\\\\\\\\\\\\\\\\\\\
	IT'S IN YOUR BEST INTEREST
	//////////////////////////
--]]

local EasingEquations = require(script:GetCustomProperty("EasingEquations"))

local tasks = {}

local function checkTask(property)
	if(tasks[property]) then return end

	tasks[property] = {}
end

local function wrapTask(property, object, func)
	checkTask(property)

	local task = Task.Spawn(func)
	task.repeatCount = -1
	task.repeatInterval = -1

	tasks[property][object] = task
	return task
end

local function clearFromTask(object, taskType)
	checkTask(taskType)

	local task = tasks[taskType][object]
	if(not task) then return end

	task:Cancel()
	tasks[taskType][object] = nil
end

local function verifyEase(uiElement, goal, easeDuration, easingEquation, easingDirection)
	if(not Object.IsValid(uiElement)) then
		return false, "Attempting to ease an object that does not exist"
	elseif(not uiElement:IsA("UIControl")) then
		return false, "Attempting to ease an object that is not a UI Element"
	elseif(uiElement:IsA("UIContainer")) then
		return false, "Attempting to ease a UIContainer"
	elseif(type(easeDuration) ~= "number") then
		return false, "Attempting to ease with an invalid amount of time"
	elseif(type(goal) ~= "number") then
		return false, "Attempting to ease to a goal that is not a number"
	elseif(type(easingEquation) ~= "number") then
		return false, "Attempting to ease with an invalid easing equation"
	elseif(type(easingDirection) ~= "number") then
		return false, "Attempting to ease with an invalid easing direction"
	end

	return true, ""
end

local Module = {}

Module.Equation = EasingEquations.Equation
Module.EasingEquation = EasingEquations.EasingEquation
Module.EasingDirection = EasingEquations.EasingDirection

function Module.Ease(uiElement, property, goal, easeDuration, easingEquation, easingDirection)
	if(type(easeDuration) == "nil") then easeDuration = 1 end
	if(type(easingEquation) == "nil") then easingEquation = Module.EasingEquation.LINEAR end
	if(type(easingDirection) == "nil") then easingDirection = Module.EasingDirection.INOUT end

	local success, response = verifyEase(uiElement, goal, easeDuration, easingEquation, easingDirection)
	assert(success, response)

	local easingFormula = EasingEquations.GetEasingEquationFormula(easingEquation, easingDirection)
	assert(easingFormula, "Attempting to ease with an invalid easing equation enum; check that you spelled the enum correctly")

	clearFromTask(uiElement, property)

	local startTime = time()
	local start = uiElement[property]

	local direction = ((start < goal) and 1) or -1

	wrapTask(property, uiElement, function()
		if(not Object.IsValid(uiElement)) then
			return clearFromTask(uiElement, property)
		end

		local currentTime = time() - startTime

		if(currentTime >= easeDuration) then
			uiElement[property] = CoreMath.Round(goal)

			return clearFromTask(uiElement, property)
		end

		uiElement[property] = CoreMath.Round(easingFormula(currentTime, start, direction * math.abs(goal - start), easeDuration))
	end)
end

function Module.EaseX(uiElement, goal, easeDuration, easingEquation, easingDirection)
	Module.Ease(uiElement, "x", goal, easeDuration, easingEquation, easingDirection)
end

function Module.EaseY(uiElement, goal, easeDuration, easingEquation, easingDirection)
	Module.Ease(uiElement, "y", goal, easeDuration, easingEquation, easingDirection)
end

function Module.EaseWidth(uiElement, goal, easeDuration, easingEquation, easingDirection)
	Module.Ease(uiElement, "width", goal, easeDuration, easingEquation, easingDirection)
end

function Module.EaseHeight(uiElement, goal, easeDuration, easingEquation, easingDirection)
	Module.Ease(uiElement, "height", goal, easeDuration, easingEquation, easingDirection)
end

function Module.EaseRotation(uiElement, goal, easeDuration, easingEquation, easingDirection)
	Module.Ease(uiElement, "rotationAngle", goal, easeDuration, easingEquation, easingDirection)
end

return Module$
"
cs:EasingEquations��������һ
��Ӌ�����.PlayerInformationZ��local GameScript = script:GetCustomProperty("Game"):WaitForObject()
local CoinsText = script:GetCustomProperty("Coins"):WaitForObject()
local WinsText = script:GetCustomProperty("Wins"):WaitForObject()
local FastestTimeText = script:GetCustomProperty("FastestTime"):WaitForObject()

local LocalPlayer = Game.GetLocalPlayer()

local function GetTime(delta)
	delta = tonumber(delta)

	if delta <= 0 then
		return 0, 0, 0
	else
		local minutes = math.floor(delta / 60)
		local seconds = math.floor(delta - (minutes * 60))
		local milliseconds = math.floor(math.ceil((delta - (minutes * 60) - seconds) * 10000) / 10)

		return minutes, seconds, milliseconds
	end
end

local function GetFormattedTime(delta)
	local minutes, seconds, milliseconds = GetTime(delta)

	return string.format("%002i:%002i.%003i", tostring(minutes), tostring(seconds), tostring(milliseconds))
end

local function updateLabels()
	local coins, wins, fastestTime =
		LocalPlayer:GetResource("Coins"),
		LocalPlayer:GetResource("Wins"),
		LocalPlayer:GetResource("HighScore")

	if(not coins) then coins = 0 end
	if(not wins) then wins = 0 end
	if((not fastestTime) or (fastestTime == 0)) then fastestTime = GameScript:GetCustomProperty("DefaultTime") * 1000 end

	CoinsText.text = tostring(coins)
	WinsText.text = tostring(wins)

	FastestTimeText.text = GetFormattedTime(fastestTime / 1000)
end

LocalPlayer.resourceChangedEvent:Connect(updateLabels)
updateLabels()
\��ۛ����*Casual & Fun Music Score Set 01
R-
AudioBlueprintAssetRefabp_CasualMusic_ref
�*�������"World Leaderboardb�*
�* å��駤��*�å��駤��World Leaderboard"  �?  �?  �?(��Ҙѩ��J2��꽰�Ų`���������ړш?Z�
<
cs:LeaderboardReference� 
mc:enetreferencetype:unknown

cs:LeaderboardTypejGLOBAL

cs:LeaderboardStatjDEATHS
"
cs:LeaderboardPersistencejTOTAL

cs:ResourceNamej 

cs:DisplayAsIntegerP

cs:UpdateTimere  �A
&
cs:UpdateOnEventjUpdateLeaderboards

cs:UpdateOnResourceChangedP 

cs:UpdateOnPlayerDiedP 

cs:UpdateOnDamageDealtP 

cs:UpdateOnRoundEndP 
&
cs:FirstPlaceColor�  �?��-?%  �?
,
cs:SecondPlaceColor��?�?�?%  �?
+
cs:ThirdPlaceColor�sI?SY>l�=%  �?
2
cs:NoPodiumPlacementColor��H?n{3?C?%  �?
)
cs:UsernameColor�  �?  �?  �?%  �?
!
cs:ScoreColor�n�>  �?%  �?
p
cs:LeaderboardType:tooltipjRThe LeaderboardType for the leaderboard referenced | GLOBAL, MONTLY, WEEKLY, DAILY
s
cs:LeaderboardStat:tooltipjUWhat is being tracked by the leaderboard | RESOURCE, KDR, KILLS, DEATHS, DAMAGE_DEALT
e
cs:UpdateTimer:tooltipjKThe seconds for the leaderboard to update naturally; must be greater than 0
w
cs:ResourceName:tooltipj\The name of the resource that will be monitored; only applies if LeaderboardStat is RESOURCE
c
cs:DisplayAsInteger:tooltipjDDetermines if the score is shown as an interger (1) or a float (1.0)
S
cs:UpdateOnEvent:tooltipj7The leaderboard will update upon this event being fired
�
"cs:UpdateOnResourceChanged:tooltipj�The leaderboard will update upon a player's resource changing that corresponds to this leaderboard's ResourceName; does not apply if LeaderboardStat is not RESOURCE
�
cs:UpdateOnPlayerDied:tooltipjoThe leaderboard will update upon a player dying; does not apply if LeaderboardStat is not KDR, KILLS, or DEATHS
�
cs:UpdateOnDamageDealt:tooltipjnThe leaderboard will update upon a player being damaged; does not apply if LeaderboardStat is not DAMAGE_DEALT
R
cs:UpdateOnRoundEnd:tooltipj3The leaderboard will update upon Game.roundEndEvent
N
!cs:LeaderboardPersistence:tooltipj)How data should be tracked | TOTAL, ROUND
e
cs:LeaderboardReference:tooltipjBThe NetReference for the Leaderboard (View -> Global Leaderboards)
[
cs:FirstPlaceColor:tooltipj=The color for the person in the first place on the leaderbard
]
cs:SecondPlaceColor:tooltipj>The color for the person in the second place on the leaderbard
[
cs:ThirdPlaceColor:tooltipj=The color for the person in the third place on the leaderbard
]
!cs:NoPodiumPlacementColor:tooltipj8The color for the everyone not on the podium (not top 3)
@
cs:UsernameColor:tooltipj$The color for each player's username
:
cs:ScoreColor:tooltipj!The color for each player's scorez(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*���꽰�Ų`Leaderboard"
    �?  �?  �?(å��駤��Z 

cs:Leaderboard�å��駤��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
������Õ�*���������Scenery"
  HC   �?  �?  �?(å��駤��2����ն���������ڸz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*�����ն���Board"
  � ���=  �@33S@(��������Z�
)
ma:Shared_BaseMaterial:id��������
 
ma:Shared_BaseMaterial:smartP 
#
ma:Shared_BaseMaterial:utilee  �?
#
ma:Shared_BaseMaterial:vtilee  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�������ڸ	Underline"
  %C  �B���=333?  �@(��������Z�
)
ma:Shared_BaseMaterial:id��������
 
ma:Shared_BaseMaterial:smartP 
#
ma:Shared_BaseMaterial:utilee���>
#
ma:Shared_BaseMaterial:vtilee  �?
5
ma:Shared_BaseMaterial:color�   ?   ?   ?%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��ړш?ClientContext"
  HC   �?  �?  �?(å��駤��2���׵������Ø���z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent� *����׵��Leaderboard_World"
    �?  �?  �?(�ړш?Z�

cs:EntryTemplate�
����ՐǩL

cs:Leaderboard�å��駤��


cs:Entries�
����Ќ֛[

cs:Title�
ڑ���ݩ�o

cs:UpdateTimer�
Ϳ����Ȍ
z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��閆����*�����Ø���Screen"
    �?  �?  �?(�ړш?2Ń�ԣ������Ќ֛[z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*�Ń�ԣ��Header"

 R��  %C   �?  �?  �?(����Ø���2ڑ���ݩ�oͿ����Ȍ
z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*�ڑ���ݩ�oTitle"
  �@��3C  �?  �?  �?(Ń�ԣ��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�|
LEADERBOARD NAME  �?  �?  �?%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*�Ϳ����Ȍ
UpdateTimer"
  H���3C  �?��,?333?(Ń�ԣ��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��
UPDATES IN 30 SECONDS���>���>���>%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*�����Ќ֛[Entries"

 R��  �B   �?  �?  �?(����Ø���z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
NoneNone
��������� FluidUIbe
U ��ã𯽂�*H��ã𯽂�TemplateBundleDummy"
    �?  �?  �?�Z

��������l
NoneNone��
 abe9b8ddc0954d09af5171c1ff7f9bc1 f9df3457225741c89209f6d484d0eba8NicholasForeman"1.5.0*�FluidUI, created by Nicholas Foreman (nforeman)
Thumbnail created by John Shoff (FearTheDev)

FluidUI is a responsive User Interface Framework that allows you to design your interface dynamically without having to worry about the screen resolution of the users playing your games. With many powerful features such as screen-size scaling, grids/lists, and aspect ratios, you will have nearly full control over the presentation of your game.

Getting the framework to work itself is simple. You only need one instance of this script inside of of a ClientContext. Any additional copies of this script will conflict with each other and you will not get the intended goal.

Within the FluidUI.lua script is some very important documentation on how to utilize the system.
��ṑ�訙MessageZ��local textBox = script:GetCustomProperty("TextBox"):WaitForObject()

local lastMessage = ""

local function message(message)
    lastMessage = message

    textBox.text = message

    Task.Wait(2)
    if(lastMessage ~= message) then return end

    textBox.text = ""
end

Events.Connect("Message", message)
�	��������TrailsServerZ�	�	local ShopData = require(script:GetCustomProperty("ShopData"))

local function getTrail(trailId)
	for _, trail in pairs(ShopData.Trails) do
		if(trail.id == trailId) then
			return trail
		end
	end
end

local function equipTrail(player, trailId)
	local trail = getTrail(trailId)
	if(trailId ~= 0) then
		if(not trail) then return end
	end

	local playerData = Storage.GetPlayerData(player)
	playerData.currentTrail = trailId
	Storage.SetPlayerData(player, playerData)

	player:SetResource("CurrentTrail", trail and trail.id or 0)
end

local function getTrails(player)
	local playerData = Storage.GetPlayerData(player)
	if(not playerData.trails) then
		playerData.trails = {}
		Storage.SetPlayerData(player, playerData)
	end

	Events.BroadcastToPlayer(player, "SetTrails", playerData.trails)
end

local function playerJoined(player)
	local playerData = Storage.GetPlayerData(player)
	if(type(playerData.currentTrail) ~= "number") then return end

	equipTrail(player, playerData.currentTrail)
end

Game.playerJoinedEvent:Connect(playerJoined)
Events.ConnectForPlayer("GetTrails", getTrails)
Events.Connect("EquipTrail", equipTrail)
Events.ConnectForPlayer("EquipTrail", equipTrail)
޵��ۈܑ��Hard1bǵ
�� ��������*���������Hard1"  �?  �?  �?(�����B2L���ŗ��.ˁ���ȗ�8��¯��L���󵛍�������ӳ�����ɝ○�����������������Z#
!
cs:Color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*����ŗ��.Music"
  zD   HB  HB  �A(��������pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*�ˁ���ȗ�8
Checkpoint"

 0�  �B    @33�A   @(��������pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*���¯��LTop"
  �D   HB  HB   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color����>  �?���>%  �?pz
mc:ecollisionsetting:forceoff� 
mc:evisibilitysetting:forceoff�
��������08�
 *����󵛍��TransitionPlatform"

 0� ��D    @33�A   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *������ӳ��RotatingKillTriggers"
 @ND���A  �?  �?  �?(��������2q��課r��������{���������ɘ��㗫���鹫�����������Ʈ������ߩk��¼�í�^���豵��ՙ�ȸ��ח�ʸ���@�����符zpz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*���課r
RotateKill"$
 �@�H����C   pA  �@  �@(�����ӳ��ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���������{
RotateKill".
��E?bK��P��C
   ��7  �@  �@  �@(�����ӳ��ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���������
RotateKill".
 Py=4w�D�ńC
   ����7  �@  �@  �@(�����ӳ��ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ɘ��㗫�
RotateKill")
B8gD�Hb��a�C  4B  �@  �@  �@(�����ӳ��ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���鹫����
RotateKill")
��a��pg���C��3B  �@  �@  �@(�����ӳ��ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��������Ʈ
RotateKill".
`ض�������C
   ����7  �@  �@  �@(�����ӳ��ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�������ߩk
RotateKill".
 ������C��C
   �6G�7  �@  �@  �@(�����ӳ��ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���¼�í�^
RotateKill")
3�fD�cD\��C��3B  �@  �@  �@(�����ӳ��ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����豵�
RotateKill")
��c��iD��C��3B  �@  �@  �@(�����ӳ��ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ՙ�ȸ��
RotateKill"$
��@�H����C ���A  �@  �@(�����ӳ��ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�ח�ʸ���@RotateKill_Deactivated"$
=��D�H��,M�C   �@  �@  �@(�����ӳ��ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff� 
mc:evisibilitysetting:forceoff�
��������08�
 *������符zRotateKill_Deactivated"$
�0���H��ib�C   �@  �@  �@(�����ӳ��ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff� 
mc:evisibilitysetting:forceoff�
��������08�
 *����ɝ○KillTriggers"
    �?  �?  �?(��������2�ڙև����:�ۡ�͟��ø�ã:�̹�����W����ϥ{����ב��k�ҥ�����y�ފ�����,�ۀ���Ϩ~٧�˧���)�֋��г��������͔���ڻ���䡳��Ȥ�������I������pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*�ڙև����:Kill"$
 ��D  �C  �D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ۡ�͟��Kill"$
  �D  D���D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�ø�ã:Kill"$
 @E  HD @�D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��̹�����WKill"$
   E ��D @�D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����ϥ{Kill"$
  �D  �D ��D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����ב��kKill"$
 ��D @�D ��D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ҥ�����yKill"$
 @�D ��D ��D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ފ�����,Kill"$
  aD   E ��D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ۀ���Ϩ~Kill"$
  D  �D ��D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�٧�˧���)Kill"$
  �C @E ��D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��֋��г�Kill"$
  H�  �D  �D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��������͔Kill"$
  �� ��D @�D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����ڻ��Kill"$
  a�  �D ��D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��䡳��Ȥ�Kill"$
 ���  �D ��D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�������IKill"$
 @�� ��D ��D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�������Kill"$
 ��� @�D ��D 33�>33�>���>(���ɝ○ZX
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
+
ma:Shared_BaseMaterial:color�
  �?%  �?pz
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����������Walls"
  zD   �?  �?  �?(��������2L��Ԏ���᳅����Ό�����ŭ����������������%�����Œ����ۡ⊏���������pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*���Ԏ���Wall"
  �   �?  �A  �A(���������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *�᳅����ΌWall"
  E   �?  �A  �A(���������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *������ŭ�Wall"
  E   �A  �?  �A(���������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���������Wall"
  �   �A  �?  �A(���������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *��������%Wall"$

0���0�����3B  �?  �A  �A(���������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *������Œ�Wall"$

,���0��D��3B  �A  �?  �A(���������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����ۡ⊏Wall"$

0��D0��D��3B  �?  �A  �A(���������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *����������Wall"$

0��D0�����3B  �A  �?  �A(���������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������088�
 *���������	Obstacles"
    �?  �?  �?(��������2��ۉ㜾����Ȍ�Щ��0ɻؔ���Ş�ɸ��ң�����ό��������ا�!�����ِ�Y�������p���Π�υl��ۨ����EƐ��������Ȫ���b��眺����¡��������������mܱ���ܠk������b�⠫��ϥ����ج��K����Փ��C�������єpz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*��ۉ㜾���Group"
 @ND  �A  �?  �?  �?(��������2����������������Āpz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*����������Group"
    �?  �?  �?(�ۉ㜾���2%���чޚ���������[�ŷ�Ƌ�e�ޫ��됽Apz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*����чޚ��Platform"
 �AD� �7  HA  xA   ?(���������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��������[Platform"
 �A�� �7  HA  xA   ?(���������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ŷ�Ƌ�ePlatform"
 �A�� �7  xA  HA   ?(���������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ޫ��됽APlatform"
 �AD� �7  xA  HA   ?(���������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��������ĀGroup"
 ��3�  �?  �?  �?(�ۉ㜾���2%���������ѩ����������ꥤ׿�����pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*���������Platform"
 �AD� �7  HA  xA   ?(�������ĀZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ѩ������Platform"
 �A�� �7  HA  xA   ?(�������ĀZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����ꥤPlatform"
 �A�� �7  xA  HA   ?(�������ĀZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�׿�����Platform"
 �AD� �7  xA  HA   ?(�������ĀZb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��Ȍ�Щ��0Group"$

�!���D  �A���=���=���=(��������2��ͤ��������ع�pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*���ͤ�����Group"
    �?  �?  �?(�Ȍ�Щ��02&ӏ��ďœ�ڎ�����������Ў��ƣ������pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*�ӏ��ďœPlatform"
 �AD� �7  HA  xA  �B(��ͤ�����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ڎ�����Platform"
 �A�� �7  HA  xA  �B(��ͤ�����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�������Ў�Platform"
 �A�� �7  xA  HA  �B(��ͤ�����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ƣ������Platform"
 �AD� �7  xA  HA  �B(��ͤ�����Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����ع�Group"
 ��3�  �?  �?  �?(�Ȍ�Щ��02'����������Ο������������ã�����ȵ�bpz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*����������Platform"
 �AD� �7  HA  xA  �B(���ع�Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��Ο�����Platform"
 �A�� �7  HA  xA  �B(���ع�Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��������ãPlatform"
 �A�� �7  xA  HA  �B(���ع�Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *������ȵ�bPlatform"
 �AD� �7  xA  HA  �B(���ع�Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�ɻؔ���ŞPlatform"$
 ���  ��  �A    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��ɸ��ң�Platform"$
 @��  p�  �A    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����ό���Platform"$
 ���  �C  HB    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *������ا�!Platform"$
 ��D  �C  �D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *������ِ�YPlatform"$
  �D  D @�D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��������pPlatform"$
 @E  HD @�D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *����Π�υlPlatform"$
   E ��D @�D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���ۨ����EPlatform"$
  �D  �D ��D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�Ɛ������Platform"$
 ��D @�D ��D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���Ȫ���bPlatform"$
 @�D ��D ��D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���眺���Platform"$
  aD   E ��D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��¡������Platform"$
  D  �D ��D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *���������mPlatform"$
  �C @E ��D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�ܱ���ܠkPlatform"$
  H�  �D  �D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�������bPlatform"$
  �� ��D @�D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��⠫��ϥPlatform"$
  a�  �D ��D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����ج��KPlatform"$
 ���  �D ��D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *�����Փ��CPlatform"$
 @�� ��D ��D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 *��������єPlatform"$
 ��� @�D ��D    @   @   ?(��������Zb
)
ma:Shared_BaseMaterial:id�Åɂ���ʴ
5
ma:Shared_BaseMaterial:color���\?�dN>  �?%  �?pz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������08�
 
NoneNone
A��������Coin	R-
PlatformBrushAssetRefUI_Fantasy_icon_Coin
K�������Basic MaterialR-
MaterialAssetRefmi_basic_pbr_material_001
���ſɃ��NameplateTemplateb�
� �㟕���ס*��㟕���סNameplateTemplate"  �?  �?  �?(�����B2灅�����������GZ\
0
ma:Shared_BaseMaterial:color�  �?  �?  �?
(
ma:Shared_BaseMaterial:id�
�������z
mc:ecollisionsetting:forceoff� 
mc:evisibilitysetting:forceoff�
��������  (�
 *�灅���Prefix"
  �A   �?  �?  �?(�㟕���סz(
&mc:ecollisionsetting:inheritfromparent�
mc:evisibilitysetting:forceon�e   ?  �?%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*���������GName"
    �?  �?  �?(�㟕���סz(
&mc:ecollisionsetting:inheritfromparent�
mc:evisibilitysetting:forceon�j  �?  �?  �?%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center
NoneNone