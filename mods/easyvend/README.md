# Easy Vending Machines [`easyvend`]
Version: 0.3.0

Adds vending and depositing machines which allow to buy and sell items from other players.

Help is included as help entry for Item Documentation [`doc_items`].

## Converting machines from `vendor` mod (experimental)
This mod is able to automatically transform the vending and depositing
machines from Bad\_Command_'s Vending machines [`vendor`] mod on loading
and turn them into the new machines from `easyvend`. This is useful if
you want to switch a world from `vendor` to `easyvend`.

**WARNING**: This feature is experimental! It is advised to backup your world
before doing this. This feature is also incomplete; items are currently
**not** transformed in the process.

### Conversion process
To transform all nodes from the `vendor` mod, disable the `vendor` mod (if
it is not already disabled), enable the setting `easyvend_convert_vendor`
and start or restart the game.

Now all nodes from the `vendor` mod will be replaced  with `easyvend` ones.

If you run a server, you should inform players of this change because a few
machines might need a reconfiguration.

### Details
The machine configuration will be kept in the process and the machines will
stay in operation provided their configuration is valid. The mod tries to
keep as many machines in operation as possible. Machines with very high values
(item count or price) might be disabled because they exceed limits and must
be reconfigured by their owners. Most machines which worked before will likely
stay in operation afterwards.

## Licenses
- Code: LGPL 2.1. Forked from mod “Vending Machines” [vendor] by Bad_Command_.
- Sounds: CC-BY 3.0/CC-BY-SA 3.0/GPL 3.0/GPL 2.0
- Textures: MIT License 
