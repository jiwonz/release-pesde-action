local serde = require("@lune/serde")
local _result = require("../Result")
local Result = _result.Result
local convertCase = require("../convertCase")

local Type = {}
local TypeMt = { __index = Type }

type Result<T> = _result.Result<T>
type Parser<T> = (input: unknown) -> Result<T>

function Type.new<T>(parser: Parser<T>): Type<T>
	return setmetatable({ _parser = parser, ["_$type"] = nil }, TypeMt)
end

function Type.parse<T>(self: Type<T>, input: unknown): Result<T>
	if type(input) == "table" then
		local camelCaseTbl: { [any]: any } = {}
		for key, value in input do
			if type(key) ~= "string" then
				camelCaseTbl[key] = value
				continue
			end
			camelCaseTbl[convertCase.toCamel(key)] = value
		end
		return self._parser(camelCaseTbl)
	end
	return self._parser(input)
end

function Type.construct<T>(self: Type<T>, value: T): T
	local result = self._parser(value)
	if result.ok then
		return result.value
	else
		error(`Failed to construct value: {result:format()}`)
	end
end

function Type.decode<T>(self: Type<T>, format: serde.EncodeDecodeFormat, encoded: buffer | string): Result<T>
	return self:parse(serde.decode(format, encoded))
end

function Type.encode<T>(self: Type<T>, format: serde.EncodeDecodeFormat, value: T): string
	return serde.encode(format, self:construct(value))
end

function Type.parser<T>(self: Type<T>): Parser<T>
	return self._parser
end

function Type.optional<T>(self: Type<T>): Type<T?>
	local parser: Parser<T?> = function(input: unknown): Result<T?>
		if input == nil then
			return Result.ok(nil)
		else
			return self:parse(input)
		end
	end
	return Type.new(parser)
end

export type Type<T> = setmetatable<{ read _parser: Parser<T>, read ["_$type"]: T }, typeof(TypeMt)>

return table.freeze(Type)
