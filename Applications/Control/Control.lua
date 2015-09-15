
--pastebin run 5whGf4Ns

local c = require("component")
local unicode = require("unicode")
local computer = require("computer")
local event = require("event")
local context = require("context")
local screen = c.screen
local gpu = c.gpu


-------------------------------------------------------------------------------------------------------------------------------

local colors = {
	topBar = 0xdddddd,
	main = 0xffffff,
	closes = {cross = 0xCC4C4C, hide = 0xDEDE6C, full = 0x57A64E},
	topText = 0x262626,
	topButtons = 0xffffff,
	topButtonsText = 0x262626,
}

local topButtons = {"О системе", "Диски", "Экран", "Память"}
local spaceBetweenTopButtons, offsetTopButtons = 2, 2
local currentMode = 1

local osIcon = image.load("System/OS/Installer/OS_Logo.png")
local hddIcon = image.load("System/OS/Icons/HDD.png")
local floppyIcon = image.load("System/OS/Icons/Floppy.png")

local x, y = "auto", "auto"
local width, height = 84, 26
x, y = ecs.correctStartCoords(x, y, width, height)
local heightOfTopBar = 3

local ram = {}
ram.free, ram.total, ram.used = ecs.getInfoAboutRAM()

local drawHDDFrom = 1
local HDDs
local bootAddress = computer.getBootAddress()

-------------------------------------------------------------------------------------------------------------------------------

--СОЗДАНИЕ ОБЪЕКТОВ
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

--Рисем цветные кружочки слева вверху
local function drawCloses()
	local symbol = "⮾"
	gpu.setBackground(colors.topBar)
	local yPos = y
	ecs.colorText(x + 1, yPos , colors.closes.cross, symbol)
	ecs.colorText(x + 3, yPos , colors.closes.hide, symbol)
	ecs.colorText(x + 5, yPos , colors.closes.full, symbol)
	newObj("Closes", 1, x + 1, yPos, x + 1, yPos)
	newObj("Closes", 2, x + 3, yPos, x + 3, yPos)
	newObj("Closes", 3, x + 5, yPos, x + 5, yPos)
end

--Рисуем верхнюю часть
local function drawTopBar()
	--Рисуем сам бар
	ecs.square(x, y, width, heightOfTopBar, colors.topBar)
	--Рисуем кнопочки
	drawCloses()
	--Рисуем титл
	--local text = topButtons[currentMode]
	--ecs.colorText(x + math.floor(width / 2 - unicode.len(text) / 2), y, colors.topText, text)
	--Рисуем кнопочки влево-вправо
	local widthOfButtons = 0
	for i = 1, #topButtons do
		widthOfButtons = widthOfButtons + unicode.len(topButtons[i]) + spaceBetweenTopButtons + offsetTopButtons * 2
	end
	local xPos, yPos = x + math.floor(width / 2 - widthOfButtons / 2), y + 1
	for i = 1, #topButtons do
		local color1, color2 = colors.topButtons, colors.topButtonsText
		if i == currentMode then color1, color2 = ecs.colors.blue, 0xffffff end
		newObj("TopButtons", i, ecs.drawAdaptiveButton(xPos, yPos, offsetTopButtons, 0, topButtons[i], color1, color2))
		xPos = xPos + unicode.len(topButtons[i]) + spaceBetweenTopButtons + offsetTopButtons * 2
		color1, color2 = nil, nil
	end
end

local function drawMain()
	ecs.square(x, y + heightOfTopBar, width, height - heightOfTopBar, colors.main)
	local xPos, yPos
	if currentMode == 1 then
		xPos, yPos = x + 3, y + heightOfTopBar + 3
		image.draw(xPos, yPos, osIcon)
		xPos, yPos = x + 36, yPos + 3
		ecs.colorTextWithBack(xPos, yPos, 0x000000, colors.main, "MineOS"); yPos = yPos + 1
		ecs.colorText(xPos, yPos, ecs.colors.lightGray, "Публичная бета-версия 1.75"); yPos = yPos + 2

		ecs.smartText(xPos, yPos, "§fСистемный блок §8(3 уровень, середина 2015 года)"); yPos = yPos + 1
		ecs.smartText(xPos, yPos, "§fПроцессор §8(3 уровень, дохуя GHz)"); yPos = yPos + 1
		ecs.smartText(xPos, yPos, "§fПамять §8(1333 МГц DDR3 "..ram.total.." KB)"); yPos = yPos + 1
		ecs.smartText(xPos, yPos, "§fГрафика §8(GTX Titan AnaloRazrivatel mk.3000)"); yPos = yPos + 1
		ecs.smartText(xPos, yPos, "§fСерийный номер §8"..ecs.stringLimit("end", computer.address(), 30)); yPos = yPos + 1
	
	elseif currentMode == 2 then
		obj["HDDControls"] = {}
		yPos = y + heightOfTopBar + 1
		HDDs = ecs.getHDDs()
		for i = drawHDDFrom, (drawHDDFrom + 3) do
			if not HDDs[i] then break end

			xPos = x + 2
			--Рисуем правильную картинку диска
			if HDDs[i].isFloppy == true then image.draw(xPos, yPos, floppyIcon) else image.draw(xPos, yPos, hddIcon) end
			
			--Рисуем тексты
			xPos = xPos + 10
			gpu.setBackground(colors.main)
			local load = ""
			if bootAddress == HDDs[i].address then load = " §eзагрузочный§8," end
			ecs.smartText(xPos, yPos, ecs.stringLimit("end", "§f" .. (HDDs[i].label or "Безымянный диск") .. "§8,"..load.." " .. HDDs[i].address, 58)); yPos = yPos + 2
			--Рисуем прогрессбар
			local percent = math.ceil(HDDs[i].spaceUsed / HDDs[i].spaceTotal * 100)
			ecs.progressBar(xPos, yPos, 50, 1, 0xdddddd, ecs.colors.blue, percent)
			yPos = yPos + 1
			ecs.colorTextWithBack(xPos + 10, yPos, 0xaaaaaa, colors.main, HDDs[i].spaceUsed.." из "..HDDs[i].spaceTotal.." KB использовано"); yPos = yPos + 1

			ecs.separator(x, yPos, width - 1, colors.main, 0xdddddd)

			--Рисуем кнопы
			xPos, yPos = x + 67, yPos - 4
			newObj("HDDControls", i, ecs.drawButton(xPos, yPos, 14, 3, "Управление", ecs.colors.blue, 0xffffff))

			yPos = yPos + 5
		end

		--Скроллбар
		ecs.srollBar(x + width - 1, y + heightOfTopBar, 1, height - heightOfTopBar, #HDDs, drawHDDFrom, 0xdddddd, ecs.colors.blue)
	
	elseif currentMode == 3 then

	else

	end
end


-------------------------------------------------------------------------------------------------------------------------------
local oldPixels = ecs.rememberOldPixels(x, y, x + width - 1, y + height - 1)
drawTopBar()
drawMain()

while true do
	local e = {event.pull()}
	if e[1] == "touch" then

		if currentMode == 2 then
			for key in pairs(obj["HDDControls"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["HDDControls"][key][1], obj["HDDControls"][key][2], obj["HDDControls"][key][3], obj["HDDControls"][key][4]) then
					ecs.drawButton(obj["HDDControls"][key][1], obj["HDDControls"][key][2], 14, 3, "Управление", 0xdddddd, ecs.colors.blue)
					local action = context.menu(obj["HDDControls"][key][1], obj["HDDControls"][key][2] + 3, {"Форматировать"}, {"Изменить имя"}, {"Установить как загрузочный"}, "-", {"Сдублировать OS на этот диск"})
					if action == "Форматировать" then
						local data = ecs.universalWindow("auto", "auto", 38, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x880000, "Внимание!"}, {"EmptyLine"}, {"CenterText", 0x262626, "Данное действие очистит весь диск."}, {"CenterText", 0x262626, "Продолжить?"}, {"EmptyLine"}, {"Button", 0xbbbbbb, 0xffffff, "Да"}, {"Button", 0x999999, 0xffffff, "Нет"})
						if data[1] ~= "Нет" then
							ecs.formatHDD(HDDs[key].address)
							drawMain()
						end
					elseif action == "Изменить имя" then
						local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Изменить имя диска"}, {"EmptyLine"}, {"Input", 0x262626, 0x000000, HDDs[key].label or "Имя"}, {"EmptyLine"}, {"Button", 0xbbbbbb, 0xffffff, "OK!"})
						if data[1] == "" or data[1] == " " then data[1] = "Untitled" end
						ecs.setHDDLabel(HDDs[key].address, data[1])
						drawMain()
					elseif action == "Сдублировать OS на этот диск" then
						ecs.duplicateFileSystem(bootAddress, HDDs[key].address)
						drawMain()
					elseif action == "Установить как загрузочный" then
						computer.setBootAddress(HDDs[key].address)
						bootAddress = HDDs[key].address
						drawMain()
					end
					ecs.drawButton(obj["HDDControls"][key][1], obj["HDDControls"][key][2], 14, 3, "Управление", ecs.colors.blue, 0xffffff)
					break
				end
			end
		end

		for key, val in pairs(obj["TopButtons"]) do
			if ecs.clickedAtArea(e[3], e[4], obj["TopButtons"][key][1], obj["TopButtons"][key][2], obj["TopButtons"][key][3], obj["TopButtons"][key][4]) then
				currentMode = key
				drawTopBar()
				drawMain()
				break
			end
		end

		for key, val in pairs(obj["Closes"]) do
			if ecs.clickedAtArea(e[3], e[4], obj["Closes"][key][1], obj["Closes"][key][2], obj["Closes"][key][3], obj["Closes"][key][4]) then
				ecs.colorTextWithBack(obj["Closes"][key][1], obj["Closes"][key][2], ecs.colors.blue, colors.topBar, "⮾")
				os.sleep(0.2)
				if key == 1 then
					ecs.drawOldPixels(oldPixels)
					return
				else
					drawTopBar()
					break
				end
			end
		end

	elseif e[1] == "key_down" then
		for i = 2, 5 do
			if e[4] == i then
				currentMode = i - 1
				drawTopBar()
				drawMain()
				break
			end
		end

		if e[4] == 28 then
			ecs.prepareToExit()
			return
		end
	
	elseif e[1] == "scroll" then
		if currentMode == 2 then
			if e[5] == 1 then
				if drawHDDFrom > 1 then drawHDDFrom = drawHDDFrom - 1; drawMain() end
			else
				if drawHDDFrom < #HDDs then drawHDDFrom = drawHDDFrom + 1; drawMain() end
			end
		end


	end
end







