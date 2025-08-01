// ###################################################################
// #### This file is part of the mathematics library project, and is
// #### offered under the licence agreement described on
// #### http://www.mrsoft.org/
// ####
// #### Copyright:(c) 2011, Michael R. . All rights reserved.
// ####
// #### Unless required by applicable law or agreed to in writing, software
// #### distributed under the License is distributed on an "AS IS" BASIS,
// #### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// #### See the License for the specific language governing permissions and
// #### limitations under the License.
// ###################################################################


unit ASMMoveOperationsx64;

// #################################################
// #### SSE optimized move oprationes
// #################################################

interface

{$I 'mrMath_CPU.inc'}

{$IFDEF x64}

procedure ASMCopyRepMov(Dest : PDouble; const destLineWidth : NativeInt; src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt);
procedure ASMMatrixCopyAlignedEvenW(Dest : PDouble; const destLineWidth : NativeInt; src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
procedure ASMMatrixCopyUnAlignedEvenW(Dest : PDouble; const destLineWidth : NativeInt; src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

procedure ASMMatrixCopyAlignedOddW(Dest : PDouble; const destLineWidth : NativeInt; src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
procedure ASMMatrixCopyUnAlignedOddW(Dest : PDouble; const destLineWidth : NativeInt; src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

procedure ASMRowSwapAlignedEvenW(A, B : PDouble; width : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
procedure ASMRowSwapUnAlignedEvenW(A, B : PDouble; width : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

procedure ASMRowSwapAlignedOddW(A, B : PDouble; width : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
procedure ASMRowSwapUnAlignedOddW(A, B : PDouble; width : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

procedure ASMInitMemAligned(A : PDouble; NumBytes : NativeInt; Value : double); {$IFDEF FPC}assembler;{$ENDIF}

// init matrix in a loop
procedure ASMMatrixInitAligned( dest : PDouble; const destLineWidth : NativeInt; Width, Height : NativeInt; Value : double); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
procedure ASMMatrixInitUnAligned( dest : PDouble; const destLineWidth : NativeInt; Width, Height : NativeInt; Value : double); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}

{$ENDIF}

implementation

{$IFDEF x64}

// rcx = dest, rdx = destLineWidth;  r8 = width, r9 = height
procedure ASMMatrixInitAligned( dest : PDouble; const destLineWidth : NativeInt; Width, Height : NativeInt; Value : double); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
asm
    {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   movddup xmm0, Value;

   //iters := -width*sizeof(double);
   imul r8, -8;

   // helper registers for the src and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // move:
           movapd [rcx + rax - 128], xmm0;
           movapd [rcx + rax - 112], xmm0;
           movapd [rcx + rax - 96], xmm0;
           movapd [rcx + rax - 80], xmm0;
           movapd [rcx + rax - 64], xmm0;
           movapd [rcx + rax - 48], xmm0;
           movapd [rcx + rax - 32], xmm0;
           movapd [rcx + rax - 16], xmm0;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
          add rax, 16;
          jg @loopEnd2;

          movapd [rcx + rax - 16], xmm0;
       jmp @addforxloop2;

       @loopEnd2:
       sub rax, 16;

       jz @nextLine;

       // last element
       movsd [rcx + rax], xmm0;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;
end;

// rcx = dest, rdx = destLineWidth;  r8 = width, r9 = height
procedure ASMMatrixInitUnAligned( dest : PDouble; const destLineWidth : NativeInt; Width, Height : NativeInt; Value : double); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   movddup xmm0, Value;

   //iters := -width*sizeof(double);
   imul r8, -8;

   // helper registers for the src and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // move:
           movupd [rcx + rax - 128], xmm0;
           movupd [rcx + rax - 112], xmm0;
           movupd [rcx + rax - 96], xmm0;
           movupd [rcx + rax - 80], xmm0;
           movupd [rcx + rax - 64], xmm0;
           movupd [rcx + rax - 48], xmm0;
           movupd [rcx + rax - 32], xmm0;
           movupd [rcx + rax - 16], xmm0;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
          add rax, 16;
          jg @loopEnd2;

          movupd [rcx + rax - 16], xmm0;
       jmp @addforxloop2;

       @loopEnd2:
       sub rax, 16;

       jz @nextLine;

       // last element
       movsd [rcx + rax], xmm0;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;
end;


// rcx = A, rdx = NumBytes;
procedure ASMInitMemAligned(A : PDouble; NumBytes : NativeInt; Value : double); {$IFDEF FPC}assembler;{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   movddup xmm1, Value;

   imul rdx, -1;
   sub rcx, rdx;

   @@loopUnrolled:
      add rdx, 128;
      jg @@loopUnrolledEnd;

      movapd [rcx + rdx - 128], xmm1;
      movapd [rcx + rdx - 112], xmm1;
      movapd [rcx + rdx - 96], xmm1;
      movapd [rcx + rdx - 80], xmm1;
      movapd [rcx + rdx - 64], xmm1;
      movapd [rcx + rdx - 48], xmm1;
      movapd [rcx + rdx - 32], xmm1;
      movapd [rcx + rdx - 16], xmm1;
   jmp @@loopUnrolled;

   @@loopUnrolledEnd:

   sub rdx, 128;

   jz @@exitProc;
        
   @@loop:
     movsd [rcx + rdx], xmm1;
     add rdx, 8;
   jnz @@loop;

   @@exitProc:
end;

procedure ASMRowSwapAlignedEvenW(A, B : PDouble; width : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = a, RDX = b, R8 = width
   imul r8, -8;

   sub rcx, r8;
   sub rdx, r8;

   @unrolloop:
     add r8, 64;
     jg @unrolloopend;

     // prefetch data...
     // prefetchw [rcx + r8];
     // prefetchw [rdx + r8];

     movdqa xmm0, [rcx + r8 - 64];
     movdqa xmm1, [rdx + r8 - 64];

     movdqa [rcx + r8 - 64], xmm1;
     movdqa [rdx + r8 - 64], xmm0;

     movdqa xmm2, [rcx + r8 - 48];
     movdqa xmm3, [rdx + r8 - 48];

     movdqa [rcx + r8 - 48], xmm3;
     movdqa [rdx + r8 - 48], xmm2;

     movdqa xmm4, [rcx + r8 - 32];
     movdqa xmm5, [rdx + r8 - 32];

     movdqa [rcx + r8 - 32], xmm5;
     movdqa [rdx + r8 - 32], xmm4;

     movdqa xmm6, [rcx + r8 - 16];
     movdqa xmm7, [rdx + r8 - 16];

     movdqa [rcx + r8 - 16], xmm7;
     movdqa [rdx + r8 - 16], xmm6;
   jmp @unrolloop;
   @unrolloopend:

   sub r8, 64;
   jz @endfunc;


   @loop:
     movdqa xmm0, [rcx + r8];
     movdqa xmm1, [rdx + r8];

     movdqa [rcx + r8], xmm1;
     movdqa [rdx + r8], xmm0;

     add r8, 16;
   jnz @loop;

   @endfunc:
end;

procedure ASMRowSwapUnAlignedEvenW(A, B : PDouble; width : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = a, RDX = b, R8 = width
   imul r8, -8;

   sub rcx, r8;
   sub rdx, r8;

   @unrolloop:
     add r8, 64;
     jg @unrolloopend;

     movdqu xmm0, [rcx + r8 - 64];
     movdqu xmm1, [rdx + r8 - 64];

     movdqu [rcx + r8 - 64], xmm1;
     movdqu [rdx + r8 - 64], xmm0;

     movdqu xmm2, [rcx + r8 - 48];
     movdqu xmm3, [rdx + r8 - 48];

     movdqu [rcx + r8 - 48], xmm3;
     movdqu [rdx + r8 - 48], xmm2;

     movdqu xmm4, [rcx + r8 - 32];
     movdqu xmm5, [rdx + r8 - 32];

     movdqu [rcx + r8 - 32], xmm5;
     movdqu [rdx + r8 - 32], xmm4;

     movdqu xmm6, [rcx + r8 - 16];
     movdqu xmm7, [rdx + r8 - 16];

     movdqu [rcx + r8 - 16], xmm7;
     movdqu [rdx + r8 - 16], xmm6;
   jmp @unrolloop;
   @unrolloopend:

   sub r8, 64;
   jz @endfunc;


   @loop:
     movdqu xmm0, [rcx + r8];
     movdqu xmm1, [rdx + r8];

     movdqu [rcx + r8], xmm1;
     movdqu [rdx + r8], xmm0;

     add r8, 16;
   jnz @loop;

   @endfunc:
end;

procedure ASMRowSwapAlignedOddW(A, B : PDouble; width : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}


   // note: RCX = a, RDX = b, R8 = width
   dec r8;
   imul r8, -8;

   sub rcx, r8;
   sub rdx, r8;

   @unrolloop:
     add r8, 64;
     jg @unrolloopend;

     movdqa xmm0, [rcx + r8 - 64];
     movdqa xmm1, [rdx + r8 - 64];

     movdqa [rcx + r8 - 64], xmm1;
     movdqa [rdx + r8 - 64], xmm0;

     movdqa xmm2, [rcx + r8 - 48];
     movdqa xmm3, [rdx + r8 - 48];

     movdqa [rcx + r8 - 48], xmm3;
     movdqa [rdx + r8 - 48], xmm2;

     movdqa xmm4, [rcx + r8 - 32];
     movdqa xmm5, [rdx + r8 - 32];

     movdqa [rcx + r8 - 32], xmm5;
     movdqa [rdx + r8 - 32], xmm4;

     movdqa xmm6, [rcx + r8 - 16];
     movdqa xmm7, [rdx + r8 - 16];

     movdqa [rcx + r8 - 16], xmm7;
     movdqa [rdx + r8 - 16], xmm6;
   jmp @unrolloop;
   @unrolloopend:

   sub r8, 64;
   jz @endfunc;


   @loop:
     movdqa xmm0, [rcx + r8];
     movdqa xmm1, [rdx + r8];

     movdqa [rcx + r8], xmm1;
     movdqa [rdx + r8], xmm0;

     add r8, 16;
   jnz @loop;

   @endfunc:

   // last swap
   movsd xmm0, [rcx];
   movsd xmm1, [rdx];

   movsd [rcx], xmm1;
   movsd [rdx], xmm0;
end;

procedure ASMRowSwapUnAlignedOddW(A, B : PDouble; width : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = a, RDX = b, R8 = width
   dec r8;
   imul r8, -8;

   sub rcx, r8;
   sub rdx, r8;

   @unrolloop:
     add r8, 64;
     jg @unrolloopend;

     movdqu xmm0, [rcx + r8 - 64];
     movdqu xmm1, [rdx + r8 - 64];

     movdqu [rcx + r8 - 64], xmm1;
     movdqu [rdx + r8 - 64], xmm0;

     movdqu xmm2, [rcx + r8 - 48];
     movdqu xmm3, [rdx + r8 - 48];

     movdqu [rcx + r8 - 48], xmm3;
     movdqu [rdx + r8 - 48], xmm2;

     movdqu xmm4, [rcx + r8 - 32];
     movdqu xmm5, [rdx + r8 - 32];

     movdqu [rcx + r8 - 32], xmm5;
     movdqu [rdx + r8 - 32], xmm4;

     movdqu xmm6, [rcx + r8 - 16];
     movdqu xmm7, [rdx + r8 - 16];

     movdqu [rcx + r8 - 16], xmm7;
     movdqu [rdx + r8 - 16], xmm6;
   jmp @unrolloop;
   @unrolloopend:

   sub r8, 64;
   jz @endfunc;


   @loop:
     movdqu xmm0, [rcx + r8];
     movdqu xmm1, [rdx + r8];

     movdqu [rcx + r8], xmm1;
     movdqu [rdx + r8], xmm0;

     add r8, 16;
   jnz @loop;

   @endfunc:

   // last swap
   movsd xmm0, [rcx];
   movsd xmm1, [rdx];

   movsd [rcx], xmm1;
   movsd [rdx], xmm0;
end;

procedure ASMCopyRepMov(Dest : PDouble; const destLineWidth : NativeInt; src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var aRSI : NativeInt;
    aRDI : NativeInt;
{$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
{$ENDIF}
asm
   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width, r8;
   mov height, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   mov aRSI, rsi;
   mov aRDI, rdi;

   mov rax, rcx;

   CLD;
   // for y := 0 to height - 1:
   @@addforyloop:
       mov rcx, width;
       shl rcx, 3; //*sizeof(double)

       mov rsi, r8;
       mov rdi, rax;

       rep movsb;

       add rax, rdx;
       add r8, r9;

   // loop y end
   dec height;
   jnz @@addforyloop;

   // epilog
   mov rsi, aRSI;
   mov rdi, aRDI;
end;

procedure ASMMatrixCopyAlignedEvenW(Dest : PDouble; const destLineWidth : NativeInt; src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
{$ifdef UNIX}
var width : NativeInt;
    height : NativeInt;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width, r8;
   mov height, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth
   //iters := -width*sizeof(double);
   mov r10, width;
   imul r10, -8;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetchw [rcx + rax];

           // move:
           movdqa xmm0, [r8 + rax - 128];
           movdqa [rcx + rax - 128], xmm0;

           movdqa xmm1, [r8 + rax - 112];
           movdqa [rcx + rax - 112], xmm1;

           movdqa xmm2, [r8 + rax - 96];
           movdqa [rcx + rax - 96], xmm2;

           movdqa xmm3, [r8 + rax - 80];
           movdqa [rcx + rax - 80], xmm3;

           movdqa xmm0, [r8 + rax - 64];
           movdqa [rcx + rax - 64], xmm0;

           movdqa xmm1, [r8 + rax - 48];
           movdqa [rcx + rax - 48], xmm1;

           movdqa xmm2, [r8 + rax - 32];
           movdqa [rcx + rax - 32], xmm2;

           movdqa xmm3, [r8 + rax - 16];
           movdqa [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movdqa xmm0, [r8 + rax];
           movdqa [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;
end;

procedure ASMMatrixCopyUnAlignedEvenW(Dest : PDouble; const destLineWidth : NativeInt; src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
{$ifdef UNIX}
var width : NativeInt;
    height : NativeInt;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width, r8;
   mov height, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 =src, R9 = src
   //iters := -width*sizeof(double);
   mov r10, width;
   imul r10, -8;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // move:
           movdqu xmm0, [r8 + rax - 128];
           movdqu [rcx + rax - 128], xmm0;

           movdqu xmm1, [r8 + rax - 112];
           movdqu [rcx + rax - 112], xmm1;

           movdqu xmm2, [r8 + rax - 96];
           movdqu [rcx + rax - 96], xmm2;

           movdqu xmm3, [r8 + rax - 80];
           movdqu [rcx + rax - 80], xmm3;

           movdqu xmm0, [r8 + rax - 64];
           movdqu [rcx + rax - 64], xmm0;

           movdqu xmm1, [r8 + rax - 48];
           movdqu [rcx + rax - 48], xmm1;

           movdqu xmm2, [r8 + rax - 32];
           movdqu [rcx + rax - 32], xmm2;

           movdqu xmm3, [r8 + rax - 16];
           movdqu [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movdqu xmm0, [r8 + rax];
           movdqu [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;
end;

procedure ASMMatrixCopyAlignedOddW(Dest : PDouble; const destLineWidth : NativeInt; src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
{$ifdef UNIX}
var width : NativeInt;
    height : NativeInt;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width, r8;
   mov height, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth
   //iters := -(width - 1)*sizeof(double);
   mov r10, width;
   dec r10;
   imul r10, -8;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetchw [rcx + rax];

           // move:
           movdqa xmm0, [r8 + rax - 128];
           movdqa [rcx + rax - 128], xmm0;

           movdqa xmm1, [r8 + rax - 112];
           movdqa [rcx + rax - 112], xmm1;

           movdqa xmm2, [r8 + rax - 96];
           movdqa [rcx + rax - 96], xmm2;

           movdqa xmm3, [r8 + rax - 80];
           movdqa [rcx + rax - 80], xmm3;

           movdqa xmm0, [r8 + rax - 64];
           movdqa [rcx + rax - 64], xmm0;

           movdqa xmm1, [r8 + rax - 48];
           movdqa [rcx + rax - 48], xmm1;

           movdqa xmm2, [r8 + rax - 32];
           movdqa [rcx + rax - 32], xmm2;

           movdqa xmm3, [r8 + rax - 16];
           movdqa [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movdqa xmm0, [r8 + rax];
           movdqa [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last element
       movsd xmm0, [r8];
       movsd [rcx], xmm0;

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;
end;

procedure ASMMatrixCopyUnAlignedOddW(Dest : PDouble; const destLineWidth : NativeInt; src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
{$ifdef UNIX}
var width : NativeInt;
    height : NativeInt;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width, r8;
   mov height, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth
   //iters := -(width - 1)*sizeof(double);
   mov r10, width;
   dec r10;
   imul r10, -8;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // move:
           movdqu xmm0, [r8 + rax - 128];
           movdqu [rcx + rax - 128], xmm0;

           movdqu xmm1, [r8 + rax - 112];
           movdqu [rcx + rax - 112], xmm1;

           movdqu xmm2, [r8 + rax - 96];
           movdqu [rcx + rax - 96], xmm2;

           movdqu xmm3, [r8 + rax - 80];
           movdqu [rcx + rax - 80], xmm3;

           movdqu xmm0, [r8 + rax - 64];
           movdqu [rcx + rax - 64], xmm0;

           movdqu xmm1, [r8 + rax - 48];
           movdqu [rcx + rax - 48], xmm1;

           movdqu xmm2, [r8 + rax - 32];
           movdqu [rcx + rax - 32], xmm2;

           movdqu xmm3, [r8 + rax - 16];
           movdqu [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movdqu xmm0, [r8 + rax];
           movdqu [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last element
       movsd xmm0, [r8];
       movsd [rcx], xmm0;

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;
end;

{$ENDIF}

end.
