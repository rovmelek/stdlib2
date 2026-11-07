--- Pipes
-- @module Data.Pipes

local Pipes = {}
local Sprites = require('__stdlib2__/stdlib/data/modules/sprites')

-- Factorio 2.x removed hr_version: the former high resolution sprites are the only sprites, drawn with scale 0.5.
-- Replace every `hr_version` by its content (the main sprite fields are overwritten).
-- The 2.x base graphics dropped the low resolution files and renamed the `hr-` files to the plain name, so the
-- `hr-` prefix of the file name is removed as well (`.../hr-pipe-cover-north.png` -> `.../pipe-cover-north.png`).
local function use_hr_version(sprite)
    if type(sprite) ~= 'table' then
        return sprite
    end
    local hr = sprite.hr_version
    if hr then
        sprite.hr_version = nil
        for k, v in pairs(hr) do
            sprite[k] = v
        end
        if type(sprite.filename) == 'string' then
            sprite.filename = sprite.filename:gsub('/hr%-([^/]+)$', '/%1')
        end
        sprite.scale = sprite.scale or 0.5
    end
    for _, layer in pairs(sprite.layers or {}) do
        use_hr_version(layer)
    end
    return sprite
end

--Define pipe connection pipe pictures, not all entities use these. This function needs some work though.
-- The default sprites are the 2.x (former high resolution) ones: twice the size of the 1.x ones, drawn with scale 0.5.
-- TODO(2.1): the sizes are those of the former high resolution files as remembered from the 1.1 base game and the
-- shifts are the 1.x ones; verify both against the 2.x files, a rectangle outside its image is a data load error.
-- Prefer the base game's own pipe picture functions when you have them.
-- A replacement may give its own `scale`, otherwise the default 0.5 is kept.
function Pipes.pictures(pictures, shift_north, shift_south, shift_west, shift_east, replacements)
    local new_pictures = {
        north = shift_north and
            {
                filename = '__base__/graphics/entity/' .. pictures .. '/' .. pictures .. '-pipe-N.png',
                priority = 'extra-high',
                width = 71,
                height = 38,
                scale = 0.5,
                shift = shift_north
            } or
            Sprites.empty_picture(),
        south = shift_south and
            {
                filename = '__base__/graphics/entity/' .. pictures .. '/' .. pictures .. '-pipe-S.png',
                priority = 'extra-high',
                width = 88,
                height = 61,
                scale = 0.5,
                shift = shift_south
            } or
            Sprites.empty_picture(),
        west = shift_west and
            {
                filename = '__base__/graphics/entity/' .. pictures .. '/' .. pictures .. '-pipe-W.png',
                priority = 'extra-high',
                width = 39,
                height = 73,
                scale = 0.5,
                shift = shift_west
            } or
            Sprites.empty_picture(),
        east = shift_east and
            {
                filename = '__base__/graphics/entity/' .. pictures .. '/' .. pictures .. '-pipe-E.png',
                priority = 'extra-high',
                width = 42,
                height = 76,
                scale = 0.5,
                shift = shift_east
            } or
            Sprites.empty_picture()
    }
    for direction, image in pairs(replacements or {}) do
        if new_pictures[direction].filename ~= '__core__/graphics/empty.png' then
            new_pictures[direction].filename = image.filename
            new_pictures[direction].width = image.width
            new_pictures[direction].height = image.height
            new_pictures[direction].scale = image.scale or new_pictures[direction].scale
            new_pictures[direction].priority = image.priority or new_pictures[direction].priority
        end
    end
    return new_pictures
end

--return pipe covers for true directions.
function Pipes.covers(n, s, w, e)
    if (n == nil and s == nil and w == nil and e == nil) then
        n, s, e, w = true, true, true, true
    end

    n =
    n and
        {
            layers = {
                {
                    filename = '__base__/graphics/entity/pipe-covers/pipe-cover-north.png',
                    priority = 'extra-high',
                    width = 64,
                    height = 64,
                    hr_version = {
                        filename = '__base__/graphics/entity/pipe-covers/hr-pipe-cover-north.png',
                        priority = 'extra-high',
                        width = 128,
                        height = 128,
                        scale = 0.5
                    }
                },
                {
                    filename = '__base__/graphics/entity/pipe-covers/pipe-cover-north-shadow.png',
                    priority = 'extra-high',
                    width = 64,
                    height = 64,
                    draw_as_shadow = true,
                    hr_version = {
                        filename = '__base__/graphics/entity/pipe-covers/hr-pipe-cover-north-shadow.png',
                        priority = 'extra-high',
                        width = 128,
                        height = 128,
                        scale = 0.5,
                        draw_as_shadow = true
                    }
                }
            }
        } or
        Sprites.empty_picture()
    e =
    e and
        {
            layers = {
                {
                    filename = '__base__/graphics/entity/pipe-covers/pipe-cover-east.png',
                    priority = 'extra-high',
                    width = 64,
                    height = 64,
                    hr_version = {
                        filename = '__base__/graphics/entity/pipe-covers/hr-pipe-cover-east.png',
                        priority = 'extra-high',
                        width = 128,
                        height = 128,
                        scale = 0.5
                    }
                },
                {
                    filename = '__base__/graphics/entity/pipe-covers/pipe-cover-east-shadow.png',
                    priority = 'extra-high',
                    width = 64,
                    height = 64,
                    draw_as_shadow = true,
                    hr_version = {
                        filename = '__base__/graphics/entity/pipe-covers/hr-pipe-cover-east-shadow.png',
                        priority = 'extra-high',
                        width = 128,
                        height = 128,
                        scale = 0.5,
                        draw_as_shadow = true
                    }
                }
            }
        } or
        Sprites.empty_picture()
    s =
    s and
        {
            layers = {
                {
                    filename = '__base__/graphics/entity/pipe-covers/pipe-cover-south.png',
                    priority = 'extra-high',
                    width = 64,
                    height = 64,
                    hr_version = {
                        filename = '__base__/graphics/entity/pipe-covers/hr-pipe-cover-south.png',
                        priority = 'extra-high',
                        width = 128,
                        height = 128,
                        scale = 0.5
                    }
                },
                {
                    filename = '__base__/graphics/entity/pipe-covers/pipe-cover-south-shadow.png',
                    priority = 'extra-high',
                    width = 64,
                    height = 64,
                    draw_as_shadow = true,
                    hr_version = {
                        filename = '__base__/graphics/entity/pipe-covers/hr-pipe-cover-south-shadow.png',
                        priority = 'extra-high',
                        width = 128,
                        height = 128,
                        scale = 0.5,
                        draw_as_shadow = true
                    }
                }
            }
        } or
        Sprites.empty_picture()
    w =
    w and
        {
            layers = {
                {
                    filename = '__base__/graphics/entity/pipe-covers/pipe-cover-west.png',
                    priority = 'extra-high',
                    width = 64,
                    height = 64,
                    hr_version = {
                        filename = '__base__/graphics/entity/pipe-covers/hr-pipe-cover-west.png',
                        priority = 'extra-high',
                        width = 128,
                        height = 128,
                        scale = 0.5
                    }
                },
                {
                    filename = '__base__/graphics/entity/pipe-covers/pipe-cover-west-shadow.png',
                    priority = 'extra-high',
                    width = 64,
                    height = 64,
                    draw_as_shadow = true,
                    hr_version = {
                        filename = '__base__/graphics/entity/pipe-covers/hr-pipe-cover-west-shadow.png',
                        priority = 'extra-high',
                        width = 128,
                        height = 128,
                        scale = 0.5,
                        draw_as_shadow = true
                    }
                }
            }
        } or
        Sprites.empty_picture()

    return {
        north = use_hr_version(n),
        south = use_hr_version(s),
        east = use_hr_version(e),
        west = use_hr_version(w)
    }
end

return Pipes
