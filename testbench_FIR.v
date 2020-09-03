`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/09/01 10:38:02
// Design Name: 
// Module Name: testbench_FIR
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench_FIR(

    );
	reg clk = 0;
	wire data_en = 0;
	integer fp_r,fp_w;  
	reg[15:0] count=0;
	reg[89:0] reg1[4999:0];
	reg[89:0] reg2;
	reg [239:0] data_out;
	wire[239:0] data_out_1;
	initial  
	begin 	
		//$readmemh("F:/vivado files/FIR10/sin2add_tst.txt",reg1,0,4999);
		reg2 = 0;
		count = 0;
		fp_r=$fopen("F:/vivado files/FIR10/sin2add_tst.txt","r");//以读的方式打开文件  
		fp_w=$fopen("F:/vivado files/FIR10/data_out.txt","w");//以写的方式打开文件  
	end 
	
	always #5 clk = ~clk;
	FIR_10 FIR_10
	( 
		.clk		(clk), 	
		.data_in 	(reg2),
		.data_out	(data_out_1),
		.data_en 	(data_en )
	);
	
	always@(posedge clk)
	begin
		data_out = data_out_1;
		if(count < 5000)
		begin
			//每次读一行 
			$fscanf(fp_r,"%d" ,reg2) ;
			//reg2 <= reg1[count];
			count <= count + 1; 
			$fwrite(fp_w,"%x\n",data_out) ;//写入文件
		end
		else
		begin
			$fclose(fp_r);//关闭已打开的文件
			$fclose(fp_w);
		end  
	end
	
endmodule
