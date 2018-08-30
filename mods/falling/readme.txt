This mod makes it impossible for griefers to successfully dirt-bomb other players'
protected wheat, cotton, flowers, etc. For reference: dirt-bombing is done by building a
bridge over the target's land and dropping falling nodes off it.

This mod fixes an issue that occurs when players drop falling nodes onto land belonging to
(and protected by) other players. Normally, falling nodes will destroy non-walkable nodes
and liquids, even when protected. This mod reimplements the falling code that exists in
the MineTest core, and causes falling nodes to be dropped as items if they fall on top of
non-walkable nodes which are protected.

This mod is a hack. It works by overriding the "__builtin:falling_node" entity and
changing its behavior. This mod will become redundant if or when the builtin code is ever
updated to respect protection; should that happen, you should remove this mod.

This mod is not guaranteed to work. It relies on behavior which is not strictly documented;
namely, the ability to override builtin entities.
