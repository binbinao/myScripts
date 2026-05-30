# Repository Guidelines

## Project Structure & Module Organization
`main.sh` is the entry point for the interactive menu and direct subcommands. Shared Bash helpers live in `lib/` (`common.sh`, `logger.sh`, `safety.sh`), runtime config lives in `config/`, and task scripts are grouped by purpose in `install/`, `cleanup/`, `troubleshoot/`, and `etc/`. Usage notes live in `examples/` and the optional Python crawler is isolated in `crawler/` with its own `requirements.txt` and README.

## Build, Test, and Development Commands
Run the toolkit locally with `./main.sh` for the menu or `bash main.sh help` to list direct commands. Common targeted runs include `./main.sh install-node`, `./main.sh cleanup-packages`, and `./main.sh check-network`. For the crawler, use `cd crawler && pip install -r requirements.txt && playwright install chromium`, then run `python nuscenes_lidarseg_crawler.py`.

## Coding Style & Naming Conventions
Use Bash for shell scripts with 4-space indentation and keep function names in `snake_case`; file names should stay hyphenated and action-oriented, such as `install-node.sh` or `check-services.sh`. Reuse helpers from `lib/` instead of duplicating OS detection, colored output, safety checks, or logging. Keep scripts portable across macOS and Linux, prefer explicit command checks, and default to safe behavior for cleanup operations.

## Testing Guidelines
There is no automated test suite in the repository today, so contributors should do focused manual verification. At minimum, run `bash main.sh help`, exercise the changed command path, and confirm both success and no-op/error branches where practical. For changes under `crawler/`, verify dependency install still works and run the script once against a live environment before merging.

## Commit & Pull Request Guidelines
Match the existing history: short imperative subjects with prefixes such as `feat:`, `docs:`, `etc:`, or scoped forms like `feat(crawler): ...`. Keep commits focused on one script area or behavior change. Pull requests should describe the user-facing impact, list the commands tested, note any OS assumptions (`macOS`, `apt`, `yum`, `dnf`, `brew`), and include screenshots only when output formatting or interactive prompts changed.

## Security & Safety Notes
Do not weaken whitelist or deletion safeguards in `config/` and `lib/safety.sh` without explicitly documenting the risk. Avoid destructive defaults, require confirmation for broad cleanup, and prefer additive config changes over hard-coded machine-specific paths.
