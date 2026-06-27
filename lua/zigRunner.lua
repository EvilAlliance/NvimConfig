local M = {}

M.job = nil
M.root = nil

local report = {}
local pending = ''

local function publish()
    vim.fn.setqflist({}, 'r', { title = 'zig build', lines = report })

    local items = vim.fn.getqflist()
    for _, item in ipairs(items) do
        item.type = item.type:upper()
    end
    vim.fn.setqflist({}, 'r', { title = 'zig build', items = items })

    report = {}

    vim.api.nvim_exec_autocmds('QuickFixCmdPost', { pattern = 'make' })
end

local function consume(line)
    report[#report + 1] = line
    if line:match '^Build Summary:' then
        publish()
    end
end

local function on_output(_, data)
    if not data then
        return
    end

    pending = pending .. data[1]
    for i = 2, #data do
        print(data[i])
        consume(pending)
        pending = data[i]
    end
end

function M.start()
    if M.job then
        return
    end

    local root = vim.fs.root(0, 'build.zig')
    if not root then
        vim.notify('zigRunner: no build.zig found', vim.log.levels.WARN)
        return
    end

    M.root = root
    report, pending = {}, ''

    M.job = vim.fn.jobstart({ 'zig', 'build', '--watch', '-fincremental', '-freference-trace=20' }, {
        cwd = root,
        stdout_buffered = false,
        on_stdout = on_output,
        on_stderr = on_output,
        on_exit = function()
            if pending ~= '' then
                consume(pending)
                pending = ''
            end
            M.job = nil
        end,
    })

    if M.job <= 0 then
        M.job = nil
        vim.notify('zigRunner: failed to start `zig build --watch`', vim.log.levels.ERROR)
    end
end

function M.stop()
    if not M.job then
        return
    end
    vim.fn.jobstop(M.job)
    M.job = nil
end

function M.restart()
    M.stop()
    M.start()
end

vim.api.nvim_create_user_command('ZigWatch', M.start, { desc = 'Start zig build --watch into quickfix' })
vim.api.nvim_create_user_command('ZigWatchStop', M.stop, { desc = 'Stop the zig build watcher' })
vim.api.nvim_create_user_command('ZigWatchRestart', M.restart, { desc = 'Restart the zig build watcher' })

vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = M.stop,
})

if vim.fs.root(0, 'build.zig') then
    M.start()
end

return M
