module adder32 (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic        cin,
    output logic [31:0] sum,
    output logic        cout
);
    always @(*) begin
        {cout, sum} = a + b + cin;
    end
endmodule

