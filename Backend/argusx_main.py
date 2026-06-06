"""ArgusX backend entrypoint.

Exposes the ASGI ``app`` for production servers and provides a ``__main__``
runner for local development:

    uv run uvicorn argusx_main:app --reload      # recommended
    uv run python argusx_main.py                 # equivalent local runner
"""

from __future__ import annotations

from config.argusx_settings import get_settings
from core.argusx_application import ArgusXApplication

# Single composition root instance; `app` is the ASGI entrypoint.
argusx = ArgusXApplication()
app = argusx.app


def main() -> None:
    import uvicorn

    settings = get_settings()
    uvicorn.run(
        "argusx_main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
    )


if __name__ == "__main__":
    main()
