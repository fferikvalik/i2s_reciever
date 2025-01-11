module i2s #(
    parameter int SAMPLE_WIDTH = 16
) (
    input  logic CLK,           // �������� �������� ������
    input  logic BCLK,          // Bit clock �� ������
    input  logic LRCLK,         // LR clock �� ������
    input  logic ADCDA,         // ������������ ��� ������ �� ������
    input  logic [SAMPLE_WIDTH-1:0] LEFT_IN,   // ������ ������ ������ ��� ������ �� ���
    input  logic [SAMPLE_WIDTH-1:0] RIGHT_IN,  // ������ ������� ������ ��� ������ �� ���
    output logic [SAMPLE_WIDTH-1:0] LEFT_OUT,  // ����������������� ������ ���, ����� �����
    output logic [SAMPLE_WIDTH-1:0] RIGHT_OUT, // ����������������� ������ ���, ������ �����
    output logic DATAREADY,     // ����� - ������ ���������
    output logic BCLK_S,        // ������������������ ������ BCLK
    output logic LRCLK_S,       // ������������������ ������ LRCLK
    output logic DACDA          // ����� ������ �� ��� ������
);

// ==============================================================
// ������������� �������� ������� � ��������� �������
// ==============================================================
logic [2:0] bclk_trg;
always_ff @(posedge CLK) 
    bclk_trg <= {bclk_trg[1:0], BCLK};

assign BCLK_S = bclk_trg[1];                   // ������������������ BCLK
logic BCLK_PE = ~bclk_trg[2] & BCLK_S;         // ���������� �������� ����� BCLK
logic BCLK_NE = bclk_trg[2] & ~BCLK_S;         // ���������� ������ ����� BCLK

logic [2:0] lrclk_trg;
always_ff @(posedge CLK)
    lrclk_trg <= {lrclk_trg[1:0], LRCLK};

assign LRCLK_S = lrclk_trg[1];                 // ������������������ LRCLK
logic LRCLK_PRV = lrclk_trg[2];                // ���������� �������� LRCLK
logic LRCLK_CH = LRCLK_PRV ^ LRCLK_S;          // ����� ��������� LRCLK

logic [1:0] adcda_trg;
always_ff @(posedge CLK)
    adcda_trg <= {adcda_trg[0], ADCDA};

logic ADCDA_S = adcda_trg[1];                  // ������������������ DAT

// ==============================================================
// ��������� ������� ������� ������ I2S
// ==============================================================
logic [31:0] shift;
logic [31:0] shift_w = {shift[30:0], ADCDA_S};
always_ff @(posedge CLK)
    if (BCLK_PE)
        shift <= shift_w;

// ������� ��� ������� ������ (��� ���)
logic [SAMPLE_WIDTH-1:0] lb;
logic [SAMPLE_WIDTH-1:0] rb;

logic [4:0] bit_cnt; // ��������� �������� ����
logic actualLR;

// �������� ����� �� ���
logic [4:0] bit_ptr = (~bit_cnt - (32-SAMPLE_WIDTH));
assign DACDA = (bit_cnt < SAMPLE_WIDTH) ? (actualLR ? lb[bit_ptr] : rb[bit_ptr]) : 1'b0;

// ���������� ���������, ������������ ������ ��� ������ �� ���
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

// ������ ������ ���
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
