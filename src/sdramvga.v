/*
 * Модуль памяти 64Мб для DE0-CV с видеопамятью 640 x 480 x (4|8|16) bit
 */

module sdram(

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
    output reg          dram_ldqm,     // Low Data QMask
    output reg          dram_udqm      // High Data QMask
);

// Command modes                 RCW
// ---------------------------------------------------------------------
localparam cmd_loadmode     = 3'b000;
localparam cmd_refresh      = 3'b001;
localparam cmd_precharge    = 3'b010;
localparam cmd_activate     = 3'b011;
localparam cmd_write        = 3'b100;
localparam cmd_read         = 3'b101;
localparam cmd_burst_term   = 3'b110;
localparam cmd_nop          = 3'b111;

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

// Команды для памяти
// ---------------------------------------------------------------------
reg             chipinit        = 1;
reg  [14:0]     icounter        = 0;
reg  [2:0]      command         = cmd_nop;
reg  [2:0]      command_init    = cmd_nop;
reg  [12:0]     dram_init       = 12'b1_00000_00000;
reg  [12:0]     dram_address    = 0;

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

endmodule
