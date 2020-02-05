module vga
(
    // Опорная частота
    input   wire        CLOCK,

    // Выходные данные
    output  reg  [3:0]  VGA_R,      // 4 бит на красный
    output  reg  [3:0]  VGA_G,      // 4 бит на зеленый
    output  reg  [3:0]  VGA_B,      // 4 бит на синий
    output  wire        VGA_HS,     // горизонтальная развертка
    output  wire        VGA_VS      // вертикальная развертка
);

// ---------------------------------------------------------------------

// Тайминги для горизонтальной развертки (800)
parameter hz_visible = 800;
parameter hz_front   = 56;
parameter hz_sync    = 120;
parameter hz_back    = 64;
parameter hz_whole   = 1040;

// Тайминги для вертикальной развертки (600)
parameter vt_visible  = 600;
parameter vt_front    = 37;
parameter vt_sync     = 6;
parameter vt_back     = 23;
parameter vt_whole    = 666;

// ---------------------------------------------------------------------
assign VGA_HS = x >= (hz_back + hz_visible + hz_front); // POS.
assign VGA_VS = y >= (vt_back + vt_visible + vt_front); // POS.
// ---------------------------------------------------------------------

wire        xmax = (x == hz_whole - 1);
wire        ymax = (y == vt_whole - 1);
reg  [10:0] x    = 0;
reg  [10:0] y    = 0;
wire [9:0]  X    = x - hz_back; // X=[0..799]
wire [9:0]  Y    = y - vt_back; // Y=[0..599]

always @(posedge CLOCK) begin

    // Кадровая развертка
    x <= xmax ?         0 : x + 1;
    y <= xmax ? (ymax ? 0 : y + 1) : y;

    // Вывод окна видеоадаптера
    if (x >= hz_back && x < hz_visible + hz_back &&
        y >= vt_back && y < vt_visible + vt_back)
    begin
         {VGA_R, VGA_G, VGA_B} <= X >= 144 && X < 656 && Y >= 44 && Y < 556 ? 12'h48C : 12'h222;
    end
    else {VGA_R, VGA_G, VGA_B} <= 12'b0;

end

endmodule
