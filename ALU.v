`include "macro.vh"

module ALU(
    input       en,
    input[31:0] rs_value,
    input[31:0] rt_value,
    input[4:0] card,
    input[4:0]  sa,
    output      en_reg_write,
    output[31:0]rd_value
);
    wire[31:0]  cmp_value;


    assign cmp_value[0] = (rs_value==rt_value)? 1: 0;
    // TODO: test
    assign cmp_value[1] = (rs_value<rt_value) ^ (rs_value[31]^rt_value[31]);
    assign cmp_value[2] = rs_value<rt_value;
    // TODO: will (rs_value<=rt_value) regarded as giving value of rs_value to rt_value?
    assign cmp_value[3] = (rs_value<=rt_value) ^ (rs_value[31]^rt_value[31]);
    assign cmp_value[4] = rs_value<=rt_value;
    assign cmp_value[9:5] = ~cmp_value[4:0];
    assign cmp_value[31:10] = 0;

    assign rd_value = 
        en? (
            (card==`ADD)?   rs_value+rt_value:
            (card==`ASUBB)? rs_value-rt_value:
            (card==`AND)?   rs_value&rt_value:
            (card==`OR)?    rs_value|rt_value:
            (card==`XOR)?   rs_value^rt_value:
            (card==`MOVZ)?  (
                (rt_value==0)? rs_value: 0
            ):
            (card==`SIL)? (rt_value<<sa):
            (card==`CMP)? cmp_value: 0
        ): 
        0
    ;
    assign en_reg_write = 
        (
            (card==`MOVZ)?(
                rt_value==0? 1: 0
            ):
            (card==`ADD)?  1:
            (card==`ASUBB)? 1:
            (card==`AND)?  1:
            (card==`OR)?   1:
            (card==`XOR)?  1:
            (card==`SIL)?  1:
            (card==`CMP)?  1:
            0
        ) 
    ;
    

endmodule