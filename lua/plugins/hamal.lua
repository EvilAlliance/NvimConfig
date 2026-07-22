return {
  "ergodice/hamal.nvim",
  config = function()
    local hamal = require("hamal")

    vim.keymap.set("n", "gs", hamal.split)
    vim.keymap.set("o", "gs", hamal.split)

    hamal.setup({
      keymaps = {
        ["k"] = function()
          require("hamal").focus(1)
        end,
        ["j"] = function()
          require("hamal").focus(3)
        end,
        ["l"] = function()
          require("hamal").focus(2)
        end,
        ["h"] = false,
        ["m"] = false,

        ["K"] = function()
          require("hamal").top()
          require("hamal").quit()
        end,
        ["J"] = function()
          require("hamal").bottom()
          require("hamal").quit()
        end,
        ["L"] = function()
          require("hamal").middle()
          require("hamal").quit()
        end,
        ["H"] = false,
        ["M"] = false,
      },
      highlights = {
        section = {
          { "HamalSection1", { bg = "#364a82" } }, -- muted blue
          { "HamalSection2", { bg = "#4c3a6e" } }, -- muted purple
          { "HamalSection3", { bg = "#3b4d3a" } }, -- muted green
        },
      },
    })
  end,
}
