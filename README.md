# 1wire
1-Wire - UART converter

## Introduction

This project is FPGA implementation of 1-Wire interface manged over UART. 

It supports access to up to eight 1-Wire busses powered with external power supply.

### Known problems with design

Should be noticed that using separate bus control FSM for each bus is useless, but I wanted to use for/generate construction on
component so much that I couldn't help it.

## Command format

Each command contains of 2 bytes: high contains management information and low one - data payload.

Detaild view of high byte:

* Bits 7-5 - 1-Wire interface address;
* Bits 4-3 - Status. Bit 4 - CRC calculating result: 0 for ok and 1 for error. Bit 3 - general error bit: 0 for ok and 1 for error.
* Bits 2-0 - Command to 1-Wire interface.

Following commannds are cupported:

* 001 - Reset bus;
* 010 - Read bit from bus;
* 110 - Read 8 bits from bus;
* 011 - Write bit to bus;
* 111 - Write 8 bits to bus;

If we are talking about errors, general error is reported only if bus is cuted out or if resetting bus fails. CRC error bit shoud be ignored if you don't expect CRC calculation result on this step.
