`timescale 1ns/1ps

module multiplier_tb;

    logic clk, rst_n;
    logic [7:0] A_in, B_in;
    logic [15:0] P_out;

    multiplier_top dut (
        .clk  (clk),
        .rst_n(rst_n),
        .A_in (A_in),
        .B_in (B_in),
        .P_out(P_out)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    class driver;
        task reset();
            rst_n = 0;
            A_in  = 0;
            B_in  = 0;
            #30;
            rst_n = 1;
        endtask

        task apply(input byte a, input byte b);
            A_in = a;
            B_in = b;
            @(posedge clk);
        endtask
    endclass

    class monitor;
        task observe();
            forever begin
                @(posedge clk);
                $display("[%0t] A=%0d B=%0d P=%0d",
                         $time, A_in, B_in, P_out);
            end
        endtask
    endclass

    class test;
        driver drv;
        monitor mon;

        function new();
            drv = new();
            mon = new();
        endfunction

        task run();
            fork
                mon.observe();
            join_none

            drv.reset();

            drv.apply(8'd3,  8'd5);
            drv.apply(8'd12, 8'd4);
            drv.apply(8'd7,  8'd9);

            #50;
            $stop;
        endtask
    endclass

    initial begin
        test t;
        t = new();
        t.run();
    end

endmodule

