local whycode = {}

local the_client

function whycode.stop()
  assert(the_client)
  the_client.stop(true)
  the_client = nil
end

local function make_on_attach(user_on_attach, verb)
  return function(client, bufnr)
    if not the_client then
      the_client = client
    elseif the_client ~= client then
      error("Why3 client must be unique")
    end

    if user_on_attach then
      user_on_attach(client, bufnr)
    end

    vim.hihi = require("whycode.hi")
    vim.hihi.init_highlights()
    vim.hihi.run_autocommands()

    vim.notify = require("notify")
  ---@diagnostic disable-next-line: param-type-mismatch
    vim.notify("Starting Why3 server", "info", {
      title = "why3-nvim",
      timeout = 700,
      on_close = function()
        vim.cmd("Trouble diagnostics toggle")
      end
    })

  vim.keymap.set("n", "<leader>r",
    function()
      local uri = client.workspace_folders[1].uri
      local ok = vim.lsp.buf_notify(0, "proof/reloadSession", { uri })
      if ok then
        print("Session reloaded")
      else
        local err = string.format("[ERROR] Notification proof/reloadSession failed (with uri=%s)", uri)
        error(err)
      end
    end, { desc = "lsp - reloadSession", buffer = bufnr, remap = false })

  end
end

function whycode.setup(opts)

  opts = opts or {}
  opts.cmd = opts.cmd or
    error("You have not defined a server default command for a server that requires it.\
           Please follow README instructions")
  opts.filetype = opts.filetype or { "why3", "coma" }
  opts.verbose = opts.verbose or false
  opts.capabilities = opts.capabilities or {}

  local lsp = require("lspconfig")
  local util = require("lspconfig.util")
  local configs = require("lspconfig.configs")

  opts.on_attach = make_on_attach(opts.on_attach, opts.verbose)

  if not configs["why3"] then
    configs["why3"] = {
      default_config = {
        autostart = true,
        cmd = opts.cmd,
        filetypes = opts.filetype,
        root_dir = function(fname)
          return util.find_git_ancestor(fname)
        end;
        on_attach = opts.on_attach,
        capabilities = opts.capabilities,
        settings = {},
      },
    }
  end

  lsp["why3"].setup({})

  --[[ local plugin = "why3-nvim"

  vim.notify = require("notify")

  vim.notify("This is an error message.\nSomething went wrong!", "error", {
    title = plugin,
    on_open = function()
      vim.notify("Attempting recovery.", vim.log.levels.WARN, {
        title = plugin,
      })
      local timer = vim.loop.new_timer()
      timer:start(2000, 0, function()
        vim.notify({ "Fixing problem.", "Please wait..." }, "info", {
          title = plugin,
          timeout = 3000,
          on_close = function()
            vim.notify("Problem solved", nil, { title = plugin })
            vim.notify("Error code 0x0395AF", 1, { title = plugin })
          end,
        })
      end)
    end,
  }) ]]
end


return whycode
