/*
 * Эмулятор процессора x86
 */

module x86cpu(

    input  wire        clock,       // Опорная частота 12.5
    input  wire        ready,       // Разрешение исполнения инструкции

    // 32-х битная шина данных
    output reg  [31:0] o_address,
    input  wire [31:0] i_data,
    output reg  [31:0] o_data,
    output reg         o_we
);

// 1. Наворачивание cbuf
// 2. Barell shifter >> o_address[1:0]
// 3. Детект префиксов (максимально 3)
// 4. Barell shifter >> prefix count (от 0 до 3 байт)
// 5. Детект опкода
// 6. Детект modrm
// 7. Детект immediate

reg [  2:0] buf_cur = 0;    // Курсор в буфере
reg [127:0] codebuf;        // 4 x 32 bit буфер кода

/* МОДУЛЬ ДЕКОДЕРА, ИСПОЛНИТЕЛЯ

    Декодирует инструкцию, а также исполняет ее

    - i_shift               относительный адрес старта в codebuf (eip[1:0])
    - codebuf
    - i_data / для o_address = ea
    out
    - i_size (размер инструкции)
    - result alu, flags, etc
    - request_data           нужны данные из памяти
    - request_ea             адрес, откуда нужны
    - request_write_back     нужно обратно записать
    - request_bit            битность данных
    - register_wb_id         номер регистра, куда записать
*/   


// ---------------------------------------------------------------------
reg [31:0]  eip         = 32'h00000000;

// Запись в буфер кода
// ---------------------------------------------------------------------
always @(posedge clock) begin

    case (buf_cur)

        0: codebuf[ 31: 0] <= i_data;
        1: codebuf[ 63:32] <= i_data;
        2: codebuf[ 95:64] <= i_data;
        3: codebuf[127:96] <= i_data;

    endcase
    
end

// Исполнение
// ---------------------------------------------------------------------
always @(posedge clock) begin

    // Записать можно только 4 dword
    if (buf_cur < 3) begin
    
        // Загрузка DWORD
        if (buf_cur == 0)
             o_address <= eip + 4;
        else o_address <= o_address + 4;

        buf_cur <= buf_cur + 1;

    end

    // if i_load_size < i_instr_size ... next cur_buf else ... exec instr
        
end

endmodule
