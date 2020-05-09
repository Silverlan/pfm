--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

-- Converts a SFM math expression to Lua
sfm.convert_math_expression_to_pragma = function(expr,varNames)
	local fns = {
		-- List of functions available in SFM
		{"dtor",1},
		{"rtod",1},
		{"abs",1},
		{"floor",1},
		{"ceiling",1},
		{"round",1},
		{"sgn",1},
		{"sqr",1},
		{"sqrt",1},
		{"sin",1},
		{"asin",1},
		{"cos",1},
		{"acos",1},
		{"tan",1},
		{"exp",1},
		{"log",1},
		{"min",2},
		{"max",2},
		{"pow",2},
		{"inrange",3},
		{"clamp",3},
		{"ramp",3},
		{"lerp",3},
		{"cramp",3},
		{"clerp",3},
		{"elerp",3},
		{"noise",3},
		{"rescale",5},
		{"crescale",5}
	}
	local fnToPragma = {
		-- Translation to Pragma equivalents (Lua)
		["dtor"] = "math.rad",
		["rtod"] = "math.deg",
		["abs"] = "math.abs",
		["floor"] = "math.floor",
		["ceiling"] = "math.ceil",
		["round"] = "math.round",
		["sgn"] = "math.sign",
		["sqr"] = "pfm.math.sqr",
		["sqrt"] = "math.sqrt",
		["sin"] = "pfm.math.sin_deg",
		["asin"] = "pfm.math.asin_deg",
		["cos"] = "pfm.math.cos_deg",
		["acos"] = "pfm.math.acos_deg",
		["tan"] = "pfm.math.tan_deg",
		["exp"] = "math.exp",
		["log"] = "math.log",
		["min"] = "math.min",
		["max"] = "math.max",
		["atan2"] = "math.atan2", -- TODO: Confirm if this is correct
		["pow"] = "math.pow",
		["inrange"] = "pfm.math.in_range",
		["clamp"] = "math.clamp",
		["ramp"] = "pfm.math.ramp",
		["lerp"] = "pfm.math.lerp",
		["cramp"] = "pfm.math.cramp",
		["clerp"] = "pfm.math.clerp",
		["elerp"] = "pfm.math.elerp",
		["noise"] = "pfm.math.noise",
		["rescale"] = "pfm.math.rescale",
		["crescale"] = "pfm.math.crescale"
	}
	local res,errMsg = math.parse_expression(expr,fns,varNames)

	local fnMap = {}
	for _,fnData in ipairs(fns) do
		fnMap[fnData[1]] = fnData[2]
	end

	if(res == false) then
		console.print_warning("Unable to parse math expression '" .. expr .. "': " .. errMsg)
		return ""
	end

	local function parse_op(i)
		local expr = res[i]
		if(expr.code == math.EXPRESSION_CODE_VALUE) then
			local identifier = expr.identifier
			if(identifier:sub(1,1) == "+") then identifier = identifier:sub(2) end -- Lua doesn't support unary +
			if(string.is_number(identifier) == false) then
				-- Variable name; We'll look it up in the expression operator object, which is passed as 'self'
				identifier = "self:GetProperty([[" .. identifier .. "]]):GetValue()"
			end
			return identifier,i
		end
		if(expr.code == math.EXPRESSION_CODE_INFIX_OPERATOR) then
			local v
			v,i = parse_op(i -1)

			local identifier = expr.identifier
			return identifier .. v,i
		end
		if(expr.code == math.EXPRESSION_CODE_BINARY_OPERATOR) then
			local l,r
			r,i = parse_op(i -1)
			l,i = parse_op(i -1)

			local identifier = expr.identifier
			if(identifier == "!=") then identifier = "~="
			elseif(identifier == "&&") then identifier = "and"
			elseif(identifier == "||") then identifier = "or" end
			return "(" .. l .. identifier .. r .. ")",i
		end
		if(expr.code == math.EXPRESSION_CODE_FUNCTION) then
			local numArgs = fnMap[expr.identifier]
			
			local targs = {}
			while(numArgs > 0) do
				local arg
				arg,i = parse_op(i -1)
				numArgs = numArgs -1

				table.insert(targs,arg)
			end

			local identifier = fnToPragma[expr.identifier]

			local args = ""
			local first = true
			for _,arg in ipairs(targs) do
				if(first == false) then arg = arg .. ","
				else first = false end
				args = arg .. args
			end
			return identifier .. "(" .. args .. ")",i
		end
		if(expr.code == math.EXPRESSION_CODE_TERNARY_ENDIF) then
			local a,b,c
			a,i = parse_op(i -1)
			b,i = parse_op(i -1)
			c,i = parse_op(i -1)
			return "((" .. c .. ") and (" .. b .. ") or (" .. a .. "))",i
		end
		if(expr.code == math.EXPRESSION_CODE_TERNARY_IF or expr.code == math.EXPRESSION_CODE_TERNARY_ELSE) then
			local v
			v,i = parse_op(i -1)
			return v,i
		end
		console.print_warning("Unsupported math expression of type " .. expr.code .. "!")
		return "",i
	end
	return parse_op(#res)
end
