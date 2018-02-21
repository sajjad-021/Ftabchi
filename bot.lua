redis = (loadfile "./redis.lua")()
redis = redis.connect('127.0.0.1', 6379)
redis:select(0)
ADMIN = 180191663--yourid

function ok_cb(extra, success, result)
end

function is_Naji(id)
	if ((id == ADMIN) or redis:sismember("selfbotBOT-IDadmins",id)) then
		return true
	else
		return false
	end
end

function get_receiver(msg)
	local reciver = ""
	if msg.to.type == 'user' then
		reciver = 'user#id'..msg.from.id
		if not redis:sismember("selfbotBOT-IDusers",reciver) then
			redis:sadd("selfbotBOT-IDusers",reciver)
		end
	elseif msg.to.type =='chat' then
		reciver ='chat#id'..msg.to.id
		if not redis:sismember("selfbotBOT-IDgroups",reciver) then
			redis:sadd("selfbotBOT-IDgroups",reciver)
		end
	elseif msg.to.type == 'encr_chat' then
		reciver = msg.to.print_name
	elseif msg.to.type == 'channel' then
		reciver = 'channel#id'..msg.to.id
		if not redis:sismember("selfbotBOT-IDsupergroups",reciver) then
			redis:sadd("selfbotBOT-IDsupergroups",reciver)
		end
	end
	return reciver
end

function rem(msg)
	if msg.to.type == 'user' then
		reciver = 'user#id'..msg.from.id
		redis:srem("selfbotBOT-IDusers",reciver)
	elseif msg.to.type =='chat' then
		reciver ='chat#id'..msg.to.id
		redis:srem("selfbotBOT-IDgroups",reciver)
	elseif msg.to.type == 'channel' then
		reciver = 'channel#id'..msg.to.id
		redis:srem("selfbotBOT-IDsupergroups",reciver)
	end
end

function backward_msg_format(msg)
  for k,name in pairs({'from', 'to'}) do
    local longid = msg[name].id
    msg[name].id = msg[name].peer_id
    msg[name].peer_id = longid
    msg[name].type = msg[name].peer_type
  end
  if msg.action and (msg.action.user or msg.action.link_issuer) then
    local user = msg.action.user or msg.action.link_issuer
    local longid = user.id
    user.id = user.peer_id
    user.peer_id = longid
    user.type = user.peer_type
  end
  return msg
end

function find_link(text)
	if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
		local text = text:gsub("t.me", "telegram.me")
		local text = text:gsub("telegram.dog", "telegram.me")
		for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
			if not redis:sismember("selfbotBOT-IDlinks",link) then
				redis:sadd("selfbotBOT-IDlinks",link)
			end
			import_chat_link(link,ok_cb,false)
		end
	end
end

function on_msg_receive (msg)
	if not started then
		return
	end
	msg = backward_msg_format(msg)
	if (not msg.to.id or not msg.from.id or msg.out or msg.to.type == 'encr_chat' or  msg.unread == 0 or  msg.date < (now-60) ) then
		return false
	end
	local receiver = get_receiver(msg)
	if msg.from.id == 777000 then
		local c = (msg.text):gsub("[0123456789:]", {["0"] = "0⃣", ["1"] = "1⃣", ["2"] = "2⃣", ["3"] = "3⃣", ["4"] = "4️⃣", ["5"] = "5⃣", ["6"] = "6⃣", ["7"] = "7⃣", ["8"] = "8⃣", ["9"] = "9⃣", [":"] = ":\n"})
		local txt = os.date("پیام ارسال شده از تلگرام در تاریخ 🗓 %Y-%m-%d 🗓 و ساعت ⏰ %X ⏰ (به وقت سرور)")
		return send_msg('user#id'..ADMIN, txt.."\n\n"..c, ok_cb, false)
	end
	if msg.text then
		local text = msg.text 
		if redis:get("selfbotBOT-IDlink") then
			find_link(text)
		end
		if is_Naji(msg.from.id) then
			find_link(text)
			if text:match("^(!markread) (.*)$") then
				local matche = text:match("^!markread (.*)$")
				if matche == "on" then
					redis:set("selfbotBOT-IDmarkread", "on")
					send_msg(receiver, "Mark read > on", ok_cb, false)
				elseif matche == "off" then
					redis:del("selfbotBOT-IDmarkread")
					send_msg(receiver, "Mark read > off", ok_cb, false)
				end
			elseif text:match("^(!setname) (.*)") then
				local matche = text:match("^!setname (.*)")
				set_profile_name(matche,ok_cb, false)
				send_msg(receiver, "Name changed", ok_cb, false)
			elseif text:match("^(!echo) (.*)") then
				local matche = text:match("^!echo (.*)")
				send_msg(receiver, matche, ok_cb, false)
			elseif text:match("^(!text) (%d+) (.*)") then
				local matches = {text:match("^!text (%d+) (.*)")}
				send_msg("user#id"..matches[1],matches[2], ok_cb, false)
				send_msg(receiver, "Message has been sent", ok_cb, false)
			elseif text:match("^(!help)$") then
				local text =[[💢 متن راهنما BOT-ID 💢

!pm [Id] [Text]
📩 ارسال  text وارد شده به فردی با id موردنظر

!bc[all|pv|gp|sgp] [text]
📤 ارسال text وارد شده به مورد خوسته شده

!fwd[all|pv|gp|sgp]  {reply on msg}
📨 فروارد پیام ریپلای شده به مورد خواسته شده

!block [Id]
⚫️ بلاک کردن فرد با id وارد شده

!unblock [id]
⚪️ انبلاک کردن فرد  با id وارد شده

!addcontact [phone] [FirstName] [LastName]
➕ اضافه کردن یک کانتکت

!delcontact [phone] [FirstName] [LastName]
➖ حذف کردن یک کانتکت

!sendcontact [phone] [FirstName] [LastName]
↩️ ارسال یک کانتکت

!contactlist
📄 دریافت لیست کانتکت ها

!markread [on]|[off]
🔘 روشن و خاموش کردن تیک مارک رید

!autojoin [on]|[off]
🔲 روشن و خاموش کردن شناسایی لینک و عضویت

!setphoto {on reply photo}
🌠 ست کردن پروفایل ربات

!stats
📈 دریافت آمار ربات

!status
⚙️ دریافت وضعیت ربات

!addmember
📌 اضافه کردن کانتکت های ربات به گروه

!echo [text]
🔁 برگرداندن text وارد شده

!exportlink
📦 دریافت لینک های ذخیره شده
!addcontact [on]|[off]
☑️ خاموش و روشن کردن افزودن خودکار مخاطبین

!addcontactpm [on]|[off]
🍃️ خاموش و روشن کردن پیام افزودن مخاطبین

!setpm [text]
📍تنظیم پیام ادشدن کانتکت

!addsudo [id]
👮 اضافه کردن سودو

!remsudo [id]
✖️ حذف کردن سودو

➖➖➖➖ا➖➖➖➖
"دانش بدون تکامل اخلاقی خطرناک و نابود کننده است."
➖➖➖➖ا➖➖➖➖]]
				send_msg(receiver, text, ok_cb, false)
			elseif text:match("^(info)$") then
				local join = redis:get("selfbotBOT-IDlink") and "✅" or "⛔️"
				local add = redis:get("selfbotBOT-IDaddcontact") and "✅" or "⛔️"
				local msg =  redis:get("selfbotBOT-IDaddcontactpm") and "✅" or "⛔️"
				local txt =  redis:get("selfbotBOT-IDpm") or "اددی گلم خصوصی پیام بده"
				local view = redis:get("selfbotBOT-IDmarkread") and "✅" or "⛔️"
				local text = "⚜️AutoJoin : "..join.."\n👁‍🗨ReadMark : "..view.."\n🔰AutoAdd Sheared Contact : "..add.."\n🌟Sending Message for Sheared Contact : "..msg.."\n📨Sheared Contact Msg: 📍"..txt.." 📍"
				send_msg(receiver, text, ok_cb, false)
			elseif text:match("^(join) (.*)$") then
				local matche = text:match("^join (.*)$")
				if matche == "on" then
					redis:set("selfbotBOT-IDlink", true)
					send_msg(receiver, "Automatic joining is ON", ok_cb, false)
				elseif matche == "off" then
					redis:del("selfbotBOT-IDlink")
					send_msg(receiver, "Automatic joining is OFF", ok_cb, false)
				end
			
			elseif (text:match("^(!fwd)(.*)$") and msg.reply_id) then
				local matche = text:match("^!fwd(.*)$")
				local naji = ""
				local id = msg.reply_id
				if matche == "all"  then
					local list = {redis:smembers("selfbotBOT-IDgroups"),redis:smembers("selfbotBOT-IDsupergroups"),redis:smembers("selfbotBOT-IDusers")}
					for x,y in pairs(list) do
						for i,v in pairs(y) do
							fwd_msg(v,id,ok_cb,false)
						end
					end
					return send_msg(receiver, "Sended!", ok_cb, false)
				elseif matche == "pv" then
					naji = "selfbotBOT-IDusers"
				elseif matche == "gp" then
					naji = "selfbotBOT-IDgroups"
				elseif matche == "sgp" then
					naji = "selfbotBOT-IDsupergroups"
				else 
					return false
				end
				local list = redis:smembers(naji)
				for i=1, #list do
					fwd_msg(list[i],id,ok_cb,false)
				end
				return send_msg(receiver, "Sended!", ok_cb, false)
			elseif text:match("^(!addsudo) (%d+)$") then
				if msg.from.id == ADMIN then
					local matche = text:match("%d+")
					if redis:sismember("selfbotBOT-IDadmins",matche) then
						return send_msg(receiver,  "User is a sudoer user!", ok_cb, false)
					else
						redis:sadd("selfbotBOT-IDadmins",matche)
						return send_msg(receiver,  "User "..matche.." added to sudoers", ok_cb, false)
					end
				else
					return send_msg(receiver,  "ONLY FULLACCESS SUDO", ok_cb, false)
				end
			elseif text:match("^(!remsudo) (%d+)$") then
				if msg.from.id == ADMIN then
					local matche = text:match("%d+")
					if redis:sismember("selfbotBOT-IDadmins",matche) then
						redis:srem("selfbotBOT-IDadmins",matche)
						return send_msg(receiver,  "User "..matche.." isn't sudoer user anymore!", ok_cb, false)
					else
						return send_msg(receiver,  "User isn't sudoer user", ok_cb, false)
					end
				else
					return send_msg(receiver,  "ONLY FULLACCESS SUDO", ok_cb, false)
				end
			end
		end
	elseif msg.action then
		if ((msg.action.type == "chat_del_user" and msg.to.id == 1146365116) or msg.action.type == "migrated_to") then
			rem(msg)
		end
	elseif msg.media then
		if msg.media.type == "contact" then
			if redis:get("selfbotBOT-IDaddcontact") then
				add_contact(msg.media.phone, ""..(msg.media.first_name or "-").."", ""..(msg.media.last_name or "-").."", ok_cb, false)
			end
			if redis:get("selfbotBOT-IDaddcontactpm") then
				local txt = redis:get("selfbotBOT-IDpm") or "اددی گلم خصوصی پیام بده"
				return reply_msg(msg.id,txt, ok_cb, false)
			end
		elseif (msg.media.caption and redis:get("selfbotBOT-IDlink")) then
				find_link(msg.media.caption)
		end		
	end
	if redis:get("selfbotBOT-IDmarkread") then
		mark_read(receiver, ok_cb, false)
	end
end

function on_binlog_replay_end()
  started = true
end

function on_our_id (id)
  our_id = id
end

function on_user_update (user, what)
end

function on_chat_update (chat, what)
end

function on_secret_chat_update (schat, what)
end

function on_get_difference_end ()
end

our_id = 0
now = os.time()
math.randomseed(now)
started = false
