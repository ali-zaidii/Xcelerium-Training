module reg32 (
    input  logic        clk,
    input  logic        rst_n,   // active-low reset
    input  logic        load,    // enable signal
    input  logic [31:0] d,       // data input
    output logic [31:0] q        // data output
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 32'b0;          // reset condition
        else if (load)
            q <= d;              // load new data
        else
            q <= q;              // hold previous value
    end

endmodule

