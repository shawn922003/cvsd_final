# CVSD Final Project — BCH Decoder (Hard/Soft Decision) RTL + Python Reference

This repository contains our BCH decoder project, including:
- **RTL implementation** with VCS simulation flow
- **Synthesis / gate-level / post-layout** simulation setups
- **Python reference models** for decoding using **Berlekamp** and **iBM** algorithms (hard/soft decision)

Supported BCH configurations:
- **BCH(63, 51)**
- **BCH(255, 239)**
- **BCH(1023, 983)**

---

## Repository Structure

```
.
├── rtl_and_sim
│   ├── 01_RTL      # RTL sources + VCS simulation entry
│   ├── 02_SYN      # Synthesis TCL scripts (syn_cg.tcl is the main flow used)
│   ├── 03_GATE     # Gate-level simulation (cycle period setup)
│   ├── 05_POST     # Post-layout simulation (cycle period setup)
│   └── ...
└── python_sim
    ├── bch_sim_63_51
    ├── bch_sim_255_239
    └── bch_sim_1023_983
```

---

## RTL Simulation (VCS)

All RTL codes are under:

- `rtl_and_sim/01_RTL`

### Run a selected pattern

In `rtl_and_sim/01_RTL`, run:

```bash
vcs -f my_rtl.f -pvalue+CYCLE=10 -pvalue+PATTERN=xxx -full64 -R -debug_access+all +v2k +notimingcheck -sverilog
```

- `PATTERN=xxx` selects the test pattern:

| PATTERN | Mode | BCH Code | #Words |
|---:|---|---|---:|
| 100 | Hard-decision decode | (63, 51) | 64 |
| 200 | Hard-decision decode | (255, 239) | 64 |
| 300 | Hard-decision decode | (1023, 983) | 64 |
| 400 | Soft-decision decode | (63, 51) | 64 |
| 500 | Soft-decision decode | (255, 239) | 64 |
| 600 | Soft-decision decode | (1023, 983) | 64 |

### Run TA-provided hard-decision patterns

In `rtl_and_sim/01_RTL`, run:

```bash
./rtlsim.sh
```

---

## Synthesis

Synthesis TCL scripts are under:

- `rtl_and_sim/02_SYN`

Main compile flow used in this project:
- `syn_cg.tcl`

---

## Gate-Level / Post-Layout Simulation

- `rtl_and_sim/03_GATE`: gate-level simulation cycle period setup
- `rtl_and_sim/05_POST`: post-layout simulation cycle period setup

(Please refer to each folder for the corresponding scripts and timing settings.)

---

## Python Reference Model

Python reference models are under:

- `python_sim/`

For each BCH configuration folder, we provide:
- `bch_berlekamp_decode.py`: BCH decoding using **Berlekamp** algorithm (hard/soft decision)
- `bch_ibm_decode.py`: BCH decoding using **iBM** algorithm (hard/soft decision)

The folder name suffix indicates the BCH code configuration:
- `python_sim/bch_sim_63_51/`  → **BCH(63, 51)**
- `python_sim/bch_sim_255_239/` → **BCH(255, 239)**
- `python_sim/bch_sim_1023_983/` → **BCH(1023, 983)**


---

## Results (Table 1: Post-APR Metrics)

Units:
- Time: **ns**
- Power: **W**

### Post-APR Summary

| Metric | Value |
|---|---:|
| Clock Period (ns) | 5.7 |
| Core Utilization | 0.85 |
| Synthesis Area (µm²) | 985133.614543 |
| Core Area (µm²) | 1085616.30 |
| Die Area (µm²) | 1112009.74 |

### Public Test Patterns (Hard-Decision)

| Pattern | Case | Time (ns) | Power (W) |
|---:|---|---:|---:|
| 100 | Hard, 64-word | 390 | 0.0112 |
| 200 | Hard, 255-word | 675 | 0.0136 |
| 300 | Hard, 1023-word | 1883 | 0.0612 |

### Self-Generated Patterns (Soft-Decision)

| Case | Time (ns) | Power (W) |
|---|---:|---:|
| Soft, 64-word | 481 | 0.0185 |
| Soft, 255-word | 766 | 0.0318 |
| Soft, 1023-word | 2180 | 0.0918 |

Note: For each BCH code length, we simulate **only two** self-generated test sequences in both hard-decision and soft-decision modes. These results are mainly used for **functionality verification** under different data patterns; they should not be interpreted as statistically averaged power numbers. All listed sequences pass without functional errors under the **5.7 ns** clock period.

---
