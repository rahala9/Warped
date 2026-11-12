-- StarterPlayerScripts/SharedClientScripts/ImageLabelAnimator (ModuleScript)

local ImageLabelAnimator = {}
ImageLabelAnimator.__index = ImageLabelAnimator

function ImageLabelAnimator.new(label: ImageLabel, cfg)
	assert(label and label:IsA("ImageLabel"), "ImageLabelAnimator.new: label must be ImageLabel")
	assert(cfg and cfg.Image and cfg.FrameSize and cfg.Columns and cfg.Rows and cfg.FPS, "ImageLabelAnimator.new: bad cfg")

	local self = setmetatable({}, ImageLabelAnimator)
	self._label = label
	self._cfg = cfg
	self._total = cfg.Columns * cfg.Rows
	self._token = 0
	self._frame = cfg.StartFrame or 0

	label.Image = cfg.Image
	label.ImageRectSize = cfg.FrameSize
	label.ImageRectOffset = Vector2.new(0, 0)

	return self
end

function ImageLabelAnimator:GetTotalFrames()
	return self._total
end

function ImageLabelAnimator:GetFrame()
	return self._frame
end

function ImageLabelAnimator:SetFrame(frameIndex: number)
	local f = math.clamp(frameIndex, 0, self._total - 1)
	self._frame = f
	local col = f % self._cfg.Columns
	local row = math.floor(f / self._cfg.Columns)
	self._label.ImageRectOffset = Vector2.new(col * self._cfg.FrameSize.X, row * self._cfg.FrameSize.Y)
end

function ImageLabelAnimator:Cancel()
	self._token += 1
end

function ImageLabelAnimator:PlayForward(opts)
	opts = opts or {}
	self._token += 1
	local t = self._token

	task.spawn(function()
		local f = self._frame
		while self._token == t do
			self:SetFrame(f)
			f += 1

			if f >= self._total then
				if opts.loop then
					f = 0
				else
					self:SetFrame(self._total - 1)
					if opts.onFinished then opts.onFinished() end
					return
				end
			end
			task.wait(1 / self._cfg.FPS)
		end
	end)
end

function ImageLabelAnimator:PlayReverse(opts)
	opts = opts or {}
	self._token += 1
	local t = self._token

	task.spawn(function()
		local start = opts.fromFrame
		if start == nil then start = self._frame end
		start = math.clamp(start, 0, self._total - 1)

		for f = start, 0, -1 do
			if self._token ~= t then return end
			self:SetFrame(f)
			task.wait(1 / self._cfg.FPS)
		end

		if self._token ~= t then return end
		self:SetFrame(0)
		if opts.onFinished then opts.onFinished() end
	end)
end

return ImageLabelAnimator
