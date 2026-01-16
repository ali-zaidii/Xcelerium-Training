// seq_detector_tb.sv
// Comprehensive class-based layered testbench for sequence detector

`timescale 1ns/1ps

//===================================================================
// Transaction Class
//===================================================================
class transaction;
    rand bit in_bit;
    bit seq_detected;
    
    // Constraints for weighted randomization
    constraint valid_bit { in_bit dist {0:=50, 1:=50}; }
    
    function void display(string name = "Transaction");
        $display("[%0t] %s: in_bit=%0b, seq_detected=%0b", 
                 $time, name, in_bit, seq_detected);
    endfunction
    
    function transaction copy();
        copy = new();
        copy.in_bit = this.in_bit;
        copy.seq_detected = this.seq_detected;
    endfunction
endclass

//===================================================================
// Generator Class
//===================================================================
class generator;
    transaction trans;
    mailbox #(transaction) gen2drv;
    event drv_done;
    event gen_done;
    int num_transactions;
    
    function new(mailbox #(transaction) gen2drv, int num = 100);
        this.gen2drv = gen2drv;
        this.num_transactions = num;
    endfunction
    
    task run();
        $display("[%0t] Generator: Starting generation of %0d transactions", 
                 $time, num_transactions);
        
        for (int i = 0; i < num_transactions; i++) begin
            trans = new();
            assert(trans.randomize()) else 
                $fatal("Randomization failed at transaction %0d", i);
            gen2drv.put(trans.copy());
            @(drv_done);
        end
        
        $display("[%0t] Generator: Completed generation", $time);
        -> gen_done;
    endtask
    
    // Method for directed test patterns
    task send_pattern(bit pattern[]);
        $display("[%0t] Generator: Sending directed pattern", $time);
        foreach(pattern[i]) begin
            trans = new();
            trans.in_bit = pattern[i];
            gen2drv.put(trans.copy());
            @(drv_done);
        end
    endtask
endclass

//===================================================================
// Driver Class
//===================================================================
class driver;
    virtual seq_detector_if vif;
    mailbox #(transaction) gen2drv;
    event drv_done;
    
    function new(virtual seq_detector_if vif, mailbox #(transaction) gen2drv);
        this.vif = vif;
        this.gen2drv = gen2drv;
    endfunction
    
    task reset();
        $display("[%0t] Driver: Applying reset", $time);
        vif.rst_n <= 0;
        vif.in_bit <= 0;
        repeat(2) @(posedge vif.clk);
        vif.rst_n <= 1;
        @(posedge vif.clk);
        $display("[%0t] Driver: Reset released", $time);
    endtask
    
    task run();
        transaction trans;
        forever begin
            gen2drv.get(trans);
            drive_transaction(trans);
            -> drv_done;
        end
    endtask
    
    task drive_transaction(transaction trans);
        @(posedge vif.clk);
        vif.in_bit <= trans.in_bit;
    endtask
endclass

//===================================================================
// Monitor Class
//===================================================================
class monitor;
    virtual seq_detector_if vif;
    mailbox #(transaction) mon2scb;
    
    function new(virtual seq_detector_if vif, mailbox #(transaction) mon2scb);
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction
    
    task run();
        transaction trans;
        
        // Wait for reset to be released
        @(posedge vif.rst_n);
        @(posedge vif.clk);
        
        forever begin
            @(posedge vif.clk);
            #1; // Small delay for signals to settle
            trans = new();
            trans.in_bit = vif.in_bit;
            trans.seq_detected = vif.seq_detected;
            mon2scb.put(trans);
        end
    endtask
endclass

//===================================================================
// Scoreboard Class
//===================================================================
class scoreboard;
    mailbox #(transaction) mon2scb;
    int total_transactions;
    int passed;
    int failed;
    
    // Reference model state
    bit [4:0] input_history;  // Track last 5 inputs to handle timing
    bit prev_detect;
    bit expected_detect;
    
    // Coverage
    bit state_s_idle_hit;
    bit state_s_1_hit;
    bit state_s_10_hit;
    bit state_s_101_hit;
    bit state_s_1011_hit;
    
    int pattern_count;
    bit last_was_pattern;
    
    function new(mailbox #(transaction) mon2scb);
        this.mon2scb = mon2scb;
        this.total_transactions = 0;
        this.passed = 0;
        this.failed = 0;
        this.input_history = 5'b00000;
        this.prev_detect = 0;
        reset_coverage();
    endfunction
    
    function void reset_coverage();
        state_s_idle_hit = 0;
        state_s_1_hit = 0;
        state_s_10_hit = 0;
        state_s_101_hit = 0;
        state_s_1011_hit = 0;
        pattern_count = 0;
        last_was_pattern = 0;
    endfunction
    
    task run();
        transaction trans;
        forever begin
            mon2scb.get(trans);
            check_transaction(trans);
        end
    endtask
    
    task check_transaction(transaction trans);
        bit [3:0] check_pattern;
        
        total_transactions++;
        
        // CORRECT TIMING for Moore FSM:
        // When we sample at clock N:
        // - trans.in_bit: NEW input being applied at cycle N
        // - trans.seq_detected: output based on CURRENT state
        // - CURRENT state was determined by inputs applied up to cycle N-1
        // 
        // input_history[3:0] contains the last 4 inputs that created current state
        check_pattern = input_history[3:0];
        expected_detect = (check_pattern == 4'b1011);
        
        // Track state coverage
        track_state_coverage();
        
        // Compare
        if (trans.seq_detected === expected_detect) begin
            passed++;
            if (expected_detect) begin
                $display("[%0t] ? PASS: Pattern 1011 detected (pattern=%4b)", 
                         $time, check_pattern);
                pattern_count++;
                last_was_pattern = 1;
            end else begin
                last_was_pattern = 0;
            end
        end else begin
            failed++;
            $display("[%0t] ? FAIL: Expected seq_detected=%0b, Got=%0b (pattern=%4b, hist=%5b, current_in=%0b)", 
                     $time, expected_detect, trans.seq_detected, check_pattern, input_history, trans.in_bit);
        end
        
        // Update history: shift in the current input
        input_history = {input_history[3:0], trans.in_bit};
        prev_detect = expected_detect;
    endtask
    
    task track_state_coverage();
        bit [3:0] pattern;
        pattern = input_history[3:0];
        
        // Track coverage based on the pattern that determines current state
        case(pattern)
            4'b0000, 4'b0001, 4'b0010, 4'b0011,
            4'b0100, 4'b0110, 4'b0111,
            4'b1000, 4'b1100, 4'b1110: state_s_idle_hit = 1;
            4'b1011: state_s_1011_hit = 1;
        endcase
        
        // Track state transitions based on patterns
        if (pattern[0] == 1) state_s_1_hit = 1;
        if (pattern[1:0] == 2'b10) state_s_10_hit = 1;
        if (pattern[2:0] == 3'b101) state_s_101_hit = 1;
    endtask
    
    function void report();
        real pass_rate;
        $display("\n");
        $display("========================================");
        $display("       SCOREBOARD FINAL REPORT");
        $display("========================================");
        $display("Total Transactions: %0d", total_transactions);
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);
        pass_rate = (total_transactions > 0) ? 
                    (passed * 100.0 / total_transactions) : 0;
        $display("Pass Rate: %.2f%%", pass_rate);
        $display("Patterns Detected: %0d", pattern_count);
        $display("========================================");
        
        // Coverage report
        $display("\n--- FUNCTIONAL COVERAGE REPORT ---");
        $display("State Coverage:");
        $display("  S_IDLE  : %s", state_s_idle_hit ? "? HIT" : "? MISS");
        $display("  S_1     : %s", state_s_1_hit ? "? HIT" : "? MISS");
        $display("  S_10    : %s", state_s_10_hit ? "? HIT" : "? MISS");
        $display("  S_101   : %s", state_s_101_hit ? "? HIT" : "? MISS");
        $display("  S_1011  : %s", state_s_1011_hit ? "? HIT" : "? MISS");
        
        if (state_s_idle_hit && state_s_1_hit && state_s_10_hit && 
            state_s_101_hit && state_s_1011_hit)
            $display("? 100%% State Coverage Achieved!");
        else
            $display("? Incomplete State Coverage");
        
        $display("========================================\n");
        
        if (failed == 0 && pattern_count > 0)
            $display("*** TEST PASSED ***\n");
        else if (failed == 0)
            $display("*** TEST PASSED (No patterns detected in random test) ***\n");
        else
            $display("*** TEST FAILED ***\n");
    endfunction
endclass

//===================================================================
// Environment Class
//===================================================================
class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    
    mailbox #(transaction) gen2drv;
    mailbox #(transaction) mon2scb;
    
    virtual seq_detector_if vif;
    
    int expected_transactions;
    
    function new(virtual seq_detector_if vif);
        this.vif = vif;
        gen2drv = new();
        mon2scb = new();
        
        gen = new(gen2drv, 500);  // 500 random transactions
        drv = new(vif, gen2drv);
        mon = new(vif, mon2scb);
        scb = new(mon2scb);
        
        gen.drv_done = drv.drv_done;
        
        // Calculate expected transactions: 6 directed tests + 500 random
        // Test patterns: 4 + 5 + 7 + 5 + 8 + 7 = 36 bits
        expected_transactions = 36 + 500;
    endfunction
    
    task run_directed_tests();
        bit pattern1[] = '{1, 0, 1, 1};  // Basic pattern
        bit pattern2[] = '{1, 1, 0, 1, 1};  // Pattern with leading 1
        bit pattern3[] = '{1, 0, 1, 1, 0, 1, 1};  // Overlapping
        bit pattern4[] = '{0, 1, 0, 1, 1};  // Pattern after 0
        bit pattern5[] = '{1, 0, 1, 1, 1, 0, 1, 1};  // Multiple overlapping
        bit pattern6[] = '{0, 0, 0, 1, 0, 1, 1};  // Pattern with leading zeros
        
        $display("\n========================================");
        $display("   RUNNING DIRECTED TEST PATTERNS");
        $display("========================================\n");
        
        $display("Test 1: Basic pattern 1011");
        gen.send_pattern(pattern1);
        repeat(3) @(posedge vif.clk);
        
        $display("\nTest 2: Pattern with leading 1: 11011");
        gen.send_pattern(pattern2);
        repeat(3) @(posedge vif.clk);
        
        $display("\nTest 3: Overlapping pattern: 1011011");
        gen.send_pattern(pattern3);
        repeat(3) @(posedge vif.clk);
        
        $display("\nTest 4: Pattern after 0: 01011");
        gen.send_pattern(pattern4);
        repeat(3) @(posedge vif.clk);
        
        $display("\nTest 5: Multiple overlapping: 10111011");
        gen.send_pattern(pattern5);
        repeat(3) @(posedge vif.clk);
        
        $display("\nTest 6: Pattern with leading zeros: 0001011");
        gen.send_pattern(pattern6);
        repeat(3) @(posedge vif.clk);
        
        $display("\n========================================");
        $display("   DIRECTED TESTS COMPLETED");
        $display("========================================\n");
    endtask
    
    task run();
        fork
            drv.run();
            mon.run();
            scb.run();
        join_none
        
        // Apply reset
        drv.reset();
        
        // Run directed tests
        run_directed_tests();
        
        // Run random tests
        $display("\n========================================");
        $display("   RUNNING RANDOM TEST PATTERNS");
        $display("========================================\n");
        gen.run();
        @(gen.gen_done);
        
        // Wait for all transactions to be processed
        wait(scb.total_transactions >= expected_transactions);
        repeat(5) @(posedge vif.clk);
        
        // Report results
        scb.report();
        
        // Stop simulation
        $display("\n========================================");
        $display("      SIMULATION COMPLETED");
        $display("========================================\n");
        $finish;
    endtask
endclass

//===================================================================
// Interface
//===================================================================
interface seq_detector_if;
    logic clk;
    logic rst_n;
    logic in_bit;
    logic seq_detected;
endinterface

//===================================================================
// Top Module
//===================================================================
module seq_detector_tb;
    // Clock generation
    bit clk;
    always #5 clk = ~clk;
    
    // Interface instantiation
    seq_detector_if vif();
    assign vif.clk = clk;
    
    // DUT instantiation
    seq_detector dut (
        .clk(vif.clk),
        .rst_n(vif.rst_n),
        .in_bit(vif.in_bit),
        .seq_detected(vif.seq_detected)
    );
    
    // Environment
    environment env;
    
    initial begin
        // VCD dump for waveform viewing
        $dumpfile("seq_detector.vcd");
        $dumpvars(0, seq_detector_tb);
        
        // Create and run environment
        env = new(vif);
        
        $display("\n");
        $display("========================================");
        $display("  SEQUENCE DETECTOR TESTBENCH START");
        $display("  Pattern: 1011");
        $display("  FSM Type: Moore Machine");
        $display("  Features: Overlapping Detection");
        $display("========================================\n");
        
        env.run();
    end
    
    // Timeout watchdog
    initial begin
        #10000000;  // 10ms timeout instead of 1ms
        $display("\n*** ERROR: Simulation timeout! ***\n");
        env.scb.report();
        $finish;
    end
endmodule
