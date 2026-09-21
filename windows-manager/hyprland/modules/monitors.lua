------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "DP-1",
    mode     = "preferred",
    position = "auto",
    scale    = "1",
})

hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "auto",
    scale    = "1",
})

hl.workspace_rule({ workspace = "1", monitor = "DP-1" , persistent = true})
hl.workspace_rule({ workspace = "2", monitor = "DP-1" , persistent = true})
hl.workspace_rule({ workspace = "3", monitor = "DP-1" , persistent = true})
hl.workspace_rule({ workspace = "4", monitor = "DP-1" , persistent = true})
hl.workspace_rule({ workspace = "5", monitor = "DP-1" , persistent = true})

-- hl.workspace_rule({ workspace = "6", monitor = "eDP-1", persistent = true})
-- hl.workspace_rule({ workspace = "7", monitor = "eDP-1", persistent = true})
-- hl.workspace_rule({ workspace = "8", monitor = "eDP-1", persistent = true})
-- hl.workspace_rule({ workspace = "9", monitor = "eDP-1", persistent = true})
-- hl.workspace_rule({ work2space = "10", monitor = "eDP-1", persistent = true})