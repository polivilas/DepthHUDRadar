////////////////////////////////////////////////
// -- Depth HUD : Radar                       //
// by Hurricaaane (Ha3)                       //
//                                            //
// http://www.youtube.com/user/Hurricaaane    //
//--------------------------------------------//
// Main autorun file, with drawing functions  //
////////////////////////////////////////////////

if SERVER then return end 

include("cl_dhradar_beacon.lua")
include("cl_dhradar_beaconspanel.lua")

dhradar_dat = {}

dhradar_dat._referenceRadarAngles = nil;
dhradar_dat._referenceRadarPos    = nil;

dhradar_dat.DEBUG_RT = false;

dhradar_dat.RT = nil;
dhradar_dat.RT_INVALID = nil;
dhradar_dat.RT_SIZE = {128,128}; // in the dhradar_dat.RT file
dhradar_dat.MATERIAL = Material("depthhud/x_radarrt");
dhradar_dat.MATERIAL_ID = surface.GetTextureID("depthhud/x_radarrt");
dhradar_dat.RT_SIZESTEP = {};

dhradar_dat.STOR_walldata = {}
dhradar_dat.STOR_heightdata = {}
dhradar_dat.STOR_heightmin = -1
dhradar_dat.STOR_heightmax = -1

dhradar_dat.STOR_lastsize  = -1
dhradar_dat.STOR_lastscale = -1
dhradar_dat.STOR_lastxrel  = -1
dhradar_dat.STOR_lastyrel  = -1
dhradar_dat.STOR_lastorient = -181

dhradar_dat.STOR_lastdhradar_Pos = Vector(0,0,0)
dhradar_dat.STOR_lastdhradar_Pos_magnet = Vector(0,0,0)
dhradar_dat.CONV_RadarPos = Vector(0,0,0)

dhradar_dat.STOR_circlebuffer = {}

dhradar_dat.STOR_TRASHTABLE_TraceData = {}
dhradar_dat.STOR_TRASHTABLE_TraceRes = {}
dhradar_dat.STOR_TRASHTABLE_FindFunction = {}
dhradar_dat.STOR_RadarTrashColor = Color(0,255,255,255)
dhradar_dat.STOR_RadarTrashVector_Position = Vector(0,0,0)

dhradar_dat.STOR_BeaconNamesTable = {}



dhradar_dat.ui_ringcolor   = Color(192,230,255,255)
dhradar_dat.ui_circlecolor = Color(32,64,94,128)
dhradar_dat.ui_shadowColor = Color(0,0,0,128)

dhradar_dat.ui_rt_floorcolor  = dhradar_dat.ui_ringcolor
dhradar_dat.ui_rt_unwalkcolor = dhradar_dat.ui_circlecolor

dhradar_dat.ui_forwardexplore = { 0 , 0 , 0.1 }
dhradar_dat.ui_forward_reladd = 0.1
dhradar_dat.ui_upexplore = { 0 , 0 , 0.1 }
dhradar_dat.ui_up_reladd = 0.05
dhradar_dat.ui_forwardreload    = false
dhradar_dat.ui_forwardpressed   = false
dhradar_dat.ui_forwardlastoccur = 0
dhradar_dat.ui_forward_delay    = 1.0

dhradar_dat.ui_scaleexplore = { 0 , 0 , 0.1 }
dhradar_dat.ui_scale_reladd = 0.1

dhradar_dat.ui_forwardlastoccur = 0
dhradar_dat.ui_forward_delay    = 1.0

local dhradar_cvars = {}

dhradar_cvars.dhradar_enable = 0;
dhradar_cvars.dhradar_range = 0;
dhradar_cvars.dhradar_showwalls = 0;
dhradar_cvars.dhradar_showheights = 0;
dhradar_cvars.dhradar_showheights_tolerance = 0;
dhradar_cvars.dhradar_forwardexplore = 0;
dhradar_cvars.dhradar_scaleexplore = 0;

dhradar_cvars.dhradar_ui_scale = 0;
dhradar_cvars.dhradar_ui_size = 0;
dhradar_cvars.dhradar_ui_pinscale = 0;
dhradar_cvars.dhradar_ui_x_rel = 0;
dhradar_cvars.dhradar_ui_y_rel = 0;
dhradar_cvars.dhradar_ui_showplayernames = 0;
dhradar_cvars.dhradar_ui_showplayeriffriend = 0;

dhradar_cvars.dhradar_col_ring_r = 0;
dhradar_cvars.dhradar_col_ring_g = 0;
dhradar_cvars.dhradar_col_ring_b = 0;
dhradar_cvars.dhradar_col_ring_a = 0;

dhradar_cvars.dhradar_col_circle_r = 0;
dhradar_cvars.dhradar_col_circle_g = 0;
dhradar_cvars.dhradar_col_circle_b = 0;
dhradar_cvars.dhradar_col_circle_a = 0;



local PARAM_HEIGHT_TOLERANCE       = 110
local PARAM_HEIGHT_PLAYERHEIGHTDEF = 0.3
local PARAM_SCALEBASE        = 128
local PARAM_WALLDRAW_MIDLEN  = 42
local PARAM_WALLDRAW_MAXSTOR = 180
local PARAM_WALLDRAW_ANGLE   = 2
local PARAM_WALLDRAW_ITER    = 180
local PARAM_WALLDRAW_FADE    = 1 //INTEGER
local PARAM_WALLDRAW_Accum   = 0
local PARAM_HEIGHTDRAW_CIRCLERES  = 64
local PARAM_HEIGHTDRAW_Step       = 2
local PARAM_HEIGHTDRAW_HasRecalc  = false
local PARAM_HEIGHTDRAW_STEP_MIN   = 1
local PARAM_HEIGHTDRAW_STEP_MAX   = 2
local PARAM_HEIGHTDRAW_SEARCHLIM  = 1.2
local PARAM_HEIGHTDRAW_STEP_MIN_IF_HIGHSCALE  = 1
local PARAM_HEIGHTDRAW_HIGHSCALE_CAP          = 25

local TIME_LastPlayerFind = 0
local TIME_LastEntityFind = 0
local TIME_DELAY_PLY = 2.0
local TIME_DELAY_ENT = 0.25

local TIME_WALLDRAW_LastSearch = 0
local TIME_WALLDRAW_DELAY = 0.15
local TIME_HEIGHTDRAW_LastSearch = 0
local TIME_HEIGHTDRAW_DELAY = 0.15
local TIME_HEIGHTDRAW_LastPrecise  = 0
local TIME_HEIGHTDRAW_PRECISEDELAY = 0.25

local FINDER_Players = {}
local FINDER_FoundTable = {}
local FINDER_AllFoundEnts = {}
local FINDER_AllFoundEntsCount = 0





local ui_xCenter  = 0
local ui_yCenter  = 0
local ui_size     = 0
local ui_pinScale = 0
dhradar_dat.ui_scale = 0

//Textures
dhradar_tex = {}
dhradar_tex.tex_sp_signal       = surface.GetTextureID("depthhud/x_square")
dhradar_tex.tex_sp_dirsignal    = surface.GetTextureID("depthhud/x_visuptri")
dhradar_tex.tex_sp_arrowsignal  = surface.GetTextureID("depthhud/x_visuptrilong")
dhradar_tex.tex_sp_cone         = surface.GetTextureID("depthhud/x_viscone")
dhradar_tex.tex_sp_circle       = surface.GetTextureID("depthhud/x_circlesolid")
dhradar_tex.tex_sp_ring         = surface.GetTextureID("depthhud/x_radarring")
dhradar_tex.tex_sp_cross        = surface.GetTextureID("depthhud/x_cross")


dhradar_tex.tex_ui_circle       = dhradar_tex.tex_sp_circle
dhradar_tex.tex_ui_ring         = dhradar_tex.tex_sp_ring

dhradar_tex.tex_pl_signal_self  = dhradar_tex.tex_sp_circle
dhradar_tex.tex_pl_signal_alive = dhradar_tex.tex_sp_signal
dhradar_tex.tex_pl_signal_dead  = dhradar_tex.tex_sp_cross
dhradar_tex.tex_pl_dirsignal    = dhradar_tex.tex_sp_dirsignal
dhradar_tex.tex_pl_cone         = dhradar_tex.tex_sp_cone

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
//// REFERENCE FUNCTIONS .

function dhradar_Angles()
	return dhradar_dat._referenceRadarAngles
end

function dhradar_Pos()
	return dhradar_dat._referenceRadarPos
end

local function dhradar_SetAngles( angles )
	dhradar_dat._referenceRadarAngles = angles
end

local function dhradar_SetPos( pos )
	dhradar_dat._referenceRadarPos = pos
end

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
//// INITIALIZATION FUNCTIONS .

local function dhradar_RegisterCVars()
	dhradar_cvars.dhradar_enable = CreateClientConVar("dhradar_enable", "1", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_enable","dhradar_enable")
	cvars.AddChangeCallback("dhradar_enable", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_enable = tonumber(newvalue)
	end,"dhradar_enable")

	dhradar_cvars.dhradar_range = CreateClientConVar("dhradar_range", "4096", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_range","dhradar_range")
	cvars.AddChangeCallback("dhradar_range", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_range = tonumber(newvalue)
	end,"dhradar_range")

	dhradar_cvars.dhradar_showwalls = CreateClientConVar("dhradar_showwalls", "0", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_showwalls","dhradar_showwalls")
	cvars.AddChangeCallback("dhradar_showwalls", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_showwalls = tonumber(newvalue)
	end,"dhradar_showwalls")

	dhradar_cvars.dhradar_showheights = CreateClientConVar("dhradar_showheights", "0", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_showheights","dhradar_showheights")
	cvars.AddChangeCallback("dhradar_showheights", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_showheights = tonumber(newvalue)
	end,"dhradar_showheights")

	dhradar_cvars.dhradar_showheights_tolerance = CreateClientConVar("dhradar_showheights_tolerance", "110", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_showheights_tolerance","dhradar_showheights_tolerance")
	cvars.AddChangeCallback("dhradar_showheights_tolerance", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_showheights_tolerance = tonumber(newvalue)
	end,"dhradar_showheights_tolerance")

	dhradar_cvars.dhradar_forwardexplore = CreateClientConVar("dhradar_forwardexplore", "0", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_forwardexplore","dhradar_forwardexplore")
	cvars.AddChangeCallback("dhradar_forwardexplore", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_forwardexplore = tonumber(newvalue)
	end,"dhradar_forwardexplore")

	dhradar_cvars.dhradar_scaleexplore = CreateClientConVar("dhradar_scaleexplore", "0", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_scaleexplore","dhradar_scaleexplore")
	cvars.AddChangeCallback("dhradar_scaleexplore", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_scaleexplore = tonumber(newvalue)
	end,"dhradar_scaleexplore")


	dhradar_cvars.dhradar_ui_scale = CreateClientConVar("dhradar_ui_scale", "7", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_ui_scale","dhradar_ui_scale")
	cvars.AddChangeCallback("dhradar_ui_scale", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_ui_scale = tonumber(newvalue)
	end,"dhradar_ui_scale")

	dhradar_cvars.dhradar_ui_size = CreateClientConVar("dhradar_ui_size", "256", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_ui_size","dhradar_ui_size")
	cvars.AddChangeCallback("dhradar_ui_size", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_ui_size = tonumber(newvalue)
	end,"dhradar_ui_size")

	dhradar_cvars.dhradar_ui_pinscale = CreateClientConVar("dhradar_ui_pinscale", "1", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_ui_pinscale","dhradar_ui_pinscale")
	cvars.AddChangeCallback("dhradar_ui_pinscale", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_ui_pinscale = tonumber(newvalue)
	end,"dhradar_ui_pinscale")

	dhradar_cvars.dhradar_ui_x_rel = CreateClientConVar("dhradar_ui_x_rel", "0.3", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_ui_x_rel","dhradar_ui_x_rel")
	cvars.AddChangeCallback("dhradar_ui_x_rel", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_ui_x_rel = tonumber(newvalue)
	end,"dhradar_ui_x_rel")

	dhradar_cvars.dhradar_ui_y_rel = CreateClientConVar("dhradar_ui_y_rel", "0.7", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_ui_y_rel","dhradar_ui_y_rel")
	cvars.AddChangeCallback("dhradar_ui_y_rel", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_ui_y_rel = tonumber(newvalue)
	end,"dhradar_ui_y_rel")

	dhradar_cvars.dhradar_ui_showplayernames = CreateClientConVar("dhradar_ui_showplayernames", "1", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_ui_showplayernames","dhradar_ui_showplayernames")
	cvars.AddChangeCallback("dhradar_ui_showplayernames", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_ui_showplayernames = tonumber(newvalue)
	end,"dhradar_ui_showplayernames")

	dhradar_cvars.dhradar_ui_showplayeriffriend = CreateClientConVar("dhradar_ui_showplayeriffriend", "0", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_ui_showplayeriffriend","dhradar_ui_showplayeriffriend")
	cvars.AddChangeCallback("dhradar_ui_showplayeriffriend", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_ui_showplayeriffriend = tonumber(newvalue)
	end,"dhradar_ui_showplayeriffriend")


	dhradar_cvars.dhradar_col_ring_r = CreateClientConVar("dhradar_col_ring_r",   "192", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_col_ring_r","dhradar_col_ring_r")
	cvars.AddChangeCallback("dhradar_col_ring_r", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_col_ring_r = tonumber(newvalue)
	end,"dhradar_col_ring_r")

	dhradar_cvars.dhradar_col_ring_g = CreateClientConVar("dhradar_col_ring_g",   "230", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_col_ring_g","dhradar_col_ring_g")
	cvars.AddChangeCallback("dhradar_col_ring_g", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_col_ring_g = tonumber(newvalue)
	end,"dhradar_col_ring_g")

	dhradar_cvars.dhradar_col_ring_b = CreateClientConVar("dhradar_col_ring_b",   "255", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_col_ring_b","dhradar_col_ring_b")
	cvars.AddChangeCallback("dhradar_col_ring_b", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_col_ring_b = tonumber(newvalue)
	end,"dhradar_col_ring_b")

	dhradar_cvars.dhradar_col_ring_a = CreateClientConVar("dhradar_col_ring_a",   "255", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_col_ring_a","dhradar_col_ring_a")
	cvars.AddChangeCallback("dhradar_col_ring_a", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_col_ring_a = tonumber(newvalue)
	end,"dhradar_col_ring_a")


	dhradar_cvars.dhradar_col_circle_r = CreateClientConVar("dhradar_col_circle_r", "32", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_col_circle_r","dhradar_col_circle_r")
	cvars.AddChangeCallback("dhradar_col_circle_r", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_col_circle_r = tonumber(newvalue)
	end,"dhradar_col_circle_r")

	dhradar_cvars.dhradar_col_circle_g = CreateClientConVar("dhradar_col_circle_g", "64", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_col_circle_g","dhradar_col_circle_g")
	cvars.AddChangeCallback("dhradar_col_circle_g", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_col_circle_g = tonumber(newvalue)
	end,"dhradar_col_circle_g")

	dhradar_cvars.dhradar_col_circle_b = CreateClientConVar("dhradar_col_circle_b", "96", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_col_circle_b","dhradar_col_circle_b")
	cvars.AddChangeCallback("dhradar_col_circle_b", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_col_circle_b = tonumber(newvalue)
	end,"dhradar_col_circle_b")

	dhradar_cvars.dhradar_col_circle_a = CreateClientConVar("dhradar_col_circle_a", "128", true, false):GetFloat()
	cvars.RemoveChangeCallback("dhradar_col_circle_a","dhradar_col_circle_a")
	cvars.AddChangeCallback("dhradar_col_circle_a", function(cvar, oldvalue, newvalue)
		dhradar_cvars.dhradar_col_circle_a = tonumber(newvalue)
	end,"dhradar_col_circle_a")
end


local function dhradar_LoadAllBeacons()
	dhradar.RemoveAll()

	local path = "depthhud_radar_beacon/"
	for _,file in pairs(file.Find("lua/"..path.."*.lua","GAME")) do
		BEACON = {}
		
		include(path..file)
		
		local keyword = string.Replace(file, ".lua", "")
		dhradar.Register(keyword, BEACON)
	end
		if (!gmod or !gmod.GetGamemode()) then
		print("EARLY, HOLDING")
		timer.Simple( 15, function()
			print("Late loading gamemode extras: ".. gmod.GetGamemode().FolderName)
			for _,file in pairs(file.Find("data/DepthHudRadar/" .. gmod.GetGamemode().FolderName.."/*.lua","GAME")) do
				BEACON = {}
			
				include("../data/DepthHudRadar/" .. gmod.GetGamemode().FolderName.."/"..file)
				
				local keyword = string.Replace(file, ".lua", "")
				dhradar.Register(keyword, BEACON)
			end
		end)
	else
		print("Loading gamemode extras: ".. gmod.GetGamemode().FolderName)
		for _,file in pairs(file.Find("data/DepthHudRadar/" .. gmod.GetGamemode().FolderName.."/*.lua","GAME")) do
			BEACON = {}
		
			include("../data/DepthHudRadar/" .. gmod.GetGamemode().FolderName.."/"..file)
			
			local keyword = string.Replace(file, ".lua", "")
			dhradar.Register(keyword, BEACON)
		end
	end
	dhradar_dat.STOR_BeaconNamesTable = dhradar.GetNamesTable()
	
	print("Beacon registered : ")
	for k,name in pairs( dhradar_dat.STOR_BeaconNamesTable ) do
		Msg("["..name.."] ")
	end
	Msg("\n")
	
	hook.Remove("HUDPaint","dhradarHudPaint")
	hook.Add("HUDPaint","dhradarHudPaint",dhradarHudPaint)
end
concommand.Add("dhradar_reloadbeacons",dhradar_LoadAllBeacons)

local function dhradar_RestoreStateVars()
	dhradar_dat.STOR_lastdhradar_Pos = dhradar_Pos()
	dhradar_dat.STOR_lastsize = ui_size
	dhradar_dat.STOR_lastxrel = ui_xCenter
	dhradar_dat.STOR_lastyrel = ui_yCenter
	dhradar_dat.STOR_lastorient = math.floor(dhradar_Angles().y) - 90
	dhradar_dat.STOR_lastscale  = dhradar_dat.ui_scale
end

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
//// HEIGHT DRAWING FUNCTIONS .

local function calcUnitsReturn()
	dhradar_dat.RT_SIZESTEP = {}
	dhradar_dat.RT_SIZESTEP[1] = math.floor(dhradar_dat.RT_SIZE[1] / PARAM_HEIGHTDRAW_Step)
	dhradar_dat.RT_SIZESTEP[2] = math.floor(dhradar_dat.RT_SIZE[2] / PARAM_HEIGHTDRAW_Step)

	local UNIT = 2/dhradar_dat.RT_SIZESTEP[1]
	
	dhradar_dat.CONV_RadarPos = Vector(dhradar_Pos().x, dhradar_Pos().y, dhradar_Pos().z)
	local xpan = dhradar_dat.CONV_RadarPos.x % (UNIT * PARAM_SCALEBASE * dhradar_dat.ui_scale)
	local ypan = dhradar_dat.CONV_RadarPos.y % (UNIT * PARAM_SCALEBASE * dhradar_dat.ui_scale)
	
	dhradar_dat.CONV_RadarPos.x = math.floor(dhradar_dat.CONV_RadarPos.x - xpan)
	dhradar_dat.CONV_RadarPos.y = math.floor(dhradar_dat.CONV_RadarPos.y - ypan)
	
	return dhradar_dat.RT_SIZESTEP,UNIT,dhradar_dat.CONV_RadarPos,xpan,ypan
end

local function calcCircle()
	dhradar_dat.STOR_RadarTrashVector_Position = dhradar_Pos() - dhradar_dat.STOR_lastdhradar_Pos_magnet
	local oscr_xpan = dhradar_dat.STOR_RadarTrashVector_Position.x / (PARAM_SCALEBASE * dhradar_dat.ui_scale * 0.5 * PARAM_HEIGHTDRAW_Step)
	local oscr_ypan = dhradar_dat.STOR_RadarTrashVector_Position.y / (PARAM_SCALEBASE * dhradar_dat.ui_scale * 0.5 * PARAM_HEIGHTDRAW_Step)
		
	//Positionning data has changed
	if (dhradar_dat.STOR_lastsize != ui_size)
	   or (dhradar_dat.STOR_lastdhradar_Pos != dhradar_Pos())
	   or (dhradar_dat.STOR_lastxrel != ui_xCenter)
	   or (dhradar_dat.STOR_lastyrel != ui_yCenter)
	   or not dhradar_dat.STOR_circlebuffer[1]
	   then
	   
		local orient = math.floor(dhradar_Angles().y) - 90
		dhradar_dat.STOR_circlebuffer = {}
		
		for i=1,PARAM_HEIGHTDRAW_CIRCLERES do
			dhradar_dat.STOR_circlebuffer[i] = {}
			dhradar_dat.STOR_circlebuffer[i].x = ui_xCenter + math.cos(math.rad( (i*360)/PARAM_HEIGHTDRAW_CIRCLERES ))*ui_size*0.5*0.99
			dhradar_dat.STOR_circlebuffer[i].y = ui_yCenter + math.sin(math.rad( (i*360)/PARAM_HEIGHTDRAW_CIRCLERES ))*ui_size*0.5*0.99
			dhradar_dat.STOR_circlebuffer[i].u = (math.cos(math.rad( -orient + (i*360)/PARAM_HEIGHTDRAW_CIRCLERES )) + 1)*0.5 + oscr_xpan
			dhradar_dat.STOR_circlebuffer[i].v = -(math.sin(math.rad( -orient + (i*360)/PARAM_HEIGHTDRAW_CIRCLERES )) + 1)*0.5 + oscr_ypan
		end
		
		
	//Orienting data has changed
	elseif (dhradar_dat.STOR_lastorient != math.floor(dhradar_Angles().y)) then
		local orient = math.floor(dhradar_Angles().y) - 90
	
		for i=1,PARAM_HEIGHTDRAW_CIRCLERES do
			dhradar_dat.STOR_circlebuffer[i].u =  (math.cos(math.rad( -orient + (i*360)/PARAM_HEIGHTDRAW_CIRCLERES )) + 1) * 0.5 + oscr_xpan
			dhradar_dat.STOR_circlebuffer[i].v = -(math.sin(math.rad( -orient + (i*360)/PARAM_HEIGHTDRAW_CIRCLERES )) + 1) * 0.5 + oscr_ypan
		end
		
		
	//Nothing changed
	else
		return
	end
end

local function dhradar_InitializeRenderTarget()
	if (dhradar_dat.RT or dhradar_dat.RT_INVALID) then return end
	
	dhradar_dat.RT = GetRenderTarget("DhradarRT",dhradar_dat.RT_SIZE[1],dhradar_dat.RT_SIZE[2])
	if (not dhradar_dat.RT) then
		dhradar_dat.RT_INVALID = true
		return
	end

end

local function dhradar_FindHeights()
	PARAM_HEIGHTDRAW_HasRecalc = false
	if dhradar_cvars.dhradar_showheights <= 0 then return end
	
	if (dhradar_dat.RT_INVALID) then return end

	if (RealTime() < (TIME_HEIGHTDRAW_LastSearch + TIME_HEIGHTDRAW_DELAY)) and (dhradar_dat.STOR_lastscale == dhradar_dat.ui_scale) then return end
	
	
	if ((RealTime() < (TIME_HEIGHTDRAW_LastPrecise + TIME_HEIGHTDRAW_PRECISEDELAY)) or ( not (dhradar_dat.ui_scale >= PARAM_HEIGHTDRAW_HIGHSCALE_CAP) and (PARAM_HEIGHTDRAW_Step <= PARAM_HEIGHTDRAW_STEP_MIN)) or ((dhradar_dat.ui_scale >= PARAM_HEIGHTDRAW_HIGHSCALE_CAP) and (PARAM_HEIGHTDRAW_Step <= PARAM_HEIGHTDRAW_STEP_MIN_IF_HIGHSCALE)) ) and (dhradar_dat.STOR_lastdhradar_Pos == dhradar_Pos()) and (dhradar_dat.STOR_lastscale == dhradar_dat.ui_scale) then return end

	TIME_HEIGHTDRAW_LastSearch = RealTime()
	
	local CHANGED_STEP = false
	
	if ((PARAM_HEIGHTDRAW_Step > PARAM_HEIGHTDRAW_STEP_MIN) or ((dhradar_dat.ui_scale >= PARAM_HEIGHTDRAW_HIGHSCALE_CAP) and (PARAM_HEIGHTDRAW_Step > PARAM_HEIGHTDRAW_STEP_MIN_IF_HIGHSCALE))) and (RealTime() > (TIME_HEIGHTDRAW_LastPrecise + TIME_HEIGHTDRAW_PRECISEDELAY)) then
		PARAM_HEIGHTDRAW_Step = PARAM_HEIGHTDRAW_Step - 1
		CHANGED_STEP = true
		//print("changing step to "..PARAM_HEIGHTDRAW_Step)
	end
	
	
	local UNIT,xpan,ypan
	dhradar_dat.RT_SIZESTEP,UNIT,dhradar_dat.CONV_RadarPos,xpan,ypan = calcUnitsReturn()
	
	
	if (dhradar_dat.CONV_RadarPos != dhradar_dat.STOR_lastdhradar_Pos_magnet) and not CHANGED_STEP then
		PARAM_HEIGHTDRAW_Step = PARAM_HEIGHTDRAW_STEP_MAX            //When moving, radar is unprecise
		dhradar_dat.RT_SIZESTEP,UNIT,dhradar_dat.CONV_RadarPos,xpan,ypan = calcUnitsReturn()
	end
	
	if  dhradar_dat.DEBUG_RT or CHANGED_STEP or (dhradar_dat.CONV_RadarPos != dhradar_dat.STOR_lastdhradar_Pos_magnet) then
		PARAM_HEIGHTDRAW_HasRecalc = true
		
		dhradar_dat.STOR_lastdhradar_Pos_magnet = dhradar_dat.CONV_RadarPos //STOR IMPORTANT
		
		//Calc
		local minheight = -1
		local maxheight = 1
		
		dhradar_dat.STOR_heightdata = {}
		for j = 1 ,dhradar_dat.RT_SIZESTEP[2] do
			local rely = 2*(j - 1)/(dhradar_dat.RT_SIZESTEP[2]-1)-1
			
			dhradar_dat.STOR_heightdata[j] = {}
			for i = 1 ,dhradar_dat.RT_SIZESTEP[1] do
				local height = 0
				
				local relx = 2*(i - 1)/(dhradar_dat.RT_SIZESTEP[1]-1)-1
				
				if ((relx^2 + rely^2) < PARAM_HEIGHTDRAW_SEARCHLIM) then
					dhradar_dat.STOR_RadarTrashVector_Position = Vector( math.floor(relx * ( PARAM_SCALEBASE * dhradar_dat.ui_scale )) , math.floor(rely * ( PARAM_SCALEBASE * dhradar_dat.ui_scale )) , 0 )
					
					local point_contents = util.PointContents( dhradar_dat.CONV_RadarPos + dhradar_dat.STOR_RadarTrashVector_Position )
					
					//print("point_contents A: ".. point_contents)
					local filter = bit.bor(CONTENTS_TESTFOGVOLUME ,CONTENTS_HITBOX , CONTENTS_TRANSLUCENT , CONTENTS_DETAIL , CONTENTS_DEBRIS , CONTENTS_TESTFOGVOLUME)
					point_contents = point_contents - (bit.band(point_contents,filter))
					//print("point_contents B: ".. point_contents)
					
					if (point_contents > 0) then
						if ((bit.band(point_contents , CONTENTS_WATER)) > 0) then						
							height = 0.5
						else						
							height = 1
						end
					else
						height = 0
					end
					
				else
					height = 1
				end
				
				dhradar_dat.STOR_heightdata[j][i] = height
				
				if (i == 1) and (j == 1) then
					minheight = height
					maxheight = height
				else
					if height < minheight then
						minheight = height
					elseif height > maxheight then
						maxheight = height
					end
				end
			end
		end
		
		/*dhradar_dat.STOR_heightmin = minheight
		dhradar_dat.STOR_heightmax = maxheight*/
		dhradar_dat.STOR_heightmin = 0
		dhradar_dat.STOR_heightmax = 1
		
		TIME_HEIGHTDRAW_LastPrecise = RealTime()
		
	end
	
	//print("generating step : " .. PARAM_HEIGHTDRAW_Step )
	if not PARAM_HEIGHTDRAW_HasRecalc then return end
	//print("recalcing...")
	
	local OldW,OldH = ScrW(),ScrH()
	local OldRT = render.GetRenderTarget()
	
	dhradar_dat.MATERIAL:SetTexture("$basetexture",dhradar_dat.RT)
	
	render.SetRenderTarget(dhradar_dat.RT)
	render.SetViewPort( 0, 0, dhradar_dat.RT_SIZE[1], dhradar_dat.RT_SIZE[2] )
	if (dhradar_dat.STOR_heightmax == dhradar_dat.STOR_heightmin) then
		render.ClearRenderTarget(dhradar_dat.RT,dhradar_dat.ui_rt_floorcolor)
	else
		render.ClearRenderTarget(dhradar_dat.RT,dhradar_dat.ui_rt_unwalkcolor)
	end
	
	local oscr_xpan = (xpan / (UNIT * PARAM_SCALEBASE * dhradar_dat.ui_scale ))*PARAM_HEIGHTDRAW_Step
	local oscr_ypan = (ypan / (UNIT * PARAM_SCALEBASE * dhradar_dat.ui_scale ))*PARAM_HEIGHTDRAW_Step
	local oscr_xpan = 0
	local oscr_ypan = 0
	
	cam.Start2D()
		for j=1,dhradar_dat.RT_SIZESTEP[2] do
			for i=1,dhradar_dat.RT_SIZESTEP[1] do
				local height = dhradar_dat.STOR_heightdata[j][i]
				local flo_pro = (height-dhradar_dat.STOR_heightmin)/(dhradar_dat.STOR_heightmax-dhradar_dat.STOR_heightmin)
				local uwk_pro = 1 - flo_pro
				if (dhradar_dat.STOR_heightmax == dhradar_dat.STOR_heightmin) then
					dhradar_dat.STOR_RadarTrashColor.r = dhradar_dat.ui_rt_floorcolor.r
					dhradar_dat.STOR_RadarTrashColor.g = dhradar_dat.ui_rt_floorcolor.g
					dhradar_dat.STOR_RadarTrashColor.b = dhradar_dat.ui_rt_floorcolor.b
					dhradar_dat.STOR_RadarTrashColor.a = dhradar_dat.ui_rt_floorcolor.a
				else
					dhradar_dat.STOR_RadarTrashColor.r = dhradar_dat.ui_rt_floorcolor.r * flo_pro + dhradar_dat.ui_rt_unwalkcolor.r * uwk_pro
					dhradar_dat.STOR_RadarTrashColor.g = dhradar_dat.ui_rt_floorcolor.g * flo_pro + dhradar_dat.ui_rt_unwalkcolor.g * uwk_pro
					dhradar_dat.STOR_RadarTrashColor.b = dhradar_dat.ui_rt_floorcolor.b * flo_pro + dhradar_dat.ui_rt_unwalkcolor.b * uwk_pro
					dhradar_dat.STOR_RadarTrashColor.a = dhradar_dat.ui_rt_floorcolor.a * flo_pro + dhradar_dat.ui_rt_unwalkcolor.a * uwk_pro
				end
				surface.SetDrawColor(dhradar_dat.STOR_RadarTrashColor.r, dhradar_dat.STOR_RadarTrashColor.g, dhradar_dat.STOR_RadarTrashColor.b, dhradar_dat.STOR_RadarTrashColor.a)
				surface.DrawRect((i-1)*PARAM_HEIGHTDRAW_Step - oscr_xpan, (j-1)*PARAM_HEIGHTDRAW_Step - oscr_ypan, PARAM_HEIGHTDRAW_Step, PARAM_HEIGHTDRAW_Step)
			end
		end
	cam.End2D()
	
	render.SetRenderTarget(OldRT);
	render.SetViewPort(0,0,OldW,OldH);
end

local function dhradar_DrawHeights()
	if dhradar_cvars.dhradar_showheights <= 0 then return end
	if (dhradar_dat.RT_INVALID) then return end
	
	calcCircle()
	
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetTexture(dhradar_dat.MATERIAL_ID)
	if (dhradar_dat.DEBUG_RT) then
		surface.DrawTexturedRect(16,512,64,64)
	else
		surface.DrawPoly(dhradar_dat.STOR_circlebuffer)
	end
end


///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
//// INTERNAL FUNCTION ... Do NOT use DrawSprite in your scripts !

function dhradar_DrawSprite(sprite, x, y, width, height, angle, r, g, b, a)
	local spriteid = 0
	if ( type(sprite) == "string" ) then
		spriteid = surface.GetTextureID(sprite)
	else
		spriteid = sprite
	end
	
	surface.SetTexture(spriteid)
	surface.SetDrawColor(r, g, b, a)
	surface.DrawTexturedRectRotated(x, y, width, height, angle)
end
function dhradar_DrawSpriteMaterial(mat, x, y, width, height, angle, r, g, b, a)	
	surface.SetMaterial(mat)
	surface.SetDrawColor(r, g, b, a)
	surface.DrawTexturedRectRotated(x, y, width, height, angle)
end


///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
//// The functions you can use in your script to draw :

function dhradar_DrawText(text, angle, distFromCenter , textColor, drawShadow)
	local newangle = angle + dhradar_Angles().y - 90

	local xPos = ui_xCenter + math.cos( math.rad(newangle) ) * (ui_size*0.5) * distFromCenter
	local yPos = ui_yCenter + math.sin( math.rad(newangle) ) * (ui_size*0.5) * distFromCenter
	if (drawShadow or false) then
		draw.SimpleText(text, "DefaultSmall", xPos+1, yPos+1, dhradar_dat.ui_shadowColor, 1, 1)
	end
	draw.SimpleText(text, "DefaultSmall", xPos, yPos, textColor, 1, 1)
end

function dhradar_DrawPin(sprite, angle, distFromCenter , color, spriteScale, spriteAngle, distanceAlter, alterMin)
	local newangle = angle + dhradar_Angles().y - 90
	local scale = ui_size * 0.1 * spriteScale * ui_pinScale * 0.6
	
	if scale <= 3 then return end
	
	if (distanceAlter) then
		local alterMinRe = alterMin or 0.30
		scale = scale * (alterMinRe + (1 - distFromCenter^10) * (1 - alterMinRe))
	end

	local xPos = ui_xCenter + math.cos( math.rad(newangle) ) * (ui_size*0.5) * distFromCenter
	local yPos = ui_yCenter + math.sin( math.rad(newangle) ) * (ui_size*0.5) * distFromCenter
	dhradar_DrawSprite( sprite , xPos, yPos, scale, scale , spriteAngle ,  color.r,  color.g,  color.b, color.a )
end
function dhradar_DrawMatPin(mat, angle, distFromCenter , color, spriteScale, spriteAngle, distanceAlter, alterMin)
	local newangle = angle + dhradar_Angles().y - 90
	local scale = ui_size * 0.1 * spriteScale * ui_pinScale * 0.6
	
	if scale <= 3 then return end
	
	if (distanceAlter) then
		local alterMinRe = alterMin or 0.30
		scale = scale * (alterMinRe + (1 - distFromCenter^10) * (1 - alterMinRe))
	end

	local xPos = ui_xCenter + math.cos( math.rad(newangle) ) * (ui_size*0.5) * distFromCenter
	local yPos = ui_yCenter + math.sin( math.rad(newangle) ) * (ui_size*0.5) * distFromCenter
	dhradar_DrawSpriteMaterial( mat , xPos, yPos, scale, scale , spriteAngle ,  color.r,  color.g,  color.b, color.a )
end

function dhradar_DrawPolarLine(angleSt, distFromCenterSt, angleEn, distFromCenterEn, color)
	local dSt_angle = angleSt + dhradar_Angles().y - 90
	local dSt_xPos  = ui_xCenter + math.cos( math.rad(dSt_angle) ) * (ui_size*0.5) * distFromCenterSt
	local dSt_yPos  = ui_yCenter + math.sin( math.rad(dSt_angle) ) * (ui_size*0.5) * distFromCenterSt
	
	local dEn_angle = angleEn + dhradar_Angles().y - 90
	local dEn_xPos  = ui_xCenter + math.cos( math.rad(dEn_angle) ) * (ui_size*0.5) * distFromCenterEn
	local dEn_yPos  = ui_yCenter + math.sin( math.rad(dEn_angle) ) * (ui_size*0.5) * distFromCenterEn
	
	surface.SetDrawColor(color.r, color.g,color.b, color.a)
	surface.DrawLine(dSt_xPos, dSt_yPos, dEn_xPos, dEn_yPos)
end

function dhradar_CalcGetPolar( vectorWorldPos )
	//RelPos
	dhradar_dat.STOR_RadarTrashVector_Position = vectorWorldPos - dhradar_Pos()	
	local angle = -1 * dhradar_dat.STOR_RadarTrashVector_Position:Angle().y
	
	local isup  = 0
	if (dhradar_dat.STOR_RadarTrashVector_Position.z >= ((1 - PARAM_HEIGHT_PLAYERHEIGHTDEF) * dhradar_cvars.dhradar_showheights_tolerance)) then
		isup = 1
	elseif (dhradar_dat.STOR_RadarTrashVector_Position.z < ((-1 - PARAM_HEIGHT_PLAYERHEIGHTDEF) * dhradar_cvars.dhradar_showheights_tolerance)) then
		isup = -1
	end
	
	dhradar_dat.STOR_RadarTrashVector_Position.z = 0  //For Pythagoria math
	local dist  = math.Clamp(dhradar_dat.STOR_RadarTrashVector_Position:Length() * ( 1 / (math.Clamp( dhradar_dat.ui_scale , 0.1, 8192 ) * PARAM_SCALEBASE ) ) , 0, 1)
	
	return angle,dist,isup
end

function dhradar_CalcGenericAltitudeSprite(isup,normSprite,dirSprite,normAng,dirUp,dirDown)
	local sprite,spriteAngle
	
	if     (isup == 1) then
		sprite = dirSprite
		spriteAngle = dirUp
	elseif (isup == -1) then
		sprite = dirSprite
		spriteAngle = dirDown
	else
		sprite = normSprite
		spriteAngle = normAng
	end
	
	return sprite,spriteAngle
end

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
//// USEFUL FUNCTIONS FOR USER .

function dhradar_GetTexture( stringPredefName )
	if     stringPredefName == "square"   then return dhradar_tex.tex_sp_signal
	elseif stringPredefName == "triangle" then return dhradar_tex.tex_sp_dirsignal
	elseif stringPredefName == "arrow"    then return dhradar_tex.tex_sp_arrowsignal
	elseif stringPredefName == "cone"     then return dhradar_tex.tex_sp_cone
	elseif stringPredefName == "circle"   then return dhradar_tex.tex_sp_circle
	elseif stringPredefName == "ring"     then return dhradar_tex.tex_sp_ring
	elseif stringPredefName == "cross"    then return dhradar_tex.tex_sp_cross
	else return dhradar_tex.tex_sp_signal end
end

function dhradar_GetStyleData( stringPredefName )
	if     stringPredefName == "color_ring"   then return dhradar_dat.ui_ringcolor
	elseif stringPredefName == "color_circle" then return dhradar_dat.ui_circlecolor
	elseif stringPredefName == "color_shadow" then return dhradar_dat.ui_shadowcolor
	elseif stringPredefName == "ui_scale"     then return dhradar_dat.ui_scale
	else return nil end
end

function dhradar_StringNiceNameTransform( stringInput )
	local stringParts = string.Explode("_",stringInput)
	local stringOutput = ""
	for k,part in pairs(stringParts) do
		local len = string.len(part)
		if (len == 1) then
			stringOutput = stringOutput .. string.upper(part)
		elseif (len > 1) then
			stringOutput = stringOutput .. string.Left(string.upper(part),1) .. string.Right(part,len-1)
		end
		if (k != #stringParts) then stringOutput = stringOutput .. " " end
	end
	return stringOutput
end


///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
//// INTERNAL SOLITON SCAN FUNCTIONS .

local function dhradar_FindWalls()
	if dhradar_cvars.dhradar_showwalls <= 0 then return end

	if (CurTime() < (TIME_WALLDRAW_LastSearch + TIME_WALLDRAW_DELAY)) then return end
	
	dhradar_dat.STOR_TRASHTABLE_TraceData = {}
	dhradar_dat.STOR_TRASHTABLE_TraceData.start = dhradar_Pos()
	dhradar_dat.STOR_TRASHTABLE_TraceData.filter = nil
	dhradar_dat.STOR_TRASHTABLE_TraceData.mask   = MASK_SOLID_BRUSHONLY
	
	local traceAng = 0
	
	//Calc
	for i = 0 , (PARAM_WALLDRAW_ITER - 1) do
		PARAM_WALLDRAW_Accum = (PARAM_WALLDRAW_Accum + PARAM_WALLDRAW_ANGLE + 180) % 360 - 180
		dhradar_dat.STOR_TRASHTABLE_TraceData.endpos   = dhradar_Pos() + Angle(0,PARAM_WALLDRAW_Accum,0):Forward() * ( PARAM_SCALEBASE * dhradar_dat.ui_scale ) * 2
		dhradar_dat.STOR_TRASHTABLE_TraceRes = util.TraceLine(dhradar_dat.STOR_TRASHTABLE_TraceData)
		/*local traceNormalNoZ = trace.HitNormal
		traceNormalNoZ.z = 0
		traceNormalNoZ = traceNormalNoZ:Normalize()*/
		
		if dhradar_dat.STOR_TRASHTABLE_TraceRes.Hit and (dhradar_dat.STOR_TRASHTABLE_TraceRes.HitNormal.z < 0.9) and (dhradar_dat.STOR_TRASHTABLE_TraceRes.HitNormal.z > -0.1) then	
			local previsnil = (#dhradar_dat.STOR_walldata > 0) and (dhradar_dat.STOR_walldata[#dhradar_dat.STOR_walldata][1] == nil)
			if previsnil or ( (#dhradar_dat.STOR_walldata > 0) and (dhradar_dat.STOR_walldata[#dhradar_dat.STOR_walldata][1] - dhradar_dat.STOR_TRASHTABLE_TraceRes.HitPos):Length() <  PARAM_WALLDRAW_MIDLEN*(2 + 0.8*(dhradar_Pos() - dhradar_dat.STOR_TRASHTABLE_TraceRes.HitPos):Length() * (1 / PARAM_SCALEBASE) ) ) then
				if (#dhradar_dat.STOR_walldata >= PARAM_WALLDRAW_MAXSTOR) then
					table.remove(dhradar_dat.STOR_walldata,1)
				end
				/*
				if (#dhradar_dat.STOR_walldata > 1) and (not previsnil) and (not dhradar_dat.STOR_walldata[#dhradar_dat.STOR_walldata][2]) then
					local vect1 = dhradar_dat.STOR_walldata[#dhradar_dat.STOR_walldata-1][1]:Normalize()
					local vect2 = dhradar_dat.STOR_walldata[#dhradar_dat.STOR_walldata][1]:Normalize()
					if (vect1:DotProduct(vect2) < 0.3) then
						table.remove(dhradar_dat.STOR_walldata,#dhradar_dat.STOR_walldata)
					end
				end
				*/
				table.insert(dhradar_dat.STOR_walldata,{dhradar_dat.STOR_TRASHTABLE_TraceRes.HitPos,previsnil})
			else
				if (#dhradar_dat.STOR_walldata >= PARAM_WALLDRAW_MAXSTOR) then
					table.remove(dhradar_dat.STOR_walldata,1)
					table.remove(dhradar_dat.STOR_walldata,1)
				end
				if (#dhradar_dat.STOR_walldata > 0) and (dhradar_dat.STOR_walldata[#dhradar_dat.STOR_walldata][2]) then
					table.remove(dhradar_dat.STOR_walldata,#dhradar_dat.STOR_walldata)
					table.insert(dhradar_dat.STOR_walldata,{dhradar_dat.STOR_TRASHTABLE_TraceRes.HitPos,true})
				else
					table.insert(dhradar_dat.STOR_walldata,{nil,true})
					table.insert(dhradar_dat.STOR_walldata,{dhradar_dat.STOR_TRASHTABLE_TraceRes.HitPos,true})
				end
			end
		end
	end
	TIME_WALLDRAW_LastSearch = CurTime()
end

local function dhradar_DrawWalls()
	if dhradar_cvars.dhradar_showwalls <= 0 then return end
	
	//Render
	local angleSt,distSt,isupSt = 0
	local angleEn,distEn,isupEn = 0
	
	for k = 1,#dhradar_dat.STOR_walldata-1 do
		if (dhradar_dat.STOR_walldata[k][1] != nil) and (dhradar_dat.STOR_walldata[k+1][1] != nil) then
			angleSt,distSt,isupSt = dhradar_CalcGetPolar(dhradar_dat.STOR_walldata[k][1]  )
			if (distSt < 1) then
				angleEn,distEn,isupEn = dhradar_CalcGetPolar(dhradar_dat.STOR_walldata[k+1][1])
				if (distEn < 1) then
					local alpha = PARAM_WALLDRAW_FADE * 192  +  (1-PARAM_WALLDRAW_FADE) * 192 * (1-(1-(k / #dhradar_dat.STOR_walldata))^2)
					dhradar_DrawPolarLine(angleSt, distSt, angleEn, distEn, Color(255,255,255,alpha) )
				end
			end
		end
	end
end

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
//// INTERNAL FINDING FUNCTIONS .

local function dhradar_FindPlayers()
	if (CurTime() < (TIME_LastPlayerFind + TIME_DELAY_PLY)) then return end
	
	FINDER_Players = {}
	FINDER_Players = player.GetAll()
	for k,ply in pairs(FINDER_Players) do
		if (ply:Team() == TEAM_SPECTATOR) then
			table.remove( FINDER_Players, k )
		end
	end
	TIME_LastPlayerFind = CurTime()
end

local function dhradar_FindEntity()
	if (CurTime() < (TIME_LastEntityFind + TIME_DELAY_ENT)) then return end
	
	local range = math.Clamp( dhradar_cvars.dhradar_range or 32, 0, 12288)
	FINDER_AllFoundEnts = {}
	FINDER_AllFoundEnts = ents.FindInBox(dhradar_Pos() + Vector(-range,-range,-range),dhradar_Pos() + Vector(range,range,range))
	FINDER_AllFoundEntsCount = #FINDER_AllFoundEnts
	for k,name in pairs( dhradar_dat.STOR_BeaconNamesTable ) do
		if (#FINDER_AllFoundEnts != FINDER_AllFoundEntsCount) then
			if (k > 1) then print("dhradar ERROR : The given entities were altered on beacon ".. name .. " !") end
			FINDER_AllFoundEntsCount = #FINDER_AllFoundEnts
		end
		local BEACON = dhradar.Get(name)
		if (BEACON and ( GetConVarNumber( "dhradar_beacon_" .. name ) > 0 ) and BEACON.FindFunction) then
			dhradar_dat.STOR_TRASHTABLE_FindFunction = {}
			FINDER_FoundTable[name] = BEACON:FindFunction( FINDER_AllFoundEnts /*table.Copy(entities)*/, dhradar_dat.STOR_TRASHTABLE_FindFunction )
		else
			FINDER_FoundTable[name] = {}
		end
	end
	TIME_LastEntityFind = CurTime()
end

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
//// INTERNAL DRAWING FUNCTIONS - THE FIRST FUNCTION CAN BE USED OUTSIDE

function dhradar_GetPlayerAlternateColor( ply )
	if (ply.dhradar_communitycolor) then
		spriteColor = ply.dhradar_communitycolor
		
	elseif (table.Count(team.GetAllTeams()) == 3) then
		//print("Generating a color for "..ply:Name().." !")
		local h   = ply:UserID()^5 % 360
		local s   = 0.1 + 0.5 * (ply:UserID()^3 % 27) / 27
		local v   = 1.0
		local hi = math.floor(h / 60)%6
		local f  = (h / 60) - math.floor(h / 60)
		local p  = v*(1-s)
		local q  = v*(1-f*s)
		local t  = v*(1-(1-f)*s)
		
		v = v * 255
		t = t * 255
		p = p * 255
		q = q * 255
		
		if     (hi == 0) then ply.dhradar_communitycolor = Color(v,t,p)
		elseif (hi == 1) then ply.dhradar_communitycolor = Color(q,v,p)
		elseif (hi == 2) then ply.dhradar_communitycolor = Color(p,v,t)
		elseif (hi == 3) then ply.dhradar_communitycolor = Color(p,q,v)
		elseif (hi == 4) then ply.dhradar_communitycolor = Color(t,p,v)
		else                  ply.dhradar_communitycolor = Color(v,p,q)
		end
		spriteColor = ply.dhradar_communitycolor
	else
		spriteColor = team.GetColor( ply:Team() )
	end
	
	return spriteColor
end

local function dhradar_DrawPlayers()	
	local sprite = 0
	local spriteColor = nil
	local spriteAngle
	local angle,dist,isup = 0
	for k,ply in pairs(FINDER_Players) do
		if ply:IsValid() then
			spriteAngle = 0
			angle,dist,isup = dhradar_CalcGetPolar( ply:GetPos() )
			
			if (ply.dhradar_isFriend == nil) then
				ply.dhradar_isFriend = (ply:GetFriendStatus() == "friend")
			end
			
			if (ply == LocalPlayer()) or (dhradar_cvars.dhradar_ui_showplayeriffriend <= 0) or (dist < 1) or (ply.dhradar_isFriend) then
				local spriteScale = 1
				if ply:Alive() then
					if ply == LocalPlayer() then 
						sprite,spriteAngle = dhradar_CalcGenericAltitudeSprite(isup,dhradar_tex.tex_pl_signal_self ,dhradar_tex.tex_pl_dirsignal, 0, 0, 180)
						spriteScale = 0.7
					else
						sprite,spriteAngle = dhradar_CalcGenericAltitudeSprite(isup,dhradar_tex.tex_pl_signal_alive,dhradar_tex.tex_pl_dirsignal, 45, 0, 180)
					end
				else
					sprite = dhradar_tex.tex_pl_signal_dead
					spriteScale = 2
					spriteAngle = 45
				end
				
				
				spriteColor = dhradar_GetPlayerAlternateColor( ply )
				
				
				dhradar_DrawPin(sprite, angle, dist, dhradar_dat.ui_shadowColor , 1.25*spriteScale, spriteAngle)
				dhradar_DrawPin(sprite, angle, dist, spriteColor                , 1.00*spriteScale, spriteAngle)
				
				if ply:Alive() and ply != LocalPlayer() and dist < 1 then
					//Cone Color
					local conecolor = dhradar_dat.STOR_RadarTrashColor
					local coneAngle = ply:EyeAngles().y - dhradar_Angles().y + 90
					dhradar_dat.STOR_RadarTrashColor.r = 127 + spriteColor.r*0.5
					dhradar_dat.STOR_RadarTrashColor.g = 127 + spriteColor.g*0.5
					dhradar_dat.STOR_RadarTrashColor.b = 127 + spriteColor.b*0.5
					dhradar_dat.STOR_RadarTrashColor.a = 127
					dhradar_DrawPin(dhradar_tex.tex_pl_cone, angle, dist, conecolor , 6, coneAngle)
				end
				
				if  (dhradar_cvars.dhradar_ui_showplayernames > 0) and (ply != LocalPlayer()) then
					dhradar_DrawText(ply:Name(), angle, dist + 0.10, spriteColor, true)
				end
			end
		end
	end
end

local function dhradar_DrawEntity()
	for k,name in pairs( dhradar_dat.STOR_BeaconNamesTable ) do
		BEACON = dhradar.Get(name)
		if (BEACON and ( GetConVarNumber( "dhradar_beacon_" .. name ) > 0 ) and BEACON.DrawFunction and FINDER_FoundTable and FINDER_FoundTable[name] and #FINDER_FoundTable[name] > 0) then
			for i,ent in pairs(FINDER_FoundTable[name]) do
				if (ent and ent:IsValid()) then BEACON:DrawFunction( ent ) end
			end
		end
	end
end

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
//// THE MAIN HOOK - THINK .

function dhradarHudPaint()
	if dhradar_cvars.dhradar_enable <= 0 then return end
	
	ui_xCenter  = math.floor(ScrW() * dhradar_cvars.dhradar_ui_x_rel)
	ui_yCenter  = math.floor(ScrH() * dhradar_cvars.dhradar_ui_y_rel)
	ui_size     = dhradar_cvars.dhradar_ui_size
	dhradar_dat.ui_scale    = dhradar_cvars.dhradar_ui_scale
	ui_pinScale = dhradar_cvars.dhradar_ui_pinscale
	
	dhradar_SetAngles( EyeAngles() )
	
	if dhradar_cvars.dhradar_forwardexplore > 0 then
		if LocalPlayer():KeyDown(IN_MOVELEFT) and LocalPlayer():KeyDown(IN_MOVERIGHT) then
			dhradar_dat.ui_forwardreload = true
			if not (dhradar_dat.ui_forwardpressed) then
				if (dhradar_dat.ui_forwardreload) and (RealTime() < (dhradar_dat.ui_forwardlastoccur + dhradar_dat.ui_forward_delay)) then
					dhradar_dat.ui_forwardreload = false
					dhradar_dat.ui_forwardexplore[1] = 0
					dhradar_dat.ui_upexplore[1]      = 0
					
					dhradar_dat.ui_forwardexplore[3] = 0.4
					dhradar_dat.ui_upexplore[3] = 0.4
					
					dhradar_dat.ui_forwardpressed = true
				else
					dhradar_dat.ui_forwardexplore[3] = 0.2
					dhradar_dat.ui_forwardreload = true
				end
				
				dhradar_dat.ui_forwardpressed = true
				dhradar_dat.ui_forwardlastoccur = RealTime()
			end
		end
		
		dhradar_dat.ui_forwardexplore[2] = dhradar_dat.ui_forwardexplore[2] + (dhradar_dat.ui_forwardexplore[1] - dhradar_dat.ui_forwardexplore[2]) * math.Clamp( dhradar_dat.ui_forwardexplore[3] * 0.5 * FrameTime() * 50 , 0 , 1 )
		dhradar_dat.ui_upexplore[2] = dhradar_dat.ui_upexplore[2] + (dhradar_dat.ui_upexplore[1] - dhradar_dat.ui_upexplore[2]) * math.Clamp( dhradar_dat.ui_upexplore[3] * 0.5 * FrameTime() * 50 , 0 , 1 )
		
		--dhradar_dat.ui_forwardexplore[2] = math.Round(dhradar_dat.ui_forwardexplore[2]*10)*0.1
		--dhradar_dat.ui_upexplore[2] = math.Round(dhradar_dat.ui_upexplore[2]*10)*0.1
		--print (EyePos())
		--print (dhradar_Angles())
		
		
		dhradar_SetPos( EyePos() 
		+ Angle(0,dhradar_Angles().y,dhradar_Angles().z):Forward()
		* math.Round(dhradar_dat.ui_forwardexplore[2]*100)
		*0.01 * dhradar_dat.ui_scale
		* PARAM_SCALEBASE 
		+ Vector(0,0,1) 
		* math.Round(dhradar_dat.ui_upexplore[2]*100)
		*0.01
		* dhradar_dat.ui_scale 
		* PARAM_SCALEBASE )
		--dhradar_SetPos( EyePos() + Angle(0,dhradar_Angles().y):Forward() * dhradar_dat.ui_forwardexplore[2] * dhradar_dat.ui_scale * PARAM_SCALEBASE + Vector(0,0,1) * dhradar_dat.ui_upexplore[2] * dhradar_dat.ui_scale * PARAM_SCALEBASE )
	else
		dhradar_SetPos( EyePos() )
	end
	
	if (dhradar_cvars.dhradar_scaleexplore > 0) then
		if LocalPlayer():KeyDown(IN_FORWARD) and LocalPlayer():KeyDown(IN_BACK) then
			dhradar_dat.ui_forwardreload = true
			if not (dhradar_dat.ui_forwardpressed) then
				if (dhradar_dat.ui_forwardreload) and (RealTime() < (dhradar_dat.ui_forwardlastoccur + dhradar_dat.ui_forward_delay)) then
					dhradar_dat.ui_forwardreload = false
					dhradar_dat.ui_scaleexplore[1] = 0
					dhradar_dat.ui_scaleexplore[3] = 0.4
					
					dhradar_dat.ui_forwardpressed = true
				end
				
				dhradar_dat.ui_forwardpressed = true
				dhradar_dat.ui_forwardlastoccur = RealTime()
			end
			
		elseif (LocalPlayer():KeyDown(IN_USE)) then
			dhradar_dat.ui_scaleexplore[3] = 0.2
		end
		
		dhradar_dat.ui_scaleexplore[2] = math.Clamp( dhradar_dat.ui_scaleexplore[2] + (dhradar_dat.ui_scaleexplore[1] - dhradar_dat.ui_scaleexplore[2]) * math.Clamp( dhradar_dat.ui_scaleexplore[3] * 0.5 * FrameTime() * 50 , 0 , 1 ) , -0.90 , 1024 )
		
		dhradar_dat.ui_scale = dhradar_dat.ui_scale * (1 + math.Round(dhradar_dat.ui_scaleexplore[2]*100)*0.01 )
	end
	
	if not (LocalPlayer():KeyDown(IN_MOVELEFT) or LocalPlayer():KeyDown(IN_MOVERIGHT) or LocalPlayer():KeyDown(IN_FORWARD) or LocalPlayer():KeyDown(IN_BACK)) then
		dhradar_dat.ui_forwardpressed = false
	end
	
	dhradar_dat.ui_ringcolor.r = dhradar_cvars.dhradar_col_ring_r
	dhradar_dat.ui_ringcolor.g = dhradar_cvars.dhradar_col_ring_g
	dhradar_dat.ui_ringcolor.b = dhradar_cvars.dhradar_col_ring_b
	dhradar_dat.ui_ringcolor.a = dhradar_cvars.dhradar_col_ring_a
	
	dhradar_dat.ui_circlecolor.r = dhradar_cvars.dhradar_col_circle_r
	dhradar_dat.ui_circlecolor.g = dhradar_cvars.dhradar_col_circle_g
	dhradar_dat.ui_circlecolor.b = dhradar_cvars.dhradar_col_circle_b
	dhradar_dat.ui_circlecolor.a = dhradar_cvars.dhradar_col_circle_a
	
	dhradar_dat.ui_rt_floorcolor  = dhradar_dat.ui_ringcolor
	dhradar_dat.ui_rt_unwalkcolor = dhradar_dat.ui_circlecolor
	
	dhradar_InitializeRenderTarget()
	
	if (dhradar_cvars.dhradar_showheights <= 0) then
		dhradar_DrawSprite( dhradar_tex.tex_ui_circle , ui_xCenter, ui_yCenter, ui_size, ui_size, 0, dhradar_dat.ui_circlecolor.r, dhradar_dat.ui_circlecolor.g, dhradar_dat.ui_circlecolor.b, dhradar_dat.ui_circlecolor.a )
	end
	
	dhradar_FindHeights()
	dhradar_DrawHeights()
	dhradar_DrawSprite( dhradar_tex.tex_ui_ring   , ui_xCenter, ui_yCenter, ui_size*1.05, ui_size*1.05 , 0 , dhradar_dat.ui_ringcolor.r, dhradar_dat.ui_ringcolor.g, dhradar_dat.ui_ringcolor.b, dhradar_dat.ui_ringcolor.a )
	
	//UI Do
	dhradar_FindWalls()
	dhradar_FindEntity()
	dhradar_FindPlayers()
	
	dhradar_DrawWalls()
	dhradar_DrawEntity()
	dhradar_DrawPlayers()
	
	//UI Priority	
	dhradar_RestoreStateVars()
end

function dhradarPlayerBindPress( ply, bind, pressed )
	if (dhradar_cvars.dhradar_forwardexplore > 0.0) and pressed then
		if LocalPlayer():KeyDown(IN_MOVELEFT) and LocalPlayer():KeyDown(IN_MOVERIGHT) then
			if string.find( bind, "invprev" ) then
				dhradar_dat.ui_forwardexplore[1] = (dhradar_dat.ui_forwardexplore[1]) + dhradar_dat.ui_forward_reladd
				dhradar_dat.ui_forwardreload = false
				return true
			end
			if string.find( bind, "invnext" ) then
				dhradar_dat.ui_forwardexplore[1] = (dhradar_dat.ui_forwardexplore[1]) - dhradar_dat.ui_forward_reladd
				dhradar_dat.ui_forwardreload = false
				return true
			end
		end
		if LocalPlayer():KeyDown(IN_FORWARD) and LocalPlayer():KeyDown(IN_BACK) then
			if string.find( bind, "invprev" ) then
				dhradar_dat.ui_upexplore[1] = (dhradar_dat.ui_upexplore[1]) + dhradar_dat.ui_up_reladd
				dhradar_dat.ui_forwardreload = false
				return true
			end
			if string.find( bind, "invnext" ) then
				dhradar_dat.ui_upexplore[1] = (dhradar_dat.ui_upexplore[1]) - dhradar_dat.ui_up_reladd
				dhradar_dat.ui_forwardreload = false
				return true
			end
		end
	end
	if (dhradar_cvars.dhradar_scaleexplore > 0.0) and pressed then
		if LocalPlayer():KeyDown(IN_USE) then
			if string.find( bind, "invprev" ) then
				dhradar_dat.ui_scaleexplore[1] = (dhradar_dat.ui_scaleexplore[1]) + dhradar_dat.ui_scale_reladd
				dhradar_dat.ui_forwardreload = false
				return true
			end
			if string.find( bind, "invnext" ) then
				dhradar_dat.ui_scaleexplore[1] = (dhradar_dat.ui_scaleexplore[1]) - dhradar_dat.ui_scale_reladd
				dhradar_dat.ui_forwardreload = false
				return true
			end
		end
	end
end
hook.Add( "PlayerBindPress", "dhradarPlayerBindPress", dhradarPlayerBindPress )

function dhradar_RevertExplore()
	dhradar_dat.ui_forwardexplore[1] = 0
	dhradar_dat.ui_upexplore[1]      = 0
	dhradar_dat.ui_scaleexplore[1]   = 0
	
	dhradar_dat.ui_forwardexplore[3] = 0.4
	dhradar_dat.ui_upexplore[3]      = 0.4
	dhradar_dat.ui_scaleexplore[3]  = 0.4
end
concommand.Add("dhradar_revertexplore",dhradar_RevertExplore)



/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
//// PANEL .


function dhradar_dat.Panel(Panel)	
	Panel:AddControl("Checkbox", {
			Label = "Enable", 
			Description = "Enable", 
			Command = "dhradar_enable" 
		}
	)
	Panel:AddControl("Checkbox", {
			Label = "Show Player Names", 
			Description = "Show Player Names", 
			Command = "dhradar_ui_showplayernames" 
		}
	)
	Panel:AddControl("Checkbox", {
			Label = "Show Far Players if friend", 
			Description = "Show Far Players if friend", 
			Command = "dhradar_ui_showplayeriffriend" 
		}
	)
	Panel:AddControl("Checkbox", {
			Label = "Show Walls", 
			Description = "Show Walls", 
			Command = "dhradar_showwalls" 
		}
	)
	Panel:AddControl("Checkbox", {
			Label = "Show Heights", 
			Description = "Show Heights", 
			Command = "dhradar_showheights" 
		}
	)
	Panel:AddControl("Slider", {
			Label = "Relative X Position",
			Type = "Float",
			Min = "0",
			Max = "1",
			Command = "dhradar_ui_x_rel"
		}
	)
	Panel:AddControl("Slider", {
			Label = "Relative Y Position",
			Type = "Float",
			Min = "0",
			Max = "1",
			Command = "dhradar_ui_y_rel"
		}
	)
	Panel:AddControl("Slider", {
			Label = "Pin Scale",
			Type = "Float",
			Min = "0",
			Max = "2",
			Command = "dhradar_ui_pinscale"
		}
	)
	Panel:AddControl("Slider", {
			Label = "Size (pixels)",
			Type = "Integer",
			Min = "64",
			Max = "512",
			Command = "dhradar_ui_size"
		}
	)
	Panel:AddControl("Slider", {
			Label = "Scale",
			Type = "Float",
			Min = "5",
			Max = "40",
			Command = "dhradar_ui_scale"
		}
	)
	Panel:AddControl("Slider", {
			Label = "Range of Detection",
			Type = "Integer",
			Min = "48",
			Max = "4096",
			Command = "dhradar_range"
		}
	)
	Panel:AddControl("Button", {
			Label = "Reload Beacon Files", 
			Description = "Reload Beacon Files", 
			Command = "dhradar_reloadbeacons" 
		}
	)
	Panel:AddControl("Button", {
			Label = "Open Menu (dhradar_menu)", 
			Description = "Open Menu (dhradar_menu)", 
			Command = "dhradar_menu"
		}
	)
	
	Panel:Help("To trigger the menu in any gamemode, type dhradar_menu in the console, or bind this command to any key.")
end

function dhradar_dat.AddPanel()
	spawnmenu.AddToolMenuOption("Options","Player","Depth HUD Radar","Depth HUD Radar","","",dhradar_dat.Panel,{SwitchConVar = 'dhradar_enable'})
end

hook.Add( "PopulateToolMenu", "AddDepthHUDRadarPanel", dhradar_dat.AddPanel )

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
//// STARTING UP .

dhradar_RegisterCVars()
dhradar_LoadAllBeacons()
dhradar_InitializeRenderTarget()

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
local removes = {"env_steam",
"func_illusionary",
"beam",
"class C_BaseEntity",
"env_sprite",
"class C_ShadowControl",
"class C_ClientRagdoll",
"func_illusionary",
"class C_PhysPropClientside",
}
	
	
        for k,v in pairs(removes) do
                for a,b in pairs(ents.FindByClass(v)) do
                        b:SetNoDraw(true)
                end
        end
