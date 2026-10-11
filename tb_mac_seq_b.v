`timescale 1ns / 1ps

module tb_mac_seq_b;

    parameter W = 8;
    parameter N = 9;

    reg                     clk;
    reg                     reset_n;
    reg                     load_weight;
    reg                     valid_in;
    reg  signed [W-1:0]     weight_in;
    reg  signed [W-1:0]     data_in;
    wire signed [2*W+4:0]   mac_out;
    wire                    out_valid;

    // Instantiate DUT
    mac_seq_b #(
        .W(W),
        .N(N)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .load_weight(load_weight),
        .valid_in(valid_in),
        .weight_in(weight_in),
        .data_in(data_in),
        .mac_out(mac_out),
        .out_valid(out_valid)
    );

    // Clock generation: 100 MHz (10 ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // Test arrays
    reg signed [W-1:0] test_weights [0:N-1];
    reg signed [W-1:0] test_data_1  [0:N-1];
    reg signed [W-1:0] test_data_2  [0:N-1];

    integer expected_dot_prod_1;
    integer expected_dot_prod_2;
    integer errors;
    integer i;

    initial begin
        $dumpfile("mac_seq_b.vcd");
        $dumpvars(0, tb_mac_seq_b);

        errors = 0;
        clk = 0;
        reset_n = 0;
        load_weight = 0;
        valid_in = 0;
        weight_in = 0;
        data_in = 0;

        // Initialize test vectors (signed values, positive and negative)
        // 9 weights: {2, -3, 4, -5, 6, -7, 8, -9, 10}
        test_weights[0] =  8'sd2;
        test_weights[1] = -8'sd3;
        test_weights[2] =  8'sd4;
        test_weights[3] = -8'sd5;
        test_weights[4] =  8'sd6;
        test_weights[5] = -8'sd7;
        test_weights[6] =  8'sd8;
        test_weights[7] = -8'sd9;
        test_weights[8] =  8'sd10;

        // Vector 1: {1, 2, -3, 4, -5, 6, -7, 8, -9}
        test_data_1[0] =  8'sd1;
        test_data_1[1] =  8'sd2;
        test_data_1[2] = -8'sd3;
        test_data_1[3] =  8'sd4;
        test_data_1[4] = -8'sd5;
        test_data_1[5] =  8'sd6;
        test_data_1[6] = -8'sd7;
        test_data_1[7] =  8'sd8;
        test_data_1[8] = -8'sd9;

        // Vector 2: all maximum negative values -128
        for (i = 0; i < N; i = i + 1) begin
            test_data_2[i] = -8'sd128;
        end

        // Compute expected dot products
        expected_dot_prod_1 = 0;
        for (i = 0; i < N; i = i + 1) begin
            expected_dot_prod_1 = expected_dot_prod_1 + (test_data_1[i] * test_weights[i]);
        end

        expected_dot_prod_2 = 0;
        for (i = 0; i < N; i = i + 1) begin
            expected_dot_prod_2 = expected_dot_prod_2 + (test_data_2[i] * test_weights[i]);
        end

        $display("==================================================================");
        $display(" RUNNING TESTBENCH FOR ASSIGNMENT 1(b): SEQUENTIAL MAC WITH REGFILE");
        $display("==================================================================");
        $display("Expected Dot Product 1: %0d", expected_dot_prod_1);
        $display("Expected Dot Product 2: %0d", expected_dot_prod_2);

        // Apply Reset
        #25;
        reset_n = 1;
        @(posedge clk);
        #1;

        // -------------------------------------------------------------
        // Phase 1: WEIGHT LOADING
        // -------------------------------------------------------------
        $display("\n[Phase 1] Loading 9 weights into register file...");
        for (i = 0; i < N; i = i + 1) begin
            @(posedge clk);
            #1;
            load_weight = 1;
            weight_in   = test_weights[i];
            valid_in    = 0;
        end

        @(posedge clk);
        #1;
        load_weight = 0;
        weight_in   = 0;

        // Verify loaded weights in internal buffer
        for (i = 0; i < N; i = i + 1) begin
            if (dut.kernel_buff[i] !== test_weights[i]) begin
                $display("ERROR: kernel_buff[%0d] = %0d, expected %0d",
                         i, dut.kernel_buff[i], test_weights[i]);
                errors = errors + 1;
            end else begin
                $display("  PASS: kernel_buff[%0d] = %0d loaded correctly", i, dut.kernel_buff[i]);
            end
        end

        repeat (2) @(posedge clk);

        // -------------------------------------------------------------
        // Phase 2: COMPUTE PHASE (Vector 1)
        // -------------------------------------------------------------
        $display("\n[Phase 2] Streaming 9 data samples for Vector 1...");
        for (i = 0; i < N; i = i + 1) begin
            @(posedge clk);
            #1;
            valid_in = 1;
            data_in  = test_data_1[i];
        end

        @(posedge clk);
        #1;
        valid_in = 0;
        data_in  = 0;

        // Check output on out_valid
        if (out_valid === 1'b1) begin
            if (mac_out === expected_dot_prod_1) begin
                $display("  PASS: out_valid asserted, mac_out = %0d (matches expected %0d)",
                         mac_out, expected_dot_prod_1);
            end else begin
                $display("  FAIL: mac_out = %0d, expected %0d", mac_out, expected_dot_prod_1);
                errors = errors + 1;
            end
        end else begin
            $display("  FAIL: out_valid was not high on expected cycle!");
            errors = errors + 1;
        end

        // Ensure out_valid falls low after 1 cycle
        @(posedge clk);
        #1;
        if (out_valid !== 1'b0) begin
            $display("  FAIL: out_valid remained high for multiple cycles!");
            errors = errors + 1;
        end

        repeat (3) @(posedge clk);

        // -------------------------------------------------------------
        // Phase 3: COMPUTE PHASE (Vector 2 - Worst case negative inputs)
        // -------------------------------------------------------------
        $display("\n[Phase 3] Streaming Vector 2 (-128 across all 9 inputs)...");
        for (i = 0; i < N; i = i + 1) begin
            @(posedge clk);
            #1;
            valid_in = 1;
            data_in  = test_data_2[i];
        end

        @(posedge clk);
        #1;
        valid_in = 0;
        data_in  = 0;

        if (out_valid === 1'b1 && mac_out === expected_dot_prod_2) begin
            $display("  PASS: mac_out = %0d (matches expected %0d)", mac_out, expected_dot_prod_2);
        end else begin
            $display("  FAIL: mac_out = %0d, expected = %0d", mac_out, expected_dot_prod_2);
            errors = errors + 1;
        end

        repeat (2) @(posedge clk);

        // -------------------------------------------------------------
        // Phase 4: SIMULTANEOUS ASSERTION (Priority Check)
        // Assert both load_weight and valid_in simultaneously
        // -------------------------------------------------------------
        $display("\n[Phase 4] Testing priority logic: asserting load_weight and valid_in simultaneously...");
        @(posedge clk);
        #1;
        load_weight = 1;
        valid_in    = 1;
        weight_in   = 8'sd99;
        data_in     = 8'sd10;

        @(posedge clk);
        #1;
        load_weight = 0;
        valid_in    = 0;

        if (dut.kernel_buff[0] === 8'sd99 && out_valid === 1'b0) begin
            $display("  PASS: load_weight took strict priority over compute; kernel_buff[0] updated, no invalid output.");
        end else begin
            $display("  FAIL: Priority conflict violation detected!");
            errors = errors + 1;
        end

        // -------------------------------------------------------------
        // Final Summary
        // -------------------------------------------------------------
        $display("\n==================================================================");
        if (errors == 0) begin
            $display(" [RESULT] ALL ASSIGNMENT 1(b) TESTS PASSED SUCCESSFULLY! (0 errors)");
        end else begin
            $display(" [RESULT] TOTAL ERRORS: %0d", errors);
        end
        $display("==================================================================\n");

        #50;
        $finish;
    end

endmodule

