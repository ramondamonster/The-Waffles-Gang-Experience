Waffles Gang v3.9.6 - Questie Navigation Bridge Fix (testing preview)

What changed
- Waffle navigation now requests the same nearest quest objective that Questie's
  tracker selects through TrackerUtils.SetQuestTomTomTarget.
- Waffle reads the resulting Questie TomTom waypoint ID (map, x, y), rather
  than treating a successful Questie call as though it returned coordinates.
- The Waffle arrow uses TomTom's world-space direction/distance APIs where
  available and falls back to native/Questie objective coordinates when not.
- When Questie updates the waypoint for the selected Waffle quest, the Waffle
  arrow follows the new destination. Invalidated waypoints no longer show a
  stale route.
- Clearing Waffle navigation does not remove a waypoint owned by Questie.
- No Questie, TomTom or other third-party code or artwork is bundled.

To install
1. Exit WoW completely. Back up your AddOns/WafflesGang and WTF folders.
2. Move the existing AddOns/WafflesGang folder outside AddOns.
3. Extract this ZIP into Interface/AddOns so the TOC is at
   Interface/AddOns/WafflesGang/WafflesGang_Forever.toc.
4. Keep Questie, QuestieDB and TomTom separately installed and enabled.
5. Enter the game and /reload if necessary.

To test
1. Make sure Waffle Quests and its optional arrow are enabled in Waffle Studio.
2. Click a quest title in Waffle Tracker, e.g. Gold Dust Exchange.
3. Waffle arrow should display a distance and turn as you turn your character.
4. If Questie reroutes the selected quest objective, Waffle arrow should update.
5. Try a quest without a valid waypoint: the arrow should state that no route
   is available, not invent a direction.

Note: Questie's public API only exposes lifecycle and quest update callbacks,
not objective waypoint coordinates. The route selection uses Questie's private
TrackerUtils module behind pcall and may require adjustment when Questie changes.
Tests were simulated using the uploaded Questie and TomTom implementations.
This has not yet been verified in the actual WoW Forever client.
