--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local function run_operator(self,op,sockets,addSockets)
	sockets = sockets or {}
	local node = self:GetNode()
	for i,socket in ipairs(sockets) do
		if(util.get_type_name(socket) ~= "Socket") then
			sockets[i] = cycles.Socket(socket)
			socket = sockets[i]
		end
		node = node or socket:GetNode()
	end
	if(node == nil) then error("Currently not implemented for concrete types!") end
	local parent = node:GetParent()
	if(parent == nil) then return end
	local node = parent:AddNode(op)
	self:Link(node,"value1")
	for i,socket in ipairs(sockets) do
		socket:Link(node,"value" .. (i +1))
	end
	if(addSockets ~= nil) then
		for identifier,socket in pairs(addSockets) do
			socket:Link(node,identifier)
		end
	end
	return node:GetPrimaryOutputSocket()
end

-- not
cycles.Node.logic_not = {
	IN_VALUE1 = "value1",
	IN_VALUE2 = "value2",
	OUT_VALUE = "value"
}
cycles.NODE_NOT = cycles.register_node("not",function(desc)
	local inValue1 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_not.IN_VALUE1,0)
	local inValue2 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_not.IN_VALUE2,0)
	local outValue = desc:RegisterOutput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_not.OUT_VALUE)
	desc:SetPrimaryOutputSocket(outValue)

	local gt = inValue1:GreaterThan(inValue2)
	local lt = gt:LessThan(1.0)

	desc:Link(lt:GetPrimaryOutputSocket(),outValue)
end)
function cycles.Socket:Not() return run_operator(self,cycles.NODE_NOT) end

-- or
cycles.Node.logic_or = {
	IN_VALUE1 = "value1",
	IN_VALUE2 = "value2",
	OUT_VALUE = "value"
}
cycles.NODE_OR = cycles.register_node("or",function(desc)
	local inValue1 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_or.IN_VALUE1,0)
	local inValue2 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_or.IN_VALUE2,0)
	local outValue = desc:RegisterOutput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_or.OUT_VALUE)
	desc:SetPrimaryOutputSocket(outValue)

	local gt1 = inValue1:GreaterThan(0.0)
	local gt2 = inValue2:GreaterThan(0.0)
	local add = desc:AddNode(cycles.NODE_MATH)
	gt1:Link(add,cycles.Node.math.IN_VALUE1)
	gt2:Link(add,cycles.Node.math.IN_VALUE2)
	add:SetProperty(cycles.Node.math.IN_TYPE,cycles.Node.math.TYPE_ADD)
	add:SetProperty(cycles.Node.math.IN_USE_CLAMP,true)

	desc:Link(add:GetPrimaryOutputSocket(),outValue)
end)
function cycles.Socket:Or(socket) return run_operator(self,cycles.NODE_OR,{socket}) end

-- and
cycles.Node.logic_and = {
	IN_VALUE1 = "value1",
	IN_VALUE2 = "value2",
	OUT_VALUE = "value"
}
cycles.NODE_AND = cycles.register_node("and",function(desc)
	local inValue1 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_and.IN_VALUE1,0)
	local inValue2 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_and.IN_VALUE2,0)
	local outValue = desc:RegisterOutput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_and.OUT_VALUE)
	desc:SetPrimaryOutputSocket(outValue)

	local gt1 = inValue1:GreaterThan(0.0)
	local gt2 = inValue2:GreaterThan(0.0)
	local mul = desc:AddNode(cycles.NODE_MATH)
	gt1:Link(mul,cycles.Node.math.IN_VALUE1)
	gt2:Link(mul,cycles.Node.math.IN_VALUE2)
	mul:SetProperty(cycles.Node.math.IN_TYPE,cycles.Node.math.TYPE_MULTIPLY)
	mul:SetProperty(cycles.Node.math.IN_USE_CLAMP,true)

	desc:Link(mul:GetPrimaryOutputSocket(),outValue)
end)
function cycles.Socket:And(socket) return run_operator(self,cycles.NODE_AND,{socket}) end

-- nor
cycles.Node.logic_nor = {
	IN_VALUE1 = "value1",
	IN_VALUE2 = "value2",
	OUT_VALUE = "value"
}
cycles.NODE_NOR = cycles.register_node("nor",function(desc)
	local inValue1 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_nor.IN_VALUE1,0)
	local inValue2 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_nor.IN_VALUE2,0)
	local outValue = desc:RegisterOutput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_nor.OUT_VALUE)
	desc:SetPrimaryOutputSocket(outValue)

	desc:Link(inValue1:Or(inValue2):Not(),outValue)
end)
function cycles.Socket:Nor(socket) return run_operator(self,cycles.NODE_NOR,{socket}) end

-- nand
cycles.Node.logic_nand = {
	IN_VALUE1 = "value1",
	IN_VALUE2 = "value2",
	OUT_VALUE = "value"
}
cycles.NODE_NAND = cycles.register_node("nand",function(desc)
	local inValue1 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_nand.IN_VALUE1,0)
	local inValue2 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_nand.IN_VALUE2,0)
	local outValue = desc:RegisterOutput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_nand.OUT_VALUE)
	desc:SetPrimaryOutputSocket(outValue)

	desc:Link(inValue1:And(inValue2):Not(),outValue)
end)
function cycles.Socket:Nand(socket) return run_operator(self,cycles.NODE_NAND,{socket}) end

-- xor
cycles.Node.logic_xor = {
	IN_VALUE1 = "value1",
	IN_VALUE2 = "value2",
	OUT_VALUE = "value"
}
cycles.NODE_XOR = cycles.register_node("xor",function(desc)
	local inValue1 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_xor.IN_VALUE1,0)
	local inValue2 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_xor.IN_VALUE2,0)
	local outValue = desc:RegisterOutput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_xor.OUT_VALUE)
	desc:SetPrimaryOutputSocket(outValue)

	local land1 = inValue1:Not():And(inValue2)
	local land2 = inValue1:And(inValue2:Not())
	local lor = land1:Or(land2)
	desc:Link(lor,outValue)
end)
function cycles.Socket:Xor(socket) return run_operator(self,cycles.NODE_XOR,{socket}) end

-- half-adder
cycles.Node.logic_half_adder = {
	IN_VALUE1 = "value1",
	IN_VALUE2 = "value2",
	OUT_VALUE1 = "value1",
	OUT_VALUE2 = "value2"
}
cycles.NODE_HALF_ADDER = cycles.register_node("half_adder",function(desc)
	local inValue1 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_half_adder.IN_VALUE1,0)
	local inValue2 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_half_adder.IN_VALUE2,0)
	local outValue1 = desc:RegisterOutput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_half_adder.OUT_VALUE1)
	local outValue2 = desc:RegisterOutput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_half_adder.OUT_VALUE2)

	desc:Link(inValue1:Xor(inValue2),outValue1)
	desc:Link(inValue1:And(inValue2),outValue2)
end)

-- full-adder
cycles.Node.logic_full_adder = {
	IN_VALUE1 = "value1",
	IN_VALUE2 = "value2",
	IN_VALUE3 = "value3",
	OUT_VALUE1 = "value1",
	OUT_VALUE2 = "value2"
}
cycles.NODE_FULL_ADDER = cycles.register_node("full_adder",function(desc)
	local inValue1 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_full_adder.IN_VALUE1,0)
	local inValue2 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_full_adder.IN_VALUE2,0)
	local inValue3 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_full_adder.IN_VALUE3,0)
	local outValue1 = desc:RegisterOutput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_full_adder.OUT_VALUE1)
	local outValue2 = desc:RegisterOutput(cycles.Socket.TYPE_FLOAT,cycles.Node.logic_full_adder.OUT_VALUE2)

	local lxor1 = inValue1:Xor(inValue2)
	local lxor2 = lxor1:Xor(inValue3)
	local land1 = inValue3:And(lxor1)
	local land2 = inValue2:And(inValue1)
	local lor = land1:Or(land2)

	desc:Link(lxor2,outValue1)
	desc:Link(lor,outValue2)
end)

cycles.Node.equal = {
	IN_VALUE1 = "value1",
	IN_VALUE2 = "value2",
	IN_TOLERANCE = "tolerance",
	OUT_VALUE = "value"
}
cycles.NODE_EQUAL = cycles.register_node("equal",function(desc)
	local inValue1 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.equal.IN_VALUE1,0)
	local inValue2 = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.equal.IN_VALUE2,0)
	local inTolerance = desc:RegisterInput(cycles.Socket.TYPE_FLOAT,cycles.Node.equal.IN_TOLERANCE,0.001)
	local outValue = desc:RegisterOutput(cycles.Socket.TYPE_FLOAT,cycles.Node.equal.OUT_VALUE)
	desc:SetPrimaryOutputSocket(outValue)

	local diff = inValue1 -inValue2

	local gt = diff:GreaterThan(-inTolerance)
	local lt = diff:LessThan(inTolerance)
	gt:And(lt):Link(outValue)
end)
function cycles.Socket:IsEqualTo(socket,tolerance) return run_operator(self,cycles.NODE_EQUAL,{socket},{[cycles.Node.equal.IN_TOLERANCE] = tolerance}) end
