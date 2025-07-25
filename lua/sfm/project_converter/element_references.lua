-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.fix_element_references = function(project)
	local root = project:GetUDMRootNode()

	local actors = {}
	root:FindElementsByType(fudm.ELEMENT_TYPE_PFM_ACTOR, actors)

	local componentToActor = {}
	for _, actor in ipairs(actors) do
		for _, c in ipairs(actor:GetComponents():GetTable()) do
			componentToActor[c] = actor
		end
	end

	-- Constraint slaves point to entity model components, but they need to point to the entity instead, so we'll redirect them here
	local constraintSlaves = {}
	root:FindElementsByType(fudm.ELEMENT_TYPE_PFM_CONSTRAINT_SLAVE, constraintSlaves)
	for _, slave in ipairs(constraintSlaves) do
		local target = slave:GetTarget()
		if target ~= nil and componentToActor[target] ~= nil then
			slave:SetTargetAttr(componentToActor[target])
		end
	end
end
