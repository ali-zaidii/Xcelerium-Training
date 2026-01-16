module barrel_shifter (
    input  logic [31:0] data_in,
    input  logic [4:0]  shift_amt,
    input  logic        dir,        // 0 = left, 1 = right
    output logic [31:0] data_out
);
    always_comb begin
        if (dir == 1'b0)
            data_out = data_in << shift_amt;
        else
            data_out = data_in >> shift_amt;
    end
endmodule

