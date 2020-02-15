/*
 * Модуль памяти 64Мб для DE0-CV с видеопамятью 640 x 480 x (4|8|16) bit
 */

module sdramvga
(
    // Тактовая частота 100 МГц (SDRAM) 25 МГц (видео)
    input  wire         i_clock_100_mhz,
    input  wire         i_clock_25_mhz,
    input  wire [25:0]  i_address,      // 64 МБ памяти
    input  wire         i_we,           // Признак записи в память
    input  wire [ 7:0]  i_data,         // Данные для записи (8 бит)
    output reg  [ 7:0]  o_data,         // Прочитанные данные
    output reg          o_ready,        // Готовность данных (=1 Готово)

    // Видеоадаптер встроен в SDRAM
    output reg  [3:0]   vga_r,
    output reg  [3:0]   vga_g,
    output reg  [3:0]   vga_b,
    output wire         vga_hs,
    output wire         vga_vs,

    // Физический интерфейс
    output wire         dram_clk,      // Clock
    output reg  [ 1:0]  dram_ba,       // Bank 2^2=4
    output wire [12:0]  dram_addr,     // Address 2^13=8192
    inout  wire [15:0]  dram_dq,       // Data I/O
    output wire         dram_cas,      // CAS
    output wire         dram_ras,      // RAS
    output wire         dram_we,       // Write Enabled
    output wire         dram_ldqm,     // Low Data QMask
    output wire         dram_udqm      // High Data QMask
);

parameter videomemory_start     = 0;
parameter videomemory_row_width = 160; // 640 x 480 x 4 цвета

// Command modes                 RCW
// ---------------------------------------------------------------------
// Команды
localparam cmd_loadmode     = 3'b000;
localparam cmd_refresh      = 3'b001;
localparam cmd_precharge    = 3'b010;
localparam cmd_activate     = 3'b011;
localparam cmd_write        = 3'b100;
localparam cmd_read         = 3'b101;
localparam cmd_burst_term   = 3'b110;
localparam cmd_nop          = 3'b111;

// Режимы работы машины состояний
localparam state_idle      = 0;
localparam state_update    = 1;
localparam state_activate  = 2;
localparam state_close_row = 3;

`ifdef ICARUS
localparam init_time = 0;
`else
localparam init_time = 5000;
`endif

initial begin

    o_ready = 0;
    dram_ba = 0;

end

// Связь с физическим интерфейсом памяти
// ---------------------------------------------------------------------

// Направление данных (in, out)
assign dram_dq   =  dram_we ? 16'hZZZZ : {i_data, i_data};
assign dram_clk  =  i_clock_100_mhz;

// Активация маски записи или чтения из памяти
assign dram_ldqm =  i_address[0];
assign dram_udqm = ~i_address[0];

// Адрес и команда
assign {dram_addr                  } = chipinit ? dram_init    : dram_address;
assign {dram_ras, dram_cas, dram_we} = chipinit ? command_init : command;

// Команды для памяти, регистры, текущее состояние
// ---------------------------------------------------------------------
reg             chipinit        = 1;
reg  [14:0]     icounter        = 0;
reg  [2:0]      command         = cmd_nop;
reg  [2:0]      command_init    = cmd_nop;
reg  [12:0]     dram_init       = 12'b1_00000_00000;
reg  [12:0]     dram_address    = 0;
reg  [24:0]     current_addr    = 0;
reg  [ 9:0]     current_x       = 0;
reg  [ 9:0]     current_y       = 0;
reg  [ 3:0]     current_state   = state_idle;
reg  [ 3:0]     cursor          = 0;

// Инициализация чипа памяти
// Параметры: BurstFull, Sequential, CASLatency=2
// ---------------------------------------------------------------------
always @(posedge i_clock_25_mhz)
if (chipinit) begin

    case (icounter)

        init_time + 1:  begin command_init <= cmd_precharge; end
        init_time + 4:  begin command_init <= cmd_refresh; end
        init_time + 18: begin command_init <= cmd_loadmode; dram_init[9:0] <= 10'b0_00_010_0_111; end
        init_time + 21: begin chipinit     <= 0; end
        default:        begin command_init <= cmd_nop; end

    endcase

    icounter <= icounter + 1;

end

// Основной обработчик (видеокарта, ввод-вывод в память)
// Работает после инициализации памяти
// ---------------------------------------------------------------------
always @(posedge i_clock_100_mhz)
if (~chipinit) begin

    case (current_state)

        // Режим ожидания чтения, записи или строки
        state_idle: begin

            // Требуется перезагрузка строки (если она в видеокадре)
            if ((current_y[0] ^ Y[0]) && (Y < vt_visible)) begin

                current_y       <= Y;
                current_addr    <= Y * videomemory_row_width + videomemory_start;
                current_state   <= state_activate;
                current_x       <= 0;
                cursor          <= 1'b0;
                o_ready         <= 1'b0;

            end
            // Готовность всех данных
            else begin

                o_ready <= 1'b1;

            end

        end

    endcase

end

// ---------------------------------------------------------------------
// Видеоадаптер
// ---------------------------------------------------------------------

// Тайминги для горизонтальной развертки (640)
parameter hz_visible = 640;
parameter hz_front   = 16;
parameter hz_sync    = 96;
parameter hz_back    = 48;
parameter hz_whole   = 800;

// Тайминги для вертикальной развертки (480)
parameter vt_visible = 480;
parameter vt_front   = 10;
parameter vt_sync    = 2;
parameter vt_back    = 33;
parameter vt_whole   = 525;

// ---------------------------------------------------------------------
assign vga_hs = x  < (hz_back + hz_visible + hz_front); // NEG.
assign vga_vs = y >= (vt_back + vt_visible + vt_front); // POS.
// ---------------------------------------------------------------------

wire        xmax = (x == hz_whole - 1);
wire        ymax = (y == vt_whole - 1);
reg  [10:0] x    = 0;
reg  [10:0] y    = 0;
wire [9:0]  X    = x - hz_back; // X=[0..639]
wire [9:0]  Y    = y - vt_back; // Y=[0..479]

always @(posedge i_clock_25_mhz) begin

    // Кадровая развертка
    x <= xmax ?         0 : x + 1;
    y <= xmax ? (ymax ? 0 : y + 1) : y;

    // Вывод окна видеоадаптера
    if (x >= hz_back && x < hz_visible + hz_back &&
        y >= vt_back && y < vt_visible + vt_back)
    begin
         {vga_r, vga_g, vga_b} <= X[3:0] == 0 || Y[3:0] == 0 ? 12'hFFF : {X[4]^Y[4], 3'h0, X[5]^Y[5], 3'h0, X[6]^Y[6], 3'h0};
    end
    else {vga_r, vga_g, vga_b} <= 12'b0;

end

endmodule
