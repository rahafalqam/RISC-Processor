
## Project Overview

This project focuses on designing and implementing a simple 32-bit RISC processor using Verilog HDL for the ENCS4370 Computer Architecture course.

The processor supports R-Type, I-Type, and J-Type instructions and includes the main components required for processor execution and verification.

## Features

- 32-bit instruction and data word size.
- 16 general-purpose registers (R0–R15).
- R0 is hardwired to zero.
- R-Type, I-Type, and J-Type instruction formats.
- Arithmetic and logical operations.
- Memory access instructions.
- Branch and jump instructions.
- Processor datapath and control path.
- Verilog testbenches and simulation resources.

## Processor Components

- Datapath
- Control Unit
- ALU (Arithmetic Logic Unit)
- Register File
- Instruction Memory
- Data Memory
- Program Counter (PC)
- Testbenches

## Instruction Set

The project specification includes the following instructions:

**R-Type:** ADD, SUB, AND, OR, XOR, NOR, SLL, SRL, CLR, JR

**I-Type:** ADDI, ANDI, ORI, LW, Lb, SW, SWAP, BEQ, BNE

**J-Type:** J, JAL

Refer to the project specification and source code for the instruction encodings and exact behavior.

## Tools and Technologies

- Verilog HDL
- Verilog Simulator
- Testbench-Based Verification
- Assembly Test Programs
- Machine-Code Instruction Files

## Project Structure

- `01_Verilog_Source/` — Verilog source files.
- `02_Testbenches/` — Testbench files.
- `03_Assembly_Programs/` — Assembly test programs.
- `04_Binary_Instructions/` — Machine-code instruction files.
- `05_Supporting_Data/` — Supporting documentation and simulation resources.
- `datapath_full.png` — Processor datapath diagram.
- `ENCS4370_Project2_Report.docx` — Project report.

## How to Run

1. Open the Verilog source files in a compatible simulator.
2. Add the required modules to the simulation project.
3. Select the appropriate testbench.
4. Configure the instruction memory files if required.
5. Run the simulation.
6. Review the simulation output and waveforms.
7. Compare the results with the expected behavior.

## Verification

The project requires test programs that collectively verify the implemented instructions. Simulation results, expected outputs, and waveform screenshots should be reviewed and included in the final report.

## Course Information

**Course:** ENCS4370 — Computer Architecture  
**Project:** Project No. 2  
**Semester:** Summer 2025/2026

