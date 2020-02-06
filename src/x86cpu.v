/*
 * Эмулятор процессора x86. Частота 12.5 МГц
 */

module x86cpu(

    input  wire        clock,
    input  wire        locked,      // Разрешение исполнения инструкции
    output wire [19:0] address,     // Адрес в памяти
    input  wire [7:0]  i_data,
    output reg  [7:0]  o_data,
    output reg         rd,
    output reg         wr
);

`include "regfile.v"
`include "statevar.v"

// =====================
// Устройство управления
// =====================

always @(posedge clock)
if (locked) begin
case (cstate)

// Инициализация перед считыванием инструкции
// ---------------------------------------------------------------------
0: begin

    opcode <= 0;
    rd     <= 1;
    ipnext <= 0;
    opsize  <= 0;        // зависит от настроек текущего сегмента кода
    adsize  <= 0;        // зависит от настроек текущего сегмента кода
    lock    <= 0;
    rep     <= 0;
    cstate  <= 1;
    segment_id <= 0;
    segment_of <= 0;

end

// Считывание и разбор
// ---------------------------------------------------------------------
1: begin

    case (i_data)

        8'b0000_1111: opcode[8] <= 1;
        8'b001x_x110: begin segment_of <= 1; segment_id <=  i_data[4:3]; end
        8'b0110_010x: begin segment_of <= 1; segment_id <= {i_data[0], 2'b00}; end
        8'b0110_0110: opsize <= ~opsize; // Расширение операнда
        8'b0110_0111: adsize <= ~adsize; // Расширение адреса
        8'b1111_0000: lock <= 1;
        8'b1111_001x: rep <= {1'b1, i_data[0]}; // REPNZ, REPZ
        default: begin

            opcode[7:0] <= i_data;
            cstate <= 2;

        end

    endcase

    ipnext <= 1;

end

endcase
end

endmodule
