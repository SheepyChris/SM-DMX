return Def.ActorFrame {
	LoadActor("TimerLabel (doubleres).png")..{
		OnCommand=function(self)
			self:SetTextureFiltering(false):addy(-27)
		end,
	}
}
