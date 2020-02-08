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

// Пока что реализован 16-битный RealMode
assign address = address16;

// Работает
wire [19:0] address16 = sela ? {segment, 4'h0} +  ea[15:0] :
                               {cs,      4'h0} + eip[15:0];

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
    op_dir      <= 0;
    op_bit      <= 0;
    reg_w       <= 0;
    ea          <= 0;
    modrm       <= 0;
    segment     <= 0;
    modph       <= 0;
    sela        <= 0;
    rd          <= 1;

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

            // По умолчанию 8/16/32
            op_bit      <= opsize && opcode[1] ? 2 : opcode[0];
            op_dir      <= opcode[1];

            // Базовый набор инструкции
            if (opcode[8] == 1'b0) begin

                // Определение наличия modrm
                casex (i_data)

                    8'b00xx_x0xx, 8'b0110_001x, 8'b0110_10x1,
                    8'b1000_xxxx, 8'b1100_000x, 8'b1100_01xx,
                    8'b1101_00xx, 8'b1101_1xxx, 8'b1111_x11x:
                        cstate <= adsize ? state_modrm32 : state_modrm16;
                    default:
                        cstate <= state_exec;

                endcase

                // @todo Вычисление битности и направления

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
                        cstate <= adsize ? state_modrm32 : state_modrm16;

                endcase

                // @todo Вычисление битности и направления

            end

        end

    endcase

    eip <= eip + 1;

end

// Разбор ModRM (16 битного)
// ---------------------------------------------------------------------
state_modrm16: case (modph)

    // Прочитать байт ModRM
    0: begin

        modph    <= 1;
        modrm    <= i_data;
        eip      <= eip + 1;

        // Здесь будет зависеть от направления opdir: 0=(rm, r), 1=(r, rm)
        reg_id_a <= op_dir ? i_data[5:3] : i_data[2:0];    // Прочитать регистровую часть
        reg_id_b <= op_dir ? i_data[2:0] : i_data[5:3];    // Прочитать часть r/m часть

        // Сегмент, котрый будет выбран по префиксу
        if (segment_of) begin

            case (segment_id)
                0: segment <= es;
                1: segment <= cs;
                2: segment <= ss;
                3: segment <= ds;
                4: segment <= fs;
                5: segment <= gs;
            endcase

        end

        // Выбор сегмента DS: SS:
        else casex (i_data)

            8'bxx_xxx_01x,
            8'b01_xxx_110,
            8'b10_xxx_110: segment <= ss;
            default: segment <= ds;

        endcase

    end

    // Прочитать значения регистров
    1: begin

        // Сохранить значение регистров в операндах
        case (op_bit)

            0: begin op1 <= reg_o_a[ 7:0]; op2 <= reg_o_b[7:0];  end
            1: begin op1 <= reg_o_a[15:0]; op2 <= reg_o_b[15:0]; end
            2: begin op1 <= reg_o_a[31:0]; op2 <= reg_o_b[31:0]; end
            3: begin op1 <= reg_o_a;       op2 <= reg_o_b;       end

        endcase

        // Выбор типа считывания
        casex (modrm)

            8'b11_xxx_xxx: cstate <= state_exec;  // Переход к исполнению
            8'b00_xxx_110: modph  <= 3;           // Читать displacement
            default: modph <= 2;                  // Найти сумму

        endcase

        // Выбор регистра для вычисления EA
        casex (modrm[2:0])

            3'b000: begin reg_id_a <= id_bx; reg_id_b <= id_si; end
            3'b001: begin reg_id_a <= id_bx; reg_id_b <= id_di; end
            3'b010: begin reg_id_a <= id_bp; reg_id_b <= id_si; end
            3'b011: begin reg_id_a <= id_bp; reg_id_b <= id_di; end
            3'b100: begin reg_id_a <= id_si; end
            3'b101: begin reg_id_a <= id_di; end
            3'b110: begin reg_id_a <= id_bp; end
            3'b111: begin reg_id_a <= id_bx; end

        endcase

    end

    // Прочитать 2 регистра для вычисления EA
    2: begin

    end

    // Получение disp16/32
    3: begin

    end

endcase

// Считывание Immediate 16/32/64
// ---------------------------------------------------------------------
state_imm: begin

end

// Чтение из памяти
// Запись в память
// Чтение из стека
// Запись в стек

endcase
end

endmodule
