----------------------------------------------------------------------------------
-- Company:   Beijing Institute of Technology
-- Engineer:  Xiao Meng
-- 
-- Create Date: 2020/08/17 09:00:00
-- Design Name: 
-- Module Name: GMODA - Behavioral
-- Project Name: 
-- Target Devices: xc7z045-ffg900 or xc7z100-ffg900
-- Tool Versions: Vivado 2016.3
-- Description: 
-- GMSK 调制 模拟部分，要求输入为串行差分编码后数据，与时钟同步，跳频序列以当前跳频点
-- 输出为k相位调制信号，经过数字中频上变频，在本方案中数字中频等于射频
-- k为部分可调
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 1.ROM地址处理
-- 240MHz主时钟，4相位 拼接为960Msample
-- 符号速率4Msymbol 因此有240倍过采样，每相位60倍过采样
-- ROM数据按照每4采样作为一个地址存入
-- 2.时钟处理
-- 输入信号为每60时钟变化一次的比特流，对应4M符号速率。 此处输入应当与上一模块良好衔接
-- 输出信号为4相位
----------------------------------------------------------------------------------


LIBRARY ieee;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library UNISIM;


entity GMODA is
  Port (
    clk	 				:in   	std_logic;
	Din					:in		std_logic;
	Enin 				:in 	std_LOGIC;
	FHNum 				:in	 	std_logic_vector(7 downto 0);
	Enout 				:out 	std_logic;
	DoutP1 				:out 	std_logic_vector(13 downto 0);
	DoutP2 				:out 	std_logic_vector(13 downto 0);
	DoutP3 				:out 	std_logic_vector(13 downto 0);
	DoutP4 				:out 	std_logic_vector(13 downto 0)
   );
end GMODA;

architecture Behavioral of GMODA is
constant OverSample : integer := 60;
constant K 			: integer := 4 ; -- 4 Phases
signal Dreg 	: std_logic_vector( 4 downto 0):="00000";
signal PhaseBase: std_logic_vector( 1 downto 0):="00";
signal CntSym	: integer range 0 to OverSample-1:=0;
signal Add 		: std_logic_vector( 5+2+6-1 downto 0);-- L = 5 , PhaseBase = 2 , log_2(60) = 6;

signal PhaseInc : std_logic_vector(31 downto 0);
signal PhaseOff : std_logic_vector(31 downto 0);
Type LogicK is array (K-1 downto 0) of std_logic;
signal CAValid : LogicK;

signal FHNumReg : std_logic_vector(7 downto 0);
signal ENinD    : std_logic:='0';

constant BBWidth : integer := 13;
signal RomDout	: std_logic_vector( BBWidth*4*2-1 downto 0); -- 13(Bits)*4(Phases)*2(Cos&Sin) = 104 

Type 	sBB 	is array (K-1 downto 0) of std_logic_vector ( BBWidth-1 downto 0);--signal BaseBand
signal 	CosBB,SinBB : sBB;

Type    PhaseType  is array (K-1 downto 0) of std_logic_vector( 63 downto 0);
signal  PhaseTdata : PhaseType :=(others =>(others=>'0')); 

Type    CAType is array (K-1 Downto 0) of std_logic_vector(31 downto 0);
signal  CA : CAType;

Type    MulOutType is array(K-1 Downto 0) of std_logic_vector(12 downto 0);
signal  MulIOut,MulQOut : MulOutType;


COMPONENT TableRom
  PORT (
    clka 	: IN STD_LOGIC;
    addra 	: IN STD_LOGIC_VECTOR(BBWidth-1 DOWNTO 0);
    douta 	: OUT STD_LOGIC_VECTOR(BBWidth*4*2-1 DOWNTO 0)
  );
END COMPONENT;

COMPONENT DDS_DUC
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_phase_tvalid : IN STD_LOGIC;
    s_axis_phase_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;


COMPONENT MUL_DUC
  PORT (
    CLK : IN STD_LOGIC;
    A : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    B : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    P : OUT STD_LOGIC_VECTOR(12 DOWNTO 0)
  );
END COMPONENT;


begin

TR : TableRom
PORT MAP (
  clka 		=> clk,
  addra 	=> Add,
  douta 	=> RomDout-- H->L C4 C3 C2 C1 S4 S3 S2 S1 
);

Gen_DUC:
for i in 0 to  K-1 generate
DUC : DDS_DUC
  PORT MAP (
    aclk => clk,
    s_axis_phase_tvalid => ENIN,
    s_axis_phase_tdata  => PhaseTdata(i),
    m_axis_data_tvalid  => CAValid(i),
    m_axis_data_tdata   => CA(i)
  );
end generate;

Gen_MUL_I:
for i in 0 to  K-1 generate
MUL_I : MUL_DUC
  PORT MAP (
    CLK => CLK,
    A => CA(i)(11 downto 0),
    B => CosBB(i),
    P => MulIOut(i)
  );
end generate;

Gen_MUL_Q:
for i in 0 to  K-1 generate
MUL_Q : MUL_DUC
  PORT MAP (
    CLK => CLK,
    A => CA(i)(27 downto 16),
    B => SinBB(i),
    P => MulQOut(i)
  );
end generate;

Dreg(0) <= Din;
Add (5 downto 0) <= conv_std_logic_vector(CntSym,6);
Add (7 downto 6) <= PhaseBase;
Add(12 downto 8) <= Dreg;


SinBB(0) <= RomDout(0*13+13-1 downto 0*13);
SinBB(1) <= RomDout(1*13+13-1 downto 1*13);
SinBB(2) <= RomDout(2*13+13-1 downto 2*13);
SinBB(3) <= RomDout(3*13+13-1 downto 3*13);
CosBB(0) <= RomDout(4*13+13-1 downto 4*13);
CosBB(1) <= RomDout(5*13+13-1 downto 5*13);
CosBB(2) <= RomDout(6*13+13-1 downto 6*13);
CosBB(3) <= RomDout(7*13+13-1 downto 7*13);


process(clk)
begin
if clk'event and clk = '1' then
EninD <= Enin;
	if Enin ='1' then
	
		CntSym  			<= CntSym+1;
		if 		CntSym = 59 and Dreg(4) ='1' then
			PhaseBase 	<= PhaseBase +1;
			CntSym 		<= 0;
			Dreg(4 downto 1) 	<= Dreg(3 downto 0);
		elsif 	CntSym = 59 and Dreg(4) ='0' then
			PhaseBase <= PhaseBase -1;
			CntSym 		<= 0;
			Dreg(4 downto 1) 	<= Dreg(3 downto 0);
		end if;
	    if 	EninD = '0' then
	       FHNumReg  <= FHNum;
	    end if;
	else
	   FHNumReg <= x"FF";
	end if;
	
   case FHNumReg is
       when x"00" =>         PhaseInc <=X"68000000";  PhaseOff <=x"5A000000";
       when x"01" =>         PhaseInc <=X"6A222222";  PhaseOff <=x"5A888889";
       when x"02" =>         PhaseInc <=X"6C444444";  PhaseOff <=x"5B111111";
       when x"03" =>         PhaseInc <=X"6E666666";  PhaseOff <=x"5B99999A";
       when others =>         PhaseInc <=(Others =>'0'); PhaseOff <=(Others =>'0');
    end case;

for i in 0 to 3 loop
    PhaseTdata(i)(31 downto 0) <= PhaseInc;
end loop;
for i in 1 to 3 loop
    PhaseTdata(i)(63 downto 32) <= PhaseTdata(i-1)(63 downto 32)+PhaseOff;
end loop;

end if;


   
   
end process;



end Behavioral;
