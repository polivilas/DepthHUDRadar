BEACON.Name        = "GmodTower : Suites"

BEACON.angle = nil
BEACON.dist  = nil
BEACON.isup  = nil

BEACON.spriteScale = 1.7
BEACON.spriteColor = nil
BEACON.sprite      = dhradar_GetTexture("square")
BEACON.spriteAngle = nil
BEACON.spriteColorBorder = Color(0,0,0,255)
BEACON.spriteColorMySuite = Color( 0, 210, 0, 255 )
BEACON.spriteColorSomeSuite = Color( 100, 100, 255, 255 )
BEACON.spriteColorFreeSuite = Color( 255, 100, 100, 255 )
BEACON.textColorRoomId      = Color( 255, 255, 255, 255 )

BEACON.roomOwner = Color(0,0,0,128)

BEACON.AngleIsEntityYaw        = false
BEACON.AngleIsRadarOrientation = true
BEACON.AngleAdd                = 0


function BEACON:FindFunction( entities , myTrashTable )
	for k,ent in pairs(entities) do
		if string.find(ent:GetClass(),"func_suitepanel") then
			table.insert(myTrashTable,ent)
		end
	end
	return myTrashTable
end

function BEACON:GetStatus(ent)
	if not GtowerRooms then return 0 end
	self.roomOwner = GtowerRooms:RoomOwner( ent.RoomId )
	
	if self.roomOwner then
		if self.roomOwner == LocalPlayer() then
			return 1
		else
			return 2
		end	
	end
	
	return 0
end

function BEACON:GetColor(ent)
	local status = self:GetStatus(ent)
	
	if status == 1 then
		return self.spriteColorMySuite
	elseif status == 2 then
		return self.spriteColorSomeSuite
	else
		return self.spriteColorFreeSuite
	end
end

function BEACON:DrawFunction( ent )
	self.angle, self.dist, self.isup = dhradar_CalcGetPolar( ent:GetPos() )
	self.spriteColor = self:GetColor(ent)
	self.spriteScale = 1.7
	if (self:GetStatus(ent) == 0) then
		self.spriteScale = self.spriteScale + self.spriteScale*0.2*math.cos(math.rad(CurTime()*360*2))
	elseif (self:GetStatus(ent) == 1) then
		self.spriteScale = self.spriteScale + 0.7 + self.spriteScale*0.2*math.cos(math.rad(CurTime()*360))
	else
		self.spriteScale = self.spriteScale
	end
	
	if (self.AngleIsEntityYaw) then
		self.spriteAngle  = ent:GetAngles().y - dhradar_Angles().y + 90 + self.AngleAdd
	elseif (self.AngleIsRadarOrientation) then
		self.spriteAngle  = -dhradar_Angles().y + 90 + self.AngleAdd
	else
		self.spriteAngle  = 0 + self.AngleAdd
	end
	
	//Border
	dhradar_DrawPin(self.sprite, self.angle, self.dist, self.spriteColorBorder, 1.0*self.spriteScale, self.spriteAngle, true, 0.7)
	//Pin
	dhradar_DrawPin(self.sprite, self.angle, self.dist, self.spriteColor      , 0.8*self.spriteScale, self.spriteAngle, true, 0.7)
	
	dhradar_DrawText("" .. ent.RoomId, self.angle, self.dist, self.textColorRoomId, false)
	if (self.dist < 1) and GtowerRooms then
		if IsValid(GtowerRooms:RoomOwner( ent.RoomId )) then
			local str = GtowerRooms:RoomOwner( ent.RoomId ):Name()
			dhradar_DrawText(str, self.angle, self.dist + 0.10, self.spriteColor, true)
		end
	end
	
	return true
end
