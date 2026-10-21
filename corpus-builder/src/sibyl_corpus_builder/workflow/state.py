"""Persistent state models for per-work corpus preparation.

The state format stores workflow metadata only. Large logs and artifacts stay outside state files.
"""

from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
import json


class WorkflowStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    READY = "ready"
    FAILED = "failed"
    WAITING_EXTERNAL = "waiting_external"


@dataclass
class WorkState:
    work_id: str
    stages: dict[str, WorkflowStatus] = field(default_factory=dict)
    error: dict[str, str] | None = None

    def save(self, path: Path) -> None:
        data = {
            "work_id": self.work_id,
            "stages": {key: value.value for key, value in self.stages.items()},
        }
        if self.error:
            data["error"] = self.error
        path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")

    @classmethod
    def load(cls, path: Path) -> "WorkState":
        data = json.loads(path.read_text(encoding="utf-8"))
        return cls(
            work_id=data["work_id"],
            stages={k: WorkflowStatus(v) for k, v in data.get("stages", {}).items()},
            error=data.get("error"),
        )
