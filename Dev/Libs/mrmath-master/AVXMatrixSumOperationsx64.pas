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


unit AVXMatrixSumOperationsx64;

interface

{$I 'mrMath_CPU.inc'}

{$IFDEF x64}

procedure AVXMatrixSumRowAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
procedure AVXMatrixSumRowUnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

procedure AVXMatrixSumColumnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
procedure AVXMatrixSumColumnUnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

function AVXMatrixSumUnAligned( Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt) : double; {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
function AVXMatrixSumAligned( Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt) : double; {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}

{$ENDIF}

implementation

{$IFDEF x64}

procedure AVXMatrixSumRowAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
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

   // prolog

   // iters := -width*sizeof(double)
   mov r10, width;
   imul r10, -8;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                        {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                        {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [r8 + rax];

           // addition:
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, [r8 + rax - 128];        {$ELSE}db $C4,$C1,$7D,$58,$44,$00,$80;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, [r8 + rax - 96];         {$ELSE}db $C4,$C1,$75,$58,$4C,$00,$A0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, [r8 + rax - 64];         {$ELSE}db $C4,$C1,$7D,$58,$44,$00,$C0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, [r8 + rax - 32];         {$ELSE}db $C4,$C1,$75,$58,$4C,$00,$E0;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                        {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
       {$IFDEF AVXSUP}vextractf128 xmm2, ymm0, 1;                     {$ELSE}db $C4,$E3,$7D,$19,$C2,$01;{$ENDIF} 
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm2;                       {$ELSE}db $C5,$F9,$7C,$C2;{$ENDIF} 

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           add rax, 16;
           jg @@addforxloop2end;

           {$IFDEF AVXSUP}vaddpd xmm0, xmm0, [r8 + rax - 16];         {$ELSE}db $C4,$C1,$79,$58,$44,$00,$F0;{$ENDIF} 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub rax, 16;
       jz @buildRes;

       {$IFDEF AVXSUP}vaddsd xmm0, xmm0, [r8 + rax];                  {$ELSE}db $C4,$C1,$7B,$58,$04,$00;{$ENDIF} 

       @buildRes:

       // build result
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                       {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 

       // write result
       {$IFDEF AVXSUP}vmovsd [rcx], xmm0;                             {$ELSE}db $C5,$FB,$11,$01;{$ENDIF} 

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

procedure AVXMatrixSumRowUnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
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

   // prolog

   // iters := -width*sizeof(double)
   mov r10, width;
   imul r10, -8;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                        {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                        {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [r8 + rax];

           // addition:
           {$IFDEF AVXSUP}vmovupd ymm2, [r8 + rax - 128];             {$ELSE}db $C4,$C1,$7D,$10,$54,$00,$80;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm2;                    {$ELSE}db $C5,$FD,$58,$C2;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd ymm2, [r8 + rax - 96];              {$ELSE}db $C4,$C1,$7D,$10,$54,$00,$A0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd ymm2, [r8 + rax - 64];              {$ELSE}db $C4,$C1,$7D,$10,$54,$00,$C0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm2;                    {$ELSE}db $C5,$FD,$58,$C2;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd ymm2, [r8 + rax - 32];              {$ELSE}db $C4,$C1,$7D,$10,$54,$00,$E0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                        {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
       {$IFDEF AVXSUP}vextractf128 xmm2, ymm0, 1;                     {$ELSE}db $C4,$E3,$7D,$19,$C2,$01;{$ENDIF} 
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm2;                       {$ELSE}db $C5,$F9,$7C,$C2;{$ENDIF} 

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           add rax, 16;
           jg @@addforxloop2end;

           {$IFDEF AVXSUP}vmovupd xmm2, [r8 + rax - 16];              {$ELSE}db $C4,$C1,$79,$10,$54,$00,$F0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm2;                    {$ELSE}db $C5,$F9,$58,$C2;{$ENDIF} 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub rax, 16;
       jz @buildRes;

       {$IFDEF AVXSUP}vaddsd xmm0, xmm0, [r8 + rax];                  {$ELSE}db $C4,$C1,$7B,$58,$04,$00;{$ENDIF} 

       @buildRes:

       // build result
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                       {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 

       // write result
       {$IFDEF AVXSUP}vmovsd [rcx], xmm0;                             {$ELSE}db $C5,$FB,$11,$01;{$ENDIF} 

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

procedure AVXMatrixSumColumnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
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
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   // for x := 0 to width - 1:
   mov r11, Width;
   sub r11, 4;
   jl @@addforxloop4end;

   // 4 columns at once
   @@addforxloop4:
       {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                        {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforyloop4:
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, [r8 + rax];              {$ELSE}db $C4,$C1,$75,$58,$0C,$00;{$ENDIF} 
       add rax, r9;
       jnz @addforyloop4;

       // build result
       {$IFDEF AVXSUP}vmovapd [rcx], ymm1;                            {$ELSE}db $C5,$FD,$29,$09;{$ENDIF} 

       // next columns:
       add rcx, 32;
       add r8, 32;

   // loop x end
   sub r11, 4;
   jge @@addforxloop4;

   @@addforxloop4end:

   add r11, 4;
   jz @@endProc;

   sub r11, 2;
   jl @@lastcolumn;

   {$IFDEF AVXSUP}vxorpd xmm1, xmm1, xmm1;                            {$ELSE}db $C5,$F1,$57,$C9;{$ENDIF} 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop2:
       {$IFDEF AVXSUP}vaddpd xmm1, xmm1, [r8 + rax];                  {$ELSE}db $C4,$C1,$71,$58,$0C,$00;{$ENDIF} 
   add rax, r9;
   jnz @addforyloop2;

   // build result
   {$IFDEF AVXSUP}vmovapd [rcx], xmm1;                                {$ELSE}db $C5,$F9,$29,$09;{$ENDIF} 

   // next columns:
   add rcx, 16;
   add r8, 16;

   dec r11;
   jnz @@endProc;

   @@lastcolumn:

   {$IFDEF AVXSUP}vxorpd xmm1, xmm1, xmm1;                            {$ELSE}db $C5,$F1,$57,$C9;{$ENDIF} 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop:
       {$IFDEF AVXSUP}vaddsd xmm1, xmm1, [r8 + rax];                  {$ELSE}db $C4,$C1,$73,$58,$0C,$00;{$ENDIF} 
   add rax, r9;
   jnz @addforyloop;

   // build result
   {$IFDEF AVXSUP}vmovsd [rcx], xmm1;                                 {$ELSE}db $C5,$FB,$11,$09;{$ENDIF} 

   @@endProc:
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

procedure AVXMatrixSumColumnUnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
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
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   // for x := 0 to width - 1:
   mov r11, Width;
   sub r11, 4;
   jl @@addforxloop4end;

   // 4 columns at once
   @@addforxloop4:
       {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                        {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforyloop4:
           {$IFDEF AVXSUP}vmovupd ymm0, [r8 + rax];                   {$ELSE}db $C4,$C1,$7D,$10,$04,$00;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm0;                    {$ELSE}db $C5,$F5,$58,$C8;{$ENDIF} 
       add rax, r9;
       jnz @addforyloop4;

       // build result
       {$IFDEF AVXSUP}vmovupd [rcx], ymm1;                            {$ELSE}db $C5,$FD,$11,$09;{$ENDIF} 

       // next columns:
       add rcx, 32;
       add r8, 32;

   // loop x end
   sub r11, 4;
   jge @@addforxloop4;

   @@addforxloop4end:

   add r11, 4;
   jz @@endProc;

   sub r11, 2;
   jl @@lastcolumn;

   {$IFDEF AVXSUP}vxorpd xmm1, xmm1, xmm1;                            {$ELSE}db $C5,$F1,$57,$C9;{$ENDIF} 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop2:
       {$IFDEF AVXSUP}vmovupd xmm0, [r8 + rax];                       {$ELSE}db $C4,$C1,$79,$10,$04,$00;{$ENDIF} 
       {$IFDEF AVXSUP}vaddpd xmm1, xmm1, [r8 + rax];                  {$ELSE}db $C4,$C1,$71,$58,$0C,$00;{$ENDIF} 
   add rax, r9;
   jnz @addforyloop2;

   // build result
   {$IFDEF AVXSUP}vmovupd [rcx], xmm1;                                {$ELSE}db $C5,$F9,$11,$09;{$ENDIF} 

   // next columns:
   add rcx, 16;
   add r8, 16;

   dec r11;
   jnz @@endProc;

   @@lastcolumn:

   {$IFDEF AVXSUP}vxorpd xmm1, xmm1, xmm1;                            {$ELSE}db $C5,$F1,$57,$C9;{$ENDIF} 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop:
       {$IFDEF AVXSUP}vaddsd xmm1, xmm1, [r8 + rax];                  {$ELSE}db $C4,$C1,$73,$58,$0C,$00;{$ENDIF} 
   add rax, r9;
   jnz @addforyloop;

   // build result
   {$IFDEF AVXSUP}vmovsd [rcx], xmm1;                                 {$ELSE}db $C5,$FB,$11,$09;{$ENDIF} 

   @@endProc:
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

function AVXMatrixSumUnAligned( Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt) : double; {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
// src : rcx; srcLineWidth : rdx; width = r8; height : r9
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

   // iters := -width*sizeof(double)
   imul r8, -8;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   {$IFDEF AVXSUP}vxorpd xmm3, xmm3, xmm3;                            {$ELSE}db $C5,$E1,$57,$DB;{$ENDIF} 

   // for y := 0 to height - 1:
   @@addforyloop:
       {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                        {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                        {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 


       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [rcx + rax];

           // addition:
           {$IFDEF AVXSUP}vmovupd ymm2, [rcx + rax - 128];            {$ELSE}db $C5,$FD,$10,$54,$01,$80;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm2;                    {$ELSE}db $C5,$FD,$58,$C2;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd ymm2, [rcx + rax - 96];             {$ELSE}db $C5,$FD,$10,$54,$01,$A0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd ymm2, [rcx + rax - 64];             {$ELSE}db $C5,$FD,$10,$54,$01,$C0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm2;                    {$ELSE}db $C5,$FD,$58,$C2;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd ymm2, [rcx + rax - 32];             {$ELSE}db $C5,$FD,$10,$54,$01,$E0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                        {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
       {$IFDEF AVXSUP}vextractf128 xmm2, ymm0, 1;                     {$ELSE}db $C4,$E3,$7D,$19,$C2,$01;{$ENDIF} 
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm2;                       {$ELSE}db $C5,$F9,$7C,$C2;{$ENDIF} 

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           add rax, 16;
           jg @@addforxloop2end;

           {$IFDEF AVXSUP}vmovupd xmm2, [rcx + rax - 16];             {$ELSE}db $C5,$F9,$10,$54,$01,$F0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm2;                    {$ELSE}db $C5,$F9,$58,$C2;{$ENDIF} 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub rax, 16;
       jz @buildRes;

       {$IFDEF AVXSUP}vaddsd xmm0, xmm0, [rcx + rax];                 {$ELSE}db $C5,$FB,$58,$04,$01;{$ENDIF} 

       @buildRes:

       // build result
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                       {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vaddsd xmm3, xmm3, xmm0;                        {$ELSE}db $C5,$E3,$58,$D8;{$ENDIF} 

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 

   movsd Result, xmm3;
end;

function AVXMatrixSumAligned( Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt) : double; {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
// src : rcx; srcLineWidth : rdx; width = r8; height : r9
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

   // iters := -width*sizeof(double)
   imul r8, -8;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   {$IFDEF AVXSUP}vxorpd xmm3, xmm3, xmm3;                            {$ELSE}db $C5,$E1,$57,$DB;{$ENDIF} 

   // for y := 0 to height - 1:
   @@addforyloop:
       {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                        {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                        {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [rcx + rax];

           // addition:
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, [rcx + rax - 128];       {$ELSE}db $C5,$FD,$58,$44,$01,$80;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, [rcx + rax - 96];        {$ELSE}db $C5,$F5,$58,$4C,$01,$A0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, [rcx + rax - 64];        {$ELSE}db $C5,$FD,$58,$44,$01,$C0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, [rcx + rax - 32];        {$ELSE}db $C5,$F5,$58,$4C,$01,$E0;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                        {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
       {$IFDEF AVXSUP}vextractf128 xmm2, ymm0, 1;                     {$ELSE}db $C4,$E3,$7D,$19,$C2,$01;{$ENDIF} 
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm2;                       {$ELSE}db $C5,$F9,$7C,$C2;{$ENDIF} 

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           add rax, 16;
           jg @@addforxloop2end;

           {$IFDEF AVXSUP}vaddpd xmm0, xmm0, [rcx + rax - 16];        {$ELSE}db $C5,$F9,$58,$44,$01,$F0;{$ENDIF} 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub rax, 16;
       jz @buildRes;

       {$IFDEF AVXSUP}vaddsd xmm0, xmm0, [rcx + rax];                 {$ELSE}db $C5,$FB,$58,$04,$01;{$ENDIF} 

       @buildRes:

       // build result
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                       {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 

       {$IFDEF AVXSUP}vaddsd xmm3, xmm3, xmm0;                        {$ELSE}db $C5,$E3,$58,$D8;{$ENDIF} 
       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;


   // epilog
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 

   movsd Result, xmm3;
end;

{$ENDIF}

end.
