return {
    'folke/trouble.nvim',
    opts = {
        modes = {
            -- Let the qflist view open/close/refresh itself from the quickfix
            -- list (e.g. the zig watcher) instead of driving it manually.
            qflist = {
                auto_open = true,
                auto_close = true,
            },
        },
    },
    cmd = 'Trouble',
    -- Load after startup so the auto_open qflist view is listening for the
    -- zig watcher's quickfix updates, not only when :Trouble is first run.
    event = 'VeryLazy',
    keys = {
        {
            '<leader>xx',
            '<cmd>Trouble diagnostics toggle<cr>',
            desc = 'Diagnostics (Trouble)',
        },
        {
            '<leader>xX',
            '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
            desc = 'Buffer Diagnostics (Trouble)',
        },
        {
            '<leader>cs',
            '<cmd>Trouble symbols toggle focus=false<cr>',
            desc = 'Symbols (Trouble)',
        },
        {
            '<leader>cl',
            '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
            desc = 'LSP Definitions / references / ... (Trouble)',
        },
        {
            '<leader>xL',
            '<cmd>Trouble loclist toggle<cr>',
            desc = 'Location List (Trouble)',
        },
        {
            '<leader>xQ',
            '<cmd>Trouble qflist toggle<cr>',
            desc = 'Quickfix List (Trouble)',
        },
    },
}
