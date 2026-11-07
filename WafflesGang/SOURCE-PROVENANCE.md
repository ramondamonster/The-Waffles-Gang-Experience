# ForeverUI v4.0.0 source update

Derived exclusively from the in-conversation v3.9.9 addon archive. In this pass we changed Core.lua, UI.lua, Bars.lua, Studio.lua, Tactical.lua, QuestTracker.lua and QuestArrow.lua and added an original transparent directional needle file (Media/Icons/TacticalNeedle.tga). All other addon sources and artwork from v3.9.9 are retained. Detailed prior provenance follows.

Uploaded third-party *reference archives* (independent, not merged into this addon): "Queestie(1).zip" (Questie), "threat classic(1).zip" (ThreatClassic), "handy notes andopen map(1).zip", "rest of handy and whats training(1).zip". Third-party code and images are not copied, embedded or redistributed in this Waffles Gang ZIP; retain the source reference ZIPs separately, with their own original licenses and creators. No claim that attribution permits use under an unverified license. No new Questie or TomTom internal code was copied for this release. The existing QuestBridge.lua still contains optional QuestieLoader internal-module fallback calls that are not guaranteed public APIs. Review compatibility and source licenses before future integration or redistribution.

# ForeverUI 3.9.9: Source and provenance

This release was edited directly from the user-provided WafflesGang-Forever
v3.9.8 Tactical Command Overhaul archive. The original addon folder name,
.toc load order, complete source Lua files and all prior images and reference
readmes remain in the package. All files outside the seven listed below were
retained unmodified from v3.9.8, excluding the version metadata, changelog,
README and new release documentation.

Primary code changed for v3.9.9:
- `Core.lua`: independent Tactical colors, settings defaults, slash shortcuts
- `UI.lua`: flat Tactical frame and window styling, no decorative repeat art
- `Bars.lua`: flat Tactical buttons, compact action strip, XP layout
- `Units.lua`: Tactical portrait-free default and simplified unit geometry
- `QuestTracker.lua`: Tactical mission framing and legibility
- `Tactical.lua`: new safe read-only field console
- `Studio.lua`: directory and three Tactical config sections

Creator/provenance: Rain is credited for the original Waffles Gang code and
visual identity; Waffles Gang community members supplied testing, direction,
and iteration. See `CREDITS-AND-THIRD-PARTY-NOTICES.md` for the full rights
and third-party reference inventory. Rain's supplied original code/art has no
verified open-source license; secure permission before redistribution beyond
whatever use Rain has authorized. Attribution alone is not permission.

Third-party WoW addons listed in CREDITS were consulted as feature/UX
references but are not contained in this archive. Optional Questie/OpenMap
public-API adapter modules are part of the Waffles Gang source and do not
copy those projects' codebases or assets.


## v4.2 Questie companion
Original WafflesGang code adds a noninteractive background behind Questie_BaseFrame without copying Questie source or data. Source compatibility checked against user-provided Queestie(1).zip. Questie itself remains separately installed. The custom navigation asset GuideNavArrow.blp was directly copied from the user-provided WafflesGangGuides/Skins/minimaparrow-player.blp and is credited in GUIDE-ARROW-ATTRIBUTION.md.


## v4.3.0 threat connector review

Starting point: WafflesGang-Forever-v4.2.0-Questie-First-Tracker.zip, supplied in the current conversation. Reviewed user-provided `threat classic(1).zip`, particularly `Details_TinyThreat/Details_TinyThreat.lua` and Details! `core/plugins.lua`, to determine the installed plugin ID (`Details_TinyThreat`) and plugin frame lifecycle. New code: `TinyThreatCompanion.lua`; changes: `Threat.lua`, `Studio.lua`, all three TOCs, documentation. The adapter references the running Details! plugin; no code or image assets from the third-party archive are embedded. The Waffle fallback implementation is retained unchanged except for conditional visibility.
