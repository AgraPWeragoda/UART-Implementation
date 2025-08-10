module uart_transceiver(
    input wire clk,           // System clock
    input wire rst_n,         // Active low reset
    
    // UART TX Interface
    input wire tx_start,      // Start transmission
    input wire [7:0] tx_data, // Data to transmit
    output reg tx_busy,       // Transmitter busy
    output reg tx,            // Serial output
    
    // UART RX Interface
    input wire rx,            // Serial input
    output reg rx_done,       // Reception complete
    output reg [7:0] rx_data  // Received data
);

    // Parameters for configuring UART
    parameter CLK_FREQ = 50_000_000;  // 50 MHz default clock
    parameter BAUD_RATE = 115200;     // Default baud rate
    parameter CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;
    
    // TX logic registers
    reg [1:0] tx_state;
    reg [15:0] tx_clk_count;
    reg [2:0] tx_bit_count;
    reg [7:0] tx_shift_reg;
    
    // RX logic registers
    reg [1:0] rx_state;
    reg [15:0] rx_clk_count;
    reg [2:0] rx_bit_count;
    reg [7:0] rx_shift_reg;
    reg rx_d1, rx_d2;          // Double-flop synchronizer for RX input
    
    // Synchronize RX input to avoid metastability
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_d1 <= 1'b1;
            rx_d2 <= 1'b1;
        end else begin
            rx_d1 <= rx;
            rx_d2 <= rx_d1;
        end
    end
    
    // TX state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= IDLE;
            tx_clk_count <= 0;
            tx_bit_count <= 0;
            tx_busy <= 0;
            tx <= 1'b1;         // Idle high
            tx_shift_reg <= 8'h00;
        end else begin
            case (tx_state)
                IDLE: begin
                    tx <= 1'b1;  // Idle high
                    tx_clk_count <= 0;
                    tx_bit_count <= 0;
                    
                    if (tx_start && !tx_busy) begin
                        tx_busy <= 1'b1;
                        tx_shift_reg <= tx_data;
                        tx_state <= START;
                    end
                end
                
                START: begin
                    tx <= 1'b0;  // Start bit is low
                    
                    if (tx_clk_count < CLKS_PER_BIT - 1) begin
                        tx_clk_count <= tx_clk_count + 1'b1;
                    end else begin
                        tx_clk_count <= 0;
                        tx_state <= DATA;
                    end
                end
                
                DATA: begin
                    tx <= tx_shift_reg[0];  // LSB first
                    
                    if (tx_clk_count < CLKS_PER_BIT - 1) begin
                        tx_clk_count <= tx_clk_count + 1'b1;
                    end else begin
                        tx_clk_count <= 0;
                        
                        // Shift data
                        tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
                        
                        if (tx_bit_count < 7) begin
                            tx_bit_count <= tx_bit_count + 1'b1;
                        end else begin
                            tx_bit_count <= 0;
                            tx_state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    tx <= 1'b1;  // Stop bit is high
                    
                    if (tx_clk_count < CLKS_PER_BIT - 1) begin
                        tx_clk_count <= tx_clk_count + 1'b1;
                    end else begin
                        tx_clk_count <= 0;
                        tx_busy <= 1'b0;
                        tx_state <= IDLE;
                    end
                end
                
                default: tx_state <= IDLE;
            endcase
        end
    end
    
    // RX state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state <= IDLE;
            rx_clk_count <= 0;
            rx_bit_count <= 0;
            rx_done <= 0;
            rx_data <= 8'h00;
            rx_shift_reg <= 8'h00;
        end else begin
            // Clear rx_done flag after one clock cycle
            if (rx_done) rx_done <= 1'b0;
            
            case (rx_state)
                IDLE: begin
                    rx_clk_count <= 0;
                    rx_bit_count <= 0;
                    
                    // Detect start bit (falling edge)
                    if (rx_d2 == 1'b0) begin
                        rx_state <= START;
                    end
                end
                
                START: begin
                    // Sample in the middle of the start bit
                    if (rx_clk_count == (CLKS_PER_BIT - 1) / 2) begin
                        // Confirm it's still low (valid start bit)
                        if (rx_d2 == 1'b0) begin
                            rx_clk_count <= rx_clk_count + 1'b1;
                        end else begin
                            // False start, go back to IDLE
                            rx_state <= IDLE;
                        end
                    end else if (rx_clk_count < CLKS_PER_BIT - 1) begin
                        rx_clk_count <= rx_clk_count + 1'b1;
                    end else begin
                        rx_clk_count <= 0;
                        rx_state <= DATA;
                    end
                end
                
                DATA: begin
                    // Sample in the middle of each data bit
                    if (rx_clk_count == (CLKS_PER_BIT - 1) / 2) begin
                        rx_shift_reg <= {rx_d2, rx_shift_reg[7:1]};  // LSB first
                        rx_clk_count <= rx_clk_count + 1'b1;
                    end else if (rx_clk_count < CLKS_PER_BIT - 1) begin
                        rx_clk_count <= rx_clk_count + 1'b1;
                    end else begin
                        rx_clk_count <= 0;
                        
                        if (rx_bit_count < 7) begin
                            rx_bit_count <= rx_bit_count + 1'b1;
                        end else begin
                            rx_bit_count <= 0;
                            rx_state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    // Sample in the middle of the stop bit
                    if (rx_clk_count < CLKS_PER_BIT - 1) begin
                        rx_clk_count <= rx_clk_count + 1'b1;
                    end else begin
                        // Reception complete
                        rx_done <= 1'b1;
                        rx_data <= rx_shift_reg;
                        rx_state <= IDLE;
                    end
                end
                
                default: rx_state <= IDLE;
            endcase
        end
    end

endmodule
