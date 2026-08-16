
-- Use this function ONLY when calling a Minetest API in
-- a situation where protection interferes!
function protector.enable_protection(enable)
	protector.PROTECTION_ENABLED = enable
end



-- Overrides should only be registered once!
if not protector.overrides_registered then
	protector.overrides_registered = true

	-- Record the old function, we still need it.
	protector.old_is_protected = minetest.is_protected

	function minetest.is_protected(pos, digger, nodename)
		digger = digger or "" -- nil check

		-- Allow protection to be temporarily disabled for API purposes.
		if not protector.PROTECTION_ENABLED then
			return protector.old_is_protected(pos, digger)
		end

		if not protector.can_dig(protector.radius, 1, "", pos, digger, false, 1) then
			-- Slight delay to separate call stacks; hopefully this fixes the rare recursion/crash issue.
			-- Update: it seems to have fixed the rare crashes, there have been no more related to this since some months.
			minetest.after(0, function()
				protector.punish_player(pos, digger)
			end)
			return true
		end

		return protector.old_is_protected(pos, digger)
	end

	-- Called when protection should be checked, but no retaliation should be carried out.
	function minetest.test_protection(pos, digger)
		digger = digger or "" -- nil check

		-- Allow protection to be temporarily disabled for API purposes.
		if not protector.PROTECTION_ENABLED then
			return protector.old_is_protected(pos, digger)
		end

		-- Don't give chat messages. Infolevel 0.
		if not protector.can_dig(protector.radius, 1, "", pos, digger, false, 0) then
			return true
		end

		return protector.old_is_protected(pos, digger)
	end
end
