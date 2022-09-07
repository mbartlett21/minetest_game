function core.override_entity(name, redefinition)
	if redefinition.name ~= nil then
		error("Attempt to redefine name of entity " .. name .. " to " .. dump(redefinition.name), 2)
	end
	local entity = core.registered_entities[name]
	if not entity then
		error("Attempt to override non-existent entity " .. name, 2)
	end
	for k, v in pairs(redefinition) do
		rawset(entity, k, v)
	end
end

