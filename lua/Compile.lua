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

vim.api.nvim_create_user_command('Compile', function()
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
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<enter>', true, false, true), 'n', false)
end, {})

vim.keymap.set({ 'i', 'n', 'v' }, '<C-i>', ':Compile<enter>', { desc = 'Compile Program' })

vim.keymap.set('n', ']e', '<Cmd>try | cnext | catch | cfirst | catch | endtry<CR><CR>', { desc = 'Next Error' })
vim.keymap.set('n', '[e', '<Cmd>try | cprevious | catch | clast | catch | endtry<CR><CR>', { desc = 'Prev Error' })
