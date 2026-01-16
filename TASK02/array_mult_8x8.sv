module array_mult_8x8 (
    input  logic [7:0] A,
    input  logic [7:0] B,
    output logic [15:0] P
);

    logic [7:0] pp [7:0];
    logic [7:0] sum [7:0];
    logic [7:0] carry;

    genvar i, j;

    generate
        for (i = 0; i < 8; i++) begin
            for (j = 0; j < 8; j++) begin
                assign pp[i][j] = A[j] & B[i];
            end
        end
    endgenerate

    assign sum[0] = pp[0];
    assign carry[0] = 1'b0;

    generate
        for (i = 1; i < 8; i++) begin : ADD_ROWS
            adder_n #(.N(8)) row_adder (
                .a   (pp[i]),
                .b   ({carry[i-1], sum[i-1][7:1]}),
                .cin (1'b0),
                .sum (sum[i]),
                .cout(carry[i])
            );
        end
    endgenerate

    assign P[0] = sum[0][0];

    generate
        for (i = 1; i < 8; i++)
            assign P[i] = sum[i][0];
    endgenerate

    assign P[15:8] = {carry[7], sum[7][7:1]};

endmodule

