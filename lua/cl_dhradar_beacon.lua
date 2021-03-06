////////////////////////////////////////////////
// -- Depth HUD : Radar                       //
// by Hurricaaane (Ha3)                       //
//                                            //
// http://www.youtube.com/user/Hurricaaane    //
//--------------------------------------------//
// The Beacon Module, to register easily      //
////////////////////////////////////////////////
--module( "dhradar", package.seeall )
dhradar = {}
local Beacons = {}
local Beacons_names = {}

function dhradar.Register(name, beacon)
	if string.find( name , " " ) then return end
	
	beacon.Name = beacon.Name or name
	Beacons[name] = beacon
	table.insert(Beacons_names, name)
	
	local cstr = ""
	if (beacon.DefaultOff or false) then
		cstr = "0"
	else
		cstr = "1"
	end
	CreateClientConVar("dhradar_beacon_" .. name, cstr, true, false)
end

function dhradar.RemoveAll()
	Beacons = {}
	Beacons_names = {}
end

function dhradar.Get(name)
	if Beacons[name] == nil then return nil end
	return Beacons[name] or nil
end

function dhradar.GetNamesTable()
	return table.Copy(Beacons_names)
end
