--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

-- test
unirender.Node.test = {
	IN_VALUE = "value1",
	OUT_VALUE = "value"
}
unirender.NODE_TEST = unirender.register_node("test",function(desc)
	local inValue1 = desc:RegisterInput(unirender.Socket.TYPE_FLOAT,unirender.Node.test.IN_VALUE,0)
	local outValue = desc:RegisterOutput(unirender.Socket.TYPE_FLOAT,unirender.Node.test.OUT_VALUE)
	desc:SetPrimaryOutputSocket(outValue)
	desc:Link(inValue1,outValue)
end)

-- test2
unirender.Node.test2 = {
	IN_VALUE = "value1",
	OUT_VALUE = "value"
}
unirender.NODE_TEST2 = unirender.register_node("test2",function(desc)
	local inValue1 = desc:RegisterInput(unirender.Socket.TYPE_FLOAT,unirender.Node.test2.IN_VALUE,0)
	local outValue = desc:RegisterOutput(unirender.Socket.TYPE_FLOAT,unirender.Node.test2.OUT_VALUE)
	desc:SetPrimaryOutputSocket(outValue)
	desc:Link(inValue1 *2,outValue)
end)

-- test3
unirender.Node.test3 = {
	IN_VALUE = "value1",
	OUT_VALUE = "value"
}
unirender.NODE_TEST3 = unirender.register_node("test3",function(desc)
	local inValue1 = desc:RegisterInput(unirender.Socket.TYPE_FLOAT,unirender.Node.test3.IN_VALUE,0)
	local outValue = desc:RegisterOutput(unirender.Socket.TYPE_FLOAT,unirender.Node.test3.OUT_VALUE)
	desc:SetPrimaryOutputSocket(outValue)

	local n = desc:AddConstantNode(0.5)
	desc:Link(n,outValue)
end)

-- test4
unirender.Node.test4 = {
	IN_VALUE = "value1",
	OUT_VALUE = "value"
}
unirender.NODE_TEST4 = unirender.register_node("test4",function(desc)
	local inValue1 = desc:RegisterInput(unirender.Socket.TYPE_FLOAT,unirender.Node.test4.IN_VALUE,0)
	local outValue = desc:RegisterOutput(unirender.Socket.TYPE_FLOAT,unirender.Node.test4.OUT_VALUE)
	desc:SetPrimaryOutputSocket(outValue)

	local n = desc:AddConstantNode(0.5) *inValue1
	desc:Link(n,outValue)
end)

-- test5
unirender.Node.test5 = {
	IN_VALUE = "value1",
	OUT_VALUE = "value"
}
unirender.NODE_TEST5 = unirender.register_node("test5",function(desc)
	local inValue1 = desc:RegisterInput(unirender.Socket.TYPE_STRING,unirender.Node.test5.IN_VALUE,unirender.get_texture_path("error"))
	local outValue = desc:RegisterOutput(unirender.Socket.TYPE_COLOR,unirender.Node.test5.OUT_VALUE)
	desc:SetPrimaryOutputSocket(outValue)

	local nodeAlbedo = desc:AddTextureNode(inValue1)
	desc:Link(nodeAlbedo:GetPrimaryOutputSocket(),outValue)
end)

-- test6
unirender.Node.test6 = {
	IN_VALUE = "value1",
	OUT_VALUE = "value"
}
unirender.NODE_TEST6 = unirender.register_node("test6",function(desc)
	local inValue1 = desc:RegisterInput(unirender.Socket.TYPE_FLOAT,unirender.Node.test6.IN_VALUE,0)
	local outValue = desc:RegisterOutput(unirender.Socket.TYPE_FLOAT,unirender.Node.test6.OUT_VALUE)
	desc:SetPrimaryOutputSocket(outValue)

	desc:Link(inValue1,outValue)
end)

unirender.Node.test.test = function(desc,case)
	if(case == 0) then
		-- Expected result: half-translucency
		local c = desc:AddNode(unirender.NODE_TEST)
		unirender.Socket(0.5):Link(c,unirender.Node.const.IN_VALUE)
		return c:GetPrimaryOutputSocket()
	elseif(case == 1) then
		-- Expected result: half-translucency
		local n = desc:AddConstantNode(0.5)
		local c = desc:AddNode(unirender.NODE_TEST)
		n:Link(c,unirender.Node.const.IN_VALUE)
		return c:GetPrimaryOutputSocket()
	elseif(case == 2) then
		-- Expected result: half-translucency
		local c = desc:AddNode(unirender.NODE_TEST)
		c:SetProperty(unirender.Node.test.IN_VALUE,0.5)
		return c:GetPrimaryOutputSocket()
	elseif(case == 3) then
		-- Expected result: fully opaque
		local c = desc:AddNode(unirender.NODE_TEST2)
		c:SetProperty(unirender.Node.test2.IN_VALUE,0.5)
		return c:GetPrimaryOutputSocket()
	elseif(case == 4) then
		-- Expected result: half-translucency
		local c = desc:AddNode(unirender.NODE_TEST3)
		c:SetProperty(unirender.Node.test3.IN_VALUE,0.5)
		return c:GetPrimaryOutputSocket()
	elseif(case == 5) then
		-- Expected result: half-translucency
		return (((unirender.Socket(1) +12) *2) -25) *0.5
	elseif(case == 6) then
		-- Expected result: half-translucency
		local n = desc:AddConstantNode(1)
		return (((n +12) *2) -25) *desc:AddConstantNode(0.5)
	elseif(case == 7) then
		-- Expected result: quarter-translucency
		local c = desc:AddNode(unirender.NODE_TEST4)
		c:SetProperty(unirender.Node.test4.IN_VALUE,0.25)
		return c:GetPrimaryOutputSocket()
	elseif(case == 8) then
		-- Expected result: quarter-translucency
		local c = desc:AddNode(unirender.NODE_TEST5)
		c:SetProperty(unirender.Node.test5.IN_VALUE,unirender.get_texture_path("white"))
		return c:GetPrimaryOutputSocket()
	elseif(case == 9) then
		-- Expected result: quarter-translucency
		local c = desc:AddNode(unirender.NODE_TEST6)
		--c:SetProperty(unirender.Node.test6.IN_VALUE,1)
		return c:GetPrimaryOutputSocket()
	end
end

unirender.Node.test.test_output = function(desc,outputNode,case)
	local principled = desc:AddNode(unirender.NODE_PRINCIPLED_BSDF)
	unirender.Node.test.test(desc,0):Link(principled,unirender.Node.principled_bsdf.IN_ALPHA)
	principled:GetPrimaryOutputSocket():Link(outputNode,unirender.Node.output.IN_SURFACE)
end

