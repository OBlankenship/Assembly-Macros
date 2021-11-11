; Author: Oliver J. Blankenship
; Last Modified: 8/9/2021
; Description: Collects 10 string representations of signed integers from the user, converts them to integers, stores them in an array,
; and displays the array, and the sum and average of the array.

INCLUDE Irvine32.inc

MAXSTRING = 20

.data
intro1		BYTE "String Primitives and Macros by Oliver J. Blankenship",0
intro2		BYTE "This program collects 10 string representations of signed integers from the user, converts them to integers, and stores the in an array.",0
intro3		BYTE "The array is then displayed, and the sum and average of the array are calculated and displayed.",0
prompt		BYTE "Please enter 10 signed integers: ",0
invalid		BYTE "Invalid Input! Must be a signed integer.",0
goodbye		BYTE "Program terminating! Goodbye!",0
printInfo	BYTE "You entered the following numbers: ",0
sumMsg		BYTE "The sum of the entered numbers is: ",0
avgMsg		BYTE "The average of the entered numbers is: ",0
space		BYTE " ",0
currentVal	BYTE MAXSTRING DUP(?)	; Stores the current value in STRING form
currentInt  SDWORD ?				; Stores the current value in INT form
array		SDWORD 10 DUP(?)		; The array that contains the 10 user entered numbers
bytesRead	DWORD ?					; Contains the number of bytes read by mGetString
isNeg		DWORD 0					; 1 if the value is negative, 0 if the value is positive
writeRev	BYTE MAXSTRING DUP(?)	; Contains the current value to be written in reversed formed
writeOut	BYTE MAXSTRING DUP(?)	; Contains the current value to be written
sum			SDWORD 0				; Contains a running total of the user entered numbers

.code
; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Generates Prompts the user, retreives a string, and returns the memory address
;	of the string, and the number of bytes read.
;
; Preconditions: EDX contains a string with a prompt. promptAddress, currentValAddress, and 
; bytesReadAddress are all valid addresses.
;
; Receives:
; promptAddress = address of the prompt to display
; currentValAddress = address where the read string will be stored
; bytesReadAddress = address where the number of bytes read will be stored
;
; returns: 
; currentValAddress = address where the read string will be stored
; bytesReadAddress = address where the number of bytes read will be stored
; ---------------------------------------------------------------------------------
mGetString MACRO promptAddress, currentValAddress, bytesReadAddress
	; Saves registers
	PUSH EDX
	PUSH ECX
	PUSH EAX
	; Displays a prompt to the user
	MOV EDX, promptAddress
	CALL WriteString
	CALL CrLF
	; Reads a string from the user, and stores it at currentValAddress
	MOV ECX, MAXSTRING
	MOV EDX, currentValAddress
	CALL ReadString
	; Sets the variables to be returned
	MOV currentValAddress, EDX
	MOV bytesReadAddress, EAX
	; Restores registers
	POP EAX
	POP ECX
	POP EDX
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays the string located at the provided memory address
;
; Preconditions: EDX contains a valid string to display
;
; Receives:
; outputAddress = address of the string to display
;
; returns: None
; ---------------------------------------------------------------------------------
mDisplayString MACRO outputAddress
	; Saves registers
	PUSH EDX
	; Prints the string stored at outputAddress
	MOV EDX, outputAddress
	CALL WriteString
	; Restores registers
	POP EDX
ENDM

; ---------------------------------------------------------------------------------
; Name: main
;
; Displays introductory messages to the user, then loops 10 times to collect values from the user using ReadVal.
; Then loops ten more times to display the values using WriteVal. The sum is also calculated during this loop.
; Finally the average is calculated and displayed. 
;
; Preconditions: None
;
; Postconditions: Program terminates gracefully
;
; Receives: None
;
; Returns: None
; ---------------------------------------------------------------------------------
main PROC
	; Displays program title and programmer name
	MOV EDX, OFFSET intro1
	CALL WriteString
	CALL CrLF
	; Displays program introduction
	MOV EDX, OFFSET intro2
	CALL WriteString
	CALL CrLF
	MOV EDX, OFFSET intro3
	CALL WriteString
	CALL CrLF
	CALL CrLF
	; Sets the counter to 10, and sets ESI to the location of the array
	MOV ECX, 10
	MOV ESI, OFFSET array
_collectValues:
	; Calls ReadVal procedure to collect the next value from the user
	PUSH OFFSET currentInt
	PUSH OFFSET isNeg
	PUSH OFFSET invalid
	PUSH OFFSET bytesRead
	PUSH OFFSET currentVal
	PUSH OFFSET prompt
	CALL ReadVal
	; Stores the read value in the current position of array
	MOV EAX, currentInt
	MOV [ESI], EAX
	ADD ESI, 4
	ADD sum, EAX
	LOOP _collectValues
	; Resets ECX and ESI to begin looping through the array
	MOV ECX, 10
	MOV ESI, OFFSET array
	; Displays a message to the user 
	MOV EDX, OFFSET printInfo
	CALL WriteString
	CALL CrLF
_printArray:
	; Moves the current element of the array into currentInt
	MOV EAX, [ESI]
	MOV currentInt, EAX
	; Calls WriteVal to print the current element in array
	PUSH OFFSET isNeg
	PUSH OFFSET writeOut
	PUSH OFFSET writeRev
	PUSH currentInt
	CALL WriteVal
	; Increments array, and prints a space
	ADD ESI, 4
	MOV EDX, OFFSET space
	CALL WriteString
	LOOP _printArray
	CALL CrLF
	; Displays the sum
	MOV EDX, OFFSET sumMsg
	CALL WriteString
	MOV EAX, sum
	MOV currentInt, EAX
	PUSH OFFSET isNeg
	PUSH OFFSET writeOut
	PUSH OFFSET writeRev
	PUSH currentInt
	CALL WriteVal
	CALL CrLF
	; Calculates the average
	MOV EBX, 10
	CDQ
	IDIV EBX
	; Displays the average
	MOV EDX, OFFSET avgMsg
	CALL WriteString
	MOV currentInt, EAX
	PUSH OFFSET isNeg
	PUSH OFFSET writeOut
	PUSH OFFSET writeRev
	PUSH currentInt
	CALL WriteVal
	CALL CrLF
	; Displays a farewell message and terminates the program
	MOV EDX, OFFSET goodbye
	CALL WriteString
	Invoke ExitProcess,0
main ENDP


; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Uses mGetString to read a string from the user. Validates to ensure it is the string representation of an integer.
; Then converts the string to a decimal representation.
;
; Preconditions: None
;
; Postconditions: None 
;
; Receives:
; OFFSET currentInt = Memory location which will contain the current value in integer form (post-conversion)
; OFFSET isNeg = Memory location containg a flag to delineate negative values
; OFFSET invalid = Memory location containing a prompt informting the user that the entry is invalid
; OFFSET bytesRead = Memory location which will contain the number of bytes read
; OFFSET currentVal = Memory location where the current val will be stored in string form
; OFFSET prompt = Memory location containing a prompt to display to the user
;
; Returns:
; OFFSET currentInt = Memory location containing the converted integer
; ---------------------------------------------------------------------------------
ReadVal PROC USES EAX EBX ECX EDX EDI ESI 
	; Preserve EBP, and set EBP to ESP
	PUSH EBP
	MOV EBP, ESP
_getString:
	; Sets isNeg flag to 0
	MOV EDX, [EBP + 48]
	MOV EBX, 0
	MOV [EDX], EBX
	; Calls mGetString with the OFFSET of the prompt, the OFFSET of the currentVal, and the OFFSET of bytesRead
	mGetString [EBP + 32], [EBP + 36], [EBP + 40]
	; Sets ESI to the OFFSET of currentVal, resets the accumulator, and sets ECX to the number of bytes read
	MOV ESI, [EBP + 36]
	MOV EDI, 0
	MOV ECX, [EBP + 40]
_loopCharacters:
	; Resets EAX, EDX, and loads the next value
	MOV EDX, 10
	MOV EAX, 0
	LODSB
	; Converts a position from ASCII to decimal. Also checks for +/- signs
	CMP EAX, 43
	JE _signedPos
	CMP EAX, 45
	JE _signedNeg
	CMP EAX, 48
	JL _invalid
	CMP EAX, 57
	JG _invalid
	SUB EAX, 48
	; Multiplies the current value of the accumulator (EDI) by 10
	MOV EBX, EAX
	MOV EAX, EDI
	MUL EDX
	JO _invalid
	MOV EDI, EAX
	; Adds the next digit to the accumulator (EDI)
	ADD EDI, EBX
	JO _invalid
	JMP _signedPos
_signedNeg:
	; Sets isNeg flag to 1
	MOV EDX, [EBP + 48]
	MOV EBX, 1
	MOV [EDX], EBX 
_signedPos:
	LOOP _loopCharacters
	JMP _finished

_invalid:
	; Displays an error message for invalid entries
	MOV EDX, [EBP + 44]
	CALL WriteString
	CALL CrLF
	JMP _getString
_finished:
	; Checks if the isNeg flag is set for this number
	MOV EDX, [EBP + 48]
	MOV EBX, 0
	CMP [EDX], EBX
	JE _noNegate
	; If so, negates the value
	NEG EDI
_noNegate:
	; Moves the final result into currentInt
	MOV EAX, [EBP + 52]
	MOV [EAX], EDI
	; Restores EBP and returns to main
	POP EBP
	RET 24
ReadVal ENDP


; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Takes an integer, converts it to a string representation, and displays it to the user.
;
; Preconditions: currentInt contains a valid signed integer
;
; Postconditions: None
;
; Receives:
; OFFSET isNeg = Memory location containg a flag to delineate negative values
; OFFSET writeOut = The memory location where the string representation will be stored (in correct order)
; OFFSET writeRev = The memory location where the string representation will be stored in reversed orientation
; currentInt = The current integer which will be converted back to a string representation
;
; Returns: None
; ---------------------------------------------------------------------------------
WriteVal PROC USES EAX EBX ECX EDX ESI EDI
	; Preserve EBP, and set EBP to ESP
	PUSH EBP
	MOV EBP, ESP
	; Sets EDI to OFFSET writeRev, and sets EAX to the currentInt to write
	MOV EAX, [EBP + 32]
	MOV EDI, [EBP + 36]
	MOV ESI, 0
	; Resets isNeg flag to 0
	MOV EBX, [EBP + 44]
	MOV [EBX], ESI 
	; Checks if the current integer is negative
	CMP EAX, 0
	JNS _divisionLoop
	; If the integer is negative, negates the integer, and sets a flag that the value should be negative
	NEG EAX
	MOV EDX, 1
	MOV EBX, [EBP + 44]
	MOV [EBX], EDX
_divisionLoop:
	; Divies the current value by 10
	MOV ECX, 10
	CDQ
	IDIV ECX
	; Preserves the result in EBX, while the remainder is transferred to EAX
	MOV EBX, EAX
	MOV EAX, EDX
	; The remainder is converted from integer to ASCII and stored in writeRev
	ADD EAX, 48
	STOSB
	ADD ESI, 1
	MOV EAX, EBX
	; Terminates the loop once the result is 0
	CMP EAX, 0
	JNE _divisionLoop
	; Sets ECX to the number of places in the integer
	MOV ECX, ESI
	; Configures ESI and EDI for string reversal
	MOV ESI, EDI
	SUB ESI, 1
	; Checks if the isNeg flag is set
	MOV EDI, [EBP + 40]
	MOV EDX, 1
	MOV EBX, [EBP + 44]
	CMP [EBX], EDX
	JNE _reverseString
	; Handles adding of a negative sign for negative integers
	MOV EDX, 45
	ADD ESI, 1
	MOV [ESI], EDX
	ADD ECX, 1
_reverseString:
	; Reverses the string in writeRev and outputs to writeOut
	STD
	LODSB
	CLD
	STOSB
	LOOP _reverseString
	; Call mDisplayString to output the current integer (currently stored in string form)
	mDisplayString [EBP + 40]
	; Clears writeRev
	MOV EDI, [EBP + 36]
	MOV EAX, 0
	MOV ECX, MAXSTRING
	REP STOSB
	; Clears writeOut
	MOV EDI, [EBP + 40]
	MOV EAX, 0
	MOV ECX, MAXSTRING
	REP STOSB
	; Restores EBP and returns to main
	POP EBP
	RET 16
WriteVal ENDP

END main