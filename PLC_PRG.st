// ==========================================
// 1. МОРГАНИЕ СИГНАЛА (Генератор импульсов)
// ==========================================
fbBlink(IN := NOT fbBlink.Q, PT := GVL.T_BLINKING);
IF fbBlink.Q THEN 
    xBlinkPulse := NOT xBlinkPulse; 
END_IF;
xB := xBlinkPulse; 

// ==========================================
// 2. КОНЕЧНЫЙ АВТОМАТ СВЕТОФОРОВ (8 ФАЗ)
// ==========================================
CASE iState OF
    1:  // С1: Зеленый, С2: Красный
        tStateDuration := GVL.T_GREEN_ON;    
        stLight1 := FC_SetLights(FALSE, FALSE, TRUE);  
        stLight2 := FC_SetLights(TRUE, FALSE, FALSE);  
        IF fbTimer.Q THEN iState := 2; xResetTimer := TRUE; END_IF;

    2:  // С1: Зеленый мигает, С2: Красный
        tStateDuration := GVL.T_GREEN_BLINK; 
        stLight1 := FC_SetLights(FALSE, FALSE, xB); 
        stLight2 := FC_SetLights(TRUE, FALSE, FALSE);  
        IF fbTimer.Q THEN iState := 3; xResetTimer := TRUE; END_IF;

    3:  // С1: Желтый, С2: Красный (Рассинхрон)
        tStateDuration := GVL.T_YELLOW_ON;   
        stLight1 := FC_SetLights(FALSE, TRUE, FALSE);  
        stLight2 := FC_SetLights(TRUE, FALSE, FALSE); 
        IF fbTimer.Q THEN iState := 4; xResetTimer := TRUE; END_IF;

    4:  // С1: Красный, С2: Красный + Желтый
        tStateDuration := GVL.T_YELLOW_ON;   
        stLight1 := FC_SetLights(TRUE, FALSE, FALSE);  
        stLight2 := FC_SetLights(TRUE, TRUE, FALSE); 
        IF fbTimer.Q THEN iState := 5; xResetTimer := TRUE; END_IF;

    5:  // С1: Красный, С2: Зеленый
        tStateDuration := GVL.T_GREEN_ON;    
        stLight1 := FC_SetLights(TRUE, FALSE, FALSE);  
        stLight2 := FC_SetLights(FALSE, FALSE, TRUE);  
        IF fbTimer.Q THEN iState := 6; xResetTimer := TRUE; END_IF;

    6:  // С1: Красный, С2: Зеленый мигает
        tStateDuration := GVL.T_GREEN_BLINK; 
        stLight1 := FC_SetLights(TRUE, FALSE, FALSE);  
        stLight2 := FC_SetLights(FALSE, FALSE, xB); 
        IF fbTimer.Q THEN iState := 7; xResetTimer := TRUE; END_IF;

    7:  // С1: Красный, С2: Желтый
        tStateDuration := GVL.T_YELLOW_ON;   
        stLight1 := FC_SetLights(TRUE, FALSE, FALSE);  
        stLight2 := FC_SetLights(FALSE, TRUE, FALSE); 
        IF fbTimer.Q THEN iState := 8; xResetTimer := TRUE; END_IF;

    8:  // С1: Красный + Желтый, С2: Красный
        tStateDuration := GVL.T_YELLOW_ON;   
        stLight1 := FC_SetLights(TRUE, TRUE, FALSE);  
        stLight2 := FC_SetLights(TRUE, FALSE, FALSE); 
        IF fbTimer.Q THEN iState := 1; xResetTimer := TRUE; END_IF;
ELSE
    iState := 1;
    xResetTimer := TRUE;
END_CASE;

// Основной таймер текущей фазы
fbTimer(IN := NOT xResetTimer, PT := tStateDuration);
xResetTimer := FALSE; 

// ==========================================
// 3. РАСЧЕТ ТАЙМЕРОВ ОСТАВШЕГОСЯ ВРЕМЕНИ ДЛЯ ТАБЛО
// ==========================================

// --- СВЕТОФОР 1 ---
CASE iState OF
    // считаем время до включения красного
    1: tTimeLeft1 := (GVL.T_GREEN_ON + GVL.T_GREEN_BLINK + GVL.T_YELLOW_ON) - fbTimer.ET;
    2: tTimeLeft1 := (GVL.T_GREEN_BLINK + GVL.T_YELLOW_ON) - fbTimer.ET;
    3: tTimeLeft1 := (GVL.T_YELLOW_ON) - fbTimer.ET;
    
    // считаем время до включения зеленого
    4: tTimeLeft1 := (GVL.T_YELLOW_ON + GVL.T_GREEN_ON + GVL.T_GREEN_BLINK + GVL.T_YELLOW_ON + GVL.T_YELLOW_ON) - fbTimer.ET;
    5: tTimeLeft1 := (GVL.T_GREEN_ON + GVL.T_GREEN_BLINK + GVL.T_YELLOW_ON + GVL.T_YELLOW_ON) - fbTimer.ET;
    6: tTimeLeft1 := (GVL.T_GREEN_BLINK + GVL.T_YELLOW_ON + GVL.T_YELLOW_ON) - fbTimer.ET;
    7: tTimeLeft1 := (GVL.T_YELLOW_ON + GVL.T_YELLOW_ON) - fbTimer.ET;
    8: tTimeLeft1 := (GVL.T_YELLOW_ON) - fbTimer.ET; // Время К+Ж фазы
END_CASE;

// --- СВЕТОФОР 2 ---
CASE iState OF
    // считаем время до включения красного
    1: tTimeLeft2 := (GVL.T_GREEN_ON + GVL.T_GREEN_BLINK + GVL.T_YELLOW_ON + GVL.T_YELLOW_ON) - fbTimer.ET;
    2: tTimeLeft2 := (GVL.T_GREEN_BLINK + GVL.T_YELLOW_ON + GVL.T_YELLOW_ON) - fbTimer.ET;
    3: tTimeLeft2 := (GVL.T_YELLOW_ON + GVL.T_YELLOW_ON) - fbTimer.ET;
    4: tTimeLeft2 := (GVL.T_YELLOW_ON) - fbTimer.ET; // Время К+Ж фазы
    
    // считаем время до включения зеленого
    5: tTimeLeft2 := (GVL.T_GREEN_ON + GVL.T_GREEN_BLINK + GVL.T_YELLOW_ON) - fbTimer.ET;
    6: tTimeLeft2 := (GVL.T_GREEN_BLINK + GVL.T_YELLOW_ON) - fbTimer.ET;
    7: tTimeLeft2 := (GVL.T_YELLOW_ON) - fbTimer.ET;
    8: tTimeLeft2 := (GVL.T_YELLOW_ON + GVL.T_GREEN_ON + GVL.T_GREEN_BLINK + GVL.T_YELLOW_ON + GVL.T_YELLOW_ON) - fbTimer.ET;
END_CASE;

// Округление 
iTimeLeftSec1 := TIME_TO_INT(tTimeLeft1 + T#999MS) / 1000;
iTimeLeftSec1 := MAX(iTimeLeftSec1, 1);

iTimeLeftSec2 := TIME_TO_INT(tTimeLeft2 + T#999MS) / 1000;
iTimeLeftSec2 := MAX(iTimeLeftSec2, 1);
