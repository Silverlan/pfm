util.register_class("sfm.Scene")
include("base_element.lua")
include("scene")

function sfm.Scene:__init(dmxData)
	local elements = dmxData:GetElements()
	self.m_sessions = {}
	for _,el in ipairs(elements) do
		if(el:GetName() == "session") then
			table.insert(self.m_sessions,sfm.Session(el))
		end
	end
end

function sfm.Scene:GetSessions() return self.m_sessions end
