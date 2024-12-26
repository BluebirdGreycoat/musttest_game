
if not minetest.global_exists("mailgui") then mailgui = {} end
mailgui.modpath = minetest.get_modpath("mailgui")



-- State management table. Used for GUIs.
mailgui.players = mailgui.players or {}

-- List of players who currently have open inbox formspecs.
mailgui.open_inboxes = mailgui.open_inboxes or {}



-- API function for alerting a player that they have mail.
mailgui.alert_player = function(from, pname)
  -- If target player's inbox is open, alert them.
  minetest.after(5, function() -- The delay is useful if player sends mail to themselves.
    minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(from) .. "> sent you mail! A Key is needed to view it.")
    if mailgui.open_inboxes[pname] then
      if mailgui.players[pname] then -- Sanity check.
        local intlive = mailgui.players[pname].live or 'true'
        if intlive == 'true' then
          mailgui.players[pname].infotext = "You received new mail! Press 'Get Mail'."
          mailgui.show_formspec(pname, true) -- Formspec should already be open.
        end
      end
    end
  end)
end



-- Called from the GUI to actually send a message.
-- (This is done by interfacing with the email mod, which handles the database.)
mailgui.send_mail_single = function(from, subject, message, mailto)
  local success, errstr = email.send_mail_single(from, mailto, subject, message)
  if success == true then
    -- This is so the player has a log of their message in chat.
    minetest.chat_send_player(from, "# Server: Email sent to <" .. rename.gpn(mailto) .. ">!")
    minetest.chat_send_player(from, "# Server: Subject: " .. subject)
    local tb = string.split(message, "\n")
    for k, v in ipairs(tb) do
      minetest.chat_send_player(from, "# Server: Message: " .. v)
    end
    
    mailgui.alert_player(from, mailto) -- GUI alert.
  else
    minetest.chat_send_player(from, "# Server: Failed to send mail to <" .. rename.gpn(mailto) .. ">!")
		easyvend.sound_error(from)
  end
  return success, errstr
end

mailgui.send_mail_multi = function(from, subject, message, mailto)
  local success, failure = email.send_mail_multi(from, mailto, subject, message)

  for k, v in ipairs(success) do
    minetest.chat_send_player(from, "# Server: Mail sent to <" .. rename.gpn(v.name) .. ">.")
    mailgui.alert_player(from, v.name) -- GUI alert.
  end
  
  for k, v in ipairs(failure) do
    local reason = "Reason unknown."
    if v.error == "boxfull" then
      reason = "Player's inbox is full."
    elseif v.error == "badplayer" then
      reason = "Player does not exist."
		elseif v.error == "toobig" then
			reason = "Email is too large."
		elseif v.error == "missingdep" then
			reason = "Missing mod dependency."
    end
    minetest.chat_send_player(from, "# Server: Failed to send mail to <" .. rename.gpn(v.name) .. ">! " .. reason)
		easyvend.sound_error(from)
  end
  
  -- This is so the player has a log of their message in chat.
  minetest.chat_send_player(from, "# Server: Subject: " .. subject)
  local tb = string.split(message, "\n")
  for k, v in ipairs(tb) do
    minetest.chat_send_player(from, "# Server: Message: " .. v)
  end
  
  return #success, #failure -- Return number of successes and failures.
end



-- Called from the GUI to obtain a player's inbox for display.
mailgui.get_inbox = function(pname)
  -- For purposes of the GUI, I need to make sure the table is ordered.
  local tb = email.get_inbox(pname)
  local out = {}
  for k, v in pairs(tb) do
    out[#out+1] = table.copy(v)
  end
  return out
end



-- Helper function to compose the display body of the currently selected mail.
mailgui.compose_inbox_body = function(pname)
  local pstate = mailgui.players[pname]
  local inboxes = pstate.inboxes or {}
  local idx = pstate.selected
  
  -- Selection can be nil.
  if type(idx) ~= "number" then return "", "" end
  
  if idx >= 1 and idx <= #inboxes then
    local frm = inboxes[idx].from or ""
    local dat = inboxes[idx].date or ""
    local sub = inboxes[idx].sub or ""
    if sub == "" then sub = "No Subject" end
    local msg = inboxes[idx].msg or ""
    
    local body =
      "From: <" .. rename.gpn(frm) .. ">\n" ..
      "To: <" .. rename.gpn(pname) .. ">\n" ..
      "Date: " .. dat .. "\n" ..
      "Subject: " .. sub .. "\n" ..
      "------------------------------" ..
      "\n" .. msg
    
    return body, msg -- Display body, original body.
  end
  return "", ""
end

mailgui.compose_outbox_body = function(pname)
  local pstate = mailgui.players[pname]
  
  local frm = pname
  local to = pstate.mailto or ""
  local dat = os.date("%Y-%m-%d")
  local sub = pstate.subject or ""
  if sub == "" then sub = "No Subject" end
  local msg = pstate.message or ""
  
  local body =
    "From: <" .. rename.gpn(frm) .. ">\n" ..
    "To: <" .. rename.gpn(to) .. ">\n" ..
    "Date: " .. dat .. "\n" ..
    "Subject: " .. sub .. "\n" ..
    "------------------------------" ..
    "\n" .. msg
  
  return body
end



mailgui.compose_formspec = function(pname)
  -- Get state table for this player.
  local pstate = mailgui.players[pname]
  local inboxes = pstate.inboxes or {}
  local intlive = pstate.live or 'true'

  local formspec = "size[14,8]" ..
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots ..
		"item_image[0,0;1,1;passport:passport_adv]" ..
    "label[1,0;==| Send and Receive Mail |==]" ..
    
    -- Inbox panel.
    "label[1,0.5;Inbox (" .. #inboxes .. " / " .. email.maxsize .. ")]" ..
    "checkbox[3.8,0.32;enable_interupt;Enable Live Interrupt;" ..
      intlive .. "]" ..
    "textlist[0,1.1;6.31,1.8;headers;"

  -- Compose list of mail headers.
  local strs = ""
  for k, v in pairs(inboxes) do
    local frm = v.from or "N/A"
    local sub = v.sub or ""
    local dat = v.date or "N/A"
    if sub == "" then sub = "No Subject" end
    strs = strs .. minetest.formspec_escape(
      dat .. ": <" .. rename.gpn(frm) .. ">: " .. sub) .. ","
  end
  strs = string.gsub(strs, ",$", "") -- Remove trailing comma.
  formspec = formspec .. strs
  
  -- Finalize mail headers.
  local idx = pstate.selected -- May be nil.
  if type(idx) ~= "number" then idx = 1 end -- Must always be valid number.
  formspec = formspec .. ";" .. tostring(idx) .. ";false]"
  
  -- Compose display of currently selected message body.
  formspec = formspec .. "textarea[0.3,3.2;6.5,4;inbox;;"
  
  -- By composing the inbox body near the same code that composes the header
  -- list, using the same index value, I ensure the two GUI elements can never
  -- somehow get out of sync. This is important, because mail deletion is done
  -- by index, and I don't want players to be able to accidentally delete the
  -- wrong mail because the selected email and displayed email weren't the same.
  local body = mailgui.compose_inbox_body(pname)
  formspec = formspec .. minetest.formspec_escape(body)
  formspec = formspec .. "]" -- End textarea element.
  
  -- Compose message panel.
  formspec = formspec .. "label[7,0.5;Compose Message"
  
  if intlive == 'true' then
    formspec = formspec .. "   (Interrupt Enabled)"
  end
  
  formspec = formspec .. "]" ..
    "label[7,1.0;Subject:]" ..
    "field[8.4,1.3;5.9,1;subject;;" ..
      minetest.formspec_escape(pstate.subject or "") .. "]" ..
    "label[7,2.0;Message:]" ..
    "textarea[8.4,2.0;5.9,4.3;message;;" ..
      minetest.formspec_escape(pstate.message or "") .. "]" ..
    "label[7,5.84;Send To:]" ..
    "field[8.4,6.14;5.9,1;mailto;;" ..
      minetest.formspec_escape(pstate.mailto or "") .. "]" ..
    
    "button[0,6.8;2,1;delall;Delete All]" ..
    "button[2,6.8;2,1;delone;Delete One]" ..
    "button[4,6.8;2,1;inboxcopy;Get Copy]" ..
    "label[0,7.7;Message: " ..
      minetest.formspec_escape(pstate.infotext or "") .. "]" ..
    
    "button[8,6.8;2,1;getmail;Get Mail]" ..
    "button[10,6.8;2,1;sendmail;Send Mail]" ..
    "button[12,6.8;2,1;outcopy;Get Copy]" ..
  
    -- Close button.
    "button[12,0;2,1;done;Close]"
  
  return formspec
end



-- API function.
mailgui.show_formspec = function(pname, reshow)
  -- Make sure player has entry in state table.
  mailgui.players[pname] = mailgui.players[pname] or {
    -- State defaults.
    infotext = "",    -- For operation messages.
    message = "",     -- Current contents of draft area.
    subject = "",     -- Current contents of subject line.
    mailto = "",      -- Current conents of mailto line.
    selected = nil,     -- Inbox selection index.
    inboxes = {},     -- Email records (badly named, I know).
    live = 'true',    -- Whether interupting is allowed.
  }
  
  -- Do stuff if opening the GUI (not simply redrawing it).
  if not reshow then
    mailgui.players[pname].infotext = "Mail management opened!"
    mailgui.players[pname].inboxes = mailgui.get_inbox(pname)
  end

  mailgui.open_inboxes[pname] = true -- Player has open formspec.
  local formspec = mailgui.compose_formspec(pname)
  minetest.show_formspec(pname, "mailgui:mailgui", formspec)
end



-- GUI callback handler.
mailgui.gui_handler = function(pref, fname, fields)
  if fname ~= "mailgui:mailgui" then return end -- Not valid for this callback.
      
  local pname = pref:get_player_name()
  if not mailgui.players[pname] then return true end -- No state, abort!
  
	if fields.quit then
		mailgui.open_inboxes[pname] = nil
		return true
	end

  -- Obtain state table for this player.
  local pstate = mailgui.players[pname]
  -- Don't update message composing state unless told to.
  if fields.message then pstate.message = fields.message end
  if fields.subject then pstate.subject = fields.subject end
  if fields.mailto then pstate.mailto = fields.mailto end
  
	if fields.done then
		mailgui.open_inboxes[pname] = nil
		passport.show_formspec(pname)
		return true
	end

  if fields.delall then
    email.clear_inbox(pname, pstate.inboxes)
    pstate.inboxes = {}
    pstate.infotext = "Inbox cleared!"
    pstate.selected = nil -- Unselect.
    
    local sz = email.get_inbox_size(pname)
    if sz > 0 then
      pstate.infotext = "Inbox cleared! (There are items remaining, press 'Get Mail'.)"
    end
  end
  
  if fields.delone then
    local idx = pstate.selected -- Can be nil.
    if type(idx) == "number" then
      if idx >= 1 and idx <= #pstate.inboxes then
        local frm = pstate.inboxes[idx].from or ""
        local sub = pstate.inboxes[idx].sub or ""
        if sub == "" then sub = "No Subject" end
        
        -- Delete email.
        local tb = {pstate.inboxes[idx]} -- Get table ref.
        email.clear_inbox(pname, tb)
        table.remove(pstate.inboxes, idx)
        
        pstate.infotext = "Message from <" .. rename.gpn(frm)
          .. "> (subject: " .. sub .. ") deleted!"
      else
        pstate.infotext = "Invalid selection index. Please select an email first."
        pstate.selected = nil
      end
    else
      pstate.infotext = "No message selected."
    end
  end
  
  if fields.enable_interupt then
    pstate.live = fields.enable_interupt
    if pstate.live == 'true' then
      pstate.infotext = "Live interrupt enabled. " ..
        "(Live mail updates will interfere with composing.)"
    elseif pstate.live == 'false' then
      pstate.infotext = "Live interrupt disabled. " ..
        "(You may compose mails without interruption.)"
    else
      pstate.infotext = "Invalid value!"
    end
  end
  
  if fields.sendmail then
    local subject = string.trim(pstate.subject or "")
    local message = string.trim(pstate.message or "")
    local mailto = pstate.mailto or ""
    
    -- Allow for no subject.
    if string.len(subject) <= email.max_subject_length then
      if message ~= "" then
        if mailto ~= "" then
          if not string.find(mailto, ",") then -- Singlename.
						mailto = string.trim(mailto)
						if mailto:lower() == "server" then
							if minetest.check_player_privs(pname, {server=true}) then
								-- Mail should be sent to all registered players.
								-- We use special keyword 'server' for this.
								-- No player can have this name.
								local nums, numf = mailall.send_mail(pname, subject, message)

								pstate.infotext = "Email sent to " .. nums ..
									" registered players(s). " .. numf .. " failure(s)."

								if numf == 0 then
									-- Clear fields on success.
									pstate.subject = ""
									pstate.message = ""
									pstate.mailto = ""
								end
							else
								pstate.infotext = "Cannot post server-wide mailing. Your privileges are insufficient!"
							end
						else
							local b, e = mailgui.send_mail_single(pname, subject, message, mailto)
							if b == true then
								pstate.infotext = "Mail sent to <" .. mailto .. ">!"

								-- Clear fields on success.
								pstate.subject = ""
								pstate.message = ""
								pstate.mailto = ""
							else
								if e == "boxfull" then
									pstate.infotext = "Recipient <" .. mailto .. ">'s inbox is full."
								elseif e == "badplayer" then
									pstate.infotext = "Recipient <" .. mailto .. "> does not exist!"
								elseif e == "toobig" then
									pstate.infotext = "Email is too big to send!"
                elseif e == "missingdep" then
                  pstate.infotext = "Missing mod dependency."
								else
									pstate.infotext = "Unknown error!"
								end
							end
						end
          elseif string.find(mailto, ",") then -- Multiname.
            local strtab = string.split(mailto)
						-- Trim all names.
						for i=1, #strtab do
							strtab[i] = string.trim(strtab[i])
						end
            local nums, numf = mailgui.send_mail_multi(pname, subject, message, strtab)
            pstate.infotext = #strtab .. " recipient(s) listed. " ..
              nums .. " message(s) sent. " .. numf .. " failure(s)."
            
            if numf == 0 then
              -- Clear fields on all success.
              pstate.subject = ""
              pstate.message = ""
              pstate.mailto = ""
            end
          else
            pstate.infotext = "Unknown error!" -- Can we ever reach here?
          end
        else
          pstate.infotext = "Please enter a recipient!"
        end
      else
        pstate.infotext = "Please enter a message!"
      end
    else
      pstate.infotext = "Subject line is too long! Max is " .. email.max_subject_length .. " bytes."
    end
  end
  
  if fields.getmail then
    pstate.inboxes = mailgui.get_inbox(pname)
    pstate.infotext = "Inbox refreshed!"
    -- Not really useful to reset the selection?
    --pstate.selected = nil -- Unselect.
  end
  
  if fields.headers then
    assert(type(fields.headers) == "string")
    local event = minetest.explode_textlist_event(fields.headers)
    if event.type == "CHG" then
      local idx = event.index
      if idx >= 1 and idx <= #pstate.inboxes then
        pstate.selected = idx
        pstate.infotext = "Selected mail #" .. tostring(idx)
      else
        pstate.selected = nil
        pstate.infotext = "No mail currently selected."
      end
    elseif event.type == "DCL" then
      local idx = event.index
      if idx >= 1 and idx <= #pstate.inboxes then
        local mail = pstate.inboxes[idx]
        local sub = mail.sub or ""
        if sub == "" then sub = "No Subject" end
        pstate.subject = "RE: " .. sub
        pstate.mailto = rename.gpn(mail.from or "")
        
        pstate.selected = idx
        pstate.infotext = "Initialized response to mail #" .. tostring(idx)
      else
        pstate.selected = nil
        pstate.infotext = "No mail currently selected!"
      end
    end
  end
  
  if fields.inboxcopy then
    local idx = pstate.selected
    if type(idx) == "number" and idx >= 1 and idx <= #pstate.inboxes then
      local inv = pref:get_inventory()
      if inv then
        if inv:contains_item("main", "default:paper") then
          local fulltext = mailgui.compose_inbox_body(pname)
          local serialized = memorandum.compose_metadata({
            text = fulltext,
            signed = pname,
          })
          local itemstack = inv:add_item("main", {
            name="memorandum:letter",
            count=1, wear=0,
            metadata=serialized,
          })
          if itemstack:is_empty() then
            inv:remove_item("main", "default:paper")
            pstate.infotext = "Message printed! You should find it in your inventory."
          else
            pstate.infotext = "You must have space in your inventory for the printed mail."
          end
        else
          pstate.infotext = "You must have blank memorandum in your inventory in order to copy mail."
        end
      else
        pstate.infotext = "Cannot get inventory access!"
      end
    else
      pstate.infotext = "No mail currently selected!"
    end
  end
  
  if fields.outcopy then
    local subject = pstate.subject or ""
    local message = pstate.message or ""
    local mailto = pstate.mailto or ""
    
    if string.len(subject) <= email.max_subject_length then
      if message ~= "" then
        if mailto ~= "" then
          -- Attempt to copy outbox message to player's inventory.
          local inv = pref:get_inventory()
          if inv then
            if inv:contains_item("main", "default:paper") then
              local fulltext = mailgui.compose_outbox_body(pname)
              local serialized = memorandum.compose_metadata({
                text = fulltext,
                signed = pname,
              })
              local itemstack = inv:add_item("main", {
                name="memorandum:letter",
                count=1, wear=0,
                metadata=serialized,
              })
              if itemstack:is_empty() then
                inv:remove_item("main", "default:paper")
                pstate.infotext = "Message printed! You should find it in your inventory."
              else
                pstate.infotext = "You must have space in your inventory for the printed draft."
              end
            else
              pstate.infotext = "You must have blank memorandum in your inventory in order to copy a draft."
            end
          else
            pstate.infotext = "Cannot get inventory access!"
          end
        else
          pstate.infotext = "Please enter a recipient!"
        end
      else
        pstate.infotext = "Please enter a message!"
      end
    else
      pstate.infotext = "Subject line is too long! (Max " .. email.max_subject_length .. " bytes.)"
    end
  end
  
  -- Keep displaying formspec until explicitly told to quit.
	mailgui.show_formspec(pname, true)
  return true
end

  
  
if not mailgui.run_once then
  minetest.register_on_player_receive_fields(function(...)
    return mailgui.gui_handler(...)
  end)
  
  local c = "mailgui:core"
  local f = mailgui.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
  mailgui.run_once = true
end
