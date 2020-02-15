/*
 * Эмулятор процессора x86
 */

module x86cpu(

    input  wire        clock,       // Опорная частота
    input  wire        locked,      // Разрешение исполнения инструкции

    // Доступ в память
    output wire [31:0] o_address,   // Адрес в памяти
    input  wire [7:0]  i_data,
    output reg  [7:0]  o_data,
    output reg         o_wr
);

endmodule
