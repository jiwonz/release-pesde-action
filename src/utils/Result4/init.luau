local Error = require("@self/Error")
local types = require("@self/types")

export type Error = Error.Error
type Reason = types.Reason

local Result = {}
local ResultMt = { __index = Result }

-- selene: allow(shadowing)
local function constructOkResult<T>(value: T): Ok<T>
	return setmetatable({
		isOk = true :: true,
		isErr = false :: false,
		value = value,
		err = nil,
	}, ResultMt)
end

local function constructErrResult(reason: Reason | Error): Err
	local fail = if Error.is(reason) then reason :: Error else Error.new(reason)

	return setmetatable({
		isOk = false :: false,
		isErr = true :: true,
		value = nil,
		err = fail,
	}, ResultMt)
end

local function constructResultFromTry<T>(fn: () -> T): Result<T>
	local ok, err = pcall(fn)
	if err then
		return constructErrResult(err)
	end
	return constructOkResult(ok)
end

Result.context = function(self: Result<any>, context: Reason): Result<any>
	if self.err then
		return constructErrResult(Error.new(context, self.err))
	end
	return constructOkResult(self.value)
end :: (<T>(self: Ok<T>, context: Reason) -> Ok<T>)
& ((self: Err, context: Reason) -> Err)
& (<T>(self: Ok<T> | Err, context: Reason) -> Ok<T> | Err)

function Result.unwrapOrError<T>(self: Result<T>, errorMsg: Reason?): T
	if self.value then
		return self.value
	end
	error(
		if errorMsg
			then Error.new(self.err, errorMsg):toString()
			else `called "Result.unwrapOrError" on err: {self.err}`
	)
end

function Result.unwrapErr(self: Result<any>): Error
	if self.err then
		return self.err
	end
	error("called 'Result.unwrapErr' on ok result")
end

type Ok<T> = setmetatable<{
	read isOk: true,
	read isErr: false,
	read value: T,
	read err: nil,
}, typeof(ResultMt)>
type Err = setmetatable<{
	read isOk: false,
	read isErr: true,
	read value: nil,
	read err: Error,
}, typeof(ResultMt)>
export type Result<T> = Ok<T> | Err

return table.freeze({
	ok = constructOkResult,
	err = constructErrResult,
	try = constructResultFromTry,
	context = Result.context,
	unwrapOrError = Result.unwrapOrError,
})
