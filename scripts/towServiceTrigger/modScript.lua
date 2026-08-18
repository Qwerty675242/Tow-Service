-- scripts/towServiceTrigger/modScript.lua
--
-- BeamNG's mod manager (core_modmanager) scans /scripts/*/modScript.lua at
-- boot, before any extensions load. Registering an extension here as
-- "manual" unload means it's loaded automatically and survives level/map/
-- career changes, instead of needing extensions.load() typed by hand.

setExtensionUnloadMode("towServiceTrigger", "manual")
loadManualUnloadExtensions()
