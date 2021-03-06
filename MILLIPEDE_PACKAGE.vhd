library IEEE;
use  IEEE.STD_LOGIC_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;

PACKAGE MILLIPEDE_PACKAGE IS

	TYPE SPACESHIP_UPDATE_STATE_T IS (MOVING, COLLISION, DELAYING);--Renomear para ser utilizado por qualquer entidade
	TYPE ROCKET_UPDATE_STATE_T IS (NOT_FIRED, FIRED);
	
	TYPE MILLIPEDE_LIFE_STATE_T IS(ALIVE, DEAD);
	TYPE VERTICAL_DIRECTION_T IS (MOVING_DOWN, MOVING_UP);
	TYPE HORIZONTAL_DIRECTION_T IS (MOVING_RIGHT, MOVING_LEFT);
	
	TYPE RENDER_STATE_T IS (ERASING_SPACESHIP, RENDERING_SPACESHIP, ERASING_ROCKET, RENDERING_ROCKET, 
		ERASING_MILLIPEDE, RENDERING_MILLIPEDE);
	
	TYPE GAME_STATE_T IS (PLAYING, WIN, GAME_OVER);
	
	TYPE MILLIPEDE_PART_T IS RECORD 
		PREV_POSIT: INTEGER;
		CUR_POSIT: INTEGER;
		CHAR: INTEGER;
		COLOR: INTEGER;
		TIME_SINCE_LAST_UPDATE: INTEGER;
		LIFE: MILLIPEDE_LIFE_STATE_T;
		VERTICAL_DIRECTION: VERTICAL_DIRECTION_T;
		HORIZONTAL_DIRECTION: HORIZONTAL_DIRECTION_T;
		TESTING_FOR_COLLISION_WITH_OBSTACLES: BOOLEAN;
		COLLIDED_WITH_OBSTACLE: BOOLEAN;
		OBSTACLE_COUNTER : INTEGER;
	END RECORD MILLIPEDE_PART_T;

	TYPE SPACESHIP_T IS RECORD 
		PREV_POSIT: INTEGER;--32 bits
		CUR_POSIT: INTEGER;--32 bits
		CHAR: INTEGER;--8 bits
		COLOR: INTEGER;--4 bits
		TIME_SINCE_LAST_UPDATE: INTEGER; 
		UPDATE_STATE: SPACESHIP_UPDATE_STATE_T;
	END RECORD SPACESHIP_T;

	TYPE ROCKET_T IS RECORD
		PREV_POSIT: INTEGER;
		CUR_POSIT: INTEGER;
		CHAR: INTEGER;
		COLOR: INTEGER;
		TIME_SINCE_LAST_UPDATE: INTEGER;
		UPDATE_STATE: ROCKET_UPDATE_STATE_T;		
	END RECORD ROCKET_T;
	
	TYPE OBSTACLE_T IS RECORD 
		CUR_POSIT: INTEGER;
		LIFE: INTEGER;
		CHAR: INTEGER;
		COLOR: INTEGER;
	END RECORD OBSTACLE_T;
	
	TYPE MILLIPEDE_PART_ARRAY_T IS ARRAY(INTEGER RANGE<>) OF MILLIPEDE_PART_T;	
	TYPE OBSTACLE_ARRAY_T IS ARRAY(INTEGER RANGE<>) OF OBSTACLE_T;

	FUNCTION MILLIPEDE_VAI_ACERTAR_OBSTACULO(PARTE: MILLIPEDE_PART_T) RETURN BOOLEAN;
	FUNCTION MILLIPEDE_VAI_ATINGIR_EXTREMO_HORIZONTAL(PARTE: MILLIPEDE_PART_T) RETURN BOOLEAN;
	FUNCTION MILLIPEDE_VAI_ATINGIR_EXTREMO_VERTICAL(PARTE: MILLIPEDE_PART_T) RETURN BOOLEAN;
	FUNCTION INVERTE_DIRECAO_HORIZONTAL_MILLIPEDE(PARTE: MILLIPEDE_PART_T) RETURN HORIZONTAL_DIRECTION_T;
	FUNCTION INVERTE_DIRECAO_VERTICAL_MILLIPEDE(PARTE: MILLIPEDE_PART_T) RETURN VERTICAL_DIRECTION_T;
	FUNCTION INICIALIZA_ARRAY_OBSTACLE(QTD: INTEGER) RETURN OBSTACLE_ARRAY_T;
	FUNCTION VAI_COLIDIR_COM_OBSTACULOS(PART: MILLIPEDE_PART_T; OBSTACLES: OBSTACLE_ARRAY_T; QTD_OBSTACLES: INTEGER) RETURN BOOLEAN;
END PACKAGE MILLIPEDE_PACKAGE;

PACKAGE BODY MILLIPEDE_PACKAGE IS

	FUNCTION VAI_COLIDIR_COM_OBSTACULOS(PART: MILLIPEDE_PART_T; OBSTACLES: OBSTACLE_ARRAY_T; QTD_OBSTACLES: INTEGER)
	RETURN BOOLEAN IS
		VARIABLE VAI_COLIDIR: BOOLEAN := FALSE;
	BEGIN
		FOR I IN 0 TO QTD_OBSTACLES-1 LOOP
			VAI_COLIDIR := (PART.HORIZONTAL_DIRECTION = MOVING_RIGHT AND PART.CUR_POSIT+1 = OBSTACLES(I).CUR_POSIT)
									OR (PART.HORIZONTAL_DIRECTION = MOVING_LEFT AND PART.CUR_POSIT-1 = OBSTACLES(I).CUR_POSIT);
			IF(VAI_COLIDIR) THEN
				RETURN TRUE;
			END IF;
				
		END LOOP;
		RETURN FALSE;
	END;

	FUNCTION INICIALIZA_ARRAY_OBSTACLE(QTD: INTEGER) RETURN OBSTACLE_ARRAY_T IS
		VARIABLE RETORNO: OBSTACLE_ARRAY_T;
	BEGIN
		FOR I IN QTD-1 DOWNTO 0 LOOP
			RETORNO(I).CUR_POSIT := 0;
			RETORNO(I).LIFE := 0;
			RETORNO(I).CHAR := 0;
			RETORNO(I).COLOR := 0;
		END LOOP;
		RETURN RETORNO;
	END;

	FUNCTION MILLIPEDE_VAI_ACERTAR_OBSTACULO(PARTE: MILLIPEDE_PART_T) RETURN BOOLEAN IS 
	BEGIN
		RETURN FALSE;
	END MILLIPEDE_VAI_ACERTAR_OBSTACULO;
	
	FUNCTION MILLIPEDE_VAI_ATINGIR_EXTREMO_HORIZONTAL(PARTE: MILLIPEDE_PART_T) RETURN BOOLEAN IS
	BEGIN
		IF((PARTE.HORIZONTAL_DIRECTION = MOVING_RIGHT) AND (PARTE.CUR_POSIT+1 MOD 40 >= 39)) THEN
			RETURN TRUE;
		ELSIF((PARTE.HORIZONTAL_DIRECTION = MOVING_LEFT )AND (PARTE.CUR_POSIT-1 MOD 40 <= 0)) THEN
			RETURN TRUE;
		END IF;
		
		RETURN FALSE;
	END MILLIPEDE_VAI_ATINGIR_EXTREMO_HORIZONTAL;
	
	FUNCTION MILLIPEDE_VAI_ATINGIR_EXTREMO_VERTICAL(PARTE: MILLIPEDE_PART_T) RETURN BOOLEAN IS
	BEGIN
		IF((PARTE.VERTICAL_DIRECTION = MOVING_DOWN) AND (PARTE.CUR_POSIT+40 >= 1159)) THEN
			RETURN TRUE;
		ELSIF ((PARTE.VERTICAL_DIRECTION = MOVING_UP) AND (PARTE.CUR_POSIT-40 <= 39)) THEN
			RETURN TRUE;
		END IF;
		
		RETURN FALSE;
	END MILLIPEDE_VAI_ATINGIR_EXTREMO_VERTICAL;
	
	FUNCTION INVERTE_DIRECAO_HORIZONTAL_MILLIPEDE(PARTE: MILLIPEDE_PART_T) RETURN HORIZONTAL_DIRECTION_T IS
	BEGIN
		IF(PARTE.HORIZONTAL_DIRECTION = MOVING_RIGHT) THEN
			RETURN MOVING_LEFT;
		ELSE
			RETURN MOVING_RIGHT;
		END IF;
	END INVERTE_DIRECAO_HORIZONTAL_MILLIPEDE;
	
	FUNCTION INVERTE_DIRECAO_VERTICAL_MILLIPEDE(PARTE: MILLIPEDE_PART_T) RETURN VERTICAL_DIRECTION_T IS
	BEGIN
		IF(PARTE.VERTICAL_DIRECTION = MOVING_DOWN) THEN
			RETURN MOVING_UP;
		ELSE 
			RETURN MOVING_DOWN;
		END IF;
	END INVERTE_DIRECAO_VERTICAL_MILLIPEDE;
		
END MILLIPEDE_PACKAGE;