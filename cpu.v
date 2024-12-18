`include "macro.vh"


module cpu(
    (*mark_debug="true"*)input           clk,                // 时钟信号
    (*mark_debug="true"*)input           resetn,             // 低有效复位信号

    (*mark_debug="true"*)output          inst_sram_en,       // 指令存储器读使能
    (*mark_debug="true"*)output[31:0]    inst_sram_addr,     // 指令存储器读地址
    (*mark_debug="true"*)input[31:0]     inst_sram_rdata,    // 指令存储器读出的数据

    output          data_sram_en,       // 数据存储器端口读/写使能
    output[3:0]     data_sram_wen,      // 数据存储器写使能      
    output[31:0]    data_sram_addr,     // 数据存储器读/写地址
    output[31:0]    data_sram_wdata,    // 写入数据存储器的数据
    input[31:0]     data_sram_rdata,    // 数据存储器读出的数据

    // 供自动测试环境进行CPU正确性检查
    output[31:0]    debug_wb_pc,        // 当前正在执行指令的PC
    output          debug_wb_rf_wen,    // 当前通用寄存器组的写使能信号
    output[4:0]     debug_wb_rf_wnum,   // 当前通用寄存器组写回的寄存器编号
    output[31:0]    debug_wb_rf_wdata   // 当前指令需要写回的数据
);

    wire[31:0]  PC;
    (*mark_debug="true"*)reg         init_PC;
 
    // 信号发起
    (*mark_debug="true"*)reg resetn_have_received, resetn_have_handled;


    initial begin
        resetn_have_handled = 0; 
        resetn_have_received = 0;
        init_PC = 0;
        last_PC = 0;
        last_last_PC = 0;
        reg_debug_wb_rf_wen = 0;
        mem_load = 0;
        reg_debug_wb_rf_wnum = 0;
        reg_debug_wb_rf_wdata = 0;
        old_rt = 0;
    end

    always @(posedge clk) begin
        if (!resetn) begin
            resetn_have_received = 0;
        end

        if (resetn_have_handled) begin
            reg_debug_wb_rf_wen = (alu_en_write&&rd!=0); // | mem_load;

            // 将 ALU 的运算结果写回
            if (alu_en_write) begin
                if (rd == 0) begin

                end else begin
                    registers[rd] = alu_reg_write_val;
                    reg_debug_wb_rf_wnum = rd;
                    reg_debug_wb_rf_wdata = alu_reg_write_val;
                end
            end
            
            // 将内存值写回寄存器
            if (mem_load) begin
                if (alu_en_write && rd==old_rt) begin 
                    // 如果读内存写入的寄存器和运算写入的寄存器是同一个
                    // 则不将读内存的值写入寄存器
                    // 例如语句如下
                    // load r3, 4(r0)
                    // add  r3, r3, r1
                end else begin 
                    registers[old_rt] = data_sram_rdata;
                end
            end
            if (op==6'b100011 && rt!=0) begin
                mem_load = 1;
                old_rt = rt;
            end else begin
                mem_load = 0;
            end
            last_last_PC = last_PC;
            last_PC = PC;
        end


        if (resetn && resetn_have_received) begin
            resetn_have_handled = 1;
            init_PC = 0; 
            // last_PC = 0;
            // last_last_PC = 0;
        end

        if (resetn && resetn_have_received==0) begin
            resetn_have_handled = 0;
            resetn_have_received = 1;
            init_PC = 1;

            // TODO: 寄存器清空操作
            last_PC = 0;
            last_last_PC = 0;
            mem_load = 0;
            reg_debug_wb_rf_wen = 0;
            reg_debug_wb_rf_wnum = 0;
            reg_debug_wb_rf_wdata = 0;
            old_rt = 0;
            //last_inst_sram_en = 0;

            registers[0]=0; registers[1]=0; registers[2]=0; registers[3]=0;
            registers[4]=0; registers[5]=0; registers[6]=0; registers[7]=0;
            registers[8]=0; registers[9]=0; registers[10]=0; registers[11]=0;
            registers[12]=0; registers[13]=0; registers[14]=0; registers[15]=0;
            registers[16]=0; registers[17]=0; registers[18]=0; registers[19]=0;
            registers[20]=0; registers[21]=0; registers[22]=0; registers[23]=0;
            registers[24]=0; registers[25]=0; registers[26]=0; registers[27]=0;
            registers[28]=0; registers[29]=0; registers[30]=0; registers[31]=0;
        end 
        
    /*
        时序：
        收到 resetn 后，先将 resetn_have_handled 拉低，
        将 resetn_have_received 拉高
        然后下一拍将 resetn_have_handled 拉高
    */
    end

    // reg last_inst_sram_en;
    /*initial begin
        last_inst_sram_en = 0;
    end*/

    /*always @(posedge clk ) begin
        last_inst_sram_en = inst_sram_en;
    end*/

    // 读取指令
    assign inst_sram_en = resetn_have_received | resetn_have_handled;
    //wire[31:0]  inst = inst_sram_rdata | 0;
    wire[31:0] inst = (inst_sram_en)? inst_sram_rdata : 0;
    
    assign inst_sram_addr = PC;
    (*mark_debug="true"*)reg[31:0]   last_PC; // 上一条指令的 PC 地址
    reg[31:0]   last_last_PC;
    wire[31:0]  NPC = last_PC + 4;
    // TODO: 把这里的 assign 改成 reg 变量，并在时钟上升沿更新
    assign PC = 0 | 
        (init_PC==1)? 0:
        (
        // 按照指令读取下一条指令地址
        // jmp 指令
        (op==6'b000010)? (NPC[31:28] + inst[15:0]<<2):
        // bbt
        (op==6'b111111)? (
            (base_value[bit]==1)? (offset<<2) + NPC: NPC
        ):
        NPC
    );

    // 寄存器组
    reg[31:0]   registers[31:0];
    integer i;
    initial begin
        for (i=0; i<32; i=i+1) begin
            registers[i] = 0;
        end
    end

    wire[31:0]  rs_value = (mem_load&&rs==old_rt)? data_sram_rdata: registers[rs];
    wire[31:0]  rt_value = (mem_load&&rt==old_rt)? data_sram_rdata: registers[rt];
    wire[31:0]  base_value = rs_value;

    // 指令译码
    wire[5:0]   card;
    (*mark_debug="true"*)wire[5:0]   op;
    wire[11:0]  op2;
    wire[4:0]   sa;
    wire[4:0]   rs, rt, rd;
    wire[4:0]   base = rs;
    assign op = inst[31:26];
    assign rs = inst[25:21];
    assign rt = inst[20:16];
    assign rd = inst[15:11];
    assign op2 = inst[10:0];
    assign sa = inst[10:6];
    assign card = 
        (op2==11'b00000_100000)? `ADD:
        (op2==11'b00000_100010)? `ASUBB:
        (op2==11'b00000_100100)? `AND:
        (op2==11'b00000_100101)? `OR:
        (op2==11'b00000_100110)? `XOR:
        (op2==11'b00000_001010)? `MOVZ:
        (inst[31:21]==0&&inst[5:0]==0)? `SIL:
        (op == 6'b111110 && op2 == 11'b00000_000000)? `CMP:
        0
    ;
    wire[15:0]  offset = inst[15:0];
    wire[4:0]   bit = inst[20:16];

    wire[31:0]  alu_reg_write_val;

    // 连接 ALU
    ALU ALU(
        .en(1),
        .rs_value(rs_value),
        .rt_value(rt_value),
        .card(card),
        .sa(sa),
        .en_reg_write(alu_en_write),
        .rd_value(alu_reg_write_val)
    );

    // 写寄存器
    always @(posedge /*negedge*/ clk) begin
/*
        reg_debug_wb_rf_wen = (alu_en_write&&rd!=0); // | mem_load;
        // 将 ALU 的运算结果写回
        if (alu_en_write) begin
            if (rd == 0) begin

            end else begin
                registers[rd] = alu_reg_write_val;
                reg_debug_wb_rf_wnum = rd;
                reg_debug_wb_rf_wdata = alu_reg_write_val;
            end
        end
        
        // 将内存值写回寄存器
        if (mem_load) begin
            if (alu_en_write && rd==old_rt) begin 
                // 如果读内存写入的寄存器和运算写入的寄存器是同一个
                // 则不将读内存的值写入寄存器
                // 例如语句如下
                // load r3, 4(r0)
                // add  r3, r3, r1
            end else begin 
                registers[old_rt] = data_sram_rdata;
            end
        end
*/
    end


    always @(posedge clk) begin 
        // 存储上一条指令地址
/*        if (resetn_have_handled) begin 
            last_last_PC = last_PC;
            last_PC = PC;
        end
        */
    end

    // 读内存
    reg         mem_load;
    reg[4:0]    old_rt;

    assign data_sram_en = op==6'b101011 || (op==6'b100011 && rt!=0);
    assign data_sram_wen = (op==6'b101011)? 7: 0;
    assign data_sram_addr = offset + 
        ((mem_load&&base==old_rt)? data_sram_rdata: registers[base])
    ;
    assign data_sram_wdata = (mem_load&&rt==old_rt)? data_sram_rdata: registers[rt];

    always @(posedge/*negedge*/ clk) begin
        // load
        /*
        if (op==6'b100011 && rt!=0) begin
            mem_load = 1;
            old_rt = rt;
        end else begin
            mem_load = 0;
        end
        */
    end



    reg         reg_debug_wb_rf_wen;
    reg[4:0]    reg_debug_wb_rf_wnum;
    reg[31:0]   reg_debug_wb_rf_wdata;

    // debug
    
    assign debug_wb_pc = last_last_PC;
    assign debug_wb_rf_wen = (reg_debug_wb_rf_wen | mem_load)|0;
    assign debug_wb_rf_wnum = ((mem_load)? old_rt: reg_debug_wb_rf_wnum)|0;
    assign debug_wb_rf_wdata = ((mem_load)? data_sram_rdata: reg_debug_wb_rf_wdata)|0;
    


endmodule

/* 
    读内存逻辑 load r4 8(r3)
    每一条读内存指令的上一条，要么是读内存指令，要么是其他指令
    如果是其他指令，那么读内存之前，寄存器 base 的值已经被写入到寄存器组中
    所以没有读写冲突
    
    在执行读内存指令时，第一个周期发送内存地址，第二个周期上升沿接受内存值
    理论上需要放到第一个指令的 rt 寄存器里，假设为 old_rt
    这时如果第二个指令需要读 rt 寄存器读，那么直接接受 data_sram_rdata，
    而不是从寄存器里读，因为此时寄存器的值是旧地址
    第二个周期下降沿写寄存器


*/

/*  
    debug 逻辑
    如果上一条指令是 load 指令，那么下一拍高触发把 debug_wb_rf_wen 拉高
    如果上一条是 alu 指令，那么下一拍把 debug_wb_rf_wen 拉高
    假设以下指令
    0x00    load r3, 4(r0)
    0x04    add  r4, r1, r2
    0x08    load r1, 4(r3)
    第一个上升沿发送 0x00 指令地址
    第二个上升沿发送 0x04 指令地址，发送 4(r0) 内存地址
    第三个上升沿发送 0x08 指令地址，
        收到 4(r0) 地址的内存数据，拉高 debug_wb_rf_wen
        发送 data_ram_rdata 到 debug_wb_rf_wdata

        收到 0x04 指令，下降沿运算 r4，并把 r4 结果暂存
    第四个上升沿发送 0x0c 指令地址，发送 4(r3) 内存地址
        拉高 debug_wb_rf_wen
        发送 r4 结果 到 debug_wb_rf_wdata

*/