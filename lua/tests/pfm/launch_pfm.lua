include("/tests/base.lua")

tests.queue("pfm_launch", function()
	pfm.launch(nil)
	return true
end)
