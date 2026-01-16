module counter #(
    parameter N = 8
)(
    input  logic        clk_50mhz,
    input  logic        rst,
    input  logic        en,
    input  logic        up_dn,
    output logic [6:0]   HEX0, HEX1, HEX2
);

	 logic [N-1:0] count;
	 logic clk;
	 logic [3:0] hundreds, tens, ones;
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            count <= '0;
        else if (en) begin
            if (up_dn)
                count <= count + 1;
            else
                count <= count - 1;
        end
    end

	 

	 // Displays:
    dec7seg d0 (
	 .dec(ones), 
	 .seg(HEX0)
	 );
	 
    dec7seg d1 (
	 .dec(tens), 
	 .seg(HEX1)
	 );
	 dec7seg d2 (
	 .dec(hundreds), 
	 .seg(HEX2)
	 );
	 
always_comb begin
    if (count >= 8'd200) begin
        hundreds = 4'd2;
        tens     = (count - 8'd200) / 8'd10;
        ones     = (count - 8'd200) % 8'd10;
    end
    else if (count >= 8'd100) begin
        hundreds = 4'd1;
        tens     = (count - 8'd100) / 8'd10;
        ones     = (count - 8'd100) % 8'd10;
    end
    else begin
        hundreds = 4'd0;
        tens     = count / 8'd10;
        ones     = count % 8'd10;
    end
end


	 clk_1hz divider( 
	 .clk_50mhz(clk_50mhz),
	 .reset(rst),
	 .clock_1hz(clk)
	 );
endmodule
