module counter_tb;

    parameter N = 8;

    logic clk, rst_n, en, up_dn;
    logic [N-1:0] count;

    // DUT
    counter #(N) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .up_dn(up_dn),
        .count(count)
    );

    // Clock
    always #5 clk = ~clk;

    // ================= DRIVER =================
    task drive(input logic en_i, input logic up_dn_i);
        en    = en_i;
        up_dn = up_dn_i;
    endtask

    // ================= SCOREBOARD =================
    logic [N-1:0] expected;

    task check;
        if (count !== expected)
            $display("? FAIL: exp=%0d got=%0d", expected, count);
        else
            $display("? PASS: count=%0d", count);
    endtask

    // ================= TEST =================
    initial begin
        clk = 0;
        rst_n = 0;
        en = 0;
        up_dn = 1;
        expected = 0;

        #12 rst_n = 1;

        // Count up
        repeat (5) begin
            @(posedge clk);
            drive(1,1);
            expected++;
            @(negedge clk);
            check();
        end

        // Count down
        repeat (3) begin
            @(posedge clk);
            drive(1,0);
            expected--;
            @(negedge clk);
            check();
        end

        // Hold
        @(posedge clk);
        drive(0,1);
        @(negedge clk);
        check();

        $finish;
    end

endmodule
