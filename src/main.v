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
wire        rd;
wire        locked = 1;

initial $readmemh("bios/lo.hex", ram, 20'h0000);

// Чтение и запись в память
always @(posedge clk) begin

            i_data  <= i_data;
    if (rd) i_data_ <= ram[ address ];
    if (wr) ram[ address ] <= o_data;

end

// ---------------------------------------------------------------------
// Центрального процессора интерфейс
// ---------------------------------------------------------------------

x86cpu u0
(
    clock,
    locked,
    address,
    i_data,
    o_data,
    rd,
    wr
);

endmodule
