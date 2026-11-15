#!/usr/bin/env bash
# Smoke test for the Neovim config (home/editor/neovim).
#
# Opens a small file of every supported language in headless Neovim, loads this
# config's Lua modules and fails if anything raises a Lua error. It does not need any
# devshell: project tools are simply reported as missing, which is not an error.
#
# Usage (after `nh os switch`, so `nvim` is the configured one):
#   tests/nvim-smoke.sh
# Another nvim:  NVIM=/path/to/nvim tests/nvim-smoke.sh
set -euo pipefail

NVIM=${NVIM:-nvim}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# One sample per language module (languages/*.nix) and per config-file type.
mkdir -p "$work/files"
printf 'class Main {}\n' >"$work/files/Main.java"
printf 'def f():\n    return 1\n' >"$work/files/app.py"
printf '{%% extends "base.html" %%}\n{%% block body %%}hi{%% endblock %%}\n' >"$work/files/page.html"
printf 'export const x: number = 1;\n' >"$work/files/app.ts"
printf 'export const A = () => <div className="p-2" />;\n' >"$work/files/App.tsx"
printf '{ a = 1; }\n' >"$work/files/default.nix"
printf 'a: 1\n' >"$work/files/config.yaml"
printf '{"a": 1}\n' >"$work/files/data.json"
printf 'echo hi\n' >"$work/files/run.sh"
printf '# Title\n' >"$work/files/README.md"
printf 'a = 1\n' >"$work/files/config.toml"
printf 'FROM alpine\n' >"$work/files/Dockerfile"
printf 'local x = 1\n' >"$work/files/init.lua"

# Runs inside Neovim after the file is opened.
cat >"$work/check.lua" <<'EOF'
local failures = {}
local function check(what, ok, err)
  if not ok then
    table.insert(failures, what .. ": " .. tostring(err))
  end
end

-- The config's own modules must load.
for _, mod in ipairs({ "devshell", "lang_java", "lang_python", "lang_web" }) do
  check("require " .. mod, pcall(require, mod))
end
-- Commands this config defines (or relies on) must exist.
for _, cmd in ipairs({ "DevshellStatus", "DevshellReload", "FzfLua", "Trouble" }) do
  check(":" .. cmd, vim.fn.exists(":" .. cmd) == 2, "command missing")
end
-- Commands of features that can be switched off (my.neovim.tasks / my.neovim.test): only
-- required when their plugin is installed.
for cmd, plugin in pairs({ OverseerRun = "overseer", Neotest = "neotest" }) do
  if pcall(require, plugin) then
    check(":" .. cmd, vim.fn.exists(":" .. cmd) == 2, "command missing")
  end
end
-- :DevshellStatus must render for this buffer (also exercises the tool registry).
check("devshell status", pcall(require("devshell").status_lines, 0))

-- Give async work (servers starting, devshell lookups) time to raise errors.
vim.wait(2000, function() return false end)

-- Anything that looks like a Lua error in :messages fails the test.
local messages = vim.api.nvim_exec2("messages", { output = true }).output
for _, line in ipairs(vim.split(messages, "\n")) do
  if line:match("E5108") or line:match("stack traceback") or line:match("Error executing") or line:match("Error in ") then
    table.insert(failures, "message: " .. line)
  end
end

local out = io.open(os.getenv("SMOKE_OUT"), "w")
out:write(vim.bo.filetype .. "\n" .. table.concat(failures, "\n") .. "\n")
out:close()
vim.cmd(#failures == 0 and "qa!" or "cquit 1")
EOF

status=0
for file in "$work"/files/*; do
  name=$(basename "$file")
  result="$work/result-$name"
  if SMOKE_OUT="$result" timeout 60 "$NVIM" --headless "$file" -c "luafile $work/check.lua" >/dev/null 2>"$work/stderr-$name"; then
    printf 'ok    %-14s (%s)\n' "$name" "$(head -1 "$result")"
  else
    status=1
    printf 'FAIL  %-14s\n' "$name"
    [ -f "$result" ] && tail -n +2 "$result" | sed 's/^/        /'
    sed 's/^/        /' "$work/stderr-$name"
  fi
done

# Startup time (Neovim's own measurement, no file opened).
"$NVIM" --headless --startuptime "$work/startup.log" +qa >/dev/null 2>&1 || true
startup=$(grep 'NVIM STARTED' "$work/startup.log" | tail -1 | awk '{print $1}')
echo "startup: ${startup:-?} ms (headless)"

exit $status
