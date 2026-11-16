local Electrocuted = {}

function Electrocuted.BuildPayload(_player: Player, _character: Model, context)
	return {
		Source = context.Source,
		SourceType = context.SourceType,
		DamageType = context.DamageType,
		WeaponName = context.WeaponName,
	}
end

return Electrocuted
