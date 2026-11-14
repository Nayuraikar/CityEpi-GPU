# CityEpi-GPU dashboard

React + TypeScript + Vite + Tailwind frontend; FastAPI backend in `../backend` serving files from `../ui_data_bundle`.
Read-only: it visualises recorded results and never runs a simulation.

    # terminal 1 (from repo root)
    cd backend && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
    .venv/bin/uvicorn app.main:app --port 8000

    # terminal 2
    cd frontend && npm install && npm run dev      # http://localhost:5173

Optional: `CITYEPI_DATA_DIR=/path/to/ui_data_bundle` overrides the data location.
GIS deep link: `http://localhost:5173/?lat=12.9716&lng=77.5946&z=16#gis`
