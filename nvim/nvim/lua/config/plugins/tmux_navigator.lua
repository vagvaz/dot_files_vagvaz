return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
    "TmuxNavigatorProcessList",
  },
  keys = {
    -- { "<m-h>",  "<cmd><C-U>TmuxNavigateLeft<cr>" },
    -- { "<m-j>",  "<cmd><C-U>TmuxNavigateDown<cr>" },
    -- { "<m-k>",  "<cmd><C-U>TmuxNavigateUp<cr>" },
    -- { "<m-l>",  "<cmd><C-U>TmuxNavigateRight<cr>" },
    -- { "<m-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    { "<c-h>",  "<cmd>TmuxNavigateLeft<cr>" },
    { "<c-j>",  "<cmd>TmuxNavigateDown<cr>" },
    { "<c-k>",  "<cmd>TmuxNavigateUp<cr>" },
    { "<c-l>",  "<cmd>TmuxNavigateRight<cr>" },
    { "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>" },
  },
}
