
-- Private function!
-- Create db:exec wrapper for error reporting.
local function db_exec(db, stmt)
  if db:exec(stmt) ~= email.sql.OK then
    local msg = db:errmsg()
    minetest.log("error", "SQLite3 ERROR: " .. msg)

    local admin = utility.get_first_available_admin()
    if admin then
      minetest.chat_send_player(admin:get_player_name(), "# Server: Error from SQL! " .. msg)
    end
  end
end



function email.db_exec(stmt)
	assert(email.db)
	db_exec(email.db, stmt)
end



-- Load all emails for player from database.
function email.load_inbox(db, name)
	assert(name)
	assert(db)

  local stmt = db:prepare([[
		SELECT sender,subject,message,date,number FROM email WHERE name = ?;
	]])

	assert(stmt, db:errmsg())
  stmt:bind(1, name)

  local r = stmt:step()
  while r == email.sql.ROW do
    r = stmt:step()
  end
  assert(r == email.sql.DONE)

	local mail = {}
  for row in stmt:nrows() do
    assert(type(row.sender) == "string")
    assert(type(row.date) == "string")
    assert(type(row.subject) == "string")
    assert(type(row.message) == "string")
    assert(type(row.number) == "number")

		mail[#mail+1] = {
			from = row.sender,
			date = row.date,
			sub = row.subject,
			msg = row.message,
			rng = row.number,
		}
  end

	local r4 = stmt:finalize()
	assert(r4 == email.sql.OK)

	return mail
end



-- Delete emails from player's inbox.
function email.delete_mails(db, name, mails)
	for k, v in ipairs(mails) do
		local rng = v.rng
		assert(type(rng) == "number")

		local stmt = db:prepare([[
			DELETE FROM email WHERE name = ? AND number = ?;
		]])

		local result = stmt:bind_values(name, rng)
		assert(result == email.sql.OK)

		local r3 = stmt:step()
		assert(r3 == email.sql.DONE)

		local r4 = stmt:finalize()
		assert(r4 == email.sql.OK)
	end
end



-- Store email in player's inbox.
function email.store_mail(db, name, mail)
	local sender = mail.from -- Cannot be substituted.
	local subject = mail.sub
	local message = mail.msg
	local number = mail.rng -- Cannot be substituted.
	local date = mail.date -- Cannot be substituted.

	-- Don't transfer corrupt data.
	if name and sender and number and message and subject and date then
		assert(type(name) == "string")
		assert(type(sender) == "string")
		assert(type(number) == "number")
		assert(type(subject) == "string")
		assert(type(message) == "string")
		assert(type(date) == "string")

		local stmt = db:prepare([[
			INSERT INTO email
				(name, sender, date, subject, message, number)
				VALUES (?, ?, ?, ?, ?, ?);
		]])

		local result = stmt:bind_values(
			name, sender, date, subject, message, number)
		assert(result == email.sql.OK)

		local r3 = stmt:step()
		assert(r3 == email.sql.DONE)

		local r4 = stmt:finalize()
		assert(r4 == email.sql.OK)
	end
end



-- For one-time database format conversion!
--[===[
function email.translate_database()
	local db = email.sql.open(email.database)
	if not db then return end

	db_exec(db, [[ DROP TABLE IF EXISTS email; ]])
	db_exec(db, [[ CREATE TABLE email (
		name TEXT,
		sender TEXT,
		date TEXT,
		subject TEXT,
		message TEXT,
		number INTEGER
	); ]])

	db_exec(db, [[ BEGIN TRANSACTION; ]])

	if email.inboxes then
		for name, inbox in pairs(email.inboxes) do
			for _, mail in ipairs(inbox) do
				email.store_mail(db, name, mail)
			end
		end
	end

	db_exec(db, [[ COMMIT; ]])
	db:close()
end
--]===]

