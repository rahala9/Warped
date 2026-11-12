-- PartLibrary.lua
local PartLibrary = {}

-- Socket compatibility
PartLibrary.Compatibility = {
	Hull = { Hull = true },
	Panel = { Panel = true },
	Interior = { Interior = true },
	-- add more as needed
}

-- Per-part snap policies
PartLibrary.Parts = {
	FloorPanel1 = {
		PartType = "Floor",
		Size = Vector3.new(4, 1, 4),
		SnapPolicy = {
			Mode = "Socket",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			MaxSnapDistance = 6,
			AllowedRotation = {
				Y = { allow = true, step = 90 },
				X = { allow = false },
				Z = { allow = false },
			},
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	FloorPanel2 = {
		PartType = "Floor",
		Size = Vector3.new(4, 1, 4),
		SnapPolicy = {
			Mode = "Socket",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			MaxSnapDistance = 6,
			AllowedRotation = {
				Y = { allow = true, step = 90 },
				X = { allow = false },
				Z = { allow = false },
			},
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	FloorPanel3 = {
		PartType = "Floor",
		Size = Vector3.new(4, 1, 4),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	FloorPanel4 = {
		PartType = "Floor",
		Size = Vector3.new(4, 1, 4),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	FloorPanel5 = {
		PartType = "Floor",
		Size = Vector3.new(4, 1, 4),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	FloorPanel6 = {
		PartType = "Floor",
		Size = Vector3.new(4, 1, 4),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	FloorPanel7 = {
		PartType = "Floor",
		Size = Vector3.new(4, 1, 4),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	FloorPanel8 = {
		PartType = "Floor",
		Size = Vector3.new(4, 1, 4),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	FloorPanel9 = {
		PartType = "Floor",
		Size = Vector3.new(4, 1, 4),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	FloorPanel10 = {
		PartType = "Floor",
		Size = Vector3.new(4, 1, 4),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	FloorPanel11 = {
		PartType = "Floor",
		Size = Vector3.new(4, 1, 4),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	FloorPanel12 = {
		PartType = "Floor",
		Size = Vector3.new(8, 1, 8),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	FloorPanel13 = {
		PartType = "Floor",
		Size = Vector3.new(4, 1, 4),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	FloorPanel14 = {
		PartType = "Floor",
		Size = Vector3.new(4, 1, 4),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	FloorPanel15 = {
		PartType = "Floor",
		Size = Vector3.new(4, 1, 4),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	FloorPanel16 = {
		PartType = "Floor",
		Size = Vector3.new(4, 1, 4),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(4,1,4),                   -- lock x/z to multiples of 4
			Plane = "Horizontal",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = .5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	WallPanel1 = {
		PartType = "Wall",
		Size = Vector3.new(8, 10, 1),
		SnapPolicy = {
			Mode = "Socket",
			GridSize = Vector3.new(1,10,1),                   -- to align on sides of flooring
			GridPhaseX =0,
			GridPhaseZ =.5,
			Plane = "Vertical",
			NumberConnectionsNeeded = 2,
			RequiredSpan = 8,      -- <== wall must span ~8 studs
			AllowedRotation = {
				Y = { allow = true, step = 90 },
				X = { allow = false },
				Z = { allow = false },
			},
			RotationStepDeg = 90,
			HeightFromDeck = 6,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
			Stacking = {
				Unit = 9,                 -- vertical quantization (studs). For a half-wall: Size.Y
				Gap = 1,                  -- extra gap between rows if you want one
				HoverAssist = true,       -- enable auto-lift when hovering compatible parts
				CompatibleType = "Wall",  -- (optional) only hover-lift when the hit has this Type
			},
		},
	},
	WallPanel2 = {
		PartType = "Wall",
		Size = Vector3.new(8, 10, 1),
		SnapPolicy = {
			Mode = "Socket",
			GridSize = Vector3.new(1,10,1),                   -- to align on sides of flooring
			GridPhaseX =0,
			GridPhaseZ =.5,
			Plane = "Vertical",
			NumberConnectionsNeeded = 2,
			AllowedRotation = {
				Y = { allow = true, step = 90 },
				X = { allow = false },
				Z = { allow = false },
			},
			RotationStepDeg = 90,
			HeightFromDeck = 6,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
			Stacking = {
				Unit = 9,                 -- vertical quantization (studs). For a half-wall: Size.Y
				Gap = 1,                  -- extra gap between rows if you want one
				HoverAssist = true,       -- enable auto-lift when hovering compatible parts
				CompatibleType = "Wall",  -- (optional) only hover-lift when the hit has this Type
			},
		},
	},
	WallPanel3 = {
		PartType = "Wall",
		Size = Vector3.new(8, 10, 1),
		SnapPolicy = {
			Mode = "Socket",
			GridSize = Vector3.new(1,10,1),                   -- to align on sides of flooring
			GridPhaseX =0,
			GridPhaseZ =.5,
			Plane = "Vertical",
			NumberConnectionsNeeded = 2,
			AllowedRotation = {
				Y = { allow = true, step = 90 },
				X = { allow = false },
				Z = { allow = false },
			},
			RotationStepDeg = 90,
			HeightFromDeck = 6,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
			Stacking = {
				Unit = 9,                 -- vertical quantization (studs). For a half-wall: Size.Y
				Gap = 1,                  -- extra gap between rows if you want one
				HoverAssist = true,       -- enable auto-lift when hovering compatible parts
				CompatibleType = "Wall",  -- (optional) only hover-lift when the hit has this Type
			},
		},
	},
	WallPanel4 = {
		PartType = "Wall",
		Size = Vector3.new(8, 10, 1),
		SnapPolicy = {
			Mode = "Socket",
			GridSize = Vector3.new(1,10,1),                   -- to align on sides of flooring
			GridPhaseX =0,
			GridPhaseZ =.5,
			Plane = "Vertical",
			NumberConnectionsNeeded = 2,
			AllowedRotation = {
				Y = { allow = true, step = 90 },
				X = { allow = false },
				Z = { allow = false },
			},
			RotationStepDeg = 90,
			HeightFromDeck = 6,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
			Stacking = {
				Unit = 9,                 -- vertical quantization (studs). For a half-wall: Size.Y
				Gap = 1,                  -- extra gap between rows if you want one
				HoverAssist = true,       -- enable auto-lift when hovering compatible parts
				CompatibleType = "Wall",  -- (optional) only hover-lift when the hit has this Type
			},
		},
	},
	WallPanel5 = {
		PartType = "Wall",
		Size = Vector3.new(8, 10, 1),
		SnapPolicy = {
			Mode = "Socket",
			GridSize = Vector3.new(1,10,1),                   -- to align on sides of flooring
			GridPhaseX =0,
			GridPhaseZ =.5,
			Plane = "Vertical",
			NumberConnectionsNeeded = 2,
			AllowedRotation = {
				Y = { allow = true, step = 90 },
				X = { allow = false },
				Z = { allow = false },
			},
			RotationStepDeg = 90,
			HeightFromDeck = 6,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
			Stacking = {
				Unit = 9,                 -- vertical quantization (studs). For a half-wall: Size.Y
				Gap = 1,                  -- extra gap between rows if you want one
				HoverAssist = true,       -- enable auto-lift when hovering compatible parts
				CompatibleType = "Wall",  -- (optional) only hover-lift when the hit has this Type
			},
		},
	},
	WallPanel6 = {
		PartType = "Wall",
		Size = Vector3.new(8, 10, 1),
		SnapPolicy = {
			Mode = "Socket",
			GridSize = Vector3.new(1,10,1),                   -- to align on sides of flooring
			GridPhaseX =0,
			GridPhaseZ =.5,
			Plane = "Vertical",
			NumberConnectionsNeeded = 2,
			AllowedRotation = {
				Y = { allow = true, step = 90 },
				X = { allow = false },
				Z = { allow = false },
			},
			RotationStepDeg = 90,
			HeightFromDeck = 6,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
			Stacking = {
				Unit = 9,                 -- vertical quantization (studs). For a half-wall: Size.Y
				Gap = 1,                  -- extra gap between rows if you want one
				HoverAssist = true,       -- enable auto-lift when hovering compatible parts
				CompatibleType = "Wall",  -- (optional) only hover-lift when the hit has this Type
			},
		},
	},
	WallPanel7 = {
		PartType = "Wall",
		Size = Vector3.new(4, 4, 1),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(4,4,1),                   -- to align on sides of flooring
			GridPhaseX =0,
			GridPhaseZ =.5,
			Plane = "Vertical",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = 3,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	WallAttachment1 = {
		PartType = "WallAttachment",
		Size = Vector3.new(2, 10, 2),
		SnapPolicy = {
			Mode = "Socket",
			GridSize = Vector3.new(2,10,2),                   -- to align on sides of flooring
			GridPhaseX =-1,
			GridPhaseZ = 0,
			Plane = "Vertical",
			AllowedRotation = {
				Y = { allow = true, step = 90 },
				X = { allow = false },
				Z = { allow = false },
			},
			RotationStepDeg = 90,
			HeightFromDeck = 6,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
			Stacking = {
				Unit = 9,                 -- vertical quantization (studs). For a half-wall: Size.Y
				Gap = 1,                  -- extra gap between rows if you want one
				HoverAssist = true,       -- enable auto-lift when hovering compatible parts
				CompatibleType = "Wall",  -- (optional) only hover-lift when the hit has this Type
			},
		},
	},
	WallAttachment2 = {
		PartType = "WallAttachment",
		Size = Vector3.new(2, 10, 3),
		SnapPolicy = {
			Mode = "Socket",
			GridSize = Vector3.new(2,10,1),                   -- to align on sides of flooring
			GridPhaseX =-1,
			GridPhaseZ = 1.5,
			Plane = "Vertical",
			MaxSnapDistance = 1,
			AllowedRotation = {
				Y = { allow = true, step = 90 },
				X = { allow = false },
				Z = { allow = false },
			},
			RotationStepDeg = 90,
			HeightFromDeck = 6,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
			Stacking = {
				Unit = 9,                 -- vertical quantization (studs). For a half-wall: Size.Y
				Gap = 1,                  -- extra gap between rows if you want one
				HoverAssist = true,       -- enable auto-lift when hovering compatible parts
				CompatibleType = "Wall",  -- (optional) only hover-lift when the hit has this Type
			},
		},
	},
	ExteriorPanel1 = {
		PartType = "ExteriorPanel",
		Size = Vector3.new(1, 4, 8),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(1,4,8),                   -- to align on sides of flooring
			Plane = "Vertical",
			AllowedRotation = {
				-- Yaw (around Y)
				Y = {
					allow = true,
					step = 15,       -- degrees per tap
					default = 0,     -- baked-in default yaw
					key = "R",       -- optional: which key increments it
				},
				-- Roll (around Z)
				Z = {
					allow = true,
					step = 15,
					default = 0,
					key = "T",
				},
				-- Pitch (around X) — optional
				X = {
					allow = false,   -- off by default
					step = 15,
					default = 0,
					key = "G",
				},
			},
			RotationStepDeg = 45,
			HeightFromDeck = 3,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
		Stacking = {
			Unit = 4,                 -- vertical quantization (studs). For a half-wall: Size.Y
			Gap = 0,                  -- extra gap between rows if you want one
			HoverAssist = true,       -- enable auto-lift when hovering compatible parts
			CompatibleType = "ExteriorPanel",  -- (optional) only hover-lift when the hit has this Type
		},
	},
	
	ControlRoom1 = {
		PartType = "Floor",
		Size = Vector3.new(12, 10, 8),
		SnapPolicy = {
			Mode = "Grid",
			GridSize = Vector3.new(1, 1, 1),                   -- to align on sides of flooring
			Plane = "Vertical",
			AllowedRotation = { Yaw = true },
			RotationStepDeg = 90,
			HeightFromDeck = 5,             -- sits on deck
			DeckRef = "MainDeck",              -- optional; if not found, ship root used
		},
	},
	--HullPanel1 = {
	--	PartType = "HullPanel",
	--	Size = Vector3.new(1, 8, 8),
	--	SnapPolicy = {
	--		Mode = "Socket",
	--		AllowedRotation = { Yaw = true, Pitch = true, Roll = false },
	--		RotationStepDeg = 90,
	--		AnchorNormalTo = "TargetNormal",           -- panel outward aligns to socket normal
	--		OrientationModes = {"Horizontal","Vertical"},
	--		DefaultOrientation = "Horizontal",
	--		MountAttachmentName = "Mount",
	--		TargetSocketType = "Hull",                 -- target must be a Hull socket
	--	},
	--},
	--InteriorWallSide = {
	--	PartType = "InteriorWallSide",
	--	Size = Vector3.new(4, 2, 0.5),
	--	SnapPolicy = {
	--		Mode = "Socket",
	--		AllowedRotation = { Yaw = true },
	--		RotationStepDeg = 90,
	--		MountAttachmentName = "Mount",
	--		TargetSocketType = "Panel",                -- mount to a panel edge/socket
	--		FaceOppositeOfTargetLook = true,           -- must face opposite of panel outward
	--		UseTargetOutwardAttachment = "Outward",
	--	},
	--},
}

return PartLibrary

