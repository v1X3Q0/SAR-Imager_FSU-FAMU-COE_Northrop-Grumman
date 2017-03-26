----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:12:19 02/09/2017 
-- Design Name: 
-- Module Name:    top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

Library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.fixed_pkg.all;-- fixed point libraray
use work.all ;
-- This file samples input analog voltage into 12 bit word and outputs to 7seg display
entity AtoDto7seg_nexys3 is port (
clk_50 : in std_logic ;
--sliderswitches : in std_logic_vector (7 downto 0);
pushbuttons,pushbuttons_out,pushbuttons_out2, pushbuttons_out3, pushbuttons_out4: in std_logic;
rst: in std_logic;
--AtoD ports
CS : out std_logic;
CS2: out std_logic;
din : in std_logic; --adc
din2: in std_logic;
din3: in std_logic;
din4: in std_logic;
SClk : out std_logic; --adc
SClk2: out std_logic;
--SYNC : out std_logic;

--- OUTPUT:
dout1: OUT unsigned(11 downto 0); 
dout2: OUT unsigned(11 downto 0); 
dout3: OUT unsigned(11 downto 0);
dout4: OUT unsigned(11 downto 0);

-- seg7  display outputs
anodesa : out std_logic_vector (3 downto 0);
enc_chara : out std_logic_vector (6 downto 0));

---------------

end AtoDto7seg_nexys3;

architecture behavior of top is

type state_type is (idle, read);
type state_type2 is (idle2, read);

signal state : state_type := read;
signal state2: state_type2:=read;

signal data : unsigned(11 downto 0); 
signal data2: unsigned(11 downto 0); 
signal data3: unsigned(11 downto 0);
signal data4 : unsigned(11 downto 0);

signal temp_data: unsigned(11 downto 0);
signal temp_data2: unsigned (11 downto 0);
signal temp_data3: unsigned (11 downto 0);
signal temp_data4: unsigned (11 downto 0);



--signal data1 : signed(11 downto 0);
signal cnt : integer range 0 to 25 := 0;
signal clkdiv : integer range 0 to 6;
signal cnt2 :  integer range 0 to 20 :=0;
signal newclk : std_logic := '0';
signal risingedge : std_logic := '1';
signal reset : std_logic := '0';
--constant A :signed := "0000001" ;

--seg7 Display signals
signal char0a : std_logic_vector (3 downto 0);
signal char1a : std_logic_vector (3 downto 0);
signal char2a : std_logic_vector (3 downto 0);
signal char3a : std_logic_vector (3 downto 0);

signal dataSL : std_logic_vector (11 downto 0);
signal dataSL2: std_logic_vector (11 downto 0);
signal dataSL3: std_logic_vector (11 downto 0);
signal dataSL4: std_logic_vector (11 downto 0);
begin

--------------------------------------------instantiation of the seg7_driver
Inst1: entity seg7_driver port map (
clk50=>clk_50, rst=>pushbuttons, char0=>char0a, char1=>char1a, char2=>char2a, char3=>char3a,
anodes=>anodesa, enc_char=>enc_chara);
----------------------------------------------------


process(clk_50,rst)
begin
if (rst='1') then
cntr<=(others=>'0') ;
elsif (rising_edge(clk_50)) then
  if (syncr='1') then
  cntr<=(others=>'0');
  else
  cntr<=cntr+1;
end if;
  end if;
end process;



--drive the adc  clock pins
SClk <= newclk; 
SClk2 <= newclk;
--data1<= data - ("000001")*A;
dataSL<=std_logic_vector(data);
dataSL2<= std_logic_vector(data2);
dataSL3<=std_logic_vector(data3);
dataSL4<=std_logic_vector(data4);

------------clock divider
clock_divider: process(clk_50, pushbuttons)
begin
if(pushbuttons = '1') then
elsif(rising_edge(clk_50)) then
if(clkdiv = 5) then
risingedge <= risingedge xor '1';
newclk <= newclk xor '1';
clkdiv <= 0;
else
clkdiv <= clkdiv + 1;
end if;
end if;
end process clock_divider;


-----------send pusbutton values to seg7 display
Process ( clk_50, pushbuttons)
begin

if (pushbuttons='1') then 
 char0a<= (others =>'0');
 char1a<= (others =>'0');
 char2a<= (others =>'0');
 char3a<= (others =>'0');
elsif(rising_edge(clk_50)) then
 -- if (pushbutton(1)='1')then    
	if (pushbuttons_out='1') then 	
  char0a<= (others =>'0');             --These were switched around
  char1a<= (dataSL(11 downto 8));        
  char2a<= (dataSL(7 downto 4));
  char3a<= (dataSL(3 downto 0));
  
  elsif (pushbuttons_out2='1') then 
  char0a<= (others =>'0');               --These were switched around
  char1a<= (dataSL2(11 downto 8));        
  char2a<= (dataSL2(7 downto 4));
  char3a<= (dataSL2(3 downto 0));
  
  elsif(pushbuttons_out3='1') then 
  char0a<= (others =>'0');               
  char1a<= (dataSL3(11 downto 8));        
  char2a<= (dataSL3(7 downto 4));
  char3a<= (dataSL3(3 downto 0));
  
  elsif(pushbuttons_out4='1') then 
  char0a<= (others =>'0');               
  char1a<= (dataSL4(11 downto 8));        
  char2a<= (dataSL4(7 downto 4));
  char3a<= (dataSL4(3 downto 0));
  
  end if;
  
end if ;
end process ;


main: process(clk_50, pushbuttons)
variable temp : integer;
begin
	if(pushbuttons = '1') then
	elsif(rising_edge(clk_50)) then
		if(clkdiv = 5 and risingedge = '1') then
		case state is
			when idle =>
				CS <= '1';
				--SYNC <= '1';
				if(cnt = 15) then
					cnt <= 0;
					state <= read;
				else
					cnt <= cnt + 1;
					state <= idle;
				end if;
			when read =>
				CS <= '0';
				--SYNC <= '1';
				cnt <= cnt + 1;
				if(cnt < 4) then
					cnt <= cnt + 1;
					state <= read;
				elsif(cnt > 3 and cnt < 16) then
					cnt <= cnt + 1;
					data2(15 - cnt) <= din2;
					data(15 - cnt) <= din;
					state <= read;
				elsif(cnt = 16) then
					--cnt <= 0;
					state <= idle;
				end if;
		end case ;  
		end if ;
	end if ;
end process main;



main2: process(clk_50, pushbuttons)
variable temp2 : integer;
begin
	if(pushbuttons = '1') then
	elsif(rising_edge(clk_50)) then
		if(clkdiv = 5 and risingedge = '1') then
			case state2 is
				when idle2 =>
					CS2 <= '1';
					--SYNC <= '1';
					if(cnt2 = 15) then
						cnt2 <= 0;
						state2 <= read;
					else
						cnt2 <= cnt2 + 1;
						state2 <= idle2;
					end if;
				when read =>
					CS2 <= '0';
					--SYNC <= '1';
					cnt2 <= cnt2 + 1;
					if(cnt < 4) then
						cnt2 <= cnt2 + 1;
						state2 <= read;
					elsif(cnt2 > 3 and cnt2 < 16) then
						cnt2 <= cnt2 + 1;
						data4(15 - cnt2) <= din4;
						data3(15 - cnt2) <= din3;
						state2 <= read;
					elsif(cnt2 = 16) then
						cnt2 <= 0;
						state2 <= idle2;
					end if;
			end case ;  
		end if ;
	end if ;
end process main2;

-- Which one of these is I and Q?
dout1<= data;
dout2<= data2;
dout3<= data3;
dout4<= data4;

end top ;





