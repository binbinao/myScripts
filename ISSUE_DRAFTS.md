# Issue Drafts

## 1. Fix Bash 3 whitelist compatibility and path matching safety

### Summary
`lib/safety.sh` used `readarray`, which is unavailable in macOS default Bash 3.2. The whitelist matcher also treated any shared prefix as protected, so a path like `~/Desktop-old` could be misclassified when `~/Desktop` was whitelisted.

### Expected
- Work on Bash 3.2 and newer.
- Only exact whitelist matches or children under the whitelisted directory should be protected.

## 2. Respect configurable cleanup depth for node_modules scanning

### Summary
`cleanup/cleanup-node.sh` defined `NODE_MODULES_DEPTH` in `config/paths.conf`, but the script ignored it and always scanned recursively. This makes the search slower than intended on large disks.

### Expected
- Load `config/paths.conf`.
- Pass `NODE_MODULES_DEPTH` through to the `find` call.

## 3. Make Python cache cleanup config-aware and cross-platform

### Summary
`cleanup/cleanup-python.sh` ignored `PYTHON_CACHE_PATTERNS`, used GNU-specific `du -sb`, and included a fallback Python cleanup step that could walk the whole home directory again without repository safety checks.

### Expected
- Honor configured cache patterns.
- Use portable size calculation.
- Restrict the Python fallback to empty `__pycache__` cleanup only.

## 4. Avoid shell-eval deletion for uv cache cleanup

### Summary
`cleanup/cleanup-packages.sh` deleted the uv cache through `run_command "rm -rf ..."`, which routes through `eval`. Direct deletion is simpler and avoids quoting hazards.

### Expected
- Delete with direct `rm -rf -- "$cache_dir"`.
- Preserve logging and success/failure output.
