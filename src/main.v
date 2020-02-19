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
reg         ready = 0;
reg  [31:0] ram[1048576];
initial     $readmemh("mem.hex", ram, 20'h0000);

wire [31:0] o_address;
reg  [ 7:0] i_data  = 0;
reg  [ 7:0] i_data_ = 0;
wire [ 7:0] o_data;
wire        o_we;

// Чтение и запись в память
always @(posedge clk) begin

    // Память
    i_data  <= i_data_;
    i_data_ <= ram[ o_address[31:2] ];

    // Запись в память
    if (o_we) ram[ o_address[31:2] ] <= o_data;

end


// ---------------------------------------------------------------------
// Центрального процессора интерфейс
// ---------------------------------------------------------------------

x86cpu u0
(
    .clock      (clock),
    .ready      (ready),

    // Память
    .o_address  (o_address),
    .i_data     (i_data),
    .o_data     (o_data),
    .o_we       (o_we)

);

endmodule
