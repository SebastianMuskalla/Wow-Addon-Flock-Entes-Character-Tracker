WoW Addon: Flock - Ente's Character Tracker
===========================================

Flock - Ente's Character Tracker is a heavily modified fork of Altruis Alt Manager ([curseforge](https://www.curseforge.com/wow/addons/altruis-alt-manager), [GitHub](https://github.com/shredxt/AltruisAltManager)).
It is meant to allow you to see on a single screen the progress of all of your max level characters.

Usage
-----

Type `/flock` in-game.

Configuration
-------------

This addon has **no** in-game configuration.

Instead, the file [Rows.lua](Rows.lua) needs to be modified to add / remove entries from the table.

To add a new entry
- create a copy of the appropriate template in [Rows.lua](Rows.lua),
- configure this copy appropriately as described by the comments
- insert it into the `ROWS` array at the bottom of the file.

Rows that should be shown once for the whole table can be inserted into `GLOBAL_ROWS` instead.
Global rows are displayed at the bottom of the table and span the full table width.

Additionally, a few basic settings can be configured at the beginning of [FlockEntesCharacterTracker.lua](FlockEntesCharacterTracker.lua).

License
-------

Copyright 2026 Sebastian Muskalla

This project contains free and open-source software.

Flock - Ente's Character Tracker is based on Altruis Alt Manager ([curseforge](https://www.curseforge.com/wow/addons/altruis-alt-manager), [GitHub](https://github.com/shredxt/AltruisAltManager)), copyright Shredxt, licensed under the [GPLv3 (GNU General Public License version 3)](GPLv3.LICENSE).

The included font [Source Sans](fonts/SourceSans3-Semibold.ttf) is licensed under the [SIL OFL 1.1](OFL.LICENSE) with the Reserved Font Name "Source", see [OFL.LICENSE](OFL.LICENSE).

The rest of the project is licensed under the [GPLv3 (GNU General Public License version 3)](GPLv3.LICENSE) see [GPLv3.LICENSE](GPLv3.LICENSE).
