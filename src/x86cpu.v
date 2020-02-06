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

    cstate  <= 1;        // Перейти на следующую фазу (считывание)
    opcode  <= 0;
    rd      <= 1;
    ipnext  <= 0;
    opsize  <= 0;        // зависит от настроек текущего сегмента кода
    adsize  <= 0;        // зависит от настроек текущего сегмента кода
    lock    <= 0;
    rep     <= 0;
    fmodrm  <= 0;
    segment_id <= 0;
    segment_of <= 0;

    // Здесь также будет проверка на то, можно ли эту инструкцию
    // выполнять в данном сегменте

    // И тут же будет тест на IRQ

end

// Считывание и разбор префиксов и самого опкода
// ---------------------------------------------------------------------
1: begin

    case (i_data)

        // Расширение опкода
        8'b0000_1111: opcode[8] <= 1;

        // Префиксы сегментов или даже селекторов
        8'b001x_x110: begin segment_of <= 1; segment_id <=  i_data[4:3]; end
        8'b0110_010x: begin segment_of <= 1; segment_id <= {i_data[0], 2'b00}; end

        // Расширение операнда и адреса
        8'b0110_0110: opsize <= ~opsize;
        8'b0110_0111: adsize <= ~adsize;

        // Префикс REP: может пригодиться в хозяйстве
        8'b1111_001x: rep <= {1'b1, i_data[0]}; // REPNZ, REPZ
        8'b1111_0000: lock <= 1;
        default: begin

            opcode[7:0] <= i_data;
            cstate      <= 2;

            // Вычисление байта ModRM

        end

    endcase

    eip <= eip + 1;

end

endcase
end

endmodule
