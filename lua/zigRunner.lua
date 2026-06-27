local M = {}

M.job = nil
M.root = nil

-- The watcher runs under a pty so zig renders its live progress bar; that means
-- every line is wrapped in ANSI escapes and ends in CR, and real diagnostics are
-- buried in build-step / progress noise. This errorformat keeps only the actual
-- `file:line:col: error|note: message` lines and drops everything else.
local efm = table.concat({
    '%f:%l:%c: %t%*[^:]: %m',
    '%-G%.%#',
}, ',')

-- zig draws each progress frame (compiling *and* the idle "watching..." status)
-- inside a DEC synchronized-update region, so these bytes head every frame and
-- appear nowhere in the real build output -- letting us tell transient progress
-- lines apart from actual diagnostics.
local PROGRESS_MARK = '\27[?2026'

local report = {}
local pending = ''
-- True while a build is actively compiling (between its first compile-progress
-- frame and its `Build Summary` line), so we clear the quickfix only once per
-- build rather than on every progress frame.
local building = false

local function strip_ansi(s)
    s = s:gsub('\27%[%??[%d;]*%a', '') -- CSI: colors, erase, sync-update, cursor moves
    s = s:gsub('\27%][^\27\7]*\27\\', '') -- OSC ... ST
    s = s:gsub('\27%][^\27\7]*\7', '') -- OSC ... BEL
    s = s:gsub('\27[%(%)][0-9A-B]', '') -- G0/G1 charset selection
    s = s:gsub('\27[=>MDE78]', '') -- misc single-char escapes
    s = s:gsub('\27\\', '') -- stray ST
    s = s:gsub('[\r\8]', '') -- CR / backspace
    return s
end

local function notify_trouble()
    -- Fire the event Trouble's qflist view listens on so its auto_open /
    -- auto_close reacts to the background update.
    vim.api.nvim_exec_autocmds('QuickFixCmdPost', { pattern = 'make' })
end

local function clear()
    vim.fn.setqflist({}, 'r', { title = 'zig build', items = {} })
    notify_trouble()
end

local function publish()
    vim.fn.setqflist({}, 'r', { title = 'zig build', lines = report, efm = efm })

    -- zig prints lowercase `error`/`note`; uppercase the type so Trouble maps the
    -- right severity/icon.
    local items = vim.fn.getqflist()
    for _, item in ipairs(items) do
        item.type = item.type:upper()
    end
    vim.fn.setqflist({}, 'r', { title = 'zig build', items = items })

    report = {}
    notify_trouble()
end

local function consume(raw)
    if raw:find(PROGRESS_MARK, 1, true) then
        -- A progress frame, never real output. zig keeps redrawing a
        -- `watching N directories...` frame while idle, so only a *compile*
        -- frame marks a new build -- and on its first one we wipe the stale
        -- results so the quickfix doesn't show outdated errors mid-build.
        if raw:find('watching', 1, true) then
            building = false
        elseif not building then
            building = true
            report = {}
            clear()
        end
        return
    end

    -- Real build output (step tree / diagnostics / summary); frames excluded.
    report[#report + 1] = strip_ansi(raw)

    if report[#report]:match '^Build Summary:' then
        publish()
        building = false
    end
end

local function on_output(_, data)
    if not data then
        return
    end

    pending = pending .. data[1]
    for i = 2, #data do
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
    report, pending, building = {}, '', false

    M.job = vim.fn.jobstart({ 'zig', 'build', '--watch', '-fincremental', '-freference-trace=20' }, {
        cwd = root,
        -- Run under a pty so zig emits its progress bar (it only does on a tty);
        -- a wide width keeps long diagnostic lines from being wrapped.
        pty = true,
        width = 1000,
        on_stdout = on_output,
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
