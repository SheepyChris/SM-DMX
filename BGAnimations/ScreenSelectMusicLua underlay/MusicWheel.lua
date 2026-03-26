local WheelSize = 18
local WheelCenter = 4
local WheelItem = { Width = 95, Height = 71 }
local WheelItemPos = {
    {x = -100, y = -280, z = -200, rotx = -56, roty = 20, rotz = 25},
	{x = -77, y = -189, z = -80, rotx = -46, roty = 20, rotz = 25},
	{x = -48.66, y = -100, z = -20, rotx = -21, roty = 11, rotz = 7},
	{x = 0, y = 0, z = 0, rotx = 0, roty = 0, rotz = 0},
	{x = 66.5, y = 100, z = -20, rotx = 15, roty = -5, rotz = 2},
	{x = 140, y = 187, z = -80, rotx = 40, roty = -20, rotz = 15},
    {x = 200, y = 240, z = -140, rotx = 50, roty = -20, rotz = 15},
	{x = -200, y = -220, z = -200, rotx = -50, roty = 30, rotz = 25},
    {x = -144, y = -105, z = -45, rotx = -32, roty = 36, rotz = 21},
    {x = -122, y = -12.5, z = -30, rotx = -4, roty = 25, rotz = 0},
    {x = -57, y = 91, z = -13, rotx = 15, roty = 15, rotz = -7},
	{x = 12.5, y = 179, z = -42, rotx = 35, roty = 2, rotz = -4},
	{x = 80, y = 270, z = -140, rotx = 50, roty = -5, rotz = 2},
	{x = -240, y = -120, z = -160, rotx = -35, roty = 50, rotz = 35},
	{x = -205, y = -20, z = -80, rotx = -10, roty = 52, rotz = 5},
	{x = -164, y = 76, z = -50, rotx = 17, roty = 39, rotz = -15},
	{x = -110, y = 178, z = -80, rotx = 37, roty = 25, rotz = -24},
	{x = -40, y = 270, z = -140, rotx = 50, roty = 5, rotz = -2},
}

local Songs = {}
local Targets = {}

local SongIndex = LastSongIndex > 0 and LastSongIndex or 1
local GroupMainIndex = LastGroupMainIndex > 0 and LastGroupMainIndex or 1
local GroupSubIndex = LastGroupSubIndex > 0 and LastGroupSubIndex or 1

local IsBusy = false

function PlayableSongs(SongList)
	local SongTable = {}
	for Song in ivalues(SongList) do
        local Steps = SongUtil.GetPlayableSteps(Song)
		if #Steps > 0 then
			SongTable[#SongTable+1] = Song
		end
	end
	return SongTable
end

Songs = PlayableSongs(SONGMAN:GetAllSongs())

-- Update Songs item targets
local function UpdateItemTargets(val)
    for i = 1, WheelSize do
        Targets[i] = val + i - WheelCenter
        -- Wrap to fit to Songs list size
        while Targets[i] > #Songs do Targets[i] = Targets[i] - #Songs end
        while Targets[i] < 1 do Targets[i] = Targets[i] + #Songs end
    end
end

local function InputHandler(event)
	local pn = event.PlayerNumber
    if not pn then return end
    
    -- Don't want to move when releasing the button
    if event.type == "InputEventType_Release" then return end

    local button = event.GameButton
    
	-- To avoid control from a player that has not joined, filter the inputs out
	if pn == PLAYER_1 and not GAMESTATE:IsPlayerEnabled(PLAYER_1) then return end
	if pn == PLAYER_2 and not GAMESTATE:IsPlayerEnabled(PLAYER_2) then return end

	if not IsBusy then
		if button == "Right" or button == "MenuRight" or button == "DownRight" then
			SongIndex = SongIndex - 1
			if SongIndex < 1 then SongIndex = #Songs end
			
			GAMESTATE:SetCurrentSong(Songs[SongIndex])
			UpdateItemTargets(SongIndex)
			MESSAGEMAN:Broadcast("Scroll", { Direction = -1 })

		elseif button == "Left" or button == "MenuLeft" or button == "DownLeft" then
			SongIndex = SongIndex + 1
			if SongIndex > #Songs then SongIndex = 1 end
			
			GAMESTATE:SetCurrentSong(Songs[SongIndex])
			UpdateItemTargets(SongIndex)
			MESSAGEMAN:Broadcast("Scroll", { Direction = 1 })
			
		elseif button == "Start" or button == "MenuStart" or button == "Center" then
            -- Filter repeated input to avoid getting stuck
            if event.type == "InputEventType_Repeat" then return end
            
			-- Save this for later
			LastSongIndex = SongIndex
			
			MESSAGEMAN:Broadcast("MusicWheelStart")

		elseif button == "Back" then
			SCREENMAN:GetTopScreen():Cancel()
		end
	end

	MESSAGEMAN:Broadcast("UpdateMusic")
end

-- Manages banner on sprite
local function UpdateBanner(self, Song)
    self:LoadFromSongBackground(Song):scaletoclipped(WheelItem.Width, WheelItem.Height)
end

local t = Def.ActorFrame {
    InitCommand=function(self)
        self:xy(SCREEN_CENTER_X - 117, SCREEN_CENTER_Y - 34)
		:fov(90):SetDrawByZPosition(true)
        :vanishpoint(SCREEN_CENTER_X - 117, SCREEN_CENTER_Y - 34)
        UpdateItemTargets(SongIndex)
    end,

    OnCommand=function(self)
        GAMESTATE:SetCurrentSong(Songs[SongIndex])
        SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
    end,
	
	OffCommand=function(self)
		
	end,
    
    -- Race condition workaround (yuck)
    MusicWheelStartMessageCommand=function(self) self:sleep(0.01):queuecommand("Confirm") end,
    ConfirmCommand=function(self) MESSAGEMAN:Broadcast("SongChosen") end,

    -- These are to control the functionality of the music wheel
    SongChosenMessageCommand=function(self)
        self:finishtweening():playcommand("Busy")
    end,
    SongUnchosenMessageCommand=function(self)
        self:finishtweening():playcommand("NotBusy")
    end,
    
    BusyCommand=function(self) IsBusy = true end,
    NotBusyCommand=function(self) IsBusy = false end,
    
    -- Play song preview (thanks Luizsan)
    Def.Actor {
        CurrentSongChangedMessageCommand=function(self)
            SOUND:StopMusic()
            self:stoptweening():sleep(2):queuecommand("PlayMusic")
        end,
        
        PlayMusicCommand=function(self)
            local Song = GAMESTATE:GetCurrentSong()
            if Song then
                SOUND:PlayMusicPart(Song:GetMusicPath(), Song:GetSampleStart(), 
                Song:GetSampleLength(), 0, 1, true, false, false, Song:GetTimingData())
            end
        end
    },
	Def.Sound {
        File=THEME:GetPathS("Common", "scan"),
        CurrentSongChangedMessageCommand=cmd(stoptweening;stop;sleep,1;queuecommand,"Play");
		PlayCommand=cmd(play);
    },
	Def.Sound {
        File=THEME:GetPathS("", "WheelIntro"),
        OnCommand=cmd(queuecommand,"Play");
		PlayCommand=cmd(play);
    },
	Def.Sound {
        File=THEME:GetPathS("Common", "typing"),
        CurrentSongChangedMessageCommand=cmd(stoptweening;stop;sleep,0.125;queuecommand,"Play");
		PlayCommand=cmd(play);
    },
    Def.Sound {
        File=THEME:GetPathS("MusicWheel", "change"),
        IsAction=true,
        ScrollMessageCommand=function(self) self:play() end
    },

    Def.Sound {
        File=THEME:GetPathS("Common", "Start"),
        IsAction=true,
        MusicWheelStartMessageCommand=function(self) self:play() end
    },
}

-- The Wheel: originally made by Luizsan
for i = 1, WheelSize do

    t[#t+1] = Def.ActorFrame{
        OnCommand=function(self)
            -- Load banner
            UpdateBanner(self:GetChild("Banner"), Songs[Targets[i]])

            -- Set initial position, Direction = 0 means it won't tween
            self:playcommand("Scroll", {Direction = 0})
        end,
		
		ForceUpdateMessageCommand=function(self)
			-- Load banner
            UpdateBanner(self:GetChild("Banner"), Songs[Targets[i]])
            
            --SCREENMAN:SystemMessage(GroupsList[GroupIndex].Name)

            -- Set initial position, Direction = 0 means it won't tween
            self:playcommand("Scroll", {Direction = 0})
		end,

        ScrollMessageCommand=function(self,param)
            self:finishtweening()
            self:GetChild("Banner"):shadowcolor(color("#00000000"))

            -- Only tween if a direction was specified
            local tween = param and param.Direction and math.abs(param.Direction) > 0
            
            -- Adjust and wrap actor index
            i = i - param.Direction
            while i > WheelSize do i = i - WheelSize end
            while i < 1 do i = i + WheelSize end

            -- If it's an edge item, load a new banner. Edge items should never tween
            if i == 1 or i == WheelSize then
				UpdateBanner(self:GetChild("Banner"), Songs[Targets[i]])
            --elseif tween then
                --self:linear(0.166)
            end
			
			self:linear(0.166)

            -- Animate!
			self:x(WheelItemPos[i].x)
			:y(WheelItemPos[i].y)
			:z(WheelItemPos[i].z)
			:rotationx(WheelItemPos[i].rotx)
			:rotationy(WheelItemPos[i].roty)
			:rotationz(WheelItemPos[i].rotz)
			
			if i == 1 or i == 7 or i == 8 or i == 13 or i == 14 or i == 18 then
				self:diffusealpha(0)
			else
				self:diffusealpha(1)
			end
            
             -- Restore shadow
            self:GetChild("Banner"):linear(0.1):shadowcolor(color("#00000077"))
            
            --self:GetChild("Index"):playcommand("Refresh")
        end,

        Def.Banner {
            Name="Banner",
			InitCommand=function(self)
				self:shadowlengthx(13)
				:shadowlengthy(9)
				:shadowcolor(color("#00000077"))
				self:diffusealpha(1)
			end,
        },

        --[[Def.BitmapText {
			Name="Index",
			Font="Common normal",
			RefreshCommand=function(self,param) self:settext(Targets[i]) end
		}--]]
    }
end

return t
