local result = require("./serdeform2/result")

type function ImplTraitsTypeFn(pack: type): type
	assert(pack:is("function"), "this type function's first argument must be a function with a type pack parameter type")
	local headParam = pack:parameters().head
	assert(headParam and headParam[1], "requires valid types more than one")
	local fieldSet: { [string]: true } = {}
	local props: { [type]: type } = {}
	for _, t in headParam do
		assert(t:is("table"), "types must be tables")
		for prop, val in t:properties() do
			-- selene: allow(shadowing)
			local val = val.read or val.write
			assert(val and val:is("function"), "traits only can have function definitions")
			local propVal = prop:value()
			assert(propVal and type(propVal) == "string", "method names must be singleton strings")
			assert(not fieldSet[propVal], "trait conflict")
			fieldSet[propVal] = true
			props[prop] = val
		end
	end
	return types.newtable(props)
end

type Impl<T...> = ImplTraitsTypeFn<(T...) -> ()>

type TypeTrait<T> = {
	parse: (self: any, input: unknown) -> result.Result<T>,
}

type NumberTypeImpl = {
	new: () -> any,
}

-- why impl check is needed: because for serdeform.form's argument type check(to check the argument is a valid Type)

local NumberType: Impl<{
	new: () -> any,
}, TypeTrait<number>>
local NumberTypeStruct = {}
local NumberTypeMt = { __index = NumberTypeStruct }

function NumberTypeStruct.new(): NumberType

end

function NumberTypeStruct.parse(): result.Result<number>

end

-- NumberType = {
-- 	new = function(): NumberType
-- 		return setmetatable({ _t = nil :: any }, NumberTypeMt)
-- 	end,
-- 	parse = function(self: NumberType, input)
-- 		return result.success(2)
-- 	end,
-- }
NumberType = NumberTypeStruct


type NumberType = setmetatable<{ _t: number }, typeof(NumberTypeMt)>


--[=[


local NumberType = impl({
	new = function(): NumberType
		...
	end
}) --
:impl({
	parse = function() ...
} :: TypeTrait<number>) --


]=]



-- local NumberType: Implements<TypeTrait<NumberType, number>> = {}
-- local NumberTypeMt = { __index = NumberType }

-- type NumberType = setmetatable<{ _t: number }, typeof(NumberTypeMt)>

-- type Parser<T> = (input: unknown) -> result.Result<T>

-- function Type.new<T>(parser: Parser<T>): Type<T>
-- 	return setmetatable({ _parser = parser, _t = nil }, TypeMt)
-- end

-- function Type.parse<T>(self: Type<T>, input: unknown): result.Result<T>
-- 	return self._parser(input)
-- end

-- function Type.parser<T>(self: Type<T>): Parser<T>
-- 	return self._parser
-- end

-- function Type.optional<T>(self: Type<T>): Type<T?>
-- 	local parser: Parser<T?> = function(input: unknown): result.Result<T?>
-- 		if input == nil then
-- 			return result.success(nil)
-- 		else
-- 			return self:parse(input)
-- 		end
-- 	end
-- 	return Type.new(parser)
-- end

-- type Type<T> = setmetatable<{ read _parser: Parser<T>, read _t: T }, typeof(TypeMt)>

-- -- WIP: Struct type
