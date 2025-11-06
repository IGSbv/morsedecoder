FPGA-Based Morse Code Decoder
This project is a real-time Morse code decoder implemented in Verilog for the Tang Nano 9K FPGA. It features an analog signal conditioning front-end to ensure clean, noise-free input from a standard push button. The FPGA decodes Morse timings (dots, dashes, and gaps) and transmits the corresponding ASCII characters to a computer via UART.





This system was developed as part of the BECE102L – Digital System Design course at VIT University, Chennai.


📋 Project Overview
The system is split into two main parts:


Analog Front-End: A push button input is fed into an MCP6004 op-amp configured as a Schmitt trigger comparator. This circuit cleans up the noisy and "bouncy" signal from the mechanical switch, converting it into a clean, stable digital pulse for the FPGA.






Digital Processing Unit: The core logic resides on the Tang Nano 9K FPGA. A Finite State Machine (FSM) written in Verilog measures the duration of button presses and gaps. It classifies these timings into dots, dashes, letter gaps, word gaps, and line gaps. A lookup table (LUT) then converts the buffered dot/dash sequences into their ASCII equivalents.






Output: The decoded ASCII characters are sent via a 9600 baud UART interface to a computer , where they can be viewed in any serial terminal (e.g., macOS screen, PuTTY).





✨ Features

Real-Time Decoding: Translates Morse code (A-Z, 0-9) to ASCII in real-time .




Robust Input: Analog Schmitt trigger provides high noise immunity and eliminates switch bounce.




UART Output: Communicates with a host PC via 9600 baud serial (using the Tang Nano's onboard USB-to-UART bridge).




Function Buttons: Includes dedicated inputs for manual space and manual newline.



Destructive Backspace: A special button combination sends a Backspace + Space + Backspace sequence to delete the last character from the terminal .





Clear Screen: A long press (2 seconds) on the Morse key triggers an ANSI clear screen command (ESC[2J) and returns the cursor to the home position (ESC[H) .




⚙️ Hardware & Software
Hardware Components

FPGA: Tang Nano 9K (Gowin GW1NR-LV9) 


Op-Amp: MCP6004 


Switches: 3x Push Button Switches (1 for Morse, 2 for functions) 



Resistors: 100kΩ, 220Ω 


Capacitor: 100nF (0.1µF) 



Misc: Breadboard, Power Supply, Jumper Wires 

Software & Tools

IDE: Gowin IDE 



Terminal: Any serial terminal program (e.g., macOS screen, PuTTY, Arduino Serial Monitor).


Baud Rate: 9600

📐 System Architecture (Verilog Modules)
The project is organized into several distinct Verilog modules:


top.v: The top-level module. It instantiates all other modules, generates the 1ms system tick , debounces the function buttons , and implements the logic for the special button combinations (space, newline, backspace) .






morse_logic.v: The core timing FSM. It takes the clean Morse key input and the 1ms tick, measuring press and gap durations . It outputs single-cycle pulses (new_dot, new_dash, gap_letter, gap_word, gap_line, long_press_clear) when a timing threshold is met .






morse_buffer.v: A shift register that collects the new_dot (as 01) and new_dash (as 10) pulses . It stores the current letter's symbol pattern (symbol_data) and its length (symbol_count). It is cleared by gap triggers or a backspace.





morse_decoder.v: A purely combinational module that acts as a Lookup Table (LUT). It takes the symbol_data and symbol_count from the buffer and instantaneously outputs the corresponding 8-bit ASCII character .




output_controller.v: A high-level FSM that manages what gets sent to the UART. It prioritizes inputs (e.g., backspace over a letter) and sequences multi-byte commands like the ANSI clear screen or destructive backspace .



uart_tx.v: A standard 8-N-1 UART transmitter module configured for 9600 baud (based on a 27MHz system clock).




debouncer.v: A generic, counter-based debouncer module used for the two manual function buttons (btn_space, btn_newline).


🕹️ How to Use (User Interface)
Morse Key (Main Button)

Dot: Short press (< 200ms).




Dash: Long press (> 200ms).




Send Letter: Pause for ~0.4 seconds (400ms) after a dot/dash.



Send Word (Letter + Space): Pause for ~0.7 seconds (700ms).




Send Line (Letter + Newline): Pause for ~1.2 seconds (1200ms).




Clear Screen: Hold the key for 2 seconds (2000ms).


Function Buttons (from top.v) 

Manual Space: Press btn_space (Button 3) while Button 4 is not pressed.

Manual Newline: Press btn_newline (Button 4) while Button 3 is not pressed.

Backspace (Destructive): Hold btn_space (Button 3), then press btn_newline (Button 4).