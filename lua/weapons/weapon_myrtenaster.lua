AddCSLuaFile()

if CLIENT then
	--SWEP.WepSelectIcon		= surface.GetTextureID("HUD/swepicons/weapon_neptunesword/icon") 
	SWEP.DrawWeaponInfoBox	= false
	SWEP.BounceWeaponIcon	= false

	language.Add("weapon_myrtenaster", "Myrtenaster")
	--killicon.Add("weapon_myrtenaster", "effects/killicons/weapon_neptunesword", color_white)
end

if SERVER then
	util.AddNetworkString("RWBY_Myrtenaster_Switch_Dust")
end

SWEP.PrintName = "Myrtenaster"
SWEP.Category = "RWBY"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.AdminOnly = false

SWEP.ViewModelFOV = 75
SWEP.ViewModel = "models/weapons/c_invisstick2.mdl"
SWEP.WorldModel = "models/weapons/w_stunbaton.mdl"
SWEP.ViewModelFlip = false
SWEP.BobScale = 2
SWEP.SwayScale = 2

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Weight = 0
SWEP.Slot = 1
SWEP.SlotPos = 1

SWEP.UseHands = true
SWEP.HoldType = "melee"
SWEP.FiresUnderwater = true
SWEP.DrawCrosshair = true
SWEP.DrawAmmo = true
SWEP.CSMuzzleFlashes = 1
SWEP.Base = "weapon_base"
SWEP.ShowViewModel = false
SWEP.ShowWorldModel = false

SWEP.Idle = 0
SWEP.IdleTimer = CurTime()

SWEP.Primary.Sound = Sound("common/null.wav")
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Damage = 40
SWEP.Primary.DelayMiss = 0.3
SWEP.Primary.DelayHit = 0.3
SWEP.Primary.Force = 1500

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 3

SWEP.ViewModelBoneMods = {}

SWEP.VElements = {
	["v_element"] = { type = "Model", model = "models/blueflytrap/rwby/myrtenaster.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(2.918, 1.518, -6), angle = Angle(-88, -70, 180), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["w_element"] = { type = "Model", model = "models/blueflytrap/rwby/myrtenaster.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(4, 0, -6), angle = Angle(285, 70, -90), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	self:SetWeaponHoldType(self.HoldType)
	self.CurrentHit = 0
	self.Idle = 0
	self.IdleTimer = CurTime() + 1
	self.ActiveDust = "Fire"
	if CLIENT then
		self.DustAnimTime = 0
		-- Create a new table for every weapon instance
		self.VElements = table.FullCopy(self.VElements)
		self.WElements = table.FullCopy(self.WElements)
		self.ViewModelBoneMods = table.FullCopy(self.ViewModelBoneMods)
		self:SetWeaponHoldType(self.HoldType)

		self:CreateModels(self.VElements) -- create viewmodels
		self:CreateModels(self.WElements) -- create worldmodels

		-- init view model bone build function
		if IsValid(self.Owner) then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)

				-- Init viewmodel visibility
				if self.ShowViewModel == nil or self.ShowViewModel then
					vm:SetColor(Color(255,255,255,255))
				else
					-- we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
					vm:SetColor(Color(255,255,255,1))
					-- ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
					-- however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
					vm:SetMaterial("Debug/hsv")
				end
			end
		end

	end

end

----------------------------------------------------
if CLIENT then

	SWEP.vRenderOrder = nil
	function SWEP:ViewModelDrawn()

		local vm = self.Owner:GetViewModel()
		if not IsValid(vm) then return end

		if not self.VElements then return end

		self:UpdateBonePositions(vm)

		if not self.vRenderOrder then

			-- we build a render order because sprites need to be drawn after models
			self.vRenderOrder = {}

			for k, v in pairs(self.VElements) do
				if v.type == "Model" then
					table.insert(self.vRenderOrder, 1, k)
				elseif  v.type == "Sprite" or v.type == "Quad" then
					table.insert(self.vRenderOrder, k)
				end
			end

		end

		for k, name in ipairs(self.vRenderOrder) do

			local v = self.VElements[name]
			if not v then self.vRenderOrder = nil break end
			if v.hide then continue end

			local model = v.modelEnt
			local sprite = v.spriteMaterial

			if not v.bone then continue end

			local pos, ang = self:GetBoneOrientation(self.VElements, v, vm)

			if not pos then continue end

			if v.type == "Model" and IsValid(model) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				--model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix("RenderMultiply", matrix)

				if v.material == "" then
					model:SetMaterial("")
				elseif  model:GetMaterial()   ~= v.material then
					model:SetMaterial(v.material)
				end

				if v.skin and v.skin   ~= model:GetSkin() then
					model:SetSkin(v.skin)
				end

				if v.bodygroup then
					for k2, v2 in pairs(v.bodygroup) do
						if model:GetBodygroup(k2) == v2 then continue end
							model:SetBodygroup(k2, v2)
					end
				end

				if v.surpresslightning then
					render.SuppressEngineLighting(true)
				end

				render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
				render.SetBlend(v.color.a / 255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)

				if v.surpresslightning then
					render.SuppressEngineLighting(false)
				end

			elseif  v.type == "Sprite" and sprite then

				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)

			elseif  v.type == "Quad" and v.draw_func then

				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func(self)
				cam.End3D2D()

			end

		end

	end

	SWEP.wRenderOrder = nil
	function SWEP:DrawWorldModel()

		if self.ShowWorldModel == nil or self.ShowWorldModel then
			self:DrawModel()
		end

		if not self.WElements then return end

		if not self.wRenderOrder then

			self.wRenderOrder = {}

			for k, v in pairs(self.WElements) do
				if v.type == "Model" then
					table.insert(self.wRenderOrder, 1, k)
				elseif  v.type == "Sprite" or v.type == "Quad" then
					table.insert(self.wRenderOrder, k)
				end
			end

		end

		if IsValid(self.Owner) then
			bone_ent = self.Owner
		else
			-- when the weapon is dropped
			bone_ent = self
		end

		for k, name in pairs(self.wRenderOrder) do

			local v = self.WElements[name]
			if not v then self.wRenderOrder = nil break end
			if v.hide then continue end

			local pos, ang

			if v.bone then
				pos, ang = self:GetBoneOrientation(self.WElements, v, bone_ent)
			else
				pos, ang = self:GetBoneOrientation(self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand")
			end

			if not pos then continue end

			local model = v.modelEnt
			local sprite = v.spriteMaterial

			if v.type == "Model" and IsValid(model) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				--model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix("RenderMultiply", matrix)

				if v.material == "" then
					model:SetMaterial("")
				elseif  model:GetMaterial()   ~= v.material then
					model:SetMaterial(v.material)
				end

				if v.skin and v.skin   ~= model:GetSkin() then
					model:SetSkin(v.skin)
				end

				if v.bodygroup then
					for k2, v2 in pairs(v.bodygroup) do
						if model:GetBodygroup(k2) == v2 then continue end
							model:SetBodygroup(k2, v2)
					end
				end

				if v.surpresslightning then
					render.SuppressEngineLighting(true)
				end

				render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
				render.SetBlend(v.color.a / 255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)

				if v.surpresslightning then
					render.SuppressEngineLighting(false)
				end

			elseif  v.type == "Sprite" and sprite then

				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)

			elseif  v.type == "Quad" and v.draw_func then

				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func(self)
				cam.End3D2D()

			end

		end

	end

	function SWEP:GetBoneOrientation(basetab, tab, ent, bone_override)
		local bone, pos, ang
		if tab.rel and tab.rel   ~= "" then

			local v = basetab[tab.rel]

			if not v then return end

			pos, ang = self:GetBoneOrientation(basetab, v, ent)

			if not pos then return end

			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)

		else
			bone = ent:LookupBone(bone_override or tab.bone)

			if not bone then return end

			pos, ang = Vector(0,0,0), Angle(0,0,0)
			local m = ent:GetBoneMatrix(bone)
			if m then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end

			if IsValid(self.Owner) and self.Owner:IsPlayer() and
				ent == self.Owner:GetViewModel() and self.ViewModelFlip then
				ang.r = -ang.r -- Fixes mirrored models
			end

		end

		return pos, ang
	end

	function SWEP:CreateModels(tab)

		if not tab then return end

		for k, v in pairs(tab) do
			if not (v.type == "Model" and v.model and v.model   ~= "" and (not IsValid(v.modelEnt) or v.createdModel   ~= v.model) and
			string.find(v.model, ".mdl") and file.Exists (v.model, "GAME")) then
				if v.type == "Sprite" and v.sprite and v.sprite   ~= "" and (not v.spriteMaterial or v.createdSprite   ~= v.sprite)
					and file.Exists ("materials/" .. v.sprite .. ".vmt", "GAME") then

					local name = v.sprite .. "-"
					local params = { ["$basetexture"] = v.sprite }
					-- make sure we create a unique name based on the selected options
					local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
					for i, j in pairs(tocheck) do
						if not v[j] then
							name = name .. "0"
							continue
						end
						params["$" .. j] = 1
						name = name .. "1"
					end

					v.createdSprite = v.sprite
					v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)

				end
				continue
			end

			v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)

			if IsValid(v.modelEnt) then
				v.modelEnt:SetPos(self:GetPos())
				v.modelEnt:SetAngles(self:GetAngles())
				v.modelEnt:SetParent(self)
				v.modelEnt:SetNoDraw(true)
				v.createdModel = v.model
			else
				v.modelEnt = nil
			end
		end

	end

	local allbones
	local hasGarryFixedBoneScalingYet = false

	function SWEP:UpdateBonePositions(vm)

		if self.ViewModelBoneMods then

			if not vm:GetBoneCount() then return end

			-- !! WORKAROUND !! --
			-- We need to check all model names :/
			local loopthrough = self.ViewModelBoneMods
			if not hasGarryFixedBoneScalingYet then
				allbones = {}
				for i = 0, vm:GetBoneCount() do
					local bonename = vm:GetBoneName(i)
					if self.ViewModelBoneMods[bonename] then
						allbones[bonename] = self.ViewModelBoneMods[bonename]
					else
						allbones[bonename] = {
							scale = Vector(1,1,1),
							pos = Vector(0,0,0),
							angle = Angle(0,0,0)
						}
					end
				end

				loopthrough = allbones
			end
			-- !! ----------- !! --

			for k, v in pairs(loopthrough) do
				local bone = vm:LookupBone(k)
				if not bone then continue end

				-- !! WORKAROUND !! --
				local s = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p = Vector(v.pos.x,v.pos.y,v.pos.z)
				local ms = Vector(1,1,1)
				if not hasGarryFixedBoneScalingYet then
					local cur = vm:GetBoneParent(bone)
					while cur >= 0 do
						local pscale = loopthrough[vm:GetBoneName(cur)].scale
						ms = ms * pscale
						cur = vm:GetBoneParent(cur)
					end
				end

				s = s * ms
				-- !! ----------- !! --

				if vm:GetManipulateBoneScale(bone)   ~= s then
					vm:ManipulateBoneScale(bone, s)
				end
				if vm:GetManipulateBoneAngles(bone)   ~= v.angle then
					vm:ManipulateBoneAngles(bone, v.angle)
				end
				if vm:GetManipulateBonePosition(bone)   ~= p then
					vm:ManipulateBonePosition(bone, p)
				end
			end
		else
			self:ResetBonePositions(vm)
		end

	end

	function SWEP:ResetBonePositions(vm)

		if not vm:GetBoneCount() then return end
		for i = 0, vm:GetBoneCount() do
			vm:ManipulateBoneScale(i, Vector(1, 1, 1))
			vm:ManipulateBoneAngles(i, Angle(0, 0, 0))
			vm:ManipulateBonePosition(i, Vector(0, 0, 0))
		end

	end


	function table.FullCopy(tab)

		if not tab then return nil end

		local res = {}
		for k, v in pairs(tab) do
			if type(v) == "table" then
				res[k] = table.FullCopy(v)
			elseif  type(v) == "Vector" then
				res[k] = Vector(v.x, v.y, v.z)
			elseif  type(v) == "Angle" then
				res[k] = Angle(v.p, v.y, v.r)
			else
				res[k] = v
			end
		end

		return res

	end

end
----------------------------------------------------


function SWEP:Deploy()
	self:SetWeaponHoldType(self.HoldType)
	self:SendWeaponAnim(ACT_VM_DRAW)
	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)
	self.Idle = 0
	self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()
	return true
end

function SWEP:Holster()
	self.Idle = 0
	self.IdleTimer = CurTime()
	return true
end

function SWEP:PrimaryAttack()
	if self.CurrentHit == 1 then
		self.CurrentHit = 0
		return
	end
	self.Owner:LagCompensation(true)

	local tr = util.TraceLine({
	start = self.Owner:GetShootPos(),
	endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 84,
	filter = self.Owner,
	mask = MASK_SHOT_HULL,
	})

	if not IsValid(tr.Entity) then
		tr = util.TraceHull({
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 84,
		filter = self.Owner,
		mins = Vector(-16, -16, 0),
		maxs = Vector(16, 16, 0),
		mask = MASK_SHOT_HULL,
		})
	end

	if SERVER and IsValid(tr.Entity) then
		local dmginfo = DamageInfo()
		dmginfo:SetAttacker(self.Owner)
		dmginfo:SetInflictor(self)
		dmginfo:SetDamage(self.Primary.Damage)
		dmginfo:SetDamageType(DMG_SLASH)
		dmginfo:SetDamagePosition(tr.HitPos)
		dmginfo:SetDamageForce(self.Owner:GetAimVector() * self.Primary.Force)
		if tr.Entity:GetClass():find("zombi") then
			dmginfo:SetDamageType(5)
		end

		if tr.Entity:Health() ~= nil and tr.Entity:Health() ~= 0 then
			local dam = self.Primary.Damage + tr.Entity:Health() / 4

			if tr.HitGroup == HITGROUP_HEAD then
				dam = dam * 3
			elseif tr.HitGroup == HITGROUP_CHEST or tr.HitGroup == HITGROUP_STOMACH then
				dam = dam
			else
				dam = dam / 2
			end

			dmginfo:SetDamage(dam)
		end

		SuppressHostEvents(NULL)
		tr.Entity:TakeDamageInfo(dmginfo)
		SuppressHostEvents(self.Owner)
		self.CurrentHit = self.CurrentHit + 1
	end

	if tr.Hit then
		if tr.Entity:IsPlayer() or tr.Entity:IsNPC() or tr.Entity.Type == "nextbot" or tr.Entity:GetClass() == "prop_ragdoll" then
			if SERVER then
				self.Owner:EmitSound("weapons/samurai/tf_katana_slice_0" .. math.random(1, 3) .. ".wav")
				self.Owner:EmitSound("phx/epicmetal_hard" .. math.random(1, 7) .. ".wav")
			end
			local BLOOOD = EffectData()
			BLOOOD:SetOrigin(tr.HitPos)
			BLOOOD:SetMagnitude(math.random(1,3))
			BLOOOD:SetEntity(tr.Entity)
			util.Effect("bloodstream",BLOOOD)
		else
			if SERVER then
				self.Owner:EmitSound("weapons/samurai/tf_katana_impact_object_0" .. math.random(1, 3) .. ".wav")
			end
			local effectdata = EffectData()
			effectdata:SetOrigin(tr.HitPos)
			effectdata:SetNormal(tr.HitNormal)
			effectdata:SetMagnitude(1)
			effectdata:SetScale(2)
			effectdata:SetRadius(1)
			util.Effect("Sparks",effectdata)
		end
		self.Owner:ViewPunch(Angle(-1,-1,0))
		self:SendWeaponAnim(ACT_VM_HITCENTER)
		self:SetNextPrimaryFire(CurTime() + self.Primary.DelayHit)
		self:SetNextSecondaryFire(CurTime() + self.Primary.DelayHit)
	else
		self.Owner:ViewPunch(Angle(1,1,0))
		self:EmitSound("Myrtenaster/RapierSlash.wav", 75, math.Rand(90, 110), 1, CHAN_WEAPON)
		self:SendWeaponAnim(ACT_VM_MISSCENTER)
		self:SetNextPrimaryFire(CurTime() + self.Primary.DelayMiss)
		self:SetNextSecondaryFire(CurTime() + self.Primary.DelayMiss)
	end

	self.Owner:SetAnimation(PLAYER_ATTACK1)
	self.Idle = 0
	self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()

	self.Owner:LagCompensation(false)
	timer.Create("MyrtenasterDoubleHit" .. self:EntIndex(), 0.2, 1, function()
		if IsValid(self) and IsFirstTimePredicted() then
			self:SetNextSecondaryFire(CurTime())
			self:SetNextPrimaryFire(CurTime())
			self:PrimaryAttack()
			if tr.Hit then
				self:SetNextSecondaryFire(CurTime() + self.Primary.DelayHit)
				self:SetNextPrimaryFire(CurTime() + self.Primary.DelayHit)
			else
				self:SetNextSecondaryFire(CurTime() + self.Primary.DelayMiss)
				self:SetNextPrimaryFire(CurTime() + self.Primary.DelayMiss)
			end
			self.CurrentHit = 1
		end
	end)
end

function SWEP:SecondaryAttack()
	if SERVER then
		if self.ActiveDust == "Ice" then
			if not self.Owner:IsOnGround() then return end
			self:EmitSound("Myrtenaster/IceSpikes.wav", 75, 100, 0.5, CHAN_AUTO)
			timer.Create("MyrtenasterIceSpike" .. self:EntIndex(), 0.5, 1, function()
				local spike_line = ents.Create("rwby_icespike_line")
				spike_line:SetPos(self.Owner:GetPos() + (self.Owner:GetAimVector() * Vector(1,1,0)):GetNormalized() * 128)
				spike_line:SetAngles(self.Owner:GetAngles())
				spike_line:SetOwner(self.Owner)
				spike_line.direction = (self.Owner:GetAimVector() * Vector(1,1,0)):GetNormalized()
				spike_line:Spawn()
			end)
		end
	end
	self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
end

function SWEP:Think()
	if self.Idle == 0 and self.IdleTimer <= CurTime() then
		if SERVER then
			self:SendWeaponAnim(ACT_VM_IDLE)
		end
		self.Idle = 1
	end
end

local DustWheel = Material("vgui/Myrtenaster/DustWheel.png")
local DustChamber = Material("vgui/Myrtenaster/DustChamber.png")
local FireDust = Material("vgui/Myrtenaster/FireDust.png")
local IceDust = Material("vgui/Myrtenaster/IceDust.png")
local LightningDust = Material("vgui/Myrtenaster/LightningDust.png")
local GravityDust = Material("vgui/Myrtenaster/GravityDust.png")

local DustTbl = {
	["Fire"] = FireDust,
	["Ice"] = IceDust,
	["Lightning"] = LightningDust,
	["Gravity"] = GravityDust
}

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function smoothstep(a, b, t, pow)
	t = math.Clamp(t, 0, 1)
	t = t ^ pow / (t ^ pow + (1 - t) ^ pow)
	return lerp(a, b, t)
end

net.Receive("RWBY_Myrtenaster_Switch_Dust", function(len, ply)
	local wep = ply:GetActiveWeapon()
	local dust = net.ReadString()
	if IsValid(wep) and wep:GetClass() == "weapon_myrtenaster" then
		wep.ActiveDust = dust
	end
end)

function SWEP:DrawHUD()
	if LocalPlayer():KeyDown(IN_RELOAD) and not LocalPlayer():KeyDownLast(IN_RELOAD) and self.DustAnimTime == 1 then
		self:EmitSound("Myrtenaster/DustSwitch.wav", 75, 90, 0.1, CHAN_WEAPON)
		self.DustAnimTime = 0
	end

	local inc = FrameTime() * 1.5
	self.DustAnimTime = self.DustAnimTime + inc
	self.DustAnimTime = math.min(self.DustAnimTime, 1)

	self.FadeTime = self.FadeTime or 1

	surface.SetMaterial(DustWheel)
	surface.SetDrawColor(200, 200, 200, 100)
	local dust_ang = smoothstep(0, -360, self.DustAnimTime, 3)
	surface.DrawTexturedRectRotated(ScrW() * 0.5, ScrH(), 360, 360, dust_ang) -- Dust Wheel

	if self.DustAnimTime >= 0.5 and self.DustAnimTime - inc < 0.5 then
		local keys = table.GetKeys(DustTbl)
		self.ActiveDust = keys[(table.KeyFromValue(keys, self.ActiveDust) % #keys) + 1]
		net.Start("RWBY_Myrtenaster_Switch_Dust")
		net.WriteString(self.ActiveDust)
		net.SendToServer()
	end

	if self.DustAnimTime >= 0.95 and self.DustAnimTime - inc < 0.95 then
		self.FadeTime = 1
	end

	if self.DustAnimTime >= 1 then
		self.FadeTime = self.FadeTime - inc * 0.5
	end

	local dust_pos = Vector(0, -123, 0)
	local wheel_ang = Angle(0, -dust_ang, 0)
	dust_pos:Rotate(wheel_ang)
	dust_pos = dust_pos + Vector(ScrW() * 0.5, ScrH(), 0)
	draw.DrawText(self.ActiveDust, "DermaLarge", ScrW() * 0.5, ScrH() - 224, Color(255, 255, 255, smoothstep(0, 255, self.FadeTime, 2)), TEXT_ALIGN_CENTER) -- Dust Name

	for i = 0, 13 do -- draw glow
		surface.SetDrawColor(255, 255, 255, 8 * (13 - i) / 13)
		surface.DrawTexturedRectRotated(dust_pos.x, dust_pos.y, 90 + i, 90 + i, -wheel_ang.y) -- Dust Icon
	end

	surface.SetDrawColor(0, 0, 0, 150)

	surface.SetMaterial(DustChamber)
	surface.DrawTexturedRectRotated(dust_pos.x, dust_pos.y, 105, 105, -wheel_ang.y) -- Dust Icon

	surface.SetDrawColor(255, 255, 255, 255)

	surface.SetMaterial(DustTbl[self.ActiveDust])
	surface.DrawTexturedRectRotated(dust_pos.x, dust_pos.y, 90, 90, -wheel_ang.y) -- Dust Icon
end