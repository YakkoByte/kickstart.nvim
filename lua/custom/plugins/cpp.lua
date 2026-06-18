-- C/C++ debugging and linting.

vim.pack.add {
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/mfussenegger/nvim-lint',
}

local dap = require 'dap'
local dapui = require 'dapui'
local lint = require 'lint'
local clang_tidy = '/opt/homebrew/opt/llvm/bin/clang-tidy'

vim.keymap.set('n', '<F5>', function() dap.continue() end, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<F10>', function() dap.step_over() end, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F11>', function() dap.step_into() end, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F12>', function() dap.step_out() end, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<leader>db', function() dap.toggle_breakpoint() end, { desc = 'Debug: Toggle Breakpoint' })
vim.keymap.set('n', '<leader>dB', function() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, { desc = 'Debug: Conditional Breakpoint' })
vim.keymap.set('n', '<leader>dr', function() dap.repl.open() end, { desc = 'Debug: Open REPL' })
vim.keymap.set('n', '<leader>du', function() dapui.toggle() end, { desc = 'Debug: Toggle UI' })
vim.keymap.set('n', '<leader>dl', function() dap.run_last() end, { desc = 'Debug: Run Last' })

dapui.setup {
  icons = { expanded = 'v', collapsed = '>', current_frame = '*' },
  controls = {
    icons = {
      pause = 'pause',
      play = 'play',
      step_into = 'into',
      step_over = 'over',
      step_out = 'out',
      step_back = 'back',
      run_last = 'last',
      terminate = 'stop',
      disconnect = 'disc',
    },
  },
}

dap.listeners.after.event_initialized['dapui_config'] = dapui.open
dap.listeners.before.event_terminated['dapui_config'] = dapui.close
dap.listeners.before.event_exited['dapui_config'] = dapui.close

local codelldb = vim.fn.stdpath 'data' .. '/mason/bin/codelldb'
dap.adapters.codelldb = {
  type = 'server',
  port = '${port}',
  executable = {
    command = codelldb,
    args = { '--port', '${port}' },
  },
}

local function executable_prompt()
  return vim.fn.input({
    prompt = 'Path to executable: ',
    default = vim.fn.getcwd() .. '/',
    completion = 'file',
  })
end

dap.configurations.c = {
  {
    name = 'Launch executable',
    type = 'codelldb',
    request = 'launch',
    program = executable_prompt,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
}
dap.configurations.cpp = dap.configurations.c

lint.linters.clangtidy.cmd = clang_tidy
lint.linters_by_ft = vim.tbl_deep_extend('force', lint.linters_by_ft or {}, {
  c = { 'clangtidy' },
  cpp = { 'clangtidy' },
})

local lint_group = vim.api.nvim_create_augroup('custom-cpp-lint', { clear = true })
vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {
  group = lint_group,
  pattern = { '*.c', '*.h', '*.cc', '*.cpp', '*.cxx', '*.hpp', '*.hxx' },
  callback = function(args)
    if vim.bo[args.buf].modifiable then lint.try_lint() end
  end,
})

vim.api.nvim_create_user_command('CppToolingStatus', function()
  local lines = {
    'C/C++ tooling',
    'LSP: clangd',
    'Formatter: clang-format via conform.nvim (<leader>f)',
    'Linter: clang-tidy via nvim-lint on save/insert-leave',
    'Debugger: codelldb via nvim-dap (F5, F10, F11, F12, <leader>db)',
    'clang-tidy: ' .. (vim.fn.executable(clang_tidy) == 1 and clang_tidy or 'not found'),
    'codelldb: ' .. (vim.fn.executable(codelldb) == 1 and codelldb or 'not installed by Mason yet'),
  }
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
end, {})
