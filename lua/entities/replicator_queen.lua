AddCSLuaFile( )

ENT.Type 			= "anim"
ENT.Base 			= "base_anim"

ENT.Editable		= false
ENT.PrintName		= "Replicator Gueen"
ENT.Spawnable 		= true
ENT.AdminSpawnable 	= false
ENT.Category		= "Stargate"
ENT.AutomaticFrameAdvance = true 

function ENT:Initialize()

	if SERVER then

		util.AddNetworkString( "rDrawStorageEffect" )
	
		self:SetModel( "models/stargate/replicators/replicator_queen.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )

		self:SetHealth( 100 )
		
	end // SERVER

	if CLIENT  then
	
		self:SetVar( "rEffectFrame", 0 )
		
	end // CLIENT

	REPLICATOR.ReplicatorInitialize( self )
	
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 15
	local SpawnAng = Angle( 0,  ply:EyeAngles().yaw, 0 )

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:SetAngles( SpawnAng )
	ent:Spawn()
	ent:Activate()

	return ent

end

function ENT:Draw()

	self:DrawModel()

	local effectTime = self.rEffectFrame
	
	net.Receive( "rDrawStorageEffect", function()
	
		if net.ReadEntity() == self then self.rEffectFrame = 1 end
		
	end )
	
	if effectTime > 0 then
	
		if self:GetVar( "rEffectFrame" ) < 100 then self.rEffectFrame = effectTime + 4 else self.rEffectFrame = 100 end
		local pos = self:GetPos() - self:GetForward() * 16 - self:GetUp() * 1
		
		local dlight = DynamicLight( LocalPlayer():EntIndex() )
		if ( dlight ) then
			dlight.pos = pos
			dlight.r = 150
			dlight.g = 200
			dlight.b = 255
			dlight.brightness = 2
			dlight.Decay = 10
			dlight.Size = 150
			dlight.DieTime = CurTime() + 1
		end
		
		local emitter = ParticleEmitter( pos, false )

		local particle = emitter:Add( Material( "sprites/gmdm_pickups/light" ), pos + VectorRand() )
		
		if particle then
		
			local randVec = VectorRand() * math.Rand( 3, 4 ) * 4
			particle:SetVelocity( randVec )
			particle:SetColor( 255, 255, 255 ) 
			particle:SetLifeTime( 0 )
			particle:SetDieTime( 2.3 )
			particle:SetStartSize( 6 )
			particle:SetEndSize( 8 )

			particle:SetGravity( -randVec )
			
		end
		
		emitter:Finish()
		
		render.SetColorMaterial()
		render.DrawSphere( pos, effectTime / 100 * 12, 20, 20, Color( 100, 150, 255, 50 ) )
		
	end
	
end

if SERVER then

	function ENT:OnTakeDamage( dmginfo )

		REPLICATOR.ReplicatorOnTakeDamage( 2, self, dmginfo )
		
	end
end

function ENT:Think()

	self:NextThink( CurTime() + 0.1 )

	if SERVER then
		
		REPLICATOR.ReplicatorAI( 2, self )
		
	end // SERVER

	if CLIENT then
		
		REPLICATOR.ReplicatorDarkPointAssig( self )

	end // CLIENT

	return true
end

if SERVER then

	function ENT:OnRemove()
	
		REPLICATOR.ReplicatorOnRemove( replicatorType, self )

	end
	
end