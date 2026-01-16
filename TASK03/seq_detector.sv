// seq_detector.sv
// Moore FSM for detecting "1011" pattern with overlapping support

module seq_detector (
    input  logic clk,
    input  logic rst_n,
    input  logic in_bit,
    output logic seq_detected
);

    // State encoding
    typedef enum logic [2:0] {
        S_IDLE  = 3'b000,  // Initial state
        S_1     = 3'b001,  // Detected "1"
        S_10    = 3'b010,  // Detected "10"
        S_101   = 3'b011,  // Detected "101"
        S_1011  = 3'b100   // Detected "1011" - sequence found
    } state_t;

    state_t current_state, next_state;

    // State register (Sequential logic)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= S_IDLE;
        else
            current_state <= next_state;
    end

    // Next state logic (Combinational logic)
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            S_IDLE: begin
                if (in_bit)
                    next_state = S_1;
                else
                    next_state = S_IDLE;
            end

            S_1: begin
                if (in_bit)
                    next_state = S_1;      // Stay in S_1 for consecutive 1s
                else
                    next_state = S_10;
            end

            S_10: begin
                if (in_bit)
                    next_state = S_101;
                else
                    next_state = S_IDLE;
            end

            S_101: begin
                if (in_bit)
                    next_state = S_1011;   // Pattern complete!
                else
                    next_state = S_10;     // Overlapping: "10" detected
            end

            S_1011: begin
                if (in_bit)
                    next_state = S_1;      // Start new search from "1"
                else
                    next_state = S_10;     // Overlapping: "10" detected
            end

            default: next_state = S_IDLE;
        endcase
    end

    // Output logic (Moore machine - output depends only on state)
    always_comb begin
        seq_detected = (current_state == S_1011);
    end

endmodule
