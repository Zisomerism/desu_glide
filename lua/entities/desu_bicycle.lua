AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_glide_motorcycle"
ENT.PrintName = "Bicycle"

ENT.GlideCategory = "Desu's Glide Stuff"
ENT.ChassisModel = "models/props_bikes/bike_frame.mdl"

ENT.MaxChassisHealth = 10000

DEFINE_BASECLASS( "base_glide_motorcycle" )
local Abs = math.abs
local Clamp = math.Clamp

    function ENT:GetFirstPersonOffset( seatIndex, localEyePos )
        if seatIndex == TURRET_SEAT_INDEX then
            return Vector( -30, 0, 115 )
        end

        localEyePos[1] = localEyePos[1] + 5
        localEyePos[3] = localEyePos[3] + 10

        return localEyePos
    end

function ENT:GetFirstPersonOffset( seatIndex, localEyePos )
    if seatIndex == 1 then
        localEyePos[1] = localEyePos[1] + 18
        localEyePos[3] = localEyePos[3] - 15
    else
        localEyePos[1] = localEyePos[1] - 8
        localEyePos[3] = localEyePos[3] + 10
    end
    return localEyePos
end

ENT.UneditableNWVars = {
    WheelRadius = false,
    SuspensionLength = false,
    PowerDistribution = false,
    ForwardTractionBias = false
}

if CLIENT then
    ENT.CameraOffset = Vector( -170, 0, 50 )

    ENT.StartSound = ""
    ENT.StoppedSound = ""
    ENT.HornSound = "glide/horns/ding.wav"

    function ENT:OnCreateEngineStream( stream )
        stream.offset = Vector( 5, 0, 0 )
        stream:LoadPreset( "desubike" )
    end

    function ENT:OnActivateMisc()
        BaseClass.OnActivateMisc( self )

        self.frontBoneId = self:LookupBone( "front_wheel" )
        self.rearBoneId = self:LookupBone( "back_wheel" )
        self.chainBoneId = self:LookupBone( "chaining" )
        self.forkBoneId = self:LookupBone( "fork" )
        self.velBoneMod = 0
    end

    local spinAng = Angle()
    local steerAngle = Angle()

    function ENT:OnUpdateAnimations()
        BaseClass.OnUpdateAnimations( self )

        self:SetPoseParameter( "suspension_front", 1 - ( Abs( self:GetWheelOffset( 1 ) ) / 7 ) )
        self:SetPoseParameter( "suspension_rear", 1 - ( Abs( self:GetWheelOffset( 2 ) ) / 7 ) )
        self:InvalidateBoneCache()

        if not self.frontBoneId then return end

        spinAng[3] = -self:GetWheelSpin( 1 )
        self:ManipulateBoneAngles( self.frontBoneId, spinAng, false )
        spinAng[3] = -self:GetWheelSpin( 2 )
        self:ManipulateBoneAngles( self.rearBoneId, spinAng, false )
        spinAng[3] = spinAng[3] * self:GetEngineThrottle()
        self:ManipulateBoneAngles( self.chainBoneId, spinAng, false )

        if not self.forkBoneId then return end
        self.velBoneMod = self:GetVelocity():Length()
        steerAngle[1] = self:GetSteering() * -28
        self:ManipulateBoneAngles( self.forkBoneId, steerAngle )
    end

    local POSE_DATA = {
        ["ValveBiped.Bip01_L_Thigh"] = Angle( -5, -5, 0 ),
        ["ValveBiped.Bip01_L_Calf"] = Angle( -5, 60, 25 ),
        ["ValveBiped.Bip01_R_Thigh"] = Angle( 5, -5, 0 ),
        ["ValveBiped.Bip01_R_Calf"] = Angle( 5, 60, -25 )
    }

    local DRIVER_POSE_DATA = {
        ["ValveBiped.Bip01_Pelvis"] = Angle( 0, 0, 20 ),
        ["ValveBiped.Bip01_Spine"] = Angle( 0, 30, 0 ),
        ["ValveBiped.Bip01_Spine1"] = Angle( 0, 20, 0 ),
        ["ValveBiped.Bip01_Neck1"] = Angle( 0, 20, 0 ),
        ["ValveBiped.Bip01_Head1"] = Angle( 0, 20, 0 ),

        ["ValveBiped.Bip01_L_UpperArm"] = Angle( -40, -30, 0 ),
        ["ValveBiped.Bip01_R_UpperArm"] = Angle( 30, -40, 0 ),

        ["ValveBiped.Bip01_L_Forearm"] = Angle( -10, -10, 0 ),
        ["ValveBiped.Bip01_R_Forearm"] = Angle( -10, -20, 0 ),

        ["ValveBiped.Bip01_L_Hand"] = Angle( -40, 0, 0 ),
        ["ValveBiped.Bip01_R_Hand"] = Angle( 20, 0, 0 ),

        ["ValveBiped.Bip01_L_Thigh"] = Angle( -10, 20, 0 ),
        ["ValveBiped.Bip01_L_Calf"] = Angle( 0, 0, 0 ),
        ["ValveBiped.Bip01_L_Foot"] = Angle( 0, 0, 0 ),

        ["ValveBiped.Bip01_R_Thigh"] = Angle( 10, 20, 0 ),
        ["ValveBiped.Bip01_R_Calf"] = Angle( 0, 0, 0 ),
        ["ValveBiped.Bip01_R_Foot"] = Angle( 0, 0, 0 ),
    }

    local FrameTime = FrameTime
    local ExpDecayAngle = Glide.ExpDecayAngle

    function ENT:GetSeatBoneManipulations( seatIndex )
        if seatIndex > 1 then
            return POSE_DATA
        end

        local decay = 5
        local dt = FrameTime()
        local resting = self.velBoneMod < 20
        local thigh = DRIVER_POSE_DATA["ValveBiped.Bip01_R_Thigh"]
        local calf = DRIVER_POSE_DATA["ValveBiped.Bip01_R_Calf"]
        local foot = DRIVER_POSE_DATA["ValveBiped.Bip01_R_Foot"]

        thigh[1] = ExpDecayAngle( thigh[1], resting and 10 or 10, decay, dt )
        thigh[2] = ExpDecayAngle( thigh[2], resting and 50 or 20, decay, dt )
        thigh[3] = ExpDecayAngle( thigh[3], resting and 0 or 0, decay, dt )

        calf[1] = ExpDecayAngle( calf[1], resting and 0 or 0, decay, dt )
        calf[2] = ExpDecayAngle( calf[2], resting and -30 or 0, decay, dt )

        foot[2] = ExpDecayAngle( foot[2], resting and 40 or 0, decay, dt )

        return DRIVER_POSE_DATA
    end
end

if SERVER then
    ENT.ChassisMass = 200
    ENT.SpawnPositionOffset = Vector( 0, 0, 40 )
    ENT.StartupTime = 0
    ENT.BurnoutForce = 50
    ENT.TiltForce = -100
    ENT.KeepUprightForce = 300
    ENT.KeepUprightDrag = -1
    ENT.WheelieMaxAng = 40
    ENT.WheelieDrag = -15
    ENT.WheelieForce = 600
    ENT.SuspensionHeavySound = ""
    ENT.SuspensionDownSound = ""
    ENT.SuspensionUpSound = ""
    ENT.ExplosionRadius = 0

    function ENT:InitializePhysics()
        self:SetSolid( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:PhysicsInit( SOLID_VPHYSICS, Vector( 0, 0, -12 ) )
    end

    function ENT:OnPostInitialize()
        BaseClass.OnPostInitialize( self )
        self:SetMaxSteerAngle( 30 )
        self:SetSteerConeChangeRate( 4 )
        self:SetSteerConeMaxSpeed( 400 )
        self:SetCounterSteer( 0.0 )
        self.EngineDamageMultiplier = 0
        self.engineBreakTorque = 0
        self.flywheelTorque = 0
        self.flywheelMass = 100
        self.flywheelRadius = 5
        self.LastBhop = 0
    end

    function ENT:CreateFeatures()
        self:SetTransmissionEfficiency( 1 )
        self:SetDifferentialRatio( 0.1 )
        self:SetBrakePower( 300 )

        self:SetMinRPM( 100 )
        self:SetMaxRPM( 1000 )

        self:SetMinRPMTorque( 900 )
        self:SetMaxRPMTorque( 1600 )

        self:SetSpringStrength( 1000 )
        self:SetSpringDamper( 5000 )
        self:SetSuspensionLength( 20 )

        self:CreateSeat( Vector( -20, 0, 38 ), Angle( 0, 270, -16 ), Vector( 0, 60, 0 ), true )
        self:CreateSeat( Vector( -26, 0, 23 ), Angle( 0, 270, -5 ), Vector( 0, -60, 0 ), true )

        -- Front
        self:CreateWheel( Vector( 23, 0, 32 ), {
            steerMultiplier = 1,
            disableSounds = true
        } )

        -- Rear
        self:CreateWheel( Vector( -21, 0, 32 ), {
            steerMultiplier = -0.1
        } )

        --self:GetPhysicsObjectNum( self:TranslateBoneToPhysBone( self:LookupBone( "front_wheel" ) ) ):EnableCollisions( false )
        --self:GetPhysicsObjectNum( self:TranslateBoneToPhysBone( self:LookupBone( "back_wheel" ) ) ):EnableCollisions( false )

        for _, w in ipairs( self.wheels ) do
            Glide.HideEntity( w, true )
        end

        self:ChangeWheelRadius( 15 )
    end

    function ENT:GetGears()
        return {
            [0] = 0,
            [1] = 4.82,
            [2] = 4.07,
            [3] = 3.53,
            [4] = 3.12,
            [5] = 2.79,
            [6] = 2.52,
            [7] = 2.30,
            --[8] = 2.12,
            --[9] = 1.89,
            --[10] = 1.77,
            --[11] = 1.66,
            --[12] = 1.56
        }
    end

    function ENT:SwitchGear( index, cooldown )
        if self:GetGear() == index then return end

        index = Clamp( index, self.minGear, self.maxGear )

        self.switchCD = cooldown or ( index == 1 and 0 or ( self:GetFastTransmission() and 0 or 0.2 ) )
        self.clutch = 1
        self:SetGear( index )
    end

    function ENT:GetYawDragMultiplier()
        return 0.25
    end

    local WORLD_X = Vector( 1, 0, 0 )
    local WORLD_Y = Vector( 0, 1, 0 )
    local WORLD_Z = Vector( 0, 0, 1 )

    function ENT:OnSimulatePhysics( phys, _, outLin, outAng )
        local frontPos = self.wheels[1]:GetPos()
        local forward = self:GetForward()
        local trX = util.QuickTrace( frontPos - ( WORLD_X * 200 ), WORLD_X * 400, self )
        local trY = util.QuickTrace( frontPos - ( WORLD_Y * 200 ), WORLD_Y * 400, self )
        local trZ = util.QuickTrace( frontPos, WORLD_Z * 50, self )
        local angCheck = Abs( self:GetAngles()[3] ) > 25

        if trX.Hit or trY.Hit or trZ.Hit or angCheck then
            phys:EnableCollisions( true )
        else
            phys:EnableCollisions( false )
        end

        if not self.stayUpright then return end
        if self:IsPlayerHolding() then return end

        local isAnyWheelGrounded = self.groundedCount > 0
        local angVel = phys:GetAngleVelocity()
        local mass = phys:GetMass()

        local rt = self:GetRight()
        local angles = self:GetAngles()

        -- Wheelie
        local leanBack = self:GetInputBool( 1, "lean_back" )

        if leanBack and isAnyWheelGrounded then
            local strength = 1 - Clamp( Abs( angles[1] ) / self.WheelieMaxAng, 0, 1 )

            -- Wheelie angular drag
            outAng[2] = outAng[2] + angVel[2] * mass * self.WheelieDrag * strength

            local l, a = phys:CalculateForceOffset( self:GetUp() * mass * strength * self.WheelieForce, frontPos )

            outLin[1] = outLin[1] + l[1]
            outLin[2] = outLin[2] + l[2]
            outLin[3] = outLin[3] + l[3]

            outAng[1] = outAng[1] + a[1]
            outAng[2] = outAng[2] + a[2]
            outAng[3] = outAng[3] + a[3]
        end

        -- Bunnyhop
        local leanForward = self:GetInputBool( 1, "lean_forward" )

        if leanForward and isAnyWheelGrounded and CurTime() > self.LastBhop + 1 then

            local strength  = 1 * Clamp( self.totalSpeed / 100, 0.1, 1 )

            local massPos = phys:GetMassCenter()
            local l, _ = phys:CalculateForceOffset( self:GetUp() * mass * strength * 10000, massPos )

            outLin[1] = outLin[1] + l[1]
            outLin[2] = outLin[2] + l[2]
            outLin[3] = outLin[3] + l[3]

            self.LastBhop = CurTime()
        end

        -- Apply keep upright force depending on how much we are tilting
        local dot = WORLD_Z:Dot( rt )
        dot = angles[3] > -90 and angles[3] < 90 and dot or -dot

        local tiltForce = isAnyWheelGrounded and self.TiltForce or self.TiltForce * 0.2

        outAng[1] = outAng[1] + self.steerTilt * mass * tiltForce
        outAng[1] = outAng[1] + angVel[1] * mass * self.KeepUprightDrag
        outAng[1] = outAng[1] + dot * mass * self.KeepUprightForce

        local revForce = forward * mass * self.reverseInput * -500

        outLin[1] = outLin[1] + revForce[1]
        outLin[2] = outLin[2] + revForce[2]
        outLin[3] = outLin[3] + revForce[3]
    end

    function ENT:CheckWaterLevel()
    end


end
