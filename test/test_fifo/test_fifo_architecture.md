# FIFO Testbench Architecture

## Description 
  - Test bench use to validate FIFO design functionality, focus on readinng and writing operation

  - **What is FIFO?**
    - A FIFO (First-In, First-Out) is a type of data buffer or memory queue in digital electronics where the first data written into the buffer is the first data that will be read out.
    
    - Key points about FIFO in digital design:

      **Structure**
      - Usually implemented using memory (RAM or registers).
      - Has two pointers:
      + Write pointer (wr_ptr) – points to the next location where new data will be stored.
      + Read pointer (rd_ptr) – points to the next location where data will be read.

      **Control signals**
      - Write enable (wr_en): when active, new data is written to FIFO.
      - Read enable (rd_en): when active, data is read from FIFO.
      - Full flag: indicates FIFO cannot accept more data.
      - Empty flag: indicates FIFO has no data to read.

      **Types of FIFO**
      - Synchronous FIFO: read and write use the same clock.
      - Asynchronous FIFO: read and write use different clocks (common in SoC or crossing clock domains).

      **Usage**
      - Data buffering between two systems with different speeds.
      - Bridging different clock domains.
      - Communication between producer and consumer circuits.

    


