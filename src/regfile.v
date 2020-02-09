// ---------------------------------------------------------------------
// Регистровый файл, управление регистрами
// ---------------------------------------------------------------------

parameter EAX = 0; parameter AX = 0; parameter AL = 0;
parameter ECX = 1; parameter CX = 1; parameter CL = 1;
parameter EDX = 2; parameter DX = 2; parameter DL = 2;
parameter EBX = 3; parameter BX = 3; parameter BL = 3;
parameter ESP = 4; parameter SP = 4; parameter AH = 4;
parameter EBP = 5; parameter BP = 5; parameter CH = 5;
parameter ESI = 6; parameter SI = 6; parameter DH = 6;
parameter EDI = 7; parameter DI = 7; parameter BH = 7;

// 16 битные регистры (копии)
reg [15:0] bx; reg [15:0] si;
reg [15:0] di; reg [15:0] bp;

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

// Запись в регистры
// ---------------------------------------------------------------------
always @(negedge clock) begin

    // Теневые регистры 16 битного ModRM
    if (reg_w) case (op_bit)

        // 8 bit
        0: case (reg_a)

            3: bx[ 7:0] <= reg_o[7:0];
            7: bx[15:8] <= reg_o[7:0];

        endcase

        // 16 bit
        default: case (reg_a)

            3: bx <= reg_o[15:0];
            5: bp <= reg_o[15:0];
            6: si <= reg_o[15:0];
            7: di <= reg_o[15:0];

        endcase

    endcase

end
