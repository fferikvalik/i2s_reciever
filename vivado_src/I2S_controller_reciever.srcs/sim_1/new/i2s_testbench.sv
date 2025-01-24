module i2s_tb;

    // Параметры
    parameter SAMPLE_WIDTH = 16;

    // Тестовые сигналы
    logic CLK;
    logic BCLK;
    logic LRCLK;
    logic ADCDA;
    logic [SAMPLE_WIDTH-1:0] LEFT_IN;
    logic [SAMPLE_WIDTH-1:0] RIGHT_IN;
    logic [SAMPLE_WIDTH-1:0] LEFT_OUT;
    logic [SAMPLE_WIDTH-1:0] RIGHT_OUT;
    logic DATAREADY;
    logic BCLK_S;
    logic LRCLK_S;
    logic DACDA;

    // Система под тестом (DUT)
    i2s #(.SAMPLE_WIDTH(SAMPLE_WIDTH)) dut (
        .CLK(CLK),
        .BCLK(BCLK),
        .LRCLK(LRCLK),
        .ADCDA(ADCDA),
        .LEFT_IN(LEFT_IN),
        .RIGHT_IN(RIGHT_IN),
        .LEFT_OUT(LEFT_OUT),
        .RIGHT_OUT(RIGHT_OUT),
        .DATAREADY(DATAREADY),
        .BCLK_S(BCLK_S),
        .LRCLK_S(LRCLK_S),
        .DACDA(DACDA)
    );

    // Генерация тактового сигнала CLK (50 МГц)
    always #10 CLK = ~CLK;

    // Генерация сигналов BCLK и LRCLK
    initial begin
        BCLK = 0;
        LRCLK = 0;
        forever begin
            #20 BCLK = ~BCLK;        // 1.25 МГц
            if (BCLK) LRCLK = ~LRCLK; // LRCLK изменяется на переднем фронте BCLK
        end
    end

    // Генерация данных ADCDA
    initial begin
        ADCDA = 0;
        forever begin
            @(posedge BCLK);
            ADCDA = $random % 2; // Генерация случайного значения (0 или 1)
        end
    end

    // Начальная настройка
    initial begin
        CLK = 0;
        LEFT_IN = 16'hAAAA; // Пример данных левого канала
        RIGHT_IN = 16'h5555; // Пример данных правого канала

        // Мониторинг сигналов
        $monitor("Time: %0t | BCLK: %b | LRCLK: %b | ADCDA: %b | LEFT_OUT: %h | RIGHT_OUT: %h | DATAREADY: %b",
                 $time, BCLK, LRCLK, ADCDA, LEFT_OUT, RIGHT_OUT, DATAREADY);

        // Завершение теста
        #2000;
        $finish;
    end

endmodule
