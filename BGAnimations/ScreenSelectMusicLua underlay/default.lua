local StageAmount = PREFSMAN:GetPreference("SongsPerPlay")

local t = Def.ActorFrame {
	-- Add timer functionality
	InitCommand=function(self)
		self:sleep(0.5):queuecommand("CheckTimer")
	end,
	
	CheckTimerCommand=function(self)
		if SCREENMAN:GetTopScreen():GetChild("Timer"):GetSeconds() <= 0 then
			self:queuecommand("TimerExpired")
		else
			self:sleep(0.5):queuecommand("CheckTimer")
		end
	end,
	
	TimerExpiredCommand=function(self)
		-- Set these or else we crash.
        GAMESTATE:SetCurrentPlayMode("PlayMode_Regular")
		GAMESTATE:SetCurrentStyle(GAMESTATE:GetNumSidesJoined() > 1 and "versus" or "single")
        SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
	end,
	
    Def.Sprite {
        Texture=THEME:GetPathG("", "SelectMusic/BackgroundEmpty.png"),
        InitCommand=function(self)
            self:xy(SCREEN_CENTER_X + 2, SCREEN_CENTER_Y - 10)
        end,
    },
	
	-- This texture is for testing and cross referencing the OG game, 
	-- keep diffusealpha at 0 if not being used
	Def.Sprite {
        Texture=THEME:GetPathG("", "SelectMusic/SongSelect1.png"),
        InitCommand=function(self)
            self:Center():diffusealpha(0)
        end,
    },
	
	Def.Sprite {
		Name="HeaderText",
		Texture=THEME:GetPathG("", "SelectMusic/MusicSelect.png"),
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X + 146, SCREEN_CENTER_Y - 92):SetTextureFiltering(false)
		end,
	},
	
	Def.Sprite {
		Texture=THEME:GetPathG("", "SelectMusic/StageFrame (doubleres).png"),
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X + 492 - (StageAmount * 71), SCREEN_CENTER_Y - 200)
			:cropright((5 - StageAmount) * 0.2 - 0.001) -- Magic sauce
		end,
	},
	
	LoadActor("SongDetails"),
	
	LoadActor("MusicWheel"),
	
	LoadActor("SelectDiff") .. {
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y + 122)
		end
	},
	
	Def.Sprite {
		Name="MenuButtonsP1",
        Condition=GAMESTATE:IsPlayerEnabled(PLAYER_1);
        Texture=THEME:GetPathG("", "MenuButtons 1x5 (doubleres).png"),
        InitCommand=function(self)
            self:xy(SCREEN_CENTER_X - 193, SCREEN_CENTER_Y + 205)
			:animate(false)
        end,
    },
	
	Def.Sprite {
		Name="MenuButtonsP2",
        Condition=GAMESTATE:IsPlayerEnabled(PLAYER_2);
        Texture=THEME:GetPathG("", "MenuButtons 1x5 (doubleres).png"),
        InitCommand=function(self)
            self:xy(SCREEN_CENTER_X + 199, SCREEN_CENTER_Y + 205)
			:animate(false)
        end,
    },
	
	Def.Sprite {
        Texture=THEME:GetPathG("", "SelectMusic/SongInfoBar.png"),
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X + 3, SCREEN_CENTER_Y - 22)
			:cropright(0.76):faderight(0.05):diffusealpha(0.75)
		end,
		CurrentSongChangedMessageCommand=function(self)
			self:stoptweening():diffusealpha(0):linear(0.125):diffusealpha(0.75)
		end,
    },
	
	Def.Sprite {
        Texture=THEME:GetPathG("", "SelectMusic/HighlightedSongFrame 4x4 (doubleres).png"),
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X - 117, SCREEN_CENTER_Y - 33)
			:SetTextureFiltering(false):diffusealpha(0):animate(false):SetAllStateDelays(0)
		end,
		CurrentSongChangedMessageCommand=function(self)
			self:stoptweening():diffusealpha(0):setstate(0):animate(false)
			:sleep(1)
			:diffusealpha(1):animate(true):SetAllStateDelays(0.055)
			:sleep(0.75)
			:queuecommand("Stop")
		end,
		StopCommand=function(self)
			self:setstate(15):animate(false):diffusealpha(0)
		end,
    },
	
	Def.Sprite {
        Texture=THEME:GetPathG("", "SelectMusic/Cursor 2x1 (doubleres).png"),
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X - 117, SCREEN_CENTER_Y - 33)
			:SetTextureFiltering(false):diffusealpha(0):animate(false)
		end,
		CurrentSongChangedMessageCommand=function(self)
			self:stoptweening():diffusealpha(0)
			:sleep(1.625)
			:diffusealpha(1)
			:sleep(0.1)
			:diffusealpha(0)
		end,
    },
	
	Def.Sprite {
        Texture=THEME:GetPathG("", "SelectMusic/Cursor 2x1 (doubleres).png"),
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X - 117, SCREEN_CENTER_Y - 33)
			:SetTextureFiltering(false):diffusealpha(0):animate(true):SetAllStateDelays(0.15)
		end,
		CurrentSongChangedMessageCommand=function(self)
			self:stoptweening():diffusealpha(0):sleep(1.65):diffusealpha(1)
		end,
    },
	
	Def.Sprite {
		Texture=THEME:GetPathG("", "SelectMusic/New.png"),
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X - 139, SCREEN_CENTER_Y - 6.5):SetTextureFiltering(false)
			-- Disabled for now, will return to this later alongside CD titles
			:diffusealpha(0)
		end,
	},
}

return t
