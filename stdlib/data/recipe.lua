--- Recipe class
-- @classmod Data.Recipe

local Data = require('__stdlib2__/stdlib/data/data')
local Table = require('__stdlib2__/stdlib/utils/table')
local Deprecate = require('__stdlib2__/stdlib/utils/deprecate')

local Recipe = {
    __class = 'Recipe',
    __index = Data,
}

function Recipe:__call(recipe)
    local new = self:get(recipe, 'recipe')
    -- rawset(new, 'Ingredients', {})
    -- rawset(new, 'Results', {})
    return new
end
setmetatable(Recipe, Recipe)

-- Factorio 2.x recipes have no normal/expensive versions. Arguments that used to select the expensive
-- version are accepted and ignored.
local function ignore_expensive(expensive)
    if expensive ~= nil then
        Deprecate.warn('recipe-expensive', 'expensive recipes do not exist in 2.x; argument ignored')
    end
end

-- Returns the prototype type ('item' or 'fluid') used in ingredients and results for a name.
local function ingredient_type(name)
    if data.raw.fluid and data.raw.fluid[name] then
        return 'fluid'
    end
    return 'item'
end

-- Convert a legacy value ('name', {'name', count}, {name = ..., amount = ...}) to a 2.x table without validation.
local function to_table(value, count)
    if type(value) == 'string' then
        return { type = ingredient_type(value), name = value, amount = count or 1 }
    elseif type(value) == 'table' then
        if value.name then
            local new = Table.deepcopy(value)
            new.type = new.type or ingredient_type(new.name)
            new.amount = new.amount or count
            return new
        elseif value[1] then
            return { type = ingredient_type(value[1]), name = value[1], amount = value[2] or count or 1 }
        end
    end
end

-- Returns a formated ingredient or product table: {type, name, amount} or {type, name, amount_min, amount_max, probability}
-- Returns nil (and logs) if the item or fluid does not exist.
local function format(ingredient, count)
    local Item = require('__stdlib2__/stdlib/data/item')
    if type(ingredient) == 'table' and ingredient.valid and ingredient.is_valid and ingredient:is_valid() then
        ingredient = ingredient.name
    end
    local object = to_table(ingredient, count)
    if object then
        if not Item(object.name):is_valid() then
            return nil
        end
        if not object.amount and not (object.amount_min and object.amount_max) then
            error('Result table requires amount, or amount_min and amount_max')
        end
    end
    return object
end

-- Remove every ingredient or result with the given name (string or formatted table).
local function remove_named(list, name)
    name = type(name) == 'table' and (name.name or name[1]) or name
    local found = false
    for i = #(list or {}), 1, -1 do
        local entry = list[i]
        if entry[1] == name or entry.name == name then
            table.remove(list, i) -- can no longer set entry to nil
            found = true
        end
    end
    return found
end

-- Replace an ingredient.
-- @tparam table ingredients Ingredients table
-- @tparam string find ingredient to replace
-- @tparam concepts.ingredient replace
-- @tparam boolean replace_name_only Don't replace amounts
local function replace_ingredient(ingredients, find, replace, replace_name_only)
    for i, ingredient in pairs(ingredients or {}) do
        if ingredient[1] == find or ingredient.name == find then
            if replace_name_only then
                replace.amount = ingredient[2] or ingredient.amount
            end
            ingredients[i] = replace
            return true
        end
    end
end

--- Add an ingredient to a recipe.
-- @tparam string|Concepts.ingredient normal
-- @tparam[opt] any expensive ignored, there are no expensive recipes in 2.x
-- @treturn Recipe
function Recipe:add_ingredient(normal, expensive)
    if self:is_valid() then
        ignore_expensive(expensive)
        normal = format(normal)
        if normal then
            self.ingredients = self.ingredients or {}
            self.ingredients[#self.ingredients + 1] = normal
        end
    end
    return self
end
Recipe.add_ing = Recipe.add_ingredient

--- Remove every ingredient with the given name.
-- @tparam string|Concepts.ingredient normal
-- @tparam[opt] any expensive ignored, there are no expensive recipes in 2.x
-- @treturn Recipe
function Recipe:remove_ingredient(normal, expensive)
    if self:is_valid() then
        ignore_expensive(expensive)
        remove_named(self.ingredients, normal)
    end
    return self
end
Recipe.rem_ing = Recipe.remove_ingredient

--- Replace one ingredient with another.
-- @tparam string replace
-- @tparam string|ingredient normal
-- @tparam[opt] any expensive ignored, there are no expensive recipes in 2.x
function Recipe:replace_ingredient(replace, normal, expensive)
    assert(replace, 'Missing recipe to replace')
    if self:is_valid() then
        ignore_expensive(expensive)
        local n_string = type(normal) == 'string'
        normal = format(normal)
        if normal then
            replace_ingredient(self.ingredients, replace, normal, n_string)
        end
    end
    return self
end
Recipe.rep_ing = Recipe.replace_ingredient

-- Currently does no checking
function Recipe:clear_ingredients()
    if self:is_valid() and self.ingredients then
        self.ingredients = {}
    end
    return self
end

--- Deprecated, there are no expensive recipes in Factorio 2.x. Does nothing.
-- @tparam[opt] number expensive_energy ignored
-- @treturn self
function Recipe:make_difficult(expensive_energy) -- luacheck: ignore expensive_energy
    Deprecate.warn('recipe-make-difficult', 'Recipe:make_difficult() does nothing, expensive recipes do not exist in 2.x')
    return self
end

local function recipe_categories(self)
    return self.categories or (self.category and { self.category }) or { 'crafting' }
end

local function category_exists(name)
    return data.raw['recipe-category'] and data.raw['recipe-category'][name] and true or false
end

--- Change the recipe category, replacing all categories of the recipe by this one.
-- @tparam string category_name The new crafting category
-- @treturn self
function Recipe:change_category(category_name)
    if self:is_valid() then
        if category_exists(category_name) then
            self.categories = { category_name }
            self.category = nil
        else
            log('Recipe category ' .. tostring(category_name) .. ' does not exist')
        end
    end
    return self
end
Recipe.set_category = Recipe.change_category

--- Add a crafting category to the recipe.
-- @tparam string category_name
-- @treturn self
function Recipe:add_category(category_name)
    if self:is_valid() then
        if category_exists(category_name) then
            local categories = Table.deepcopy(recipe_categories(self))
            if not Table.any(categories, function(v) return v == category_name end) then
                categories[#categories + 1] = category_name
            end
            self.categories = categories
            self.category = nil
        else
            log('Recipe category ' .. tostring(category_name) .. ' does not exist')
        end
    end
    return self
end

--- Remove a crafting category from the recipe. The last category can not be removed.
-- @tparam string category_name
-- @treturn self
function Recipe:remove_category(category_name)
    if self:is_valid() then
        local categories = Table.deepcopy(recipe_categories(self))
        for i = #categories, 1, -1 do
            if categories[i] == category_name then
                table.remove(categories, i)
            end
        end
        if #categories > 0 then
            self.categories = categories
            self.category = nil
        else
            log('Recipe ' .. self.name .. ' must keep at least one category')
        end
    end
    return self
end

--- Does the recipe have the crafting category? A recipe without categories is in `crafting`.
-- @tparam string category_name
-- @treturn boolean
function Recipe:has_category(category_name)
    if self:is_valid() then
        for _, category in pairs(recipe_categories(self)) do
            if category == category_name then
                return true
            end
        end
    end
    return false
end

--- Add to technology as a recipe unlock.
-- @tparam string tech_name Name of the technology to add the unlock too
-- @treturn self
function Recipe:add_unlock(tech_name)
    if self:is_valid() then
        local Tech = require('__stdlib2__/stdlib/data/technology')
        Tech.add_effect(self, tech_name) --self is passed as a valid recipe
    end
    return self
end

--- Remove the recipe unlock from the technology.
-- @tparam string tech_name Name of the technology to remove the unlock from
-- @treturn self
function Recipe:remove_unlock(tech_name)
    if self:is_valid('recipe') then
        local Tech = require('__stdlib2__/stdlib/data/technology')
        Tech.remove_effect(self, tech_name, 'unlock-recipe')
    end
    return self
end

--- Set the enabled status of the recipe.
-- @tparam boolean enabled Enable or disable the recipe
-- @treturn self
function Recipe:set_enabled(enabled)
    if self:is_valid() then
        self.enabled = enabled
    end
    return self
end

-- Converts a legacy recipe table (1.x format) in place.
local function convert_legacy(tbl)
    if tbl.result ~= nil then
        tbl.results = { to_table(tbl.result, tbl.result_count or 1) }
    end
    tbl.result = nil
    tbl.result_count = nil
    for i, ingredient in pairs(tbl.ingredients or {}) do
        if ingredient.name == nil or ingredient.type == nil or (ingredient.amount == nil and ingredient.amount_min == nil) then
            tbl.ingredients[i] = to_table(ingredient) or ingredient
        end
    end
    for i, result in pairs(tbl.results or {}) do
        if result.name == nil or result.type == nil or (result.amount == nil and result.amount_min == nil) then
            tbl.results[i] = to_table(result) or result
        end
    end
end

--- Convert a recipe in the 1.x format to the 2.x format.
-- <p>`result` and `result_count` become `results`, short form ingredients (`{'iron-plate', 2}`) become
-- `{type = 'item', name = 'iron-plate', amount = 2}`. A left over `normal` version is moved to the top level
-- and `expensive` is dropped.
-- @treturn self
function Recipe:convert_results()
    if self:is_valid('recipe') then
        local normal, expensive = rawget(self._raw, 'normal'), rawget(self._raw, 'expensive')
        if normal or expensive then
            for key, value in pairs(normal or expensive) do
                if self._raw[key] == nil then
                    self._raw[key] = value
                end
            end
            self._raw.normal, self._raw.expensive = nil, nil
        end
        convert_legacy(self._raw)
    end
    return self
end

--- Set the main product of the recipe.
-- @tparam string|boolean main_product the item to use, or true to use the product given as `normal`
-- @tparam[opt] Concepts.Product|string normal the product used when main_product is true
-- @tparam[opt] any expensive ignored, there are no expensive recipes in 2.x
-- @treturn self
function Recipe:set_main_product(main_product, normal, expensive)
    if self:is_valid('recipe') then
        ignore_expensive(expensive)
        local Item = require('__stdlib2__/stdlib/data/item')
        if type(main_product) == 'string' and Item(main_product):is_valid() then
            self.main_product = main_product
        elseif main_product == true and normal then
            local product = format(normal)
            if product then
                self.main_product = product.name
            end
        end
    end
    return self
end

--- Remove the main product of the recipe.
-- @tparam[opt=true] boolean for_normal
-- @tparam[opt] any for_expensive ignored, there are no expensive recipes in 2.x
function Recipe:remove_main_product(for_normal, for_expensive)
    if self:is_valid('recipe') then
        ignore_expensive(for_expensive)
        if for_normal or for_normal == nil then
            self.main_product = nil
        end
    end
    return self
end

--- Add a new product to results.
-- @tparam string|Concepts.product result_name
-- @tparam[opt] any expensive ignored, there are no expensive recipes in 2.x
-- @tparam[opt] string main_product
function Recipe:add_result(result_name, expensive, main_product)
    if self:is_valid() then
        ignore_expensive(expensive)
        result_name = format(result_name)
        if result_name then
            self.results = self.results or {}
            table.insert(self.results, result_name)
            if main_product then
                self.main_product = main_product
            end
        end
    end
    return self
end

--- Remove every product with the given name from results.
-- @tparam string|Concepts.product result_name
-- @tparam[opt] any expensive ignored, there are no expensive recipes in 2.x
-- @tparam[opt] string main_product new main_product to use
function Recipe:remove_result(result_name, expensive, main_product)
    if self:is_valid() then
        ignore_expensive(expensive)
        if self.results then
            remove_named(self.results, result_name)
            if main_product then
                self.main_product = main_product
            end
        end
    end
    return self
end

--- Replace a product.
-- @tparam string|Concepts.product replace_name the result to be replaced
-- @tparam[opt] string|Concepts.product new_result the new result to be added
-- @tparam[opt] any expensive ignored, there are no expensive recipes in 2.x
-- @tparam[opt] string main_product
function Recipe:replace_result(replace_name, new_result, expensive, main_product)
    if self:is_valid() then
        ignore_expensive(expensive)
        new_result = format(new_result)
        if new_result then
            self:remove_result(replace_name)
            self:add_result(new_result)
            if main_product then
                self.main_product = main_product
            end
        end
    end
    return self
end

return Recipe
