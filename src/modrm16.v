// ---------------------------------------------------------------------
// Разбор 16 битного ModRM
// ---------------------------------------------------------------------

state_modrm16: case (modph)

    // Прочитать байт ModRM
    0: begin

        modph    <= 1;
        modrm    <= i_data;
        eip      <= eip + 1;

        // Здесь будет зависеть от направления opdir: 0=(rm, r), 1=(r, rm)
        reg_a <= op_dir ? (op_bit ? i_data[5:3] : i_data[4:3]) : (op_bit ? i_data[2:0] : i_data[1:0]);
        reg_b <= op_dir ? (op_bit ? i_data[2:0] : i_data[1:0]) : (op_bit ? i_data[5:3] : i_data[4:3]);

        // Сегмент, котрый будет выбран по префиксу
        if (segment_of)
        begin

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
        else
        casex (i_data)

            8'bxx_xxx_01x,
            8'b01_xxx_110,
            8'b10_xxx_110: segment <= ss;
            default:       segment <= ds;

        endcase

        // Размер immediate операнда
        casex (i_data)

            8'b00_xxx_110, // dword : word
            8'b10_xxx_xxx: dispsize <= opsize ? 3 : 1;
            default:       dispsize <= 0;

        endcase

    end

    // Прочитать значения регистров
    1: begin

        // Сохранить значение регистров в операндах
        case (op_bit)

            0: begin
                op1 <= reg_a[2] ? i_reg_a[15:8] : i_reg_a[ 7:0];
                op2 <= reg_b[2] ? i_reg_b[15:8] : i_reg_b[ 7:0]; end
            1: begin op1 <= i_reg_a[15:0]; op2 <= i_reg_b[15:0]; end
            2: begin op1 <= i_reg_a[31:0]; op2 <= i_reg_b[31:0]; end
            3: begin op1 <= i_reg_a;       op2 <= i_reg_b;       end

        endcase

        // Предварительное вычисление `ea`
        casex (modrm[2:0])

            3'b000: ea <= bx + si;
            3'b001: ea <= bx + di;
            3'b010: ea <= bp + si;
            3'b011: ea <= bp + di;
            3'b100: ea <= si;
            3'b101: ea <= di;
            3'b110: ea <= bp;
            3'b111: ea <= bx;

        endcase

        // Выбор режима считывания displacement
        casex (modrm)

            8'b00_xxx_110: modph  <= 2;           // Читать disp-16
            8'b11_xxx_xxx: cstate <= state_exec;  // Переход к исполнению
            8'b00_xxx_xxx: begin modph <= 5; sela <= 1; end
            default:       modph  <= 3;

        endcase

    end

    // Получение disp8/16
    2: begin

        casex (modrm[7:6])

            2'b00: begin modph <= 3; ea[15:0] <= i_data; end
            2'b01: begin modph <= 4; ea[15:0] <= ea[15:0] + {{8{i_data[7]}}, i_data}; sela <= 1; end
            2'b10: begin modph <= 3; ea[15:0] <= i_data + ea[15:0]; end

        endcase

        eip <= eip + 1;

    end

    // Получение disp16
    3: begin

        modph    <= 4;
        sela     <= 1;
        ea[15:8] <= ea[15:8] + i_data;
        eip      <= eip + 1;

    end

    // Считывание операнда из памяти
    4: begin

        // @todo Проверка доступа к сегменту : адресу. Если все плохо, то капец вызвать General Protection Error, гадство, чтоб тебя

        case (dispimm)

            // 8, 16 bit
            0: if (op_dir) op2        <= i_data; else op1        <= i_data;
            1: if (op_dir) op2[15: 8] <= i_data; else op1[15: 8] <= i_data;
            // 32 bit
            2: if (op_dir) op2[23:16] <= i_data; else op1[23:16] <= i_data;
            3: if (op_dir) op2[31:24] <= i_data; else op1[31:24] <= i_data;
            /* 64 bit
            4: if (op_dir) op2 <= i_data; else op1 <= i_data;
            5: if (op_dir) op2 <= i_data; else op1 <= i_data;
            6: if (op_dir) op2 <= i_data; else op1 <= i_data;
            7: if (op_dir) op2 <= i_data; else op1 <= i_data;
            */

        endcase

        // При достижении окончания считывания
        if (dispsize == 0) begin

            ea       <= ea - dispimm;
            cstate   <= state_exec;

        end else begin

            dispsize <= dispsize - 1;
            dispimm  <= dispimm + 1;
            ea       <= ea + 1;

        end

    end

endcase
