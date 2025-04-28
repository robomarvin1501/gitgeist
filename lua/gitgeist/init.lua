local gg = {}
-- Check if the current file is in a Git repository
local function is_git_repo()
    local handle = io.popen("git rev-parse --is-inside-work-tree 2>/dev/null")
    local result = handle:read("*a")
    handle:close()
    return result:match("true")
end

-- Get the number of commits for the current branch and file
local function get_commit_count(branch_name, filepath)
    local cmd = string.format("git rev-list --count %s -- %s 2>/dev/null", branch_name, filepath)
    local handle = io.popen(cmd)
    local count = tonumber(handle:read("*a"))
    handle:close()
    return count or 0
end

-- Check if the file's extension is in the enabled list
local function is_enabled_extension(filepath)
    local ext = filepath:match("^.+%.([a-zA-Z0-9]+)$")
    if not ext then return false end
    for _, enabled_ext in ipairs(config.enabled_file_extensions) do
        if ext == enabled_ext then
            return true
        end
    end
    return false
end

gg.git_commit_on_save = function ()
    if not is_git_repo() then return end

    -- Get the current file path and name
    local filepath = vim.fn.expand("%:p")
    local filename = vim.fn.expand("%:t:r") -- File name without extension

    -- Check if the file extension is enabled
    if not is_enabled_extension(filepath) then return end

    -- Create a branch name based on the file name
    local branch_name = "edit-" .. filename

    -- Check if the branch already exists
    local branch_exists = vim.fn.system(string.format("git branch --list %s", branch_name))
    if branch_exists == "" then
        -- Create a new branch if it doesn't exist
        vim.fn.system(string.format("git checkout -b %s", branch_name))
    else
        -- Switch to the branch if it exists
        vim.fn.system(string.format("git checkout %s", branch_name))
    end

    -- Get the commit count for the branch and file
    local commit_count = get_commit_count(branch_name, filepath) + 1

    -- Add the file and commit changes
    vim.fn.system(string.format("git add %s", filepath))
    local commit_message = string.format("Auto commit for %s (commit #%d)", filename, commit_count)
    vim.fn.system(string.format("git commit -m '%s'", commit_message))
end

vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*",
    callback = gg.git_commit_on_save,
})

return gg
