
local YMAX = -26900--mcl_vars.mg_end_max
local YMIN = -27050--mcl_vars.mg_end_min

local biome_size = 200

--Needed for context for some reason
local perlin
local perlin_l






--api

mcl_better_end.mapgen.registered_nodes = {
    end_stone = minetest.get_content_id("mcl_end:end_stone"),
    old_chorus_plant = minetest.get_content_id("mcl_end:chorus_plant"),
    old_chorus_plant_top = minetest.get_content_id("mcl_end:chorus_flower_dead"),
    air = minetest.get_content_id("air"),
}

--API
mcl_better_end.api.register_biome = function(e)
    mcl_better_end.biomes[#mcl_better_end.biomes + 1] = e
end


mcl_better_end.api.is_island = function(x, y, z)
    if perlin_l:get_3d({x = x, y = y, z = z}) > 0.5 then
        return true
    end
    return false
end





--mapgen


minetest.register_on_joinplayer(
    function() 
        perlin = minetest.get_perlin({
            offset = 0,
            scale = 1,
            spread = {x = biome_size, y = biome_size/2, z = biome_size},
            seed = minetest.get_mapgen_setting("seed"),
            octaves = 3,
            persist = 0.5
        })
        perlin_l = minetest.get_perlin({
                offset = 0,
                scale = 1,
                spread = {x = 50, y = 20, z = 50},
                seed = minetest.get_mapgen_setting("seed"),
                octaves = 3,
                persist = 0.5
            })
    end
)








--Gen

function mcl_better_end.mapgen.gen(minp, maxp, seed)
    -- Check if the current Y range is within the desired bounds
    if maxp.y < YMIN or minp.y > YMAX then
        return
    end

    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
    local data = vm:get_data()

    local pr = PseudoRandom((seed + minp.x + maxp.z) / 3)

    local is_island = mcl_better_end.api.is_island
    -- Loop through the area and set nodes
    for y = minp.y, maxp.y do
        for z = minp.z, maxp.z do
            for x = minp.x, maxp.x do
                --do tuff
                local vi = area:index(x, y, z)

                --if not generated
                if is_island(x, y, z) then
                    data[vi] = mcl_better_end.mapgen.registered_nodes.end_stone

                    for _, f in pairs(mcl_better_end.mapgen.ores) do
                        f(data, vi, area, pr, x, y, z)
                    end

                    if not is_island(x, y+1, z) then
                        local noise_center = perlin:get_3d({x = x, y = y, z = z})
                        --do biomes
                        for _, p in pairs(mcl_better_end.biomes) do
                            if (noise_center <= p.noise_high) and (noise_center >= p.noise_low) then
                                p.gen(data, vi, area, pr, x, y, z)
                            end
                        end
                    end
                    
                elseif data[vi] == mcl_better_end.mapgen.registered_nodes.end_stone or data[vi] == mcl_better_end.mapgen.registered_nodes.old_chorus_plant_top or data[vi] == mcl_better_end.mapgen.registered_nodes.old_chorus_plant then
                    data[vi] = mcl_better_end.mapgen.registered_nodes.air
                end

            end
        end
    end

    vm:set_data(data)
    vm:write_to_map()
    vm:update_map()
end

minetest.register_on_generated(
    function(minp, maxp, seed)
        mcl_better_end.mapgen.gen(minp, maxp, seed)
    end
    
)