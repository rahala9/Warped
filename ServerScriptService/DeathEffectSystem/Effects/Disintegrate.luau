local Disintegrate = {}

function Disintegrate.BuildPayload(_player: Player, _character: Model, context)
	return {
		Source = context.Source,
		DamageType = context.DamageType,
		WeaponName = context.WeaponName,
	}
end

return Disintegrate
