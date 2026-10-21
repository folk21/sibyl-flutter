"""CLI adapter for state-driven corpus workflow commands."""

from pathlib import Path
from .engine import AdvanceEngine

_COMMANDS = {"advance"}


def register_commands(subparsers) -> None:
    parser = subparsers.add_parser("advance", help="Advance incomplete work items from state")
    parser.add_argument("--state-root", type=Path, required=True)


def dispatch(args) -> bool:
    if args.command not in _COMMANDS:
        return False
    for work_id in AdvanceEngine(args.state_root).advance():
        print(work_id)
    return True
