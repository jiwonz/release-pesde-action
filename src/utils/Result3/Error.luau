local pp = require("../pp")
local types = require("./types")

type Reason = types.Reason

local Error = {}
local ErrorMt = {
	__index = Error,
	__tostring = function(self: Error): string
		return self:toString()
	end
}

function Error.is(value: unknown): boolean
	return type(value) == "table" and getmetatable(value) == ErrorMt
end

function Error.new(reason: Error | Reason, source: (Error | Reason)?): Error
	local processedSource: Error? = nil
	if source then
		-- If source is already a Error, use it as-is. Otherwise wrap it.
		if Error.is(source) then
			processedSource = source :: Error
		else
			processedSource = Error.new(source)
		end
	end

	return setmetatable({
		reason = reason,
		source = processedSource,
	}, ErrorMt)
end

function Error.toString(self: Error): string
	if not self.source then
		return pp(self.reason)
	end
	return `{pp(self:rootCause().reason)}: {pp(self.reason)}`
end

function Error.toDebugString(self: Error): string
	local lines: { string } = {}
	table.insert(lines, "Error: " .. pp(self:rootCause().reason))

	if not self.source then
		return lines[1]
	end

	table.insert(lines, "\nCaused by:")
	local current: Error? = self
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

function Error.chain(self: Error): { Error }
	local chain: { Error } = {}
	local current: Error? = self
	while current do
		table.insert(chain, current)
		current = current.source
	end
	return chain
end

function Error.rootCause(self: Error): Error
	local current: Error = self
	while current.source do
		current = current.source
	end
	return current
end

export type Error = setmetatable<{
	read reason: Reason,
	read source: Error?
}, typeof(ErrorMt)>

return Error
