pfm = pfm or {}

pfm.LOG_SEVERITY_NORMAL = 0
pfm.LOG_SEVERITY_WARNING = 1
pfm.LOG_SEVERITY_ERROR = 2
pfm.LOG_SEVERITY_CRITICAL = 3

local MAX_LOG_CATEGORIES = 30
local g_enabledCategories = bit.lshift(1,MAX_LOG_CATEGORIES) -1 -- Enable all call categories by default
pfm.is_log_category_enabled = function(categories)
	return bit.band(categories,g_enabledCategories) ~= 0
end

pfm.set_log_category_enabled = function(category,enabled)
	g_enabledCategories = math.set_flag_enabled(g_enabledCategories,category,enabled)
end

pfm.log = function(msg,categories,severity)
	severity = severity or pfm.LOG_SEVERITY_NORMAL
	categories = categories or 0
	if(pfm.is_log_category_enabled(categories) == false) then return false end
	if(severity == pfm.LOG_SEVERITY_NORMAL) then console.print_messageln(msg)
	elseif(severity == pfm.LOG_SEVERITY_WARNING) then console.print_warning(msg)
	elseif(severity == pfm.LOG_SEVERITY_ERROR) then console.print_error(msg)
	elseif(severity == pfm.LOG_SEVERITY_CRITICAL) then console.print_error(msg)
	else return false end
	return true
end

local g_logCategories = {}
pfm.register_log_category = function(name)
	local catName = "LOG_CATEGORY_" .. name:upper()
	if(pfm[catName] ~= nil) then return pfm[catName] end
	if(#g_logCategories >= MAX_LOG_CATEGORIES) then
		console.print_warning("Unable to register log category '" .. name .. "': Max log category count of " .. MAX_LOG_CATEGORIES .. " has been exceeded!")
		return -1
	end
	local catId = #g_logCategories
	table.insert(g_logCategories,{
		name = name
	})
	pfm[catName] = catId
	return catId
end

pfm.register_log_category("pfm")
