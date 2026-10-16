local FavoredFools = {}
FavoredFools.mod = SMODS.current_mod

--#region Drawing

SMODS.Atlas {
    key = 'sticker',
    path = 'sticker.png',
    px = 71,
    py = 95
}

SMODS.DrawStep {
    key = 'favorite',
    order = 41,
    func = function(card, layer)
        if G.PROFILES[G.SETTINGS.profile].fav_favorites and G.PROFILES[G.SETTINGS.profile].fav_favorites[card.config.center_key] and FavoredFools.mod.config.sticker then
            if not FavoredFools.sticker_sprite then
                FavoredFools.sticker_sprite = SMODS.create_sprite(0, 0, 1, 1, 'fav_sticker', { x = 0, y = 0 })
            end
            FavoredFools.sticker_sprite.role.draw_major = card
            FavoredFools.sticker_sprite:draw_shader('dissolve', nil, nil, nil, card.children.center)
            FavoredFools.sticker_sprite:draw_shader('voucher', nil, card.ARGS.send_to_shader, nil, card.children.center)
        end
    end,
    conditions = { vortex = false, facing = 'front' },
}

--#endregion

--#region Functionality

SMODS.Keybind {
    key_pressed = 'f',
    action = function(self)
        if G.CONTROLLER.hovering.target then
            local target = G.CONTROLLER.hovering.target
            if target:is(Card) and G.P_CENTERS[target.config.center_key] ~= nil then
                local profile = G.PROFILES[G.SETTINGS.profile]
                profile.fav_favorites = profile.fav_favorites or {}
                if profile.fav_favorites[target.config.center_key] then
                    local starting_reduce_point = profile.fav_favorites[target.config.center_key]
                    profile.fav_favorites[target.config.center_key] = nil
                    for k, v in pairs(profile.fav_favorites) do
                        if profile.fav_favorites[k] >= starting_reduce_point then
                            profile.fav_favorites[k] = profile.fav_favorites[k] - 1
                        end
                    end
                else
                    profile.fav_favorites[target.config.center_key] = SMODS.table_size(profile.fav_favorites) + 1
                end
                target:juice_up()
                play_sound('gold_seal', 1.2, 0.4)
            end
        end
    end
}

SMODS.Sound {
    key = 'appear_notif',
    path = 'appear_notif.ogg'
}

local create_card_ref = create_card
function create_card(...)
    local card = create_card_ref(...)

    if G.STAGE == G.STAGES.RUN then
        if G.PROFILES[G.SETTINGS.profile].fav_favorites and G.PROFILES[G.SETTINGS.profile].fav_favorites[card.config.center_key] then
            -- Play sound in event
            if FavoredFools.mod.config.sound_cue then
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.2,
                    func = function()
                        card:juice_up(1, 0.5)
                        play_sound('fav_appear_notif')
                        return true;
                    end
                }))
            end

            -- Lock controls briefly like editions if config is active
            if FavoredFools.mod.config.creation_lock then
                G.CONTROLLER.locks.fav_anim = true
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.3,
                    func = function()
                        G.CONTROLLER.locks.fav_anim = false
                    return true
                    end
                }))
            end
        end
    end

    return card
end

--#endregion

--#region Collection

local function get_centers_from_favorites()
    local centers = {}
    for k, v in pairs(G.P_CENTERS) do
        if G.PROFILES[G.SETTINGS.profile].fav_favorites[v.key] then
            centers[#centers+1] = v
        end
    end
    return centers
end

local function tally(pool)
	local obj_tally = {tally = 0, of = 0}

    for _, v in pairs(pool) do
        obj_tally.of = obj_tally.of+1
        if v.discovered then
            obj_tally.tally = obj_tally.tally+1
        end
    end

    return obj_tally
end

function FavoredFools.mod.custom_collection_tabs()
    if G.PROFILES[G.SETTINGS.profile].fav_favorites and next(G.PROFILES[G.SETTINGS.profile].fav_favorites) then
        return { 
            UIBox_button {
                button = "fav_your_collection_favorites",
                label = { localize("b_fav_favorites") },
                count = tally(get_centers_from_favorites()),
                minw = 5,
                id = "fav_your_collection_favorites",
            }
        }
    else
        return {}
    end
end

function G.FUNCS.fav_your_collection_favorites(e)
	G.SETTINGS.paused = true
	G.FUNCS.overlay_menu {
		definition = G.UIDEF.create_UIBox_your_collection_favorites(),
	}
end

function G.UIDEF.create_UIBox_your_collection_favorites()
	local pool = get_centers_from_favorites()
    table.sort(pool, function(a, b) return G.PROFILES[G.SETTINGS.profile].fav_favorites[a.key] < G.PROFILES[G.SETTINGS.profile].fav_favorites[b.key] end)
	return SMODS.card_collection_UIBox(pool, { 5, 5, 5 }, {
		no_materialize = true,
		h_mod = 0.95,
		back_func = 'your_collection_other_gameobjects',
	})
end

--#endregion

--#region Config

FavoredFools.mod.config_tab = function()
    return {
        n = G.UIT.ROOT,
        config = { align = "m", r = 0.1, padding = 0.1, colour = G.C.BLACK, minw = 8, minh = 6 },
        nodes = {
            { n = G.UIT.R, config = { align = "cl", padding = 0, minh = 0.1 },      nodes = {} },

            -- Sticker Toggle
            {
                n = G.UIT.R,
                config = { align = "cl", padding = 0 },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = { align = "cl", padding = 0.05 },
                        nodes = {
                            create_toggle { col = true, label = "", scale = 1, w = 0, shadow = true, ref_table = FavoredFools.mod.config, ref_value = "sticker" },
                        }
                    },
                    {
                        n = G.UIT.C,
                        config = { align = "c", padding = 0 },
                        nodes = {
                            { n = G.UIT.T, config = { text = localize('b_fav_sticker'), scale = 0.45, colour = G.C.UI.TEXT_LIGHT } },
                        }
                    },
                }
            },

            -- Sound Cue Toggle
            {
                n = G.UIT.R,
                config = { align = "cl", padding = 0 },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = { align = "cl", padding = 0.05 },
                        nodes = {
                            create_toggle { col = true, label = "", scale = 1, w = 0, shadow = true, ref_table = FavoredFools.mod.config, ref_value = "sound_cue" },
                        }
                    },
                    {
                        n = G.UIT.C,
                        config = { align = "c", padding = 0 },
                        nodes = {
                            { n = G.UIT.T, config = { text = localize('b_fav_sound_cue'), scale = 0.45, colour = G.C.UI.TEXT_LIGHT } },
                        }
                    },
                }
            },

            -- Creation Lock Toggle
            {
                n = G.UIT.R,
                config = { align = "cl", padding = 0 },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = { align = "cl", padding = 0.05 },
                        nodes = {
                            create_toggle { col = true, label = "", scale = 1, w = 0, shadow = true, ref_table = FavoredFools.mod.config, ref_value = "creation_lock" },
                        }
                    },
                    {
                        n = G.UIT.C,
                        config = { align = "c", padding = 0 },
                        nodes = {
                            { n = G.UIT.T, config = { text = localize('b_fav_creation_lock'), scale = 0.45, colour = G.C.UI.TEXT_LIGHT } },
                        }
                    },
                }
            },

        }
    }
end

--#endregion
