return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'

    -- REQUIRED
    harpoon:setup {}
    -- REQUIRED

    local conf = require('telescope.config').values
    --    local conf = require('telescope.config').values
    local function toggle_telescope(harpoon_files)
      local file_paths = {}
      for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
      end

      require('telescope.pickers')
        .new({}, {
          prompt_title = 'Harpoon',
          finder = require('telescope.finders').new_table {
            results = file_paths,
          },
          previewer = conf.file_previewer {},
          sorter = conf.generic_sorter {},
        })
        :find()
    end

    vim.keymap.set('n', '<C-b>', function()
      harpoon:list():add()
    end, { desc = '[H]arpoon [A]dd File' })
    vim.keymap.set('n', '<C-e>', function()
      toggle_telescope(harpoon:list())
    end, { desc = 'Open harpoon window' })

    local function set_navigation(number)
      vim.keymap.set('n', '<C-g>' .. number, function()
        harpoon:list():select(number)
      end, { desc = 'Go to harpoon ' .. number })
    end

    local function set_delete(number)
      vim.keymap.set('n', '<C-d>' .. number, function()
        if number < harpoon:list():length() then
          harpoon:list():remove_at(number)
        end
      end, { desc = 'Delete File harpoon ' .. number })
    end

    set_navigation(1)
    set_navigation(2)
    set_navigation(3)
    set_navigation(4)
    set_navigation(5)
    set_navigation(6)
    set_navigation(7)
    set_navigation(8)
    set_navigation(9)

    set_delete(1)
    set_delete(2)
    set_delete(3)
    set_delete(4)
    set_delete(5)
    set_delete(6)
    set_delete(7)
    set_delete(8)
    set_delete(9)

    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set('n', '<S-h>', function()
      harpoon:list():prev()
    end)
    vim.keymap.set('n', '<S-l>', function()
      harpoon:list():next()
    end)
  end,
}
