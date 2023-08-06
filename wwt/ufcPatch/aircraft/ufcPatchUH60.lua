-- Credit to ANDR0ID on DCS Forums

local ufcUtils = require("ufcPatch\\utilities\\ufcPatchUtils")

ufcPatchUH60 = {}

function ufcPatchUH60.generateUFCData()
	-- Access the UH60 Main panel & other devices from DCS
	local MainPanel = GetDevice(0)
	local UHFRadio = GetDevice(5)
	local FMRadio1 = GetDevice(6)
	local VHFRadio = GetDevice(8)
	local FMRadio2 = GetDevice(10)
	local HFRadio = GetDevice(12)

	--Initial Data
	local PwrSwpos = MainPanel:get_argument_value(17)

	--Checks UH-60 power and starts data pull
	if PwrSwpos == 1 then
		FM1Freq = FMRadio1:get_frequency()
		UHFFreq = UHFRadio:get_frequency()
		VHFFreq = VHFRadio:get_frequency()
		FM2Freq = FMRadio2:get_frequency()
		HFFreq = HFRadio:get_frequency()
		
		ARC201FM1Freq = get_param_handle("ARC201FM1param"):get()
		ARC201FM2Freq = get_param_handle("ARC201FM2param"):get()
		ARC186Freq = get_param_handle("ARC186param"):get()

		FuelInfo = get_param_handle("CDU_FUEL_DIGITS"):get()
		AuxFuelInfoLO = get_param_handle("AFMS_DISPLAY_OUTBD_L"):get()
		AuxFuelInfoLI = get_param_handle("AFMS_DISPLAY_INBD_L"):get()
		AuxFuelInfoRI = get_param_handle("AFMS_DISPLAY_INBD_R"):get()
		AuxFuelInfoRO = get_param_handle("AFMS_DISPLAY_OUTBD_R"):get()
		AuxFuelTank = MainPanel:get_argument_value(462)
		WepsRotaryInfo = get_param_handle("WepsRotarySelector"):get()
		RocketInfo = MainPanel:get_argument_value(2005)
	end

	-- Got these argument values from: mainpanel_init.lua
	local digits = {
		math.floor((MainPanel:get_argument_value(174) + 0.05) * 10), --Need to round Radar Alt values, see Huey file for more info
		math.floor((MainPanel:get_argument_value(175) + 0.05) * 10),
		math.floor((MainPanel:get_argument_value(176) + 0.05) * 10),
		math.floor((MainPanel:get_argument_value(177) + 0.05) * 10)
	}

	-- Parse digits and build the radar alt string
	local radarAltitudeString = ""
	for index, value in ipairs(digits) do
		local digitToAppend = value
		if value >= 10 then
			digitToAppend = 0
		end
		radarAltitudeString = radarAltitudeString .. digitToAppend
	end

	--Flare Count
	local flaredigit = {
		math.floor(MainPanel:get_argument_value(554) * 10),
		math.floor((MainPanel:get_argument_value(555) + 0.05) * 10)
	}

	local flarecount = ""
	for index, value in ipairs(flaredigit) do
		local flaredigitToAppend = value
		if value >= 10 then
			flaredigitToAppend = 0
		end
		flarecount = flarecount .. flaredigitToAppend
	end

	--Chaff Count
	local chaffdigit = {
		math.floor(MainPanel:get_argument_value(556) * 10),
		math.floor((MainPanel:get_argument_value(557) + 0.05) * 10)
	}

	local chaffcount = ""
	for index, value in ipairs(chaffdigit) do
		local chaffdigitToAppend = value
		if value >= 10 then
			chaffdigitToAppend = 0
		end
		chaffcount = chaffcount .. chaffdigitToAppend
	end

	--Combined Flare/Chaff Count (Not Currently Used, retained as an option)
	local flarechaffdigit = {
		math.floor(MainPanel:get_argument_value(554) * 10),
		math.floor((MainPanel:get_argument_value(555) + 0.05) * 10),
		math.floor(MainPanel:get_argument_value(556) * 10),
		math.floor((MainPanel:get_argument_value(557) + 0.05) * 10)
	}

	local flarechaffcount = ""
	for index, value in ipairs(flarechaffdigit) do
		local flarechaffdigitToAppend = value
		if value >= 10 then
			flarechaffdigitToAppend = 0
		end
		flarechaffcount = flarechaffcount .. flarechaffdigitToAppend
	end

	--Countermeassures Arm Status (Not Currently Used, retained as an option)
	local CMdigits = { math.floor(MainPanel:get_argument_value(558) * 10) }

	local CMString = ""
	for index, value in ipairs(CMdigits) do
		local CMdigitToAppend = value
		if value >= 10.1 then
			CMdigitToAppend = 0
		end
		CMString = CMString .. CMdigitToAppend
		if value == 0 then
			CMDisplay = "X"
		elseif value > 0 then
			CMDisplay = "A"
		end
	end

	--Heading
	local Headingdigits = { math.floor(MainPanel:get_argument_value(120) * 360) }

	local HeadingString = ""
	for index, value in ipairs(Headingdigits) do
		local HeadingdigitToAppend = value
		if value >= 359.99 then
			HeadingdigitToAppend = 0
		end
		HeadingString = tostring(value)
		if value < 10 then
			HeadingString = "00" ..
				value ..
				"T" --Using "T" for true heading, as even though we are pulling the mag compass from the UH-60 it is actually providing true heading in game... UH-60 base module issue
		elseif value >= 100 then
			HeadingString = "" ..
				value ..
				"T" --Using "T" for true heading, as even though we are pulling the mag compass from the UH-60 it is actually providing true heading in game... UH-60 base module issue
		elseif value >= 10 then
			HeadingString = "0" ..
				value ..
				"T" --Using "T" for true heading, as even though we are pulling the mag compass from the UH-60 it is actually providing true heading in game... UH-60 base module issue
		end
	end

	--Fuel (Internal)
	local Fueldigits = { math.floor(FuelInfo) }

	local FuelString = ""
	for index, value in ipairs(Fueldigits) do
		local FueldigitToAppend = value
		if value >= 8889 then
			FueldigitToAppend = 0
		end
		FuelString = FuelString .. FueldigitToAppend
	end

	--Aux Fuel
	if AuxFuelTank == 1 then
		AuxFuelString = AuxFuelInfoLI
	elseif AuxFuelTank == 0 then
		AuxFuelString = AuxFuelInfoLO
	end

	--Radios
	--AN/ARC 201 FM1
	local FM1digits = { math.floor(ARC201FM1Freq / 1000) }

	local FM1String = ""
	for index, value in ipairs(FM1digits) do
		local FM1digitToAppend = value
		if value >= 88000 then
			FM1digitToAppend = 88000
		end
		FM1String = FM1String .. FM1digitToAppend
	end

	--AN/ARC 164 UHF
	local UHFdigits = { math.floor(UHFFreq / 1000) }

	local UHFString = ""
	for index, value in ipairs(UHFdigits) do
		local UHFdigitToAppend = value
		if value >= 399975 then
			UHFdigitToAppend = 399975
		end
		UHFString = UHFString .. UHFdigitToAppend
	end

	--AN/ARC 186 VHF
	local VHFdigits = { math.floor(ARC186Freq / 1000) }

	local VHFString = ""
	for index, value in ipairs(VHFdigits) do
		local VHFdigitToAppend = value
		if value >= 152000 then
			VHFdigitToAppend = 152000
		end
		VHFString = VHFString .. VHFdigitToAppend
	end

	--AN/ARC 201 FM2
	local FM2digits = { math.floor(ARC201FM2Freq / 1000) }

	local FM2String = ""
	for index, value in ipairs(FM2digits) do
		local FM2digitToAppend = value
		if value >= 88000 then
			FM2digitToAppend = 88000
		end
		FM2String = FM2String .. FM2digitToAppend
	end

	--AN/ARC 220 HF
	local HFdigits = { math.floor(HFFreq / 1000) }

	local HFString = ""
	for index, value in ipairs(HFdigits) do
		local HFdigitToAppend = value
		if value >= 30000 then
			HFdigitToAppend = 30000
		end
		HFString = HFString .. HFdigitToAppend
	end

	--Pilot ICP
	local ICPdigits = { math.floor(MainPanel:get_argument_value(400) * 5) }

	local ICPdisplay = ""
	for index, value in ipairs(ICPdigits) do
		local ICPdisplayToAppend = value
		if value >= 10 then
			ICPdisplayToAppend = 0
		end
		ICPdisplay = ICPdisplay .. ICPdisplayToAppend
		if value == 0 then
			RadioDisplay = "000000"
			RadioDisplay1 = "I"
			RadioDisplay2 = "C"
		elseif value == 1 then
			RadioDisplay = FM1String
			RadioDisplay1 = "F"
			RadioDisplay2 = "1"
		elseif value == 2 then
			RadioDisplay = UHFString
			RadioDisplay1 = "U"
			RadioDisplay2 = "H"
		elseif value == 3 then
			RadioDisplay = VHFString
			RadioDisplay1 = "V"
			RadioDisplay2 = "H"
		elseif value == 4 then
			RadioDisplay = FM2String
			RadioDisplay1 = "F"
			RadioDisplay2 = "2"
		elseif value == 5 then
			RadioDisplay = 2 --HFString (Commented out & hard coded to 2 (matches SRS) until HF Radio Implimented for UH-60)
			RadioDisplay1 = "H"
			RadioDisplay2 = "F"
		end
	end

	--Armed Blackhawk Weapons (Note: Needs version 5.1 or later to work)

	local RocketPairSwitch = RocketInfo

	if RocketPairSwitch == 0 then
		RocketNum = "RKT1"
	elseif (RocketPairSwitch > 0.0 and RocketPairSwitch <= 0.15) then
		RocketNum = "RKT2"
	elseif (RocketPairSwitch > 0.15 and RocketPairSwitch <= 0.21) then
		RocketNum = "RKT3"
	elseif (RocketPairSwitch > 0.21 and RocketPairSwitch <= 0.32) then
		RocketNum = "RKT4"
	elseif (RocketPairSwitch > 0.32 and RocketPairSwitch <= 0.49) then
		RocketNum = "RKT5"
	elseif RocketPairSwitch == 0.5 then
		RocketNum = "RKT6"
	elseif RocketPairSwitch >= 0.51 then
		RocketNum = "RKTS"
	end

	local WepsSelectordigits = { math.floor(WepsRotaryInfo) }

	local WepsSelectordisplay = ""
	for index, value in ipairs(WepsSelectordigits) do
		local WepsSelectordisplayToAppend = value
		if value >= 5 then
			WepsSelectordisplayToAppend = 5
		end
		WepsSelectordisplay = WepsSelectordisplay .. WepsSelectordisplayToAppend
		if value == 1 then
			WepsSelectorDisplay1 = "SAFE"
		elseif value == 2 then
			WepsSelectorDisplay1 = "GUNS"
		elseif value == 3 then
			WepsSelectorDisplay1 = RocketNum
		elseif value == 4 then
			WepsSelectorDisplay1 = "MSL"
		elseif value == 5 then
			WepsSelectorDisplay1 = "TORP"
		end
	end

	--Send info to UFC components
	return ufcUtils.buildSimAppProUFCPayload({
		scratchPadNumbers = RadioDisplay, --Freq of Slectected Radio
		option1 = radarAltitudeString, --Altitiude
		option2 = HeadingString, --Heading
		option3 = FuelString, --Total Fuel (Internal)
		option4 = AuxFuelString, --Aux Fuel (Inboard or Outboard)
		option5 = WepsSelectorDisplay1, --Armed Blackhawk Rotary Selector Indication
		com1 = flarecount, --Flare Count
		com2 = chaffcount, --Chaff Count
		scratchPadString1 = RadioDisplay1, --RadioType1
		scratchPadString2 = RadioDisplay2 --RadioType2
	})
end

return ufcPatchUH60 --v2.1 by ANDR0ID
