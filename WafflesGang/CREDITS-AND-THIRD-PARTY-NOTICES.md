# Waffles Gang: Credits and third-party notices

## Project credits

- **Rain**: original Waffles Gang UI, core project architecture, theme art, original WaffleLogo and the v3.0 Guild Edition foundation.
- **Waffles Gang community**: ideas, testing, bug reports, and ongoing development feedback.
- **Later Waffles Gang integration work**: simplified Waffle Studio controls, quest-journal bridge, combat settings, four independently selectable UI styles and Modern-first visual revision, independent dual threat-meter controls, optional OpenMap API bridge, and related fixes.

No separate license was found in Rain's supplied Waffles Gang v3.0 archive. **Do not assume an open-source license or permission to republish Rain's original code/art without his approval.** The developer should confirm the rights and preferred attribution before sharing outside the authorized community.

## Third-party assets and referenced projects

| Project | Role | Code/assets included? | Notes |
|---|---|---|---|
| WafflesGangGuides (user-provided guide pack) | Supplies `GuideNavArrow.blp`, originally `Skins/minimaparrow-player.blp` | **One asset** | Asset provenance: user-provided WafflesGangGuides ZIP, a branded adaptation of a guide viewer attributed to Zygor Guides. See `GUIDE-ARROW-ATTRIBUTION.md`; original authors' rights remain in force. |
| [Questie](https://github.com/Questie/Questie) | Optional independent quest engine, map markers and stable public callbacks | **No** | API used: `Questie.API.RegisterOnReady`, `Questie.API.RegisterForQuestUpdates`. Questie and QuestieDB are **not included**. Questie's `LICENSE.md` describes a GPLv3 effort **plus uncertain rights for some historical contributors**; do not treat the whole source archive as unambiguously GPL. Its trademarked name/logo are not licensed for forks. |
| [OpenMap](https://www.curseforge.com/wow/addons/openmap) | Optional independent seamless world map and supported OpenMapAPI integration | **No** | Author: jigrobbulus / OpenMap team. API documented at https://github.com/openmap-world/openmap/blob/main/docs/api.md; MIT-licensed code, with separate Blizzard-origin artwork. OpenMap is NOT bundled. |
| [EllesmereUI](https://www.curseforge.com/wow/addons/ellesmereui) | High-level inspiration for clear modern control organization, moving/resizing, and modular UX | **No** | Uploaded source is all-rights-reserved. No source, third-party assets, icons, or textures from EllesmereUI used. This is not a fork or rebrand and not affiliated. |
| [GW2 UI](https://www.curseforge.com/wow/addons/gw2-ui) | High-level inspiration for an immersive adventure-oriented art direction | **No** | No GW2 UI source, icons, textures or proprietary artwork copied. |
| [QuestieDB](https://github.com/Questie/QuestieDB) | Questie quest data, separately installed by players | **No** | Its own licensing and historical-provenance notices remain with the external addon. |
| Details! / Tiny Threat | Reference for threat-meter behavior and combat UI | **No** | The uploaded Details! archive contains a root LICENSE saying `All rights reserved`; no source, icon, localization or framework from it was copied into this release. |
| ThreatClassic | Reference material provided by user for threat-system planning | **No** | No third-party source copied. |
| Clique, Capping, TomTom, HandyNotes, What's Training, GTFO, DBM, Baganator | Independently installed tools, optional settings-directory or feature planning references | **No** | Their source code and artwork are not bundled. The Tools page only detects installed addons and prepares their user-facing commands. |
| Grid2, Plater, Shadowed Unit Frames, WeakAuras, ElvUI | High-level UI/UX references and feature comparison only | **No** | These addons, their assets and their libraries are not included. |

The Waffles Gang addon uses Blizzard's game API and original code for its controls. Reference to a project is not a claim of affiliation or endorsement.

## Sharing and licensing guidance

A private Discord channel does not automatically exempt redistributing other people's code from license obligations. Keep this attribution file with shared copies. **If future versions actually bundle GPL-covered code**, include the corresponding copyright notices, applicable license text, and complete source as required by that license, and assess compatibility with other code in the bundle. This preview deliberately avoids bundling Questie or Details! source/assets. The previously imported guide-arrow asset is identified above, with its provenance and original attribution preserved.

These notes describe the current package and are not a legal opinion.


## ForeverUI v4.3.0: Details! Tiny Threat companion

The optional **Details! Tiny Threat** plugin (part of **Details! Damage Meter** by its respective authors) supplies its own real-time threat data, bars, sorting, and visual semantics. ForeverUI adds a separate visual layer and controls which threat display is visible. No Details!/Tiny Threat source files, artwork, or threat-calculation routines are redistributed in this ZIP. Users install and configure Details! + Details_TinyThreat separately.
