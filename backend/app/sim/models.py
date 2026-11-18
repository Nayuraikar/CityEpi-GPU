"""Request model and validation. All user input is validated here before any process is started."""
from __future__ import annotations

import math
import re
from typing import Annotated, Any

from pydantic import BaseModel, ConfigDict, Field, ValidationError, field_validator

from . import config, registry

StrictInt = Annotated[int, Field(strict=True)]
_CTRL = re.compile(r"[\x00-\x1f\x7f]")


class RunRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    dataset: str
    backend: str = "v0"
    days: StrictInt = 100
    seed: StrictInt = 42
    initial_infected: StrictInt = 100
    beta_home: float = Field(0.3, allow_inf_nan=False)   # per-day force of infection at the agent's home location
    beta_work: float = Field(0.3, allow_inf_nan=False)   # ... at the agent's work/destination location
    incubation_days: StrictInt = 3
    infectious_days: StrictInt = 5
    timeout_seconds: StrictInt = config.DEFAULT_TIMEOUT_S
    snapshots: bool = Field(False, strict=True)   # opt-in per-agent daily states (V0 only); off by default
    label: str | None = None

    @field_validator("label")
    @classmethod
    def _label(cls, v):
        if v is None:
            return None
        v = _CTRL.sub(" ", v).strip()
        if len(v) > 80:
            raise ValueError("label must be at most 80 characters")
        return v or None


def _rng(name: str, v, field: str, errors: list, kind: str = "number"):
    lo, hi = config.LIMITS[name]
    if not (lo <= v <= hi):
        errors.append({"field": field, "message": f"{field} must be between {lo:g} and {hi:g}"})


def validate_request(raw: Any) -> tuple[RunRequest | None, list[dict], list[dict], dict | None]:
    """Returns (request, errors, warnings, dataset). `request` is None whenever there are errors."""
    errors: list[dict] = []
    warnings: list[dict] = []
    if not isinstance(raw, dict):
        return None, [{"field": "_body", "message": "request body must be a JSON object"}], [], None
    try:
        req = RunRequest.model_validate(raw)
    except ValidationError as e:
        for err in e.errors():
            loc = ".".join(str(x) for x in err["loc"]) or "_body"
            msg = err["msg"]
            if err["type"] == "int_type" or err["type"] == "int_parsing":
                msg = "must be an integer"
            elif err["type"] == "extra_forbidden":
                msg = "unknown field"
            errors.append({"field": loc, "message": msg})
        return None, errors, warnings, None

    ds = registry.datasets().get(req.dataset)
    if ds is None:
        errors.append({"field": "dataset", "message": f"unknown dataset '{req.dataset}'"})
    spec = registry.BACKENDS.get(req.backend)
    if spec is None:
        errors.append({"field": "backend", "message": f"unknown or unsupported backend '{req.backend}' "
                       f"(supported: {', '.join(registry.BACKENDS)})"})
    else:
        st = registry.backend_status(spec)
        if not st["available"]:
            errors.append({"field": "backend", "message": f"backend {spec.id.upper()} is not available: {st['reason']}"})

    if req.snapshots and spec is not None and not spec.supports_snapshots:
        errors.append({"field": "snapshots", "message": f"per-agent snapshots are currently V0-only; backend {spec.id.upper()} does not support them"})
    if req.snapshots and req.days > config.SNAPSHOT_MAX_DAYS:
        errors.append({"field": "snapshots", "message": f"snapshots are limited to runs of at most {config.SNAPSHOT_MAX_DAYS} days"})
    _rng("days", req.days, "days", errors)
    _rng("seed", req.seed, "seed", errors)
    _rng("initial_infected", req.initial_infected, "initial_infected", errors)
    _rng("incubation_days", req.incubation_days, "incubation_days", errors)
    _rng("infectious_days", req.infectious_days, "infectious_days", errors)
    _rng("timeout_seconds", req.timeout_seconds, "timeout_seconds", errors)
    for f in ("beta_home", "beta_work"):
        _rng("beta", getattr(req, f), f, errors)
    if ds is not None and req.initial_infected > ds["agents"]:
        errors.append({"field": "initial_infected", "message": f"initial_infected cannot exceed the population ({ds['agents']:,} agents)"})

    if not errors:
        if req.initial_infected == 0:
            warnings.append({"field": "initial_infected", "message": "With 0 initial infections no epidemic can start."})
        if ds is not None and req.initial_infected == ds["agents"]:
            warnings.append({"field": "initial_infected", "message": "Every agent starts infected; nobody is left susceptible."})
        if req.beta_home == 0 and req.beta_work == 0:
            warnings.append({"field": "beta_home", "message": "Both transmission rates are 0: infections will never spread."})
    return (req if not errors else None), errors, warnings, ds


def build_args(req: RunRequest, spec: registry.BackendSpec, dataset_path, daily_prefix, json_path, snapshots_dir=None) -> list[str]:
    """Argument vector for extpop_run. Every value is derived from validated typed fields or server-owned paths (no shell)."""
    assert math.isfinite(req.beta_home) and math.isfinite(req.beta_work)
    args = ["--input", str(dataset_path), "--backend", spec.cli_backend,
            "--days", str(req.days), "--seed", str(req.seed), "--init", str(req.initial_infected),
            "--beta-home", repr(float(req.beta_home)), "--beta-work", repr(float(req.beta_work)),
            "--incubation", str(req.incubation_days), "--infectious", str(req.infectious_days),
            "--daily-csv", str(daily_prefix), "--json", str(json_path)]
    if spec.progress_per_day:
        args.append("--progress")
    if req.snapshots:
        assert spec.supports_snapshots and snapshots_dir is not None
        args += ["--snapshots", str(snapshots_dir)]
    args.extend(spec.extra_args)
    return args
