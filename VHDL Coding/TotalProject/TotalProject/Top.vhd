----------------------------------------------------------------------------------
-- Company: FAMU-FSU College of Engineering
-- Engineer: Matthew Webster
-- 
-- Create Date:    02:47:44 02/08/2017 
-- Design Name: 
-- Module Name:    Top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Make sure were upload values to the SRAM and that we can access
--              these values. Just gonna upload the Basis functions and display them
--              on the 7 segment display. 
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

entity Top is port( 
	clk_50 : in std_logic; 
	pushbuttons : in  std_logic_vector (3 downto 0); 
	sliderswitches : in std_logic_vector (7 downto 0);
	seg7 : out std_logic_vector (6 downto 0); 
	an : out  std_logic_vector (3 downto 0);           --anodes for 7seg display       
--------------------ports for RAM interface on NEXYS 2, NEXYS 3 might be different

   RAM_Adr : inout std_logic_vector (25 downto 0);    --(25 downto 0); 	-- Address -- was out before inout
   RAMAdv  : out std_logic; 								   -- Address Valid
   RAMClk  : out std_logic; 								   -- RAM clock
   RAMCre   : out std_logic; 								   -- 
   RAM_LB	: out std_logic; 								   -- Lower Byte
   RAM_UB	: out std_logic; 								   -- Upper Byte
   RAM_data	: inout std_logic_vector (15 downto 0);	-- Bidirectional data   inout
   RAM_OE	: out std_logic;								   -- Output Enable
   RAM_WE	: out std_logic;								   -- Write Enable
   RAM_CE	: out std_logic);								   -- Chep Enable
--------------------------------------------------------------------------------------------------------------------
end Top;
architecture Behavioral of Top is
-------------- Component Declaration for the 7 segment driver -------------------
Component seg7_driver is port ( clk50: in std_logic;
	rst : in std_logic;
	char0 : in std_logic_vector (3 downto 0);
	char1 : in std_logic_vector (3 downto 0);
	char2 : in std_logic_vector (3 downto 0);
	char3 : in std_logic_vector (3 downto 0);
	anodes : out std_logic_vector (3 downto 0);
	enc_char : out std_logic_vector (6 downto 0));
end component;

-------------------------ARRAY TYPES for basis functions, data and anticipated computations -------------------------------
-------------------------Set up different array types needed --------------------------------------------------------------
	type array_type_basis is array(0 to 255) of signed(15 downto 0); -- from .bin file which has to be 16 bits from matlab

----------------------------ARRAY SIGNALS
	signal cos : array_type_basis;  -- 256 16 bit cosine values
	signal sin : array_type_basis;  -- 256 16 bit sin values
 
	signal cntr1 : unsigned (12 downto 0) ;
	signal syncr1 : std_logic;----synchronous reset 
	signal addrCount : unsigned (14 downto 0) ; -- plenty of bits
	signal SampleRate : std_logic;  -----
 
--------------------------------------	signals from instantiate seg7_driver code	
	signal char0a : std_logic_vector (3 downto 0);
	signal char1a : std_logic_vector (3 downto 0);
	signal char2a : std_logic_vector (3 downto 0);
	signal char3a : std_logic_vector (3 downto 0);

begin
-------------------------- Instantiation of the seg7_driver ---------------------
Inst1: component seg7_driver port map (
clk50=>clk_50, rst=>pushbuttons(0), char0=>char0a, char1=>char1a, char2=>char2a, char3=>char3a,
anodes=>an, enc_char=>seg7	);

------------set SRAM outputs  for READ ------------------------------------------
RAMAdv <= '0';
RAMClk <= clk_50;
RAMCre <= '0';
RAM_LB <= '0';
RAM_UB <= '0';
RAM_CE <= '0';
RAM_OE <= '0' ;  
RAM_WE<= '1';  ---set to 1 for constant read mode

-- Generate the Read Pulse pulse counter with synchronous counter that counts greater
-- than min access time of 70nS
process(clk_50,pushbuttons(0))  -- 100 MHz clock gives us a 10 ns clock period
begin
 if ((pushbuttons(0)='1')) then   
  cntr1<=(others=>'0');
   elsif (rising_edge(clk_50)) then
    if (syncr1='1') then
		cntr1<=(others=>'0');
	 else  
		cntr1<=cntr1+1; -- This must be equal to 7 before we can access memory(make it 9 to be safe)
	 end if;
 end if;
end process;

-- need at least 7 clocks, cntr1=6 to meet meet SRAM min access time of 70 nS ----------------------
syncr1<='1' when (cntr1= 10) else '0'; 
-- with 100 MHz clock, 10 counts is 100 nS.
 
SampleRate <= syncr1; -- Goes high every 80 ns  

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

---sliderswitches for data verify or address counter selects RAM address
Process (clk_50, pushbuttons(0))  
variable int_adr : integer range 0 to 511;
variable sin_adr : integer range 0 to 255; -- New line
begin 
	if (rising_edge(clk_50)) then
		if pushbuttons(0)='1' then   
			RAM_adr(25 downto 0) <= "000000000000000000" & sliderswitches ; --(25 downto 0)
		else 
			RAM_adr(25 downto 0) <= "00000000000"& std_logic_vector(addrcount) ;   
			int_adr := to_integer(unsigned(RAM_adr));
			if(int_adr <= 256) then
				cos(int_adr) <= signed(RAM_data);
			else
				sin_adr := int_adr - 255;
				sin(sin_adr) <= signed(RAM_data);
			end if;
		end if;
	end if; 
end process;

-- First Goal is to successfully load the memory values into the sin and cos arrays--
-- Pete was moving each value in one by one but wants to replace that with a process-


-- Second goal is displaying them on the 7 segment display---------------------------
process (clk_50, pushbuttons,sin,cos)
variable adr1 : integer range 0 to 255;
variable VecCos : std_logic_vector(15 downto 0) := "0000000000000000";
variable VecSin : std_logic_vector(15 downto 0):= "0000000000000000";
begin
	VecSin := std_logic_vector(sin(adr1));
	VecCos := std_logic_vector(cos(adr1));
	if pushbuttons ="0001" then
		char3a<= "0000";
		char2a<= "0000";
		char1a<= "0000";
		char0a<= "0000";
	elsif (rising_edge(clk_50)) then
		if pushbuttons= "0000" then  --"0010" then
			char3a<=  VecCos(15 downto 12) ; 	 
			char2a<=  VecCos(11 downto 8) ;          
			char1a<=  VecCos(7 downto 4) ;       
			char0a<=  VecCos(3 downto 0) ;     
		elsif pushbuttons= "0100" then
			char3a<=  VecSin(15 downto 12) ; 	 
			char2a<=  VecSin(11 downto 8) ;          
			char1a<=  VecSin(7 downto 4) ;       
			char0a<=  VecSin(3 downto 0) ;
		elsif pushbuttons= "1000" then
			adr1 := adr1 + 1;                         -- increment the address when you push the button
		else
			char3a<= "0000";
			char2a<= "0000";
			char1a<= "0000";
			char0a<= "0000";
		end if;
	end if;
end process; 
end Behavioral;

