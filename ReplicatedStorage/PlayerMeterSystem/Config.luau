local Config = {
	UpdateInterval = 0.25,

	Meters = {
		Biohazard = {
			CurrentAttribute = "Biohazard",
			MaximumAttribute = "MaxBiohazard",
			Default = 0,
			Maximum = 100,
			-- Exposure clears slowly when no effect is adding to it.
			BaseRatePerSecond = -0.1,

			UI = {
				Name = "BiohazardBar",
				-- Fill the green-symbol status slot without spilling into adjacent rows.
				Position = UDim2.new(0, 79, 1, -43),
				Size = UDim2.fromOffset(117, 18),
				ZIndex = 98,
				FillColor = Color3.fromRGB(155, 205, 25),
				GradientDark = Color3.fromRGB(50, 75, 5),
				GradientBright = Color3.fromRGB(205, 245, 45),
				TextColor = Color3.fromRGB(245, 255, 220),
				TextStrokeColor = Color3.fromRGB(20, 35, 0),
			},
		},
	},
}

return Config
