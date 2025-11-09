local serde = require("@lune/serde")
local tableUtil = require("./utils/tableUtil")
local convertCase = require("./utils/convertCase")
local pathfs = require("../lune_packages/pathfs")
local pubclass = require("./utils/pubclass")
local typeforge = require("./utils/typeforge")

local Manifest = {}
local mt = { __index = Manifest }

type Fields = {
	_pesde: PesdeConfig,
	_release: ReleaseConfig,
}

function Manifest.new(pesde: PesdeConfig, release: ReleaseConfig): Self
	local fields: Fields = {
		_pesde = pesde,
		_release = release,
	}
	return setmetatable(fields, mt) :: Self
end

function Manifest.default(): Self
	return Manifest.new({}, {
		keepachangelog = nil,
		bundles = nil,
		publishes = nil,
		osTargets = nil,
		osTargetGlobal = nil,
		commitToken = nil,
	})
end

-- WIP: from PesdeManifest(another class)?
function Manifest.fromDeserializedPesdeManifest(deserialized: any): Self
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

function Manifest.fromPesdeManifestFile(path: pathfs.AsPath): Self
	-- TODO: Allow pathfs.FilePath type as input after FilePath.from allows passing its self type
	return Manifest.fromDeserializedPesdeManifest(pathfs.deserializeFile(path))
end

function Manifest.withPesde(self: Self, pesde: PesdeConfig): Self
	self._pesde = pesde
	return self
end

function Manifest.withRelease(self: Self, release: ReleaseConfig): Self
	self._release = release
	return self
end

function Manifest.pesde(self: Self): PesdeConfig
	return self._pesde
end

function Manifest.release(self: Self): ReleaseConfig
	return self._release
end

type PesdeConfig = typeforge.Partial<typeforge.ReadOnly<{}>>

type ReleaseConfig = typeforge.Partial<typeforge.ReadOnly<{
	keepachangelog: boolean,
	bundles: { string },
	publishes: { string },
	osTargets: { string },
	osTargetGlobal: string,
	commitToken: string,
}>>

type Self = pubclass.Class<Fields, typeof(mt)>

export type Manifest = pubclass.PublicInstance<Self>

return Manifest :: pubclass.PublicClass<Self>
