--- Item
-- @classmod Data.Item

local Data = require('__stdlib2__/stdlib/data/data')
local Table = require('__stdlib2__/stdlib/utils/table')

local Item = {
    __class = 'Item',
    __index = Data,
    __call = Data.__call
}
setmetatable(Item, Item)

local function make_table(params)
    if not params then
        return Table.keys(data.raw.lab)
    else
        return type(params) == 'table' and params or { params }
    end
end

local function change_inputs(name, lab_names, add)
    lab_names = make_table(lab_names)
    local Entity = require('__stdlib2__/stdlib/data/entity')
    for _, lab_name in pairs(lab_names) do
        Entity(lab_name, 'lab'):change_lab_inputs(name, add)
    end
end

function Item:add_to_labs(lab_names)
    if self:is_valid() then
        change_inputs(self.name, lab_names, true)
    end
    return self
end

--- Make the item a fuel.
-- @tparam string|number value the fuel_value, for example `'4MJ'`
-- @tparam string|table categories a fuel category name or an array of names
-- @tparam[opt] string burnt_result
-- @treturn self
function Item:set_fuel(value, categories, burnt_result)
    if self:is_valid() then
        self.fuel_value = value
        self.fuel_categories = type(categories) == 'table' and categories or { categories }
        self.fuel_category = nil
        if burnt_result then
            self.burnt_result = burnt_result
        end
    end
    return self
end

--- Add a fuel category to the item. A legacy `fuel_category` is moved into `fuel_categories`.
-- @tparam string name
-- @treturn self
function Item:add_fuel_category(name)
    if self:is_valid() then
        local categories = self.fuel_categories and Table.deepcopy(self.fuel_categories) or {}
        if self.fuel_category then
            categories[#categories + 1] = self.fuel_category
            self.fuel_category = nil
        end
        for _, existing in pairs(categories) do
            if existing == name then
                self.fuel_categories = categories
                return self
            end
        end
        categories[#categories + 1] = name
        self.fuel_categories = categories
    end
    return self
end

function Item:remove_from_labs(lab_names)
    if self:is_valid() then
        change_inputs(self.name, lab_names, false)
    end
    return self
end

return Item
