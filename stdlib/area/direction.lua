--- Functions for working with directions and orientations.
-- @module Area.Direction
-- @usage local Direction = require('__stdlib2__/stdlib/area/direction')
-- @see defines.direction

local Direction = {
    __class = 'Direction',
    __index = require('__stdlib2__/stdlib/core')
}
setmetatable(Direction, Direction)

--- defines.direction.north
Direction.north = defines.direction.north
--- defines.direction.east
Direction.east = defines.direction.east
--- defines.direction.west
Direction.west = defines.direction.west
--- defines.direction.south
Direction.south = defines.direction.south
--- defines.direction.northeast
Direction.northeast = defines.direction.northeast
--- defines.direction.northwest
Direction.northwest = defines.direction.northwest
--- defines.direction.southeast
Direction.southeast = defines.direction.southeast
--- defines.direction.southwest
Direction.southwest = defines.direction.southwest
--- defines.direction.northnortheast
Direction.northnortheast = defines.direction.northnortheast
--- defines.direction.eastnortheast
Direction.eastnortheast = defines.direction.eastnortheast
--- defines.direction.eastsoutheast
Direction.eastsoutheast = defines.direction.eastsoutheast
--- defines.direction.southsoutheast
Direction.southsoutheast = defines.direction.southsoutheast
--- defines.direction.southsouthwest
Direction.southsouthwest = defines.direction.southsouthwest
--- defines.direction.westsouthwest
Direction.westsouthwest = defines.direction.westsouthwest
--- defines.direction.westnorthwest
Direction.westnorthwest = defines.direction.westnorthwest
--- defines.direction.northnorthwest
Direction.northnorthwest = defines.direction.northnorthwest


--- Returns the opposite direction
-- @tparam defines.direction direction the direction
-- @treturn defines.direction the opposite direction
function Direction.opposite(direction)
    return (direction + 8) % 16
end

local steps = { [true] = 2, ['16'] = 1, [16] = 1 }

--- Returns the next direction.
--> For entities that only support two directions, see @{opposite}.
-- @tparam defines.direction direction the starting direction
-- @tparam[opt] boolean|string mode `true` for the next 8-way direction, `'16'` for the next of all 16 directions, otherwise the next 4-way direction
-- @treturn defines.direction the next direction
function Direction.next(direction, mode)
    return (direction + (steps[mode] or 4)) % 16
end

--- Returns the previous direction.
--> For entities that only support two directions, see @{opposite}.
-- @tparam defines.direction direction the starting direction
-- @tparam[opt] boolean|string mode `true` for the previous 8-way direction, `'16'` for the previous of all 16 directions, otherwise the previous 4-way direction
-- @treturn defines.direction the previous direction
function Direction.previous(direction, mode)
    return (direction - (steps[mode] or 4)) % 16
end

--- Returns an orientation from a direction.
-- @tparam defines.direction direction
-- @treturn float
function Direction.to_orientation(direction)
    return direction / 16
end

local function round(n)
    return math.floor(n * 1e6 + 0.5) / 1e6
end

--- Returns a vector from a direction.
-- <p>The 8 primary directions keep their historic behaviour (a diagonal moves `distance` along both axes).
-- The 8 secondary directions (such as `northnortheast`) return the unit vector scaled by `distance`.
-- @tparam defines.direction direction
-- @tparam[opt = 1] number distance
-- @treturn Position
function Direction.to_vector(direction, distance)
    distance = distance or 1
    local x, y = 0, 0
    if direction == Direction.north then
        y = y - distance
    elseif direction == Direction.northeast then
        x, y = x + distance, y - distance
    elseif direction == Direction.east then
        x = x + distance
    elseif direction == Direction.southeast then
        x, y = x + distance, y + distance
    elseif direction == Direction.south then
        y = y + distance
    elseif direction == Direction.southwest then
        x, y = x - distance, y + distance
    elseif direction == Direction.west then
        x = x - distance
    elseif direction == Direction.northwest then
        x, y = x - distance, y - distance
    elseif direction and direction % 2 == 1 and direction >= 0 and direction < 16 then
        local radians = direction / 16 * 2 * math.pi
        x, y = round(math.sin(radians) * distance), round(-math.cos(radians) * distance)
    end
    return { x = x, y = y }
end

-- Deprecated
do
    local Orientation = require('__stdlib2__/stdlib/area/orientation')
    Direction.opposite_direction = Direction.opposite
    Direction.direction_to_orientation = Direction.to_orientation

    function Direction.orientation_to_4way(orientation)
        return Orientation.to_direction(orientation)
    end

    function Direction.orientation_to_8way(orientation)
        return Orientation.to_direction(orientation, true)
    end

    function Direction.next_direction(direction, reverse, eight_way)
        return (direction + (eight_way and ((reverse and -2) or 2) or ((reverse and -4) or 4))) % 16
    end

    function Direction.orientation_to_16way(orientation)
        return Orientation.to_direction(orientation, 'sixteen_way')
    end
end

return Direction
