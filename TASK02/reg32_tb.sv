module reg32_tb;

    // Testbench signals
    logic clk;
    logic rst_n;
    logic load;
    logic [31:0] d;
    logic [31:0] q;

    // Counters
    integer sva_fail_count  = 0;
    integer stim_pass_count = 0;
    integer stim_fail_count = 0;

    // DUT
    reg32 dut (
        .q(q),
        .clk(clk),
        .rst_n(rst_n),
        .load(load),
        .d(d)
    );

    // Clock generation (10 ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // SystemVerilog Assertions (SVA)

    // Property 1: Reset behavior - output should be 0 when reset is active
    property p_reset;
        @(posedge clk) !rst_n |=> (q == 32'b0);
    endproperty
    assert_reset: assert property(p_reset)
    else begin
        sva_fail_count++;
        $error("Reset assertion failed: q = %h (expected 0)", q);
    end

    // Property 2: Load behavior - output should capture input when load is high
    property p_load;
        @(posedge clk) disable iff(!rst_n)
        (rst_n && load) |=> (q == $past(d));
    endproperty
    assert_load: assert property(p_load)
    else begin
        sva_fail_count++;
        $error("Load assertion failed: q = %h, expected d = %h", q, $past(d));
    end

    // Property 3: Hold behavior - output should remain stable when load is low
    property p_hold;
        @(posedge clk) disable iff(!rst_n)
        (rst_n && !load) |=> (q == $past(q));
    endproperty
    assert_hold: assert property(p_hold)
    else begin
        sva_fail_count++;
        $error("Hold assertion failed: q changed from %h to %h", $past(q), q);
    end

    // Property 4: Reset has priority over load
    property p_reset_priority;
        @(posedge clk) (!rst_n && load) |=> (q == 32'b0);
    endproperty
    assert_reset_priority: assert property(p_reset_priority)
    else begin
        sva_fail_count++;
        $error("Reset priority failed: q = %h", q);
    end

    // Property 5: No metastability - output is always defined
    property p_no_x;
        @(posedge clk) !$isunknown(q);
    endproperty
    assert_no_x: assert property(p_no_x)
    else begin
        sva_fail_count++;
        $error("Output q contains X or Z: %h", q);
    end

    // Test Stimulus
    initial begin
        // Initialization of signals
        rst_n = 0;
        load  = 0;
        d     = 32'h0;

        // Test 1: Reset behavior
        $display("Test 1: Reset Behavior");
        repeat(2) @(posedge clk);
        #1;
        if (q == 32'h0) stim_pass_count++;
        else begin stim_fail_count++; $error("Reset test failed"); end

        // Test 2: Release reset
        $display("Test 2: Release Reset");
        rst_n = 1;
        @(posedge clk);

        // Test 3: Load patterns
        $display("Test 3: Load Various Data Patterns");
        load = 1;

        d = 32'hAAAAAAAA;
        @(posedge clk); #1;
        if (q == 32'hAAAAAAAA) stim_pass_count++;
        else begin stim_fail_count++; $error("Load test 1 failed"); end

        d = 32'h55555555;
        @(posedge clk); #1;
        if (q == 32'h55555555) stim_pass_count++;
        else begin stim_fail_count++; $error("Load test 2 failed"); end

        d = 32'hFFFFFFFF;
        @(posedge clk); #1;
        if (q == 32'hFFFFFFFF) stim_pass_count++;
        else begin stim_fail_count++; $error("Load test 3 failed"); end

        // Test 4: Hold behavior (Load = 0)
        $display("Test 4: Hold Behavior");
        load = 0;
        d = 32'h12345678;
        @(posedge clk); #1;
        if (q == 32'hFFFFFFFF) stim_pass_count++;
        else begin stim_fail_count++; $error("Hold test failed"); end

        @(posedge clk); #1;
        if (q == 32'hFFFFFFFF) stim_pass_count++;
        else begin stim_fail_count++; $error("Hold test 2 failed"); end

        // Test 5: Load after hold
        $display("Test 5: Load After Hold");
        load = 1;
        d = 32'hDEADBEEF;
        @(posedge clk); #1;
        if (q == 32'hDEADBEEF) stim_pass_count++;
        else begin stim_fail_count++; $error("Load after hold failed"); end

        // Test 6: Reset priority
        $display("Test 6: Reset Priority Over Load");
        rst_n = 0;
        load  = 1;
        d     = 32'hBADC0FFE;
        @(posedge clk); #1;
        if (q == 32'h0) stim_pass_count++;
        else begin stim_fail_count++; $error("Reset priority test failed"); end

        // Test 7: Consecutive loads
        $display("Test 7: Consecutive Loads");
        rst_n = 1;
        load  = 1;
        repeat (5) begin
            d = $random;
            @(posedge clk);
        end

 
        // Final Summary
        $display("\n======================================");
        $display("        SIMULATION SUMMARY");
        $display("======================================");
        $display("SVA assertion failures : %0d", sva_fail_count);
        $display("Directed test PASSES   : %0d", stim_pass_count);
        $display("Directed test FAILURES : %0d", stim_fail_count);

        if (sva_fail_count == 0 && stim_fail_count == 0)
            $display("STATUS : All TESTS PASSED");
        else
            $display("STATUS : SOME TESTS FAILED");

        $display("======================================\n");

        $finish;
    end

endmodule
