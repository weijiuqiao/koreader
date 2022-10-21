-- Start with the english keyboard layout (deep copy, to not alter it)
local vi_keyboard = require("util").tableDeepCopy(require("ui/data/keyboardlayouts/en_keyboard"))

local IME = require("frontend/ui/data/keyboardlayouts/generic_ime")
local util = require("util")
local _ = require("gettext")
local SHOW_CANDI_KEY = "keyboard_chinese_stroke_show_candidates"

-- see https://www.hieuthi.com/blog/2017/03/21/all-vietnamese-syllables.html
local code_map = require("frontend/ui/data/keyboardlayouts/zh_wubi_data")
local ime =
    IME:new {
    code_map = code_map,
    partial_separators = {" "},
    auto_separate_callback = function()
        return true
    end,
    show_candi_callback = function()
        return true
    end,
    switch_char = "z"
}

local z = table.remove(vi_keyboard.keys[4], 2)
table.insert(vi_keyboard.keys[4], 8, z)
vi_keyboard.keys[4][2][2].alt_label = nil
vi_keyboard.keys[3][4][2].alt_label = "·"
vi_keyboard.keys[3][7][2].alt_label = "·"
vi_keyboard.keys[3][10][2] = {
    "，",
    north = "；",
    alt_label = "；",
    northeast = "（",
    northwest = "“",
    east = "《",
    west = "？",
    south = ",",
    southeast = "【",
    southwest = "「",
    "{",
    "[",
    ";"
}

vi_keyboard.keys[5][3][2] = {
    "。",
    north = "：",
    alt_label = "：",
    northeast = "）",
    northwest = "”",
    east = "…",
    west = "！",
    south = ".",
    southeast = "】",
    southwest = "」",
    "}",
    "]",
    ":"
}

local genMenuItems = function(self)
    return {
        {
            text = _("Show character candidates"),
            checked_func = function()
                return G_reader_settings:nilOrTrue(SHOW_CANDI_KEY)
            end,
            callback = function()
                G_reader_settings:flipNilOrTrue(SHOW_CANDI_KEY)
            end
        }
    }
end

local wrappedAddChars = function(inputbox, char)
    ime:wrappedAddChars(inputbox, char)
end

local function separate(inputbox)
    ime:separate(inputbox)
end

local function wrappedDelChar(inputbox)
    ime:wrappedDelChar(inputbox)
end

local function clear_stack()
    ime:clear_stack()
end

local wrapInputBox = function(inputbox)
    if inputbox._vi_wrapped == nil then
        inputbox._vi_wrapped = true
        local wrappers = {}

        -- Wrap all of the navigation and non-single-character-input keys with
        -- a callback to finish (separate) the input status, but pass through to the
        -- original function.

        -- -- Delete text.
        table.insert(wrappers, util.wrapMethod(inputbox, "delChar", wrappedDelChar, nil))
        table.insert(wrappers, util.wrapMethod(inputbox, "delToStartOfLine", nil, clear_stack))
        table.insert(wrappers, util.wrapMethod(inputbox, "clear", nil, clear_stack))
        -- -- Navigation.
        table.insert(wrappers, util.wrapMethod(inputbox, "leftChar", nil, separate))
        table.insert(wrappers, util.wrapMethod(inputbox, "rightChar", nil, separate))
        table.insert(wrappers, util.wrapMethod(inputbox, "upLine", nil, separate))
        table.insert(wrappers, util.wrapMethod(inputbox, "downLine", nil, separate))
        -- -- Move to other input box.
        table.insert(wrappers, util.wrapMethod(inputbox, "unfocus", nil, separate))
        table.insert(wrappers, util.wrapMethod(inputbox, "onCloseKeyboard", nil, separate))
        -- -- Gestures to move cursor.
        table.insert(wrappers, util.wrapMethod(inputbox, "onTapTextBox", nil, separate))
        table.insert(wrappers, util.wrapMethod(inputbox, "onHoldTextBox", nil, separate))
        table.insert(wrappers, util.wrapMethod(inputbox, "onSwipeTextBox", nil, separate))

        -- addChars is the only method we need a more complicated wrapper for.
        table.insert(wrappers, util.wrapMethod(inputbox, "addChars", wrappedAddChars, nil))

        return function()
            if inputbox._vi_wrapped then
                for _, wrapper in ipairs(wrappers) do
                    wrapper:revert()
                end
                inputbox._vi_wrapped = nil
            end
        end
    end
end

vi_keyboard.wrapInputBox = wrapInputBox
vi_keyboard.genMenuItems = genMenuItems
vi_keyboard.keys[5][4].label = "空格"

return vi_keyboard
