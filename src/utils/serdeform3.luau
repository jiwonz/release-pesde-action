--[=[
	함수가 Composable, 클래스 한개
]=]

local result = require("./serdeform2/result")
local typeforge = require("./typeforge")

local Type = {}
local TypeMt = { __index = Type }

type Parser<T> = (input: unknown) -> result.Result<T>

function Type.new<T>(parser: Parser<T>): Type<T>
	return setmetatable({ _parser = parser, ["@type"] = nil }, TypeMt)
end

function Type.parse<T>(self: Type<T>, input: unknown): result.Result<T>
	return self._parser(input)
end

function Type.parser<T>(self: Type<T>): Parser<T>
	return self._parser
end

function Type.optional<T>(self: Type<T>): Type<T?>
	local parser: Parser<T?> = function(input: unknown): result.Result<T?>
		if input == nil then
			return result.success(nil)
		else
			return self:parse(input)
		end
	end
	return Type.new(parser)
end

type Type<T> = setmetatable<{ read _parser: Parser<T>, read ["@type"]: T }, typeof(TypeMt)>

local serdeform = {}

serdeform.number = Type.new(function(input)
	return result.success(2)
end)

type function InferType(t: type): type
	assert(t:is("table"), "type must be a table")
	local prop = t:readproperty(types.singleton("@type"))
	assert(prop, "TypeKey is not found")
	return prop
end

type function FormType(schema: type): type
	assert(schema:is("table"), "schema must be table")
	local props: { [type]: type } = {}
	for prop, val in schema:properties() do
		-- selene: allow(shadowing)
		local val = val.read or val.write
		assert(val, "schema property value must be valid")

	end
end

function serdeform.form<T>(schema: T): Type<T>

end
