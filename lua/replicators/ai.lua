--[[

	REPLICATORS Artificial Intelligence ( AI )
	
]]

AddCSLuaFile( )

REPLICATOR.ReplicatorAI = function( replicatorType, self  )
	
	// ======================= Varibles =================
	
	local h_Ground 			= {}
	local h_GroundDist 		= 0
	
	local h_Phys 			= self:GetPhysicsObject()
	local h_YawRot 			= self.rYawRot
	local h_Move 			= self.rMove
	local h_MoveMode 		= self.rMoveMode
	local h_Research 		= self.rResearch
	local h_Mode 			= self.rMode
	local h_ModeStatus 		= self.rModeStatus
	local h_PrevInfo 		= self.rPrevPointId

	local h_StandAnimReset 	= false
	
	if replicatorType == 1 then
	
		h_Ground, h_GroundDist = REPLICATOR.TraceHullQuick( self:GetPos() + self:GetUp() * 15, -self:GetUp() * 30, Vector( 6, 6, 6 ), g_ReplicatorNoCollideGroupWith )
		
	elseif replicatorType == 2 then
	
		h_Ground, h_GroundDist = REPLICATOR.TraceHullQuick( self:GetPos() + self:GetUp() * 10, -self:GetUp() * 40, Vector( 8, 8, 8 ), g_ReplicatorNoCollideGroupWith )
			
	end

	REPLICATOR.CreatingPath( self, h_Ground )

	if h_Research then
	
		self.rMove 			= true
		self.rMoveMode 		= 1
		self.rMoveReverse 	= false
		
		timer.Remove( "rRefind"..self:EntIndex() )

		local m_Name = "rRotateBack" .. self:EntIndex()
		
		if not timer.Exists( m_Name ) then
			
			timer.Create( m_Name, 4, 1, function()
			
				if self:IsValid() then self:SetAngles( self:LocalToWorldAngles( Angle( 0, 90, 0 ) ) ) end
				
			end )
		end		
			
		local m_Name = "rChangingDirection"..self:EntIndex()
		
		if not timer.Exists( m_Name ) then
		
			timer.Create( m_Name, math.Rand( 0.5, 1 ), 1, function() end )
			
			if self:IsValid() then self.rYawRot = math.Rand( 30, -30 ) end
		end
		
		local m_MetalAmount = self.rMetalAmount
		local m_Name = "rScanner"..self:EntIndex()
		local m_TargetEnt = self.rTargetEnt

		if table.Count( g_MetalPoints ) > 0 and table.Count( h_PrevInfo ) > 0 
			and ( h_Mode == 0 or ( h_Mode == 1 and ( h_ModeStatus == 0 or h_ModeStatus == 1 ) ) ) and not timer.Exists( m_Name ) then

			timer.Create( m_Name, math.Rand( 5, 5 ), 1, function() end )

			local m_PathResult 	= { }
			local m_MetalId		= 0
			
			if m_TargetEnt:IsValid() then

				m_PathResult = self.rMovePath
				m_MetalId = self.rTargetMetalId
				
			else m_PathResult, m_MetalId = GetPatchWayToClosestMetal( h_PrevInfo ) end

			if table.Count( m_PathResult ) > 0 then
			
				if not g_MetalPoints[ m_MetalId ].m_Ent then g_MetalPoints[ m_MetalId ].used = true end
				
				timer.Remove( "rRotateBack"..self:EntIndex() )
				timer.Remove( "rScannerDark"..self:EntIndex() )
				timer.Remove( "rScanner"..self:EntIndex() )
				
				self.rResearch = false
				self.rMoveStep = 1
				
				self.rMode = 1
				self.rModeStatus = 0
				self.rTargetMetalId = m_MetalId
				self.rMovePath = m_PathResult
				
			end
		end

		// ===================== Searching path to a dark point ======================
		
		local m_Name = "rScannerDark"..self:EntIndex()
		
		if ( h_Mode == 1 and h_ModeStatus == 2 or h_Mode == 4 ) and table.Count( g_DarkPoints ) > 0 and not timer.Exists( m_Name ) then
			
			timer.Create( m_Name, math.Rand( 5, 10 ), 1, function() end )

			if self:IsValid() then

				self.rResearch = false
				self.rMode = 1
				self.rModeStatus = 2

				timer.Remove( "rRotateBack"..self:EntIndex() )
				timer.Remove( "rScanner"..self:EntIndex() )
				timer.Remove( "rScannerDark"..self:EntIndex() )
				
			end
		end
		
		// ===================== Searching path to an enemy ======================
		
		local m_Name = "rScannerAttacker"..self:EntIndex()

		if table.Count( g_Attackers ) > 0 and not timer.Exists( m_Name ) then
			
			timer.Create( m_Name, math.Rand( 5, 10 ), 1, function() end )
			
			local m_PathResult, t_TargetEnt, t_TargetId
			local m_TargetEnt = self.rTargetEnt
			
			if m_TargetEnt:IsValid() then

				m_PathResult = self.rMovePath
				t_TargetId = self.rTargetId
				
			else
			
				local m_Case, m_Index = FindClosestPoint( self:GetPos(), 1 )
				m_PathResult, t_TargetEnt, t_TargetId = GetPatchWayToClosestEnt( { case = m_Case, index = m_Index }, g_Attackers )

			end

			if table.Count( m_PathResult ) > 0 then
				
				timer.Remove( "rRotateBack" .. self:EntIndex() )
				timer.Remove( "rScanner" .. self:EntIndex() )
				timer.Remove( "rScannerDark"..self:EntIndex() )

				self.rResearch 	= false
				self.rMoveStep 	= 1
				
				self.rMode 			= 2
				self.rModeStatus 	= 0
				self.rTargetId 		= t_TargetId
				self.rMovePath 		= m_PathResult
				
			end
		end
		
		local t_MoveTo 	= self:GetPos() + self:GetForward() * 40 + self:GetRight() * h_YawRot
		self.rMoveTo 	= t_MoveTo
		
	else
	
		// ======================================= Getting metal ===============================
		if h_Mode == 1 then
			
			local t_TargetMetalId = self.rTargetMetalId
			
			if h_ModeStatus == 0 then
			
				local mPointPos 	= Vector( )
				local mPointInfo 	= g_MetalPoints[ t_TargetMetalId ]
				
				if mPointInfo then

					if mPointInfo.ent and mPointInfo.ent:IsValid() then mPointPos = mPointInfo.ent:GetPos()
					elseif mPointInfo.pos then mPointPos = mPointInfo.pos else self.rResearch = true end

				end
				
				if h_Ground.HitPos:Distance( mPointPos ) < 50 then self.rMoveMode = 0 else self.rMoveMode = 1 end
				
				if h_Ground.MatType == MAT_METAL and ( ( h_Ground.HitWorld and h_Ground.HitPos:Distance( mPointPos ) < 20 )
					or ( mPointInfo and mPointInfo.ent and mPointInfo.ent:IsValid() and h_Ground.Entity == mPointInfo.ent ) ) then

					timer.Remove( "rRefind" .. self:EntIndex() )
					timer.Remove( "rWalking" .. self:EntIndex() )
					timer.Remove( "rRun" .. self:EntIndex() )
					
					h_StandAnimReset 	= true
					self.rMove 			= false
					self.rMoveStep 		= 0
					self.rModeStatus	= 1
					
					if mPointInfo then
					
						if mPointInfo.ent and mPointInfo.ent:IsValid() then
						
							self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
							h_Phys:SetMass( 1 )
							
							constraint.Weld( mPointInfo.ent, self, 0, 0, 0, collision == true, false )
							self.rDisableMovining = true
							
						end
					end
				end
				
			// ========================== Eating metal ======================
			elseif h_ModeStatus == 1 then
				
				local m_Name = "rEating"..self:EntIndex()
				local m_MetalAmount = self.rMetalAmount
				local t_Skip = false
				
				if ( table.Count( g_QueenCount ) == 0 and m_MetalAmount >= ( g_segments_to_assemble_queen - g_segments_to_assemble_replicator )) then
				
					t_Skip = true
					self.rModeStatus = 2
					
				end
				
				if not t_Skip and not timer.Exists( m_Name ) then
				
					timer.Create( m_Name, REPLICATOR.PlaySequence( self, "eating" ), 1, function()
					
						if self:IsValid() then
						
							local t_TargetMetalId = self.rTargetMetalId
							local mPointInfo = g_MetalPoints[ t_TargetMetalId ]
							local vPoint = Vector()

							if mPointInfo.ent then
								
								local t_Hegiht = 0
								if replicatorType == 1 then t_Hegiht = 4 
								elseif replicatorType == 2 then t_Hegiht = 12 end
								vPoint = self:LocalToWorld( Vector( 0, 0, -t_Hegiht ) )
								
							else
							
								vPoint = mPointInfo.pos - self:GetUp() * 5
							
							end
							
							local effectdata = EffectData()
							effectdata:SetOrigin( vPoint )
							effectdata:SetNormal( self:GetUp() )
							util.Effect( "acid_spit", effectdata )


							local t_TargetMetalAmount = 0
							if mPointInfo then t_TargetMetalAmount = mPointInfo.amount end
							
							local m_MetalAmount = self.rMetalAmount
							local h_ModeStatus = self.rModeStatus
							local m_Amount = g_replicator_collection_speed

							if t_TargetMetalAmount < g_replicator_collection_speed then m_Amount = t_TargetMetalAmount end

							if not (( m_MetalAmount + m_Amount ) < g_segments_to_assemble_replicator
								or ( table.Count( g_QueenCount ) == 0 
								and m_MetalAmount + m_Amount < ( g_segments_to_assemble_queen - g_segments_to_assemble_replicator ))) then

								timer.Remove( "rEating"..self:EntIndex() )
								
								self.rModeStatus 		= 2
								self.rMove 				= true
								self.rMoveMode 			= 1
								self.rDisableMovining 	= false

								if mPointInfo and mPointInfo.ent and mPointInfo.ent:IsValid() then
								
									constraint.RemoveAll( self )
									self:SetCollisionGroup( COLLISION_GROUP_NONE )
									
									if replicatorType == 1 then h_Phys:SetMass( 25 )
									elseif replicatorType == 2 then h_Phys:SetMass( 100 )
									end

								end
								
							end
							
							if ( t_TargetMetalAmount - m_Amount ) <= 0 then
								
								timer.Remove( "rEating"..self:EntIndex() )
								
								self.rDisableMovining 	= false
								self.rResearch			= true
								self.rModeStatus 		= 0

								if mPointInfo and ( mPointInfo.ent and mPointInfo.ent:IsValid() ) then

									self.rTargetEnt = Entity( 0 )
									
									if mPointInfo.ent then
										
										if mPointInfo.ent:IsValid() then
										
											constraint.RemoveAll( self )
											self:SetCollisionGroup( COLLISION_GROUP_NONE )
											
											if replicatorType == 1 then h_Phys:SetMass( 25 )
											elseif replicatorType == 2 then h_Phys:SetMass( 100 )
											end
											
											REPLICATOR.DissolveEntity( mPointInfo.ent )
											g_MetalPoints[ mPointInfo.ent:EntIndex() ] = nil
											g_MetalPointsAssigned[ mPointInfo.ent:EntIndex() ] = nil
											
										end
										
									else
									
										g_MetalPoints[ t_TargetMetalId ] = nil
									
									end
									
								end
							end

							if mPointInfo and g_MetalPoints[ t_TargetMetalId ] then
							
								self:EmitSound( "acid/acid_spit.wav", 60, 150 + math.Rand( -25, 25 ), 1, CHAN_AUTO )
								
								if mPointInfo.ent then
									
									if mPointInfo.ent:IsValid() then UpdateMetalEntity( mPointInfo.ent, t_TargetMetalAmount - m_Amount ) end
									
								elseif mPointInfo.pos then
								
									UpdateMetalPoint( t_TargetMetalId, t_TargetMetalAmount - m_Amount )
									
								end
								
							end
							
							m_MetalAmount = m_MetalAmount + m_Amount
							self.rMetalAmount = m_MetalAmount
							
						end
					end )
				end
				
			// ============================== Transporting metal ======================
			elseif h_ModeStatus == 2 then

				local m_QueenFounded = false
				
				if table.Count( g_QueenCount ) > 0 then
				
					local m_PathResult	= { }
					local m_QueenEnt 	= Entity( 0 )
					
					if self.rTargetGueen:IsValid() then
					
						m_PathResult 	= self.rMovePath
						m_QueenEnt 		= self.rTargetGueen
						
						self.rMoveReverse = false
						
					else
						m_PathResult = { self:GetPos() }

						local t_Path = {}
						local m_Case, m_Index = FindClosestPoint( self:GetPos(), 1 )

						t_PathGet, m_QueenEnt = GetPatchWayToClosestEnt( { case = m_Case, index = m_Index }, g_QueenCount )
						
						table.Add( m_PathResult, t_PathGet )
					end
					
					if table.Count( m_PathResult ) > 0 and m_QueenEnt:IsValid() then

						self.rMode = 1
						self.rModeStatus = 3
						
						self.rTargetGueen = m_QueenEnt
						
						self.rMove = true
						self.rMoveMode = 1
						
						self.rMoveStep = 1
						self.rMovePath = m_PathResult
						
						m_QueenFounded = true
						
					end
					
				elseif not m_QueenFounded then
				
					local m_MetalId = self.rTargetMetalId

					if g_MetalPoints[ m_MetalId ] and g_MetalPoints[ m_MetalId ].used then g_MetalPoints[ m_MetalId ].used = false end
					
					if table.Count( g_DarkPoints ) > 0 then
						
						local m_MetalId = self.rTargetMetalId

						if g_MetalPoints[ m_MetalId ].used then g_MetalPoints[ m_MetalId ].used = false end
						
						local m_Case, m_Index = FindClosestPoint( self:GetPos(), 1 )
						local m_PathResult, m_DarkId = GetPatchWayToClosestId( { case = m_Case, index = m_Index }, g_DarkPoints )
						
						if table.Count( m_PathResult ) > 0 then
						
							g_DarkPoints[ m_DarkId ].used = true
							
							self.rMode = 4
							self.rModeStatus = 1

							self.rMoveReverse = false
							
							self.rTargetDarkId = m_DarkId
							
							self.rMove= true
							self.rMoveStep = 1
							self.rMovePath = m_PathResult
							
						else self.rResearch = true end
						
					else self.rResearch = true end
					
				end
				
			elseif h_ModeStatus == 3 then
			
				// ======================= Wait until Replicator reaches queen ======================
				local m_QueenEnt = self.rTargetGueen
				
				if m_QueenEnt:IsValid() then
				
					if m_QueenEnt:GetPos():Distance( self:GetPos() ) < 40 then
					
						self.rModeStatus = 4
						self.rMove = false
					
					end
					
				else 
					
					self.rModeStatus = 2
					
				end
				
			elseif h_ModeStatus == 4 then

				// ======================= Giving metal ==========================
				local m_Name = "rGiving"..self:EntIndex()
				
				if not timer.Exists( m_Name ) then
				
					timer.Create( m_Name, REPLICATOR.PlaySequence( self, "stand" ), 1, function() timer.Remove( "rGiving"..self:EntIndex() ) end )
					
					local m_QueenEnt = self.rTargetGueen
					local m_MetalAmount = math.min( g_replicator_giving_speed, self.rMetalAmount )
					
					if m_QueenEnt and m_QueenEnt:IsValid() then
					
						m_QueenEnt.rMetalAmount = m_QueenEnt.rMetalAmount + m_MetalAmount
						self.rMetalAmount = self.rMetalAmount - m_MetalAmount
						
					else
						
						if table.Count( g_QueenCount ) > 0 then self.rModeStatus = 2
						else self.rModeStatus = 1 end
						
					end
					
					if self.rMetalAmount <= 0 then

						self.rMoveReverse 	= true
						self.rMove 			= true
						self.rMode 			= 1
						self.rModeStatus 	= 0
						
					end
				end
			end
			
		// ===================== Attack mode ======================
		elseif h_Mode == 2 then
		
			if h_ModeStatus == 0 then
			
				local m_Target = g_Attackers[ self.rTargetId ]
				
				if m_Target and m_Target:IsValid() then
				
					local m_Filter = { }
					table.Add( m_Filter, g_ReplicatorNoCollideGroupWith )
					table.Add( m_Filter, { "player", "npc" } )
					
					local m_Trace, m_TraceDist = REPLICATOR.TraceLine( self:GetPos(), m_Target:GetPos(), m_Filter )
					
					if not m_Trace.Hit or m_Target.Entity == m_Target then
					
						self.rMoveTo = m_Target:GetPos()
						timer.Start( "rRefind"..self:EntIndex() )
						
						if m_Target:GetPos():Distance( self:GetPos() ) < 150 then
						
							local h_Forward, h_ForwardDist = REPLICATOR.TraceHullQuick( self:GetPos(), self:GetForward() * 50, Vector( 12, 12, 12 ), g_ReplicatorNoCollideGroupWith )

							if h_Forward.Hit and h_Forward.Entity == m_Target then
							
								self:SetAngles( ( m_Target:GetPos() - h_Phys:GetPos() ):Angle() + Angle( -90, 0, 0 ) )
								self:SetPos( h_Forward.HitPos )

								self.rModeStatus 	= 1
								self.rMove 			= false
								h_StandAnimReset 	= true
								
								self:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )
								timer.Remove( "rRefind"..self:EntIndex() )

								if m_Target:IsPlayer() or m_Target:IsNPC() then self:SetParent( m_Target, 1 )
								else self:SetParent( m_Target, -1 ) end
								
							end
							
							if h_Ground.Hit then
								
								self.rDisableMovining = true
								h_Phys:SetVelocity( ( m_Target:GetPos() + Vector( 0, 0, m_Target:OBBMaxs().z ) - h_Phys:GetPos() ) * 4 )
								
							else
							
								local JUANG = self:WorldToLocalAngles( ( m_Target:GetPos() - h_Phys:GetPos() ):Angle() ).y
								local zeroAng = self:WorldToLocalAngles( Angle( 0, JUANG + self:GetAngles().yaw, 0 ) )

								h_Phys:AddAngleVelocity( Vector( zeroAng.z, zeroAng.x, zeroAng.y ) * 6 - h_Phys:GetAngleVelocity() )

							end
							
						else self.rDisableMovining = false end
					end
					
				else
				
					self.rMode = 0
					self.rResearch = true
					
				end
				
			elseif h_ModeStatus == 1 then
			
				local name = "rDamagining"..self:EntIndex()
				
				local function UnParm_Ent( self, h_Phys, m_Target, m_TargetCase )
				
					constraint.RemoveAll( self )
					
					self.rMode 				= 0
					self.rMoveStatus 		= 0
					self.rResearch 			= true
					self.rMove 				= true
					self.rTargetId 			= ""
					self.rDisableMovining 	= false 
					
					timer.Remove( name )
					
					self:SetParent( NULL )
					self:SetCollisionGroup( COLLISION_GROUP_NONE )
					
					if m_Target then g_Attackers[ m_TargetCase ] = nil end
					
				end

				if not timer.Exists( name ) then
				
					h_StandAnimReset = true

					timer.Create( name, REPLICATOR.PlaySequence( self, "eating" ) / 10, 1, function() end )
					
					local m_Target = g_Attackers[ self.rTargetId ]
					
					if m_Target then
					
						if m_Target:IsValid() and m_Target:Health() > 0 then
						
							m_Target:TakeDamage( 3, self, self )
							h_Phys = self:GetPhysicsObject()
							
						end
					
						if m_Target:Health() <= 0 then UnParm_Ent( self, h_Phys, m_Target, self.rTargetId ) end
						
					else UnParm_Ent( self, h_Phys ) end
				end
				
				if self.rTargetId then
				
					local m_Target = g_Attackers[ self.rTargetId ]
					
					if m_Target then
					
						if m_Target:Health() <= 0 then UnParm_Ent( self, h_Phys, m_Target, self.rTargetId ) end
						
					else UnParm_Ent( self, h_Phys ) end
					
				end
				
			elseif h_ModeStatus == 2 then
			end
			
		elseif h_Mode == 3 then
			
		// ===================== Crafting mode ======================
		elseif h_Mode == 4 then
		
			if h_ModeStatus == 1 then
			
				local m_DarkId = self.rTargetDarkId
			
				if h_Ground.HitPos:Distance( g_DarkPoints[ m_DarkId ].pos ) < 50 then self.rMoveMode = 0
				else self.rMoveMode = 1 end

				if g_DarkPoints[ m_DarkId ].pos:Distance( h_Ground.HitPos ) < 10 then
					
					timer.Remove( "rWalking" .. self:EntIndex() )
					timer.Remove( "rRun" .. self:EntIndex() )
					timer.Remove( "rRefind"..self:EntIndex() )
					
					h_StandAnimReset 	= true
					
					self.rMove 			= false
					self.rMoveStep		= 0
					self.rModeStatus	= 2
					
					timer.Simple( REPLICATOR.PlaySequence( self, "crafting_start" ), function()
					
						// IF QUEEN
						if replicatorType == 2 then
						
							g_QueenCount[ self:EntIndex() ] = self
							g_WorkersCount[ self:EntIndex() ] = nil
							
							net.Start( "rDrawStorageEffect" ) net.WriteEntity( self ) net.Broadcast()
							
						end
						
						timer.Create( "rCrafting" .. self:EntIndex(), REPLICATOR.PlaySequence( self, "crafting" ), 0, function()
						
							if self:IsValid() then
							
								if self.rMetalAmount >= 1 and table.Count( g_WorkersCount ) < g_replicator_limit then
								
									local m_Ent = ents.Create( "replicator_segment" )
									self:EmitSound( "physics/metal/weapon_impact_soft" .. math.random( 1, 3 ) .. ".wav", 60, 150 + math.Rand( -25, 25 ), 1, CHAN_AUTO )
									
									if ( !IsValid( m_Ent ) ) then return end
									m_Ent:SetPos( self:GetPos() + self:GetForward() * 6 - self:GetUp() * 3 )
									m_Ent:SetAngles( AngleRand() )
									m_Ent:SetOwner( self:GetOwner() )
									m_Ent:Spawn()
									
									if replicatorType == 1 then m_Ent.rCraftingQueen = true end
									
									local h_Phys = m_Ent:GetPhysicsObject()
									h_Phys:Wake()
									h_Phys:SetVelocity( VectorRand() * 40 + self:GetForward() * 60 )	
									
									self.rMetalAmount = self.rMetalAmount - 1
									
								elseif replicatorType != 2 then
								
									// ====================== Self Destruction ======================

									g_DarkPoints[ m_DarkId ].used = false
									
									REPLICATOR.ReplicatorBreak( replicatorType, self, 10, self:WorldToLocal( Vector() ), true )
									
								end
							end
						end )
					end )
				end
			end
		end
	end
	
	REPLICATOR.ReplicatorWalking( replicatorType, self, h_Ground, h_GroundDist, h_Move, h_MoveMode )
		
	REPLICATOR.ReplicatorWalkingAnimation( replicatorType, self, h_Move, h_MoveMode, h_StandAnimReset )
	
	REPLICATOR.ReplicatorScanningResources( self )

	if not h_Phys:IsGravityEnabled() and h_Phys:IsMotionEnabled() then h_Phys:SetVelocity( self:GetForward() * h_Phys:GetMass() / 2 ) end

		
	local m_Pos, m_PosString = REPLICATOR.ConvertToGrid( h_Ground.HitPos, 30 )

	if h_Ground.MatType == MAT_METAL then
		
		if h_Ground.HitWorld then 
			
			self.rTargetMetalId = m_PosString
			if not g_MetalPointsAssigned[ m_PosString ] then AddMetalPoint( m_PosString, h_Ground.HitPos, h_Ground.HitNormal, 100 ) end
		
		elseif h_Ground.Entity:IsValid() then
						
			self.rTargetMetalId = h_Ground.Entity:EntIndex()
			if not g_MetalPointsAssigned[ self.rTargetMetalId ] then AddMetalEntity( h_Ground.Entity ) end
			
		end
	end
end