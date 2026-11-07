--- Functions for working with orientations.
-- @module Area.Orientation
-- @usage local Orientation = require('__stdlib2__/stdlib/area/orientation')

local Orientation = {
    __class = 'Orientation',
    __index = require('__stdlib2__/stdlib/core'),
}
setmetatable(Orientation, Orientation)

--- north orientation
Orientation.north = defines.direction.north / 16
--- east orientation
Orientation.east = defines.direction.east / 16
--- west orientation
Orientation.west = defines.direction.west / 16
--- south orientation
Orientation.south = defines.direction.south / 16
--- northeast orientation
Orientation.northeast = defines.direction.northeast / 16
--- northwest orientation
Orientation.northwest = defines.direction.northwest / 16
--- southeast orientation
Orientation.southeast = defines.direction.southeast / 16
--- southwest orientation
Orientation.southwest = defines.direction.southwest / 16

local floor = math.floor

--- Returns a direction from an orientation.
-- Directions are the 16 value `defines.direction` of Factorio 2.x (north = 0, east = 4, south = 8, west = 12).
-- @tparam float orientation
-- @tparam[opt=false] boolean|string eight_way true for 8-way directions, `'sixteen_way'` for all 16 directions, otherwise 4-way
-- @treturn defines.direction
function Orientation.to_direction(orientation, eight_way)
    if eight_way == 'sixteen_way' then
        return floor(orientation * 16 + 0.5) % 16
    elseif eight_way then
        return floor(orientation * 8 + 0.5) % 8 * 2
    end
    return floor(orientation * 4 + 0.5) % 4 * 4
end

--- Returns the opposite orientation.
-- @tparam float orientation
-- @treturn float the opposite orientation
function Orientation.opposite(orientation)
    return (orientation + 0.5) % 1
end

--- Add two orientations together.
-- @tparam float orientation1
-- @tparam float orientation2
-- @treturn float the orientations added together
function Orientation.add(orientation1, orientation2)
    return (orientation1 + orientation2) % 1
end

return Orientation
