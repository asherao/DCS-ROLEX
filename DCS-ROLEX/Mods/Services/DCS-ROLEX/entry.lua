declare_plugin("DCS-ROLEX", {
	installed = true,
	dirName = current_mod_path,
	developerName = _("Bailey"),
	developerLink = _("None"),
	displayName = _("DCS-ROLEX"),
	version = "1.0",
	state = "installed",
	info = _("DCS-ROLEX.\n\nKnow what time it is.\n\nVisit Bailey's Discord for more mods and utilities: https://discord.gg/PbYgC5e.\n\n~Bailey"),
    load_immediate = true,
	Skins = {
		{ name = "DCS-ROLEX", dir = "Theme" },
	},
	Options = {
		{ name = "DCS-ROLEX", nameId = "DCS-ROLEX", dir = "Options", allow_in_simulation = true; },
	},
})

plugin_done()