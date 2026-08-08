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
    return buffer_is_in_tab(chan["buffer"])
  end, terminal_chans)

  local function get_bufinfo(chan)
    return vim.fn.getbufinfo(chan["buffer"])[1]
  end

  table.sort(terminal_chans, function(a, b)
    -- If both visible or both hidden, return last used first
    if get_bufinfo(a).hidden == get_bufinfo(b).hidden then
      return get_bufinfo(a).lastused > get_bufinfo(b).lastused
    end

    return get_bufinfo(a).hidden < get_bufinfo(b).hidden
  end)

  local terminal = terminal_chans[1]
  if terminal then
    return terminal["id"], terminal["buffer"]
  end
end

local function show_terminal_in_last_window(buffer)
  if vim.fn.bufwinid(buffer) ~= -1 then
    return
  end

  local win = vim.b[buffer].send_to_term_win
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_buf(win, buffer)
  else
    vim.cmd("sbuffer " .. buffer)
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

  if terminal_buffer then
    show_terminal_in_last_window(terminal_buffer)
  end

  if terminal_chan then
    -- We send the command to the terminal. We add a newline
    -- so the command is executed.
    vim.api.nvim_chan_send(terminal_chan, cmd_text .. "\n")
    scroll_to_the_end(terminal_buffer)
  end
end

local function setup()
  vim.api.nvim_create_autocmd("BufWinLeave", {
    callback = function(event)
      if vim.bo[event.buf].buftype == "terminal" then
        vim.b[event.buf].send_to_term_win = vim.api.nvim_get_current_win()
      end
    end,
  })

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
