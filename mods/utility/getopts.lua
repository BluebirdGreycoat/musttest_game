
-- Interpret the parameters of a command, separating options and arguments.
-- Input: command, param
--   command: name of command
--   param: parameters of command
-- Returns: opts, args
--   opts is a string of option letters, or false on error
--   args is an array with the non-option arguments in order, or an error message
-- Example: for this command line:
--      /command a b -cd e f -g
-- the function would receive:
--      a b -cd e f -g
-- and it would return:
--	"cdg", {"a", "b", "e", "f"}
-- Negative numbers are taken as arguments. Long options (--option) are
-- currently rejected as reserved.
function utility.getopts(command, param)
	local opts = ""
	local args = {}
	for match in param:gmatch("%S+") do
		if match:byte(1) == 45 then -- 45 = '-'
			local second = match:byte(2)
			if second == 45 then
				return false, "Invalid parameters (see /help " .. command .. ")."
			elseif second and (second < 48 or second > 57) then -- 48 = '0', 57 = '9'
				opts = opts .. match:sub(2)
			else
				-- numeric, add it to args
				args[#args + 1] = match
			end
		else
			args[#args + 1] = match
		end
	end
	return opts, args
end
