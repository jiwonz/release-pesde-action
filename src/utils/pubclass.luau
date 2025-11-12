type function ExportClassTypeFn(classIdKey: type, rootClass: type): type
	assert(classIdKey:is("singleton"), "ClassIdKey must be a valid singleton")
	if not rootClass:is("table") then
		return rootClass
	end

	local hasClassId = rootClass:readproperty(classIdKey)
	assert(hasClassId, "missing ClassId field")

	-- selene: allow(shadowing)
	local mt = rootClass:metatable()
	assert(mt, "class must have a metatable")

	-- For class type itself - no fields
	local publicType = types.newtable(nil, nil, nil)

	-- For instances - collect public properties
	local instanceProps: { [type]: { read: type?, write: type? } } = {}
	for prop, val in rootClass:properties() do
		if prop:is("singleton") then
			local propName = prop:value()
			if type(propName) == "string" then
				-- Remove all _ prefixed fields (including __do_not_use_this_field_ClassId)
				if propName:sub(1, 1) ~= "_" then
					instanceProps[prop] = val
				end
			end
		end
	end

	-- Store instance type for new() method
	local instanceType = types.newtable(instanceProps :: any, nil, nil)

	-- Collect public methods from __index (excluding _ prefixed methods)
	local indexTbl = mt:readproperty(types.singleton("__index"))
	assert(indexTbl and indexTbl:is("table"), "metatable must have __index table")

	local publicMethods: { [type]: { read: type?, write: type? } } = {}
	for prop, val in indexTbl:properties() do
		if prop:is("singleton") then
			local propName = prop:value()
			if type(propName) == "string" and propName:sub(1, 1) ~= "_" then
				-- Process method to replace parameter and return types
				local funcVal = val.read or val.write
				if funcVal and funcVal:is("function") then
					-- Replace parameter types (especially self parameter)
					local params = funcVal:parameters()
					if params.head then
						local newParams = {}
						for i, paramType in params.head do
							-- If parameter is the original class type, replace with public type
							if paramType:is("table") and paramType:readproperty(classIdKey) then
								newParams[i] = publicType
							else
								newParams[i] = paramType
							end
						end
						funcVal:setparameters(newParams, params.tail)
					end

					-- Replace return types
					local returns = funcVal:returns()
					if returns.head then
						local newReturns = {}
						for i, returnType in returns.head do
							-- If return is the original class type, replace with instance type
							if returnType:is("table") and returnType:readproperty(classIdKey) then
								newReturns[i] = instanceType -- Use instance type for new()/parse() return
							else
								newReturns[i] = returnType
							end
						end
						funcVal:setreturns(newReturns, returns.tail)
					end
				end
				publicMethods[prop] = val
			end
		else
			publicMethods[prop] = val
		end
	end

	-- Create new __index table with only public methods
	local newIndexTbl = types.newtable(publicMethods :: any, nil, nil)

	-- Create new metatable with the new __index
	local newMtProps: { [type]: any } = {}
	for prop, val in mt:properties() do
		if prop:is("singleton") and prop:value() == "__index" then
			newMtProps[prop] = { read = newIndexTbl }
		else
			newMtProps[prop] = val
		end
	end
	local newMt = types.newtable(newMtProps :: any, nil, nil)

	-- Set metatable for both types
	publicType:setmetatable(newMt)
	instanceType:setmetatable(newMt)

	-- publicType is the class type (no fields)
	-- methods will return instanceType (with public fields)
	return publicType
end

type function UUID(): type
	local function uuid(): string
		local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
		local s = string.gsub(template, "[xy]", function(c)
			local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
			return string.format("%x", v)
		end)
		return s
	end
	return types.singleton(uuid())
end

type function WithClassIdTypeFn(classIdKey: type, tbl: type): type
	assert(classIdKey:is("singleton"), "ClassIdKey must be a valid singleton")
	assert(tbl:is("table"), "WithClassId can only be applied to table types")
	tbl:setreadproperty(classIdKey, types.singleton(nil))
	return tbl
end

type function ExportInstanceTypeFn(classIdKey: type, rootClass: type): type
	assert(classIdKey:is("singleton"), "ClassIdKey must be a valid singleton")
	if not rootClass:is("table") then
		return rootClass
	end

	local hasClassId = rootClass:readproperty(classIdKey)
	assert(hasClassId, "missing ClassId field")

	-- selene: allow(shadowing)
	local mt = rootClass:metatable()
	assert(mt, "class must have a metatable")

	-- For instances - collect public properties
	local instanceProps: { [type]: { read: type?, write: type? } } = {}
	for prop, val in rootClass:properties() do
		if prop:is("singleton") then
			local propName = prop:value()
			if type(propName) == "string" then
				-- Remove all _ prefixed fields (including __do_not_use_this_field_ClassId)
				if propName:sub(1, 1) ~= "_" then
					instanceProps[prop] = val
				end
			end
		end
	end

	-- Create instance type with public fields
	local instanceType = types.newtable(instanceProps :: any, nil, nil)

	-- Collect public methods from __index (excluding _ prefixed methods)
	local indexTbl = mt:readproperty(types.singleton("__index"))
	assert(indexTbl and indexTbl:is("table"), "metatable must have __index table")

	local publicMethods: { [type]: { read: type?, write: type? } } = {}
	for prop, val in indexTbl:properties() do
		if prop:is("singleton") then
			local propName = prop:value()
			if type(propName) == "string" and propName:sub(1, 1) ~= "_" then
				-- Process method to replace parameter and return types
				local funcVal = val.read or val.write
				if funcVal and funcVal:is("function") then
					-- Replace parameter types (especially self parameter)
					local params = funcVal:parameters()
					if params.head then
						local newParams = {}
						for i, paramType in params.head do
							-- If parameter is the original class type, replace with instance type
							if paramType:is("table") and paramType:readproperty(classIdKey) then
								newParams[i] = instanceType
							else
								newParams[i] = paramType
							end
						end
						funcVal:setparameters(newParams, params.tail)
					end

					-- Replace return types
					local returns = funcVal:returns()
					if returns.head then
						local newReturns = {}
						for i, returnType in returns.head do
							-- If return is the original class type, replace with instance type
							if returnType:is("table") and returnType:readproperty(classIdKey) then
								newReturns[i] = instanceType
							else
								newReturns[i] = returnType
							end
						end
						funcVal:setreturns(newReturns, returns.tail)
					end
				end
				publicMethods[prop] = val
			end
		else
			publicMethods[prop] = val
		end
	end

	-- Create new __index table with only public methods
	local newIndexTbl = types.newtable(publicMethods :: any, nil, nil)

	-- Create new metatable with the new __index
	local newMtProps: { [type]: any } = {}
	for prop, val in mt:properties() do
		if prop:is("singleton") and prop:value() == "__index" then
			newMtProps[prop] = { read = newIndexTbl }
		else
			newMtProps[prop] = val
		end
	end
	local newMt = types.newtable(newMtProps :: any, nil, nil)

	-- Set metatable for instance type
	instanceType:setmetatable(newMt)

	return instanceType
end

type function PrivateKey(s: type): type
	assert(s:is("singleton"), "PrivateKey can only be created from singleton types")
	local keyStr = s:value()
	assert(type(keyStr) == "string", "PrivateKey can only be created from string singletons")
	return types.singleton("_class@" .. keyStr)
end

type DefaultClassIdKey = PrivateKey<UUID<>>
export type PublicClass<T> = ExportClassTypeFn<DefaultClassIdKey, T>
export type PublicInstance<T> = ExportInstanceTypeFn<DefaultClassIdKey, T>
export type WithClassId<T> = WithClassIdTypeFn<DefaultClassIdKey, T>
export type Class<T, MT> = setmetatable<WithClassId<T>, MT>

return {}
