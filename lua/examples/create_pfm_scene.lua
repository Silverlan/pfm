-- This script will instantiate and start the specified project in the game world
local projectFileName = "projects/test_project.pfmp_b" -- Replace this with your PFM project

local ent = ents.create("pfm_project_manager")
ent:Spawn()
local projectManagerC = ent:GetComponent(ents.COMPONENT_PFM_PROJECT_MANAGER)
projectManagerC:SetProjectFile(projectFileName)
projectManagerC:Start()
