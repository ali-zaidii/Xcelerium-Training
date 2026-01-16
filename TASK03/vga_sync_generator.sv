module vga_sync_generator (
    input  logic        clk,
    input  logic        rst_n,
    output logic        hsync,
    output logic        vsync,
    output logic        display_enable,
    output logic [9:0]  h_count,
    output logic [9:0]  v_count
);
    import vga_pkg::*;
    
    vga_state_t current_state, next_state;
    logic [9:0] h_counter, v_counter;
    logic h_sync_reg, v_sync_reg;
    logic display_en;
    
    // Horizontal counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_counter <= 0;
        end else begin
            if (h_counter == H_TOTAL - 1) begin
                h_counter <= 0;
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end
    
    // Vertical counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v_counter <= 0;
        end else begin
            if (h_counter == H_TOTAL - 1) begin
                if (v_counter == V_TOTAL - 1) begin
                    v_counter <= 0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end
    
    // FSM State Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // FSM Next State Logic
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (h_counter == 0 && v_counter == 0)
                    next_state = DISPLAY_ACTIVE;
            end
            
            DISPLAY_ACTIVE: begin
                if (h_counter == H_DISPLAY - 1)
                    next_state = HORIZONTAL_FRONT_PORCH;
            end
            
            HORIZONTAL_FRONT_PORCH: begin
                if (h_counter == H_DISPLAY + H_FRONT - 1)
                    next_state = HORIZONTAL_SYNC;
            end
            
            HORIZONTAL_SYNC: begin
                if (h_counter == H_DISPLAY + H_FRONT + H_SYNC - 1)
                    next_state = HORIZONTAL_BACK_PORCH;
            end
            
            HORIZONTAL_BACK_PORCH: begin
                if (h_counter == H_TOTAL - 1)
                    next_state = DISPLAY_ACTIVE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Output Logic
    always_comb begin
        // Horizontal Sync (active low)
        h_sync_reg = ~((h_counter >= (H_DISPLAY + H_FRONT)) && 
                       (h_counter < (H_DISPLAY + H_FRONT + H_SYNC)));
        
        // Vertical Sync (active low)
        v_sync_reg = ~((v_counter >= (V_DISPLAY + V_FRONT)) && 
                       (v_counter < (V_DISPLAY + V_FRONT + V_SYNC)));
        
        // Display Enable
        display_en = (h_counter < H_DISPLAY) && (v_counter < V_DISPLAY);
    end
    
    // Register outputs
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hsync <= 1;
            vsync <= 1;
            display_enable <= 0;
            h_count <= 0;
            v_count <= 0;
        end else begin
            hsync <= h_sync_reg;
            vsync <= v_sync_reg;
            display_enable <= display_en;
            h_count <= h_counter;
            v_count <= v_counter;
        end
    end
endmodule
