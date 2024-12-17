local telescope = require("telescope")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

-- Get logbook config if available, otherwise use defaults
local logbook_config = {
	default_path = "~/logbook",
	file_extension = ".md",
}

local M = {}

-- Helper function to ensure path is expanded
local function normalize_path(path)
	-- If path starts with ~, expand it
	if path:match("^~") then
		path = vim.fn.expand(path)
	end

	-- Remove any trailing slashes
	path = path:gsub("/$", "")

	-- Convert to absolute path
	if not path:match("^/") then
		path = vim.fn.fnamemodify(path, ":p")
	end

	return path
end

-- Extension configuration
local config = {
	default_path = normalize_path("~/logbook"),
	file_extension = ".md",
}

-- Try to load logbook configuration if available
local ok, logbook = pcall(require, "logbook.config")
if ok then
	-- If logbook plugin is available, use its normalized path
	config = vim.tbl_deep_extend("force", config, logbook.options)
else
	-- If path was provided directly to telescope extension, normalize it
	config.default_path = normalize_path(config.default_path)
end

-- Helper function to ensure path is expanded
local function get_logbook_path()
	return config.default_path -- Already normalized
end

-- Search through logbook content
M.search_logbooks = function(opts)
	opts = opts or {}

	-- Ensure the logbook directory exists
	local logbook_path = get_logbook_path()
	if vim.fn.isdirectory(logbook_path) == 0 then
		vim.notify("Logbook directory doesn't exist: " .. logbook_path, vim.log.levels.ERROR)
		return
	end

	-- Build the ripgrep command with proper path
	local command = {
		"rg",
		"--color=never",
		"--no-heading",
		"--with-filename",
		"--line-number",
		"--column",
		"--smart-case",
		"--type",
		"md", -- only search markdown files
		".", -- search everything (will be filtered by directory)
		logbook_path, -- specify directory last
	}

	pickers
		.new(opts, {
			prompt_title = "Logbook Search",
			finder = finders.new_oneshot_job(command, {
				entry_maker = function(line)
					-- Parse ripgrep output
					local filename, lnum, col, text = line:match("([^:]+):(%d+):(%d+):(.*)")

					if not filename then
						return nil
					end

					-- Clean up the display text
					text = vim.trim(text)

					return {
						value = line,
						display = string.format("%s:%d: %s", vim.fn.fnamemodify(filename, ":t"), lnum, text),
						ordinal = text,
						filename = filename,
						lnum = tonumber(lnum),
						col = tonumber(col),
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			previewer = previewers.vimgrep.new(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						-- Store current position in jumplist
						vim.cmd("normal! m'")
						-- Open the file and jump to the line
						vim.cmd(string.format("edit +%d %s", selection.lnum, selection.filename))
						-- Move cursor to the correct column
						vim.cmd(string.format("normal! %d|", selection.col))
					end
				end)
				return true
			end,
		})
		:find()
end

-- List all logbook files
M.list_logbooks = function(opts)
	opts = opts or {}

	local logbook_path = get_logbook_path()
	if vim.fn.isdirectory(logbook_path) == 0 then
		vim.notify("Logbook directory doesn't exist: " .. logbook_path, vim.log.levels.ERROR)
		return
	end

	local find_command = {
		"fd",
		"--type",
		"f",
		"--extension",
		string.sub(logbook_config.file_extension, 2), -- remove the leading dot
		".",
		logbook_path,
	}

	pickers
		.new(opts, {
			prompt_title = "Logbook Files",
			finder = finders.new_oneshot_job(find_command, {
				entry_maker = function(entry)
					local filename = entry
					local display = vim.fn.fnamemodify(filename, ":t:r")
					return {
						value = filename,
						display = display,
						ordinal = display,
						path = filename,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			previewer = previewers.new_buffer_previewer({
				title = "Logbook Preview",
				define_preview = function(self, entry)
					local lines = vim.fn.readfile(entry.path)
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
					vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
				end,
			}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						-- Store current position in jumplist
						vim.cmd("normal! m'")
						vim.cmd("edit " .. selection.path)
					end
				end)
				return true
			end,
		})
		:find()
end

-- Register the extension with telescope
return telescope.register_extension({
	exports = {
		logbook = M.search_logbooks,
		logbook_files = M.list_logbooks,
	},
})
