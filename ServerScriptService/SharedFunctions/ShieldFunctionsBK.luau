-----------------------------------------------------------------------
---- ShieldPatchPlacement.lua (server or shared)
---- 1) PlacePatchOnDome: align a separated shield patch model to a dome hit (using PatchCenter attachment)
---- 2) ShieldRipple: smooth transparency ripple across Center -> ring2 -> ring3 (named parts)
-----------------------------------------------------------------------

--local TweenService = game:GetService("TweenService")

--local ShieldPatchPlacement = {}

-----------------------------------------------------------------------
---- Patch placement (your existing helpers, hardened)
-----------------------------------------------------------------------

--local function CFrameFromNormal(pos: Vector3, normal: Vector3)
--	local n = normal.Unit
--	local up = Vector3.yAxis
--	if math.abs(n:Dot(up)) > 0.98 then
--		up = Vector3.xAxis
--	end

--	local right = up:Cross(n).Unit
--	local trueUp = n:Cross(right).Unit

--	-- X = right, Y = trueUp, Z = normal/out
--	return CFrame.fromMatrix(pos, right, trueUp, n)
--end

--local function FindPatchCenterAttachment(patchModel: Model): Attachment?
--	-- Prefer PatchCenter anywhere under patchModel; if you specifically keep it under patchModel.Center, it still works.
--	for _, d in ipairs(patchModel:GetDescendants()) do
--		if d:IsA("Attachment") and d.Name == "PatchCenter" then
--			return d
--		end
--	end
--	return nil
--end

---- Aligns PatchCenter (in the patch model) to the hit point + normal.
---- If PatchCenter’s own axis is not +Z = "out", use patchFaceCorrection to rotate it.
--local function PlacePatchOnDome(hitbox: BasePart, patchModel: Model, hitPos: Vector3, hitNormal: Vector3, patchFaceCorrection: CFrame?)
--	patchFaceCorrection = patchFaceCorrection or CFrame.identity

--	local patchCenter = FindPatchCenterAttachment(patchModel)
--	if not patchCenter then
--		warn("PlacePatchOnDome: PatchCenter attachment not found in patchModel:", patchModel:GetFullName())
--		return
--	end

--	-- 1) Desired PatchCenter world-space (pos + orientation), slight push out to avoid z-fight
--	local cfHit = CFrameFromNormal(hitPos + hitNormal.Unit * 0.4, hitNormal.Unit) * patchFaceCorrection

--	-- 2) PatchCenter current world-space
--	local cfCenterNow = patchCenter.WorldCFrame

--	-- 3) Compute center->pivot offset in current space, then apply to desired
--	local pivotNow = patchModel:GetPivot()
--	local centerToPivot = cfCenterNow:Inverse() * pivotNow
--	local newPivot = cfHit * centerToPivot

--	patchModel:PivotTo(newPivot)
--end

--ShieldPatchPlacement.CFrameFromNormal = CFrameFromNormal
--ShieldPatchPlacement.FindPatchCenterAttachment = FindPatchCenterAttachment
--ShieldPatchPlacement.PlacePatchOnDome = PlacePatchOnDome

-----------------------------------------------------------------------
---- ShieldRipple (smooth transparency ripple across rings)
---- Naming assumption:
----   Center piece is named "Center"
----   Ring2 pieces named "2","3","4","5","6","7"
----   Ring3 pieces named "8".."19"
---- Works if these are BaseParts (MeshPart/Part/Union) anywhere under the shield model.
-----------------------------------------------------------------------

--local function toNameSet(nums: {number})
--	local set = {}
--	for _, v in ipairs(nums) do
--		set[tostring(v)] = true
--	end
--	return set
--end

--local RING_2 = toNameSet({2,3,4,5,6,7})
--local RING_3 = toNameSet({8,9,10,11,12,13,14,15,16,17,18,19})

---- Track active tweens per-part (weak keys so garbage collection is safe)
--local activeTweenByPart = setmetatable({}, { __mode = "k" })

--local function cancelTween(p: BasePart)
--	local tw = activeTweenByPart[p]
--	if tw then
--		tw:Cancel()
--		activeTweenByPart[p] = nil
--	end
--end

--local function playTween(parts: {BasePart}, ti: TweenInfo, props)
--	for _, p in ipairs(parts) do
--		if p and p.Parent then
--			cancelTween(p)
--			local tw = TweenService:Create(p, ti, props)
--			activeTweenByPart[p] = tw
--			tw:Play()
--		end
--	end
--end

--local function collectRings(model: Model)
--	local rings = {
--		center = {},
--		ring2 = {},
--		ring3 = {},
--	}

--	for _, inst in ipairs(model:GetDescendants()) do
--		if inst:IsA("BasePart") then
--			-- store original transparency once (so we can return to it)
--			if inst:GetAttribute("ShieldOrigTransparency") == nil then
--				inst:SetAttribute("ShieldOrigTransparency", inst.Transparency)
--			end

--			local n = inst.Name
--			if n == "Center" then
--				table.insert(rings.center, inst)
--			elseif RING_2[n] then
--				table.insert(rings.ring2, inst)
--			elseif RING_3[n] then
--				table.insert(rings.ring3, inst)
--			end
--		end
--	end

--	return rings
--end

--local ShieldRipple = {}
--ShieldRipple.__index = ShieldRipple

--export type RippleConfig = {
--	model: Model,
--	visibleTransparency: number?, -- default 0
--	hiddenTransparency: number?,  -- optional; if nil, returns to per-part original
--	ringDelay: number?,           -- default 0.06
--	fadeInTime: number?,          -- default 0.10
--	holdTime: number?,            -- default 0.06
--	fadeOutTime: number?,         -- default 0.18
--	betweenFadeTime: number?,     -- default 0.5
--	easingStyle: Enum.EasingStyle?,
--	easingDirection: Enum.EasingDirection?,
--}

--function ShieldRipple.new(cfg: RippleConfig)
--	assert(cfg and cfg.model, "ShieldRipple.new requires cfg.model")

--	local self = setmetatable({}, ShieldRipple)
--	self.model = cfg.model

--	self.visibleTransparency = cfg.visibleTransparency or 0
--	self.hiddenTransparency  = cfg.hiddenTransparency -- nil => revert to ShieldOrigTransparency

--	self.ringDelay  = cfg.ringDelay  or 0.06
--	self.fadeInTime = cfg.fadeInTime or 0.10
--	self.holdTime   = cfg.holdTime   or 0.06
--	self.fadeOutTime= cfg.fadeOutTime or 0.18
--	self.betweenFadeTime = cfg.betweenFadeTime or .5

--	self.easingStyle = cfg.easingStyle or Enum.EasingStyle.Quad
--	self.easingDirection = cfg.easingDirection or Enum.EasingDirection.Out

--	self.rings = collectRings(self.model)
--	self._token = 0

--	return self
--end

--function ShieldRipple:_hiddenForPart(p: BasePart): number
--	if self.hiddenTransparency ~= nil then
--		return self.hiddenTransparency
--	end
--	local orig = p:GetAttribute("ShieldOrigTransparency")
--	if typeof(orig) == "number" then
--		return orig
--	end
--	return 1
--end

--function ShieldRipple:Rip()
--	self._token += 1
--	local token = self._token

--	local tiIn  = TweenInfo.new(self.fadeInTime, self.easingStyle, self.easingDirection)
--	local tiOut = TweenInfo.new(self.fadeOutTime, self.easingStyle, Enum.EasingDirection.In)

--	-- mode controls which phases run:
--	--   "in"   => fade in only (no hold/out)
--	--   "out"  => fade out only
--	--   "both" => fade in, hold, fade out
--	local function ringPulse(parts: {BasePart}, mode: "in" | "out" | "both")
--		if token ~= self._token then return end

--		-- FADE IN
--		if mode == "in" or mode == "both" then
--			playTween(parts, tiIn, { Transparency = self.visibleTransparency })
--			if token ~= self._token then return end
--		end

--		-- HOLD only if doing both
--		if mode == "both" then
--			task.wait(self.holdTime)
--			if token ~= self._token then return end
--		end

--		-- FADE OUT
--		if mode == "out" or mode == "both" then
--			-- fade out (per-part hidden/original)
--			for _, p in ipairs(parts) do
--				if p and p.Parent then
--					cancelTween(p)
--					local target = self:_hiddenForPart(p)
--					local tw = TweenService:Create(p, tiOut, { Transparency = target })
--					activeTweenByPart[p] = tw
--					tw:Play()
--				end
--			end
--		end
--	end


--	task.spawn(function()
--		--Initially set on invisible
--		for _, p in ipairs(self.model:GetChildren()) do
--			if p and p.Parent then
--				p.Transparency = 1
--			end
--		end
		
--		ringPulse(self.rings.center,"in")
--		task.wait(self.ringDelay)
--		if token ~= self._token then return end

--		ringPulse(self.rings.ring2,"in")
--		task.wait(self.ringDelay)
--		if token ~= self._token then return end

--		ringPulse(self.rings.ring3,"in")
		
--		task.wait(self.betweenFadeTime)
--		ringPulse(self.rings.ring3,"out")
--		task.wait(self.ringDelay)
--		ringPulse(self.rings.ring2,"out")
--		task.wait(self.ringDelay)
--		ringPulse(self.rings.center,"out")
		
--	end)
--end

--function ShieldRipple:StopAndHide()
--	self._token += 1

--	for _, group in pairs(self.rings) do
--		for _, p in ipairs(group) do
--			if p and p.Parent then
--				cancelTween(p)
--				p.Transparency = self:_hiddenForPart(p)
--			end
--		end
--	end
--end

---- Expose on module
--ShieldPatchPlacement.ShieldRipple = ShieldRipple

-----------------------------------------------------------------------
---- Convenience helpers (optional)
-----------------------------------------------------------------------

---- One-liner usage without constructing an object:
---- ShieldPatchPlacement.RippleOnce(shieldModel, { ... })
--function ShieldPatchPlacement.RippleOnce(shieldModel: Model, cfg: RippleConfig?)
--	cfg = cfg or {}
--	cfg.model = shieldModel
--	local r = ShieldRipple.new(cfg)
--	r:Rip()
--	return r -- returned so you can reuse it (recommended)
--end

--return ShieldPatchPlacement
