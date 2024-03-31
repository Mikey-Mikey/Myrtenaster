AddCSLuaFile()
ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Ice Spike Line"
ENT.Author = ""
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:Initialize()
    self:SetModel("models/props_junk/PopCan01a.mdl") -- can model
    self:SetNoDraw(true)
    self:DrawShadow(false)
    if CLIENT then return end
    self.spikes = {}
    self.direction = self.direction or Vector(1, 0, 0)

    self.spike_pos = self:GetPos()
    self.spike_normal = Vector(0, 0, 1)

    self:CreateTimer("Spawn Spike" .. self:EntIndex(), 0.05, 10, function()
        local spike_tr = util.TraceLine({
            start = self.spike_pos + self.spike_normal * 50,
            endpos = self.spike_pos + self.direction * 100 + self.spike_normal * 50,
            filter = self
        })
        if not spike_tr.Hit or spike_tr.StartSolid then
            spike_tr = util.TraceLine({
                start = self.spike_pos + self.direction * 50 + self.spike_normal * 100,
                endpos = self.spike_pos + self.direction * 50 - self.spike_normal * 100,
                filter = self
            })
        end

        if not spike_tr.Hit then
            spike_tr = util.TraceLine({
                start = self.spike_pos + self.direction * 50 + self.spike_normal * 100,
                endpos = self.spike_pos - self.direction * 175 - self.spike_normal * 100,
                filter = self
            })
        end
        if spike_tr.Hit then
            self.spike_pos = spike_tr.HitPos
            self.spike_normal = spike_tr.HitNormal
            local ang_diff = Angle(0, 0, 0)
            ang_diff[1] = self.direction:Dot(self.spike_normal)
            ang_diff[3] = self.direction:Cross(self.spike_normal):Dot(self.spike_normal)
            self.direction:Rotate(ang_diff)
            self:SpawnSpike(self.spike_pos, self.spike_normal:Angle() + Angle(90,0,0))
        end
    end)
    local dir = self.direction
    self:CreateTimer("MyrtenasterIceSpikeMelt", 5, 1, function()
        EmitSound("Myrtenaster/IceSpikesMelt.wav", self:GetPos() + dir * 250, 75, 125, 0.4, CHAN_AUTO)
    end)
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

function ENT:SpawnSpike(pos, ang) -- perform the spike spawn code here
    local spike = ents.Create("rwby_icespike")
    spike:SetPos(pos)
    spike:SetAngles(ang)
    spike:Spawn()

    self.spikes[#self.spikes + 1] = spike
end

function ENT:OnRemove()
    for k, v in pairs(self.spikes) do
        if IsValid(v) then
            v:Remove()
        end
    end
end