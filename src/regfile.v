// ---------------------------------------------------------------------
// Регистровый файл, управление регистрами
// ---------------------------------------------------------------------

parameter id_eax = 0; parameter id_ax = 0;
parameter id_ecx = 1; parameter id_cx = 1;
parameter id_edx = 2; parameter id_dx = 2;
parameter id_ebx = 3; parameter id_bx = 3;
parameter id_esp = 4; parameter id_sp = 4;
parameter id_ebp = 5; parameter id_bp = 5;
parameter id_esi = 6; parameter id_si = 6; 
parameter id_edi = 7; parameter id_di = 7;

// Регистры общего назначения
reg [31:0] eax = 32'h0000_0000;
reg [31:0] ecx = 32'h0000_0000;
reg [31:0] edx = 32'h0000_0000;
reg [31:0] ebx = 32'h0000_0000;
reg [31:0] esp = 32'h0000_0000;
reg [31:0] ebp = 32'h0000_0000;
reg [31:0] esi = 32'h0000_0000;
reg [31:0] edi = 32'h0000_0000;

// Сегментные регистры
reg [15:0] es  = 16'h0000;
reg [15:0] cs  = 16'h0000;
reg [15:0] ss  = 16'h0000;
reg [15:0] ds  = 16'h0000;
reg [15:0] fs  = 16'h0000;
reg [15:0] gs  = 16'h0000;

// Специальные регистры
reg [31:0] eip    = 32'h0000_0000;
reg [31:0] eflags = 32'h0000_0000;

// Чтение из регистров
// ---------------------------------------------------------------------
always @* begin

    // Выбор регистра #1
    case (reg_id_a)

        0: reg_o_a = (op_bit == 0 ? eax[ 7:0] : (op_bit == 1 ? eax[15:0] : op_bit == 2 ? eax : 0));
        1: reg_o_a = (op_bit == 0 ? ecx[ 7:0] : (op_bit == 1 ? ecx[15:0] : op_bit == 2 ? ecx : 0));
        2: reg_o_a = (op_bit == 0 ? edx[ 7:0] : (op_bit == 1 ? edx[15:0] : op_bit == 2 ? edx : 0));
        3: reg_o_a = (op_bit == 0 ? ebx[ 7:0] : (op_bit == 1 ? ebx[15:0] : op_bit == 2 ? ebx : 0));
        4: reg_o_a = (op_bit == 0 ? eax[15:8] : (op_bit == 1 ? esp[15:0] : op_bit == 2 ? esp : 0));
        5: reg_o_a = (op_bit == 0 ? ecx[15:8] : (op_bit == 1 ? ebp[15:0] : op_bit == 2 ? ebp : 0));
        6: reg_o_a = (op_bit == 0 ? edx[15:8] : (op_bit == 1 ? esi[15:0] : op_bit == 2 ? esi : 0));
        7: reg_o_a = (op_bit == 0 ? ebx[15:8] : (op_bit == 1 ? edi[15:0] : op_bit == 2 ? edi : 0));

    endcase

    // Выбор регистра #2
    case (reg_id_b)

        0: reg_o_b = (op_bit == 0 ? eax[ 7:0] : (op_bit == 1 ? eax[15:0] : op_bit == 2 ? eax : 0));
        1: reg_o_b = (op_bit == 0 ? ecx[ 7:0] : (op_bit == 1 ? ecx[15:0] : op_bit == 2 ? ecx : 0));
        2: reg_o_b = (op_bit == 0 ? edx[ 7:0] : (op_bit == 1 ? edx[15:0] : op_bit == 2 ? edx : 0));
        3: reg_o_b = (op_bit == 0 ? ebx[ 7:0] : (op_bit == 1 ? ebx[15:0] : op_bit == 2 ? ebx : 0));
        4: reg_o_b = (op_bit == 0 ? eax[15:8] : (op_bit == 1 ? esp[15:0] : op_bit == 2 ? esp : 0));
        5: reg_o_b = (op_bit == 0 ? ecx[15:8] : (op_bit == 1 ? ebp[15:0] : op_bit == 2 ? ebp : 0));
        6: reg_o_b = (op_bit == 0 ? edx[15:8] : (op_bit == 1 ? esi[15:0] : op_bit == 2 ? esi : 0));
        7: reg_o_b = (op_bit == 0 ? ebx[15:8] : (op_bit == 1 ? edi[15:0] : op_bit == 2 ? edi : 0));

    endcase

end

// Запись в регистры
// ---------------------------------------------------------------------
always @(negedge clock) begin

    if (reg_w)
    case (op_bit)

        // 8 bit
        0: case (reg_id_a)

            0: eax[ 7:0] <= reg_i[7:0];
            1: ecx[ 7:0] <= reg_i[7:0];
            2: edx[ 7:0] <= reg_i[7:0];
            3: ebx[ 7:0] <= reg_i[7:0];
            4: eax[15:8] <= reg_i[7:0];
            5: ecx[15:8] <= reg_i[7:0];
            6: edx[15:8] <= reg_i[7:0];
            7: ebx[15:8] <= reg_i[7:0];

        endcase

        // 16 bit
        1: case (reg_id_a)

            0: eax[15:0] <= reg_i[15:0];
            1: ecx[15:0] <= reg_i[15:0];
            2: edx[15:0] <= reg_i[15:0];
            3: ebx[15:0] <= reg_i[15:0];
            4: esp[15:0] <= reg_i[15:0];
            5: ebp[15:0] <= reg_i[15:0];
            6: esi[15:0] <= reg_i[15:0];
            7: edi[15:0] <= reg_i[15:0];

        endcase

        // 32 bit
        1: case (reg_id_a)

            0: eax <= reg_i[31:0];
            1: ecx <= reg_i[31:0];
            2: edx <= reg_i[31:0];
            3: ebx <= reg_i[31:0];
            4: esp <= reg_i[31:0];
            5: ebp <= reg_i[31:0];
            6: esi <= reg_i[31:0];
            7: edi <= reg_i[31:0];

        endcase

    endcase

    // Работа с ESP

end
