# Vehicle Facts — MODEL (YEAR, ENGINE)

**Purpose:** Single source of truth for all verified vehicle-specific data.
Every entry must have a source column. Missing source = do not use the value.
Run `/vida_init` to populate this file automatically from VIDA SQL.

---

## Vehicle Identification

| Field | Value | Source |
|-------|-------|--------|
| VIN | YOUR_VIN_HERE | Vehicle registration |
| Model | MODEL (PLATFORM) | VIDA fkVehicleModel=MODEL_ID |
| Year | YEAR | VIDA fkModelYear=YEAR_ID |
| Engine | ENGINE_CODE | VIDA carcom / registration |
| Mileage (reference) | — km | (fill in at first readout) |

---

## VIDA DocumentProfile — Vehicle Filter

| Parameter | Value |
|-----------|-------|
| fkVehicleModel | MODEL_ID |
| fkModelYear | YEAR_ID |

These values are found by `/vida_init` querying the VIDA SQL database directly.
Never guess or copy from another vehicle — IDs differ per model and year.

---

## Confirmed VIDA Source Documents

_(empty — populated by each /vida_repair run)_

| VCC Number | Title | Topic | Extracted |
|-----------|-------|-------|-----------|

---

## Not Found in VIDA

_(empty — populated when a search yields no results)_

| Item | Searched on | Search terms |
|------|-------------|-------------|

---

_Last updated: DATE — Vehicle: YOUR_VIN_HERE_
