"""Orchestration for resumable corpus preparation workflows."""

from dataclasses import dataclass
from pathlib import Path
from .state import WorkState, WorkflowStatus


@dataclass
class AdvanceEngine:
    state_root: Path

    def advance(self) -> list[str]:
        """Returns retryable work ids discovered from persistent state files."""
        completed = []
        for state_path in sorted(self.state_root.glob("*/state.json")):
            state = WorkState.load(state_path)
            if any(status != WorkflowStatus.READY for status in state.stages.values()):
                completed.append(state.work_id)
        return completed
