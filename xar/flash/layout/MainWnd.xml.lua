local Helper = XLGetGlobal("Helper")
if not Helper then
	Helper = {}
	XLSetGlobal("Helper", Helper)
end

function Helper:LOG(...)
	local printResult = ""
	for i = 1, #arg do
		printResult = printResult..tostring(arg[i])
	end
	XLMessageBox(tostring(printResult))
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

--调用约定：flash代码应准确地使用aaa:Fun() 或 aaa.Fun()
local function InvokeGlobalFunc(func_name, func_param)
	if "string" ~= type(func_name) or "table" ~= type(func_param) then return end
	local targetFunc = nil
	local host = nil
	
	local pos = string.find(func_name, ":")
	if pos then
		local hostStr = string.sub(func_name, 1, pos-1)
		func_name = string.gsub(func_name, ":", "%.")
		targetFunc, host = loadstring("return "..func_name..", "..hostStr)()
		
		if not host then return end
		table.insert(func_param, 1, host)
	else
		targetFunc = loadstring("return "..func_name)()
	end
	
	if "function" ~= type(targetFunc) then return end
	return targetFunc(unpack(func_param))
end





function close_btn_OnLButtonDown(self)
	---创建内置动画的实例
	local aniFactory = XLGetObject("Xunlei.UIEngine.AnimationFactory")
	local alphaAni = aniFactory:CreateAnimation("AlphaChangeAnimation")
	alphaAni:SetTotalTime(700)
	alphaAni:SetKeyFrameAlpha(255,0)
	local owner = self:GetOwner()
	local icon = owner:GetUIObject("icon")
	alphaAni:BindRenderObj(icon) 
	owner:AddAnimation(alphaAni)
	alphaAni:Resume()
	
	local posAni = aniFactory:CreateAnimation("PosChangeAnimation")
	posAni:SetTotalTime(700)
	posAni:SetKeyFrameRect(45,100,45+60,100+60,45-30,100-30,45+60+30,100+60+30)
	posAni:BindLayoutObj(icon)
	owner:AddAnimation(posAni)
	posAni:Resume()

	local alphaAni2 = aniFactory:CreateAnimation("AlphaChangeAnimation")
	alphaAni2:SetTotalTime(700)
	alphaAni2:SetKeyFrameAlpha(255,0)
	local msg = owner:GetUIObject("msg")
	alphaAni2:BindRenderObj(msg)
	owner:AddAnimation(alphaAni2)
	alphaAni2:Resume()
	
	---定义动画结束的回调函数
	local function onAniFinish(self,oldState,newState)
		if newState == 4 then
		----os.exit 效果等同于windows的exit函数，不推荐实际应用中直接使用
			os.exit()
		end
	end

	local posAni2 = aniFactory:CreateAnimation("PosChangeAnimation")
	posAni2:SetTotalTime(800)
	posAni2:BindLayoutObj(msg)
	posAni2:SetKeyFramePos(135,100,500,100)
	--当动画结束后，应用程序才退出
	posAni2:AttachListener(true,onAniFinish)
	owner:AddAnimation(posAni2)
	posAni2:Resume()
end

function OnFlashCall(flashObj, request)
	local func_name, func_param = FlashHelper:ParseRequest(request)
	if "string" ~= type(func_name) then return end
	
	InvokeGlobalFunc(func_name, func_param)
end

function OnInitFlash(self)
	local owner = self:GetOwner()
	local flashObj = owner:GetUIObject("flashobj")
	
	flashObj:AttachListener("OnFlashCall", true, function(_, ...) OnFlashCall(flashObj, ...) end)
	local ret = flashObj:LoadMovie("C:\\tmpcode\\XLUE_Dev_Env\\src\\flash\\ActionScript\\flash4862.swf")
end

function OnInitControl(self)
	local owner = self:GetOwner()
	
	--动态创建一个ImageObject,这个Object在XML里没定义
	local objFactory = XLGetObject("Xunlei.UIEngine.ObjectFactory")
	local newIcon = objFactory:CreateUIObject("icon2","ImageObject")
	local xarManager = XLGetObject("Xunlei.UIEngine.XARManager")
	newIcon:SetResProvider(xarManager)
	newIcon:SetObjPos(45,165,45+70,165+70)
	newIcon:SetResID("app.icon2")
	local function onClickIcon()
		XLMessageBox("Don't touch me!")
	end
	--绑定鼠标事件的响应函数到对象
	newIcon:AttachListener("OnLButtonDown",true,onClickIcon)
	self:AddChild(newIcon)
	
	--创建一个自定义动画，作用在刚刚动态创建的ImageObject上
	local aniFactory = XLGetObject("Xunlei.UIEngine.AnimationFactory")
	myAni = aniFactory:CreateAnimation("HelloBolt.ani")
	--一直运行的动画就是一个TotalTime很长的动画
	myAni:SetTotalTime(9999999) 
	local aniAttr = myAni:GetAttribute()
	aniAttr.obj = newIcon
	owner:AddAnimation(myAni)
	myAni:Resume()
	
	OnInitFlash(self)
end

function MSG_OnMouseMove(self)
	self:SetTextFontResID ("msg.font.bold")
	self:SetCursorID ("IDC_HAND")
end

function MSG_OnMouseLeave(self)
	self:SetTextFontResID ("msg.font")
	self:SetCursorID ("IDC_ARROW")
end

function userdefine_btn_OnClick(self)
	local myClassFactory = XLGetObject("HelloBolt.MyClass.Factory")
	local myClass = myClassFactory:CreateInstance()
	myClass:AttachResultListener(function(result) XLMessageBox("result is "..result) end)
	myClass:Add(100,200)
end
