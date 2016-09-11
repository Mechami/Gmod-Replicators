--[[

	REPLICATORS
	
]]

AddCSLuaFile( )

REPLICATOR = { }

include( "replicators/data.lua" )
include( "replicators/keron.lua" )
include( "replicators/collisions.lua" )

include( "replicators/initialize.lua" )
include( "replicators/think.lua" )
include( "replicators/path_moving.lua" )
include( "replicators/walk.lua" )

REPLICATOR.ReplicatorOnTakeDamage = function( replicatorType, self, dmginfo )
	
	local h_Damage = dmginfo:GetDamage()
	local h_Attacker = dmginfo:GetAttacker()
	
	self:SetHealth( self:Health() - h_Damage )

	if not g_Attackers[ "r"..h_Attacker:EntIndex() ] and ( h_Attacker:IsNPC() or h_Attacker:IsPlayer() and h_Attacker:Alive() ) then
	
		g_Attackers[ "r"..h_Attacker:EntIndex() ] = h_Attacker
		
		if ( replicatorType == 2 and not table.HasValue( g_QueenCount, self )) then
		
			self.rResearch = true
			
		end
		
	end
	
	if self:Health() <= 0 then
		
		REPLICATOR.ReplicatorBreak( replicatorType, self, h_Damage, dmginfo:GetDamagePosition() )
		
	end
end

REPLICATOR.ReplicatorOnRemove = function( self ) 

	local h_MetalId = self.rTargetMetalId
	local h_DarkId = self.rTargetDarkId
	
	if g_MetalPoints[ h_MetalId ] and g_MetalPoints[ h_MetalId ].used then g_MetalPoints[ h_MetalId ].used = false end
	if g_DarkPoints[ h_DarkId ] and g_DarkPoints[ h_DarkId ].used then g_DarkPoints[ h_DarkId ].used = false end
						
	timer.Remove( "rWalking"..self:EntIndex() )
	timer.Remove( "rRun"..self:EntIndex() )
	timer.Remove( "rRotateBack"..self:EntIndex() )
	timer.Remove( "rScanner"..self:EntIndex() )
	timer.Remove( "rScannerDark"..self:EntIndex() )
	timer.Remove( "rChangingDirection"..self:EntIndex() )
	timer.Remove( "rEating"..self:EntIndex() )
	timer.Remove( "rGiving"..self:EntIndex() )
	timer.Remove( "rDamagining"..self:EntIndex() )
	
end

REPLICATOR.ReplicatorDarkPointAssig = function( self )

	local h_Radius = Vector( 4, 4, 4 )
	local h_Ground, h_GroundDist = CNRTraceHullQuick( 
		self:GetPos(), -self:GetUp() * 20, 
		h_Radius, g_ReplicatorNoCollideGroupWith )
		
	local h_LColor = render.GetLightColor( self:GetPos() )
	local h_DarkLevel = ( h_LColor.x + h_LColor.y + h_LColor.z ) / 3 * 100
	
	local h_HitNormal = h_Ground.HitNormal
	h_HitNormal = Vector( math.Round( h_HitNormal.x ), math.Round( h_HitNormal.y ), math.Round( h_HitNormal.z ) )

	local h_Pos, h_StringPos = convertToGrid( self:GetPos(), 100 )
	
	local h_Radius = Vector( 30, 30, 30 )
	
	local h_Trace = CNRTraceHullQuick( 
		self:GetPos() + Vector( 0, 0, h_Radius.z + 2 ), 
		Vector( ),
		h_Radius, g_ReplicatorNoCollideGroupWith )
	
	if h_HitNormal == Vector( 0, 0, 1 ) and h_DarkLevel < g_replicator_min_dark_level 
	and not g_DarkPoints[ h_StringPos ] and not h_Trace.Hit then AddDarkPoint( h_StringPos, h_Ground.HitPos ) end

end

REPLICATOR.ReplicatorScanningResources = function( self )
	
	local h_Result = ents.FindInSphere( self:GetPos(), 500 )
	
	for k, v in pairs( h_Result ) do
		
		if v:GetClass() == "prop_physics" then
		
			local m_Dir = VectorRand()
			m_Dir:Normalize()
			
			m_Trace = CNRTraceQuick( 
			v:WorldSpaceCenter(), m_Dir * v:GetModelRadius(),
			g_ReplicatorNoCollideGroupWith )
			
			if m_Trace.MatType == MAT_METAL and v:IsValid() and not g_MetalPointsAsigned[ "_"..v:EntIndex() ] then AddMetalEntity( v ) end
			
		elseif v:IsNPC() then
			
			v:AddEntityRelationship( self.rReplicatorNPCTarget, D_HT , 99 ) 
			
		end
	end
end

REPLICATOR.ReplicatorBreak = function( replicatorType, self, damage, dmgpos )

	local t_Count = 0
	
	if replicatorType == 1 then t_Count = g_segments_to_assemble_replicator
	elseif replicatorType == 2 then t_Count = g_segments_to_assemble_queen
	end
	
	local h_Ent
	
	for i = 1, t_Count do
	
		h_Ent = ents.Create( "replicator_segment" )
		
		if not IsValid( h_Ent ) then return end
		h_Ent:SetPos( self:GetPos() + VectorRand() * 3 )
		h_Ent:SetAngles( AngleRand() )
		h_Ent:SetOwner( self:GetOwner() )
		h_Ent:Spawn()
		
		local phys = h_Ent:GetPhysicsObject()
		phys:Wake()
		
		local vec = ( self:GetPos() - dmgpos )
		vec:Normalize()
		
		phys:SetVelocity( ( VectorRand() + vec / 2 ) * ( damage / 2 + 100 ) )
		
	end
	
	h_Ent:EmitSound( "npc/manhack/gib.wav", 75, 150 + math.Rand( -25, 25 ), 1, CHAN_AUTO )
	
	self:Remove()
end

REPLICATOR.ReplicatorDrawDebug = function( self )
	
	net.Receive( "rDrawPoint", function() net.ReadEntity().cPoint = net.ReadVector() end )
	render.DrawLine( self:GetPos(), self.cPoint, Color( 255, 255, 255 ), true )
	
	net.Receive( "rDrawpPoint", function() net.ReadEntity().pPoint = net.ReadVector() end )
	render.DrawLine( self:GetPos(), self.pPoint, Color( 255, 255, 255 ), true )
	
end