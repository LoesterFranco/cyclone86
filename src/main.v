`timescale 10ns / 1ns

module main;

// ---------------------------------------------------------------------
reg clk;    always #0.5 clk = ~clk;
reg clock;  always #2.0 clock = ~clock;

initial begin clk = 1; clock = 0; #2000 $finish; end
initial begin $dumpfile("main.vcd"); $dumpvars(0, main); end

// ---------------------------------------------------------------------
// Памяти интерфейс
// ---------------------------------------------------------------------
reg  [7:0]  ram[1048576];

wire [19:0] address;
reg  [7:0]  i_data  = 0;
reg  [7:0]  i_data_ = 0;
wire [7:0]  o_data;
wire        wr;
wire        locked = 1;

wire [3:0]  reg_a;
wire [3:0]  reg_b;
reg  [63:0] i_reg_a;
reg  [63:0] i_reg_b;
wire [63:0] reg_o;
wire        reg_w;

initial $readmemh("mem.hex", ram, 20'h0000);

// Чтение и запись в память
always @(posedge clk) begin

    // Память
    i_data  <= i_data_;
    i_data_ <= ram[ address ];
    if (wr) ram[ address ] <= o_data;

end

// ---------------------------------------------------------------------
// Центрального процессора интерфейс
// ---------------------------------------------------------------------

x86cpu u0
(
    clock,
    locked,

    // Память
    address,
    i_data,
    o_data,
    wr,

    // Регистры
    reg_a,
    reg_b,
    i_reg_a,
    i_reg_b,
    reg_o,
    reg_w
);

endmodule
