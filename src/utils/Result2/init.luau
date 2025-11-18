local Failure = require("@self/Failure")
local types = require("@self/types")

export type Failure = Failure.Failure
type Reason = types.Reason

local Result = {}
local ResultMt = { __index = Result }

-- selene: allow(shadowing)
local function value<T>(value: T): ResultValue<T>
	return setmetatable({
		value = value,
		failure = nil,
	}, ResultMt)
end

local function failure(reason: Reason | Failure.Failure): ResultFailure
	local fail = if Failure.is(reason) then reason :: Failure.Failure else Failure.new(reason)

	return setmetatable({
		failure = fail,
		value = nil,
	}, ResultMt)
end

local function try<T>(fn: () -> T): Result<T>
	local ok, err = pcall(fn)
	if err then
		return failure(err)
	end
	return value(ok)
end

-- function Result.context<T>(self: Result<T>, context: Reason): Result<T>
-- 	if self.failure then
-- 		return failure(Failure.new(context, self.failure))
-- 	end
-- 	return value(self.value)
-- end
Result.context = function<T>(self: Result<T>, context: Reason): Result<T>
	if self.failure then
		-- Context becomes the new outer reason, existing failure becomes source
		return failure(Failure.new(context, self.failure))
	end
	return value(self.value)
end :: (<T>(self: ResultValue<T>, context: Reason) -> ResultValue<T>)
& ((self: ResultFailure, context: Reason) -> ResultFailure)
& (<T>(self: ResultValue<T> | ResultFailure, context: Reason) -> ResultValue<T> | ResultFailure)

function Result.unwrapOrError<T>(self: Result<T>, errorMsg: Reason?): T
	if self.value then
		return self.value
	end
	error(
		if errorMsg
			then Failure.new(self.failure, errorMsg):toString()
			else `called 'Result.unwrapOrError' on failure: '{self.failure}'`
	)
end

--- idk
-- function Result.unwrapOrElse<T>(self: Result<T>, onFailure: (failure: Failure) -> T): T

-- end

type ResultValue<T> = setmetatable<{
	read value: T,
	read failure: nil,
}, typeof(ResultMt)>
type ResultFailure = setmetatable<{
	read value: nil,
	read failure: Failure,
}, typeof(ResultMt)>
export type Result<T> = ResultValue<T> | ResultFailure

return table.freeze({
	value = value,
	failure = failure,
	try = try,
	context = Result.context,
	unwrapOrError = Result.unwrapOrError,
})
