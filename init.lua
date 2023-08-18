-- SPDX-FileCopyrightText: 2023 DS
--
-- SPDX-License-Identifier: Apache-2.0

local nodebox = {
	type = "fixed",
	fixed = {-8/16, -8/16, -8/16, 8/16, -7/16, 8/16},
}

local function get_nand_output_rules(node)
	local param2 = node.param2 % 4
	if param2 == 0 then
		return {vector.new(-1, 0,  0)}
	elseif param2 == 1 then
		return {vector.new( 0, 0,  1)}
	elseif param2 == 2 then
		return {vector.new( 1, 0,  0)}
	elseif param2 == 3 then
		return {vector.new( 0, 0, -1)}
	end
end

local function get_and_output_rules(node)
	local param2 = node.param2 % 4
	if param2 == 0 then
		return {vector.new( 1, 0,  0)}
	elseif param2 == 1 then
		return {vector.new( 0, 0, -1)}
	elseif param2 == 2 then
		return {vector.new(-1, 0,  0)}
	elseif param2 == 3 then
		return {vector.new( 0, 0,  1)}
	end
end

local function get_input_rules(node)
	if node.param2 % 2 == 0 then
		return {vector.new(0, 0, -1), vector.new(0, 0, 1)}
	else
		return {vector.new(-1, 0, 0), vector.new(1, 0, 0)}
	end
end

-- turn the gate on or off
local function toggle(pos, node, state)
	if mesecon.do_overheat(pos) then
		-- it overheated
		minetest.remove_node(pos)
		mesecon.receptor_off(pos, mesecon.rules.flat)
		minetest.add_item(pos, "anand_gate:anand_off")
		return
	end

	local nand_rules = get_nand_output_rules(node)
	local and_rules = get_and_output_rules(node)

	if state then
		node.name = "anand_gate:anand_on"
		minetest.swap_node(pos, node)
		mesecon.receptor_off(pos, nand_rules)
		mesecon.receptor_on(pos, and_rules)
	else
		node.name = "anand_gate:anand_off"
		minetest.swap_node(pos, node)
		mesecon.receptor_on(pos, nand_rules)
		mesecon.receptor_off(pos, and_rules)
	end
end

local function update_off_gate(pos, node)
	local rules = get_input_rules(node)
	local input1 = mesecon.is_powered(pos, rules[1])
	local input2 = mesecon.is_powered(pos, rules[2])
	if not input1 or not input2 then
		-- it stays off
		return
	end
	-- turn it on
	toggle(pos, node, true)
end

local function update_on_gate(pos, node)
	local rules = get_input_rules(node)
	local input1 = mesecon.is_powered(pos, rules[1])
	local input2 = mesecon.is_powered(pos, rules[2])
	if input1 and input2 then
		-- it stays on
		return
	end
	-- turn it off
	toggle(pos, node, false)
end

mesecon.register_node("anand_gate:anand", {
	description = "ANAND Gate",
	inventory_image = "anand_gate_anand_off.png",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	drawtype = "nodebox",
	drop = "anand_gate:anand_off",
	selection_box = nodebox,
	node_box = nodebox,
	sounds = default.node_sound_stone_defaults(),
	after_dig_node = mesecon.do_cooldown,
},{
	tiles = {"jeija_microcontroller_bottom.png^anand_gate_anand_off.png"},
	groups = {dig_immediate = 2, overheat = 1},
	mesecons = {receptor = {
		state = mesecon.state.on,
		rules = get_nand_output_rules,
	}, effector = {
		rules = mesecon.rules.flat,
		action_change = update_off_gate,
	}}
},{
	tiles = {"jeija_microcontroller_bottom.png^anand_gate_anand_on.png"},
	groups = {dig_immediate = 2, not_in_creative_inventory = 1, overheat = 1},
	mesecons = {receptor = {
		state = mesecon.state.on,
		rules = get_and_output_rules,
	}, effector = {
		rules = mesecon.rules.flat,
		action_change = update_on_gate,
	}}
})

minetest.register_craft({
	type = "shapeless",
	output = "anand_gate:anand_off",
	recipe = {"mesecons_gates:and_off", "mesecons_gates:nand_off"},
})
