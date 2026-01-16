module mult8x8_adder_tree (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        en,
    input  logic [7:0]  A_in,
    input  logic [7:0]  B_in,
    output logic [15:0] P_out
);

    // -----------------------------
    // Input registers (as Fig-3)
    // -----------------------------
    logic [7:0] A, B;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A <= '0;
            B <= '0;
        end
        else if (en) begin
            A <= A_in;
            B <= B_in;
        end
    end

    // -----------------------------
    // Partial products (8 rows)
    // -----------------------------
    logic [15:0] pp [7:0];

    genvar i;
    generate
        for (i = 0; i < 8; i++) begin
            assign pp[i] = B[i] ? (A << i) : 16'd0;
        end
    endgenerate

    // -----------------------------
    // Adder Tree (Fig-4)
    // Stage-1 (8 ? 4)
    // -----------------------------
    logic [15:0] s1_0, s1_1, s1_2, s1_3;
    assign s1_0 = pp[0] + pp[1];
    assign s1_1 = pp[2] + pp[3];
    assign s1_2 = pp[4] + pp[5];
    assign s1_3 = pp[6] + pp[7];

    // -----------------------------
    // Stage-2 (4 ? 2)
    // -----------------------------
    logic [15:0] s2_0, s2_1;
    assign s2_0 = s1_0 + s1_1;
    assign s2_1 = s1_2 + s1_3;

    // -----------------------------
    // Stage-3 (2 ? 1)
    // -----------------------------
    logic [15:0] product_comb;
    assign product_comb = s2_0 + s2_1;

    // -----------------------------
    // Output register (as Fig-3)
    // -----------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            P_out <= 16'd0;
        else if (en)
            P_out <= product_comb;
    end

endmodule

