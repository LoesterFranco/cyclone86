/*
 * Модуль памяти 64Мб для DE0-CV с видеопамятью 640 x 480 x 16 цветов
 */

module sdramvga
(
    // Тактовая частота 100 МГц (SDRAM) 25 МГц (видео)
    input  wire         clock_100_mhz,
    input  wire         clock_25_mhz,

    // Управленеи
    input  wire [25:0]  i_address,      // 64 МБ памяти
    input  wire         i_we,           // Признак записи в память
    input  wire [ 7:0]  i_data,         // Данные для записи (8 бит)
    output reg  [ 7:0]  o_data,         // Прочитанные данные
    output reg          o_ready,        // Готовность данных (=1 Готово)

    // Видеоадаптер VGA (640 x 480 x 16 цветов)
    output reg  [3:0]   vga_r,
    output reg  [3:0]   vga_g,
    output reg  [3:0]   vga_b,
    output wire         vga_hs,
    output wire         vga_vs,

    // Физический интерфейс DRAM
    output wire         dram_clk,       // Тактовая частота памяти
    output reg  [ 1:0]  dram_ba,        // 4 банка
    output wire [12:0]  dram_addr,      // Максимальный адрес 2^13=8192
    inout  wire [15:0]  dram_dq,        // Ввод-вывод
    output wire         dram_cas,       // CAS
    output wire         dram_ras,       // RAS
    output wire         dram_we,        // WE
    output reg          dram_ldqm,      // Маска для младшего байта
    output reg          dram_udqm,      // Маска для старшего байта

    // Буфер строки (сдвоенный)
    output reg  [ 8:0]  vb_address_w,
    output reg  [ 8:0]  vb_address_r,
    output reg          vb_wren,
    output reg  [15:0]  vb_data,        // vb[vb_address_w] = vb_data
    input  wire [15:0]  vb_read         // vb_read = vb[vb_address_r]
);

// Параметр начального адреса видеопамяти
parameter videomemory_start     = 0;

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
localparam state_write     = 4;

localparam request_none    = 0;
localparam request_write   = 1;
localparam request_read    = 2;

`ifdef ICARUS
localparam init_time = 0;
`else
localparam init_time = 5000;
`endif

initial begin

    o_ready   = 0;
    dram_ba   = 0;
    dram_ldqm = 1;
    dram_udqm = 1;
    vb_wren   = 0;

end

// Связь с физическим интерфейсом памяти
// ---------------------------------------------------------------------

// Направление данных (in, out), если dram_we=0, то запись; иначе чтение
assign dram_dq   =  dram_we ? 16'hZZZZ : {i_data, i_data};
assign dram_clk  =  clock_100_mhz;

// Адрес и команда
assign {dram_addr                  } = chipinit ? dram_init    : address;
assign {dram_ras, dram_cas, dram_we} = chipinit ? command_init : command;

// Команды для памяти, регистры, текущее состояние
// ---------------------------------------------------------------------
reg             chipinit        = 1;
reg  [14:0]     icounter        = 0;
reg  [2:0]      command         = cmd_nop;
reg  [2:0]      command_init    = cmd_nop;
reg  [12:0]     dram_init       = 12'b1_00000_00000;
reg  [12:0]     address         = 0;
reg  [24:0]     current_addr    = 0;
reg  [ 7:0]     current_x       = 0;
reg             current_y       = 0;
reg  [ 3:0]     current_state   = state_idle;
reg  [ 3:0]     cursor          = 0;
reg  [25:0]     w_address       = 0;
reg  [ 1:0]     rw_request      = 0;

// Инициализация чипа памяти
// Параметры: BurstFull, Sequential, CASLatency=2
// ---------------------------------------------------------------------
always @(posedge clock_25_mhz)
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
always @(posedge clock_100_mhz)
if (~chipinit) begin

    case (current_state)

        // Режим ожидания чтения, записи, или новой строки
        // -----------------------------------------
        state_idle: begin

            // Высший приоритет на установку o_ready <= 0 для чтения/записи
            if ((i_address != w_address) && (rw_request == request_none)) begin

                rw_request  <= i_we ? request_write : request_read;
                w_address   <= i_address;
                o_ready     <= 1'b0;

                if (i_we) o_data <= i_data;

            end
            // Требуется перезагрузка строки (если она в видеокадре)
            // 160 слов = 4 цвета каждое слово
            else if ((current_y ^ Y[0]) && (Y < 480)) begin

                current_state <= state_activate;
                current_addr  <= Y*256 + 2 + videomemory_start; // 160
                current_x     <= 0;
                current_y     <= Y[0];
                cursor        <= 1'b0;
                o_ready       <= 1'b0;
                dram_ldqm     <= 1'b0;
                dram_udqm     <= 1'b0;

            end
            // Обнаружена ЗАПИСЬ в новую ячейку памяти
            else if (rw_request) begin

                cursor        <= 0;
                command       <= cmd_activate;
                rw_request    <= request_none;
                current_state <= state_write;

                current_addr  <=  w_address[25:1];
                address       <=  w_address[23:11];
                dram_ba       <=  w_address[25:24];
                dram_udqm     <=  w_address[0];
                dram_ldqm     <= ~w_address[0];

            end
            
            // Готовность всех данных
            else begin o_ready <= 1'b1; end

        end

        // Активировать строку и загрузить конвейер
        // -----------------------------------------
        state_activate: case (cursor)

            // Задать банк 23:22 | 21:10 | 9:0
            0: begin

                cursor  <= 1;
                command <= cmd_activate;
                address <= current_addr[22:10]; // 13 бит [12:0]
                dram_ba <= current_addr[24:23]; // 2 бита [ 1:0]

            end

            // Ожидание принятия команды `activate` (3 такта)

            // Задать текущий адрес
            4: begin

                cursor  <= 5;
                command <= cmd_read;
                address <= {1'b1, current_addr[9:0]};

            end

            // Активация #1
            5: begin

                cursor       <= cursor + 1;
                current_addr <= current_addr + 1;
                address[9:0] <= address[9:0] + 1;

            end

            // Активация #2
            6: begin

                cursor        <= 0;
                current_state <= state_update;
                current_addr  <= current_addr + 1;
                address[9:0]  <= address[9:0] + 1;

            end

            // По умолчанию NOP
            default: begin

                command <= cmd_nop;
                cursor  <= cursor + 1;

            end

        endcase

        // Последовательное считывание из памяти
        // -----------------------------------------
        state_update: begin

            // Запись в необходимую ячейку
            vb_wren      <= 1;
            vb_address_w <= {~Y[0], current_x[7:0]};
            vb_data      <= dram_dq;

            // Смещение в памяти
            current_addr <= current_addr + 1;
            current_x    <= current_x + 1;
            address[9:0] <= address[9:0] + 1;

            // Закрыть строку по ее завершении
            if (current_x == 159) current_state <= state_close_row;

        end

        // Закрыть строку
        // -----------------------------------------
        state_close_row: case (cursor)

            // Перезарядка банков, отключить запись
            0: begin

                command     <= cmd_precharge;
                address[10] <= 1'b1;
                vb_wren     <= 1'b0;
                cursor      <= 1;
                dram_ldqm   <= 1'b1;
                dram_udqm   <= 1'b1;

            end

            // Ожидание завершения перезарядки банка
            1: begin cursor <= cursor + 1; command <= cmd_nop; end

            // Решение о продлении считывания из памяти
            2: current_state <= state_idle;

        endcase

        // Запись в память
        // -----------------------------------------
        state_write: case (cursor)

            // Запись
            2: begin
            
                cursor  <= 3;
                command <= cmd_write;
                address <= {1'b1, current_addr[9:0]};

            end

            // Перезарядка банка, закрытие строки
            5: begin
            
                cursor      <= 6;
                command     <= cmd_precharge;
                address[10] <= 1'b1;
                dram_udqm   <= 1'b1;
                dram_ldqm   <= 1'b1;

            end

            // Переход к IDLE
            6: begin

                cursor        <= 0;
                command       <= cmd_nop;
                current_state <= state_idle;

            end

            // NOP (ожидание активации строки)
            default: begin command <= cmd_nop; cursor <= cursor + 1; end

        endcase

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

// Скорректированное значение (X, Y) относительно конвейеров и порожека
wire [9:0]  X    = x - hz_back + 5; // X=[0..639]
wire [8:0]  Y    = y - vt_back + 1; // Y=[0..479]

// Вычисление цвета
reg  [ 3:0] color_id;
reg  [11:0] color_rgb;
reg  [ 1:0] color_ax;

// Реализация пиксельного буфера
always @(posedge clock_25_mhz) begin

    // Кадровая развертка
    x <= xmax ?         0 : x + 1;
    y <= xmax ? (ymax ? 0 : y + 1) : y;

    // Вывод окна видеоадаптера
    if (x >= hz_back && x < hz_visible + hz_back &&
        y >= vt_back && y < vt_visible + vt_back)
    begin
         {vga_r, vga_g, vga_b} <= color_rgb; // T=4
    end
    else {vga_r, vga_g, vga_b} <= 12'b0;

    // T=3 Декодирование цвета
    case (color_id)

        4'b0000: color_rgb <= 12'h000;
        4'b0001: color_rgb <= 12'h008;
        4'b0010: color_rgb <= 12'h080;
        4'b0011: color_rgb <= 12'h088;
        4'b0100: color_rgb <= 12'h800;
        4'b0101: color_rgb <= 12'h808;
        4'b0110: color_rgb <= 12'h880;
        4'b0111: color_rgb <= 12'hccc;
        4'b1000: color_rgb <= 12'h888;
        4'b1001: color_rgb <= 12'h00f;
        4'b1010: color_rgb <= 12'h0f0;
        4'b1011: color_rgb <= 12'h0ff;
        4'b1100: color_rgb <= 12'hf00;
        4'b1101: color_rgb <= 12'hf0f;
        4'b1110: color_rgb <= 12'hff0;
        4'b1111: color_rgb <= 12'hfff;

    endcase

    // T=2 Декодирование ниббла
    case (color_ax)

        2'b00: color_id <= vb_read[15:12];
        2'b01: color_id <= vb_read[11:8];
        2'b10: color_id <= vb_read[ 7:4];
        2'b11: color_id <= vb_read[ 3:0];

    endcase

    // T=1 Следующий пиксель
    vb_address_r <= {Y[0], X[9:2]};
    color_ax     <=  X[1:0];

end

endmodule
