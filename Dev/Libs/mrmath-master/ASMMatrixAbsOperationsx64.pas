// ###################################################################
// #### This file is part of the mathematics library project, and is
// #### offered under the licence agreement described on
// #### http://www.mrsoft.org/
// ####
// #### Copyright:(c) 2017, Michael R. . All rights reserved.
// ####
// #### Unless required by applicable law or agreed to in writing, software
// #### distributed under the License is distributed on an "AS IS" BASIS,
// #### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// #### See the License for the specific language governing permissions and
// #### limitations under the License.
// ###################################################################

unit ASMMatrixAbsOperationsx64;

// #####################################################
// #### Abs opertaion applied to every element in a matrix
// #####################################################

interface

{$I 'mrMath_CPU.inc'}

{$IFDEF x64}

procedure ASMMatrixAbsAlignedEvenW(Dest : PDouble; const LineWidth, Width, Height : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
procedure ASMMatrixAbsUnAlignedEvenW(Dest : PDouble; const LineWidth, Width, Height : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

procedure ASMMatrixAbsAlignedOddW(Dest : PDouble; const LineWidth, Width, Height : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
procedure ASMMatrixAbsUnAlignedOddW(Dest : PDouble; const LineWidth, Width, Height : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

{$ENDIF}

implementation

{$IFDEF x64}

const cLocSignBits : Array[0..1] of int64 = ($7FFFFFFFFFFFFFFF, $7FFFFFFFFFFFFFFF);

procedure ASMMatrixAbsAlignedEvenW(Dest : PDouble; const LineWidth, Width, Height : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
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

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   //iters := -width*sizeof(double);
   imul r8, -8;

   // helper registers for the dest pointer
   sub rcx, r8;

   movupd xmm0, [rip + cLocSignBits];

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           //prefetchw [rcx + rax];

           // Abs:
           movapd xmm4, [rcx + rax - 128];
           Andpd xmm4, xmm0;
           movapd [rcx + rax - 128], xmm4;

           movapd xmm1, [rcx + rax - 112];
           andpd xmm1, xmm0;
           movapd [rcx + rax - 112], xmm1;

           movapd xmm2, [rcx + rax - 96];
           andpd xmm2, xmm0;
           movapd [rcx + rax - 96], xmm2;

           movapd xmm3, [rcx + rax - 80];
           andpd xmm3, xmm0;
           movapd [rcx + rax - 80], xmm3;

           movapd xmm4, [rcx + rax - 64];
           andpd xmm4, xmm0;
           movapd [rcx + rax - 64], xmm4;

           movapd xmm5, [rcx + rax - 48];
           andpd xmm5, xmm0;
           movapd [rcx + rax - 48], xmm5;

           movapd xmm6, [rcx + rax - 32];
           andpd xmm6, xmm0;
           movapd [rcx + rax - 32], xmm6;

           movapd xmm7, [rcx + rax - 16];
           andpd xmm7, xmm0;
           movapd [rcx + rax - 16], xmm7;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movapd xmm7, [rcx + rax];
           andpd xmm7, xmm0;
           movapd [rcx + rax], xmm7;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;
end;

procedure ASMMatrixAbsUnAlignedEvenW(Dest : PDouble; const LineWidth, Width, Height : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
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

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   //iters := -width*sizeof(double);
   imul r8, -8;

   // helper registers for the dest pointer
   sub rcx, r8;

   movupd xmm0, [rip + cLocSignBits];

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // Abs:
           movupd xmm4, [rcx + rax - 128];
           Andpd xmm4, xmm0;
           movupd [rcx + rax - 128], xmm4;

           movupd xmm1, [rcx + rax - 112];
           andpd xmm1, xmm0;
           movupd [rcx + rax - 112], xmm1;

           movupd xmm2, [rcx + rax - 96];
           andpd xmm2, xmm0;
           movupd [rcx + rax - 96], xmm2;

           movupd xmm3, [rcx + rax - 80];
           andpd xmm3, xmm0;
           movupd [rcx + rax - 80], xmm3;

           movupd xmm4, [rcx + rax - 64];
           andpd xmm4, xmm0;
           movupd [rcx + rax - 64], xmm4;

           movupd xmm5, [rcx + rax - 48];
           andpd xmm5, xmm0;
           movupd [rcx + rax - 48], xmm5;

           movupd xmm6, [rcx + rax - 32];
           andpd xmm6, xmm0;
           movupd [rcx + rax - 32], xmm6;

           movupd xmm7, [rcx + rax - 16];
           andpd xmm7, xmm0;
           movupd [rcx + rax - 16], xmm7;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movupd xmm1, [rcx + rax];
           andpd xmm1, xmm0;
           movupd [rcx + rax], xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;
end;

procedure ASMMatrixAbsAlignedOddW(Dest : PDouble; const LineWidth, Width, Height : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
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

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   //iters := -(width - 1)*sizeof(double);
   dec r8;
   imul r8, -8;

   // helper registers for the dest pointer
   sub rcx, r8;

   movupd xmm0, [rip + cLocSignBits];

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           //prefetchw [rcx + rax];

           // Abs:
           movapd xmm4, [rcx + rax - 128];
           Andpd xmm4, xmm0;
           movapd [rcx + rax - 128], xmm4;

           movapd xmm1, [rcx + rax - 112];
           andpd xmm1, xmm0;
           movapd [rcx + rax - 112], xmm1;

           movapd xmm2, [rcx + rax - 96];
           andpd xmm2, xmm0;
           movapd [rcx + rax - 96], xmm2;

           movapd xmm3, [rcx + rax - 80];
           andpd xmm3, xmm0;
           movapd [rcx + rax - 80], xmm3;

           movapd xmm4, [rcx + rax - 64];
           andpd xmm4, xmm0;
           movapd [rcx + rax - 64], xmm4;

           movapd xmm5, [rcx + rax - 48];
           andpd xmm5, xmm0;
           movapd [rcx + rax - 48], xmm5;

           movapd xmm6, [rcx + rax - 32];
           andpd xmm6, xmm0;
           movapd [rcx + rax - 32], xmm6;

           movapd xmm7, [rcx + rax - 16];
           andpd xmm7, xmm0;
           movapd [rcx + rax - 16], xmm7;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movapd xmm7, [rcx + rax];
           andpd xmm7, xmm0;
           movapd [rcx + rax], xmm7;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last element
       movsd xmm1, [rcx + rax];
       andpd xmm1, xmm0;
       movsd [rcx + rax], xmm1;

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;
end;

procedure ASMMatrixAbsUnAlignedOddW(Dest : PDouble; const LineWidth, Width, Height : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
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

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   //iters := -(width-1)*sizeof(double);
   dec r8;
   imul r8, -8;

   // helper registers for the dest pointer
   sub rcx, r8;

   movupd xmm0, [rip + cLocSignBits];

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // Abs:
           movupd xmm4, [rcx + rax - 128];
           Andpd xmm4, xmm0;
           movupd [rcx + rax - 128], xmm4;

           movupd xmm1, [rcx + rax - 112];
           andpd xmm1, xmm0;
           movupd [rcx + rax - 112], xmm1;

           movupd xmm2, [rcx + rax - 96];
           andpd xmm2, xmm0;
           movupd [rcx + rax - 96], xmm2;

           movupd xmm3, [rcx + rax - 80];
           andpd xmm3, xmm0;
           movupd [rcx + rax - 80], xmm3;

           movupd xmm4, [rcx + rax - 64];
           andpd xmm4, xmm0;
           movupd [rcx + rax - 64], xmm4;

           movupd xmm5, [rcx + rax - 48];
           andpd xmm5, xmm0;
           movupd [rcx + rax - 48], xmm5;

           movupd xmm6, [rcx + rax - 32];
           andpd xmm6, xmm0;
           movupd [rcx + rax - 32], xmm6;

           movupd xmm7, [rcx + rax - 16];
           andpd xmm7, xmm0;
           movupd [rcx + rax - 16], xmm7;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movupd xmm1, [rcx + rax];
           andpd xmm1, xmm0;
           movupd [rcx + rax], xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last element
       movsd xmm1, [rcx + rax];
       andpd xmm1, xmm0;
       movsd [rcx + rax], xmm1;

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;
end;

{$ENDIF}

end.
