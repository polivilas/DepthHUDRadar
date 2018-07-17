AddCSLuaFile()
BEACON.Name        = "Weapons"
BEACON.DefaultOff  = true

BEACON.AngleIsEntityYaw        = true
BEACON.AngleIsRadarOrientation = false
BEACON.AngleAdd                = 0

BEACON.angle = nil
BEACON.dist  = nil
BEACON.isup  = nil
--gui/silkicons/application_put
BEACON.spriteScale = 1
BEACON.spriteColor = Color(255,255,255)
BEACON.sprite      = Material("icon16/gun.png", "noclamp" ) 
BEACON.spriteAngle = nil
BEACON.spriteColorShadow = Color(0,0,0,128)


function BEACON:FindFunction( entities , myTrashTable )
	for k,ent in pairs(entities) do
		if ent:IsWeapon() and !ent:IsDormant() and ent:IsValid() and ent:GetMoveType() ~= MOVETYPE_NONE then
			table.insert(myTrashTable,ent)
		end
	end
	return myTrashTable
end

function BEACON:DrawFunction( ent )
	self.angle, self.dist, self.isup = dhradar_CalcGetPolar( ent:GetPos() )
	
	if (self.AngleIsEntityYaw) then
		self.spriteAngle  = ent:GetAngles().y - dhradar_Angles().y + 90 + self.AngleAdd
	elseif (self.AngleIsRadarOrientation) then
		self.spriteAngle  = -dhradar_Angles().y + 90 + self.AngleAdd
	else
		self.spriteAngle  = 0 + self.AngleAdd
	end
	
	if gmod.GetGamemode().Name == "DarkRP" and ent.PrintName and ent.PrintName == "Spawned Weapon" then
	weapon = weapons.Get( ent:GetWeaponClass() ).PrintName or ent:GetClass()
	if ent.dt.amount > 1 then
	weapon = (weapon.." x".. ent.dt.amount)
	end
	elseif gmod.GetGamemode().Name == "Trouble in Terrorist Town" then
	weapon = LANG.TryTranslation(ent:GetPrintName() or ent.PrintName or "...")
	elseif gmod.GetGamemode().Name == "Zombie Survival" then
	shithole = ent:GetDTString("0") or ent:GetClass()
	if not shithole then shithole = "weapon_toolgun" end
	if shithole then
	weapon = weapons.Get( shithole ) and weapons.Get( shithole ).PrintName or shithole
	else 
	weapon = ent:GetClass()
	end
	else
	weapon = language.GetPhrase( ent:GetPrintName() or "#GMOD_Physgun" ) or ent:GetClass()
	end	
	if !ent:IsDormant() and ent:IsValid() and ent:GetMoveType() ~= MOVETYPE_NONE then
	if self.dist < 1 then
		dhradar_DrawText( weapon, self.angle, self.dist + 0.10, self.spriteColor, false )
	end
	
	
	dhradar_DrawMatPin( self.sprite, self.angle, self.dist, self.spriteColor, 2*self.spriteScale, self.spriteAngle, true, 0.5)
	end
	return true
end
