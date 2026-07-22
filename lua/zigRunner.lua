local M = {}

M.job = nil
M.root = nil

-- zig wraps every progress update -- compile progress *and* the idle
-- "watching N directories..." status -- in a DEC synchronized-update region,
-- ESC[?2026h ... ESC[?2026l. A frame spans several lines but only its first
-- carries the begin marker, so we track the region and drop every line inside it.
local FRAME_BEGIN = '\27[?2026h'
local FRAME_END = '\27[?2026l'

local report = {}
local pending = ''
-- True while inside a synchronized-update region (a progress frame).
local in_frame = false
-- True while a build is actively compiling (between its first compile-progress
-- frame and its `Build Summary` line), so we clear the quickfix only once per
-- build rather than on every progress frame.
local building = false

local function strip_ansi(s)
    s = s:gsub('\27%[%??[%d;]*%a', '') -- CSI: colors, erase, sync-update, cursor moves
    s = s:gsub('\27%][^\27\7]*\27\\', '') -- OSC ... ST
    s = s:gsub('\27%][^\27\7]*\7', '') -- OSC ... BEL
    s = s:gsub('\27%(0.-\27%(B', '') -- DEC line-drawing run (zig's build-tree glyphs)
    s = s:gsub('\27[%(%)][0-9A-B]', '') -- stray G0/G1 charset selects
    s = s:gsub('\27[=>MDE78]', '') -- misc single-char escapes
    s = s:gsub('\27\\', '') -- stray ST
    s = s:gsub('[\r\8]', '') -- CR / backspace
    return s
end

-- Classic quickfix: drive the native quickfix window directly. Open it only when
-- there are real (valid) diagnostics -- zig's `Build Summary` / build-step lines
-- parse as invalid entries, so a successful build leaves nothing to show -- and
-- open without stealing focus from the window you're editing in.
local function refresh_window()
    local has_valid = false
    for _, item in ipairs(vim.fn.getqflist()) do
        if item.valid == 1 then
            has_valid = true
            break
        end
    end

    if has_valid then
        local win = vim.api.nvim_get_current_win()
        vim.cmd 'copen'
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_set_current_win(win)
        end
    else
        vim.cmd 'cclose'
    end
end

local function clear()
    vim.fn.setqflist({}, 'r', { title = 'zig build', items = {} })
    refresh_window()
end

local function publish()
    vim.fn.setqflist({}, 'r', { title = 'zig build', lines = report })

    -- zig prints lowercase `error`/`note`; uppercase the type for the right
    -- quickfix sign/severity.
    local items = vim.fn.getqflist()
    for _, item in ipairs(items) do
        item.type = item.type:upper()
    end
    vim.fn.setqflist({}, 'r', { title = 'zig build', items = items })

    report = {}
    refresh_window()
end

-- Position of the last occurrence of a plain substring, or 0 if absent.
local function last_pos(s, sub)
    local at, pos = 0, 1
    while true do
        local i = s:find(sub, pos, true)
        if not i then
            return at
        end
        at, pos = i, i + 1
    end
end

local function consume(raw)
    local began = last_pos(raw, FRAME_BEGIN)
    local ended = last_pos(raw, FRAME_END)

    if began > 0 then
        -- zig keeps redrawing a `watching N directories...` frame while idle, so
        -- only a *compile* frame marks a new build -- and on its first one we wipe
        -- the stale results so the quickfix doesn't show outdated errors mid-build.
        if raw:find('watching', 1, true) then
            building = false
        elseif not building then
            building = true
            report = {}
            clear()
        end
    end

    -- A chunk boundary can merge a frame's closing marker with the next frame's
    -- opening one onto a single line, so the region we end up inside is decided by
    -- whichever marker comes last. Drop any line that opens, closes, or sits
    -- inside a synchronized-update region -- that's all transient progress output.
    local started_in_frame = in_frame
    if began > 0 or ended > 0 then
        in_frame = began > ended
    end
    if started_in_frame or began > 0 or ended > 0 then
        return
    end

    -- Real build output (step tree / diagnostics / summary). Keep it all as
    -- quickfix context; the errorformat in publish() tags the actual diagnostics.
    local line = strip_ansi(raw)
    if line:match '^%s*$' then
        return -- skip blank lines so they don't become empty context entries
    end
    report[#report + 1] = line

    if line:match '^Build Summary:' then
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
    report, pending, in_frame, building = {}, '', false, false

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
