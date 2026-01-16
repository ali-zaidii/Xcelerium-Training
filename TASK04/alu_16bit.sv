import alu_pkg::*;

module alu_16bit (
    input  logic [15:0] A,
    input  logic [15:0] B,
    input  alu_op_t     OP,
    output logic [15:0] RESULT,
    output logic        CARRY,
    output logic        ZERO
);

    logic [16:0] temp;

    always_comb begin
        RESULT = 16'h0000;
        CARRY  = 1'b0;

        case (OP)
            ADD: begin
                temp   = A + B;
                RESULT = temp[15:0];
                CARRY  = temp[16];
            end

            SUB: begin
                temp   = A - B;
                RESULT = temp[15:0];
                CARRY  = temp[16];
            end

            AND_OP     : RESULT = A & B;
            OR_OP      : RESULT = A | B;
            XOR_OP     : RESULT = A ^ B;
            SHIFT_LEFT : RESULT = A << B[4:0];
            SHIFT_RIGHT: RESULT = A >> B[4:0];
        endcase

        ZERO = (RESULT == 16'h0000);
    end

endmodule

