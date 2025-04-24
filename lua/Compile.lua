local json = vim.fn.json_encode
local json_decode = vim.fn.json_decode

-- Path to store per-project makeprg values
local store_path = vim.fn.stdpath 'data' .. '/project_makeprg.json'
local makeprg_store = {}

-- Load existing saved commands
local function load_store()
    local f = io.open(store_path, 'r')
    if f then
        makeprg_store = json_decode(f:read '*a') or {}
        f:close()
    end
end

-- Save to file
local function save_store()
    local f = io.open(store_path, 'w')
    if f then
        f:write(json(makeprg_store))
        f:close()
    end
end

-- Identify project by cwd
local function get_project_key()
    return vim.fn.getcwd()
end

-- Auto-load on startup
load_store()

-- Restore makeprg on file open
vim.api.nvim_create_autocmd('BufEnter', {
    callback = function()
        local key = get_project_key()
        local saved = makeprg_store[key]
        if saved then
            vim.o.makeprg = saved
        end
    end,
})

-- Auto-open quickfix window if errors exist after :make
vim.api.nvim_create_autocmd('QuickFixCmdPost', {
    pattern = { 'make' },
    callback = function()
        if #vim.fn.getqflist() > 0 then
            vim.cmd 'Trouble qflist open'
        else
            vim.cmd 'Trouble qflist close'
        end
    end,
})

-- Command to change makeprg and persist it
vim.api.nvim_create_user_command('ChangeCommand', function()
    local current = vim.o.makeprg
    local input = vim.fn.input('Set makeprg: ', current)

    if input == '' then
        print 'Cancelled.'
        return
    end

    vim.o.makeprg = input
    makeprg_store[get_project_key()] = input
    save_store()
end, {})

-- Run make, prompting for makeprg if not set
vim.api.nvim_create_user_command('RunCommand', function()
    if vim.o.makeprg == '' or vim.o.makeprg == 'make' then
        local input = vim.fn.input 'Set makeprg: '
        if input == '' then
            print 'Cancelled.'
            return
        end
        vim.o.makeprg = input
        makeprg_store[get_project_key()] = input
        save_store()
    end

    vim.cmd 'make!'
end, {})

-- Keymaps
vim.keymap.set({ 'n', 'i', 'v' }, '<C-i>', ':RunCommand<CR>', { desc = 'Run Command' })
vim.keymap.set('n', ';', ':ChangeCommand<CR>', { desc = 'Change Command' })
vim.keymap.set('n', ']e', '<Cmd>try | cnext | catch | cfirst | catch | endtry<CR><CR>', { desc = 'Next Error' })
vim.keymap.set('n', '[e', '<Cmd>try | cprevious | catch | clast | catch | endtry<CR><CR>', { desc = 'Prev Error' })
vim.keymap.set('n', '<M-i>', '<Cmd>Trouble qflist close<CR>', { desc = 'Close Trouble QuickFix' })
