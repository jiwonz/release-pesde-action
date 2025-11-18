local Failure = require("@self/Failure")
local types = require("@self/types")

export type Failure = Failure.Failure
type Reason = types.Reason

local Result = {}
local ResultMt = { __index = Result }

-- selene: allow(shadowing)
local function value<T>(value: T): ResultSuccess<T>
	return setmetatable({
		isSuccess = true :: true,
		isFailed = false :: false,
		value = value,
		failure = nil,
	}, ResultMt)
end

local function failure(reason: Reason | Failure): ResultFailure
	local fail = if Failure.is(reason) then reason :: Failure else Failure.new(reason)

	return setmetatable({
		isSuccess = false :: false,
		isFailed = true :: true,
		value = nil,
		failure = fail,
	}, ResultMt)
end

local function try<T>(fn: () -> T): Result<T>
	local ok, err = pcall(fn)
	if err then
		return failure(err)
	end
	return value(ok)
end

function Result.context<T>(self: Result<T>, context: Reason): Result<T>
	if self.failure then
		return failure(Failure.new(context, self.failure))
	end
	return value(self.value)
end

function Result.unwrapOrError<T>(self: Result<T>, errorMsg: Reason?): T
	if self.value then
		return self.value
	end
	error(
		if errorMsg
			then Failure.new(self.failure, errorMsg):toString()
			else `called "Result.unwrapOrError" on failure: {self.failure}`
	)
end

function Result.unwrapFailureOrError(self: Result<any>): Failure
	if self.failure then
		return self.failure
	end
	error("called 'Result.unwrapFailureOrError' on ok result")
end

--- idk
-- function Result.unwrapOrElse<T>(self: Result<T>, onFailure: (failure: Failure) -> T): T

-- end

type ResultSuccess<T> = setmetatable<{
	read isSuccess: true,
	read isFailed: false,
	read value: T,
	read failure: nil,
}, typeof(ResultMt)>
type ResultFailure = setmetatable<{
	read isSuccess: false,
	read isFailed: true,
	read value: nil,
	read failure: Failure,
}, typeof(ResultMt)>
export type Result<T> = ResultSuccess<T> | ResultFailure

return table.freeze({
	value = value,
	failure = failure,
	try = try,
	context = Result.context,
	unwrapOrError = Result.unwrapOrError,
})
