# Assignment 1(b): 8-Bit Sequential MAC with Local Register File

## 1. Overview & Architecture
This module implements a synthesizable, hardware-efficient **8-bit Sequential Multiply-Accumulate (MAC) Unit** equipped with a **local register file (`kernel_buff`)** for storing weight coefficients.

### Key Specifications:
- **Sequence Length ($N$)**: 9 elements.
- **Data & Weight Precision**: Signed 8-bit (`signed [7:0]`), two's complement format (range $-128$ to $+127$).
- **Local Register File**: 9-entry signed register array (`reg signed [7:0] kernel_buff [0:8]`).
- **Phased Execution**:
  1. **Weight Load Phase**: Sequential loading of 9 weights under `load_weight = 1`.
  2. **Compute Phase**: Sequential streaming of 9 data samples under `valid_in = 1`, computing the dot product against stored weights.
- **Priority Logic**: Reset > `load_weight` > `valid_in` (Compute). Loading weights strictly inhibits computation.
- **Bit-Growth & Overflow Prevention**:
  $$\text{Max Product} = (-128) \times (-128) = 16,384 \text{ (needs 16 bits signed)}$$
  $$\text{Accumulation Growth} = \lceil \log_2(9) \rceil = 4 \text{ bits}$$
  $$\text{Total Required Width} = 16 + 4 = 20 \text{ bits signed}$$
  The output port `mac_out` is sized as `signed [2*W+4:0]` (21 bits, `[20:0]`), mathematically guaranteeing zero overflow.

---

## 2. Port Definitions

| Port | Direction | Width | Type | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | 1 bit | wire | System Clock (100 MHz) |
| `reset_n` | Input | 1 bit | wire | Active-Low Asynchronous Reset |
| `load_weight` | Input | 1 bit | wire | Control signal asserted during weight loading |
| `valid_in` | Input | 1 bit | wire | Control signal asserted during input data streaming |
| `weight_in` | Input | 8 bits | signed wire | Serial weight input during load phase |
| `data_in` | Input | 8 bits | signed wire | Serial data input during compute phase |
| `mac_out` | Output | 21 bits | signed reg | Accumulated dot product output |
| `out_valid` | Output | 1 bit | reg | High for 1 cycle when final result is valid |

---

## 3. How to Run Simulation

You can simulate this design using Icarus Verilog (`iverilog`):

```bash
# Compile
iverilog -o sim_mac_seq_b.vvp mac_seq_b.v tb_mac_seq_b.v

# Execute simulation
vvp sim_mac_seq_b.vvp
```

To view the generated waveforms:
```bash
gtkwave mac_seq_b.vcd
```

