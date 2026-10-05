# It Was This Big!

An interface 16001 fishing addon for WoW Forever. Copy this folder into
`Interface\AddOns\ItWasThisBig`, enable it at the character-select AddOns
screen, and open it with `/iwtb` or `/bigfish`.

The addon watches your loot messages for catalogued fish and records an
estimated length and weight for each one. Lengths are in centimeters and
weights are in kilograms. Since Azeroth's fish are fictional, their averages
are based on representative real-world analogues listed below. The standard
deviations in `IWTB_Fish.lua` are gameplay variation estimates, not measured
biological statistics; random values are clamped at zero. Freshwater fish are
generally lighter than saltwater fish, and estimates tend to rise with fish
level.

| Catalog fish | Real-world size analogue | Reference |
| --- | --- | --- |
| Brilliant Smallfish | Fathead minnow | [FishBase](https://www.fishbase.se/summary/Pimephales-promelas.html) |
| Slitherskin Mackerel | Atlantic mackerel | [NOAA Fisheries](https://www.fisheries.noaa.gov/species/atlantic-mackerel) |
| Longjaw Mud Snapper | Mudminnow | [FishBase](https://www.fishbase.se/summary/Umbra-limi.html) |
| Rainbow Fin Albacore | Albacore | [FishBase](https://www.fishbase.se/summary/Thunnus-alalunga.html) |
| Bristle Whisker Catfish | Channel catfish | [FishBase](https://www.fishbase.se/summary/Ictalurus-punctatus.html) |
| Rockscale Cod | Atlantic cod | [NOAA Fisheries](https://www.fisheries.noaa.gov/species/atlantic-cod) |
| Mithril Head Trout | Rainbow trout | [FishBase](https://www.fishbase.se/summary/Oncorhynchus-mykiss.html) |
| Redgill | Redbreast sunfish | [FishBase](https://www.fishbase.se/summary/Lepomis-auritus.html) |
| Spotted Yellowtail | Yellowtail snapper | [NOAA Fisheries](https://www.fisheries.noaa.gov/species/yellowtail-snapper); [Florida Museum](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/yellowtail-snapper/) |
| Sunscale Salmon | Atlantic salmon | [NOAA Fisheries](https://www.fisheries.noaa.gov/species/atlantic-salmon) |
| Nightfin Snapper | Black crappie | [FishBase](https://www.fishbase.se/summary/Pomoxis-nigromaculatus.html) |
| Greater Sagefish | Larger adult gizzard shad | [FishBase](https://www.fishbase.se/summary/Dorosoma-cepedianum.html) |
| Sagefish | Gizzard shad | [FishBase](https://www.fishbase.se/summary/Dorosoma-cepedianum.html) |
| Oily Blackmouth | Atlantic menhaden | [FishBase](https://www.fishbase.se/summary/Brevoortia-tyrannus.html) |
| Firefin Snapper | Red snapper | [NOAA Fisheries](https://www.fisheries.noaa.gov/species/red-snapper) |
| Stonescale Eel | Conger eel | [FishBase](https://www.fishbase.se/summary/Conger-conger.html) |
| Deviate Fish | Common carp (size and habitat proxy) | [FishBase](https://www.fishbase.se/summary/Cyprinus-carpio.html) |
| Glossy Mightfish | Greater amberjack | [NOAA Fisheries](https://www.fisheries.noaa.gov/species/greater-amberjack) |
| Whitescale Salmon | Chinook salmon | [NOAA Fisheries](https://www.fisheries.noaa.gov/species/chinook-salmon) |
| Winter Squid | Longfin inshore squid (mantle length) | [FishBase](https://www.fishbase.se/summary/Doryteuthis-pealeii.html) |
| Summer Bass | Black sea bass | [NOAA Fisheries](https://www.fisheries.noaa.gov/species/black-sea-bass) |
| Darters | Rainbow darter | [FishBase](https://www.fishbase.se/summary/Etheostoma-caeruleum.html) |
| Blackbelly Mudfish | Bowfin | [FishBase](https://www.fishbase.se/summary/Amia-calva.html) |
| Large Mightfish | Large adult greater amberjack | [NOAA Fisheries](https://www.fisheries.noaa.gov/species/greater-amberjack) |
| Darkclaw Lobster | American lobster | [NOAA Fisheries](https://www.fisheries.noaa.gov/species/american-lobster) |

These are deliberately rounded working estimates, not exact averages for the
fictional fish. Several names have no clear real species match: those entries
use a proxy based on the name, habitat, or likely body type. The game applies
the same Fishing-skill bonus on top of these baseline weights.

The menu has Settings, Freshwater, Saltwater, Log, and Stats tabs. New catches
store the current zone in the log and update persistent zone totals. The Stats
tab shows the most-caught species, heaviest and lightest catches, and zone
with the most catches. The catch log is a rolling history capped at 500 catches;
species and zone totals are separate lifetime aggregates and do not decrease as
old log entries roll off. On upgrade, aggregates are rebuilt from the saved log
and personal records, so catches already missing from that history cannot be
reconstructed. Older log entries without zone data are not attributed to a zone.
Fish species you
have not discovered appear as question-mark icons; caught species show their
best-record rarity as the icon border. Click a discovered fish icon for its catch count,
heaviest and lightest catches, estimated weight bonus from your Fishing skill,
species averages, and a short field note. Log shows recent catches. Border
color indicates the catch's length relative to its species average:
poor below average, common around average, then uncommon, rare, epic, and
legendary at increasing standard-deviation thresholds. Rare, epic, and
legendary catches each have an independent sound checkbox, as does the
personal-record sound. The Settings tab also has checkboxes for the minimap
icon and temporarily muting music, ambience, and dialog sound from the fishing
cast until a fish is looted. Sound effects remain enabled so the fishing splash
can play. The original muted settings are restored when loot is received, if
the cast is interrupted or fails, when the option is turned off, or when the
player logs out; addon catch alerts use the master sound channel.
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

The addon is split by responsibility: `ItWasThisBig.lua` parses loot and
records catches; `IWTB_Stats.lua` owns lifetime species/zone aggregates and
their legacy-data initialization; `IWTB_Audio.lua` handles cast muting and
catch alerts; `IWTB_Minimap.lua` manages the minimap button; `IWTB_UI.lua`
renders the window and views; and `IWTB_Settings.lua` builds settings
controls. The `.toc` file lists them in required load order.

The standalone behavior tests mock the WoW APIs and can be run from the addon
directory with `lua tests\test_addon.lua` (Lua 5.1 or compatible).

## License

This project is distributed under the BSD 2-Clause License. See [LICENSE](LICENSE)
for the complete terms.
