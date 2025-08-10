`timescale 1ns/1ps

module uart_transceiver_tb();

    // Test parameters
    parameter CLK_PERIOD = 20; // 50 MHz clock (20ns period)
    parameter BAUD_RATE = 115200;
    parameter BIT_PERIOD = 1000000000/BAUD_RATE; // Bit period in ns
    
    // Testbench signals
    reg clk;
    reg rst_n;
    
    // TX signals
    reg tx_start;
    reg [7:0] tx_data;
    wire tx_busy;
    wire tx_out;
    
    // RX signals
    wire rx_done;
    wire [7:0] rx_data;
    
    // Loopback: connect TX output to RX input
    wire loopback;
    assign loopback = tx_out;
    
    // Test data
    reg [7:0] test_data [0:9];
    integer i;
    
    // Instantiate the UART transceiver
    uart_transceiver #(
        .CLK_FREQ(50_000_000),
        .BAUD_RATE(115200)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_busy(tx_busy),
        .tx(tx_out),
        .rx(loopback),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Monitor for received data
    always @(posedge rx_done) begin
        $display("Time %0t: Received data: 0x%h", $time, rx_data);
        if (rx_data == tx_data)
            $display("Data matched successfully!");
        else
            $display("ERROR: Data mismatch! Expected: 0x%h, Got: 0x%h", tx_data, rx_data);
    end
    
    // Main test procedure
    initial begin
        // Initialize test data
        test_data[0] = 8'h55; // Alternating 0s and 1s
        test_data[1] = 8'hAA; // Alternating 1s and 0s
        test_data[2] = 8'h00; // All 0s
        test_data[3] = 8'hFF; // All 1s
        test_data[4] = 8'h01; // Single bit
        test_data[5] = 8'h80; // Single bit (MSB)
        test_data[6] = 8'h33; // Some pattern
        test_data[7] = 8'hCC; // Another pattern
        test_data[8] = 8'hA5; // Mixed pattern
        test_data[9] = 8'h5A; // Mixed pattern
        
        // Initialize signals
        rst_n = 0;
        tx_start = 0;
        tx_data = 0;
        
        // Apply reset
        #100;
        rst_n = 1;
        #100;
        
        // Test each data value
        for (i = 0; i < 10; i = i + 1) begin
            // Wait for any previous transmission to complete
            wait(!tx_busy);
            
            // Prepare transmission
            @(posedge clk);
            tx_data = test_data[i];
            $display("\nTime %0t: Transmitting data: 0x%h", $time, tx_data);
            
            // Start transmission
            tx_start = 1;
            @(posedge clk);
            tx_start = 0;
            
            // Wait for transmission to complete and reception to be done
            wait(rx_done);
            #100; // Wait a bit more
        end
        
        // End simulation
        #5000;
        $display("\nUART Transceiver Test Complete");
        $finish;
    end
    
    // Generate waveform file
    initial begin
        $dumpfile("uart_transceiver_tb.vcd");
        $dumpvars(0, uart_transceiver_tb);
    end

endmodule