-- Auto-open quickfix window if errors exist after make/grep/etc.
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

vim.api.nvim_create_user_command('ChangeCommand', function()
    local input = vim.fn.input('Set makeprg: ', vim.o.makeprg.sub(vim.o.makeprg, 0, vim.o.makeprg.len(vim.o.makeprg) - 2))

    if input == '' then
        print 'Cancelled.'
        return
    end
    vim.o.makeprg = input
end, {})

vim.api.nvim_create_user_command('RunCommand', function()
    local makeprg = vim.o.makeprg

    -- If makeprg is not set or empty
    if makeprg == '' or makeprg == 'make' then
        -- Ask the user for a command
        local input = vim.fn.input 'Set makeprg: '
        if input == '' then
            print 'Cancelled.'
            return
        end
        vim.o.makeprg = input
    end

    -- Run :make
    vim.cmd 'make'
end, {})

vim.keymap.set({ 'n', 'i', 'v' }, '<C-i>', ':RunCommand<enter>', { desc = 'Run Command' })
vim.keymap.set({ 'n' }, ';', ':ChangeCommand<enter>', { desc = 'Change Command' })

vim.keymap.set('n', ']e', '<Cmd>try | cnext | catch | cfirst | catch | endtry<CR><CR>', { desc = 'Next Error' })
vim.keymap.set('n', '[e', '<Cmd>try | cprevious | catch | clast | catch | endtry<CR><CR>', { desc = 'Prev Error' })
