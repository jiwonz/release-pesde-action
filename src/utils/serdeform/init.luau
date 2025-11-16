-- TODO: Support error formatter like anyhow lib and Support various naming cases
-- TODO: what about exposing InferType type function?
-- TODO: what about casting(like between numbers and strings) into serdeform Type when decoding?

local _result = require("./Result")
local Result = _result.Result
local Type = require("@self/Type")
local stdio = require("@lune/stdio")

export type Type<T> = Type.Type<T>
type Result<T> = _result.Result<T>

local serdeform = {}

type TypeByTypeName = {
	["nil"]: nil,
	number: number,
	string: string,
	boolean: boolean,
	table: { [any]: any },
	["function"]: (...any) -> ...any,
	thread: thread,
}

type function ParserFromTypeTypeFn(typeByTypeName: type, name: type): type
	assert(typeByTypeName:is("table"), "typeByTypeName must be a table")
	assert(name:is("singleton"), "name must be a singleton string")
	local prop = typeByTypeName:readproperty(name)
	assert(prop, "TypeByTypeName does not have property " .. tostring(name))
	return prop
end

type ParserFromType<T> = ParserFromTypeTypeFn<TypeByTypeName, T>

local function typeFromTypeName<T>(typeName: T & keyof<TypeByTypeName>): Type<ParserFromType<T>>
	return Type.new(function(input: unknown): Result<any>
		if type(input) == typeName then
			return Result.ok(input)
		else
			return Result.fail(`Expected {typeName}, got {typeof(input)}`)
		end
	end) :: any
end

serdeform.number = typeFromTypeName('number')
serdeform.string = typeFromTypeName('string')
serdeform.boolean = typeFromTypeName('boolean')
serdeform.table = typeFromTypeName('table')
serdeform.none = typeFromTypeName('nil')
type function InferType(t: type): type
	assert(t:is("table"), "type must be a table")
	local prop = t:readproperty(types.singleton("_$type"))
	assert(prop, "TypeKey is not found")
	return prop
end

type function FormType(schema: type): type
	assert(schema:is("table"), "schema must be table")
	local props: { [type]: type } = {}
	for prop, val in schema:properties() do
		assert(prop:is("singleton"), "schema property key must be singleton string")
		-- selene: allow(shadowing)
		local val = val.read or val.write
		assert(val, "schema property value must be valid")
		props[prop] = InferType(val)
	end
	return types.newtable(props)
end

local function form<T>(schema: T, strict: boolean): Type<FormType<T>>
	return Type.new(function(input: unknown): Result<{ [any]: any }>
		if type(input) ~= "table" then
			return Result.fail(`Expected table, got {typeof(input)}`)
		end

		local output: { [any]: any } = {}

		for prop, val in schema :: { [string]: Type<any>? } do
			if val == nil then
				return Result.fail(`Missing property: {prop}`)
			end
			local result = val:parse((input :: { [any]: any })[prop])
			if result.ok then
				output[prop] = result.value
			else
				return Result.fail(`In property '{prop}': {result:format()}`)
			end
		end

		if strict then
			for key, _ in input :: { [any]: any } do
				if type(key) == "string" and (schema :: { [string]: Type<any>? })[key] == nil then
					return Result.fail(`Unexpected property: {key}`)
				end
			end
		end

		return Result.ok(output)
	end) :: any
end

function serdeform.form<T>(schema: T): Type<FormType<T>>
	return form(schema, false)
end

--- This doesn't allow extra properties
function serdeform.strictForm<T>(schema: T): Type<FormType<T>>
	return form(schema, true)
end

local function formatLiternal<T>(value: T): string
	if type(value) == "string" then
		return `"{value}"`
	else
		return stdio.format(value)
	end
end

function deepEqual(obj1: any, obj2: any)
    if obj1 == obj2 then return true end
    if type(obj1) ~= "table" or type(obj2) ~= "table" then
        return false
    end
    for k, v in obj1 do
        if not deepEqual(v, (obj2 :: any)[k]) then
            return false
        end
    end
    for k, v in obj2 do
        if not deepEqual(v, (obj1 :: any)[k]) then
            return false
        end
    end
    return true
end

function serdeform.literal<T>(value: T): Type<T>
	return Type.new(function(input: unknown): Result<T>
		if deepEqual(input, value) then
			return Result.ok(value)
		else
			return Result.fail(`Expected literal value {formatLiternal(value)}, got {formatLiternal(input)}`)
		end
	end)
end

function serdeform.any(): Type<any>
	return Type.new(function(input: unknown): Result<any>
		return Result.ok(input)
	end)
end

function serdeform.unknown(): Type<unknown>
	return Type.new(function(input: unknown): Result<unknown>
		return Result.ok(input)
	end)
end

function serdeform.array<T>(elementType: Type<T>): Type<{ T }>
	return Type.new(function(input: unknown): Result<{ T }>
		if type(input) ~= "table" then
			return Result.fail(`Expected array (table), got {typeof(input)}`)
		end

		local output: { T } = {}
		local index = 1
		while (input :: { [any]: any })[index] ~= nil do
			local elementResult = elementType:parse((input :: { [any]: any })[index])
			if elementResult.ok then
				output[index] = elementResult.value
			else
				return Result.fail(`In array at index {index}: {elementResult:format()}`)
			end
			index += 1
		end

		return Result.ok(output)
	end)
end

function serdeform.map<K, V>(keyType: Type<K>, valueType: Type<V>): Type<{ [K]: V }>
	return Type.new(function(input: unknown): Result<{ [K]: V }>
		if type(input) ~= "table" then
			return Result.fail(`Expected map (table), got {typeof(input)}`)
		end

		local output: { [K]: V } = {}

		for key, value in input :: { [any]: any } do
			local keyResult = keyType:parse(key)
			if not keyResult.ok then
				return Result.fail(`In map key '{tostring(key)}': {keyResult:format()}`)
			end

			local valueResult = valueType:parse(value)
			if not valueResult.ok then
				return Result.fail(`In map value for key '{tostring(key)}': {valueResult:format()}`)
			end

			output[keyResult.value] = valueResult.value
		end

		return Result.ok(output)
	end)
end

type function UnionTypeTypeFn<T...>(packFn: type): type
	assert(packFn:is("function"), "expected a function with type pack")
	local pack = packFn:parameters().head
	assert(pack, "expected type pack")
	local unionTypes: { type } = {}
	for _, val in pack do
		table.insert(unionTypes, InferType(val))
	end
	if #unionTypes == 1 then
		return unionTypes[1]
	end
	return types.unionof(unpack(unionTypes))
end

type UnionType<T...> = UnionTypeTypeFn<(T...) -> ()>

function serdeform.union<T...>(...: T...): Type<UnionType<T...>>
	local unionTypes = { ... } :: { Type<any> }
	return Type.new(function(input: unknown): Result<any>
		local reasons: { string } = {}

		for _, unionType in unionTypes do
			local result = (unionType :: Type<any>):parse(input)
			if result.ok then
				return Result.ok(result.value)
			else
				table.insert(reasons, result:format())
			end
		end

		return Result.fail(`No union types matched. Reasons: {table.concat(reasons, "; ")}`)
	end) :: any
end

function serdeform.custom<T>(parser: (input: unknown) -> Result<T>): Type<T>
	return Type.new(parser)
end

return table.freeze(serdeform)
