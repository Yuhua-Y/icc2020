module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output reg match;
output [4:0] match_index;
output  valid;
////////////////////////////////////////////////////////////////
reg [3:0]cur_state,next_state;
parameter IDLE=4'd0,STRING=4'd1,PATTERN=4'd2,STR_MATCH=4'd3,PAT_MATCH=4'd4,OUT=4'd5;
parameter wbeg=8'h5E,wend=8'h24,wany=8'h2E;

reg true;
reg new_str;
reg [31:0]vec_beg;
reg [5:0]strm_counter,patm_counter;
reg [5:0]string_counter,pattern_counter;
reg [7:0]string_data[31:0];
reg [7:0]pattern_data[31:0];
reg fir_match,match_finish2;
reg [5:0]string_number;

wire is_str,is_pat;
wire match_finish1;
//integer i;
////////////////////////////////////////////////////////////////
assign is_str=isstring;
assign is_pat=ispattern;
assign valid=(cur_state==OUT)?1:0;
assign match_finish1=((cur_state==STR_MATCH)&(strm_counter==string_number))?1:0;
//assign match_finish2=((cur_state==PAT_MATCH)&(patm_counter==pattern_counter-1))?1:0;
//assign match=true;
assign match_index=strm_counter-1;//?

always @(posedge clk) begin
    match<=true;
end

//match_finish2
always @(*) begin
    if(cur_state==PAT_MATCH)begin
       if((patm_counter==pattern_counter-1)&(true))//-1
            match_finish2=1;
        else
            match_finish2=0;
    end
    else
        match_finish2=0;
end


//fir_match
always @(*) begin
    if(cur_state==STR_MATCH)begin
        if(string_data[strm_counter]==pattern_data[0])
            fir_match=1;
        else if(pattern_data[0]==wany)
            fir_match=1;
        else if(((string_data[strm_counter]==pattern_data[1])|(pattern_data[1]==wany))&(pattern_data[0]==wbeg)&((strm_counter==0)|(string_data[strm_counter-1]==8'h20)))
            fir_match=1;
        else
            fir_match=0;
    end
    else
        fir_match=0;
end

always @(posedge clk or posedge reset) begin
    if(reset)
        cur_state<=IDLE;
    else
        cur_state<=next_state;
end

always @(*) begin
    case (cur_state)
        IDLE:next_state=STRING;
        STRING:next_state=(is_str)?STRING:PATTERN;
        PATTERN:next_state=(ispattern)?PATTERN:STR_MATCH;
        STR_MATCH:begin
            if(match_finish1)
                next_state=OUT;
            else if(fir_match)
                next_state=PAT_MATCH;
            else
                next_state=STR_MATCH;
        end
        PAT_MATCH:begin
            if((true)|(patm_counter==0))begin
                if(match_finish2)
                    next_state=OUT;
                else 
                    next_state=PAT_MATCH;
            end
            else
            next_state=STR_MATCH;
        end
        OUT:next_state=(is_str)?STRING:PATTERN;
        default: next_state=IDLE;
    endcase    
end

always @(posedge clk) begin
    if(ispattern)
        new_str<=1;
    else if(is_str)
        new_str<=0;
end

//string_counter ??go back to zero
always @(posedge clk or posedge reset) begin
    if(reset)
        string_counter<=0;
    else if(is_str)
       string_counter<=string_counter+1;
    else 
        string_counter<=0;
end

always @(posedge clk or posedge reset) begin
    if(reset)
        string_number<=0;
    else if(is_str)
        string_number<=string_counter+1;
end

//pattern_counter
always @(posedge clk or posedge reset) begin
    if(reset)
        pattern_counter<=0;
    else if(ispattern)
        pattern_counter<=pattern_counter+1;
    else if(match_finish2|match_finish1)
        pattern_counter<=0;
end

//string_data
always @(posedge clk) begin
    if(is_str)
        string_data[string_counter]<=chardata;
end

//pattern_data
always @(posedge clk) begin
    if(is_pat)
        pattern_data[pattern_counter]<=chardata;
    //else if(match_finish1|match_finish2)
    //    for(i=0; i<pattern_counter; i++)
        
end

//strm_counter
always @(posedge clk or posedge reset) begin
    if(reset)
        strm_counter<=0;
    else if(cur_state==STR_MATCH)
        strm_counter<=strm_counter+1;
    else if(cur_state==OUT)
        strm_counter<=0;
end

//patm_counter
always @(posedge clk or posedge reset) begin
    if(reset)
        patm_counter<=0;
    else if(cur_state==PAT_MATCH)begin
        
        patm_counter<=patm_counter+1;
    end
    else
        patm_counter<=0;
end

always @(*) begin
    if(reset)
        true=0;
    else if(cur_state==PAT_MATCH)begin
        if(string_data[patm_counter+strm_counter-1]==pattern_data[patm_counter])
            true=1;
        else if(pattern_data[patm_counter]==wany)
            true=1;
        else if(pattern_data[0]==wbeg)begin
            if(patm_counter==0)
                true=1;
            else if(((string_data[strm_counter-2]==8'h20)|(strm_counter==1))&((string_data[patm_counter+strm_counter-2]==pattern_data[patm_counter])|(pattern_data[patm_counter]==wany)))
                true=1;
            else if((pattern_data[patm_counter]==wend)&((string_data[patm_counter+strm_counter-2]==8'h20)|(strm_counter==string_number-pattern_counter+3)))
                true=1;
            else
                true=0;
        end    
        else if((pattern_data[patm_counter]==wend)&((strm_counter==string_number-pattern_counter+2)|(string_data[patm_counter+strm_counter-1]==8'h20)))
            true=1;
        else
            true=0;
    end
    else //if(cur_state==OUT)
        true=0;
end


endmodule
