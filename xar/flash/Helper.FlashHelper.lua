local Helper = XLGetGlobal("Helper")
if not Helper then
	Helper = {}
	XLSetGlobal("Helper", Helper)
end

local FlashHelper = {}
Helper.FlashHelper = FlashHelper

function FlashHelper:ParseRequest(request)
	local node_attr, node_value = string.match(request, "<invoke(.-)>(.*)</invoke>")
	local func_name = string.match(node_attr, "name=\"(.-)\"")
	node_value = string.match(node_value, "<arguments>(.*)</arguments>")
	local func_param = {}
	local start_pos = 0
	while true do
		local tag_pos, tag_end = string.find(node_value, "<(%a+)[/]?>", start_pos)
		if tag_pos == nil or tag_end == nil then
			break
		end
		start_pos = tag_end
		local tag_name = string.sub(node_value, tag_pos, tag_end)
		tag_name = string.match(tag_name, "<(%a+)[/]?>")
		if tag_name == "true" then
			table.insert(func_param, true)
		elseif tag_name == "false" then
			table.insert(func_param, false)
		else
			-- 获取出value
			local value = string.match(node_value, "(.-)</" .. tag_name .. ">", tag_end + 1)
			if value then
				if tag_name == "string" then
					-- 先转义
					local s = string.gsub(value, "&amp;", "&")
					s = string.gsub(s, "&apos;", "\'")
					s = string.gsub(s, "&quot;", "\"")
					table.insert(func_param, s)
				elseif tag_name == "number" then
					table.insert(func_param, tonumber(value))
				elseif tag_name == "bool" then
					if string.lower(value) == "true" then
						table.insert(func_param, true)
					else
						table.insert(func_param, false)
					end
				else
					table.insert(func_param, nil)
				end
			else
				table.insert(func_param, nil)
			end
		end
	end
	return func_name, func_param
end