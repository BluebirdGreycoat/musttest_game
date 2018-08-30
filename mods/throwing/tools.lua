if not DISABLE_WOODEN_BOW then
	throwing_register_bow ('bow_wood', 'Wooden Bow', {x=1, y=1, z=0.5}, 11, 0.8, 50, false, {
			{'', 'default:stick', ''},
			{'farming:string', '', 'default:stick'},
			{'', 'default:stick', ''},
		})
end

if not DISABLE_LONGBOW then
	throwing_register_bow ('longbow', 'Longbow', {x=1, y=2.5, z=0.5}, 17, 1.8, 100, false, {
			{'farming:string', 'group:wood', ''},
			{'farming:string', '', 'group:wood'},
			{'farming:string', 'group:wood', ''},
		})
end

if not DISABLE_COMPOSITE_BOW then
	throwing_register_bow ('bow_composite', 'Composite Bow', {x=1, y=1.4, z=0.5}, 17, 1, 150, false, {
			{'farming:string', 'group:wood', ''},
			{'farming:string', '', 'stainless_steel:ingot'},
			{'farming:string', 'group:wood', ''},
		})
end

if not DISABLE_STEEL_BOW then
	throwing_register_bow ('bow_steel', 'Steel Bow', {x=1, y=1.4, z=0.5}, 20, 1.3, 250, false, {
			{'farming:string', 'stainless_steel:ingot', ''},
			{'farming:string', '', 'stainless_steel:ingot'},
			{'farming:string', 'stainless_steel:ingot', ''},
		})
end

if not DISABLE_ROYAL_BOW then
	throwing_register_bow ('bow_royal', 'Royal Bow', {x=1, y=1.5, z=0.5}, 18, 1.4, 750, false, {
			{'farming:string', 'group:wood', 'default:diamond'},
			{'farming:string', '', 'default:gold_ingot'},
			{'farming:string', 'group:wood', 'default:diamond'},
		})
end

if not DISABLE_CROSSBOW then
	throwing_register_bow ('crossbow', 'Crossbow', {x=1, y=1.3, z=0.5}, 28, 5, 80, true, {
			{'group:wood', 'farming:string', ''},
			{'stainless_steel:ingot', 'farming:string', 'group:wood'},
			{'group:wood', 'farming:string', ''},
		})
end

if not DISABLE_ARBALEST then
	throwing_register_bow ('arbalest', 'Arbalest', {x=1, y=1.3, z=0.5}, 35, 7.5, 120, true, {
			{'stainless_steel:ingot', 'farming:string', 'default:stick'},
			{'stainless_steel:ingot', 'farming:string', 'stainless_steel:ingot'},
			{'stainless_steel:ingot', 'farming:string', 'default:stick'},
		})
end

if not DISABLE_AUTOMATED_ARBALEST then
	throwing_register_bow ('arbalest_auto', 'Automated Arbalest', {x=1, y=1.3, z=0.5}, 40, 3.5, 60, true, {
			{'stainless_steel:ingot', 'farming:string', 'default:mese_crystal'},
			{'stainless_steel:ingot', 'farming:string', 'stainless_steel:ingot'},
			{'stainless_steel:ingot', 'farming:string', 'default:mese_crystal'},
		})
end
