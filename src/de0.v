module de0(

      /* Reset */
      input              RESET_N,

      /* Clocks */
      input              CLOCK_50,
      input              CLOCK2_50,
      input              CLOCK3_50,
      inout              CLOCK4_50,

      /* DRAM */
      output             DRAM_CKE,
      output             DRAM_CLK,
      output      [1:0]  DRAM_BA,
      output      [12:0] DRAM_ADDR,
      inout       [15:0] DRAM_DQ,
      output             DRAM_CAS_N,
      output             DRAM_RAS_N,
      output             DRAM_WE_N,
      output             DRAM_CS_N,
      output             DRAM_LDQM,
      output             DRAM_UDQM,

      /* GPIO */
      inout       [35:0] GPIO_0,
      inout       [35:0] GPIO_1,

      /* 7-Segment LED */
      output      [6:0]  HEX0,
      output      [6:0]  HEX1,
      output      [6:0]  HEX2,
      output      [6:0]  HEX3,
      output      [6:0]  HEX4,
      output      [6:0]  HEX5,

      /* Keys */
      input       [3:0]  KEY,

      /* LED */
      output      [9:0]  LEDR,

      /* PS/2 */
      inout              PS2_CLK,
      inout              PS2_DAT,
      inout              PS2_CLK2,
      inout              PS2_DAT2,

      /* SD-Card */
      output             SD_CLK,
      inout              SD_CMD,
      inout       [3:0]  SD_DATA,

      /* Switch */
      input       [9:0]  SW,

      /* VGA */
      output      [3:0]  VGA_R,
      output      [3:0]  VGA_G,
      output      [3:0]  VGA_B,
      output             VGA_HS,
      output             VGA_VS
);

// Z-state
assign DRAM_DQ = 16'hzzzz;
assign GPIO_0  = 36'hzzzzzzzz;
assign GPIO_1  = 36'hzzzzzzzz;

// LED OFF
assign HEX0 = ps2_data_register; // 7'b1111111;
assign HEX1 = 7'b1111111;
assign HEX2 = 7'b1111111;
assign HEX3 = 7'b1111111;
assign HEX4 = 7'b1111111;
assign HEX5 = 7'b1111111;

// ---------------------------------------------------------------------
wire clock_25;
wire clock_50;
wire clock_100;

pll u0(

    // Источник тактирования
    .clkin (CLOCK_50),

    // Производные частоты
    .m25   (clock_25),
    .m50   (clock_50),
    .m75   (clock_75),
    .m100  (clock_100),
    .m106  (clock_106),
);

// -----------------------------------------------------------------------
// Клавиатура
// -----------------------------------------------------------------------
reg         kbd_reset           = 1'b0;
reg  [7:0]  ps2_command         = 1'b0;
reg         ps2_command_send    = 1'b0;
wire        ps2_command_was_sent;
wire        ps2_error_communication_timed_out;
wire [7:0]  ps2_data;
wire        ps2_data_clk;

ps2_keyboard ukdb(

    /* Вход */
    .CLOCK_50       (CLOCK_50),
    .reset          (kbd_reset),
    .the_command    (ps2_command),
    .send_command   (ps2_command_send),

    /* Ввод-вывод */
    .PS2_CLK        (PS2_CLK),
    .PS2_DAT        (PS2_DAT),

    /* Статус команды */
    .command_was_sent               (ps2_command_was_sent),
    .error_communication_timed_out  (ps2_error_communication_timed_out),

    /* Выход полученных */
    .received_data      (ps2_data),
    .received_data_en   (ps2_data_clk)
);

reg [6:0] ps2_data_register;

// Данные принимаются только по тактовому сигналу и при наличии ps2_data_clk
always @(posedge CLOCK_50) begin

    if (ps2_data_clk) begin
        ps2_data_register <= ps2_data;
    end

end

// -----------------------------------------------------------------------
// Видеодаптер
// -----------------------------------------------------------------------

vga u1(
    .CLOCK  (clock_50),
    .VGA_R  (VGA_R),
    .VGA_G  (VGA_G),
    .VGA_B  (VGA_B),
    .VGA_HS (VGA_HS),
    .VGA_VS (VGA_VS)
);

endmodule

// *********************************************************************
// Модуль PLL
// *********************************************************************

module  pll(

	input wire clkin,
	input wire rst,

	output wire m25,
	output wire m50,
	output wire m75,
	output wire m100,
	output wire m106,

	output wire locked
);

altera_pll #(
    .fractional_vco_multiplier("false"),
    .reference_clock_frequency("50.0 MHz"),
    .operation_mode("normal"),
    .number_of_clocks(5),
    .output_clock_frequency0("25.0 MHz"),
    .phase_shift0("0 ps"),
    .duty_cycle0(50),
    .output_clock_frequency1("100.0 MHz"),
    .phase_shift1("0 ps"),
    .duty_cycle1(50),
    .output_clock_frequency2("50 MHz"),
    .phase_shift2("0 ps"),
    .duty_cycle2(50),
    .output_clock_frequency3("106 MHz"),
    .phase_shift3("0 ps"),
    .duty_cycle3(50),
    .output_clock_frequency4("75 MHz"),
    .phase_shift4("0 ps"),
    .duty_cycle4(50),
    .output_clock_frequency5("0 MHz"),
    .phase_shift5("0 ps"),
    .duty_cycle5(50),
    .output_clock_frequency6("0 MHz"),
    .phase_shift6("0 ps"),
    .duty_cycle6(50),
    .output_clock_frequency7("0 MHz"),
    .phase_shift7("0 ps"),
    .duty_cycle7(50),
    .output_clock_frequency8("0 MHz"),
    .phase_shift8("0 ps"),
    .duty_cycle8(50),
    .output_clock_frequency9("0 MHz"),
    .phase_shift9("0 ps"),
    .duty_cycle9(50),
    .output_clock_frequency10("0 MHz"),
    .phase_shift10("0 ps"),
    .duty_cycle10(50),
    .output_clock_frequency11("0 MHz"),
    .phase_shift11("0 ps"),
    .duty_cycle11(50),
    .output_clock_frequency12("0 MHz"),
    .phase_shift12("0 ps"),
    .duty_cycle12(50),
    .output_clock_frequency13("0 MHz"),
    .phase_shift13("0 ps"),
    .duty_cycle13(50),
    .output_clock_frequency14("0 MHz"),
    .phase_shift14("0 ps"),
    .duty_cycle14(50),
    .output_clock_frequency15("0 MHz"),
    .phase_shift15("0 ps"),
    .duty_cycle15(50),
    .output_clock_frequency16("0 MHz"),
    .phase_shift16("0 ps"),
    .duty_cycle16(50),
    .output_clock_frequency17("0 MHz"),
    .phase_shift17("0 ps"),
    .duty_cycle17(50),
    .pll_type("General"),
    .pll_subtype("General")
)
altera_pll_i (
    .rst	(rst),
    .outclk	({m75, m106, m50, m100, m25}),
    .locked	(locked),
    .fboutclk ( ),
    .fbclk	(1'b0),
    .refclk	(clkin)
);

endmodule
