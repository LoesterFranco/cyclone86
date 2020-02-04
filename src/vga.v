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

// Тайминги для горизонтальной развертки (640)
parameter horiz_visible = 640;
parameter horiz_back    = 48;
parameter horiz_sync    = 96;
parameter horiz_front   = 16;
parameter horiz_whole   = 800;

// Тайминги для вертикальной развертки (400)
parameter vert_visible  = 400;
parameter vert_back     = 35;
parameter vert_sync     = 2;
parameter vert_front    = 12;
parameter vert_whole    = 449;

// ---------------------------------------------------------------------
// H: [48 back] .. [640 vis] .. [16 front] .. [96 hsync]
// V: [35 back] .. [400 vis] .. [12 front] .. [2 sync]
// ---------------------------------------------------------------------
assign VGA_HS = x >= (horiz_back + horiz_visible + horiz_front);
assign VGA_VS = y >= ( vert_back +  vert_visible +  vert_front);
// ---------------------------------------------------------------------

reg  [9:0] x = 0;
reg  [9:0] y = 0;

// x,y = [0..w-1, 0..h-1]
wire [9:0] X = x - horiz_back;
wire [9:0] Y = y - vert_back;

wire xmax = (x == horiz_whole - 1);
wire ymax = (y == vert_whole  - 1);

always @(posedge CLOCK) begin

    // Кадровая развертка
    x <= xmax ?         0 : x + 1;
    y <= xmax ? (ymax ? 0 : y + 1) : y;

    // Вывод окна видеоадаптера
    if (x >= horiz_back && x < horiz_visible + horiz_back &&
        y >= vert_back  && y < vert_visible  + vert_back)
    begin
         {VGA_R, VGA_G, VGA_B} <= X[3:0] == 0 || Y[3:0] == 0 ? 12'hFFF : 12'h555;
    end
    else {VGA_R, VGA_G, VGA_B} <= 12'b0;

end

endmodule
