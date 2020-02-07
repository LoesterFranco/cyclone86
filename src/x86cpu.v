/*
 * Эмулятор процессора x86. Частота 12.5 МГц
 */

module x86cpu(

    input  wire        clock,
    input  wire        locked,      // Разрешение исполнения инструкции
    output wire [19:0] address,     // Адрес в памяти
    input  wire [7:0]  i_data,
    output reg  [7:0]  o_data,
    output reg         wr
);

assign address = {cs[15:0], 4'h0} + eip[15:0];

parameter state_init        = 0;
parameter state_opcode      = 1;
parameter state_modrm16     = 2;
parameter state_modrm32     = 3;
parameter state_exec        = 4;

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
state_init: begin

    cstate      <= state_opcode;
    opcode      <= 0;
    o_data      <= 0;
    opsize      <= 0;       // зависит от настроек текущего сегмента кода
    adsize      <= 0;       // зависит от настроек текущего сегмента кода
    lock        <= 0;
    rep         <= 0;
    fmodrm      <= 0;
    segment_id  <= 0;
    segment_of  <= 0;

    // Здесь также будет проверка на то, можно ли эту инструкцию
    // выполнять в данном сегменте

    // И тут же будет тест на IQ... то есть, IRQ, ошибся

end

// Считывание и разбор префиксов и самого опкода
// ---------------------------------------------------------------------
state_opcode: begin

    case (i_data)

        // Расширение опкода
        8'b0000_1111: opcode[8] <= 1'b1;

        // Префиксы сегментов или даже селекторов
        8'b001x_x110: begin segment_of <= 1'b1; segment_id <=  i_data[4:3]; end
        8'b0110_010x: begin segment_of <= 1'b1; segment_id <= {i_data[0], 2'b00}; end

        // Расширение операнда и адреса
        8'b0110_0110: opsize <= ~opsize;
        8'b0110_0111: adsize <= ~adsize;

        // Префикс REP: может пригодиться в хозяйстве
        8'b1111_001x: rep <= {1'b1, i_data[0]}; // REPNZ, REPZ
        8'b1111_0000: lock <= 1;

        // Запись опкода
        default: begin

            opcode[7:0] <= i_data;

            // Базовый набор инструкции
            if (opcode[8] == 1'b0) begin

                casex (i_data)

                    8'b00xx_x0xx, 8'b0110_001x, 8'b0110_10x1,
                    8'b1000_xxxx, 8'b1100_000x, 8'b1100_01xx,
                    8'b1101_00xx, 8'b1101_1xxx, 8'b1111_x11x:
                        cstate <= (opsize | adsize) ? state_modrm32 : state_modrm16;
                    default:
                        cstate <= state_exec;

                endcase

            end
            // Расширенный набор инструкции
            else begin

                casex (i_data)

                    8'b0000_01xx, 8'b0000_10xx, 8'b0000_11x0,
                    8'b0010_01x1, 8'b0011_0xxx, 8'b0011_10x1,
                    8'b0011_11xx, 8'b0111_0111, 8'b0111_101x,
                    8'b1000_xxxx, 8'b1010_x00x, 8'b1010_0x10,
                    8'b1010_1010, 8'b1010_0111, 8'b1100_1xxx,
                    8'b1111_1111:
                        cstate <= state_exec;
                    default:
                        cstate <= (opsize | adsize) ? state_modrm32 : state_modrm16;

                endcase

            end

        end

    endcase

    eip <= eip + 1;

end

// Разбор ModRM (16 битного)
state_modrm16: begin

end

endcase
end

endmodule
