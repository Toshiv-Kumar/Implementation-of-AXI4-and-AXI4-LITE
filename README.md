# Implementation-of-AXI4-and-AXI4-LITE
Simplified parameterised AXI4‑Lite and AXI4 wrapper with byte‑enabled synchronous RAM and a randomised testbench. Supports WSTRB, burst‑aware address progression and configurable widths/depths/IDs. Includes a simple RAM model and master_TB for functional verification.
# AXI4-Full-RAM-Interface

**AXI4-Full Protocol Wrapper for a Single-Port RAM in Verilog HDL**
A Verilog-based implementation of an **AXI4-Full slave interface** wrapping a single-port RAM, focusing on **burst transactions, byte-strobe writes, FSM-based channel control, and word-vs-byte addressing translation**, verified using a randomized testbench and simulation waveforms.

![AXI4](https://img.shields.io/badge/Protocol-AXI4--Full-blue?style=flat-square) <img src="https://img.shields.io/badge/HDL-Verilog-blue.svg" /> <img src="https://img.shields.io/badge/Domain-Bus%20Protocol%20Design-orange.svg" /> <img src="https://img.shields.io/badge/EDA-Generic%20Simulator-brightgreen.svg" />

---

## 🧩 Overview

This project presents the **design, implementation, and verification of an AXI4-Full slave interface** (`axi_full_wraps_ram`) that sits between an AXI **Master (Manager/CPU)** and a **single-port RAM (Subordinate)**, using Verilog HDL.

The wrapper implements all five AXI4 channels — Write Address (AW), Write Data (W), Write Response (B), Read Address (AR), and Read Data (R) — using independent FSMs for the write and read paths. It handles **INCR burst transactions**, **byte-level write masking (WSTRB)** over a word-addressable RAM, and **DECERR** response generation for out-of-range addresses.

The design is verified using a self-driving, randomized testbench (`master_TB`) that exercises all five channels concurrently using `$urandom()` stimulus.

---

## ✨ Features

* AXI4-Full slave interface wrapping a single-port RAM
* Full implementation of AW, W, B, AR, and R channels
* INCR burst mode support with configurable burst length (`AWLEN`/`ARLEN`) and size (`AWSIZE`/`ARSIZE`)
* Byte-level write masking via `WSTRB` on a word-addressable RAM
* FSM-based write and read control paths (`IDLE → WRITE/READ → RESP`)
* `DECERR` response generation for out-of-range write addresses
* Randomized, self-driving testbench (`master_TB`) exercising all channels concurrently
* FPGA- and ASIC-friendly RTL design practices

---

## 📊 Simulation Waveforms & Schematic

### AXI4 Transaction Waveform
<img width="1221" height="942" alt="image" src="https://github.com/user-attachments/assets/63b8f5d9-690a-4285-9003-2bfc341f8d7c" />


### Synthesis and RTL Schematic
<img width="1067" height="642" alt="image" src="https://github.com/user-attachments/assets/7581c9c9-4687-4ec4-8b17-53a3159e3554" />
##### Synthesized Schematic below:
<img width="1075" height="530" alt="image" src="https://github.com/user-attachments/assets/d612846d-fb37-46a0-b265-a63da89579cb" />

---

## 🛠️ EDA Tools & Technologies

* **HDL:** Verilog
* **Design Style:** RTL + FSM-based Structural Modeling
* **Verification:** Testbench-driven simulation (`master_TB`) with randomized stimulus (`$urandom()`)
* **Protocol:** AMBA AXI4-Full (Write Address, Write Data, Write Response, Read Address, Read Data channels)
* **Burst Type:** INCR (incrementing burst)

---

## 📘 Learnings / Challenges

> *Learnings/Challenges: (Put some of these in the synth checklist) — check reset in all blocks: 1 or 0*

**Best Learning:** I nearly derived the industrial standard standard layered testbench myself without knowing what layered testbench actually is. I felt the need of randomized blocks such that there is no biasness in the functional verification and so I used $urandom system directive many times. Along with that I kept a few things seperate such as: 
Stimulus generation: ✔ You separate the generation of AXI parameters (AWLEN, AWSIZE, AWBURST, etc.) from the DUT logic instead of hardcoding them inside the DUT.
Driver: ✔ Your always @(posedge aclk_tb) block acts as a driver by performing the AXI handshakes (AWVALID, WVALID, ARVALID, RREADY, etc.) according to the DUT state.
Protocol awareness: ✔ You're driving transactions based on AXI protocol states (idle, write, read, resp) rather than simply toggling signals randomly.
Separation from DUT: ✔ The DUT contains only design logic, while the TB generates and controls transactions.
✘ A monitor that passively observes the AXI interface without driving it.
✘ A scoreboard/reference model that automatically checks whether every read/write is correct.
✘ A separate transaction generator (currently generation and driving are mixed in the same always block).


1. Outstanding transactions mean that multiple transaction requests can be issued by the master to the slave without waiting for the completion of previous transactions.

2. The idea behind `localparam` (added in the Verilog-2001 standard) is to protect its value from accidental or incorrect redefinition by an end user — unlike a `parameter`, a `localparam`'s value cannot be modified through parameter redefinition or a `defparam` statement.

```verilog
module tb;
    // Module instantiation override
    design_ip #(BUS_WIDTH = 64, DATA_WIDTH = 128) d0 ( [port list] );

    // Use of defparam to override
    defparam d0.FIFO_DEPTH = 128;
endmodule
```

3. How do we declare wires/registers that let a hierarchical top module communicate with its instantiated submodule? In Verilog, the rule is: **connect a source to a sink, not a sink to a sink.** So, for a child module inside a parent:

   - **Child output → Parent output**: Not a direct, legal functional connection in the usual sense, since both are outputs — neither is meant to drive the other. Instead, connect both to the same intermediate wire/net, where that net is driven only by the child output and then exported by the parent.
   - **Child input → Parent output**: Valid only if the parent output drives the child input through a net. In practice, a parent `output` is just a port; internally it is usually a `wire` unless declared otherwise, so it can connect to the child input.
   - **Child output → Parent input**: Valid. This is the normal case — the child drives a net, and the parent exposes it through an output port.
   - **Child input → Parent input**: Not a direct driving connection. Two inputs are both receivers, so they aren't meant to drive each other. If you want them tied together, use a shared net that drives both from elsewhere.

4. Learned the difference between byte addressing and bit addressing.

5. Direct Memory Access (DMA) lets certain hardware subsystems access main system memory directly, without going through the CPU for every transfer. [1]

   Without DMA, the CPU has to manage data transfers itself (programmed I/O), which keeps it occupied for the full duration of the transfer and unable to do other work. With DMA, the CPU only sets up the transfer and then moves on to other tasks while the DMA controller (DMAC) handles the actual movement of data, notifying the CPU with an interrupt once it's done. This is especially useful whenever the CPU can't keep pace with the data-transfer rate, or when it needs to stay busy with other work while a slower transfer completes in the background.

6. Can a testbench declare an output signal connected to a DUT input as a `wire`, if it's meant to be driven by some logic? Yes — but with a caveat: if a signal is connected to a DUT input and the testbench logic drives it, it should typically be declared as a `reg` in Verilog (or `logic` in SystemVerilog). Use `wire` only when it's driven by a continuous assignment or by another module's output.

7. **Challenge:** The RAM I designed was word-addressable, while AXI works with byte addressing. This required changes to the design to make the two compatible.

8. **Learning — Why AXI Uses Bursts:**
   AXI bursts improve bandwidth by sending one address followed by multiple consecutive data transfers, avoiding the overhead of sending a new address for every word. For example, writing 16 words individually would require 16 address handshakes, whereas a burst needs only one address handshake followed by 16 data beats. A single-port RAM can access only **one memory location per clock cycle** (it can't write to two different locations at once, since it has only one write port). If the AXI/CPU side sends byte-addressable data over an 8-byte-wide transfer, two consecutive locations in a 32-bit RAM would need to be written — which is why `AWSIZE` is limited to the RAM's max data width. A burst lets the AXI wrapper perform these writes efficiently, sequentially, over consecutive clock cycles, while keeping the address channel free for future transactions — increasing throughput without needing multiple RAM write ports.

9. **Feature:** Implements concurrent read and write transactions between the manager and subordinate through burst mode.

10. **Learning:** `%0d` means the field width will be just wide enough to show the full value of a variable. `%o` is the octal radix format specifier.

11. **Challenge:** Implementing burst support was difficult once I realized the CPU was pulling data using byte addressing rather than word addressing from the RAM. I had to change a lot of the logic in the AXI interface to make the word-addressable RAM compatible with byte-addressable data from the CPU.

12. **Learning:** In Verilog, a part-select such as `mem[w_addr][31:24]` requires the bit positions (`31` and `24`) to be **compile-time constants**. For example:

```verilog
for (i = 0; i < 4; i = i + 1)
    mem[w_addr][8*i+7 : 8*i] <= ...
```

   This causes a compiler error, because `8*i+7` and `8*i` depend on the loop variable `i`, which isn't treated as a constant part-select in Verilog-2001. This restriction exists because Verilog was originally designed for static hardware — the compiler needs to know exactly which wires connect to which bits at elaboration time, rather than deciding the slice boundaries at runtime. Allowing variable part-selects would effectively require a programmable bit selector (a multiplexer) instead of fixed wiring.

   SystemVerilog later introduced **indexed part-selects** to solve this, allowing expressions like `mem[w_addr][8*i +: 8]` or `mem[w_addr][8*i+7 -: 8]`, where the **width is constant (8 bits)** but the starting position can vary. This is synthesizable and is the recommended parameterized solution if your tool supports SystemVerilog.

### Layered testbench overview:
A **layered testbench** is a verification methodology, **not a SystemVerilog feature**. Although it became popular with SystemVerilog and UVM, we can absolutely write one in **plain Verilog (.v)** by separating responsibilities into different tasks/modules instead of putting everything inside one `initial` block. The goal is to make the testbench modular, reusable, and easier to maintain as the design grows. 
### Flat testbench (what most beginners write)

Everything is mixed together:

```text
initial begin
    reset;

    // Generate inputs
    A = 10;
    B = 20;

    // Drive DUT
    valid = 1;
    @(posedge clk);

    // Check outputs
    if (result != 30)
        $display("FAIL");
end
```

As the DUT becomes larger (UART, AXI, CPU, etc.), this quickly becomes difficult to maintain.

---

## Layered testbench

Instead of mixing everything, divide it into layers.

```text
              TEST
                │
        chooses test case
                │
                ▼
          Stimulus Generator
     (creates transactions)
                │
                ▼
             Driver
   (converts transaction to DUT pins)
                │
                ▼
              DUT
                │
        ┌───────┴────────┐
        ▼                ▼
     Monitor         Reference Model
 (samples outputs)  (expected result)
        │                │
        └───────┬────────┘
                ▼
            Scoreboard
      (compare actual vs expected)
```

Each block has **one responsibility**, making it easier to extend and debug. ([picture.iczhiku.com][1])

---

## Small Verilog example (Adder)

Instead of one huge `initial` block, write separate tasks.

```verilog
task generate_transaction;
begin
    a = $random;
    b = $random;
end
endtask

task drive;
begin
    @(posedge clk);
    valid = 1;
end
endtask

task monitor;
begin
    @(posedge clk);
    dut_result = result;
end
endtask

task check;
begin
    expected = a + b;

    if (dut_result != expected)
        $display("FAIL");
end
endtask

initial begin
    repeat (100) begin
        generate_transaction();
        drive();
        monitor();
        check();
    end
end
```

Notice that the **main test** doesn't know how to drive signals or check results—it simply calls each layer in order.

---

## For my AXI project
* **Generator**: randomly generates `AWADDR`, `AWLEN`, `AWSIZE`, `WDATA`, etc.
* **Driver**: performs the AXI handshakes (`AWVALID`, `WVALID`, `ARVALID`, etc.).
* **Monitor**: observes `BRESP`, `RDATA`, `RLAST`, etc., without driving signals.
* **Scoreboard**: maintains a software model of RAM and checks that every read/write matches the expected contents.


---

## 📚 References

1. AMBA AXI PROTOCOL FULL COURSE by ALL ABOUT VLSI: https://youtube.com/playlist?list=PLqPfWwayuBvOuCQS9yakPb1AQRzIA36np&si=MC9nmSvhB4zcwQ84
2. AMBA® AXI Protocol Specification
---

## Differences between different AXI versions
### AXI IDs (Concise Notes)

In a **single-master, single-RAM AXI4 system**, transactions are usually processed **in order**, so ID fields provide little practical benefit. The write data channel cannot be overtaken by another burst, and write responses generally return in the same order. This is why **AXI-Lite omits ID signals entirely**.

However, IDs become important when **multiple transactions are outstanding**, **multiple slaves** are connected through an interconnect, or a **slave processes requests internally in parallel**. In such systems, responses may complete out of order. The ID field allows the master to correctly associate each response with the transaction that generated it.

A useful analogy is a restaurant: a waiter takes orders sequentially, but different chefs may prepare meals in parallel, causing a later order to finish first. The order number (ID) ensures each customer receives the correct meal.

**Note:** The diagrams showing **AWID**, **WID**, and **BID** correspond to **AXI3**. AXI3 supported **write-data interleaving**, so each write data beat required a **WID**. AXI4 removed write-data interleaving, making **WID unnecessary**. In AXI4, write data must follow the order of the corresponding write addresses.

## Implementation-of-AXI4-and-AXI4-LITE — Protocol Understanding

Why the protocol exists: AXI exists so bus traffic doesn’t stall waiting for one slow transfer to finish. Splitting a transaction into five independent channels (write address, write data, write response, read address, read data) lets a master issue a new address before the previous transfer’s data phase has even completed, and lets reads and writes proceed fully independently of each other — which is why AXI underlies high-bandwidth interconnects where APB’s single-outstanding-transaction model would bottleneck.

How a transaction takes place (a single write):

Master drives AWADDR, AWLEN (burst length), AWSIZE, AWBURST and asserts AWVALID.
The address transfers on the clock edge where AWVALID and AWREADY are both high — this VALID/READY handshake is the one rule every AXI channel follows, and it’s what lets either side insert wait cycles without breaking the protocol.
Master drives WDATA and WSTRB per beat, asserting WVALID; slave asserts WREADY when ready. Repeats for AWLEN+1 beats, with WLAST on the final one.
Once all beats are accepted, the slave returns BRESP (OKAY/DECERR) and asserts BVALID; the master asserts BREADY to complete it.
---
A read mirrors this with ARADDR/ARVALID/ARREADY and RDATA/RRESP/RLAST/RVALID/RREADY — no separate response channel is needed since RRESP rides with the data itself.

What each important signal does:

AWADDR/ARADDR — burst start address
AWLEN/ARLEN — beats per burst, minus 1
AWVALID/AWREADY (and the matching pair on every other channel) — the handshake: a transfer happens only on the cycle both are high
WDATA/WSTRB — the data beat and which bytes of it are actually meant to be written
RDATA/RRESP, BRESP — returned data/status
WLAST/RLAST — marks the final beat

How data moves between components: Write: address then data beats flow master→slave, response flows back only after all data is accepted. Read: address flows master→slave, data flows back slave→master beat by beat. Because channels are independent, a read address can be outstanding while write data for an earlier write is still being sent.

Different operating conditions: Back-to-back bursts (new AWVALID before the previous response completes); slave not ready (master just holds VALID/data stable — nothing is lost); partial-word writes (WSTRB masks the untouched bytes); out-of-range address (handshake still completes, but BRESP returns DECERR instead of OKAY).

What can go wrong: Deasserting VALID before READY is actually seen (a protocol violation); byte-vs-word addressing mismatches when the underlying memory isn’t natively byte-addressable (this was a real bug I hit); mishandling WLAST/RLAST, which can truncate or overrun a burst; without a monitor/scoreboard, data-integrity errors in a long burst are easy to miss from waveform snapshots alone.
---
## Implementation-of-AXI4-and-AXI4-LITE

Q: Tell me about your project.

Problem: AMBA AXI exists because a simple shared bus stalls the whole system during a slow transfer — only one source can drive it at a time. AXI solves this by splitting a transaction into independent channels (address, data, response) so address and data phases can overlap, and a master can issue a new address before the previous transaction’s data phase even finishes. The goal was to build an AXI4-Full slave wrapper around a simple RAM that exposes all five channels correctly.

Approach: I designed independent FSMs for the write and read paths rather than one shared control path, since AXI’s channels are meant to progress concurrently. Each FSM runs an address phase, a data phase, and (for writes) a response phase — matching the real handshake, where a transfer only completes on the clock edge where VALID and READY are both high.

Implementation: AWADDR/ARADDR carry the starting address, AWLEN/ARLEN the burst length, WDATA/WSTRB the write payload and byte mask, and RDATA/RRESP/BRESP return read data and status. Since the RAM underneath is word-addressable but AXI is byte-addressed, most of the real effort went into translating burst addresses and WSTRB masks into the correct word offset and byte lane on every beat. INCR bursts auto-increment the address; a DECERR response fires whenever the computed address runs past the RAM’s valid range.

Testing: A randomized, self-driving testbench drives both channels concurrently with $urandom-based address, data, and wait-state stimulus, checked against waveforms for correct handshake timing and data integrity across bursts.

Result: A working AXI4-Full slave handling INCR burst reads/writes, byte-masked partial writes, and out-of-range DECERR responses, fully simulation-verified.

Challenges: The byte-vs-word addressing mismatch was the hardest bug — early versions wrote to the wrong word boundary on non-aligned bursts, fixed by computing the word index and byte-lane selection explicitly rather than assuming a direct pass-through. The next step would be a monitor and software scoreboard, since correctness is still checked by reading waveforms rather than an automatic checker.
---
## Implementation-of-AXI4-and-AXI4-LITE
🧠 Design Decisions
Chose INCR burst mode exclusively (not FIXED/WRAP) since the target RAM is straightforward sequential memory, matching the design’s own parameter comment — this avoided the extra address-wrap logic WRAP would need for a use case that doesn’t require it.
Used independent FSMs for the write and read paths rather than one shared FSM, so read and write transactions can proceed concurrently — this is what directly enables concurrent read/write support.
Reserved the top of the 16-location address range (write_addr_reg >= 4'b1110) to deliberately trigger DECERR responses, giving the testbench a way to exercise the slave-error path without needing a genuinely out-of-range address.
⚖️ Trade-offs and Outcomes
Built the testbench with separated, driver-like stimulus logic instead of one monolithic initial block — cost more structure up front, but surfaced the word-vs-byte addressing mismatch that a flatter testbench likely would have masked, and ended up mirroring real layered-testbench practice.
Skipped a full scoreboard/reference model in favor of manual waveform checking — got a working, verified design faster, with the scoreboard identified as the clear next step for a more rigorous environment.
Kept the memory small (depth=16) rather than a larger address space — made waveforms small enough to manually trace while debugging, at the cost of not stress-testing a wider address range.
