/**
 * Определение наличия Modrm-байта 16/32 и его декодирование
 */

reg         modrm_has;
reg [31:0]  modrm_ea_base;
reg [31:0]  modrm_op_reg;       // Регистровая часть modrm
reg [31:0]  modrm_op_rm;        // Память или регистр
reg [ 3:0]  m_size;             // Размер, который занимает опкод с modrm

wire [7:0]  modrm = codebuf[15:8];

// Тест на наличие байта ModRM
// ---------------------------------------------------------------------
always @* begin

    modrm_has = 0;

    if (p_ext) /* 0F xx */
        casex (codebuf[7:0])

            8'b0000_01xx, 8'b0000_10xx, 8'b0000_11x0,
            8'b0010_01x1, 8'b0011_0xxx, 8'b0011_10x1,
            8'b0011_11xx, 8'b0111_0111, 8'b0111_101x,
            8'b1000_xxxx, 8'b1010_x00x, 8'b1010_0x10,
            8'b1010_1010, 8'b1010_0111, 8'b1100_1xxx,
            8'b1111_1111:
                modrm_has = 1'b0;
            default:
                modrm_has = 1'b1;

        endcase
    else
    // Не расширенный опкод
    casex (codebuf[7:0])

        8'b00xx_x0xx, 8'b0110_001x, 8'b0110_10x1,
        8'b1000_xxxx, 8'b1100_000x, 8'b1100_01xx,
        8'b1101_00xx, 8'b1101_1xxx, 8'b1111_x11x:
            modrm_has = 1'b1;

    endcase

end

// @todo Вычисление размера и направленности (bitsize, direction)
always @* begin

    // По умолчанию
    op_bitsize = codebuf[0];
    op_dir     = codebuf[1];

end

// Вычислить байт modrm
// ---------------------------------------------------------------------
always @* begin

    m_size        = 1;
    modrm_segment = ds;
    modrm_ea_base = 0;
    modrm_ea      = 0;
    request_ea    = 0;

    if (modrm_has) begin

        // --------------------------------
        // 16-битный MODRM
        // --------------------------------

        if (p_adsize == 0) begin

            // Если выбрана не регистровая часть, то запрос на получение значения в EA
            request_ea = (modrm[7:6] != 2'b11);

            // Анализ базового смещения
            casex (modrm)

                8'bxx_xxx_000: begin modrm_ea_base = ebx[15:0] + esi[15:0]; end
                8'bxx_xxx_001: begin modrm_ea_base = ebx[15:0] + edi[15:0]; end
                8'bxx_xxx_010: begin modrm_ea_base = ebp[15:0] + esi[15:0]; modrm_segment = ss; end
                8'bxx_xxx_011: begin modrm_ea_base = ebp[15:0] + edi[15:0]; modrm_segment = ss; end
                8'bxx_xxx_100: begin modrm_ea_base = esi[15:0]; end
                8'bxx_xxx_101: begin modrm_ea_base = edi[15:0]; end
                8'b00_xxx_110: begin modrm_ea_base = codebuf[31:16]; end
                8'bxx_xxx_110: begin modrm_ea_base = ebp[15:0]; modrm_segment = ss; end
                8'bxx_xxx_111: begin modrm_ea_base = ebx[15:0]; end

            endcase

            // Анализ смещения displacement
            casex (modrm)

                8'b01_xxx_xxx: begin m_size = 3; modrm_ea[15:0] = modrm_ea_base[15:0] + {{8{codebuf[23]}}, codebuf[23:16]}; end
                8'b10_xxx_xxx: begin m_size = 4; modrm_ea[15:0] = modrm_ea_base[15:0] + codebuf[31:16]; end
                default: begin       m_size = 2; modrm_ea       = modrm_ea_base; end

            endcase

            // Вычисление операнда #1 (регистрая часть)
            case (modrm[5:3])

                3'b000: modrm_op_reg = p_opsize & op_bitsize ? eax : (op_bitsize ? eax[15:0] : eax[ 7:0]);
                3'b001: modrm_op_reg = p_opsize & op_bitsize ? ecx : (op_bitsize ? ecx[15:0] : ecx[ 7:0]);
                3'b010: modrm_op_reg = p_opsize & op_bitsize ? edx : (op_bitsize ? edx[15:0] : edx[ 7:0]);
                3'b011: modrm_op_reg = p_opsize & op_bitsize ? ebx : (op_bitsize ? ebx[15:0] : ebx[ 7:0]);
                3'b100: modrm_op_reg = p_opsize & op_bitsize ? esp : (op_bitsize ? esp[15:0] : eax[15:8]);
                3'b101: modrm_op_reg = p_opsize & op_bitsize ? ebp : (op_bitsize ? ebp[15:0] : ecx[15:8]);
                3'b110: modrm_op_reg = p_opsize & op_bitsize ? esi : (op_bitsize ? esi[15:0] : edx[15:8]);
                3'b111: modrm_op_reg = p_opsize & op_bitsize ? edi : (op_bitsize ? edi[15:0] : ebx[15:8]);

            endcase

            // Вычисление операнда #2 (reg/mem часть)
            if (request_ea)
                modrm_op_rm = p_opsize & op_bitsize ? data_ea[31:0] : (op_bitsize ? data_ea[15:0] : data_ea[7:0]);
            else
            // Запрос на регистр
            case (modrm[2:0])

                3'b000: modrm_op_rm = p_opsize & op_bitsize ? eax : (op_bitsize ? eax[15:0] : eax[ 7:0]);
                3'b001: modrm_op_rm = p_opsize & op_bitsize ? ecx : (op_bitsize ? ecx[15:0] : ecx[ 7:0]);
                3'b010: modrm_op_rm = p_opsize & op_bitsize ? edx : (op_bitsize ? edx[15:0] : edx[ 7:0]);
                3'b011: modrm_op_rm = p_opsize & op_bitsize ? ebx : (op_bitsize ? ebx[15:0] : ebx[ 7:0]);
                3'b100: modrm_op_rm = p_opsize & op_bitsize ? esp : (op_bitsize ? esp[15:0] : eax[15:8]);
                3'b101: modrm_op_rm = p_opsize & op_bitsize ? ebp : (op_bitsize ? ebp[15:0] : ecx[15:8]);
                3'b110: modrm_op_rm = p_opsize & op_bitsize ? esi : (op_bitsize ? esi[15:0] : edx[15:8]);
                3'b111: modrm_op_rm = p_opsize & op_bitsize ? edi : (op_bitsize ? edi[15:0] : ebx[15:8]);

            endcase

            // op1
            // op2

        end
        ///else begin ... end

    end

    // Если есть префикс, то заменить его
    if (p_override)
    case (p_over_seg)

        0: modrm_segment = es;
        1: modrm_segment = cs;
        2: modrm_segment = ss;
        3: modrm_segment = ds;
        4: modrm_segment = fs;
        5: modrm_segment = gs;

    endcase

end
