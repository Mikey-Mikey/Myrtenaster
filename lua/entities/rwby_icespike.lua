AddCSLuaFile()
ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Ice Spike"
ENT.Author = ""
ENT.Spawnable = false
ENT.AdminSpawnable = false

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function ease(a, b, t, pow)
	t = math.Clamp(t, 0, 1)
	t = t ^ pow / (t ^ pow + (1 - t) ^ pow)
	return lerp(a, b, t)
end

local function easeIn(a, b, t, pow)
    t = math.Clamp(t, 0, 1)
    t = t ^ pow
    return lerp(a, b, t)
end

local function easeOut(a, b, t, pow)
    t = math.Clamp(t, 0, 1)
    t = 1 - (1 - t) ^ pow
    return lerp(a, b, t)
end

function ENT:Initialize()
    self:SetModel("models/icespike/stalactite_cluster01a.mdl")
    self:SetMaterial("models/rwby/icespike/ice_overlay")
    self:DrawShadow(false)
    self:SetPos(self:GetPos() - self:GetUp() * 2)
    self.SpawnTime = CurTime()
    --self:SetRenderMode(RENDERMODE_TRANSTEXTURE)
    --self:SetColor(Color(255, 255, 255, 230))
    if SERVER then
        self:CreateTimer("StartMovingDown" .. self:EntIndex(), 5, 1, function()
            if IsValid(self) then
                SafeRemoveEntityDelayed(self, 0.36)
            end
        end)
    else
        local scl = 0
        local scale = Vector(1, 1, scl)

        local mat = Matrix()
        mat:Scale(scale)
        self:EnableMatrix("RenderMultiply", mat)

        self:CreateTimer("SpikeUpAnim" .. self:EntIndex(), 0.01, 24, function()
            if IsValid(self) then
                scl = scl + 1 / 24
                local scale = Vector(1, 1, easeOut(0, 1, scl, 2))

                local mat = Matrix()
                mat:Scale(scale)
                self:EnableMatrix("RenderMultiply", mat)
            else
                self:RemoveTimer("SpikeUpAnim" .. self:EntIndex())
            end
        end)
        self:CreateTimer("StartMovingDown" .. self:EntIndex(), 5, 1, function()
            if IsValid(self) then
                self:CreateTimer("SpikeDownAnim" .. self:EntIndex(), 0.01, 24, function()
                    if IsValid(self) then
                        scl = scl - 1 / 24
                        local scale = Vector(1, 1, ease(0, 1, scl, 2))

                        local mat = Matrix()
                        mat:Scale(scale)
                        self:EnableMatrix("RenderMultiply", mat)
                    end
                end)
            end
        end)
    end
end

function ENT:CreateTimer(name, delay, reps, func)
    timer.Create(name .. self:EntIndex(), delay, reps, function()
        if IsValid(self) then
            func()
        else -- if the entity is invalid, remove the timer
            timer.Remove(name .. self:EntIndex())
        end
    end)
end

function ENT:RemoveTimer(name)
    timer.Remove(name .. self:EntIndex())
end

function ENT:DrawTranslucent()
    for i = 1, 3 do -- spread
        for a = 1, 7 do -- ang
            self:SetupBones()
            local pos = Vector(i * 20, 0, 0)
            pos:Rotate(Angle(0, a * (360 / 7), 0))
            self:ManipulateBonePosition(0, pos + Vector(0,0,36))
            self:ManipulateBoneAngles(0, Angle(i * 130,180 + math.sin((i + a + self.SpawnTime) * 2543) * 15,math.sin((i + a + self.SpawnTime) * 27364) * 15))
            self:DrawModel()
        end
    end
end

function ENT:Draw()
    for i = 1, 3 do -- spread
        for a = 1, 4 do -- ang
            self:SetupBones()
            local pos = Vector(i * 20, 0, 0)
            pos:Rotate(Angle(0, a * (360 / 4) + self.SpawnTime * 1000 * 360, 0))
            self:ManipulateBonePosition(0, pos + Vector(0,0,40))
            self:ManipulateBoneAngles(0, Angle(i * 130,180 + math.sin((i + a + self.SpawnTime) * 2543) * 15,math.sin((i + a + self.SpawnTime) * 27364) * 15))
            self:DrawModel()
        end
    end
end