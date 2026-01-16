module shift_reg #(
    parameter int N = 8
)(
    input  logic         clk,
    input  logic         rst_n,
    input  logic         shift_en,
    input  logic         dir,      // 0: left, 1: right
    input  logic         d_in,
    output logic [N-1:0] q_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_out <= '0;
        end
        else if (shift_en) begin
            if (dir)
                q_out <= {d_in, q_out[N-1:1]};
            else
                q_out <= {q_out[N-2:0], d_in};
        end
        else begin
            q_out <= q_out;
        end
    end

endmodule
