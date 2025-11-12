--[=[
	Type 클래스가 Composable, 싱글톤 클래스가 모두 따로
]=]

local result = require("./serdeform2/result")

local Type = {}
local TypeMt = { __index = Type }

type Parser<T> = (input: unknown) -> result.Result<T>

function Type.new<T>(parser: Parser<T>): Type<T>

end

type Type<T> = setmetatable<{ _t: T }, typeof(TypeMt)>

local serdeform = {}

do
	local NumberType = {}
	local NumberTypeMt = { __index = NumberType }

	function NumberType.new(type: Type<number>): NumberType
		return setmetatable({ type = type }, NumberTypeMt)
	end

	type NumberType = setmetatable<{ type: Type<number> }, typeof(NumberTypeMt)>

	serdeform.number = NumberType.new(Type.new(function(input)
		return result.success(2)
	end))
end
