local serde = require("@lune/serde")
local tableUtil = require("./utils/tableUtil")
local convertCase = require("./utils/convertCase")
local pathfs = require("../lune_packages/pathfs")
local pubclass = require("./utils/pubclass")
local typeforge = require("./utils/typeforge")

local Options = {}
local mt = { __index = Options }

type Fields = {
	_pesdeManifest: PesdeManifest,
	_releaseConfig: ReleaseConfig,
}

function Options.new(pesdeManifest: PesdeManifest, releaseConfig: ReleaseConfig): Self
	local fields: Fields = {
		_pesdeManifest = pesdeManifest,
		_releaseConfig = releaseConfig,
	}
	return setmetatable(fields, mt) :: Self
end

function Options.default(): Self
	return Options.new({}, {
		keepachangelog = nil,
		bundles = nil,
		publishes = nil,
		osTargets = nil,
		osTargetGlobal = nil,
		commitToken = nil,
	})
end

function Options.fromDeserialized(deserialized: any): Self
	if type(deserialized) ~= "table" then
		error("Manifest.fromDeserialized: expected table, got " .. typeof(deserialized))
	end
	do
		local function recursive(tbl: {}): {}
			return tableUtil.fromEntries(
				tableUtil.map(
					tableUtil.entries(tbl :: { [unknown]: unknown }),
					function(entry: { key: any, value: any })
						local key: any = if type(entry.key) == "string" then
							convertCase.toCamel(entry.key)
						else
							entry.key
						local value: any = if type(entry.value) == "table" then
							recursive(entry.value)
						else
							entry.value
						return { key = key, value = value }
					end
				)
			)
		end
		deserialized = recursive(deserialized)
	end
end

function Options.fromFile(path: pathfs.AsPath): Self
	-- TODO: Allow pathfs.FilePath type as input after FilePath.from allows passing its self type
	return Options.fromDeserialized(pathfs.deserializeFile(path))
end

function Options.withPesdeManifest(self: Self, pesdeManifest: PesdeManifest): Self
	self._pesdeManifest = pesdeManifest
	return self
end

function Options.withReleaseConfig(self: Self, releaseConfig: ReleaseConfig): Self
	self._releaseConfig = releaseConfig
	return self
end

function Options.pesdeManifest(self: Self): PesdeManifest
	return self._pesdeManifest
end

function Options.releaseConfig(self: Self): ReleaseConfig
	return self._releaseConfig
end

export type PesdeManifest = typeforge.Partial<{}>

export type ReleaseConfig = typeforge.Partial<{
	keepachangelog: boolean,
	bundles: { string },
	publishes: { string },
	osTargets: { string },
	osTargetGlobal: string,
	commitToken: string,
}>

type Self = pubclass.Class<Fields, typeof(mt)>

export type Options = pubclass.PublicInstance<Self>

return Options :: pubclass.PublicClass<Self>
