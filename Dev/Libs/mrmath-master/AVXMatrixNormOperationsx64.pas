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


unit AVXMatrixNormOperationsx64;

interface

{$I 'mrMath_CPU.inc'}

{$IFDEF x64}

uses MatrixConst;

function AVXMatrixElementwiseNorm2Aligned(dest : PDouble; const LineWidth : NativeInt; Width, height : NativeInt) : double;
function AVXMatrixElementwiseNorm2UnAligned(dest : PDouble; const LineWidth : NativeInt; Width, height : NativeInt) : double;


procedure AVXMatrixNormalizeRowAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt ); {$IFDEF FPC}assembler;{$ENDIF}
procedure AVXMatrixNormalizeRowUnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt ); {$IFDEF FPC}assembler;{$ENDIF}

procedure AVXMatrixNormalizeColumnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt ); {$IFDEF FPC}assembler;{$ENDIF}
procedure AVXMatrixNormalizeColumnUnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt ); {$IFDEF FPC}assembler;{$ENDIF}

{$ENDIF}

implementation

{$IFDEF x64}

function AVXMatrixElementwiseNorm2Aligned(dest : PDouble; const LineWidth : NativeInt; Width, height : NativeInt) : double; {$IFDEF FPC}assembler;{$ENDIF}
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

   // note: RCX = dest, RDX = destLineWidth, R8 = widh, R9 = height
   // prolog - simulate stack

   //iters := -width*sizeof(double);
   imul r8, -8;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                            {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 
   {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                            {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

   mov r11, r9;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [rcx + rax];

           // mul add:
           {$IFDEF AVXSUP}vmovapd ymm3, [rcx + rax - 128];            {$ELSE}db $C5,$FD,$28,$5C,$01,$80;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm3;                    {$ELSE}db $C5,$E5,$59,$DB;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm3;                    {$ELSE}db $C5,$F5,$58,$CB;{$ENDIF} 

           {$IFDEF AVXSUP}vmovapd ymm2, [rcx + rax - 96];             {$ELSE}db $C5,$FD,$28,$54,$01,$A0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm2, ymm2, ymm2;                    {$ELSE}db $C5,$ED,$59,$D2;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 

           {$IFDEF AVXSUP}vmovapd ymm3, [rcx + rax - 64];             {$ELSE}db $C5,$FD,$28,$5C,$01,$C0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm3;                    {$ELSE}db $C5,$E5,$59,$DB;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm3;                    {$ELSE}db $C5,$F5,$58,$CB;{$ENDIF} 

           {$IFDEF AVXSUP}vmovapd ymm2, [rcx + rax - 32];             {$ELSE}db $C5,$FD,$28,$54,$01,$E0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm2, ymm2, ymm2;                    {$ELSE}db $C5,$ED,$59,$D2;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @@addforxloop2end;

           {$IFDEF AVXSUP}vmovapd xmm3, [rcx + rax - 16];             {$ELSE}db $C5,$F9,$28,$5C,$01,$F0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd xmm3, xmm3, xmm3;                    {$ELSE}db $C5,$E1,$59,$DB;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm3;                    {$ELSE}db $C5,$F9,$58,$C3;{$ENDIF} 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub rax, 16;
       jz @nextLine;

       {$IFDEF AVXSUP}vmovsd xmm3, [rcx + rax];                       {$ELSE}db $C5,$FB,$10,$1C,$01;{$ENDIF} 
       {$IFDEF AVXSUP}vmulsd xmm3, xmm3, xmm3;                        {$ELSE}db $C5,$E3,$59,$DB;{$ENDIF} 
       {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm3;                        {$ELSE}db $C5,$FB,$58,$C3;{$ENDIF} 

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // build result
   {$IFDEF AVXSUP}vextractf128 xmm2, ymm1, 1;                         {$ELSE}db $C4,$E3,$7D,$19,$CA,$01;{$ENDIF} 
   {$IFDEF AVXSUP}vhaddpd xmm1, xmm1, xmm2;                           {$ELSE}db $C5,$F1,$7C,$CA;{$ENDIF} 
   {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm1;                            {$ELSE}db $C5,$F9,$58,$C1;{$ENDIF} 
   {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                           {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 

   // epilog claenup stack
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

function AVXMatrixElementwiseNorm2UnAligned(dest : PDouble; const LineWidth : NativeInt; Width, height : NativeInt) : double; {$IFDEF FPC}assembler;{$ENDIF}
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

   // note: RCX = dest, RDX = destLineWidth, R8 = widh, R9 = height
   // prolog - simulate stack

   //iters := -width*sizeof(double);
   imul r8, -8;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                            {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 
   {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                            {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

   mov r11, r9
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [rcx + rax];

           // mul add:
           {$IFDEF AVXSUP}vmovupd ymm3, [rcx + rax - 128];            {$ELSE}db $C5,$FD,$10,$5C,$01,$80;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm3;                    {$ELSE}db $C5,$E5,$59,$DB;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm3;                    {$ELSE}db $C5,$F5,$58,$CB;{$ENDIF} 

           {$IFDEF AVXSUP}vmovupd ymm2, [rcx + rax - 96];             {$ELSE}db $C5,$FD,$10,$54,$01,$A0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm2, ymm2, ymm2;                    {$ELSE}db $C5,$ED,$59,$D2;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 

           {$IFDEF AVXSUP}vmovupd ymm3, [rcx + rax - 64];             {$ELSE}db $C5,$FD,$10,$5C,$01,$C0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm3;                    {$ELSE}db $C5,$E5,$59,$DB;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm3;                    {$ELSE}db $C5,$F5,$58,$CB;{$ENDIF} 

           {$IFDEF AVXSUP}vmovupd ymm2, [rcx + rax - 32];             {$ELSE}db $C5,$FD,$10,$54,$01,$E0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm2, ymm2, ymm2;                    {$ELSE}db $C5,$ED,$59,$D2;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @@addforxloop2end;

           {$IFDEF AVXSUP}vmovupd xmm3, [rcx + rax - 16];             {$ELSE}db $C5,$F9,$10,$5C,$01,$F0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd xmm3, xmm3, xmm3;                    {$ELSE}db $C5,$E1,$59,$DB;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm3;                    {$ELSE}db $C5,$F9,$58,$C3;{$ENDIF} 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub rax, 16;
       jz @nextLine;

       {$IFDEF AVXSUP}vmovsd xmm3, [rcx + rax];                       {$ELSE}db $C5,$FB,$10,$1C,$01;{$ENDIF} 
       {$IFDEF AVXSUP}vmulsd xmm3, xmm3, xmm3;                        {$ELSE}db $C5,$E3,$59,$DB;{$ENDIF} 
       {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm3;                        {$ELSE}db $C5,$FB,$58,$C3;{$ENDIF} 

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // build result
   {$IFDEF AVXSUP}vextractf128 xmm2, ymm1, 1;                         {$ELSE}db $C4,$E3,$7D,$19,$CA,$01;{$ENDIF} 
   {$IFDEF AVXSUP}vhaddpd xmm1, xmm1, xmm2;                           {$ELSE}db $C5,$F1,$7C,$CA;{$ENDIF} 
   {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm1;                            {$ELSE}db $C5,$F9,$58,$C1;{$ENDIF} 
   {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                           {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 

   // epilog claenup stack
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

procedure AVXMatrixNormalizeRowAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt ); {$IFDEF FPC}assembler;{$ENDIF}
var tmp : double;
    {$ifdef UNIX}
    width : NativeInt;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = widh, R9 = height
   // prolog - simulate stack

   //iters := -width*sizeof(double);
   mov r10, width;
   imul r10, -8;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r10;
   sub r8, r10;

   mov r11, height;
   @@addforyloop:
       {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                        {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                        {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [rcx + rax];

           // mul add:
           {$IFDEF AVXSUP}vmovapd ymm3, [r8 + rax - 128];             {$ELSE}db $C4,$C1,$7D,$28,$5C,$00,$80;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm3;                    {$ELSE}db $C5,$E5,$59,$DB;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm3;                    {$ELSE}db $C5,$F5,$58,$CB;{$ENDIF} 

           {$IFDEF AVXSUP}vmovapd ymm2, [r8 + rax - 96];              {$ELSE}db $C4,$C1,$7D,$28,$54,$00,$A0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm2, ymm2, ymm2;                    {$ELSE}db $C5,$ED,$59,$D2;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 

           {$IFDEF AVXSUP}vmovapd ymm3, [r8 + rax - 64];              {$ELSE}db $C4,$C1,$7D,$28,$5C,$00,$C0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm3;                    {$ELSE}db $C5,$E5,$59,$DB;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm3;                    {$ELSE}db $C5,$F5,$58,$CB;{$ENDIF} 

           {$IFDEF AVXSUP}vmovapd ymm2, [r8 + rax - 32];              {$ELSE}db $C4,$C1,$7D,$28,$54,$00,$E0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm2, ymm2, ymm2;                    {$ELSE}db $C5,$ED,$59,$D2;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @@addforxloop2end;

           {$IFDEF AVXSUP}vmovapd xmm3, [r8 + rax - 16];              {$ELSE}db $C4,$C1,$79,$28,$5C,$00,$F0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd xmm3, xmm3, xmm3;                    {$ELSE}db $C5,$E1,$59,$DB;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm3;                    {$ELSE}db $C5,$F9,$58,$C3;{$ENDIF} 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub rax, 16;
       jz @nextLine;

       {$IFDEF AVXSUP}vmovsd xmm3, [r8 + rax];                        {$ELSE}db $C4,$C1,$7B,$10,$1C,$00;{$ENDIF} 
       {$IFDEF AVXSUP}vmulsd xmm3, xmm3, xmm3;                        {$ELSE}db $C5,$E3,$59,$DB;{$ENDIF} 
       {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm3;                        {$ELSE}db $C5,$FB,$58,$C3;{$ENDIF} 

       @nextLine:

       // build result
       {$IFDEF AVXSUP}vextractf128 xmm2, ymm1, 1;                     {$ELSE}db $C4,$E3,$7D,$19,$CA,$01;{$ENDIF} 
       {$IFDEF AVXSUP}vhaddpd xmm1, xmm1, xmm2;                       {$ELSE}db $C5,$F1,$7C,$CA;{$ENDIF} 
       {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm1;                        {$ELSE}db $C5,$F9,$58,$C1;{$ENDIF} 
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                       {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 

       // build result
       {$IFDEF AVXSUP}vsqrtsd xmm0, xmm0, xmm0;                       {$ELSE}db $C5,$FB,$51,$C0;{$ENDIF} 

       //1/sqrt(norm)
       lea rax, [rip + cOne];
       {$IFDEF AVXSUP}vmovsd xmm1, [rax];                             {$ELSE}db $C5,$FB,$10,$08;{$ENDIF} 
       {$IFDEF AVXSUP}vdivsd xmm1, xmm1, xmm0;                        {$ELSE}db $C5,$F3,$5E,$C8;{$ENDIF} 

       lea rax, tmp;
       {$IFDEF AVXSUP}vmovsd [rax], xmm1;                             {$ELSE}db $C5,$FB,$11,$08;{$ENDIF} 
       {$IFDEF AVXSUP}vbroadcastsd ymm2, [rax];                       {$ELSE}db $C4,$E2,$7D,$19,$10;{$ENDIF} // need avx2

       //  normalize
       mov rax, r10;
       @addforxloop3:
           add rax, 128;
           jg @loopEnd2;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetchw [rcx + rax];

           // mult:
           {$IFDEF AVXSUP}vmovapd ymm0, [r8 + rax - 128];             {$ELSE}db $C4,$C1,$7D,$28,$44,$00,$80;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm0, ymm0, ymm2;                    {$ELSE}db $C5,$FD,$59,$C2;{$ENDIF} 
           {$IFDEF AVXSUP}vmovapd [rcx + rax - 128], ymm0;            {$ELSE}db $C5,$FD,$29,$44,$01,$80;{$ENDIF} 

           {$IFDEF AVXSUP}vmovapd ymm1, [r8 + rax - 96];              {$ELSE}db $C4,$C1,$7D,$28,$4C,$00,$A0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$59,$CA;{$ENDIF} 
           {$IFDEF AVXSUP}vmovapd [rcx + rax - 96], ymm1;             {$ELSE}db $C5,$FD,$29,$4C,$01,$A0;{$ENDIF} 

           {$IFDEF AVXSUP}vmovapd ymm0, [r8 + rax - 64];              {$ELSE}db $C4,$C1,$7D,$28,$44,$00,$C0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm0, ymm0, ymm2;                    {$ELSE}db $C5,$FD,$59,$C2;{$ENDIF} 
           {$IFDEF AVXSUP}vmovapd [rcx + rax - 64], ymm0;             {$ELSE}db $C5,$FD,$29,$44,$01,$C0;{$ENDIF} 

           {$IFDEF AVXSUP}vmovapd ymm1, [r8 + rax - 32];              {$ELSE}db $C4,$C1,$7D,$28,$4C,$00,$E0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$59,$CA;{$ENDIF} 
           {$IFDEF AVXSUP}vmovapd [rcx + rax - 32], ymm1;             {$ELSE}db $C5,$FD,$29,$4C,$01,$E0;{$ENDIF} 

       jmp @addforxloop3

       @loopEnd2:

       sub rax, 128;

       jz @nextLine2;

       @addforxloop4:
           add rax, 16;
           jg @addforxloop4end;

           {$IFDEF AVXSUP}vmovapd xmm0, [r8 + rax - 16];              {$ELSE}db $C4,$C1,$79,$28,$44,$00,$F0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd xmm0, xmm0, xmm2;                    {$ELSE}db $C5,$F9,$59,$C2;{$ENDIF} 
           {$IFDEF AVXSUP}vmovapd [rcx + rax - 16], xmm0;             {$ELSE}db $C5,$F9,$29,$44,$01,$F0;{$ENDIF} 
       jmp @addforxloop4;

       @addforxloop4end:
       sub rax, 16;
       jz @nextLine2;

       {$IFDEF AVXSUP}vmovsd xmm0, [r8 + rax];                        {$ELSE}db $C4,$C1,$7B,$10,$04,$00;{$ENDIF} 
       {$IFDEF AVXSUP}vmulsd xmm0, xmm0, xmm2;                        {$ELSE}db $C5,$FB,$59,$C2;{$ENDIF} 
       {$IFDEF AVXSUP}vmovsd [rcx + rax], xmm0;                       {$ELSE}db $C5,$FB,$11,$04,$01;{$ENDIF} 

       @nextLine2:

       // next line:
       add rcx, rdx;
       add r8, r9;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog claenup stack
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

procedure AVXMatrixNormalizeRowUnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var tmp : double;
    {$ifdef UNIX}
    width : NativeInt;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = widh, R9 = height
   // prolog - simulate stack

   //iters := -width*sizeof(double);
   mov r10, width;
   imul r10, -8;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r10;
   sub r8, r10;

   mov r11, height;
   @@addforyloop:
       {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                        {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                        {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [rcx + rax];

           // mul add:
           {$IFDEF AVXSUP}vmovupd ymm3, [r8 + rax - 128];             {$ELSE}db $C4,$C1,$7D,$10,$5C,$00,$80;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm3;                    {$ELSE}db $C5,$E5,$59,$DB;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm3;                    {$ELSE}db $C5,$F5,$58,$CB;{$ENDIF} 

           {$IFDEF AVXSUP}vmovupd ymm2, [r8 + rax - 96];              {$ELSE}db $C4,$C1,$7D,$10,$54,$00,$A0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm2, ymm2, ymm2;                    {$ELSE}db $C5,$ED,$59,$D2;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 

           {$IFDEF AVXSUP}vmovupd ymm3, [r8 + rax - 64];              {$ELSE}db $C4,$C1,$7D,$10,$5C,$00,$C0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm3;                    {$ELSE}db $C5,$E5,$59,$DB;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm3;                    {$ELSE}db $C5,$F5,$58,$CB;{$ENDIF} 

           {$IFDEF AVXSUP}vmovupd ymm2, [r8 + rax - 32];              {$ELSE}db $C4,$C1,$7D,$10,$54,$00,$E0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm2, ymm2, ymm2;                    {$ELSE}db $C5,$ED,$59,$D2;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @@addforxloop2end;

           {$IFDEF AVXSUP}vmovupd xmm3, [r8 + rax - 16];              {$ELSE}db $C4,$C1,$79,$10,$5C,$00,$F0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd xmm3, xmm3, xmm3;                    {$ELSE}db $C5,$E1,$59,$DB;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm3;                    {$ELSE}db $C5,$F9,$58,$C3;{$ENDIF} 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub rax, 16;
       jz @nextLine;

       {$IFDEF AVXSUP}vmovsd xmm3, [r8 + rax];                        {$ELSE}db $C4,$C1,$7B,$10,$1C,$00;{$ENDIF} 
       {$IFDEF AVXSUP}vmulsd xmm3, xmm3, xmm3;                        {$ELSE}db $C5,$E3,$59,$DB;{$ENDIF} 
       {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm3;                        {$ELSE}db $C5,$FB,$58,$C3;{$ENDIF} 

       @nextLine:

       // build result
       {$IFDEF AVXSUP}vextractf128 xmm2, ymm1, 1;                     {$ELSE}db $C4,$E3,$7D,$19,$CA,$01;{$ENDIF} 
       {$IFDEF AVXSUP}vhaddpd xmm1, xmm1, xmm2;                       {$ELSE}db $C5,$F1,$7C,$CA;{$ENDIF} 
       {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm1;                        {$ELSE}db $C5,$F9,$58,$C1;{$ENDIF} 
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                       {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 

       // build result
       {$IFDEF AVXSUP}vsqrtsd xmm0, xmm0, xmm0;                       {$ELSE}db $C5,$FB,$51,$C0;{$ENDIF} 

       //1/sqrt(norm)
       lea rax, [rip + cOne];
       {$IFDEF AVXSUP}vmovsd xmm1, [rax];                             {$ELSE}db $C5,$FB,$10,$08;{$ENDIF} 
       {$IFDEF AVXSUP}vdivsd xmm1, xmm1, xmm0;                        {$ELSE}db $C5,$F3,$5E,$C8;{$ENDIF} 

       lea rax, tmp;
       {$IFDEF AVXSUP}vmovsd [rax], xmm1;                             {$ELSE}db $C5,$FB,$11,$08;{$ENDIF} 
       {$IFDEF AVXSUP}vbroadcastsd ymm2, [rax];                       {$ELSE}db $C4,$E2,$7D,$19,$10;{$ENDIF} // need avx2

       //  normalize
       mov rax, r10;
       @addforxloop3:
           add rax, 128;
           jg @loopEnd2;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetchw [rcx + rax];

           // mult:
           {$IFDEF AVXSUP}vmovupd ymm0, [r8 + rax - 128];             {$ELSE}db $C4,$C1,$7D,$10,$44,$00,$80;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm0, ymm0, ymm2;                    {$ELSE}db $C5,$FD,$59,$C2;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd [rcx + rax - 128], ymm0;            {$ELSE}db $C5,$FD,$11,$44,$01,$80;{$ENDIF} 

           {$IFDEF AVXSUP}vmovupd ymm1, [r8 + rax - 96];              {$ELSE}db $C4,$C1,$7D,$10,$4C,$00,$A0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$59,$CA;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd [rcx + rax - 96], ymm1;             {$ELSE}db $C5,$FD,$11,$4C,$01,$A0;{$ENDIF} 

           {$IFDEF AVXSUP}vmovupd ymm0, [r8 + rax - 64];              {$ELSE}db $C4,$C1,$7D,$10,$44,$00,$C0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm0, ymm0, ymm2;                    {$ELSE}db $C5,$FD,$59,$C2;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd [rcx + rax - 64], ymm0;             {$ELSE}db $C5,$FD,$11,$44,$01,$C0;{$ENDIF} 

           {$IFDEF AVXSUP}vmovupd ymm1, [r8 + rax - 32];              {$ELSE}db $C4,$C1,$7D,$10,$4C,$00,$E0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$59,$CA;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd [rcx + rax - 32], ymm1;             {$ELSE}db $C5,$FD,$11,$4C,$01,$E0;{$ENDIF} 

       jmp @addforxloop3

       @loopEnd2:

       sub rax, 128;

       jz @nextLine2;

       @addforxloop4:
           add rax, 16;
           jg @addforxloop4end;

           {$IFDEF AVXSUP}vmovupd xmm0, [r8 + rax - 16];              {$ELSE}db $C4,$C1,$79,$10,$44,$00,$F0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd xmm0, xmm0, xmm2;                    {$ELSE}db $C5,$F9,$59,$C2;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd [rcx + rax - 16], xmm0;             {$ELSE}db $C5,$F9,$11,$44,$01,$F0;{$ENDIF} 
       jmp @addforxloop4;

       @addforxloop4end:
       sub rax, 16;
       jz @nextLine2;

       {$IFDEF AVXSUP}vmovsd xmm0, [r8 + rax];                        {$ELSE}db $C4,$C1,$7B,$10,$04,$00;{$ENDIF} 
       {$IFDEF AVXSUP}vmulsd xmm0, xmm0, xmm2;                        {$ELSE}db $C5,$FB,$59,$C2;{$ENDIF} 
       {$IFDEF AVXSUP}vmovsd [rcx + rax], xmm0;                       {$ELSE}db $C5,$FB,$11,$04,$01;{$ENDIF} 

       @nextLine2:

       // next line:
       add rcx, rdx;
       add r8, r9;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog claenup stack
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

procedure AVXMatrixNormalizeColumnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var iRBX : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
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

   // prolog
   mov iRBX, rbx;

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1 and dest pointers
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
           {$IFDEF AVXSUP}vmovapd ymm3, [r8 + rax];                   {$ELSE}db $C4,$C1,$7D,$28,$1C,$00;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm3;                    {$ELSE}db $C5,$E5,$59,$DB;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm3;                    {$ELSE}db $C5,$F5,$58,$CB;{$ENDIF} 
       add rax, r9;
       jnz @addforyloop4;

       // normalization factor
       lea rax, [rip + cOne];
       {$IFDEF AVXSUP}vbroadcastsd ymm2, [rax];                       {$ELSE}db $C4,$E2,$7D,$19,$10;{$ENDIF} 
       {$IFDEF AVXSUP}vsqrtpd ymm1, ymm1;                             {$ELSE}db $C5,$FD,$51,$C9;{$ENDIF} 
       {$IFDEF AVXSUP}vdivpd ymm0, ymm2, ymm1;                        {$ELSE}db $C5,$ED,$5E,$C1;{$ENDIF} 

       // normalize
       mov rax, r10;
       xor rbx, rbx;
       @addforyloop4_2:
           {$IFDEF AVXSUP}vmovapd ymm1, [r8 + rax];                   {$ELSE}db $C4,$C1,$7D,$28,$0C,$00;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm0;                    {$ELSE}db $C5,$F5,$59,$C8;{$ENDIF} 
           {$IFDEF AVXSUP}vmovapd [rcx + rbx], ymm1;                  {$ELSE}db $C5,$FD,$29,$0C,$19;{$ENDIF} 

       add rbx, rdx;
       add rax, r9;
       jnz @addforyloop4_2;

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
       {$IFDEF AVXSUP}vmovapd xmm0, [r8 + rax];                       {$ELSE}db $C4,$C1,$79,$28,$04,$00;{$ENDIF} 
       {$IFDEF AVXSUP}vmulpd xmm0, xmm0, xmm0;                        {$ELSE}db $C5,$F9,$59,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vaddpd xmm1, xmm1, xmm0;                        {$ELSE}db $C5,$F1,$58,$C8;{$ENDIF} 
   add rax, r9;
   jnz @addforyloop2;

   // normalization factor
   lea rax, [rip + cOne];
   {$IFDEF AVXSUP}vmovddup xmm2, [rax];                               {$ELSE}db $C5,$FB,$12,$10;{$ENDIF} 
   {$IFDEF AVXSUP}vsqrtpd xmm1, xmm1;                                 {$ELSE}db $C5,$F9,$51,$C9;{$ENDIF} 
   {$IFDEF AVXSUP}vdivpd xmm0, xmm2, xmm1;                            {$ELSE}db $C5,$E9,$5E,$C1;{$ENDIF} 

   // normalize
   mov rax, r10;
   xor rbx, rbx;
   @addforyloop2_2:
      {$IFDEF AVXSUP}vmovapd xmm1, [r8 + rax];                        {$ELSE}db $C4,$C1,$79,$28,$0C,$00;{$ENDIF} 
      {$IFDEF AVXSUP}vmulpd xmm1, xmm1, xmm0;                         {$ELSE}db $C5,$F1,$59,$C8;{$ENDIF} 
      {$IFDEF AVXSUP}vmovapd [rcx + rbx], xmm1;                       {$ELSE}db $C5,$F9,$29,$0C,$19;{$ENDIF} 
   add rbx, rdx;
   add rax, r9;
   jnz @addforyloop2_2;

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
   @addforyloop_1:
       {$IFDEF AVXSUP}vmovsd xmm0, [r8 + rax];                        {$ELSE}db $C4,$C1,$7B,$10,$04,$00;{$ENDIF} 
       {$IFDEF AVXSUP}vmulsd xmm0, xmm0, xmm0;                        {$ELSE}db $C5,$FB,$59,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vaddsd xmm1, xmm1, xmm0;                        {$ELSE}db $C5,$F3,$58,$C8;{$ENDIF} 
   add rax, r9;
   jnz @addforyloop_1;


   // build result
   lea rax, [rip + cOne];
   {$IFDEF AVXSUP}vmovsd xmm2, [rax];                                 {$ELSE}db $C5,$FB,$10,$10;{$ENDIF} 
   {$IFDEF AVXSUP}vsqrtsd xmm1, xmm1, xmm1;                           {$ELSE}db $C5,$F3,$51,$C9;{$ENDIF} 
   {$IFDEF AVXSUP}vdivsd xmm0, xmm2, xmm1;                            {$ELSE}db $C5,$EB,$5E,$C1;{$ENDIF} 

   // normalize last column
   mov rax, r10;
   xor rbx, rbx;
   @addforyloop2_1:
      {$IFDEF AVXSUP}vmovsd xmm1, [r8 + rax];                         {$ELSE}db $C4,$C1,$7B,$10,$0C,$00;{$ENDIF} 
      {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm0;                         {$ELSE}db $C5,$F3,$59,$C8;{$ENDIF} 
      {$IFDEF AVXSUP}vmovsd [rcx + rbx], xmm1;                        {$ELSE}db $C5,$FB,$11,$0C,$19;{$ENDIF} 
   add rbx, rdx;
   add rax, r9;
   jnz @addforyloop2_1;

   @@endProc:

   // epilog
   mov rbx, iRBX;
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;


procedure AVXMatrixNormalizeColumnUnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var iRBX : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
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

   // prolog
   mov iRBX, rbx;

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1 and dest pointers
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
           {$IFDEF AVXSUP}vmovupd ymm3, [r8 + rax];                   {$ELSE}db $C4,$C1,$7D,$10,$1C,$00;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm3;                    {$ELSE}db $C5,$E5,$59,$DB;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm3;                    {$ELSE}db $C5,$F5,$58,$CB;{$ENDIF} 
       add rax, r9;
       jnz @addforyloop4;

       // normalization factor
       lea rax, [rip + cOne];
       {$IFDEF AVXSUP}vbroadcastsd ymm2, [rax];                       {$ELSE}db $C4,$E2,$7D,$19,$10;{$ENDIF} 
       {$IFDEF AVXSUP}vsqrtpd ymm1, ymm1;                             {$ELSE}db $C5,$FD,$51,$C9;{$ENDIF} 
       {$IFDEF AVXSUP}vdivpd ymm0, ymm2, ymm1;                        {$ELSE}db $C5,$ED,$5E,$C1;{$ENDIF} 

       // normalize
       mov rax, r10;
       xor rbx, rbx;
       @addforyloop4_2:
           {$IFDEF AVXSUP}vmovupd ymm1, [r8 + rax];                   {$ELSE}db $C4,$C1,$7D,$10,$0C,$00;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm0;                    {$ELSE}db $C5,$F5,$59,$C8;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd [rcx + rbx], ymm1;                  {$ELSE}db $C5,$FD,$11,$0C,$19;{$ENDIF} 

       add rbx, rdx;
       add rax, r9;
       jnz @addforyloop4_2;

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
       {$IFDEF AVXSUP}vmulpd xmm0, xmm0, xmm0;                        {$ELSE}db $C5,$F9,$59,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vaddpd xmm1, xmm1, xmm0;                        {$ELSE}db $C5,$F1,$58,$C8;{$ENDIF} 
   add rax, r9;
   jnz @addforyloop2;

   // normalization factor
   lea rax, [rip + cOne];
   {$IFDEF AVXSUP}vmovddup xmm2, [rax];                               {$ELSE}db $C5,$FB,$12,$10;{$ENDIF} 
   {$IFDEF AVXSUP}vsqrtpd xmm1, xmm1;                                 {$ELSE}db $C5,$F9,$51,$C9;{$ENDIF} 
   {$IFDEF AVXSUP}vdivpd xmm0, xmm2, xmm1;                            {$ELSE}db $C5,$E9,$5E,$C1;{$ENDIF} 

   // normalize
   mov rax, r10;
   xor rbx, rbx;
   @addforyloop2_2:
      {$IFDEF AVXSUP}vmovupd xmm1, [r8 + rax];                        {$ELSE}db $C4,$C1,$79,$10,$0C,$00;{$ENDIF} 
      {$IFDEF AVXSUP}vmulpd xmm1, xmm1, xmm0;                         {$ELSE}db $C5,$F1,$59,$C8;{$ENDIF} 
      {$IFDEF AVXSUP}vmovupd [rcx + rbx], xmm1;                       {$ELSE}db $C5,$F9,$11,$0C,$19;{$ENDIF} 
   add rbx, rdx;
   add rax, r9;
   jnz @addforyloop2_2;

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
   @addforyloop_1:
       {$IFDEF AVXSUP}vmovsd xmm0, [r8 + rax];                        {$ELSE}db $C4,$C1,$7B,$10,$04,$00;{$ENDIF} 
       {$IFDEF AVXSUP}vmulsd xmm0, xmm0, xmm0;                        {$ELSE}db $C5,$FB,$59,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vaddsd xmm1, xmm1, xmm0;                        {$ELSE}db $C5,$F3,$58,$C8;{$ENDIF} 
   add rax, r9;
   jnz @addforyloop_1;


   // build result
   lea rax, [rip + cOne];
   {$IFDEF AVXSUP}vmovsd xmm2, [rax];                                 {$ELSE}db $C5,$FB,$10,$10;{$ENDIF} 
   {$IFDEF AVXSUP}vsqrtsd xmm1, xmm1, xmm1;                           {$ELSE}db $C5,$F3,$51,$C9;{$ENDIF} 
   {$IFDEF AVXSUP}vdivsd xmm0, xmm2, xmm1;                            {$ELSE}db $C5,$EB,$5E,$C1;{$ENDIF} 

   // normalize last column
   mov rax, r10;
   xor rbx, rbx;
   @addforyloop2_1:
      {$IFDEF AVXSUP}vmovsd xmm1, [r8 + rax];                         {$ELSE}db $C4,$C1,$7B,$10,$0C,$00;{$ENDIF} 
      {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm0;                         {$ELSE}db $C5,$F3,$59,$C8;{$ENDIF} 
      {$IFDEF AVXSUP}vmovsd [rcx + rbx], xmm1;                        {$ELSE}db $C5,$FB,$11,$0C,$19;{$ENDIF} 
   add rbx, rdx;
   add rax, r9;
   jnz @addforyloop2_1;

   @@endProc:

   // epilog
   mov rbx, iRBX;
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

{$ENDIF}

end.
