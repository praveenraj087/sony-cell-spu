ai 0 0 12		//Even pipe structural hazard
ilh 4 -15
ai 1 0 1
ilh 5 -14
ahi 2 2 14
ilh 6 -13
ahi 3 2 1
stqd 1 0(1) 	//Odd pipe structural hazard, plus memory ref
stqd 1 1(1)
stqd 1 2(1)
stqd 1 3(1)
lqa 4 13
lqa 5 14
lqa 6 15
lqa 7 16
ila 25 3		//Set r25 to 3 and decrement
ila 26 0
ai 25 25 -1		//Keep decrementing until r25==0
ai 26 26 1
brnz 25 -2		//Branch hazard resolution, odd destination addr; Also RAW hazard, brnz is stalled 1 cyc until dec r25 finishes
avgb 2 0 1		//Dual issue example
rotqbi 12 4 5
mpy 5 3 4
rotqbi 13 4 0
mpy 8 6 7
rotqbi 14 4 1
mpy 11 9 10
rotqbi 15 4 3
mpy 17 25 26
rotqbi 15 4 2	//Forwarding without stalling
stop			//Stop instr ignores all following instr and ends program
mpy 8 6 7
rotqbi 14 4 1
mpy 11 9 10
rotqbi 15 4 3
mpy 14 22 23