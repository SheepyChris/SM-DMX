local ChartIndex = 1
local ChartArray = nil
local SongIsChosen = false

local function InputHandler(event)
    local pn = event.PlayerNumber
    if not pn then return end

    -- To avoid control from a player that has not joined, filter the inputs out
    if pn == PLAYER_1 and not GAMESTATE:IsPlayerEnabled(PLAYER_1) then return end
    if pn == PLAYER_2 and not GAMESTATE:IsPlayerEnabled(PLAYER_2) then return end

    if SongIsChosen then
        -- Filter out everything but button presses
        if event.type == "InputEventType_Repeat" or event.type == "InputEventType_Release" then return end

        local button = event.button
        if button == "Left" or button == "MenuLeft" or button == "DownLeft" then
            if ChartIndex == 1 then
                return
            else
                ChartIndex = ChartIndex - 1
            end
            MESSAGEMAN:Broadcast("UpdateChartDisplay")
			
        elseif button == "Right" or button == "MenuRight" or button == "DownRight" then
            if ChartIndex == #ChartArray then
                return
            else
                ChartIndex = ChartIndex + 1
            end
            MESSAGEMAN:Broadcast("UpdateChartDisplay")
			
        elseif button == "Start" or button == "MenuStart" or button == "Center" then
            if ChartIndex >= 3 then
                MESSAGEMAN:Broadcast("SongUnchosen")
                MESSAGEMAN:Broadcast("UpdateChartDisplay")
            else
                SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
            end
        end
    end
    return
end

local t = Def.ActorFrame {
	InitCommand=function(self)
		-- Set these or else we crash.
		GAMESTATE:SetCurrentPlayMode("PlayMode_Regular")
		GAMESTATE:SetCurrentStyle(GAMESTATE:GetNumSidesJoined() > 1 and "versus" or "single")
	end,
	
    OnCommand=function(self)
        SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
        self:visible(false):playcommand("Refresh")
    end,

    -- Update chart list
    UpdateChartDisplayMessageCommand=function(self) self:playcommand("Refresh") end,

    -- These are to control the visibility of the chart highlight.
    SongChosenMessageCommand=function(self) 
		SongIsChosen = true
		self:visible(true):playcommand("Refresh") 
	end,
    SongUnchosenMessageCommand=function(self) 
		SongIsChosen = false 
		ChartIndex = 1
		self:visible(false):playcommand("Refresh") 
	end,

    RefreshCommand=function(self)
        ChartArray = nil
		
        local CurrentSong = GAMESTATE:GetCurrentSong()
        if CurrentSong then
			local ChartMild = SongUtil.GetPlayableSteps(CurrentSong)[1]
			local ChartWild = SongUtil.GetPlayableSteps(CurrentSong)[2] or ChartMild
            ChartArray = { ChartMild, ChartWild, ChartMild }
        end

        if ChartArray then
			self:GetChild("DiffList"):setstate(ChartIndex - 1)
			
			-- Set the selected charts
            if GAMESTATE:IsPlayerEnabled(PLAYER_1) and ChartIndex <= 2 then
				GAMESTATE:SetCurrentSteps(PLAYER_1, ChartArray[ChartIndex])
            end
            if GAMESTATE:IsPlayerEnabled(PLAYER_2) and ChartIndex <= 2 then
				GAMESTATE:SetCurrentSteps(PLAYER_2, ChartArray[ChartIndex])
			end
		end
    end,
	
	Def.Sprite {
		Name="DiffList",
		Texture=THEME:GetPathG("", "SelectMusic/SelectDifficulty 1x3 (doubleres).png"),
		InitCommand=function(self)
			self:animate(false):setstate(0)
		end
	},
	
    Def.Sound {
        File=THEME:GetPathS("Common", "value"),
        IsAction=true,
        UpdateChartDisplayMessageCommand=function(self) self:play() end
    },
	
	Def.Sound {
        File=THEME:GetPathS("Common", "Start"),
        IsAction=true,
        StepsChosenMessageCommand=function(self) self:play() end,
        SongUnchosenMessageCommand=function(self) self:play() end
    }
}

return t;
