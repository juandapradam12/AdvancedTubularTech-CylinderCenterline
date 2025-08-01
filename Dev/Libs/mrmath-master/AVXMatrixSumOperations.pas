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


unit AVXMatrixSumOperations;

interface

{$I 'mrMath_CPU.inc'}

{$IFNDEF x64}

procedure AVXMatrixSumRowAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
procedure AVXMatrixSumRowUnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}

procedure AVXMatrixSumColumnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
procedure AVXMatrixSumColumnUnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}

function AVXMatrixSumUnAligned( Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt) : double; {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
function AVXMatrixSumAligned( Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt) : double; {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}

{$ENDIF}

implementation

{$IFNDEF x64}

procedure AVXMatrixSumRowAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt);
asm
   // prolog
   push ebx;
   push edi;
   push esi;

   // iters := -width*sizeof(double)
   mov edi, width;
   imul edi, -8;

   mov ebx, srcLineWidth;

   // helper registers for the mt1, mt2 and dest pointers
   sub ecx, edi;

   // for y := 0 to height - 1:
   @@addforyloop:
       {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                        {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                        {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov esi, edi;
       @addforxloop:
           add esi, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [ecx + esi];

           // addition:
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, [ecx + esi - 128];       {$ELSE}db $C5,$FD,$58,$44,$31,$80;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, [ecx + esi - 96];        {$ELSE}db $C5,$F5,$58,$4C,$31,$A0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, [ecx + esi - 64];        {$ELSE}db $C5,$FD,$58,$44,$31,$C0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, [ecx + esi - 32];        {$ELSE}db $C5,$F5,$58,$4C,$31,$E0;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                        {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
       {$IFDEF AVXSUP}vextractf128 xmm2, ymm0, 1;                     {$ELSE}db $C4,$E3,$7D,$19,$C2,$01;{$ENDIF} 
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm2;                       {$ELSE}db $C5,$F9,$7C,$C2;{$ENDIF} 

       sub esi, 128;

       jz @buildRes;

       @addforxloop2:
           add esi, 16;
           jg @@addforxloop2end;

           {$IFDEF AVXSUP}vaddpd xmm0, xmm0, [ecx + esi - 16];        {$ELSE}db $C5,$F9,$58,$44,$31,$F0;{$ENDIF} 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub esi, 16;
       jz @buildRes;

       {$IFDEF AVXSUP}vaddsd xmm0, xmm0, [ecx + esi];                 {$ELSE}db $C5,$FB,$58,$04,$31;{$ENDIF} 

       @buildRes:

       // build result
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                       {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 

       // write result
       {$IFDEF AVXSUP}vmovsd [eax], xmm0;                             {$ELSE}db $C5,$FB,$11,$00;{$ENDIF} 

       // next line:
       add ecx, ebx;
       add eax, destLineWidth;

   // loop y end
   dec Height;
   jnz @@addforyloop;

   // epilog
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
   pop esi;
   pop edi;
   pop ebx;
end;

procedure AVXMatrixSumRowUnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt);
asm
   // prolog
   push ebx;
   push edi;
   push esi;

   // iters := -width*sizeof(double)
   mov edi, width;
   imul edi, -8;

   // helper registers for the mt1, mt2 and dest pointers
   sub ecx, edi;

   mov ebx, srcLineWidth;
   // for y := 0 to height - 1:
   @@addforyloop:
       {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                        {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                        {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov esi, edi;
       @addforxloop:
           add esi, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [ecx + esi];

           // addition:
           {$IFDEF AVXSUP}vmovupd ymm2, [ecx + esi - 128];            {$ELSE}db $C5,$FD,$10,$54,$31,$80;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm2;                    {$ELSE}db $C5,$FD,$58,$C2;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd ymm2, [ecx + esi - 96];             {$ELSE}db $C5,$FD,$10,$54,$31,$A0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd ymm2, [ecx + esi - 64];             {$ELSE}db $C5,$FD,$10,$54,$31,$C0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm2;                    {$ELSE}db $C5,$FD,$58,$C2;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd ymm2, [ecx + esi - 32];             {$ELSE}db $C5,$FD,$10,$54,$31,$E0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                        {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
       {$IFDEF AVXSUP}vextractf128 xmm2, ymm0, 1;                     {$ELSE}db $C4,$E3,$7D,$19,$C2,$01;{$ENDIF} 
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm2;                       {$ELSE}db $C5,$F9,$7C,$C2;{$ENDIF} 

       sub esi, 128;

       jz @buildRes;

       @addforxloop2:
           add esi, 16;
           jg @@addforxloop2end;

           {$IFDEF AVXSUP}vmovupd xmm2, [ecx + esi - 16];             {$ELSE}db $C5,$F9,$10,$54,$31,$F0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm2;                    {$ELSE}db $C5,$F9,$58,$C2;{$ENDIF} 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub esi, 16;
       jz @buildRes;

       {$IFDEF AVXSUP}vaddsd xmm0, xmm0, [ecx + esi];                 {$ELSE}db $C5,$FB,$58,$04,$31;{$ENDIF} 

       @buildRes:

       // build result
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                       {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 

       // write result
       {$IFDEF AVXSUP}vmovsd [eax], xmm0;                             {$ELSE}db $C5,$FB,$11,$00;{$ENDIF} 

       // next line:
       add ecx, ebx;
       add eax, edx;

   // loop y end
   dec Height;
   jnz @@addforyloop;

   // epilog
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
   pop esi;
   pop edi;
   pop ebx;
end;

function AVXMatrixSumUnAligned( Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt) : double; {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
// src : eax; srcLineWidth : edx; width = ecx;
asm
   // prolog
   push edi;
   push esi;

   // iters := -width*sizeof(double)
   imul ecx, -8;

   // helper registers for the mt1, mt2 and dest pointers
   sub eax, ecx;

   {$IFDEF AVXSUP}vxorpd xmm4, xmm4, xmm4;                            {$ELSE}db $C5,$D9,$57,$E4;{$ENDIF} 

   // for y := 0 to height - 1:
   @@addforyloop:
       {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                        {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                        {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov esi, ecx;
       @addforxloop:
           add esi, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [eax + esi];

           // addition:
           {$IFDEF AVXSUP}vmovupd ymm2, [eax + esi - 128];            {$ELSE}db $C5,$FD,$10,$54,$30,$80;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm2;                    {$ELSE}db $C5,$FD,$58,$C2;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd ymm2, [eax + esi - 96];             {$ELSE}db $C5,$FD,$10,$54,$30,$A0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd ymm2, [eax + esi - 64];             {$ELSE}db $C5,$FD,$10,$54,$30,$C0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm2;                    {$ELSE}db $C5,$FD,$58,$C2;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd ymm2, [eax + esi - 32];             {$ELSE}db $C5,$FD,$10,$54,$30,$E0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm2;                    {$ELSE}db $C5,$F5,$58,$CA;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                        {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
       {$IFDEF AVXSUP}vextractf128 xmm2, ymm0, 1;                     {$ELSE}db $C4,$E3,$7D,$19,$C2,$01;{$ENDIF} 
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm2;                       {$ELSE}db $C5,$F9,$7C,$C2;{$ENDIF} 

       sub esi, 128;

       jz @buildRes;

       @addforxloop2:
           add esi, 16;
           jg @@addforxloop2end;

           {$IFDEF AVXSUP}vmovupd xmm2, [eax + esi - 16];             {$ELSE}db $C5,$F9,$10,$54,$30,$F0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm2;                    {$ELSE}db $C5,$F9,$58,$C2;{$ENDIF} 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub esi, 16;
       jz @buildRes;

       {$IFDEF AVXSUP}vaddsd xmm0, xmm0, [eax + esi];                 {$ELSE}db $C5,$FB,$58,$04,$30;{$ENDIF} 

       @buildRes:

       // build result
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                       {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vaddsd xmm4, xmm4, xmm0;                        {$ELSE}db $C5,$DB,$58,$E0;{$ENDIF} 

       // next line:
       add eax, edx;

   // loop y end
   dec Height;
   jnz @@addforyloop;

   // epilog
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 

   movsd Result, xmm4;

   pop esi;
   pop edi;
end;

function AVXMatrixSumAligned( Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt) : double; {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
// src : eax; srcLineWidth : edx; width = ecx;
asm
   // prolog
   push edi;
   push esi;

   // iters := -width*sizeof(double)
   imul ecx, -8;

   // helper registers for the mt1, mt2 and dest pointers
   sub eax, ecx;

   {$IFDEF AVXSUP}vxorpd xmm4, xmm4, xmm4;                            {$ELSE}db $C5,$D9,$57,$E4;{$ENDIF} 

   // for y := 0 to height - 1:
   @@addforyloop:
       {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                        {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                        {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov esi, ecx;
       @addforxloop:
           add esi, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [eax + esi];

           // addition:
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, [eax + esi - 128];       {$ELSE}db $C5,$FD,$58,$44,$30,$80;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, [eax + esi - 96];        {$ELSE}db $C5,$F5,$58,$4C,$30,$A0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm0, ymm0, [eax + esi - 64];        {$ELSE}db $C5,$FD,$58,$44,$30,$C0;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, [eax + esi - 32];        {$ELSE}db $C5,$F5,$58,$4C,$30,$E0;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                        {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
       {$IFDEF AVXSUP}vextractf128 xmm2, ymm0, 1;                     {$ELSE}db $C4,$E3,$7D,$19,$C2,$01;{$ENDIF} 
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm2;                       {$ELSE}db $C5,$F9,$7C,$C2;{$ENDIF} 

       sub esi, 128;

       jz @buildRes;

       @addforxloop2:
           add esi, 16;
           jg @@addforxloop2end;

           {$IFDEF AVXSUP}vaddpd xmm0, xmm0, [eax + esi - 16];        {$ELSE}db $C5,$F9,$58,$44,$30,$F0;{$ENDIF} 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub esi, 16;
       jz @buildRes;

       {$IFDEF AVXSUP}vaddsd xmm0, xmm0, [eax + esi];                 {$ELSE}db $C5,$FB,$58,$04,$30;{$ENDIF} 

       @buildRes:

       // build result
       {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                       {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 
       {$IFDEF AVXSUP}vaddsd xmm4, xmm4, xmm0;                        {$ELSE}db $C5,$DB,$58,$E0;{$ENDIF} 

       // next line:
       add eax, edx;

   // loop y end
   dec Height;
   jnz @@addforyloop;

   // epilog
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 

   movsd Result, xmm4;

   pop esi;
   pop edi;
end;

procedure AVXMatrixSumColumnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt);
asm
   // prolog
   push ebx;
   push edi;
   push esi;

   // init
   xor edi, edi;
   sub edi, height;
   imul edi, srcLineWidth;

   mov ebx, srcLineWidth;

   // helper registers for the mt1, mt2 and dest pointers
   sub ecx, edi;

   // for x := 0 to width - 1:
   sub Width, 4;
   jl @@addforxloop4end;

   // 4 columns at once
   @@addforxloop4:
       {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                        {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov esi, edi;
       @addforyloop4:
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, [ecx + esi];             {$ELSE}db $C5,$F5,$58,$0C,$31;{$ENDIF} 
       add esi, ebx;
       jnz @addforyloop4;

       // build result
       {$IFDEF AVXSUP}vmovapd [eax], ymm1;                            {$ELSE}db $C5,$FD,$29,$08;{$ENDIF} 

       // next columns:
       add eax, 32;
       add ecx, 32;

   // loop x end
   sub Width, 4;
   jge @@addforxloop4;

   @@addforxloop4end:

   add Width, 4;
   jz @@endProc;

   sub Width, 2;
   jl @@lastcolumn;

   {$IFDEF AVXSUP}vxorpd xmm1, xmm1, xmm1;                            {$ELSE}db $C5,$F1,$57,$C9;{$ENDIF} 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov esi, edi;
   @addforyloop2:
       {$IFDEF AVXSUP}vaddpd xmm1, xmm1, [ecx + esi];                 {$ELSE}db $C5,$F1,$58,$0C,$31;{$ENDIF} 
   add esi, ebx;
   jnz @addforyloop2;

   // build result
   {$IFDEF AVXSUP}vmovapd [eax], xmm1;                                {$ELSE}db $C5,$F9,$29,$08;{$ENDIF} 

   // next columns:
   add eax, 16;
   add ecx, 16;

   dec width;
   jnz @@endProc;

   @@lastcolumn:

   {$IFDEF AVXSUP}vxorpd xmm1, xmm1, xmm1;                            {$ELSE}db $C5,$F1,$57,$C9;{$ENDIF} 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov esi, edi;
   @addforyloop:
       {$IFDEF AVXSUP}vaddsd xmm1, xmm1, [ecx + esi];                 {$ELSE}db $C5,$F3,$58,$0C,$31;{$ENDIF} 
   add esi, ebx;
   jnz @addforyloop;

   // build result
   {$IFDEF AVXSUP}vmovsd [eax], xmm1;                                 {$ELSE}db $C5,$FB,$11,$08;{$ENDIF} 

   @@endProc:
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
   pop esi;
   pop edi;
   pop ebx;
end;

procedure AVXMatrixSumColumnUnAligned(dest : PDouble; const destLineWidth : NativeInt; Src : PDouble; const srcLineWidth : NativeInt; width, height : NativeInt);
asm
   // prolog
   push ebx;
   push edi;
   push esi;

   // prepare
   xor edi, edi;
   sub edi, height;
   imul edi, srcLineWidth;

   // helper registers for the mt1, mt2 and dest pointers
   sub ecx, edi;

   mov ebx, srcLineWidth;

   // for x := 0 to width - 1:
   sub Width, 4;
   jl @@addforxloop4end;

   // 4 columns at once
   @@addforxloop4:
       {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                        {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov esi, edi;
       @addforyloop4:
           {$IFDEF AVXSUP}vmovupd ymm0, [ecx + esi];                  {$ELSE}db $C5,$FD,$10,$04,$31;{$ENDIF} 
           {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm0;                    {$ELSE}db $C5,$F5,$58,$C8;{$ENDIF} 
       add esi, ebx;
       jnz @addforyloop4;

       // build result
       {$IFDEF AVXSUP}vmovupd [eax], ymm1;                            {$ELSE}db $C5,$FD,$11,$08;{$ENDIF} 

       // next columns:
       add eax, 32;
       add ecx, 32;

   // loop x end
   sub Width, 4;
   jge @@addforxloop4;

   @@addforxloop4end:

   add Width, 4;
   jz @@endProc;

   sub Width, 2;
   jl @@lastcolumn;

   {$IFDEF AVXSUP}vxorpd xmm1, xmm1, xmm1;                            {$ELSE}db $C5,$F1,$57,$C9;{$ENDIF} 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov esi, edi;
   @addforyloop2:
       {$IFDEF AVXSUP}vmovupd xmm0, [ecx + esi];                      {$ELSE}db $C5,$F9,$10,$04,$31;{$ENDIF} 
       {$IFDEF AVXSUP}vaddpd xmm1, xmm1, [ecx + esi];                 {$ELSE}db $C5,$F1,$58,$0C,$31;{$ENDIF} 
   add esi, ebx;
   jnz @addforyloop2;

   // build result
   {$IFDEF AVXSUP}vmovupd [eax], xmm1;                                {$ELSE}db $C5,$F9,$11,$08;{$ENDIF} 

   // next columns:
   add eax, 16;
   add ecx, 16;

   dec Width;
   jnz @@endProc;

   @@lastcolumn:

   {$IFDEF AVXSUP}vxorpd xmm1, xmm1, xmm1;                            {$ELSE}db $C5,$F1,$57,$C9;{$ENDIF} 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov esi, edi;
   @addforyloop:
       {$IFDEF AVXSUP}vaddsd xmm1, xmm1, [ecx + esi];                 {$ELSE}db $C5,$F3,$58,$0C,$31;{$ENDIF} 
   add esi, ebx;
   jnz @addforyloop;

   // build result
   {$IFDEF AVXSUP}vmovsd [eax], xmm1;                                 {$ELSE}db $C5,$FB,$11,$08;{$ENDIF} 

   @@endProc:
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 

   pop esi;
   pop edi;
   pop ebx;
end;

{$ENDIF}

end.
