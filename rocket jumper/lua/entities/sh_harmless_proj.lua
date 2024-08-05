AddCSLuaFile( )

ENT.Type = "anim"
ENT.PrintName = "Harmless Projectile"
ENT.Author = "Isemenuk27"
ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.DisableDuplicator = true
ENT.Spawnable = false
ENT.AdminOnly = true

ENT.Model = "models/weapons/w_missile_closed.mdl"
local b = 150
local col = Color(b, b, b, 255)
local trail = "trails/smoke"

local Rad = 256
local RadSqr = Rad * Rad
local ExplodeSnd = "Airboat_impact_hard"
local ExplodeEffect = "Explosion"

function ENT:Initialize()
	self:SetModel( self.Model )
    
	self:SetMoveType( MOVETYPE_FLY )
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS  )
	self:SetSolid( SOLID_VPHYSICS )

	if ( SERVER ) then 
		self:PhysicsInit( SOLID_VPHYSICS )
		timer.Simple(0, function()
			if ( not IsValid(self) ) then return end
			self.phys = self:GetPhysicsObject()
			self.phys:SetVelocity( self.Dir * 1500 )
		end)
		timer.Simple(.2, function()
			if ( not IsValid(self) ) then return end
			util.SpriteTrail( self, 0, col, true, 3, 0, .3, .6, trail )
		end)
	end

	self:PhysWake()
end

function ENT:SetDir( vNormal )
	self.Dir = vNormal
end

function ENT:Think()
	if CLIENT then
		if self.PrevPos then
			local pos = self:GetPos()
			local a = ( pos - self.PrevPos ):Angle()
			self:SetRenderAngles( a )
		end
		self.PrevPos = self:GetPos()
		return 
	end
	if ( self.phys and not self.Shot ) then
		self.phys:SetVelocity( self.Dir * 1500 )
		self.Shot = true
	end
end

function ENT:Explode()
	if self.Exploded then return end
	self.Exploded = true

	local pos = self:GetPos()

	if ( IsFirstTimePredicted() ) then
		local ef = EffectData()
		ef:SetOrigin( pos )
		ef:SetMagnitude( 12 )
		ef:SetFlags( 4 + 8 )

		util.Effect( ExplodeEffect, ef )
	end

	self:EmitSound(ExplodeSnd)

	local e = self:GetOwner()
	if ( not IsValid(e) ) then self:Remove() return end

	local epos = e:GetPos()
	if epos:DistToSqr(pos) > RadSqr then self:Remove() return end

	epos:Add(vector_up * 76)
	local n = (epos - pos)
	n:Normalize()

	e:SetVelocity( n * ( e:KeyDown(IN_DUCK) and 150 or 300 ) )

	self:Remove()
end

function ENT:PhysicsCollide( data, phys )
	self:Explode()
end

function ENT:Draw()
	local d = self:GetPos():DistToSqr(EyePos())
	if d < 2000 then return end
	self:DrawModel()
end