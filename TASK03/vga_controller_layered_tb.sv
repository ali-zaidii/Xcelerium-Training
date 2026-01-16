`timescale 1ns/1ps

// ============================================================
// INTERFACE
// ============================================================
interface vga_if(input logic clk);
    logic reset;

    logic hsync;
    logic vsync;
    logic [3:0] red, green, blue;
endinterface

// ============================================================
// TRANSACTION
// ============================================================
class vga_txn;
    bit hsync;
    bit vsync;
    bit [3:0] red, green, blue;
    time t;

    function void display(string tag="TXN");
        $display("[%0t] %s | HS=%0b VS=%0b RGB=%0h%0h%0h",
                 t, tag, hsync, vsync, red, green, blue);
    endfunction
endclass

// ============================================================
// GENERATOR
// ============================================================
class vga_generator;
    mailbox gen2drv;
    int num_samples;

    function new(mailbox m, int n);
        gen2drv = m;
        num_samples = n;
    endfunction

    task run();
        vga_txn txn;
        repeat (num_samples) begin
            txn = new();
            gen2drv.put(txn);
            #1;
        end
    endtask
endclass

// ============================================================
// DRIVER (only reset control here)
// ============================================================
class vga_driver;
    virtual vga_if vif;

    function new(virtual vga_if vif);
        this.vif = vif;
    endfunction

    task reset_dut();
        vif.reset <= 1;
        repeat (5) @(posedge vif.clk);
        vif.reset <= 0;
        $display("[%0t] DRIVER: Reset released", $time);
    endtask
endclass

// ============================================================
// MONITOR
// ============================================================
class vga_monitor;
    virtual vga_if vif;
    mailbox mon2scb;

    function new(virtual vga_if vif, mailbox m);
        this.vif = vif;
        mon2scb = m;
    endfunction

    task run();
        vga_txn txn;
        forever begin
            @(posedge vif.clk);
            txn = new();
            txn.hsync = vif.hsync;
            txn.vsync = vif.vsync;
            txn.red   = vif.red;
            txn.green = vif.green;
            txn.blue  = vif.blue;
            txn.t     = $time;
            mon2scb.put(txn);
        end
    endtask
endclass

// ============================================================
// SCOREBOARD
// ============================================================
class vga_scoreboard;
    mailbox mon2scb;

    // --------------------------------------------------------
    // 1. VGA Timing Constants (640x480 @ 60Hz)
    // --------------------------------------------------------
    // Horizontal Timing (in Pixel Clocks)
    localparam H_SYNC_CYC = 96;
    localparam H_BP_CYC   = 48;
    localparam H_ACT_CYC  = 640;
    localparam H_FP_CYC   = 16;
    localparam H_TOTAL    = 800;

    // Vertical Timing (in Lines)
    localparam V_SYNC_LN  = 2;
    localparam V_BP_LN    = 33;
    localparam V_ACT_LN   = 480;
    localparam V_FP_LN    = 10;
    localparam V_TOTAL    = 525;

    // --------------------------------------------------------
    // 2. Internal Counters
    // --------------------------------------------------------
    int h_counter; // Tracks horizontal pixel position (0 to 799)
    int v_counter; // Tracks vertical line position (0 to 524)

    function new(mailbox m);
        mon2scb = m;
        h_counter = 0;
        v_counter = 0;
    endfunction

    task run();
        vga_txn txn;
        bit prev_hsync = 1; 
        bit prev_vsync = 1; 
        
        // CORRECTION: Declare these at the top, not in the middle
        bit h_active; 
        bit v_active;

        forever begin
            mon2scb.get(txn);

            // ------------------------------------------------
            // 3. Counter Synchronization Logic
            // ------------------------------------------------
            if (prev_vsync == 1 && txn.vsync == 0) begin
                v_counter = 0;
            end

            if (prev_hsync == 1 && txn.hsync == 0) begin
                h_counter = 0;
                v_counter = (v_counter + 1) % V_TOTAL; 
            end else begin
                h_counter = (h_counter + 1) % H_TOTAL;
            end

            // Update history for edge detection
            prev_hsync = txn.hsync;
            prev_vsync = txn.vsync;

            // ------------------------------------------------
            // 4. Region Verification Logic
            // ------------------------------------------------
            
            // Now you can just use the variables (already declared above)
            h_active = (h_counter >= (H_SYNC_CYC + H_BP_CYC)) && 
                       (h_counter <  (H_SYNC_CYC + H_BP_CYC + H_ACT_CYC));

            v_active = (v_counter >= (V_SYNC_LN + V_BP_LN)) && 
                       (v_counter <  (V_SYNC_LN + V_BP_LN + V_ACT_LN));

            // ... rest of your checks ...
             if (h_active && v_active) begin
                // Active Region Checks
             end else begin
                // Blanking Region Checks
             end
        end
    endtask
endclass
// ============================================================
// ENVIRONMENT
// ============================================================
class vga_env;
    vga_generator gen;
    vga_driver    drv;
    vga_monitor   mon;
    vga_scoreboard scb;

    mailbox gen2drv;
    mailbox mon2scb;

    virtual vga_if vif;

    function new(virtual vga_if vif);
        this.vif = vif;
        gen2drv = new();
        mon2scb = new();

        gen = new(gen2drv, 20000);
        drv = new(vif);
        mon = new(vif, mon2scb);
        scb = new(mon2scb);
    endfunction

    task run();
        fork
            drv.reset_dut();
            gen.run();
            mon.run();
            scb.run();
        join_none
    endtask
endclass

// ============================================================
// TOP TESTBENCH
// ============================================================
module vga_controller_layered_tb;

    logic clk = 0;
    always #10 clk = ~clk;   // 50 MHz

    vga_if vif(clk);

    // DUT
    vga_controller_top dut (
    .clk_50mhz (clk),
    .rst_n     (~vif.reset),   // active-low reset
    .vga_hsync (vif.hsync),
    .vga_vsync (vif.vsync),
    .vga_red   (vif.red),
    .vga_green (vif.green),
    .vga_blue  (vif.blue)
);


    vga_env env;

    initial begin
        env = new(vif);
        env.run();

        #5ms;
        $display("=================================");
        $display(" VGA TEST COMPLETED SUCCESSFULLY ");
        $display("=================================");
        $finish;
    end

endmodule

