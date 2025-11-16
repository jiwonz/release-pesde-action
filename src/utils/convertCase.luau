--!native

-- TODO: Make sure is --!native is really necessary here and what about making type function utilities?

local convertCase = {}

local function capitalFirst(str: string): string
	return string.upper(string.sub(str, 1, 1)) .. string.lower(string.sub(str, 2))
end

local function getWords(variableName: string): { string }
	variableName = string.upper(variableName) == variableName and string.lower(variableName) or variableName
	variableName = string.upper(string.sub(variableName, 1, 1)) .. string.sub(variableName, 2)

	variableName = string.gsub(variableName, "-(.)", function(str)
		return string.upper(str)
	end)

	variableName = string.gsub(variableName, "_(.)", function(str)
		return string.upper(str)
	end)

	local words: { string } = {}

	for word in string.gmatch(variableName, "[A-Z][^A-Z]*") do
		words[#words + 1] = word
	end

	return words
end

function convertCase.toCamel(variableName: string): string
	local words = getWords(variableName)
	if #words == 0 then
		return variableName
	end
	local newVariableName = string.lower(words[1])

	for index = 2, #words do
		newVariableName = newVariableName .. capitalFirst(words[index])
	end

	return newVariableName
end

function convertCase.toPascal(variableName: string): string
	local words = getWords(variableName)
	if #words == 0 then
		return variableName
	end
	local newVariableName = ""

	for index = 1, #words do
		newVariableName = newVariableName .. capitalFirst(words[index])
	end

	return newVariableName
end

function convertCase.toSnake(variableName: string): string
	local words = getWords(variableName)
	if #words == 0 then
		return variableName
	end
	local newVariableName = string.lower(words[1])

	for index = 2, #words do
		newVariableName = newVariableName .. "_" .. string.lower(words[index])
	end

	return newVariableName
end

function convertCase.toUpperSnake(variableName: string): string
	local words = getWords(variableName)
	if #words == 0 then
		return variableName
	end
	local newVariableName = words[1]

	for index = 2, #words do
		newVariableName = newVariableName .. "_" .. words[index]
	end

	return string.upper(newVariableName)
end

function convertCase.toKebab(variableName: string): string
	local words = getWords(variableName)
	if #words == 0 then
		return variableName
	end
	local newVariableName = string.lower(words[1])

	for index = 2, #words do
		newVariableName = newVariableName .. "-" .. string.lower(words[index])
	end

	return newVariableName
end

function convertCase.toLower(variableName: string): string
	local words = getWords(variableName)
	if #words == 0 then
		return variableName
	end
	local newVariableName = string.lower(words[1])

	for index = 2, #words do
		newVariableName = newVariableName .. string.lower(words[index])
	end

	return newVariableName
end

return table.freeze(convertCase)
