READ V4.1-READ-ME-FIRST.txt FIRST for the new Adventure HUD, threat rows, branded arrow and integration settings.
READ V4.0-TACTICAL-MINIMAL-QUESTS.txt FIRST FOR v4.0.0.
This update prioritizes the player-supplied Tactical screenshot critique. See the Studio Tactical Deck, Field Intel and Finish sections; /wg tools opens deep options.

READ V3.9.9-FOREVERUI-TACTICAL-FIRST.txt FIRST for the latest Tactical overhaul and searchable deep settings.
Read CREDITS-AND-THIRD-PARTY-NOTICES.md for source and sharing terms.

READ V3.9.1-QUEST-TRACKER-FIX.txt FIRST for the latest Questie-inspired tracker rebuild.

READ V3.6-READ-ME-FIRST.txt FIRST for the latest four-style, dual threat and OpenMap integration test build.
See CREDITS-AND-THIRD-PARTY-NOTICES.md for author and licensing notes.

READ V3.5-STUDIO-README.txt FIRST for the latest unified editor and Questie integration.
See CREDITS-AND-THIRD-PARTY-NOTICES.md for author and licensing notes.

READ V3.5-STUDIO-README.txt FIRST for the latest unified editor and Questie integration.
See CREDITS-AND-THIRD-PARTY-NOTICES.md for author and licensing notes.

READ V3.5-STUDIO-README.txt FIRST for the latest unified editor and Questie integration.
See CREDITS-AND-THIRD-PARTY-NOTICES.md for author and licensing notes.

Read V3.2-GUILD-FOCUS-READ-ME-FIRST.txt first for the latest guild changes.
Read V3.0-READ-ME-FIRST.txt for the latest B key, XP bar, Gear Advisor fixes.

WAFFLES GANG v3.0.0 — GUILD EDITION / WOW FOREVER
=================================================

INSTALLATION
1. Exit the game, then back up your existing WafflesGang folder and
   WTF/Account/<account>/SavedVariables/WafflesGang.lua.
2. Extract WafflesGang directly inside the active WoW: Forever Interface/AddOns
   directory. Do not nest WafflesGang inside another WafflesGang folder.
3. Restart, enable the addon, and use /wg or /wg setup.
4. Turn on script error reporting with /console scriptErrors 1 if problems occur.

ORIGINAL v2.9 THEME OVERHAUL
* Pantry keybinding corrected for both key-down and key-up click variants.
  Press B once to open and once again to close. If an older recovery setting
  disabled the override, v2.9 enables it once; thereafter the Layout switch
  can turn it off again. Use /wg bags as a fallback when chat has keyboard focus.
* Full visual treatment: Waffles, Cake, Pie, Pizza, Samurai.
  Cake: frosting details and berry/cream accents.
  Pie: lattice crust engraving and warm copper/cherry tones.
  Pizza: brick-oven details, cheese gold and tomato/pepperoni tones.
  Samurai: layered armor engraving, lacquer red / indigo / jade / imperial gold.
  Each theme has four coordinated, complete colorways, including backgrounds,
  panel fills, borders, buttons, titles and chat accent when enabled.
  Choosing a new theme retains the last colorway you picked for that theme.
* New high-resolution themed crests in the same 256x256 TGA format as the
  original art, plus theme-specific panel and header textures.
* Gear Advisor detects the player's current class and lists only that
  class's talent trees (nine Forever classes, 27 trees). AUTO selects the
  tree with most invested points when the client exposes that data, otherwise
  uses the active specialization, then the first tree as last resort.
  You may select any of your class's three trees explicitly. Stat-based
  percentage improvements are estimates, not simulated DPS or healing gains.
* Guild Manager uses independent high-contrast member rows, fixed columns,
  online status labels, class name colors, dark text inputs and selected-row
  indicators. Guild Invite and Invite to Party remain available.
* Saves visual theme and its per-theme colors in the SOLO/GROUP/RAID profiles.
* All existing Pantry, recipe-sharing, bag sorting, action bars/cooldowns,
  celebration, XP, quest-reward, chat, and automation modules retained.

SHORTCUTS
/wg            Dashboard
/wg bags       Toggle Waffle Pantry; B works when the override is enabled
/wg appearance Select a theme and one of its four coordinated colorways
/wg gear       Class and talent-tree gear recommendations
/wg guild      Guild roster and group invitation tools
/wg settings   Search and toggle all features
/wg layout     Move windows, configure the B override, or reset positions
/wg edit       Move HUD elements
/wg recover    Restore Blizzard action bars, bag bar and unit frames

IMPORTANT LIMITATIONS
- No real WoW: Forever client is available in this build environment.
  Lua parsing and offline simulated UI/interaction tests pass, but live
  keybinding conflicts, secure item clicks and combat restrictions remain
  subject to in-game verification.
- The gear scoring heuristics do not model weapon DPS, set bonuses, proc effects,
  spell synergies or a complete talent rotation, so a positive percent is NOT
  a promise of improved actual performance.
- Profession/recipe sharing requires other guild members using Waffles Gang
  with sharing enabled; the addon does not inspect private recipes remotely.
- If the override does not respond while an edit box has focus, press Escape
  to unfocus it. Conflicting keybind addons may need their own B override disabled.
