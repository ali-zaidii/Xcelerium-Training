module multiplier_top (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [7:0]  A_in,
    input  logic [7:0]  B_in,
    output logic [15:0] P_out
);

    logic [7:0]  A_reg, B_reg;
    logic [15:0] P_comb;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= '0;
            B_reg <= '0;
            P_out <= '0;
        end else begin
            A_reg <= A_in;
            B_reg <= B_in;
            P_out <= P_comb;
        end
    end

    array_mult_8x8 u_mult (
        .A(A_reg),
        .B(B_reg),
        .P(P_comb)
    );

endmodule

