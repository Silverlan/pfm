--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.RetargetRig.BoneRemapper")
function ents.RetargetRig.BoneRemapper:__init(skeletonSrc,refSrc,skeletonDst,refDst,nameWeight,depthWeight,branchLengthWeight,distWeight,kindredWeight)
	self.m_nameWeight = nameWeight or 1.0
	self.m_depthWeight = depthWeight or 0.2
	self.m_branchLengthWeight = branchLengthWeight or 0.2
	self.m_distWeight = distWeight or 0.4
	self.m_kindredWeight = kindredWeight or 1.5
	--[[
	self.m_nameWeight = nameWeight or 1.0
	self.m_depthWeight = depthWeight or 0.2
	self.m_branchLengthWeight = branchLengthWeight or 0.2
	self.m_distWeight = distWeight or 0.4
	self.m_kindredWeight = kindredWeight or 1.5
	]]

	self.m_skeletonSrc = skeletonSrc
	self.m_referenceSrc = refSrc

	self.m_skeletonDst = skeletonDst
	self.m_referenceDst = refDst
end
function ents.RetargetRig.BoneRemapper:CollectSkeletonData(skeleton)
	local boneData = {}
	for _,bone in ipairs(skeleton:GetBones()) do
		boneData[bone:GetID()] = {
			bone = bone,
			depth = 0,
			branchLength = 0
		}
	end
	local maxDepth = 0
	local function update_depth_values(bone,depth)
		local branchLength = 0
		for boneId,child in pairs(bone:GetChildren()) do
			branchLength = math.max(branchLength,update_depth_values(child,depth +1))
		end
		boneData[bone:GetID()].branchLength = branchLength
		boneData[bone:GetID()].depth = depth
		maxDepth = math.max(maxDepth,depth)
		return branchLength +1
	end
	for boneId,bone in pairs(skeleton:GetRootBones()) do
		update_depth_values(bone,0)
	end
	if(maxDepth > 0) then
		for boneId,data in pairs(boneData) do
			data.depth = data.depth /maxDepth
		end
	end
	return boneData
end
function ents.RetargetRig.BoneRemapper:CollectRelationData(boneData0,boneData1)
	local ref0 = self.m_referenceSrc
	local ref1 = self.m_referenceDst
	for boneId0,data0 in pairs(boneData0) do
		local pose0 = ref0:GetBonePose(boneId0)
		if(pose0 ~= nil) then
			local origin0 = pose0:GetOrigin()
			data0.targetBones = {}
			local maxDist = 0
			local maxBranchLengthDistance = 0
			for boneId1,data1 in pairs(boneData1) do
				local sim = string.calc_levenshtein_similarity(data0.bone:GetName():lower(),data1.bone:GetName():lower())
				local pose1 = ref1:GetBonePose(boneId1)
				if(pose1 ~= nil) then
					local distance = origin0:Distance(pose1:GetOrigin())
					local branchLengthDistance = math.abs(data1.branchLength -data0.branchLength)
					local depthDistance = math.abs(data1.depth -data0.depth)
					table.insert(data0.targetBones,{
						bone = data1.bone,
						similarity = sim,
						distance = distance,
						branchLengthDistance = branchLengthDistance,
						depthDistance = depthDistance
					})
					maxDist = math.max(maxDist,distance)
					maxBranchLengthDistance = math.max(maxBranchLengthDistance,branchLengthDistance)
				end
			end
			for _,data in ipairs(data0.targetBones) do
				data.distanceFactor = 1.0 -data.distance /maxDist
				data.branchLengthFactor = 1.0 -data.branchLengthDistance /maxBranchLengthDistance
				data.depthDistanceFactor = 1.0 -data.depthDistance

				local sim = data.similarity
				-- Increase the chance if this bone pair has been tagged as a match in the past
				if(ents.RetargetRig.Rig.is_bone_relation_in_cache(data0.bone:GetName(),data.bone:GetName())) then sim = 1.0 end

				local weight = sim *self.m_nameWeight +
					data.branchLengthFactor *self.m_branchLengthWeight +
					data.distanceFactor *self.m_distWeight +
					data.depthDistanceFactor *self.m_depthWeight

				data.weight = weight
			end
			table.sort(data0.targetBones,function(a,b) return a.weight > b.weight end)
		end
	end
end
function ents.RetargetRig.BoneRemapper:AutoRemap()
	local boneData0 = self:CollectSkeletonData(self.m_skeletonSrc)
	local boneData1 = self:CollectSkeletonData(self.m_skeletonDst)
	self:CollectRelationData(boneData0,boneData1)

	-- We'll iterate our bone tree and check if the individual branches match
	-- with the branches of the target skeleton. The probability of the bones that
	-- have a matching branch is increased; if the branch doesn't match, the probability is decreased.
	local function check_hierarchy_match(bone)
		local mostLikelyCandidate = boneData0[bone:GetID()].targetBones[1].bone
		local parent = bone:GetParent()
		local n = 0
		local nMatches = 0
		while(parent ~= nil) do
			n = n +1
			local parentMostLikelyCandidate = boneData0[parent:GetID()].targetBones[1].bone
			local isParentCandidateAncestorOfCandidate = false
			local isAncestor = parentMostLikelyCandidate:IsAncestorOf(mostLikelyCandidate)
			if(isAncestor) then nMatches = nMatches +1 end
			--if(bone:GetName() == "Bip01 R Finger12") then print(parentMostLikelyCandidate:GetName(),)
			parent = parent:GetParent()
		end
		if(n > 0) then
			local match = nMatches /n
			local matchFactor = (match /0.7) -- If we had less than 70% matches we'll decrease the probability, otherwise increase
			--print("Match: ",matchFactor)
			boneData0[bone:GetID()].targetBones[1].weight = boneData0[bone:GetID()].targetBones[1].weight *matchFactor
			table.sort(boneData0[bone:GetID()].targetBones,function(a,b) return a.weight > b.weight end)
		end

		for boneId,child in pairs(bone:GetChildren()) do
			check_hierarchy_match(child)
		end
	end
	for boneId,bone in pairs(self.m_skeletonSrc:GetRootBones()) do
		check_hierarchy_match(bone)
	end


--[[
iterate through hierarchy
foreach bone a -> grab most likely candidate b
	go backwards through hierarchy of a with parent c, grab most likely candidate d
		if d exists in parent hierarchy of b, increase chance
		otherwise decrease
		-> average as factor?
]]













	local probabilityTable = {}
	for boneId,data in pairs(boneData0) do
		for i,tbData in ipairs(data.targetBones) do
			table.insert(probabilityTable,{boneId,tbData.bone:GetID(),tbData.weight})
		end
	end
	table.sort(probabilityTable,function(a,b) return a[3] > b[3] end)

	local boneMappingData = {}
	local acquired = {}
	for i=1,#probabilityTable do
		local probBoneData = probabilityTable[i]
		if(boneMappingData[probBoneData[1]] == nil and acquired[probBoneData[2]] == nil) then
			-- print("Adding match: ",self.m_skeletonSrc:GetBone(probBoneData[1]):GetName(),"->",self.m_skeletonDst:GetBone(probBoneData[2]):GetName(),probBoneData[3])
			boneMappingData[probBoneData[1]] = probBoneData[2]
			probBoneData[3] = math.huge
			acquired[probBoneData[2]] = true

			-- If these two bones match, it's likely that their direct children (and parents) match as well,
			-- so we'll increase their chances. This will only affect bones that haven't been processed yet!
			--[[local boneSrc = self.m_skeletonSrc:GetBone(probBoneData[1])
			local boneDst = self.m_skeletonDst:GetBone(probBoneData[2])
			local boneSrcParent = boneSrc:GetParent()
			local boneDstParent = boneDst:GetParent()
			local probabilityUpdateTable = {}
			if(boneSrcParent ~= nil and boneDstParent ~= nil) then
				probabilityUpdateTable[boneSrcParent:GetID()] = {[boneDstParent:GetID()] = true}
			end

			local boneSrcChildren = boneSrc:GetChildren()
			local boneDstChildren = boneDst:GetChildren()
			if(#boneSrcChildren > 0 and #boneDstChildren > 0) then
				for _,child in ipairs(boneSrcChildren) do
					for _,childOther in ipairs(boneDstChildren) do
						probabilityUpdateTable[child:GetID()] = probabilityUpdateTable[child:GetID()] or {}
						probabilityUpdateTable[child:GetID()][childOther:GetID()] = true
					end
				end
			end
			
			for j=i +1,#probabilityTable do
				local probBoneData = probabilityTable[j]
				if(probabilityUpdateTable[probBoneData[1] ] ~= nil) then
					--print(probBoneData[3],probBoneData[3] *self.m_kindredWeight)

					if(probabilityUpdateTable[probBoneData[1] ][probBoneData[2] ]) then
						probBoneData[3] = probBoneData[3] *self.m_kindredWeight
					else
						probBoneData[3] = probBoneData[3] /self.m_kindredWeight
					end
				end
			end
			table.sort(probabilityTable,function(a,b) return a[3] > b[3] end)]]
		end
	end

	local t = {}
	for k,v in pairs(boneMappingData) do
		t[v] = k
	end

	return t

	--[[
	local boneMappingData = {}
	for boneId,data in pairs(boneData0) do
		for i,tbData in ipairs(data.targetBones) do
			local boneIdTgt = tbData.bone:GetID()
			boneMappingData[boneIdTgt] = boneMappingData[boneIdTgt] or {}
			table.insert(boneMappingData[boneIdTgt],{
				boneId = boneId,
				weight = tbData.weight
			})
		end
	end
	]]

	--[[local boneMappings = {}
	for boneIdTgt,data in pairs(boneMappingData) do
		table.sort(data,function(a,b) return a.weight > b.weight end)
		if(boneIdTgt == 4) then
			print(self.m_skeletonDst:GetBone(boneIdTgt):GetName())
			print(self.m_skeletonSrc:GetBone(data[1].boneId):GetName())
			console.print_table(data)
		end
		boneMappings[data[1].boneId] = boneIdTgt
	end
	return boneMappings]]
end
