`timescale 1ns/1ps
import alu_pkg::*;

module alu_16bit_layered_tb;

    // ====================================================
    // Clock
    // ====================================================
    logic clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // ====================================================
    // DUT Signals
    // ====================================================
    logic [15:0] A, B;
    logic [15:0] RESULT;
    logic        CARRY, ZERO;
    alu_op_t     OP;

    // ====================================================
    // DUT
    // ====================================================
    alu_16bit dut (
        .A(A),
        .B(B),
        .OP(OP),
        .RESULT(RESULT),
        .CARRY(CARRY),
        .ZERO(ZERO)
    );

    // ====================================================
    // Transaction
    // ====================================================
    class alu_txn;
    rand logic [15:0] A;
    rand logic [15:0] B;
    rand alu_op_t OP;

    logic [15:0] RESULT;
    logic        CARRY;
    logic        ZERO;

    constraint shift_limit {
        if (OP inside {SHIFT_LEFT, SHIFT_RIGHT})
            B inside {[0:15]};
    }
endclass


    // ====================================================
    // Generator
    // ====================================================
    class generator;
        mailbox #(alu_txn) gen2drv;
        int count;

        function new(mailbox #(alu_txn) m);
            gen2drv = m;
            count   = 0;
        endfunction

        task run();
            alu_txn tx;
            repeat (200) begin
                tx = new();
                assert(tx.randomize());
                gen2drv.put(tx);
                count++;
            end
        endtask
    endclass

    // ====================================================
    // Driver
    // ====================================================
    class driver;
        mailbox #(alu_txn) gen2drv;

        function new(mailbox #(alu_txn) m);
            gen2drv = m;
        endfunction

        task run();
            alu_txn tx;
            forever begin
                gen2drv.get(tx);
                @(posedge clk);
                A  = tx.A;
                B  = tx.B;
                OP = tx.OP;
            end
        endtask
    endclass

    // ====================================================
    // Monitor
    // ====================================================
    class monitor;
        mailbox #(alu_txn) mon2scb;

        function new(mailbox #(alu_txn) m);
            mon2scb = m;
        endfunction

        task run();
    alu_txn tx;
    forever begin
        @(posedge clk);
        tx = new();

        // capture inputs
        tx.A  = A;
        tx.B  = B;
        tx.OP = OP;

        // capture outputs (same cycle)
        tx.RESULT = RESULT;
        tx.CARRY  = CARRY;
        tx.ZERO   = ZERO;

        mon2scb.put(tx);
    end
endtask

    endclass

    // ====================================================
    // Scoreboard + Functional Coverage
    // ====================================================
    class scoreboard;

        mailbox #(alu_txn) mon2scb;

        // Coverage
        covergroup alu_cg;
            option.per_instance = 1;

            cp_op : coverpoint tx.OP {
                bins all_ops[] = {ADD, SUB, AND_OP, OR_OP, XOR_OP, SHIFT_LEFT, SHIFT_RIGHT};
            }

            cp_A : coverpoint tx.A {
                bins zero = {0};
                bins max  = {16'hFFFF};
                bins mid  = {[1:65534]};
            }

            cp_B : coverpoint tx.B {
                bins zero = {0};
                bins max  = {16'hFFFF};
                bins mid  = {[1:65534]};
            }

            cross cp_op, cp_A;
            cross cp_op, cp_B;
        endgroup

        alu_txn tx;

        function new(mailbox #(alu_txn) m);
            mon2scb = m;
            alu_cg = new();
        endfunction

        function logic [15:0] golden(
            logic [15:0] a,
            logic [15:0] b,
            alu_op_t op
        );
            case (op)
                ADD        : golden = a + b;
                SUB        : golden = a - b;
                AND_OP     : golden = a & b;
                OR_OP      : golden = a | b;
                XOR_OP     : golden = a ^ b;
                SHIFT_LEFT : golden = a << b;
                SHIFT_RIGHT: golden = a >> b;
            endcase
        endfunction

        task run();
            forever begin
                mon2scb.get(tx);

                alu_cg.sample();

                if (tx.RESULT !== golden(tx.A, tx.B, tx.OP)) begin
    $error("? MISMATCH | OP=%0d A=%0d B=%0d EXP=%0d GOT=%0d",
           tx.OP, tx.A, tx.B,
           golden(tx.A, tx.B, tx.OP),
           tx.RESULT);
end

            end
        endtask
    endclass

    // ====================================================
    // Environment
    // ====================================================
    mailbox #(alu_txn) gen2drv = new();
    mailbox #(alu_txn) mon2scb = new();

    generator  gen;
    driver     drv;
    monitor    mon;
    scoreboard scb;

    initial begin
        gen = new(gen2drv);
        drv = new(gen2drv);
        mon = new(mon2scb);
        scb = new(mon2scb);

        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_none

        #3000;
        $display("? TEST COMPLETE");
        $finish;
    end

endmodule

