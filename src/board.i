************************************************************************
**	This file is part of "cdtv device resourced"
**    
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
**  Lesser General Public License for more details.
**
**  You should have received a copy of the GNU Lesser General Public
**  License along with this library; if not, write to the Free Software
**  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
**
************************************************************************

ISTR	EQU $41		;interrupt status		(read only)
CNTR	EQU $43		;control				(read/write)
PBAR	EQU $48		;peripheral base address		(read/write)
PDVD	EQU $4c		;peripheral device disable	(write only)
WTCH	EQU $80		;word transfer count hi		(read/write)
WTCL	EQU $82		;word transfer count lo		(read/write)
SACH	EQU $84		;source address counter hi	(write only)
SACL	EQU $86		;source address counter lo	(write only)
DACH	EQU $88		;destination address counter hi	(write only)
DACL	EQU $8a		;destination address counter lo	(write only)
DAWR	EQU $8f		;data acknowledge width		(read/write)
SDMA    EQU $e0		;start DMA			(strobe)
SRST	EQU $e2		;software reset (stop DMA)	(strobe)
CINT	EQU $e4		;clear interrupts		(strobe)
FDMA    EQU $e8		;strobe to flush DMA		(strobe)
SASR	EQU $91		;SCSI auxiliary status register	(read)
SCMD	EQU $93		;where all other registers appear (read/write)    
SCMDD	EQU $A1     ;Direct access to cmd buffer

UNKN    EQU $C0     ; XT Write Enable  

; TRIPORT
MPS6525_PRA  EQU $b1 
MPS6525_PRB  EQU $b3  
MPS6525_PRC  EQU $b5
MPS6525_DDRA EQU $b7 
MPS6525_DDRB EQU $b9
MPS6525_DDRC EQU $bb
MPS6525_CR   EQU $bd  
MPS6525_AIR  EQU $bf  

; RESET CMD 

SCSI_RESET_CMD  EQU $81
ISTR_PEND       EQU $10
ISTR_EOP        EQU $20

CDTV_MOTOR_OFF  EQU $5
CDTV_MOTOR_ON   EQU $4

PRB_CMD         EQU     0 ; /CMD
PRB_ENABLE      EQU     1 ; /ENABLE
PRB_XAEN        EQU     2 ; /XAEN
PRB_DTEN        EQU     3 ; /DTEN
PRB_WEPROM      EQU     4 ; WEPROM
PRB_DACATT      EQU     5 ; DACATT - to LC7883M pin 9 (ATT)
PRB_DACST       EQU     6 ; DACST - to LC7883M pin 10 (SHIFT)
PRB_DACLCH      EQU     7 ; DACLCH - to LC7883M pin 11 (LATCH)

PRC_STCH        EQU     2 ; /STCH 
PRC_STEN        EQU     3 ; /STEN
