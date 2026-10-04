# It Was This Big!

An interface 16001 fishing addon for WoW Forever. Copy this folder into
`Interface\AddOns\ItWasThisBig`, enable it at the character-select AddOns
screen, and open it with `/iwtb` or `/bigfish`.

The addon watches your loot messages for catalogued fish and records an
estimated length and weight for each one. Estimates use the species' average
and standard deviation in `IWTB_Fish.lua`; random values are clamped at zero.
Freshwater fish use lower weight estimates than comparable saltwater fish,
and the estimates generally rise with fish level.

The menu has Settings, Freshwater, Saltwater, and Log tabs. Fish species you
have not discovered appear as question-mark icons; caught species show their
best-record rarity as the icon border. Click a discovered fish icon for its catch count,
heaviest and lightest catches, estimated weight bonus from your Fishing skill,
species averages, and a short field note. Log shows recent catches. Border
color indicates the catch's length relative to its species average:
poor below average, common around average, then uncommon, rare, epic, and
legendary at increasing standard-deviation thresholds. Rare, epic, and
legendary catches each have an independent sound checkbox, as does the
personal-record sound. The Settings tab uses checkboxes for each sound option
and for the minimap icon.
The Settings tab also lets you turn the Deviate Fish minimap button on or off;
the button can be dragged around the minimap and clicked to open the addon.
The minimap button angle is saved between sessions.

Estimated catch weight rises with Fishing skill, up to a 50% bonus at the
skill-line cap; when the skill cannot be read, the base estimate is used.
Species field notes are paraphrased from [Warcraft Wiki fish entries](https://warcraft.wiki.gg/wiki/Fishing_items),
including [Deviate Fish](https://warcraft.wiki.gg/wiki/Deviate_Fish),
[Stonescale Eel](https://warcraft.wiki.gg/wiki/Stonescale_Eel), and
[Nightfin Snapper](https://warcraft.wiki.gg/wiki/Raw_Nightfin_Snapper).

This is an estimate-based tracking addon, not a source of actual fish sizes.
The bundled catalog covers the classic fish set; add species to `IWTB_Fish.lua`
to support additional fish names or custom-server content.

The addon code is divided into `ItWasThisBig.lua` for catch tracking and saved
data, `IWTB_UI.lua` for the window and fish views, and `IWTB_Settings.lua` for
settings controls. The `.toc` file lists them in required load order.
