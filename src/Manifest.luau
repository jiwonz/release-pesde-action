local serde = require("@lune/serde")

local Manifest = {}
Manifest.__index = Manifest

function Manifest.new(): Manifest
	return setmetatable({}, Manifest) :: Manifest
end

function Manifest.parse(contents: string | buffer): Manifest

end

function Manifest.is(value: unknown): boolean
	return type(value) == "table" and getmetatable(value :: any) == Manifest
end

function Manifest.withReleaseConfig(self: Manifest)
	self._release = {} :: any
end

export type Manifest = setmetatable<{
	_pesde: {

	},
	_release: {
		read keepachangelog: boolean?,
		read bundles: { string }?,
		read publishes: { string }?,
		read osTargets: { string }?,
		read osTargetGlobal: string?,
		read commitToken: string?,
	},
}, typeof(Manifest)>
