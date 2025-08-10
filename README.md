# UART-Implementation
UART Implementation Assignment for EN2111 Module
# 🚀 UART Transceiver with Custom Testbench (FPGA Project)

This repository contains a **UART (Universal Asynchronous Receiver–Transmitter) transceiver** implementation in Verilog, along with a **custom-built testbench** for functional verification.

> **Important Note**  
> - The `uart_transceiver` module is **third-party provided** and used here as the Device Under Test (DUT).  
> - The `uart_transceiver_tb` module (testbench) was **entirely developed by us** to verify the DUT’s performance and protocol compliance.

## ✨ Features
- **Integrated Tx/Rx Design** – Combines transmitter and receiver into one resource-efficient RTL module.
- **Custom Testbench** – Automated loopback simulation at 115,200 baud.
- **Protocol Accuracy Checks** – Validates framing, bit order, and data integrity.
- **Waveform Output** – ModelSim simulations for timing and logic analysis.
- **Configurable Parameters** – Easily adjust clock frequency and baud rate.

## 🛠 Tools & Technologies
- **HDL:** Verilog  
- **Simulation:** ModelSim  
- **Hardware:** DE0-Nano FPGA Board  

## 📊 Project Overview
The UART transceiver integrates both transmission and reception paths into a single module, sharing the baud-rate generator and I/O resources for reduced FPGA logic utilization.  
The testbench runs a series of loopback tests, ensuring correct data transmission and reception while providing waveform data for debugging and validation.
