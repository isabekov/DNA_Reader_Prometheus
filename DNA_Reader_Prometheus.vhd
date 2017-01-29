------------------------------------------------------------------
-- Project Name:   DNA reader for Prometheus FGPA (Spartan 3A)
-- Description:    Load DNA of the device into a register and show 
--                 it on 7-segment displays
-- Target Devices: xc3s50a
-- Engineer:       Altynbek Isabekov
-- Create Date:    00:55:53 2017/01/28 
------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity DNA_Reader_Prometheus is
	 generic (M: INTEGER:=65536); -- Display multiplexer value for 50 MHz clock
	
    Port ( CLK : in  STD_LOGIC;
        Trigger: in STD_LOGIC;
           Half: in STD_LOGIC;
           SevenSegments : out  STD_LOGIC_VECTOR (6 downto 0);
           Anodes : out  STD_LOGIC_VECTOR (7 downto 0));
end DNA_Reader_Prometheus;

architecture Behavioral of DNA_Reader_Prometheus is
	signal Lock: STD_LOGIC:='0';	
	signal Has_Started: STD_LOGIC:='0';	
	signal Is_Loaded: STD_LOGIC:='0';	
	signal Is_Shifted: STD_LOGIC:='0';
	signal DNA_READ   : STD_LOGIC;
	signal DNA_SHIFT  : STD_LOGIC;
	signal DNA_DOUT   : STD_LOGIC;	
	signal DNA_REG: STD_LOGIC_VECTOR(56 downto 0):=(others => '0');
	signal HALF_REG: STD_LOGIC_VECTOR(31 downto 0):=(others => '0');
	signal F: STD_LOGIC_VECTOR(3 downto 0);
begin
	 -- Xilinx DNA_PORT primitive
	 -- Initialized only if UNISIM.VComponents.all library is used
    Device_DNA: DNA_PORT
    port map(   DIN => '1',
               READ => DNA_READ,
              SHIFT => DNA_SHIFT,                       
               DOUT => DNA_DOUT,                       
                CLK => CLK);
					 
	 -- Select which half of the DNA to display
	 with Half select
	 HALF_REG <= DNA_REG(31 downto 0)                when '0',
				    ("0000000" & DNA_REG(56 downto 32)) when '1',
					 (others => '0')                     when others;		
	
	 -- Hexadecimal to 7-segment decoder						
    with F select
	 SevenSegments <= "0000001" when "0000",
						 "1001111" when "0001",
						 "0010010" when "0010",
						 "0000110" when "0011",
						 "1001100" when "0100",
						 "0100100" when "0101",
						 "0100000" when "0110",
						 "0001111" when "0111",
						 "0000000" when "1000",
						 "0000100" when "1001",
						 "0001000" when "1010",
						 "1100000" when "1011",
						 "0110001" when "1100",
						 "1000010" when "1101",
						 "0110000" when "1110",
						 "0111000" when "1111",
						 "0000001" when others;
						 
	process(CLK)
	variable DNA_Counter : INTEGER range 0 to 57;
	begin
		if(rising_edge(CLK)) then
			if Lock = '0' then 
				if Trigger = '1' then
					Lock <= '1';
				end if;
			else	
				if Has_Started = '0' then
					Has_Started <= '1';
					DNA_READ <= '1';
				else
					if Is_Loaded = '0' then
						Is_Loaded <= '1';
						DNA_READ <= '0'; 
						DNA_SHIFT <= '1'; 
					else
						if Is_Shifted = '0' then
							DNA_Counter := DNA_Counter + 1;
							if DNA_Counter = 57 then
								Is_Shifted <= '1';
								DNA_SHIFT <= '0';
								Lock <= '0';
								Has_Started <= '0';
							end if;
							DNA_REG <= DNA_REG(55 downto 0) & DNA_DOUT;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	
	-- Display multiplexer for 8 displays
	process(CLK)
	variable Mux_Counter : INTEGER range 0 to M;
	begin
		if(rising_edge(CLK)) then
			Mux_Counter := Mux_Counter + 1;
			if (Mux_Counter mod M = 0) then
				Anodes <= "11111110";
				F <= HALF_REG(3 downto 0); 
			elsif (Mux_Counter mod M = 1*M/8) then
				Anodes <= "11111101";
				F <= HALF_REG(7 downto 4); 
			elsif (Mux_Counter mod M = 2*M/8) then
				Anodes <= "11111011";
				F <= HALF_REG(11 downto 8); 
			elsif (Mux_Counter mod M = 3*M/8) then
				Anodes <= "11110111";
				F <= HALF_REG(15 downto 12); 
			elsif (Mux_Counter mod M = 4*M/8) then
				Anodes <= "11101111";
				F <= HALF_REG(19 downto 16); 
			elsif (Mux_Counter mod M = 5*M/8) then
				Anodes <= "11011111";
				F <= HALF_REG(23 downto 20); 
			elsif (Mux_Counter mod M = 6*M/8) then
				Anodes <= "10111111";
				F <= HALF_REG(27 downto 24); 
			elsif (Mux_Counter mod M = 7*M/8) then
				Anodes <= "01111111";
				F <= HALF_REG(31 downto 28); 
			end if;
		end if;
	end process;
end Behavioral;