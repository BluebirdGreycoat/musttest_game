Minetest mod: droplift

                ** May 29 -- Major changes -- Update strongly recommended **

==== Droplift ====

Droplift lifts drops out of solid blocks.
This mod adds no in-world items or blocks, just additional physics.

Droplift also prevents buried drops from sinking below the floor
when the game reloads.

A simple API allows it to cooperate with other mods.

Goals:
* Controlled item elevation through blocks, so it can be used reliably
  in plans and contraptions.
* As computationally 'nice' as possible.
* In balance with game play and physics. Generally handy and fun,
  but not excessive or distracting.

Design choices:
* Moves by whole nodes only.
* Treats all nodes as whole cubes.
* Lifts at about 1 m/s.


----

Copyright (C) 2016 Aftermoth, Zolan Davis

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation; either version 2.1 of the License,
or (at your option) version 3 of the License.

http://www.gnu.org/licenses/lgpl-2.1.html

