local function buffer_is_in_tab(buffer_to_find)
  local is_in_tab = vim.tbl_contains(vim.api.nvim_list_bufs(), function(buffer)
    return buffer_to_find == buffer and vim.bo[buffer].buflisted
  end, { predicate = true })

  return is_in_tab
end

local function scroll_to_the_end(buffer)
  if not vim.api.nvim_buf_is_valid(buffer) then
    return
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buffer then
      local nr_lines = vim.api.nvim_buf_line_count(buffer)
      vim.api.nvim_win_set_cursor(win, { nr_lines, 0 })
    end
  end
end

-- Get most recent terminal that is visible
local function get_first_terminal()
  local terminal_chans = {}
  for _, chan in pairs(vim.api.nvim_list_chans()) do
    if chan["mode"] == "terminal" and chan["pty"] ~= "" then
      table.insert(terminal_chans, chan)
    end
  end

  if #terminal_chans == 0 then
    return nil
  end

  terminal_chans = vim.tbl_filter(function(chan)
    local hidden = vim.fn.getbufinfo(chan["buffer"])[1].hidden
    local buffer = vim.fn.getbufinfo(chan["buffer"])[1].bufnr
    local is_visible = hidden == 0

    return is_visible and buffer_is_in_tab(buffer)
  end, terminal_chans)

  if not vim.tbl_isempty(terminal_chans) then
    local newest_terminal = terminal_chans[1]
    for _, term in ipairs(terminal_chans) do
      if term["buffer"] < newest_terminal["buffer"] then
        newest_terminal = term
      end
    end

    return newest_terminal["id"], newest_terminal["buffer"]
  end
end

local function send_to_term(cmd_text)
  if not cmd_text then
    return
  end

  local terminal_chan, terminal_buffer = get_first_terminal()

  if not terminal_chan then
    -- If there is not terminal open a new one
    vim.cmd("term")
    terminal_chan, terminal_buffer = get_first_terminal()
  end

  if terminal_chan then
    -- We send the command to the terminal. We add a newline
    -- so the command is executed.
    vim.api.nvim_chan_send(terminal_chan, cmd_text .. "\n")
    scroll_to_the_end(terminal_buffer)
  end
end

local function setup()
  vim.api.nvim_create_user_command("SendToTerm", function(args)
    if #args.args ~= 0 then
      vim.schedule(function() send_to_term(args.args) end)
    else
      vim.ui.input({
        prompt = "SendToTerm",
      }, function(input)
        vim.schedule(function()
          send_to_term(input)
        end)
      end)
    end
  end, { nargs = "?" })
end

return {
  setup = setup,
  send = send_to_term
}
