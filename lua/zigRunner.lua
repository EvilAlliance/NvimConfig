local uv = vim.uv

local M = {}

M.ev = uv.new_fs_event()

function M.init()
    uv.fs_event_start(M.ev, '.zigReport.txt', {}, function(err, filename, events)
        vim.schedule(function()
            vim.cmd ':cgetfile .zigReport.txt'
        end)
    end)
end

function M.deinit()
    uv.fs_event_stop(M.ev)
end

if vim.fs.root(0, 'build.zig') then
    M.init()
end

return M
