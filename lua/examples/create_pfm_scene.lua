-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local projectFileName = "projects/test_project.pfmp_b" -- Replace this with your PFM project

local ent = ents.create("pfm_project_manager")
ent:Spawn()
local projectManagerC = ent:GetComponent(ents.COMPONENT_PFM_PROJECT_MANAGER)
projectManagerC:SetProjectFile(projectFileName)
projectManagerC:Start()
