// ###################################################################
// #### This file is part of the mathematics library project, and is
// #### offered under the licence agreement described on
// #### http://www.mrsoft.org/
// ####
// #### Copyright:(c) 2018, Michael R. . All rights reserved.
// ####
// #### Unless required by applicable law or agreed to in writing, software
// #### distributed under the License is distributed on an "AS IS" BASIS,
// #### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// #### See the License for the specific language governing permissions and
// #### limitations under the License.
// ###################################################################

unit AVXMatrixCumSumDiffOperationsx64;

interface

{$I 'mrMath_CPU.inc'}

{$IFDEF x64}

procedure AVXMatrixCumulativeSumRow(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

procedure AVXMatrixCumulativeSumColumnUnaligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
procedure AVXMatrixCumulativeSumColumnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

procedure AVXMatrixDifferentiateRow(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

procedure AVXMatrixDifferentiateColumnUnaligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
procedure AVXMatrixDifferentiateColumnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

{$ENDIF}

implementation

{$IFDEF x64}

// ##################################################
// #### Cumulative sum
// ##################################################

procedure AVXMatrixCumulativeSumRow(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var iRSI : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
// rcx: dest, rdx: destlinewidth; r8: src; r9 : srclinewidth
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

   // prolog - maintain stack
   mov iRSI, rsi;

   // if (width <= 0) or (height <= 0) then exit;
   mov r10, width;
   cmp r10, 0;
   jle @@exitproc;
   mov rsi, height;
   cmp rsi, 0;
   jle @@exitproc;

   // iter := -width*sizeof(Double)
   imul r10, -8;

   // prepare counters
   sub rcx, r10;
   sub r8, r10;
   @@foryloop:
      mov rax, r10;

      {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                         {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 
      @@forxloop:
         {$IFDEF AVXSUP}vmovsd xmm1, [r8 + rax];                      {$ELSE}db $C4,$C1,$7B,$10,$0C,$00;{$ENDIF} 
         {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                      {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd [rcx + rax], xmm0;                     {$ELSE}db $C5,$FB,$11,$04,$01;{$ENDIF} 
      add rax, 8;
      jnz @@forxloop;

      add rcx, rdx;
      add r8, r9;
   dec rsi;
   jnz @@foryloop;
   @@exitProc:

   // epilog - stack cleanup
   mov rsi, iRSI;
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

procedure AVXMatrixCumulativeSumColumnUnaligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var iRDI, iRSI : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
// rcx: dest, rdx: destlinewidth; r8: src; r9 : srclinewidth
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

   // prolog - maintain stack
   mov iRDI, rdi;
   mov iRSI, rsi;

   // if (width <= 1) or (height <= 0) then exit;
   mov r11, height;
   cmp r11, 0;

   jle @@exitproc;
   mov r10, width;
   sub r10, 4;
   jl @@lastColumns;

   @@forxloop:
       mov rax, r11;
       {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                        {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
       xor rdi, rdi;
       xor rsi, rsi;

       // 4 values at once
       @@foryloop:
           {$IFDEF AVXSUP}vmovupd ymm1, [r8 + rdi];                   {$ELSE}db $C4,$C1,$7D,$10,$0C,$38;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                    {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd [rcx + rsi], ymm0;                  {$ELSE}db $C5,$FD,$11,$04,$31;{$ENDIF} 

           add rdi, r9;
           add rsi, rdx;
       dec rax;
       jnz @@foryloop;

       add r8, 32;
       add rcx, 32;
   sub r10, 4;
   jge @@forxloop;

   @@lastColumns:
   add r10, 4;
   jz @@exitProc;

   @@forxloopshort:
       mov rax, r11;
       {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                        {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 
       xor rdi, rdi;
       xor rsi, rsi;

       // 4 values at once
       @@foryloopshort:
           {$IFDEF AVXSUP}vmovsd xmm1, [r8 + rdi];                    {$ELSE}db $C4,$C1,$7B,$10,$0C,$38;{$ENDIF} 
           {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                    {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
           {$IFDEF AVXSUP}vmovsd [rcx + rsi], xmm0;                   {$ELSE}db $C5,$FB,$11,$04,$31;{$ENDIF} 

           add rdi, r9;
           add rsi, rdx;
       dec rax;
       jnz @@foryloopshort;

       add r8, 8;
       add rcx, 8;
   sub r10, 1;
   jg @@forxloopshort;

   @@exitProc:

   // epilog - stack cleanup
   mov rdi, iRDI;
   mov rsi, iRSI;
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

procedure AVXMatrixCumulativeSumColumnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var iRDI, iRSI : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
// rcx: dest, rdx: destlinewidth; r8: src; r9 : srclinewidth
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

   // prolog - maintain stack
   mov iRDI, rdi;
   mov iRSI, rsi;

   // if (width <= 1) or (height <= 0) then exit;
   mov r11, height;
   cmp r11, 0;

   jle @@exitproc;
   mov r10, width;
   sub r10, 4;
   jl @@lastColumns;

   @@forxloop:
       mov rax, r11;
       {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                        {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
       xor rdi, rdi;
       xor rsi, rsi;

       // 4 values at once
       @@foryloop:
           {$IFDEF AVXSUP}vmovapd ymm1, [r8 + rdi];                   {$ELSE}db $C4,$C1,$7D,$28,$0C,$38;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                    {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
           {$IFDEF AVXSUP}vmovapd [rcx + rsi], ymm0;                  {$ELSE}db $C5,$FD,$29,$04,$31;{$ENDIF} 

           add rdi, r9;
           add rsi, rdx;
       dec rax;
       jnz @@foryloop;

       add r8, 32;
       add rcx, 32;
   sub r10, 4;
   jge @@forxloop;

   @@lastColumns:
   add r10, 4;
   jz @@exitProc;

   @@forxloopshort:
       mov rax, r11;
       {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                        {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 
       xor rdi, rdi;
       xor rsi, rsi;

       // 4 values at once
       @@foryloopshort:
           {$IFDEF AVXSUP}vmovsd xmm1, [r8 + rdi];                    {$ELSE}db $C4,$C1,$7B,$10,$0C,$38;{$ENDIF} 
           {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                    {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
           {$IFDEF AVXSUP}vmovsd [rcx + rsi], xmm0;                   {$ELSE}db $C5,$FB,$11,$04,$31;{$ENDIF} 

           add rdi, r9;
           add rsi, rdx;
       dec rax;
       jnz @@foryloopshort;

       add r8, 8;
       add rcx, 8;
   sub r10, 1;
   jg @@forxloopshort;

   @@exitProc:
   // epilog - stack cleanup
   mov rdi, iRDI;
   mov rsi, iRSI;
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

// ###############################################
// #### Differentiate
// ###############################################

procedure AVXMatrixDifferentiateRow(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
{$ifdef UNIX}
var width : NativeInt;
    height : NativeInt;
    {$ENDIF}
// rcx: dest, rdx: destlinewidth; r8: src; r9 : srclinewidth
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

   // prolog - maintain stack

   // if (width <= 1) or (height <= 0) then exit;
   mov r10, width;
   cmp r10, 1;
   jle @@exitproc;
   mov r11, height;
   cmp r11, 0;
   jle @@exitproc;
   // iter := -width*sizeof(Double)
   imul r10, -8;
   // prepare counters
   sub rcx, r10;
   sub r8, r10;
   add r10, 8;
   @@foryloop:
       mov rax, r10;
       {$IFDEF AVXSUP}vmovsd xmm1, [r8 + rax - 8];                    {$ELSE}db $C4,$C1,$7B,$10,$4C,$00,$F8;{$ENDIF} 
       @@forxloop:
           {$IFDEF AVXSUP}vmovsd xmm0, [r8 + rax];                    {$ELSE}db $C4,$C1,$7B,$10,$04,$00;{$ENDIF} 
           {$IFDEF AVXSUP}vsubsd xmm2, xmm0, xmm1;                    {$ELSE}db $C5,$FB,$5C,$D1;{$ENDIF} 
           {$IFDEF AVXSUP}vmovsd [rcx + rax - 8], xmm2;               {$ELSE}db $C5,$FB,$11,$54,$01,$F8;{$ENDIF} 
           {$IFDEF AVXSUP}vmovapd xmm1, xmm0;                         {$ELSE}db $C5,$F9,$29,$C1;{$ENDIF} 
       add rax, 8;
       jnz @@forxloop;

       add rcx, rdx;
       add r8, r9;
   dec r11;
   jnz @@foryloop;

   @@exitProc:

   // epilog - stack cleanup
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

procedure AVXMatrixDifferentiateColumnUnaligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var iRDI, iRSI : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
// rcx: dest, rdx: destlinewidth; r8: src; r9 : srclinewidth
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
   // prolog - maintain stack
   mov iRDI, rdi;
   mov iRSI, rsi;

   // if (width <= 1) or (height <= 0) then exit;
   mov r11, height;
   cmp r11, 1;
   jle @@exitproc;

   mov r10, width;
   cmp r10, 1;
   jle @@exitproc;

   dec r11;
   sub r10, 4;
   jl @@forxloopend;

   @@forxloop:
       mov rax, r11;
       {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                        {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
       mov rdi, r9;
       xor rsi, rsi;

       {$IFDEF AVXSUP}vmovupd ymm0, [r8];                             {$ELSE}db $C4,$C1,$7D,$10,$00;{$ENDIF} 

       // 4 values at once
       @@foryloop:
           {$IFDEF AVXSUP}vmovupd ymm1, [r8 + rdi];                   {$ELSE}db $C4,$C1,$7D,$10,$0C,$38;{$ENDIF} 
           {$IFDEF AVXSUP}vsubpd ymm2, ymm1, ymm0;                    {$ELSE}db $C5,$F5,$5C,$D0;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd [rcx + rsi], ymm2;                  {$ELSE}db $C5,$FD,$11,$14,$31;{$ENDIF} 

           {$IFDEF AVXSUP}vmovapd ymm0, ymm1;                         {$ELSE}db $C5,$FD,$29,$C8;{$ENDIF} 

           add rdi, r9;
           add rsi, rdx;
       dec rax;
       jnz @@foryloop;

       add r8, 32;
       add rcx, 32;
   sub r10, 4;
   jge @@forxloop;

   @@forxloopend:
   add r10, 4;
   jz @@exitProc;

   // #####################################
   // #### last < 4 columns
   @@forxloopshort:
      mov rax, r11;
      {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                         {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 
      mov rdi, r9;
      xor rsi, rsi;

      {$IFDEF AVXSUP}vmovsd xmm0, [r8];                               {$ELSE}db $C4,$C1,$7B,$10,$00;{$ENDIF} 

      // one column value:
      @@foryloopshort:
          {$IFDEF AVXSUP}vmovsd xmm1, [r8 + rdi];                     {$ELSE}db $C4,$C1,$7B,$10,$0C,$38;{$ENDIF} 
          {$IFDEF AVXSUP}vsubsd xmm2, xmm1, xmm0;                     {$ELSE}db $C5,$F3,$5C,$D0;{$ENDIF} 
          {$IFDEF AVXSUP}vmovsd [rcx + rsi], xmm2;                    {$ELSE}db $C5,$FB,$11,$14,$31;{$ENDIF} 

          {$IFDEF AVXSUP}vmovsd xmm0, xmm0, xmm1;                     {$ELSE}db $C5,$FB,$11,$C8;{$ENDIF} 

          add rdi, r9;
          add rsi, rdx;
      dec rax;
      jnz @@foryloopshort;

      add r8, 8;
      add rcx, 8;

   dec r10;
   jnz @@forxloopshort;

   @@exitProc:

   // epilog - stack cleanup
   mov rdi, iRDI;
   mov rsi, iRSI;
end;

procedure AVXMatrixDifferentiateColumnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var iRDI, iRSI : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
// rcx: dest, rdx: destlinewidth; r8: src; r9 : srclinewidth
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
   // prolog - maintain stack
   mov iRDI, rdi;
   mov iRSI, rsi;

   // if (width <= 1) or (height <= 0) then exit;
   mov r11, height;
   cmp r11, 1;
   jle @@exitproc;

   mov r10, width;
   cmp r10, 1;
   jle @@exitproc;

   dec r11;
   sub r10, 4;
   jl @@forxloopend;

   @@forxloop:
       mov rax, r11;
       {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                        {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
       mov rdi, r9;
       xor rsi, rsi;

       {$IFDEF AVXSUP}vmovupd ymm0, [r8];                             {$ELSE}db $C4,$C1,$7D,$10,$00;{$ENDIF} 

       // 4 values at once
       @@foryloop:
           {$IFDEF AVXSUP}vmovapd ymm1, [r8 + rdi];                   {$ELSE}db $C4,$C1,$7D,$28,$0C,$38;{$ENDIF} 
           {$IFDEF AVXSUP}vsubpd ymm2, ymm1, ymm0;                    {$ELSE}db $C5,$F5,$5C,$D0;{$ENDIF} 
           {$IFDEF AVXSUP}vmovapd [rcx + rsi], ymm2;                  {$ELSE}db $C5,$FD,$29,$14,$31;{$ENDIF} 

           {$IFDEF AVXSUP}vmovapd ymm0, ymm1;                         {$ELSE}db $C5,$FD,$29,$C8;{$ENDIF} 

           add rdi, r9;
           add rsi, rdx;
       dec rax;
       jnz @@foryloop;

       add r8, 32;
       add rcx, 32;
   sub r10, 4;
   jge @@forxloop;

   @@forxloopend:
   add r10, 4;
   jz @@exitProc;

   // #####################################
   // #### last < 4 columns
   @@forxloopshort:
      mov rax, r11;
      {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                         {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 
      mov rdi, r9;
      xor rsi, rsi;

      {$IFDEF AVXSUP}vmovsd xmm0, [r8];                               {$ELSE}db $C4,$C1,$7B,$10,$00;{$ENDIF} 

      // one column value:
      @@foryloopshort:
          {$IFDEF AVXSUP}vmovsd xmm1, [r8 + rdi];                     {$ELSE}db $C4,$C1,$7B,$10,$0C,$38;{$ENDIF} 
          {$IFDEF AVXSUP}vsubsd xmm2, xmm1, xmm0;                     {$ELSE}db $C5,$F3,$5C,$D0;{$ENDIF} 
          {$IFDEF AVXSUP}vmovsd [rcx + rsi], xmm2;                    {$ELSE}db $C5,$FB,$11,$14,$31;{$ENDIF} 

          {$IFDEF AVXSUP}vmovsd xmm0, xmm0, xmm1;                     {$ELSE}db $C5,$FB,$11,$C8;{$ENDIF} 

          add rdi, r9;
          add rsi, rdx;
      dec rax;
      jnz @@foryloopshort;

      add r8, 8;
      add rcx, 8;

   dec r10;
   jnz @@forxloopshort;

   @@exitProc:

   // epilog - stack cleanup
   mov rdi, iRDI;
   mov rsi, iRSI;
end;


{$ENDIF}

end.
