--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

-- Converts a SFM math expression to exprtk
sfm.convert_math_expression_to_pragma = function(exprFull, variables)
	local fns = {
		-- List of functions available in SFM
		{ "dtor", 1 },
		{ "rtod", 1 },
		{ "abs", 1 },
		{ "floor", 1 },
		{ "ceiling", 1 },
		{ "round", 1 },
		{ "sgn", 1 },
		{ "sqr", 1 },
		{ "sqrt", 1 },
		{ "sin", 1 },
		{ "asin", 1 },
		{ "cos", 1 },
		{ "acos", 1 },
		{ "tan", 1 },
		{ "exp", 1 },
		{ "log", 1 },
		{ "min", 2 },
		{ "max", 2 },
		{ "pow", 2 },
		{ "inrange", 3 },
		{ "clamp", 3 },
		{ "ramp", 3 },
		{ "lerp", 3 },
		{ "cramp", 3 },
		{ "clerp", 3 },
		{ "elerp", 3 },
		{ "noise", 3 },
		{ "rescale", 5 },
		{ "crescale", 5 },
	}
	local fnToPragma = {
		-- Translation to Pragma equivalents (exprtk)
		["dtor"] = "deg2rad",
		["rtod"] = "rad2deg",
		["abs"] = "abs",
		["floor"] = "floor",
		["ceiling"] = "ceil",
		["round"] = "round",
		["sgn"] = "sgn",
		["sqr"] = "sqr",
		["sqrt"] = "sqrt",
		["sin"] = "sin",
		["asin"] = "asin",
		["cos"] = "cos",
		["acos"] = "acos",
		["tan"] = "tan",
		["exp"] = "exp",
		["log"] = "log",
		["min"] = "min",
		["max"] = "max",
		["atan2"] = "atan2", -- TODO: Confirm if this is correct
		["pow"] = "pow",
		["inrange"] = "inrange",
		["clamp"] = "clamp",
		["ramp"] = "ramp",
		["lerp"] = "lerp",
		["cramp"] = "cramp",
		["clerp"] = "clerp",
		["elerp"] = "elerp",
		["noise"] = "noise",
		["rescale"] = "rescale",
		["crescale"] = "crescale",
	}
	local fnTrig = {
		["sin"] = true,
		["asin"] = true,
		["cos"] = true,
		["acos"] = true,
		["tan"] = true, -- These expect degree as argument in SFM, but radian in exprtk, so they'll have to be wrapped
		-- For some reason atan2 in SFM appears to be an exception to this rule and does *not* expect degree (needs to be confirmed!)
	}
	local varNames = {}
	for varName, _ in pairs(variables) do
		table.insert(varNames, varName)
	end
	local builtInVariables = {
		["time"] = true,
		["timeIndex"] = true,
		["value"] = true,
	}
	local res, errMsg = math.parse_expression(exprFull, fns, varNames)

	local fnMap = {}
	for _, fnData in ipairs(fns) do
		fnMap[fnData[1]] = fnData[2]
	end

	if res == false then
		console.print_warning("Unable to parse math expression '" .. expr .. "': " .. errMsg)
		return ""
	end

	local function parse_op(i)
		local expr = res[i]
		if expr.code == math.EXPRESSION_CODE_VALUE then
			local identifier = expr.identifier
			if identifier:sub(1, 1) == "+" then
				identifier = identifier:sub(2)
			end -- Remove unary +
			if string.is_number(identifier) == false and builtInVariables[identifier] ~= true then
				if variables[identifier] ~= nil then
					identifier = variables[identifier]
				else
					console.print_warning(
						"Expression operator '"
							.. exprFull
							.. "' uses unknown variable '"
							.. identifier
							.. "' (or unsupported variable type)! This expression will not work."
					)
				end
			end
			return identifier, i
		end
		if expr.code == math.EXPRESSION_CODE_INFIX_OPERATOR then
			local v
			v, i = parse_op(i - 1)

			local identifier = expr.identifier
			return identifier .. v, i
		end
		if expr.code == math.EXPRESSION_CODE_BINARY_OPERATOR then
			local l, r
			r, i = parse_op(i - 1)
			l, i = parse_op(i - 1)

			local identifier = expr.identifier
			if identifier == "!=" then
				identifier = "!="
			elseif identifier == "&&" then
				identifier = "and"
			elseif identifier == "||" then
				identifier = "or"
			end
			return "(" .. l .. identifier .. r .. ")", i
		end
		if expr.code == math.EXPRESSION_CODE_FUNCTION then
			local numArgs = fnMap[expr.identifier]

			local targs = {}
			while numArgs > 0 do
				local arg
				arg, i = parse_op(i - 1)
				numArgs = numArgs - 1

				table.insert(targs, arg)
			end

			local identifier = fnToPragma[expr.identifier]

			local args = ""
			local first = true
			for _, arg in ipairs(targs) do
				if first == false then
					arg = arg .. ","
				else
					first = false
				end
				args = arg .. args
			end
			if fnTrig[identifier] == true then
				args = "deg2rad(" .. args .. ")"
			end
			return identifier .. "(" .. args .. ")", i
		end
		if expr.code == math.EXPRESSION_CODE_TERNARY_ENDIF then
			local a, b, c
			a, i = parse_op(i - 1)
			b, i = parse_op(i - 1)
			c, i = parse_op(i - 1)
			return "((" .. c .. ") and (" .. b .. ") or (" .. a .. "))", i
		end
		if expr.code == math.EXPRESSION_CODE_TERNARY_IF or expr.code == math.EXPRESSION_CODE_TERNARY_ELSE then
			local v
			v, i = parse_op(i - 1)
			return v, i
		end
		console.print_warning("Unsupported math expression of type " .. expr.code .. "!")
		return "", i
	end
	return parse_op(#res)
end
