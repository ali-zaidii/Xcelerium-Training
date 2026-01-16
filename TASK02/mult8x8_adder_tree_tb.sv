`timescale 1ns/1ps

module mult8x8_adder_tree_tb;

    // DUT signals
    logic clk, rst_n, en;
    logic [7:0] A_in, B_in;
    logic [15:0] P_out;

    // Instantiate DUT
    mult8x8_adder_tree dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .A_in(A_in),
        .B_in(B_in),
        .P_out(P_out)
    );

    // Clock
    always #5 clk = ~clk;

    // -----------------------------
    // Transaction
    // -----------------------------
    class mult_trans;
        rand logic [7:0] A;
        rand logic [7:0] B;
        logic [15:0] exp;
        function void calc();
            exp = A * B;
        endfunction
    endclass

    // -----------------------------
    // Driver
    // -----------------------------
    class driver;
        task drive(mult_trans t);
            @(posedge clk);
            en   <= 1;
            A_in <= t.A;
            B_in <= t.B;
            @(posedge clk);
            en <= 0;
        endtask
    endclass

    // -----------------------------
    // Monitor
    // -----------------------------
    class monitor;
        task sample(output logic [15:0] p);
            @(posedge clk);
            p = P_out;
        endtask
    endclass

    // -----------------------------
    // Scoreboard
    // -----------------------------
    class scoreboard;
        task check(mult_trans t, logic [15:0] p);
            if (p !== t.exp)
                $error("FAIL: A=%0d B=%0d Expected=%0d Got=%0d",
                       t.A, t.B, t.exp, p);
            else
                $display("PASS: A=%0d B=%0d P=%0d",
                         t.A, t.B, p);
        endtask
    endclass

    // -----------------------------
    // Assertions
    // -----------------------------
    property reset_check;
        !rst_n |-> P_out == 0;
    endproperty
    assert property (reset_check);

    // -----------------------------
    // Test
    // -----------------------------
    initial begin
        clk = 0; rst_n = 0; en = 0;
        A_in = 0; B_in = 0;

        driver     d = new();
        monitor    m = new();
        scoreboard s = new();

        #20 rst_n = 1;

        repeat (20) begin
            mult_trans t = new();
            assert(t.randomize());
            t.calc();

            d.drive(t);

            logic [15:0] p;
            m.sample(p);
            s.check(t, p);
        end

        $display("=== TEST COMPLETED ===");
        $finish;
    end

endmodule

