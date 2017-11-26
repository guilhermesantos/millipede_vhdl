library IEEE;
use  IEEE.STD_LOGIC_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.ALL; 

use work.MILLIPEDE_PACKAGE.all;

ENTITY notepad IS
	GENERIC (NUM_MILLIPEDE_PARTS: INTEGER := 3);
	
	PORT(
		clkvideo, clk, reset  : IN	STD_LOGIC;		
		videoflag	: out std_LOGIC;
		vga_pos		: out STD_LOGIC_VECTOR(15 downto 0);
		vga_char		: out STD_LOGIC_VECTOR(15 downto 0);
		
		key			: IN 	STD_LOGIC_VECTOR(7 DOWNTO 0);	-- teclado
		ship_pos : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		
		obst_addr: OUT STD_LOGIC_VECTOR(10 DOWNTO 0);
		obst_write: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		obst_read: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		obst_wren: OUT STD_LOGIC
		);

END  notepad ;

ARCHITECTURE a OF notepad IS
	--Instancia primeira parte do Millipede
	SIGNAL MILLIPEDE_PART0: MILLIPEDE_PART_T := (  
		PREV_POSIT => 0,
		CUR_POSIT => 64,
		CHAR => 2,
		COLOR => 10,
		TIME_SINCE_LAST_UPDATE => 0,
		LIFE => ALIVE,
		VERTICAL_DIRECTION => MOVING_DOWN,
		HORIZONTAL_DIRECTION => MOVING_RIGHT
	);
	
	--Instancia segunda parte do Millipede
	SIGNAL MILLIPEDE_PART1: MILLIPEDE_PART_T := (
		PREV_POSIT => 0,
		CUR_POSIT => 62,
		CHAR => 4,
		COLOR => 10,
		TIME_SINCE_LAST_UPDATE => 0,
		LIFE => ALIVE,
		VERTICAL_DIRECTION => MOVING_DOWN,
		HORIZONTAL_DIRECTION => MOVING_RIGHT
	);
	--Instancia terceira parte do millipede
	SIGNAL MILLIPEDE_PART2: MILLIPEDE_PART_T := (
		PREV_POSIT => 0,
		CUR_POSIT => 60,
		CHAR => 4,
		COLOR => 10,
		TIME_SINCE_LAST_UPDATE => 0,
		LIFE => ALIVE,
		VERTICAL_DIRECTION => MOVING_DOWN,
		HORIZONTAL_DIRECTION => MOVING_RIGHT
	);
	
	--Coloca as duas partes criadas do Millipede em um array	
	SIGNAL MILLIPEDE_PARTS: MILLIPEDE_PART_ARRAY_T(NUM_MILLIPEDE_PARTS-1 DOWNTO 0) := (MILLIPEDE_PART0, 
																				MILLIPEDE_PART1, MILLIPEDE_PART2);
	SIGNAL MIL_COUNT_UPDATE: INTEGER := 0;
	SIGNAL MIL_COUNT_RENDER: INTEGER := 0;
	SIGNAL MIL_COUNT_COLIS: INTEGER := 0;
	
	--Instancia uma Spaceship
	SIGNAL SPACESHIP: SPACESHIP_T := (
		PREV_POSIT => 0,
		CUR_POSIT => 700,
		CHAR => 1,
		COLOR => 1,
		TIME_SINCE_LAST_UPDATE => 0,
		UPDATE_STATE => MOVING
	);
	
	--Instancia um foguete
	SIGNAL ROCKET: ROCKET_T := (
		PREV_POSIT => 0,
		CUR_POSIT => 0,
		CHAR => 6,
		COLOR => 1, 
		TIME_SINCE_LAST_UPDATE => 0,
		UPDATE_STATE => NOT_FIRED
	);	
	

	-- Escreve na tela
	SIGNAL VIDEOE     : STD_LOGIC_VECTOR(7 DOWNTO 0);

	SIGNAL OBSTACLE: OBSTACLE_T := (
		POSIT => 350,
		LIFE => 3
	);
	
BEGIN

-- Nave
UPDATE_SPACESHIP: PROCESS (clk, reset)
	BEGIN
		
	IF RESET = '1' THEN
		SPACESHIP.CUR_POSIT <= 700;
		SPACESHIP.CHAR <= 1;
		SPACESHIP.COLOR <= 1;
		SPACESHIP.TIME_SINCE_LAST_UPDATE <= 0;
		SPACESHIP.UPDATE_STATE <= MOVING;
		
	ELSIF (clk'event) and (clk = '1') THEN
	
		CASE SPACESHIP.UPDATE_STATE IS 
			WHEN MOVING =>
				CASE key IS 
					WHEN x"73" => --Nao esta tentando ir abaixo da ultima linha
						IF(SPACESHIP.CUR_POSIT < 1159) THEN
							SPACESHIP.CUR_POSIT <= SPACESHIP.CUR_POSIT + 40;
						END IF;
					WHEN x"77" => --Nao esta tentando ir acima da primeira linha
						IF(SPACESHIP.CUR_POSIT > 39) THEN
							SPACESHIP.CUR_POSIT <= SPACESHIP.CUR_POSIT - 40;
						END IF;
					WHEN x"61" => --Nao esta na extrema esquerda
						IF(NOT(SPACESHIP.CUR_POSIT MOD 40 = 0) ) THEN
							SPACESHIP.CUR_POSIT <= SPACESHIP.CUR_POSIT - 1;

						END IF;
					WHEN x"64" => --Nao esta na extrema direita
						IF(NOT(SPACESHIP.CUR_POSIT MOD 40 = 39) ) THEN
							SPACESHIP.CUR_POSIT <= SPACESHIP.CUR_POSIT + 1;
						END IF;
					WHEN OTHERS =>
				END CASE; --Case do teclado	
				
				SPACESHIP.UPDATE_STATE <= DELAYING;
			WHEN DELAYING =>
			
				IF(SPACESHIP.TIME_SINCE_LAST_UPDATE >= 3000) THEN 
					SPACESHIP.TIME_SINCE_LAST_UPDATE <= 0;
					SPACESHIP.UPDATE_STATE <= MOVING;
				ELSE 
					SPACESHIP.TIME_SINCE_LAST_UPDATE <= SPACESHIP.TIME_SINCE_LAST_UPDATE+1;
				END IF;		
			WHEN OTHERS =>
			
		END CASE;--Case do update da nave
			
	END IF;

END PROCESS;

UPDATE_ROCKETS: PROCESS(clk, reset)
BEGIN 
	IF RESET = '1' THEN
		ROCKET.CUR_POSIT <= 0;
		ROCKET.CHAR <= 5;
		ROCKET.COLOR <= 3; 
		ROCKET.TIME_SINCE_LAST_UPDATE <= 0;
		ROCKET.UPDATE_STATE <= NOT_FIRED;
		
	ELSIF (CLK'EVENT AND CLK = '1') THEN
		CASE ROCKET.UPDATE_STATE IS
			WHEN NOT_FIRED =>--Foguete ainda nao foi disparado
				CASE key IS 
					WHEN x"66" => --Tecla f
						ROCKET.CUR_POSIT <= SPACESHIP.CUR_POSIT-40;
						ROCKET.TIME_SINCE_LAST_UPDATE <= 0;
						ROCKET.UPDATE_STATE <= FIRED;
					WHEN OTHERS =>
				END CASE;
			WHEN FIRED =>--Foguete foi disparado. Atualiza posicao

				IF(ROCKET.TIME_SINCE_LAST_UPDATE >= 3000) THEN --Chegou o momento de atualizar a posicao do foguete
					IF(ROCKET.CUR_POSIT > 39) THEN--Ainda esta dentro da tela
						ROCKET.CUR_POSIT <= ROCKET.CUR_POSIT-40;
					ELSE --Saiu da tela
						ROCKET.UPDATE_STATE <= NOT_FIRED;
						ROCKET.CUR_POSIT <= 0;
					END IF;				
					--Em ambos os casos, reinicializa o timer de atualizacao do foguete
					ROCKET.TIME_SINCE_LAST_UPDATE <= 0;
				ELSE--Se nao chegou a hora de atualizar, reinicia o timer e entra de novo no processo
					ROCKET.TIME_SINCE_LAST_UPDATE <= ROCKET.TIME_SINCE_LAST_UPDATE+1;	
				END IF;--If do delay
		END CASE;--Case da maquina de estados do foguete
	END IF;--If do clock

END PROCESS;

UPDATE_MILLIPEDE: PROCESS(clk, reset)
	VARIABLE BLA: BOOLEAN := FALSE;
	VARIABLE VAI_ATINGIR_EXTREMO_HORIZONTAL : BOOLEAN := FALSE;
	VARIABLE VAI_ATINGIR_EXTREMO_VERTICAL: BOOLEAN := FALSE;
	VARIABLE VAI_MOVER_NA_VERTICAL: BOOLEAN := FALSE;
	VARIABLE COLIDIU_COM_OBSTACULO : BOOLEAN := FALSE;
BEGIN
	IF RESET = '1' THEN
		MIL_COUNT_UPDATE <= 0;
		--MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CUR_POSIT <= 61;
		MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CHAR <= 2;
		MILLIPEDE_PARTS(MIL_COUNT_UPDATE).COLOR <= 10;
		MILLIPEDE_PARTS(MIL_COUNT_UPDATE).TIME_SINCE_LAST_UPDATE <= 0;
		MILLIPEDE_PARTS(MIL_COUNT_UPDATE).VERTICAL_DIRECTION <= MOVING_DOWN;
		MILLIPEDE_PARTS(MIL_COUNT_UPDATE).HORIZONTAL_DIRECTION <= MOVING_RIGHT;
	
	ELSIF (CLK'EVENT AND CLK = '1') THEN
		IF(MILLIPEDE_PARTS(MIL_COUNT_UPDATE).TIME_SINCE_LAST_UPDATE >= 2000) THEN

			CASE (MILLIPEDE_PARTS(MIL_COUNT_UPDATE).LIFE) IS
				WHEN ALIVE =>
													
					VAI_MOVER_NA_VERTICAL := FALSE;					
					
					COLIDIU_COM_OBSTACULO := (MILLIPEDE_PARTS(MIL_COUNT_COLIS).HORIZONTAL_DIRECTION = MOVING_RIGHT AND 
						MILLIPEDE_PARTS(MIL_COUNT_COLIS).CUR_POSIT + 1 = OBSTACLE.POSIT) OR
						(MILLIPEDE_PARTS(MIL_COUNT_COLIS).HORIZONTAL_DIRECTION = MOVING_LEFT AND
						(MILLIPEDE_PARTS(MIL_COUNT_COLIS).CUR_POSIT - 1 = OBSTACLE.POSIT));
							
					VAI_ATINGIR_EXTREMO_HORIZONTAL := ((MILLIPEDE_PARTS(MIL_COUNT_UPDATE).HORIZONTAL_DIRECTION = MOVING_RIGHT) AND ((MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CUR_POSIT+1) MOD 40 >= 39))
						OR ((MILLIPEDE_PARTS(MIL_COUNT_UPDATE).HORIZONTAL_DIRECTION = MOVING_LEFT ) AND ((MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CUR_POSIT-1) MOD 40 <= 0));
					
					VAI_MOVER_NA_VERTICAL := VAI_ATINGIR_EXTREMO_HORIZONTAL OR COLIDIU_COM_OBSTACULO;
					
					IF(VAI_ATINGIR_EXTREMO_HORIZONTAL OR COLIDIU_COM_OBSTACULO) THEN
						--Verifica se atingiu um dos extremos horizontais ou colidiu com um obstaculo. 
						--Se um dos dois aconteceu, a parte precisa descer e inverter direcao DO movimento horizontal
										
						IF(MILLIPEDE_PARTS(MIL_COUNT_UPDATE).HORIZONTAL_DIRECTION = MOVING_RIGHT) then
							--Inverte a direcao horizontal
							MILLIPEDE_PARTS(MIL_COUNT_UPDATE).HORIZONTAL_DIRECTION <= MOVING_LEFT;
						ELSE 
							MILLIPEDE_PARTS(MIL_COUNT_UPDATE).HORIZONTAL_DIRECTION <= MOVING_RIGHT;
						END IF;
						
						--MILLIPEDE_PARTS(MIL_COUNT_UPDATE).HORIZONTAL_DIRECTION <= 
						--INVERTE_DIRECAO_HORIZONTAL_MILLIPEDE(MILLIPEDE_PARTS(MIL_COUNT_UPDATE));
					ELSE
					
						--Nao precisa mover na vertical, entao vai continuar na horizontal
						IF(MILLIPEDE_PARTS(MIL_COUNT_UPDATE).HORIZONTAL_DIRECTION = MOVING_RIGHT) THEN
							--Realiza o movimento horizontal
							MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CHAR <= 2;--TALVEZ ISSO DEVA SER FEITO NA MAQUINA DE RENDERING
							MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CUR_POSIT <= MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CUR_POSIT + 1;
						ELSE
							MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CHAR <= 3;
							MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CUR_POSIT <= MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CUR_POSIT - 1;
						END IF;
						
					END IF;
										
					IF(VAI_MOVER_NA_VERTICAL) THEN
					
						VAI_ATINGIR_EXTREMO_VERTICAL := ((MILLIPEDE_PARTS(MIL_COUNT_UPDATE).VERTICAL_DIRECTION = MOVING_DOWN) AND (MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CUR_POSIT+40 >= 1159))
						OR ((MILLIPEDE_PARTS(MIL_COUNT_UPDATE).VERTICAL_DIRECTION = MOVING_UP) AND (MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CUR_POSIT-40 <= 39));
					
						IF(VAI_ATINGIR_EXTREMO_VERTICAL) THEN
							--Verifica se atingiu um dos extremos verticais. Se atingiu, inverte a direcao do movimento vertical
							
							IF(MILLIPEDE_PARTS(MIL_COUNT_UPDATE).VERTICAL_DIRECTION = MOVING_DOWN) then
								--Inverte a direcao vertical
								MILLIPEDE_PARTS(MIL_COUNT_UPDATE).VERTICAL_DIRECTION <= MOVING_UP;
							ELSE 
							
								MILLIPEDE_PARTS(MIL_COUNT_UPDATE).VERTICAL_DIRECTION <= MOVING_DOWN;
							END IF;
							
						END IF;
						
						IF(MILLIPEDE_PARTS(MIL_COUNT_UPDATE).VERTICAL_DIRECTION = MOVING_DOWN) THEN
							--Realiza o movimento vertical
							MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CUR_POSIT <= MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CUR_POSIT + 40;
						ELSE 
							MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CUR_POSIT <= MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CUR_POSIT - 40;
						END IF;
						
					END IF;--Fim do if que trata o movimento vertical
				
				WHEN DEAD =>--Morreu, entao desaparece e 1cria um obstaculo no lugar (TO DO)
					MILLIPEDE_PARTS(MIL_COUNT_UPDATE).CHAR <= 7;
				WHEN OTHERS =>--????
				
			END CASE;--Fim do if que trata o status da vida do millipede
			
			MILLIPEDE_PARTS(MIL_COUNT_UPDATE).TIME_SINCE_LAST_UPDATE <= 0;
			
		ELSE --Else do if que trata o delay
		
			MILLIPEDE_PARTS(MIL_COUNT_UPDATE).TIME_SINCE_LAST_UPDATE <= MILLIPEDE_PARTS(MIL_COUNT_UPDATE).TIME_SINCE_LAST_UPDATE + 1;
		
		END IF;--FIm do if que trata o delay
		
		
		--Faz com que a iteracao seguinte do process atualize o segmento seguinte do millipede
	MIL_COUNT_UPDATE <= (MIL_COUNT_UPDATE +1) MOD NUM_MILLIPEDE_PARTS;
	
	ship_pos(23 DOWNTO 0) <= std_logic_vector(to_unsigned(SPACESHIP.CUR_POSIT, 24));
	ship_pos(31 DOWNTO 24) <= x"00";
		
	END IF;--Fim do case que verifica se chegou clock
END PROCESS;

UPDATE_COLLISION: PROCESS(clk, reset)
BEGIN
	IF(RESET = '1') THEN
		MIL_COUNT_COLIS <= 0;

	ELSIF (CLK'EVENT AND CLK = '1') THEN
		
		IF(ROCKET.UPDATE_STATE = FIRED AND ROCKET.CUR_POSIT - 40 = MILLIPEDE_PARTS(MIL_COUNT_COLIS).CUR_POSIT) THEN		
				MILLIPEDE_PARTS(MIL_COUNT_COLIS).LIFE <= DEAD;
		END IF;
		
		MIL_COUNT_COLIS <= (MIL_COUNT_COLIS+1) MOD NUM_MILLIPEDE_PARTS;
	END IF;
END PROCESS;

-- Escreve na Tela
RENDER_SCREEN: PROCESS (clk, reset)
BEGIN
	IF RESET = '1' THEN
		VIDEOE <= x"00";
		videoflag <= '0';
		MIL_COUNT_RENDER <= 0;
	
		--Inicializa a posicao anterior da nave
		SPACESHIP.PREV_POSIT <= 0;
		--Inicializa a posicao anterior do foguete
		ROCKET.PREV_POSIT <= 0;
		--Inicializa a posicao anterior do millipede
		MILLIPEDE_PARTS(MIL_COUNT_RENDER).PREV_POSIT <= 0;
		
	ELSIF (clkvideo'event) and (clkvideo = '1') THEN
		CASE VIDEOE IS	
			WHEN x"00" => --Apaga nave
				IF(SPACESHIP.PREV_POSIT = SPACESHIP.CUR_POSIT) THEN
					VIDEOE <= x"04";--Se a nave nao mexeu, a maquina de estados passa pra renderizacao do foguete
				ELSE 				
					--Se mexeu, pinta o quadrado de preto
					vga_char(15 downto 12) <= "0000";
					vga_char(11 downto 8) <= "0000";
					vga_char(7 downto 0) <= "00000000";
					vga_pos(15 downto 0)	<= std_logic_vector(to_unsigned(SPACESHIP.PREV_POSIT, 16));
					videoflag <= '1';
					VIDEOE <= x"01";--Vai pro estado que desliga a flag
				END IF;
				
			WHEN x"01" => 
				videoflag <= '0';--Desliga flag
				VIDEOE <= x"02"; --Vai pro estado que desenha a nave
				
			WHEN x"02" => --Desenha nave
				vga_char(15 DOWNTO 12) <= "0000";
				vga_char(11 DOWNTO 8) <= std_logic_vector(to_unsigned(SPACESHIP.COLOR, 4)); 
				vga_char(7 DOWNTO 0) <= std_logic_vector(to_unsigned(SPACESHIP.CHAR, 8));
				vga_pos(15 DOWNTO 0) <= std_logic_vector(to_unsigned(SPACESHIP.CUR_POSIT, 16)); 
				SPACESHIP.PREV_POSIT <= SPACESHIP.CUR_POSIT;
				videoflag  <= '1';			
				VIDEOE <= x"03";--Vai pro estado que desliga a flag
				
			WHEN x"03" =>
				videoflag <= '0'; --Desliga flag
				VIDEOE <= x"04"; --Vai pro estado que desenha o foguete
				
			WHEN x"04" => --Apaga o foguete			
				IF(ROCKET.PREV_POSIT = ROCKET.CUR_POSIT) THEN
					--Se o foguete nao mexeu, pode passar para o proximo estagio da maquina de rendering 
					VIDEOE <= x"08";--que consiste em desenhar o millipede
				ELSE
					--Se mexeu, pinta o quadrado de preto
					vga_char(15 downto 12) <= "0000";
					vga_char(11 downto 8) <= "0000";
					vga_char(7 downto 0) <= "00000000";
					vga_pos(15 downto 0)	<= std_logic_vector(to_unsigned(ROCKET.PREV_POSIT, 16));
					ROCKET.PREV_POSIT <= ROCKET.CUR_POSIT;

					videoflag <= '1';
				
					VIDEOE <= x"05";--Vai pro estado que desliga a flag
				END IF;
				
			WHEN x"05" => --Desliga flag
				videoflag <= '0';
				VIDEOE <= x"06";--Vai pro estado que desenha o foguete
				
			WHEN x"06" => --Desenha o foguete
				IF( ROCKET.UPDATE_STATE /= FIRED) THEN
					VIDEOE <= x"08";--Se o foguete nao foi disparado, nao precisa desenha-lo novamente
				ELSE 					 --Vai para o estagio de desenhar o millipede
					vga_char(15 DOWNTO 12) <= "0000";
					vga_char(11 DOWNTO 8) <= std_logic_vector(to_unsigned(ROCKET.COLOR, 4)); 
					vga_char(7 DOWNTO 0) <= std_logic_vector(to_unsigned(ROCKET.CHAR, 8));
					vga_pos(15 DOWNTO 0) <= std_logic_vector(to_unsigned(ROCKET.CUR_POSIT, 16)); 
					videoflag  <= '1';			
					VIDEOE <= x"07";--Vai pro estado que desliga a flag
				END IF;
				
			WHEN x"07" => --Desliga flag e vai pro estado que apaga o millipede
				videoflag <= '0';
				VIDEOE <= x"08";
			WHEN x"08" => --Apaga o pedaco do millipede
				
				IF(MILLIPEDE_PARTS(MIL_COUNT_RENDER).PREV_POSIT = MILLIPEDE_PARTS(MIL_COUNT_RENDER).CUR_POSIT
					AND MILLIPEDE_PARTS(MIL_COUNT_RENDER).LIFE /= DEAD) THEN
					
					--Se o millipede nao mexeu, pode passar para o proximo estagio da maquina de rendering 				
					--que por enquanto nao existe. reinicia a maquina de estados					
					
					MIL_COUNT_RENDER <= (MIL_COUNT_RENDER + 1) MOD NUM_MILLIPEDE_PARTS; 
					--Faz com que a iteracao seguinte do process atualie o proximo pedaco do millipedes
					
					VIDEOE <= x"00";
				ELSE													   
					--Se mexeu, pinta o quadrado de preto
					vga_char(15 downto 12) <= "0000";
					vga_char(11 downto 8) <= "0000";
					vga_char(7 downto 0) <= "00000000";
					vga_pos(15 downto 0)	<= std_logic_vector(to_unsigned(MILLIPEDE_PARTS(MIL_COUNT_RENDER).PREV_POSIT, 16));
					videoflag <= '1';			
					VIDEOE <= x"09";--Vai pro estado que desliga a flag
				END IF;
				
			WHEN x"09" => --Desliga a flag de video
				videoflag <= '0';
				VIDEOE <= x"0A";
			WHEN x"0A" => --Desenha o pedaco do millipede
				
				--IF(MILLIPEDE_PARTS(MIL_COUNT_RENDER).LIFE = DEAD) THEN
				--	VIDEOE <= x"00";
					--Pedaco do millipede morreu, entao nao precisa ser renderizado. Passa para o proximo
					--etapa da maquina, que por enquanto ainda nao existe, entao reinicia
				--ELSE 
				vga_char(15 DOWNTO 12) <= "0000";
				vga_char(11 DOWNTO 8) <= std_logic_vector(to_unsigned(MILLIPEDE_PARTS(MIL_COUNT_RENDER).COLOR, 4)); 
				vga_char(7 DOWNTO 0) <= std_logic_vector(to_unsigned(MILLIPEDE_PARTS(MIL_COUNT_RENDER).CHAR, 8));
				vga_pos(15 DOWNTO 0) <= std_logic_vector(to_unsigned(MILLIPEDE_PARTS(MIL_COUNT_RENDER).CUR_POSIT, 16));
				
				MILLIPEDE_PARTS(MIL_COUNT_RENDER).PREV_POSIT <= MILLIPEDE_PARTS(MIL_COUNT_RENDER).CUR_POSIT;

				videoflag <= '1';
													
				VIDEOE <= x"0B";--Vai pro estado que desliga a flag					
				--END IF;
			
				MIL_COUNT_RENDER <= (MIL_COUNT_RENDER + 1) MOD NUM_MILLIPEDE_PARTS; --Faz com que a iteracao seguinte do process
																			  							  --desenhe o proximo segmento do millipede				
				
			WHEN x"0B" => --Desliga a flag de video e reinicia a maquina de estados
				videoflag <= '0';
				VIDEOE <= x"00";
			WHEN OTHERS =>
				videoflag <= '0';
				VIDEOE <= x"00";	
		END CASE;
	END IF;
END PROCESS;
	
--PROCESS (videoflag, video_set)
--BEGIN
--  IF video_set = '1' THEN video_ready <= '0';
--  ELSIF videoflag'EVENT and videoflag = '1' THEN video_ready <= '1';
--  END IF;
--END PROCESS;

END a;
