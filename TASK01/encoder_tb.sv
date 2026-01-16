module encoder_tb;

    logic [7:0] in;
    logic [2:0] out;
    logic       v;

    int pass = 0, fail = 0;
    logic [2:0] expected;

    encoder dut (.*);

    task check_v;
        #1;
        if (v && out === expected) begin
            pass++;
            $display("PASS: in=%b out=%0d", in, out);
        end else begin
            fail++;
            $display("FAIL: in=%b exp=%0d got=%0d v=%b",
                      in, expected, out, v);
        end
    endtask

    initial begin
        // Valid single-bit inputs
        for (int i=0; i<8; i++) begin
            in = 8'b1 << i;
            expected = i;
            check_v();
        end

        // Invalid patterns
        in = 8'b00000000; #1;
        if (!v) pass++; else fail++;

        in = 8'b10101010; #1;
        if (v) pass++; else fail++;

        $display("Encoder Summary: PASS=%0d FAIL=%0d", pass, fail);
        $finish;
    end
endmodule

