
// ---------------------------------------------------------------------
// Этап последовательного декодирования префиксов (до 3-х префиксов)
// ---------------------------------------------------------------------

reg       p_ext;        // Префикс расширения опкода 0F:
reg       p_override;   // Наличие сегментного префикса
reg [2:0] p_over_seg;   // Номер сегмента
reg [1:0] p_rep;        // REP[1] - наличие REP(NZ/Z)
reg       p_opsize;     // Размер операнда 16/32
reg       p_adsize;     // Размер адреса 16/32
reg [1:0] p_size;       // Общая длина префиксов
reg [2:0] p_cont;       // Признак продления префиксов
reg       p_invalid;    // Есть 4-й префикс

always @* begin

    p_ext       = 0;
    p_override  = 0;
    p_over_seg  = 0;
    p_rep       = 0;
    p_opsize    = 0;
    p_adsize    = 0;
    p_size      = 0;
    p_cont      = 0;
    p_invalid   = 0;

    // Определение длины
    // -----------------------------------------------------------------

    // Префикс 1
    casex (b_codebuf[7:0])

        8'b0000_1111: p_size = 1; /* extopcode */
        8'b001x_x110, 8'b0110_01xx, 8'b1111_0000, 8'b1111_001x: begin p_size = 1; p_cont[0] = 1'b1; end

    endcase

    // Префикс 2
    if (p_cont[0])
    casex (b_codebuf[15:8])

        8'b0000_1111: p_size = 2; /* extopcode */
        8'b001x_x110, 8'b0110_01xx, 8'b1111_0000, 8'b1111_001x: begin p_size = 2; p_cont[1] = 1'b1; end

    endcase

    // Префикс 3
    if (p_cont[1])
    casex (b_codebuf[23:16])

        8'b0000_1111: p_size = 3; /* extopcode */
        8'b001x_x110, 8'b0110_01xx, 8'b1111_0000, 8'b1111_001x: begin p_size = 3; p_cont[2] = 1'b1; end

    endcase

    // Запрещенный префикс
    if (p_cont[2])
    casex (b_codebuf[31:24])

        8'b0000_1111, 8'b001x_x110, 8'b0110_01xx, 8'b1111_0000, 8'b1111_001x:
        p_invalid = 1;

    endcase

    // Декодирование
    // -----------------------------------------------------------------

    // Префикс в байте 0
    casex (b_codebuf[7:0])

        8'b0000_1111: begin p_ext       = 1; end
        8'b001x_x110: begin p_override  = 1; p_over_seg = {       b_codebuf[4:3]}; end
        8'b0110_010x: begin p_override  = 1; p_over_seg = {2'b10, b_codebuf[  0]}; end
        8'b0110_0110: begin p_opsize    = 1; end
        8'b0110_0111: begin p_adsize    = 1; end
        8'b1111_001x: begin p_rep       = {1'b1, b_codebuf[0]}; end

    endcase

    // Префикс в байте 1
    if (p_cont[0])
    casex (b_codebuf[15:8])

        8'b0000_1111: begin p_ext       = 1; end
        8'b001x_x110: begin p_override  = 1; p_over_seg = {       b_codebuf[4:3]}; end
        8'b0110_010x: begin p_override  = 1; p_over_seg = {2'b10, b_codebuf[  0]}; end
        8'b0110_0110: begin p_opsize    = 1; end
        8'b0110_0111: begin p_adsize    = 1; end
        8'b1111_001x: begin p_rep       = {1'b1, b_codebuf[0]}; end

    endcase

    // Префикс в байте 2
    if (p_cont[1])
    casex (b_codebuf[23:16])

        8'b0000_1111: begin p_ext       = 1; end
        8'b001x_x110: begin p_override  = 1; p_over_seg = {       b_codebuf[4:3]}; end
        8'b0110_010x: begin p_override  = 1; p_over_seg = {2'b10, b_codebuf[  0]}; end
        8'b0110_0110: begin p_opsize    = 1; end
        8'b0110_0111: begin p_adsize    = 1; end
        8'b1111_001x: begin p_rep       = {1'b1, b_codebuf[0]}; end

    endcase

end
