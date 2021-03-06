    include whdmacros.i
    INCLUDE "lvo/expansion.i"
    INCLUDE "lvo/exec.i"
    include cd.i
    include board.i

        INCLUDE "libraries/configregs.i"
        INCLUDE "libraries/configvars.i"

MANUFACTURER    EQU     $202
PRODUCT         EQU     $3
        
hb  equr  a5    
start:
    lea     ExpanName(pc),a1 ; first, find our board
    moveq.l #0,d0           ;using any expansion.library
    move.l  $4,a6
    jsr      (_LVOOpenLibrary,a6)

    tst.l   d0 ; make sure we got it
    beq.w   .error

    movea.l d0,a6
    suba.l  a0,a0 ; clear a0
    movem.l ManuProd(pc),d0-d1
    jsr      (_LVOFindConfigDev,a6)

    movea.l d0,hb ; A5 contains the config dev struct
    
    
    movea.l a6,a1
    move.l  $4,a6

    jsr      (_LVOCloseLibrary,a6)

    move.l  hb,d0 ; exit if the board was not found
    beq.w   .error

.loop
    movea.l cd_BoardAddr(hb),hb   ; $E90000
    
    bsr.w   InitBoardHW
    moveq.l #0,d0
    rts
    
.error
       moveq.l  #1,d0
       rts

******************************************************************
*
* InitBoardHW - Initialize the hardware?
*
******************************************************************

InitBoardHW:                               ; CODE XREF: InitDevice+44↑p
                                        ; DoDriveReset↑p
                                        
                move.l  #$DEADBEEF,$60000
                move.l  #$DEADBEEF,$607FC
                move.l  #$DEADBEEF,$60800
                bsr.w   Disable
                move.b  #0,MPS6525_DDRA(hb)
                move.b  #$FF,MPS6525_PRB(hb)
                move.b  #$FF,MPS6525_DDRB(hb)
                move.b  #$20,MPS6525_PRC(hb)
                move.b  #0,MPS6525_DDRC(hb)
                bsr.w   MuteCD

                bsr.w   Enable
                
                bsr startDrive
                bsr ReadSectors
                
                rts
                
MuteCD:                               ; CODE XREF: CODE:00000B88↑p
                                        ; CODE:00000B9C↑p ...
                movem.l d0-d1/a0-a1,-(a7)
                moveq   #0,d0
                bsr   SetVolume
                movem.l (a7)+,d0-d1/a0-a1
                rts

startDrive:                               ; CODE XREF: CmdStart↑p
                bsr.w   Disable
                move.b  #0,MPS6525_DDRA(hb)
                move.b  #$FF,MPS6525_PRB(hb)
                move.b  #$FF,MPS6525_DDRB(hb)
                move.b  #$20,MPS6525_PRC(hb)
                move.b  #0,MPS6525_DDRC(hb)
                move.b  #$F1,MPS6525_CR(hb)
                move.b  #$2E,MPS6525_DDRC(hb)
                move.b  #0,MPS6525_PRC(hb)
                move.b  MPS6525_AIR(hb),d0
                bsr.w   MuteCD

                bsr.w   Enable
                rts


stopDrive:
                move.b  #0,MPS6525_DDRC(hb)
                move.b  #$F0,MPS6525_CR(hb)
                rts
                
ReadSectors:                                ; CODE XREF: CmdRead+66↑p
                                        ; CmdRead+96↑p
                bsr.w   RefreshMuteState
                bsr.w   NewPutPacket
                move.l  #$4A83580/$800,4(a0)    ; start sector
                move.w  #1,8(a0)    ; nb sectors
                move.b  #2,4(a0) ; CMD is 02
                bsr.w   SCSIPut
                bsr.w   Disable

        move.w  #0,$DFF09C
                move.l  #$60000,d1
                move.l  #$800,d0
                bsr     StartDMAXfer
.loop                
        move.w  #$0F0,$DFF180
                move.w  $DFF01E,d0
                btst    #3,d0
                beq.b   .loop
                moveq   #ISTR_PEND|ISTR_EOP,d0
                and.b   ISTR(hb),d0 ; pending interrupt?

                cmpi.b  #ISTR_PEND|ISTR_EOP,d0
                bne   .loop

                move.w  d0,FDMA(hb)

                blitz
                
                bsr.w   Enable
                rts
RefreshMuteState:                               ; CODE XREF: ReadSectors↑p
                ;btst    #2,$141(db)
                ;beq.s   .exit
                bsr.w   MuteCD
.exit:                            
                rts     

SCSIPut:
                ; first byte is the number of bytes to send
                move.l  (a0)+,d1

SCSIPutNoHdr:                               ; CODE XREF: CODE:00000DD6↑p
                bsr.w   Disable
                andi.b  #$FC,MPS6525_PRB(hb)
                bra.s   .loop_start

                ; loop over each byte in the buffer 
.loop_next                               ; CODE XREF: SCSIPut:$1↓j
                move.b  (a0)+,d0
                move.b  d0,SCMDD(hb)
.loop_start                               ; CODE XREF: SCSIPut+C↑j
                dbf     d1,.loop_next
                ori.b   #3,MPS6525_PRB(hb)
                bsr.w   Enable
                rts

; D0: size in ???
; D1: out buffer

StartDMAXfer
                bsr.w   Disable
                bclr    #PRB_ENABLE,MPS6525_PRB(hb)
                bset    #PRB_CMD,MPS6525_PRB(hb)
                              ; CODE XREF: ProcessCDXLNode+50↑p
                lsr.l   #1,d0

                move.l  d0,WTCH(hb)
                move.l  d1,SACH(hb)
                move.b  #0,DAWR(hb)     ; unknown 145(db) offset
                move.b  #$90,CNTR(hb)
                move.w  d0,SDMA(hb)

                bsr.w   Enable
                rts
 
FlushDMA:
                ori.b   #3,MPS6525_PRB(hb)
                bclr    #4,CNTR(hb)

                moveq   #0,d0
 
                move.w  d0,FDMA(hb) ; flush dma
                move.w  d0,SRST(hb) ; software reset
                move.l  d0,WTCH(hb)
                move.w  d0,CINT(hb)

                rts 
************************************************************************
***
***  NewPutPacket - Create a new empty drive "put" packet
***
***  d0 - packet command byte
***  a0 - result
***
************************************************************************

NewPutPacket:                              
                lea     db_SCSICommand(pc),a0
                move.l  #7,(a0) ; Command length
                clr.l   4(a0) ; empty the first 4 bytes
                clr.l   8(a0) ; empty the second 4 bytes
                move.b  d0,4(a0) ; set the command in the first cmd byte. 
                rts

db_SCSICommand
                    ds.b    $6E-$4A,0
                    
************************************************************************
***
***  SetVolume - Actually Set the CD Play Volume on the drive
***
************************************************************************

SetVolume:                               ; CODE XREF: CODE:00000DA6↑p
                                        ; CODE:00000DC8↑p ...
                bsr.w   Disable
                lsr.w   #1,d0
                andi.w  #$3FF0,d0
                ;;;;or.w    db_VolumeLSB(db),d0
                moveq   #$F,d1

.loop:                               ; CODE XREF: SetVolume+30↓j
                asr.w   #1,d0
                bcc.s   .1
                bset    #PRB_DACATT,MPS6525_PRB(hb)
                bra.w   .2

.1 :                               ; CODE XREF: SetVolume+12↑j
                bclr    #PRB_DACATT,MPS6525_PRB(hb)

.2                                ; CODE XREF: SetVolume+1A↑j
                bclr    #PRB_DACST,MPS6525_PRB(hb)
                bset    #PRB_DACST,MPS6525_PRB(hb)
                dbf     d1,.loop
                bclr    #PRB_DACLCH,MPS6525_PRB(hb)
                bset    #PRB_DACLCH,MPS6525_PRB(hb)
                bsr.w   Enable
                rts

                
Disable
        move.l  $4,a6
        jsr (_LVODisable,a6)
        rts
Enable
        move.l  $4,a6
        jsr (_LVOEnable,a6)
        rts
        
ExpanName:      dc.b 'expansion.library',0              
                dc.b   0
       even
ManuProd:       dc.l MANUFACTURER             
                dc.l PRODUCT       