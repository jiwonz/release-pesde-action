local pp = require("../pp")
local types = require("./types")

type Reason = types.Reason

local Failure = {}
local FailureMt = {
	__index = Failure,
	__tostring = function(self: Failure): string
		return self:toString()
	end
}

function Failure.is(value: unknown): boolean
	return type(value) == "table" and getmetatable(value) == FailureMt
end

function Failure.new(reason: Failure | Reason, source: (Failure | Reason)?): Failure
	local processedSource: Failure? = nil
	if source then
		-- If source is already a Failure, use it as-is. Otherwise wrap it.
		if Failure.is(source) then
			processedSource = source :: Failure
		else
			processedSource = Failure.new(source)
		end
	end

	return setmetatable({
		reason = reason,
		source = processedSource,
	}, FailureMt)
end

function Failure.toString(self: Failure): string
	if not self.source then
		return pp(self.reason)
	end
	return `{pp(self:rootCause().reason)}: {pp(self.reason)}`
end

function Failure.toDebugString(self: Failure): string
	local lines: { string } = {}
	table.insert(lines, "Failure: " .. pp(self:rootCause().reason))

	if not self.source then
		return lines[1]
	end

	table.insert(lines, "\nCaused by:")
	local current: Failure? = self
	local root = self:rootCause()

	-- Collect contexts from self to root (excluding root)
	local contexts: { string } = {}
	while current and current ~= root do
		table.insert(contexts, pp(current.reason))
		current = current.source
	end

	-- Print in reverse order (oldest context first)
	for i = #contexts, 1, -1 do
		table.insert(lines, "\t" .. contexts[i])
	end

	return table.concat(lines, "\n")
end

function Failure.chain(self: Failure): { Failure }
	local chain: { Failure } = {}
	local current: Failure? = self
	while current do
		table.insert(chain, current)
		current = current.source
	end
	return chain
end

function Failure.rootCause(self: Failure): Failure
	local current: Failure = self
	while current.source do
		current = current.source
	end
	return current
end

export type Failure = setmetatable<{
	read reason: Reason,
	read source: Failure?
}, typeof(FailureMt)>

return Failure
