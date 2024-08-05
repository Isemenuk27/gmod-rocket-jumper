AddCSLuaFile()

SWEP.Author			= "Isemenuk27"
SWEP.Instructions	= ""

SWEP.UseHands 			= true
SWEP.Spawnable			= true

SWEP.BounceWeaponIcon = false
SWEP.DrawWeaponInfoBox = false

SWEP.ViewModel			= "models/weapons/c_rpg.mdl"
SWEP.WorldModel			= "models/weapons/w_rocket_launcher.mdl"
SWEP.ViewModelFOV = 55

SWEP.Primary.ClipSize		= 6
SWEP.Primary.DefaultClip	= 0
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "AirboatGun"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.PrintName			= "Rocket Jumper"			
SWEP.Slot				= 1
SWEP.SlotPos			= 5
SWEP.DrawAmmo			= true
SWEP.DrawCrosshair		= true

SWEP.Material = "models/props_borealis/mooring_cleat001"
SWEP.IMAT = CLIENT and Material( SWEP.Material ) or nil

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 0, "NextReloadTime" )
	--self:NetworkVar( "Float", 1, "HolsterTime" )
	self:NetworkVar( "Bool", 0, "InReload" )
	--self:NetworkVar( "Bool", 1, "Holster" )
	--self:NetworkVar( "Entity", 0, "NextWeapon" )
end

function SWEP:Initialize()
	self:SetHoldType("rpg")
	self.OrigMat = self:GetMaterial()
	self:SetSubMaterial( nil, self.Material )
end

function SWEP:DrawWorldModel( flags )
	render.MaterialOverride( self.IMAT )
	self:DrawModel( flags )
	render.MaterialOverride( nil )
end

function SWEP:Holster( eWeapon, bForced )
	return true
	/*
	if not IsFirstTimePredicted() then return end
	self:SetInReload( false )

	if bForced then
		self:SetHolsterTime( 0 )
		return
	end

	self:SetNextWeapon( eWeapon )

	local VModel = self:GetOwner():GetViewModel()
	local EnumToSeq = VModel:SelectWeightedSequence( ACT_VM_IDLE_TO_LOWERED )

	VModel:SendViewModelMatchingSequence( EnumToSeq )

	local duration = VModel:SequenceDuration( EnumToSeq )

	self:SetHolsterTime( CurTime() + duration - .8 )
	return*/
end

function SWEP:PrimaryAttack()
	local CT = CurTime()
	local Owner = self:GetOwner()

	self:SetInReload( false )

	if self:Clip1() <= 0 then 
		self:Reload() return 
	end

	if SERVER then
		local proj = ents.Create( "sh_harmless_proj" )
		proj:SetPos( Owner:GetShootPos() - Owner:GetAimVector() * 3 )
		proj:SetAngles( Owner:EyeAngles() )
		proj:SetDir( Owner:GetAimVector() )
		proj:SetOwner( Owner )
		proj:Spawn()
	end

	self:EmitSound("WaterExplosionEffect.Sound")

	self:TakePrimaryAmmo( 1 )

	local VModel = Owner:GetViewModel()
	local EnumToSeq = VModel:SelectWeightedSequence( ACT_VM_PRIMARYATTACK )

	VModel:SendViewModelMatchingSequence( EnumToSeq )

	local duration = VModel:SequenceDuration( EnumToSeq )

	local t = CT + duration - .4
	self:SetNextPrimaryFire(t) 
	self:SetNextReloadTime(t)

	if self:Clip1() <= 0 then 
		self:Reload() return 
	end
end

function SWEP:SecondaryAttack()
	return false
end

function SWEP:FireAnimationEvent( pos, ang, event, options )
	if ( event == 21 or event == 5003 ) then return true end	
end

function SWEP:Reload()
	if (self:GetNextReloadTime() > CurTime() ) then return end
	if ( self:Clip1() >= self.Primary.ClipSize ) then self:SetInReload( false ) return end
	self:SetInReload( true )
	local CT = CurTime()
	local Owner = self:GetOwner()
	local VModel = Owner:GetViewModel()
	local EnumToSeq = VModel:SelectWeightedSequence( ACT_VM_RELOAD )

	VModel:SendViewModelMatchingSequence( EnumToSeq )

	local duration = VModel:SequenceDuration( EnumToSeq )

	timer.Simple(duration * .2, function()
		if ( not IsValid(self) ) then return end
		self:SetClip1( math.min( self:Clip1() + 1, self.Primary.ClipSize ) )
		self:EmitSound("AmmoCrate.Open")
		if ( self:Clip1() >= self.Primary.ClipSize ) then self:SetInReload( false ) end
	end)

	self:SetNextPrimaryFire(CT + duration * .35) 
	self:SetNextReloadTime(CT + duration * .3)
end

function SWEP:Deploy()
	local VModel = self:GetOwner():GetViewModel()
	local EnumToSeq = VModel:SelectWeightedSequence( ACT_VM_DRAW )

	VModel:SendViewModelMatchingSequence( EnumToSeq )
end

function SWEP:Think()
	/*
	local fTime = self:GetHolsterTime()
	if ( fTime != 0 and fTime <= CurTime() ) then
		self:Holster( self:GetNextWeapon(), true )
	end*/
	if ( self:GetOwner():KeyPressed( IN_ATTACK ) ) then
		self:SetInReload( false )
		return false
	end
	if ( self:GetInReload() ) then
		self:Reload()
	end
	return false
end

local oldMat

function SWEP:PreDrawViewModel( vm, weapon, ply )
	render.MaterialOverride( self.IMAT )
end

function SWEP:ViewModelDrawn( vm, weapon, ply )
	render.MaterialOverride( nil )
end

function SWEP:ShouldDropOnDie()
	return false
end

function SWEP:CustomAmmoDisplay()
	self.AmmoDisplay = self.AmmoDisplay or {} 
 
	self.AmmoDisplay.Draw = true

	self.AmmoDisplay.PrimaryClip = self:Clip1()
 
	return self.AmmoDisplay
end