----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Matthew Webster
-- 
-- Create Date:    14:06:08 03/03/2017 
-- Design Name: 
-- Module Name:    MathFunct - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Code to take the ADC inputs,calibrate them, and perform a FFT on the
--              Calibrated Values.
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MathFunct is port( 
	clk_50 : in std_logic; 
	pushbuttons : in  std_logic_vector (3 downto 0);   
--------------------ports for RAM interface on NEXYS 3--------------------------------------------------------------

   RAM_Adr : inout std_logic_vector (25 downto 0);    --(25 downto 0); 	-- Address -- was out before inout
   RAMAdv  : out std_logic; 								   -- Address Valid
   RAMClk  : out std_logic; 								   -- RAM clock
   RAMCre   : out std_logic; 								   -- 
   RAM_LB	: out std_logic; 								   -- Lower Byte
   RAM_UB	: out std_logic; 								   -- Upper Byte
   RAM_data	: inout std_logic_vector (15 downto 0);	-- Bidirectional data   inout
   RAM_OE	: out std_logic;								   -- Output Enable
   RAM_WE	: out std_logic;								   -- Write Enable
   RAM_CE	: out std_logic;								   -- Chep Enable
--------------------------------------------------------------------------------------------------------------------
-- REMINDER: Gonna need ports for interface with ADC inputs-----------------------
	ready : in std_logic; -- lets the code know the input values are done uploading
	data1 : in std_logic_vector(11 downto 0);
	data2 : in std_logic_vector(11 downto 0));
--REMINDER: Gonna need ports for interface with the VGA code----------------------

end MathFunct;
architecture Behavioral of MathFunct is
-------------------------ARRAY TYPES for basis functions, data and anticipated computations
--Set up different array types needed
type array_type_basis is array(0 to 15) of signed(15 downto 0);
type basis is array(0 to 15) of array_type_basis; -- 2D array 16x16 
-- above is from.bin file which has to be 16 bits from matlab
type array_type_data is array(0 to 15) of signed(11 downto 0);
--above is becausue A/D converter is 12 bits when added
type array_type_cal_product is array(0 to 15) of signed(23 downto 0); 
--above is for mult two 12bit data numbers then add for 12+12+1=25 bits
type array_type_final_product is array(0 to 15) of signed (39 downto 0);  
-- above is mult 25bit(cal_product)*16bit(basisfunctions) then 32(16 real and 16 imag) adds is 25+16+16=57 bits
--16 since keep real and imag seperate. Will need to do squaring though since will have neg number results
type array_type_temp_AtD is array(0 to 15) of std_logic_vector(11 downto 0);
--------------------------------------------------------------------------------
-- Array type for state machine--------------
type state_num is (zero, one, two, three, four, five, six); 
----------------------------------------------

----------------------------ARRAY SIGNALS
-- have seperate array for each of 16, could combine and be one 256 element array for each
	signal cos : basis;
	signal sin : basis;

	signal Id,Qd,Icd,Qcd: array_type_data;

	signal IcalProduct, QcalProduct, CalAmplitude: array_type_cal_product;

	signal FinalProduct: array_type_final_product ;
	signal Iaccume0,Iaccume1,Iaccume2,Iaccume3,Iaccume4,Iaccume5,Iaccume6,Iaccume7 : array_type_final_product ;
	signal Iaccume8,Iaccume9,Iaccume10,Iaccume11,Iaccume12,Iaccume13,Iaccume14,Iaccume15 : array_type_final_product ;

	signal AD_Id, AD_Qd, AD_Icd, AD_Qcd: array_type_temp_AtD ;
	signal a : signed (56 downto 0);
	signal index1 : integer range 0 to 16;
	signal index2 : integer range 0 to 16;
	signal inc : integer range 0 to 16;
	signal math1 : unsigned (15 downto 0) ; 
	signal cntr1 : unsigned (12 downto 0) ;
	signal cntr2 : unsigned (12 downto 0) ;
	signal syncr1 : std_logic;----synchronous reset 
	signal addrCount : unsigned (14 downto 0) ; -- plenty of bits
	signal SampleRate : std_logic;  -----
 	signal RAM_Addr_A : unsigned(23 downto 1);

	signal state : state_num := one;

begin

-- OK here's the plan: 
-- State1 - Upload basis functions into the arrays
--        - Dont start uploading until we have all of our input data from the ADC
-- State2 - Upload sin basis functions into arrays
-- State3 - Convert input values to signed
-- State4 - calibrate the ADC values 
-- State4 - Multiply calibrated data with basis functions
-- State5 - calculate accumulated data
-- State6 - sum up final product
--        - send product to VGA code
--        - Keep at State5 until its time to do another scan 

Process(clk_50,Qd,SampleRate,state,AD_Id,AD_Qd,AD_Icd,AD_Qcd,Id,Icd,Qcd,IcalProduct,cos,sin,QcalProduct,ready,Iaccume8,Iaccume9,Iaccume10,Iaccume11,Iaccume12,Iaccume13,Iaccume14,Iaccume15,Iaccume0,Iaccume1,Iaccume2,Iaccume3,Iaccume4,Iaccume5,Iaccume6,Iaccume7,inc,data1,data2,FinalProduct)
begin
case state is
	when zero =>                       -- Upload input data into our arrays Id and Qd
		if(ready = '1') then
			if(inc < 16) then
				AD_Id(inc) <= data1;
				AD_Qd(inc) <= data2;
				inc <= inc + 1;
				state <= zero;
			else                         -- Arrays are full
				inc <= 0;                 -- reset inc
				state <= one;         -- move on to state one. Values from the ADC are no longer being uploaded.
			end if;
		end if;
	
	when one =>
		if SampleRate='1' then
			if (rising_edge (clk_50)) then 
				cos(index2)(index1)<=signed(ram_data) ; -- start filling cos values
				if (index1 < 15) then
					index1 <= index1 + 1;
					state <= one;
				else
					index2 <= index2 + 1;
					index1 <= 0;
					if(index2 > 15) then
						index2 <= 0;
						state <= two;
					else
						state <= one;
					end if;
				end if;
			end if;
		end if;

	when two =>
		if SampleRate='1' then
			if (rising_edge (clk_50)) then 
				sin(index2)(index1)<=signed(ram_data) ; -- start filling sin values
				if (index1 < 15) then
					index1 <= index1 + 1;
					state <= two;
				else
					index2 <= index2 + 1;
					index1 <= 0;
					if(index2 > 15) then
						state <= three;
					else 
						state <= two;
					end if;
				end if;
			end if;
		end if;
	
	when three =>  -- convert input data to signed for math computations
	For i in 15 downto 0 loop
		Id(15-i)<=signed(AD_Id(15-i));   
		Qd(15-i)<=signed(AD_Qd(15-i));
		Icd(15-i)<=signed(AD_Icd(15-i)); 
		Qcd(15-i)<=signed(AD_Qcd(15-i));
		if(i = 0) then
			state <= four;
		else 
			state <= three;
		end if;
	end loop;
	
	when four =>  -- Calibrate input data
	For i in 15 downto 0 loop  -- Remember were gonna have to divide by a multiple of 2 
		IcalProduct(15-i)<=((Icd(15-i)*Id(15-i))+(Qcd(15-i)*Qd(15-i))); -- /(Icd(15-i)*Icd(15-i) + Qcd(15-i)*Qcd(15-i));
		QcalProduct(15-i)<=(Qd(15-i)*Icd(15-i)- Id(15-i)*Qcd(15-i)); -- /(Icd(15-i)*Icd(15-i) + Qcd(15-i)*Qcd(15-i));
		if(i = 0) then
			state <= five;
		else 
			state <= four;
		end if;
	end loop;
	
	when five =>  -- multiply calibrated data by basis functions
	For i in 15 downto 0 loop 
		Iaccume0(15-i)<= cos(0)(15-i)*IcalProduct(15-i)+sin(0)(15-i)*QcalProduct(15-i);
		Iaccume1(15-i)<= cos(1)(15-i)*IcalProduct(15-i)+sin(1)(15-i)*QcalProduct(15-i);
		Iaccume2(15-i)<= cos(2)(15-i)*IcalProduct(15-i)+sin(2)(15-i)*QcalProduct(15-i);
		Iaccume3(15-i)<= cos(3)(15-i)*IcalProduct(15-i)+sin(3)(15-i)*QcalProduct(15-i);
		Iaccume4(15-i)<= cos(4)(15-i)*IcalProduct(15-i)+sin(4)(15-i)*QcalProduct(15-i);
		Iaccume5(15-i)<= cos(5)(15-i)*IcalProduct(15-i)+sin(5)(15-i)*QcalProduct(15-i);
		Iaccume6(15-i)<= cos(6)(15-i)*IcalProduct(15-i)+sin(6)(15-i)*QcalProduct(15-i);
		Iaccume7(15-i)<= cos(7)(15-i)*IcalProduct(15-i)+sin(7)(15-i)*QcalProduct(15-i);
		Iaccume8(15-i)<= cos(8)(15-i)*IcalProduct(15-i)+sin(8)(15-i)*QcalProduct(15-i);
		Iaccume9(15-i)<= cos(9)(15-i)*IcalProduct(15-i)+sin(9)(15-i)*QcalProduct(15-i);
		Iaccume10(15-i)<= cos(10)(15-i)*IcalProduct(15-i)+sin(10)(15-i)*QcalProduct(15-i);
		Iaccume11(15-i)<= cos(11)(15-i)*IcalProduct(15-i)+sin(11)(15-i)*QcalProduct(15-i);
		Iaccume12(15-i)<= cos(12)(15-i)*IcalProduct(15-i)+sin(12)(15-i)*QcalProduct(15-i);
		Iaccume13(15-i)<= cos(13)(15-i)*IcalProduct(15-i)+sin(13)(15-i)*QcalProduct(15-i);
		Iaccume14(15-i)<= cos(14)(15-i)*IcalProduct(15-i)+sin(14)(15-i)*QcalProduct(15-i);
		Iaccume15(15-i)<= cos(15)(15-i)*IcalProduct(15-i)+sin(15)(15-i)*QcalProduct(15-i);
		if(i = 15) then
			state <= six;
		else
			state <= five;
		end if;
	end loop;
	
	when OTHERS => -- sum up the multiples for each basis function
	FinalProduct(0)<= (Iaccume0(0)+Iaccume0(1)+Iaccume0(2)+Iaccume0(3)+Iaccume0(4)+Iaccume0(5)+Iaccume0(6)+Iaccume0(7)+ Iaccume0(8)+Iaccume0(9)+Iaccume0(10)+Iaccume0(11)+Iaccume0(12)+Iaccume0(13)+Iaccume0(14)+Iaccume0(15));
	FinalProduct(1)<= (Iaccume1(0)+Iaccume1(1)+Iaccume1(2)+Iaccume1(3)+Iaccume1(4)+Iaccume1(5)+Iaccume1(6)+Iaccume1(7)+ Iaccume1(8)+Iaccume1(9)+Iaccume1(10)+Iaccume1(11)+Iaccume1(12)+Iaccume1(13)+Iaccume1(14)+Iaccume1(15));
	FinalProduct(2)<= (Iaccume2(0)+Iaccume2(1)+Iaccume2(2)+Iaccume2(3)+Iaccume2(4)+Iaccume2(5)+Iaccume2(6)+Iaccume2(7)+ Iaccume2(8)+Iaccume2(9)+Iaccume2(10)+Iaccume2(11)+Iaccume2(12)+Iaccume2(13)+Iaccume2(14)+Iaccume2(15));
	FinalProduct(3)<= (Iaccume3(0)+Iaccume3(1)+Iaccume3(2)+Iaccume3(3)+Iaccume3(4)+Iaccume3(5)+Iaccume3(6)+Iaccume3(7)+ Iaccume3(8)+Iaccume3(9)+Iaccume3(10)+Iaccume3(11)+Iaccume3(12)+Iaccume3(13)+Iaccume3(14)+Iaccume3(15));
	FinalProduct(4)<= (Iaccume4(0)+Iaccume4(1)+Iaccume4(2)+Iaccume4(3)+Iaccume4(4)+Iaccume4(5)+Iaccume4(6)+Iaccume4(7)+ Iaccume4(8)+Iaccume4(9)+Iaccume4(10)+Iaccume4(11)+Iaccume4(12)+Iaccume4(13)+Iaccume4(14)+Iaccume4(15));
	FinalProduct(5)<= (Iaccume5(0)+Iaccume5(1)+Iaccume5(2)+Iaccume5(3)+Iaccume5(4)+Iaccume5(5)+Iaccume5(6)+Iaccume5(7)+ Iaccume5(8)+Iaccume5(9)+Iaccume5(10)+Iaccume5(11)+Iaccume5(12)+Iaccume5(13)+Iaccume5(14)+Iaccume5(15));
	FinalProduct(6)<= (Iaccume6(0)+Iaccume6(1)+Iaccume6(2)+Iaccume6(3)+Iaccume6(4)+Iaccume6(5)+Iaccume6(6)+Iaccume6(7)+ Iaccume6(8)+Iaccume6(9)+Iaccume6(10)+Iaccume6(11)+Iaccume6(12)+Iaccume6(13)+Iaccume6(14)+Iaccume6(15));
	FinalProduct(7)<= (Iaccume7(0)+Iaccume7(1)+Iaccume7(2)+Iaccume7(3)+Iaccume7(4)+Iaccume7(5)+Iaccume7(6)+Iaccume7(7)+ Iaccume7(8)+Iaccume7(9)+Iaccume7(10)+Iaccume7(11)+Iaccume7(12)+Iaccume7(13)+Iaccume7(14)+Iaccume7(15));
	FinalProduct(8)<= (Iaccume8(0)+Iaccume8(1)+Iaccume8(2)+Iaccume8(3)+Iaccume8(4)+Iaccume8(5)+Iaccume8(6)+Iaccume8(7)+ Iaccume8(8)+Iaccume8(9)+Iaccume8(10)+Iaccume8(11)+Iaccume8(12)+Iaccume8(13)+Iaccume8(14)+Iaccume8(15));
	FinalProduct(9)<= (Iaccume9(0)+Iaccume9(1)+Iaccume9(2)+Iaccume9(3)+Iaccume9(4)+Iaccume9(5)+Iaccume9(6)+Iaccume9(7)+ Iaccume9(8)+Iaccume9(9)+Iaccume9(10)+Iaccume9(11)+Iaccume9(12)+Iaccume9(13)+Iaccume9(14)+Iaccume9(15));
	FinalProduct(10)<= (Iaccume10(0)+Iaccume10(1)+Iaccume10(2)+Iaccume10(3)+Iaccume10(4)+Iaccume10(5)+Iaccume10(6)+Iaccume10(7)+ Iaccume10(8)+Iaccume10(9)+Iaccume10(10)+Iaccume10(11)+Iaccume10(12)+Iaccume10(13)+Iaccume10(14)+Iaccume10(15));
	FinalProduct(11)<= (Iaccume11(0)+Iaccume11(1)+Iaccume11(2)+Iaccume11(3)+Iaccume11(4)+Iaccume11(5)+Iaccume11(6)+Iaccume11(7)+ Iaccume11(8)+Iaccume11(9)+Iaccume11(10)+Iaccume11(11)+Iaccume11(12)+Iaccume11(13)+Iaccume11(14)+Iaccume11(15));
	FinalProduct(12)<= (Iaccume12(0)+Iaccume12(1)+Iaccume12(2)+Iaccume12(3)+Iaccume12(4)+Iaccume12(5)+Iaccume12(6)+Iaccume12(7)+ Iaccume12(8)+Iaccume12(9)+Iaccume12(10)+Iaccume12(11)+Iaccume12(12)+Iaccume12(13)+Iaccume12(14)+Iaccume12(15));
	FinalProduct(13)<= (Iaccume13(0)+Iaccume13(1)+Iaccume13(2)+Iaccume13(3)+Iaccume13(4)+Iaccume13(5)+Iaccume13(6)+Iaccume13(7)+ Iaccume13(8)+Iaccume13(9)+Iaccume13(10)+Iaccume13(11)+Iaccume13(12)+Iaccume13(13)+Iaccume13(14)+Iaccume13(15));
	FinalProduct(14)<= (Iaccume14(0)+Iaccume14(1)+Iaccume14(2)+Iaccume14(3)+Iaccume14(4)+Iaccume14(5)+Iaccume14(6)+Iaccume14(7)+ Iaccume14(8)+Iaccume14(9)+Iaccume14(10)+Iaccume14(11)+Iaccume14(12)+Iaccume14(13)+Iaccume14(14)+Iaccume14(15));
	FinalProduct(15)<= (Iaccume15(0)+Iaccume15(1)+Iaccume15(2)+Iaccume15(3)+Iaccume15(4)+Iaccume15(5)+Iaccume15(6)+Iaccume15(7)+ Iaccume15(8)+Iaccume15(9)+Iaccume15(10)+Iaccume15(11)+Iaccume15(12)+Iaccume15(13)+Iaccume15(14)+Iaccume15(15));
	if (ready = '0') then
		state <= zero; 
	else
		state <= six;
	end if;

	end case;
end Process;
		



--generate the Read Pulse pulse counter with synchrnous counter that counts greater
-- than min access time of 70nS
process(clk_50,pushbuttons(0))
begin
 if ((pushbuttons(0)='1')) then   
  cntr1<=(others=>'0');
   elsif ( rising_edge(clk_50)) then
    if (syncr1='1') then
		cntr1<=(others=>'0');
	 else  
		cntr1<=cntr1+1;
	 end if;
 end if;
end process;
 
syncr1<='1' when (cntr1= 10) else '0';  -- need at least 7 clocks, cntr1=7 to meet meet SRAM min access time of 70 nS
                                        -- with 100 MHz clock, 10 counts is 100 nS. Should be plenty of time
 
SampleRate<=syncr1;  
  
-----------generate counter value that scrolls addresses at sample rate
process (clk_50, pushbuttons(0))
begin
	if ((pushbuttons(0)='1')) then
		addrCount <= (others=>'0');
	elsif (rising_edge (clk_50)) then 
		if SampleRate='1' then
			AddrCount<=AddrCount + 1;
		end if;
	end if;
end process;	
	

RAM_adr(25 downto 0) <= "00000000000"& std_logic_vector(addrcount) ;


-- Since AtoD signal not available make a signal that is hardwired with values for now
-- all 1s to make math easier to verify
--Temporary data that represents the cal AtoD inputs

AD_Icd(0)<="000000000001"; 
AD_Icd(1)<="000000000001";
AD_Icd(2)<="000000000001";
AD_Icd(3)<="000000000001";
AD_Icd(4)<="000000000001";
AD_Icd(5)<="000000000001";
AD_Icd(6)<="000000000001";
AD_Icd(7)<="000000000001";
AD_Icd(8)<="000000000001";
AD_Icd(9)<="000000000001";
AD_Icd(10)<="000000000001";
AD_Icd(11)<="000000000001";
AD_Icd(12)<="000000000001";
AD_Icd(13)<="000000000001";
AD_Icd(14)<="000000000001";
AD_Icd(15)<="000000000001";


AD_Qcd(0)<="000000000001";
AD_Qcd(1)<="000000000001";
AD_Qcd(2)<="000000000001";
AD_Qcd(3)<="000000000001";
AD_Qcd(4)<="000000000001";
AD_Qcd(5)<="000000000001";
AD_Qcd(6)<="000000000001";
AD_Qcd(7)<="000000000001";
AD_Qcd(8)<="000000000001";
AD_Qcd(9)<="000000000001";
AD_Qcd(10)<="000000000001";
AD_Qcd(11)<="000000000001";
AD_Qcd(12)<="000000000001";
AD_Qcd(13)<="000000000001";
AD_Qcd(14)<="000000000001";
AD_Qcd(15)<="000000000001";


-- process to sum numbers in array in for loop. Did not work as seen on 7seg display. Should be easy? 
--process(Iaccume)
--begin
--if addrcount=32767 then
--for i in 15 downto 0 loop
--a<=a+Iaccume(15-i);
--end loop;
--end if;
--FinalProduct(0)<=a;
--end process;

-- RAM_data <=(others=>'Z'); -- what is this??

end Behavioral;

