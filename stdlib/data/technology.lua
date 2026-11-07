--- Technology
-- @classmod Data.Technology

local Data = require('__stdlib2__/stdlib/data/data')

local Technology = {
    __class = 'Technology',
    __index = Data,
}

function Technology:__call(tech)
    return self:get(tech, 'technology')
end
setmetatable(Technology, Technology)

--- Add an effect to a technology, or add a technology unlock to a recipe.
-- <p>Called on a technology `effect` may be a recipe name (default `unlock-recipe`), or a full effect table
-- of any type, which is appended as is. Called on a recipe, `effect` is the name (or an array of names) of the
-- technology that unlocks the recipe; the first valid one is used.
-- @tparam string|table effect
-- @tparam[opt='unlock-recipe'] string unlock_type
-- @treturn self
function Technology:add_effect(effect, unlock_type)
    assert(effect)

    local add_unlock = function(technology, name)
        technology.effects = technology.effects or {}
        local effects = technology.effects
        effects[#effects + 1] = {
            type = 'unlock-recipe',
            recipe = name
        }
    end

    if self:is_valid('technology') then
        local Recipe = require('__stdlib2__/stdlib/data/recipe')
        if type(effect) == 'table' and effect.type and effect.type ~= 'unlock-recipe' then
            -- any other effect type is appended as is
            self.effects = self.effects or {}
            self.effects[#self.effects + 1] = effect
        else
            unlock_type = unlock_type or (type(effect) == 'table' and effect.type) or 'unlock-recipe'
            local r_name = type(effect) == 'table' and (effect.recipe or effect.name) or effect
            if unlock_type == 'unlock-recipe' and Recipe(r_name):is_valid() then
                add_unlock(self, r_name)
            end
        end
    elseif self:is_valid('recipe') then
        -- Convert to array and return first valid tech
        local techs = type(effect) == 'string' and { effect } or effect
        for _, name in pairs(techs) do
            local tech = Technology(name)
            if tech:is_valid('technology') then
                self:set_enabled(false)
                add_unlock(tech, self.name)
                break
            end
        end
    end

    return self
end

-- Does the effect match the unlock type and name?
local function effect_matches(effect, unlock_type, name)
    if effect.type ~= unlock_type then
        return false
    end
    if name == nil then
        return true
    end
    return effect.recipe == name or effect.item == name or effect.space_location == name or effect.quality == name
        or effect.ammo_category == name or effect.turret_id == name
end

local function remove_effects(effects, unlock_type, name)
    for index = #(effects or {}), 1, -1 do
        if effect_matches(effects[index], unlock_type, name) then
            table.remove(effects, index)
        end
    end
end

--- Remove effects.
-- <p>Called on a technology: removes every effect of `unlock_type` (default `unlock-recipe`) whose name matches `name`
-- (the recipe of an `unlock-recipe`, otherwise the item, space location or quality), or all effects of that type when
-- `name` is nil.
-- <p>Called on a recipe: removes the unlock of this recipe from the technology `tech_name`, or from every technology.
-- @tparam[opt] string tech_name the technology to remove the recipe unlock from (recipes only)
-- @tparam[opt='unlock-recipe'] string unlock_type
-- @tparam[opt] string name the effect name to remove (technologies only)
-- @treturn self
function Technology:remove_effect(tech_name, unlock_type, name)
    if self:is_valid('technology') then
        remove_effects(self.effects, unlock_type or 'unlock-recipe', name)
    elseif self:is_valid('recipe') then
        if tech_name then
            local tech = Technology(tech_name)
            if tech:is_valid() then
                remove_effects(tech.effects, 'unlock-recipe', self.name)
            end
        else
            for _, tech in pairs(data.raw['technology']) do
                remove_effects(tech.effects, 'unlock-recipe', self.name)
            end
        end
    end
    return self
end

-- Technologies with a research_trigger have no unit.
local function has_unit(self, action)
    if self.unit then
        return true
    end
    log('Technology ' .. tostring(self.name) .. ' has no unit (it uses research_trigger), cannot ' .. action)
    return false
end

-- Read an ingredient in either {name, count} or {type=, name=, amount=} shape
local function pack_name(ing)
    return ing.name or ing[1]
end

--- Add a science pack to the technology unit. Does nothing for technologies that use a research_trigger.
-- @tparam string|table new_pack the pack name, or `{name, count}`, or `{type=, name=, amount=}`
-- @tparam[opt=1] number count
-- @treturn self
function Technology:add_pack(new_pack, count)
    if self:is_valid('technology') and has_unit(self, 'add a pack') then
        local Item = require('__stdlib2__/stdlib/data/item')
        if type(new_pack) == 'table' then
            count = new_pack.amount or new_pack[2] or 1
            new_pack = pack_name(new_pack)
        elseif type(new_pack) == 'string' then
            count = count or 1
        else
            error('new_pack must be a table or string')
        end

        if Item(new_pack):is_valid() then
            self.unit.ingredients = self.unit.ingredients or {}
            local ing = self.unit.ingredients
            ing[#ing + 1] = { new_pack, count }
        end
    end
    return self
end

--- Remove a science pack from the technology unit.
-- @tparam string pack
-- @treturn self
function Technology:remove_pack(pack)
    if self:is_valid('technology') and has_unit(self, 'remove a pack') then
        local ings = self.unit.ingredients
        for i = #(ings or {}), 1, -1 do
            if pack_name(ings[i]) == pack then
                table.remove(ings, i)
                break
            end
        end
    end
    return self
end

--- Replace a science pack of the technology unit.
-- @tparam string old_pack
-- @tparam string new_pack
-- @tparam[opt] number count
-- @treturn self
function Technology:replace_pack(old_pack, new_pack, count)
    if self:is_valid('technology') and has_unit(self, 'replace a pack') then
        local ings = self.unit.ingredients
        for _, ing in pairs(ings or {}) do
            if pack_name(ing) == old_pack then
                local old_count = ing.amount or ing[2]
                for k in pairs(ing) do ing[k] = nil end
                ing[1] = new_pack
                ing[2] = count or old_count or 1
                break
            end
        end
    end
    return self
end

--- Use a research trigger instead of a unit.
-- @tparam table trigger the TechnologyTrigger
-- @treturn self
function Technology:set_research_trigger(trigger)
    if self:is_valid('technology') then
        self.research_trigger = trigger
        self.unit = nil
    end
    return self
end

--- Use a unit instead of a research trigger.
-- @tparam table unit the TechnologyUnit
-- @treturn self
function Technology:set_unit(unit)
    if self:is_valid('technology') then
        self.unit = unit
        self.research_trigger = nil
    end
    return self
end

function Technology:add_prereq(tech_name)
    if self:is_valid('technology') and Technology(tech_name):is_valid() then
        self.prerequisites = self.prerequisites or {}
        local pre = self.prerequisites
        for _, existing in pairs(pre) do
            if existing == tech_name then
                return self
            end
        end

        pre[#pre + 1] = tech_name
    end
    return self
end

function Technology:remove_prereq(tech_name)
    if self:is_valid('technology') then
        local pre = self.prerequisites or {}
        for i = #pre, 1, -1 do
            if pre[i] == tech_name then
                table.remove(pre, i)
                break
            end
        end
        if #pre == 0 then
            self.prerequisites = nil
        end
    end
    return self
end

return Technology
