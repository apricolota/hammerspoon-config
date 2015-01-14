require = require("utils.require")
require.update_require_paths("In Home", {
    os.getenv("HOME").."/.hammerspoon/?.lua;"..
    os.getenv("HOME").."/.hammerspoon/?/init.lua",
    os.getenv("HOME").."/.hammerspoon/?.so"}, false)
require.update_require_paths("Luarocks", "luarocks path", true)

inspect = hs.inspect
inspect1 = function(what) return inspect(what, {depth=1}) end

hs.ipc.cliInstall("/opt/amagill")

-- What can I say? I like the original Hydra's console documentation style,
-- rather than help("...")
-- _G["debug.docs.module"] = "sort"
doc = hs.doc.fromJSONFile(hs.docstrings_json_file)

-- For my convenience while testing and screwing around...
-- If something grows into usefulness, I'll modularize it.
_asm = {
    _ = package.loaded,
    extras = require("hs._asm.extras"),
    _keys = require.require_path("utils._keys", false),
    _actions = require.require_path("utils._actions", false),
    _doc = "use _asm._doc_load() to load docs corrosponding to package.loaded.",
    _doc_load = function() _asm._doc = hs.doc.fromPackageLoaded() end,
}

hs.hints.style = "vimperator"

print("Running: ".._asm.extras._paths.bundlePath)
