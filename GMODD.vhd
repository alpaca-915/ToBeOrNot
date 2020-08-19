----------------------------------------------------------------------------------
-- Company:   Beijing Institute of Technology
-- Engineer:  Xiao Meng
-- 
-- Create Date: 2020/08/19 09:04:55
-- Design Name: 
-- Module Name: GMODA - Behavioral
-- Project Name: 
-- Target Devices: xc7z045-ffg900 or xc7z100-ffg900
-- Tool Versions: Vivado 2016.3
-- Description: 
-- GMSK�������ֲ��֣�Ҫ�����������ݣ����ȷ��Ϲ�񣬰���ʹ�ܣ�������������ͬ��ͷ������ʹ�ܡ�
--���Ϊ�������ݣ����ȸ�ʽ���Ϲ��--
-- 2 PA + 24 COR + 446 DT + 2 PHASE SYNC + 4 ZEROS + 24COR + 2PA
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- �������ݷ�Ϊ�������˿ڣ����ݶ˿�ʵ�������ؼ��Ӽ�����ģʽ����⵽�����غ�ʼ�������ݣ����ݲ��������棬ʹ��1С��32λ����λ�Ĵ������л���
-- ʹ��PCNT������λ�ۼӣ��Լ���2��PHASE SYNC��ֵ
----------------------------------------------------------------------------------


LIBRARY ieee;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
library UNISIM;

entity GMODD is
Port (
clk         : in    std_logic;
DTIn        : in    std_logic;
ENIn        : in    std_logic;
ENCor       : in    std_logic;
DCorH       : in    std_logic_vector(23 downto 0);
DCorT       : in    std_logic_vector(23 downto 0);
DOut        : out   std_logic;
ENOut       : out   std_logic
 );
end GMODD;

architecture Behavioral of GMODD is
Constant LData : integer :=446;
Constant LCor  : integer :=24;


signal ENInD : std_logic;
signal CodeFlag : std_logic;
signal CorHReg,CorTReg: std_logic_vector(23 downto 0);
signal ShiftReg : std_logic_vector(31 downto 0);
signal CNT : integer range 0 to 511:=0; 
signal DoutReg : std_logic;
begin


process(clk)
begin
if clk'event and clk = '1' then
    ENInD<= ENIn;
    if ENIn    = '1' and ENInD = '0' then
        ShiftReg(31 downto 1) <= ShiftReg(30 downto 0);
        ShiftReg(0) <= DTIn;
        CodeFlag    <= '1';
        CNT         <=  0;
    elsif CodeFlag = '1' then
        ShiftReg(31 downto 1)   <=  ShiftReg(30 downto 0);
        ShiftReg(0)             <=  DTIn;
        CNT                     <=  CNT +1;
        ENOut                   <=  '1';
        if      CNT <=  1  then
            DoutReg <= '0';
        elsif   CNT <=  1+LCor then
            DoutReg <= DoutReg xor CorHReg(Cnt-2);
        elsif   CNT <= 1+LCor+LData then
            DoutReg <= DoutReg xor ShiftReg(LCor+2);
        elsif   CNT = 1+LCor+LData+LCor+2 then--------
            DoutReg <= DoutReg xor ShiftReg(LCor+2);-------
            CodeFlag <= '0';
        end if;
    end if;
    if ENCor   = '1' then
        CorHReg <= DCorH;
        CorTReg <= DCorT;
    end if;
end if;
end process;
end Behavioral;
