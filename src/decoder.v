/* ---------------------------------------------------------------------
 * Центральный исполнительно-декодирующий модуль
 * Принимает на вход данные с загружаемого кодового буфера,
 * интерпретирует префиксы, опкоды, modrm, immediate и вычисляет
 * итоговые результаты, а также устанавливает необходимые запросы к
 * памяти или данным
 * ------------------------------------------------------------------ */

module decoder
(
    // Данные для анализа и декодера
    input   wire [127:0]    i_codebuf,  // Исходный даннее
    input   wire [  1:0]    align,      // При невыровненных

    // Данные по адресу modrm_segment : modrm_ea
    output  reg  [ 31:0]    modrm_segment,
    output  reg  [ 31:0]    modrm_ea,
    input   wire [ 31:0]    data_ea,
    output  reg             op_bitsize,         // =0 byte =1 word/dword
    output  reg             op_dir,             // =0 rm,reg; =1 reg, rm
    output  reg             request_ea,         // Необходимы данные для [data_ea]

    // Регистры общего назначения
    input   wire [ 31:0]    eax,
    input   wire [ 31:0]    ecx,
    input   wire [ 31:0]    edx,
    input   wire [ 31:0]    ebx,
    input   wire [ 31:0]    esp,
    input   wire [ 31:0]    ebp,
    input   wire [ 31:0]    esi,
    input   wire [ 31:0]    edi,

    // Сегментные регистры
    input   wire [ 15:0]    es,
    input   wire [ 15:0]    cs,
    input   wire [ 15:0]    ss,
    input   wire [ 15:0]    ds,
    input   wire [ 15:0]    fs,
    input   wire [ 15:0]    gs
);

// Итоговые операнды
reg  [31:0] op1;
reg  [31:0] op2;

// Шаг 0 .Выравнивание кода, если данные не были выровнены ранее (0-3 байта)
wire [127:0] a_codebuf = align[0] ? i_codebuf[127: 8] : i_codebuf;
wire [127:0] b_codebuf = align[1] ? a_codebuf[127:16] : a_codebuf;

// Шаг 1. Декодирование до 3-х префиксов
`include "prefix.v"

// Шаг 2. Удаление префиксов из кодового буфера
wire [127:0] c_codebuf = p_size[0] ? b_codebuf[127: 8] : b_codebuf;
wire [127:0]   codebuf = p_size[1] ? c_codebuf[127:16] : c_codebuf;

// Шаг 3. Декодирование опкода и наличия байта modrm, зависит от префиксов
// Определение наличия modrm
`include "modrm.v"

// Декодирование modrm 16/32
// Декодирование immediate
// Вычисление результата (в том числе возможен вход из общей памяти)
// Выдача запросов на память, если есть, ea, и прочего, что нужно сделать
// -- на следующих тактах, т.е. досбор данных

endmodule
