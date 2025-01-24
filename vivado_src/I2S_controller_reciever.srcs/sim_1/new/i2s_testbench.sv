module i2s_tb;

    // ���������
    parameter SAMPLE_WIDTH = 16;

    // �������� �������
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

    // ������� ��� ������ (DUT)
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

    // ��������� ��������� ������� CLK (50 ���)
    always #10 CLK = ~CLK;

    // ��������� �������� BCLK � LRCLK
    initial begin
        BCLK = 0;
        LRCLK = 0;
        forever begin
            #20 BCLK = ~BCLK;        // 1.25 ���
            if (BCLK) LRCLK = ~LRCLK; // LRCLK ���������� �� �������� ������ BCLK
        end
    end

    // ��������� ������ ADCDA
    initial begin
        ADCDA = 0;
        forever begin
            @(posedge BCLK);
            ADCDA = $random % 2; // ��������� ���������� �������� (0 ��� 1)
        end
    end

    // ��������� ���������
    initial begin
        CLK = 0;
        LEFT_IN = 16'hAAAA; // ������ ������ ������ ������
        RIGHT_IN = 16'h5555; // ������ ������ ������� ������

        // ���������� ��������
        $monitor("Time: %0t | BCLK: %b | LRCLK: %b | ADCDA: %b | LEFT_OUT: %h | RIGHT_OUT: %h | DATAREADY: %b",
                 $time, BCLK, LRCLK, ADCDA, LEFT_OUT, RIGHT_OUT, DATAREADY);

        // ���������� �����
        #2000;
        $finish;
    end

endmodule
