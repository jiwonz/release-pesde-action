local pathfs = require("../lune_packages/pathfs")

export type Options = {
	keepachangelog: boolean?,
	bundles: { string }?,
	publishes: { string }?,
	osTargets: { string }?,
	osTargetGlobal: string?,
	commitToken: string?,
}

local lib = {}

function lib.release(options: Options, dryRun: boolean?)

end

return lib
