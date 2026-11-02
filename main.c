#include "MKL46Z4.h"

// Hardware:
// SW1 (botón izquierdo)  = PTC3
// SW2 (botón derecho)    = PTC12
// LED_RED                = PTE29
// LED_GREEN              = PTD5

// Estado inicial: 0 (ambos apagados según el enunciado)
volatile int estado = 0;

// --- FUNCIONES LED ROJO (PTE29) ---
void led_red_init(void)
{
    SIM->COPC = 0;                          // Deshabilitar watchdog
    SIM->SCGC5 |= SIM_SCGC5_PORTE_MASK;     // Reloj PORT E
    PORTE->PCR[29] = PORT_PCR_MUX(1);       // Función GPIO
    GPIOE->PDDR |= (1 << 29);               // Salida
    GPIOE->PSOR = (1 << 29);                // Apagar (activos a nivel bajo)
}

void led_red_on(void)
{
    GPIOE->PCOR = (1 << 29);                // Nivel bajo encender
}

void led_red_off(void)
{
    GPIOE->PSOR = (1 << 29);                // Nivel alto apagar
}

// --- FUNCIONES LED VERDE (PTD5) ---
void led_green_init(void)
{
    SIM->SCGC5 |= SIM_SCGC5_PORTD_MASK;     // Reloj PORT D
    PORTD->PCR[5] = PORT_PCR_MUX(1);        // Función GPIO
    GPIOD->PDDR |= (1 << 5);                // Salida
    GPIOD->PSOR = (1 << 5);                 // Apagar
}

void led_green_on(void)
{
    GPIOD->PCOR = (1 << 5);                 // Nivel bajo encender
}

void led_green_off(void)
{
    GPIOD->PSOR = (1 << 5);                 // Nivel alto apagar
}

// --- ACTUALIZACIÓN DE SALIDAS DEL AUTÓMATA ---
void actualizar_leds(void)
{
    switch (estado) {
        case 0: // Ambos apagados
            led_red_off();
            led_green_off();
            break;
        case 1: // Rojo encendido, verde apagado
            led_red_on();
            led_green_off();
            break;
        case 2: // Ambos encendidos
            led_red_on();
            led_green_on();
            break;
        case 3: // Rojo apagado, verde encendido
            led_red_off();
            led_green_on();
            break;
    }
}

// --- CONFIGURACIÓN DE BOTONES (PTC3 Y PTC12) ---
void buttons_init(void)
{
    SIM->SCGC5 |= SIM_SCGC5_PORTC_MASK;     // Reloj PORT C

    // SW1 (PTC3): GPIO + Pull-up + Interrupción en Flanco de Bajada (0xA)
    PORTC->PCR[3] = PORT_PCR_MUX(1) | PORT_PCR_PE_MASK | PORT_PCR_PS_MASK | PORT_PCR_IRQC(0xA);
    GPIOC->PDDR &= ~(1 << 3);              

    // SW2 (PTC12): GPIO + Pull-up + Interrupción en Flanco de Bajada (0xA)[cite: 26, 32]
    PORTC->PCR[12] = PORT_PCR_MUX(1) | PORT_PCR_PE_MASK | PORT_PCR_PS_MASK | PORT_PCR_IRQC(0xA);
    GPIOC->PDDR &= ~(1 << 12);              

    // Habilitar IRQ #31 (PORTC/PORTD) en el NVIC
    NVIC_EnableIRQ(PORTC_PORTD_IRQn);       
}

// --- RUTINA DE INTERRUPCIÓN (ISR) ---
// Sin "static" para sobrescribir la rutina débil de startup.c
void PORTDIntHandler(void)                  
{  
    if (PORTC->ISFR & (1 << 3)) {
        PORTC->ISFR = (1 << 3);             // Limpiar el flag de la interrupción
        
        estado = (estado + 1) % 4;          // Avanza la secuencia
        actualizar_leds();
    }

    if (PORTC->ISFR & (1 << 12)) {
        PORTC->ISFR = (1 << 12);            // Limpiar el flag de la interrupción
        
        estado = (estado + 3) % 4;          // Retrocede la secuencia
        actualizar_leds();
    }
}

int main(void)
{
    led_green_init();
    led_red_init();
    buttons_init();

    actualizar_leds();

    while(1) {
    }

    return 0;
}