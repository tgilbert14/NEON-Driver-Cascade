# Small Mammal schema 2: month-adjusted catch index dry run (2026-10-26)

Produced by `scripts/dryrun_mammal_index.R`, which reads three Small Mammal checkouts
from the command line through the production adapter in `R/source_adapters.R` and writes
nothing under `data/`. Years are limited to the committed family's range
(2013 to 2025); each site's monthly climatology uses every year its bundle carries, as the builder does.

Sources:

- pinned: `d2a53282637e4dbd7e5ebef7f64665fa27028531` (the committed Atlas family's mammal pin is `d2a53282637e4dbd7e5ebef7f64665fa27028531`), shape schema1
- main: `c1a229d332801206bf9c37a294b6f96ee7a7b1f1`, shape schema1
- PR #101 head: `08dc7829a7ca66e7c3e4b4aad1248c07646e54b2`, shape schema2

Rulings applied (lead, M-1 to M-7): a bundle is schema2 when it carries all of
`gridCompletion`, `samplingImpractical` and `eventID`, schema1 when it carries none; a
partial bundle or a mixed set stops. Under schema2 `mammal_cpue` is the month-adjusted
index: per plot-month (plotID by trap-night year-month) CPUE = 100 x tagged capture rows /
resolved trap-nights over trapped plot-months, minus the site's unweighted mean CPUE for
that calendar month, averaged unweighted within the year; it is published only when the
year has 3 or more sampled calendar months and 300 or more trap-nights. Trap-nights,
captures, MNKA and the audit columns stay pooled per year. Under schema1 every output is
unchanged.

## (a) Schema1 parity with the committed family

Pinned bundles through `cascade_mammal_annual(..., "schema1")` against `data/cascade.rds` annual (510 site-year rows; 0 recomputed site-years missing from it):

| column | result |
| --- | --- |
| mammal_cpue | PASS |
| mammal_mnka | PASS |
| mammal_trap_nights | PASS |
| mammal_captures | PASS |
| mammal_placeholder_trap_rows | PASS |
| mammal_multi_capture_trap_events | PASS |
| mammal_reviewed_double_trap_events | PASS |

Overall: PASS.

## (b) SRER under schema2 beside the sibling's values

| year | pooled | sibling_pooled | index | sibling_index | diff | months | trap_nights | ok |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2016 | 37.7 | 37.7 | -3.9 | -3.9 | -0.02 | 8 | 7255.5 | TRUE |
| 2017 | 65.9 | 65.9 | 21.1 | 21.1 | -0.04 | 6 | 3869.5 | TRUE |
| 2018 | 31.2 | 31.2 | -10.6 | -10.6 | 0.05 | 6 | 3429.0 | TRUE |
| 2019 | 35.1 | 35.1 | -4.2 | -4.2 | 0.04 | 6 | 3153.0 | TRUE |
| 2020 | 26.0 | NA | -7.3 | NA | NA | 1 | 684.0 | FALSE |
| 2021 | 40.5 | 40.5 | -4.2 | -4.2 | -0.03 | 3 | 1530.0 | TRUE |
| 2022 | 66.2 | 66.2 | 23.8 | 23.8 | -0.00 | 4 | 1248.5 | TRUE |
| 2023 | 37.9 | 37.9 | -3.9 | -3.9 | 0.02 | 4 | 1483.0 | TRUE |
| 2024 | 24.0 | 24.0 | -13.6 | -13.6 | 0.02 | 3 | 1310.5 | TRUE |

Largest absolute index difference over the gated years: 0.05 CPUE units (the sibling values are rounded to 0.1).

## Coverage: finite `mammal_cpue` site-years

Totals: pinned schema1 410, main schema1 410, PR #101 pooled (same rows, schema1 rule) 410, PR #101 schema2 364.
26 of 46 sites lose at least one year against main: ABBY, BARR, BLAN, CLBJ, CPER, DCFS, DEJU, DSNY, GRSM, GUAN, HEAL, JERC, LENO, MLBS, NIWO, NOGP, ORNL, OSBS, SJER, SOAP, SRER, STER, TEAK, TOOL, WOOD, WREF.
The coverage gate will see this drop at the first refresh that reads schema2 bundles.

Per site (dropped years list the PR #101 site-years that have a pooled CPUE but fail the index gate, with the failing condition):

| site | pinned_s1 | main_s1 | pr101_pooled | pr101_s2 | dropped_years |
| --- | --- | --- | --- | --- | --- |
| ABBY |  9 |  9 |  9 |  7 | 2016 (1 mo); 2020 (2 mo) |
| BARR |  6 |  6 |  6 |  2 | 2017 (2 mo); 2022 (2 mo); 2023 (1 mo); 2024 (1 mo, 260.0 TN) |
| BART | 11 | 11 | 11 | 11 |  |
| BLAN | 10 | 10 | 10 |  9 | 2020 (1 mo) |
| BONA |  8 |  8 |  8 |  8 |  |
| CLBJ |  8 |  8 |  8 |  7 | 2021 (1 mo) |
| CPER | 12 | 12 | 12 | 11 | 2020 (2 mo) |
| DCFS |  8 |  8 |  8 |  7 | 2020 (2 mo) |
| DEJU |  9 |  9 |  9 |  8 | 2016 (2 mo) |
| DELA |  9 |  9 |  9 |  9 |  |
| DSNY | 12 | 12 | 12 |  8 | 2020 (1 mo); 2021 (1 mo); 2023 (1 mo); 2024 (1 mo) |
| GRSM | 10 | 10 | 10 |  6 | 2020 (1 mo); 2021 (2 mo); 2022 (2 mo); 2024 (2 mo) |
| GUAN |  2 |  2 |  2 |  1 | 2017 (2 mo) |
| HARV | 12 | 12 | 12 | 12 |  |
| HEAL | 10 | 10 | 10 |  7 | 2015 (1 mo); 2017 (2 mo); 2021 (2 mo) |
| JERC | 11 | 11 | 11 |  9 | 2020 (1 mo); 2021 (1 mo) |
| JORN |  9 |  9 |  9 |  9 |  |
| KONA |  8 |  8 |  8 |  8 |  |
| KONZ | 10 | 10 | 10 | 10 |  |
| LAJA |  1 |  1 |  1 |  1 |  |
| LENO |  8 |  8 |  8 |  6 | 2023 (1 mo); 2024 (1 mo) |
| MLBS |  8 |  8 |  8 |  6 | 2017 (1 mo); 2020 (1 mo) |
| MOAB |  9 |  9 |  9 |  9 |  |
| NIWO | 10 | 10 | 10 |  9 | 2020 (2 mo) |
| NOGP |  9 |  9 |  9 |  8 | 2020 (2 mo) |
| OAES |  9 |  9 |  9 |  9 |  |
| ONAQ | 10 | 10 | 10 | 10 |  |
| ORNL | 11 | 11 | 11 | 10 | 2020 (1 mo) |
| OSBS | 12 | 12 | 12 | 11 | 2020 (1 mo) |
| RMNP |  8 |  8 |  8 |  8 |  |
| SCBI | 11 | 11 | 11 | 11 |  |
| SERC |  9 |  9 |  9 |  9 |  |
| SJER |  9 |  9 |  9 |  6 | 2016 (1 mo); 2020 (2 mo); 2021 (2 mo) |
| SOAP |  6 |  6 |  6 |  5 | 2021 (2 mo) |
| SRER |  9 |  9 |  9 |  8 | 2020 (1 mo) |
| STEI | 10 | 10 | 10 | 10 |  |
| STER | 11 | 11 | 11 | 10 | 2020 (2 mo) |
| TALL | 10 | 10 | 10 | 10 |  |
| TEAK |  5 |  5 |  5 |  3 | 2021 (1 mo); 2024 (1 mo) |
| TOOL |  6 |  6 |  6 |  4 | 2017 (2 mo); 2021 (1 mo) |
| TREE | 10 | 10 | 10 | 10 |  |
| UKFS | 10 | 10 | 10 | 10 |  |
| UNDE | 11 | 11 | 11 | 11 |  |
| WOOD | 11 | 11 | 11 | 10 | 2020 (2 mo) |
| WREF |  8 |  8 |  8 |  6 | 2017 (1 mo); 2020 (1 mo) |
| YELL |  5 |  5 |  5 |  5 |  |

