module i2s #(
    parameter int SAMPLE_WIDTH = 16
) (
    input  logic CLK,           // Основной тактовый сигнал
    input  logic BCLK,          // Bit clock от кодека
    input  logic LRCLK,         // LR clock от кодека
    input  logic ADCDA,         // Оцифрованные АЦП данные от кодека
    input  logic [SAMPLE_WIDTH-1:0] LEFT_IN,   // Вектор левого канала для вывода на ЦАП
    input  logic [SAMPLE_WIDTH-1:0] RIGHT_IN,  // Вектор правого канала для вывода на ЦАП
    output logic [SAMPLE_WIDTH-1:0] LEFT_OUT,  // Десериализованные данные АЦП, левый канал
    output logic [SAMPLE_WIDTH-1:0] RIGHT_OUT, // Десериализованные данные АЦП, правый канал
    output logic DATAREADY,     // Строб - данные обновлены
    output logic BCLK_S,        // Синхронизированный сигнал BCLK
    output logic LRCLK_S,       // Синхронизированный сигнал LRCLK
    output logic DACDA          // Выход данных на ЦАП кодека
);

// ==============================================================
// Синхронизация клоковых доменов и выделение фронтов
// ==============================================================
logic [2:0] bclk_trg;
always_ff @(posedge CLK) 
    bclk_trg <= {bclk_trg[1:0], BCLK};

assign BCLK_S = bclk_trg[1];                   // Синхронизированный BCLK
logic BCLK_PE = ~bclk_trg[2] & BCLK_S;         // Выделенный передний фронт BCLK
logic BCLK_NE = bclk_trg[2] & ~BCLK_S;         // Выделенный задний фронт BCLK

logic [2:0] lrclk_trg;
always_ff @(posedge CLK)
    lrclk_trg <= {lrclk_trg[1:0], LRCLK};

assign LRCLK_S = lrclk_trg[1];                 // Синхронизированный LRCLK
logic LRCLK_PRV = lrclk_trg[2];                // Предыдущее значение LRCLK
logic LRCLK_CH = LRCLK_PRV ^ LRCLK_S;          // Любое изменение LRCLK

logic [1:0] adcda_trg;
always_ff @(posedge CLK)
    adcda_trg <= {adcda_trg[0], ADCDA};

logic ADCDA_S = adcda_trg[1];                  // Синхронизированный DAT

// ==============================================================
// Сдвиговый регистр входных данных I2S
// ==============================================================
logic [31:0] shift;
logic [31:0] shift_w = {shift[30:0], ADCDA_S};
always_ff @(posedge CLK)
    if (BCLK_PE)
        shift <= shift_w;

// Вектора для входных данных (для ЦАП)
logic [SAMPLE_WIDTH-1:0] lb;
logic [SAMPLE_WIDTH-1:0] rb;

logic [4:0] bit_cnt; // Указатель текущего бита
logic actualLR;

// Битстрим выход на ЦАП
logic [4:0] bit_ptr = (~bit_cnt - (32-SAMPLE_WIDTH));
assign DACDA = (bit_cnt < SAMPLE_WIDTH) ? (actualLR ? lb[bit_ptr] : rb[bit_ptr]) : 1'b0;

// Вычисление указателя, защелкивание данных для выхода на ЦАП
always_ff @(posedge CLK) begin
    if (LRCLK_CH) begin
        bit_cnt <= 5'd31;
        actualLR <= ~LRCLK_S;
    end else if (BCLK_NE) begin
        actualLR <= LRCLK_S;
        bit_cnt <= bit_cnt + 1'b1;
        if (bit_cnt == 5'd31) begin
            lb <= LEFT_IN;
            rb <= RIGHT_IN;
        end
    end
end

// Захват данных АЦП
always_ff @(posedge CLK) begin
    if (LRCLK_CH) begin
        if (LRCLK_PRV) begin
            RIGHT_OUT <= shift_w[31:32-SAMPLE_WIDTH];
            DATAREADY <= 1'b1;
        end else begin
            LEFT_OUT <= shift_w[31:32-SAMPLE_WIDTH];
        end
    end else begin
        DATAREADY <= 1'b0;
    end
end

endmodule
