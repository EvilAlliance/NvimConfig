return {
    {
        'tomasky/bookmarks.nvim',
        lazy = false,
        config = function()
            require('bookmarks').setup {
                save_file = vim.fn.expand '$HOME/.bookmarks',
                keywords = {
                    ['@t'] = '☑️ ',
                    ['@w'] = '⚠️ ',
                    ['@f'] = '⛏ ',
                    ['@n'] = ' ',
                },
            }
        end,
    },
    {
        'tom-anders/telescope-vim-bookmarks.nvim',
        dependencies = { 'tomasky/bookmarks.nvim' },
        config = function()
            require('telescope').load_extension('bookmarks')
        end,
    },
}
