require 'options'
require 'keymaps'
require 'Compile'
require 'autocmd'

local add_cmd = vim.api.nvim_create_user_command

add_cmd('Spacelen2', function()
    vim.bo.expandtab = true --expand tabs to spaces
    vim.bo.shiftwidth = 2 --visual mode >,<-key: number of spaces for indendation
    vim.bo.tabstop = 2 --Tab key: number of spaces for indendation
end, {})
add_cmd('Spacelen4', function()
    vim.bo.expandtab = true --expand tabs to spaces
    vim.bo.shiftwidth = 4 --visual mode >,<-key: number of spaces for indendation
    vim.bo.tabstop = 4 --Tab key: number of spaces for indendation
end, {})
add_cmd('Spacelen8', function()
    vim.bo.expandtab = true --expand tabs to spaces
    vim.bo.shiftwidth = 8 --visual mode >,<-key: number of spaces for indendation
    vim.bo.tabstop = 8 --Tab key: number of spaces for indendation
end, {})
add_cmd('Tablen2', function()
    vim.bo.expandtab = false --expand tabs to spaces
    vim.bo.shiftwidth = 2 --visual mode >,<-key: number of spaces for indendation
    vim.bo.tabstop = 2 --Tab key: number of spaces for indendation
end, {})
add_cmd('Tablen4', function()
    vim.bo.expandtab = false --expand tabs to spaces
    vim.bo.shiftwidth = 4 --visual mode >,<-key: number of spaces for indendation
    vim.bo.tabstop = 4 --Tab key: number of spaces for indendation
end, {})
add_cmd('Tablen8', function()
    vim.bo.expandtab = false --expand tabs to spaces
    vim.bo.shiftwidth = 8 --visual mode >,<-key: number of spaces for indendation
    vim.bo.tabstop = 8 --Tab key: number of spaces for indendation
end, {})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
            { out, 'WarningMsg' },
            { '\nPress any key to exit...' },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)
-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.

require('lazy').setup {
    -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).

    -- NOTE: Plugins can also be added by using a table,
    -- with the first argument being the link and the following
    -- keys can be used to configure plugin behavior/loading/etc.
    --
    -- Use `opts = {}` to force a plugin to be loaded.
    --
    spec = {
        -- import your plugins
        { import = 'plugins' },
    },
}
