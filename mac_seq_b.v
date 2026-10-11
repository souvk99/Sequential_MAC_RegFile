`timescale 1ns / 1ps

//==============================================================================
// Assignment 1(b): Sequential MAC with Local Register File
//
// Features:
//   - Sequence length N = 9
//   - Signed 8-bit inputs (data_in) and weights (weight_in)
//   - Internal register file (kernel_buff) storing 9 weight coefficients
//   - Weight-load phase: loads 9 weights sequentially when load_weight is high
//   - Compute phase: streams 9 data samples sequentially, computing dot product
//   - Priority logic: Reset > load_weight > compute (valid_in)
//   - Bit-accurate output width [2*W+4:0] (21 bits) to prevent overflow
//==============================================================================

module mac_seq_b #(
    parameter W = 8,
    parameter N = 9
)(
    input  wire                    clk,
    input  wire                    reset_n,
    input  wire                    load_weight, // high during weight loading phase
    input  wire                    valid_in,    // high during data compute phase
    input  wire signed [W-1:0]     weight_in,   // one weight per cycle while loading
    input  wire signed [W-1:0]     data_in,     // one input per cycle while computing
    output reg  signed [2*W+4:0]   mac_out,     // 21-bit signed result (2*8+4 = 20 -> [20:0])
    output reg                     out_valid
);

    // Internal register file for weights
    reg signed [W-1:0] kernel_buff [0:N-1];

    // Index counters
    reg [3:0] load_idx;
    reg [3:0] comp_idx;

    // Accumulator register (21 bits signed)
    reg signed [2*W+4:0] acc;

    // Multiplication
    wire signed [W-1:0]   current_weight;
    wire signed [2*W-1:0] mult_result;

    assign current_weight = kernel_buff[comp_idx];
    assign mult_result    = data_in * current_weight;

    integer i;

    // Priority logic: Reset > load_weight > valid_in (compute)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            load_idx  <= 4'd0;
            comp_idx  <= 4'd0;
            acc       <= {(2*W+5){1'b0}};
            mac_out   <= {(2*W+5){1'b0}};
            out_valid <= 1'b0;
            for (i = 0; i < N; i = i + 1) begin
                kernel_buff[i] <= {W{1'b0}};
            end
        end
        else if (load_weight) begin
            // -------------------------------------------------------------
            // Weight Load Phase (Highest Priority after Reset)
            // Compute is strictly inhibited during weight loading.
            // -------------------------------------------------------------
            out_valid <= 1'b0;
            comp_idx  <= 4'd0;
            acc       <= {(2*W+5){1'b0}};

            kernel_buff[load_idx] <= weight_in;

            if (load_idx == N - 1) begin
                load_idx <= 4'd0; // wrap index upon completion
            end else begin
                load_idx <= load_idx + 4'd1;
            end
        end
        else if (valid_in) begin
            // -------------------------------------------------------------
            // Compute Phase
            // Accumulate products across N cycles
            // -------------------------------------------------------------
            if (comp_idx == N - 1) begin
                // 9th cycle: produce final accumulated MAC result
                mac_out   <= acc + mult_result;
                out_valid <= 1'b1;
                comp_idx  <= 4'd0;
                acc       <= {(2*W+5){1'b0}};
            end else begin
                acc       <= acc + mult_result;
                comp_idx  <= comp_idx + 4'd1;
                out_valid <= 1'b0;
            end
        end
        else begin
            // Idle phase
            out_valid <= 1'b0;
        end
    end

endmodule

