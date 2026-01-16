module barrel_shifter_tb;

    logic [31:0] data_in, data_out;
    logic [4:0]  shift_amt;
    logic        dir;

    logic [31:0] expected;
    int pass = 0, fail = 0;

    barrel_shifter dut (.*);

    task check;
        #1;
        if (data_out === expected) begin
            pass++;
            $display("PASS: data=%h shift=%0d dir=%b",
                      data_in, shift_amt, dir);
        end else begin
            fail++;
            $display("FAIL: data=%h shift=%0d dir=%b exp=%h got=%h",
                      data_in, shift_amt, dir, expected, data_out);
        end
    endtask

    initial begin
        repeat (100) begin
            data_in   = $random;
            shift_amt = $random % 32;
            dir       = $random;

            if (dir == 0)
                expected = data_in << shift_amt;
            else
                expected = data_in >> shift_amt;

            check();
        end

        $display("Barrel Shifter Summary: PASS=%0d FAIL=%0d", pass, fail);
        $finish;
    end
endmodule

