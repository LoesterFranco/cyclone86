/*
 * Эмулятор процессора x86
 */

module x86cpu(

    input  wire        clock,       // Опорная частота 12.5
    input  wire        ready,       // Разрешение исполнения инструкции

    // 32-х битная шина данных
    output reg  [31:0] o_address,
    input  wire [ 7:0] i_data,
    output reg  [ 7:0] o_data,
    output reg         o_we
);


endmodule
