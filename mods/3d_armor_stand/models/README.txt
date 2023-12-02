3d_armor_entity.blend has been created from the existing .OBJ files:

- 3d_armor_stand.obj
- 3d_armor_entity.obj

The stand object has been imported for visual reference only: it is scaled up
by 10x, to match the entity object's own scale. Lights and textures are also
there for previewing purposes only.

The shield display has been added as a separate object ("Shield") such that it
can be freely repositioned.

To create the .OBJ entity model file for Minetest, the shield object ("Shield")
and the armor entity object ("Player_Cube") have to be joined first, such that
the resulting .OBJ file created by the exporter will contain a single object.
