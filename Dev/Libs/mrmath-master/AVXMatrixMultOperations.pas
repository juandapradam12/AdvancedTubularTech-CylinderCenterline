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


unit AVXMatrixMultOperations;

interface

{$I 'mrMath_CPU.inc'}

{$IFNDEF x64}

// full matrix operations
procedure AVXMatrixMultAligned(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; width1, height1, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
procedure AVXMatrixMultUnAligned(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; width1, height1, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}


// some special types of multiplications used e.g. in QR Decomposition
// dest = mt1'*mt2; where mt2 is a lower triangular matrix and the operation is transposition
// the function assumes a unit diagonal (does not touch the real middle elements)
// width and height values are assumed to be the "original" (non transposed) ones
procedure AVXMtxMultTria2T1(dest : PDouble; LineWidthDest : NativeInt; mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  width1, height1, width2, height2 : NativeInt); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}

// mt1 = mt1*mt2'; where mt2 is an upper triangular matrix
procedure AVXMtxMultTria2T1StoreT1(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  width1, height1, width2, height2 : NativeInt); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}

// W = C1*V1*T -> V1 is an upper triangular matrix with assumed unit diagonal entries. Operation on V1 transposition
procedure AVXMtxMultTria2TUpperUnit(dest : PDouble; LineWidthDest : NativeInt; mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  width1, height1, width2, height2 : NativeInt); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}

// mt1 = mt1*mt2; where mt2 is an upper triangular matrix
procedure AVXMtxMultTria2Store1(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  width1, height1, width2, height2 : NativeInt); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}

// calculates mt1 = mt1*mt2', mt2 = lower triangular matrix. diagonal elements are assumed to be 1!
procedure AVXMtxMultLowTria2T2Store1(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  width1, height1, width2, height2 : NativeInt); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}

// mt1 = mt1*mt2; where mt2 is an upper triangular matrix - diagonal elements are unit
procedure AVXMtxMultTria2Store1Unit(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  width1, height1, width2, height2 : NativeInt); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}


// performs a rank2 update in the form
// C = C - A*B' - B*A'
// N...order of C (N x N matrix)
// k... number of columns of A and B
// the lower triangle of C is not referenced
procedure AVXSymRank2UpdateUpperUnaligned( C : PDouble; LineWidthC : NativeInt; A : PDouble; LineWidthA : NativeInt;
  B : PDouble; LineWidthB : NativeInt; N : NativeInt; k : NativeInt ); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}



{$ENDIF}

implementation

{$IFNDEF x64}

procedure AVXMatrixMultAligned(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; width1, height1, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt);
var bytesWidth2, destOffset : NativeInt;
    iter : NativeInt;
// eax = dest; edx = destLineWidth; ecx = mtx
asm
   // prolog - simulate stack
   push ebx;
   push edi;
   push esi;

   mov edi, width1;
   imul edi, -8;
   mov iter, edi;

   sub ecx, edi;

   //destOffset := destLineWidth - Width2*sizeof(double);
   mov ebx, Width2;
   shl ebx, 3;
   sub edx, ebx;
   mov destOffset, edx;

   //bytesWidth2 := width2*sizeof(double);
   mov bytesWidth2, ebx;

   // for y := 0 to height1 - 1 do
   @@foryloop:

      mov esi, width2;
      sub esi, 2;
      jl @LastXColumn;

      @@forxloop:
      // for x := 0 to width2 div 2 - 1
          // esi: mt1 - width1*sizeof(double)
          // mt2: mt2

          //mov ecx, mt1;
          mov ebx, mt2;
          mov edx, iter;
          mov edi, LineWidth2;

          {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                     {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
          {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                     {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

          cmp edx, -32;
          jg @@Innerloop2Begin;

          // for z := 0 to width1 - 1do
          // AVX part:
          @@InnerLoop1:
             // 4x4 block
             {$IFDEF AVXSUP}vmovapd xmm2, [ebx];                      {$ELSE}db $C5,$F9,$28,$13;{$ENDIF} 
             add ebx, edi;
             {$IFDEF AVXSUP}vmovapd xmm4, xmm2;                       {$ELSE}db $C5,$F9,$29,$D4;{$ENDIF} 

             {$IFDEF AVXSUP}vmovapd xmm3, [ebx];                      {$ELSE}db $C5,$F9,$28,$1B;{$ENDIF} 
             add ebx, edi;

             // shuffle so we can multiply

             // swap such that we can immediately multiply
             {$IFDEF AVXSUP}vmovlhps xmm2, xmm2, xmm3;                {$ELSE}db $C5,$E8,$16,$D3;{$ENDIF} 
             {$IFDEF AVXSUP}vmovhlps xmm3, xmm3, xmm4;                {$ELSE}db $C5,$E0,$12,$DC;{$ENDIF} 

             // next 4 elements
             {$IFDEF AVXSUP}vmovapd xmm4, [ebx];                      {$ELSE}db $C5,$F9,$28,$23;{$ENDIF} 
             add ebx, edi;
             {$IFDEF AVXSUP}vmovapd xmm6, xmm4;                       {$ELSE}db $C5,$F9,$29,$E6;{$ENDIF} 

             {$IFDEF AVXSUP}vmovapd xmm5, [ebx];                      {$ELSE}db $C5,$F9,$28,$2B;{$ENDIF} 
             add ebx, edi;

             {$IFDEF AVXSUP}vmovapd ymm7, [ecx + edx]                 {$ELSE}db $C5,$FD,$28,$3C,$11;{$ENDIF} 

             {$IFDEF AVXSUP}vmovlhps xmm4, xmm4, xmm5;                {$ELSE}db $C5,$D8,$16,$E5;{$ENDIF} 
             {$IFDEF AVXSUP}vmovhlps xmm5, xmm5, xmm6;                {$ELSE}db $C5,$D0,$12,$EE;{$ENDIF} 

             {$IFDEF AVXSUP}vinsertf128 ymm2, ymm2, xmm4, 1;          {$ELSE}db $C4,$E3,$6D,$18,$D4,$01;{$ENDIF} 
             {$IFDEF AVXSUP}vinsertf128 ymm3, ymm3, xmm5, 1;          {$ELSE}db $C4,$E3,$65,$18,$DD,$01;{$ENDIF} 

             // now multiply and add
             {$IFDEF AVXSUP}vmulpd ymm2, ymm2, ymm7;                  {$ELSE}db $C5,$ED,$59,$D7;{$ENDIF} 
             {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm7;                  {$ELSE}db $C5,$E5,$59,$DF;{$ENDIF} 

             {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm2;                  {$ELSE}db $C5,$FD,$58,$C2;{$ENDIF} 
             {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm3;                  {$ELSE}db $C5,$F5,$58,$CB;{$ENDIF} 
          add edx, 32;
          jl @@InnerLoop1;

          {$IFDEF AVXSUP}vextractf128 xmm2, ymm0, 1;                  {$ELSE}db $C4,$E3,$7D,$19,$C2,$01;{$ENDIF} 
          {$IFDEF AVXSUP}vextractf128 xmm3, ymm1, 1;                  {$ELSE}db $C4,$E3,$7D,$19,$CB,$01;{$ENDIF} 

          {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm2;                    {$ELSE}db $C5,$F9,$7C,$C2;{$ENDIF} 
          {$IFDEF AVXSUP}vhaddpd xmm1, xmm1, xmm3;                    {$ELSE}db $C5,$F1,$7C,$CB;{$ENDIF} 

          test edx, edx;
          jz @@InnerLoopEnd2;

          @@Innerloop2Begin:

          // rest in single elements
          @@InnerLoop2:
             {$IFDEF AVXSUP}vmovapd xmm2, [ebx];                      {$ELSE}db $C5,$F9,$28,$13;{$ENDIF} 
             add ebx, edi;

             {$IFDEF AVXSUP}vmovddup xmm3, [ecx + edx];               {$ELSE}db $C5,$FB,$12,$1C,$11;{$ENDIF} 

             {$IFDEF AVXSUP}vmulpd xmm2, xmm2, xmm3;                  {$ELSE}db $C5,$E9,$59,$D3;{$ENDIF} 
             {$IFDEF AVXSUP}vmovhlps xmm4, xmm4, xmm2;                {$ELSE}db $C5,$D8,$12,$E2;{$ENDIF} 

             {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm2;                  {$ELSE}db $C5,$FB,$58,$C2;{$ENDIF} 
             {$IFDEF AVXSUP}vaddsd xmm1, xmm1, xmm4;                  {$ELSE}db $C5,$F3,$58,$CC;{$ENDIF} 
          add edx, 8;
          jnz @@InnerLoop2;

          @@InnerLoopEnd2:

          // finall horizontal addition
          {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm1;                    {$ELSE}db $C5,$F9,$7C,$C1;{$ENDIF} 

          {$IFDEF AVXSUP}vmovapd [eax], xmm0;                         {$ELSE}db $C5,$F9,$29,$00;{$ENDIF} 

          // increment the pointers
          // inc(mt2), inc(dest);
          //add dword ptr [mt2], 8;
          add mt2, 16;
          add eax, 16;

      // end for x := 0 to width2 div 2 - 1
      sub esi, 2;
      jge @@forxloop;

      @LastXColumn:

      cmp esi, -1;
      jne @NextLine;

      // last column of mt2
      mov edx, iter;
      mov ebx, mt2;

      {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                         {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 

      @InnerLoop2:
         {$IFDEF AVXSUP}vmovsd xmm1, [ecx + edx];                     {$ELSE}db $C5,$FB,$10,$0C,$11;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd xmm2, [ebx];                           {$ELSE}db $C5,$FB,$10,$13;{$ENDIF} 

         {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                      {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
         {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                      {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 

         add ebx, edi;
      add edx, 8;
      jnz @InnerLoop2;

      {$IFDEF AVXSUP}vmovsd [eax], xmm0;                              {$ELSE}db $C5,$FB,$11,$00;{$ENDIF} 
      add eax, 8;
      add mt2, 8;

      @NextLine:
      // dec(mt2, Width2);
      // inc(PByte(mt1), LineWidth1);
      // inc(PByte(dest), destOffset);
      //mov ebx, bytesWidth2;
      //sub dword ptr [mt2], ebx;
      mov edx, bytesWidth2;
      sub mt2, edx;

      add eax, destOffset;
      add ecx, LineWidth1;

   // end for y := 0 to height1 - 1
   dec height1;
   jnz @@foryloop;

   // epilog
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 

   pop esi;
   pop edi;
   pop ebx;
end;

procedure AVXMatrixMultUnAligned(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; width1, height1, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt);
var bytesWidth2, destOffset : NativeInt;
    iter : NativeInt;
// eax = dest; edx = destLineWidth; ecx = mtx
asm
   // prolog - simulate stack
   push ebx;
   push edi;
   push esi;

   mov edi, width1;
   imul edi, -8;
   mov iter, edi;

   sub ecx, edi;

   //destOffset := destLineWidth - Width2*sizeof(double);
   mov ebx, Width2;
   shl ebx, 3;
   sub edx, ebx;
   mov destOffset, edx;

   //bytesWidth2 := width2*sizeof(double);
   mov bytesWidth2, ebx;

   // for y := 0 to height1 - 1 do
   @@foryloop:

      mov esi, width2;
      sub esi, 2;
      jl @LastXColumn;

      @@forxloop:
      // for x := 0 to width2 div 2 - 1
          // esi: mt1 - width1*sizeof(double)
          // mt2: mt2

          //mov ecx, mt1;
          mov ebx, mt2;
          mov edx, iter;
          mov edi, LineWidth2;

          {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                     {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
          {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                     {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

          cmp edx, -32;
          jg @@Innerloop2Begin;

          // for z := 0 to width1 - 1do
          // AVX part:
          @@InnerLoop1:
             // 4x4 block
             {$IFDEF AVXSUP}vmovupd xmm2, [ebx];                      {$ELSE}db $C5,$F9,$10,$13;{$ENDIF} 
             add ebx, edi;
             {$IFDEF AVXSUP}vmovupd xmm4, xmm2;                       {$ELSE}db $C5,$F9,$11,$D4;{$ENDIF} 

             {$IFDEF AVXSUP}vmovupd xmm3, [ebx];                      {$ELSE}db $C5,$F9,$10,$1B;{$ENDIF} 
             add ebx, edi;

             // shuffle so we can multiply

             // swap such that we can immediately multiply
             {$IFDEF AVXSUP}vmovlhps xmm2, xmm2, xmm3;                {$ELSE}db $C5,$E8,$16,$D3;{$ENDIF} 
             {$IFDEF AVXSUP}vmovhlps xmm3, xmm3, xmm4;                {$ELSE}db $C5,$E0,$12,$DC;{$ENDIF} 

             // next 4 elements
             {$IFDEF AVXSUP}vmovupd xmm4, [ebx];                      {$ELSE}db $C5,$F9,$10,$23;{$ENDIF} 
             add ebx, edi;
             {$IFDEF AVXSUP}vmovupd xmm6, xmm4;                       {$ELSE}db $C5,$F9,$11,$E6;{$ENDIF} 

             {$IFDEF AVXSUP}vmovupd xmm5, [ebx];                      {$ELSE}db $C5,$F9,$10,$2B;{$ENDIF} 
             add ebx, edi;

             {$IFDEF AVXSUP}vmovupd ymm7, [ecx + edx]                 {$ELSE}db $C5,$FD,$10,$3C,$11;{$ENDIF} 

             {$IFDEF AVXSUP}vmovlhps xmm4, xmm4, xmm5;                {$ELSE}db $C5,$D8,$16,$E5;{$ENDIF} 
             {$IFDEF AVXSUP}vmovhlps xmm5, xmm5, xmm6;                {$ELSE}db $C5,$D0,$12,$EE;{$ENDIF} 

             {$IFDEF AVXSUP}vinsertf128 ymm2, ymm2, xmm4, 1;          {$ELSE}db $C4,$E3,$6D,$18,$D4,$01;{$ENDIF} 
             {$IFDEF AVXSUP}vinsertf128 ymm3, ymm3, xmm5, 1;          {$ELSE}db $C4,$E3,$65,$18,$DD,$01;{$ENDIF} 

             // now multiply and add
             {$IFDEF AVXSUP}vmulpd ymm2, ymm2, ymm7;                  {$ELSE}db $C5,$ED,$59,$D7;{$ENDIF} 
             {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm7;                  {$ELSE}db $C5,$E5,$59,$DF;{$ENDIF} 

             {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm2;                  {$ELSE}db $C5,$FD,$58,$C2;{$ENDIF} 
             {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm3;                  {$ELSE}db $C5,$F5,$58,$CB;{$ENDIF} 
          add edx, 32;
          jl @@InnerLoop1;

          {$IFDEF AVXSUP}vextractf128 xmm2, ymm0, 1;                  {$ELSE}db $C4,$E3,$7D,$19,$C2,$01;{$ENDIF} 
          {$IFDEF AVXSUP}vextractf128 xmm3, ymm1, 1;                  {$ELSE}db $C4,$E3,$7D,$19,$CB,$01;{$ENDIF} 

          {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm2;                    {$ELSE}db $C5,$F9,$7C,$C2;{$ENDIF} 
          {$IFDEF AVXSUP}vhaddpd xmm1, xmm1, xmm3;                    {$ELSE}db $C5,$F1,$7C,$CB;{$ENDIF} 

          test edx, edx;
          jz @@InnerLoopEnd2;

          @@Innerloop2Begin:

          // rest in single elements
          @@InnerLoop2:
             {$IFDEF AVXSUP}vmovupd xmm2, [ebx];                      {$ELSE}db $C5,$F9,$10,$13;{$ENDIF} 
             add ebx, edi;

             {$IFDEF AVXSUP}vmovddup xmm3, [ecx + edx];               {$ELSE}db $C5,$FB,$12,$1C,$11;{$ENDIF} 

             {$IFDEF AVXSUP}vmulpd xmm2, xmm2, xmm3;                  {$ELSE}db $C5,$E9,$59,$D3;{$ENDIF} 
             {$IFDEF AVXSUP}vmovhlps xmm4, xmm4, xmm2;                {$ELSE}db $C5,$D8,$12,$E2;{$ENDIF} 

             {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm2;                  {$ELSE}db $C5,$FB,$58,$C2;{$ENDIF} 
             {$IFDEF AVXSUP}vaddsd xmm1, xmm1, xmm4;                  {$ELSE}db $C5,$F3,$58,$CC;{$ENDIF} 
          add edx, 8;
          jnz @@InnerLoop2;

          @@InnerLoopEnd2:

          // finall horizontal addition
          {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm1;                    {$ELSE}db $C5,$F9,$7C,$C1;{$ENDIF} 

          {$IFDEF AVXSUP}vmovupd [eax], xmm0;                         {$ELSE}db $C5,$F9,$11,$00;{$ENDIF} 

          // increment the pointers
          // inc(mt2), inc(dest);
          //add dword ptr [mt2], 8;
          add mt2, 16;
          add eax, 16;

      // end for x := 0 to width2 div 2 - 1
      sub esi, 2;
      jge @@forxloop;

      @LastXColumn:

      cmp esi, -1;
      jne @NextLine;

      // last column of mt2
      mov edx, iter;
      mov ebx, mt2;

      {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                         {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 

      @InnerLoop2:
         {$IFDEF AVXSUP}vmovsd xmm1, [ecx + edx];                     {$ELSE}db $C5,$FB,$10,$0C,$11;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd xmm2, [ebx];                           {$ELSE}db $C5,$FB,$10,$13;{$ENDIF} 

         {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                      {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
         {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                      {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 

         add ebx, edi;
      add edx, 8;
      jnz @InnerLoop2;

      {$IFDEF AVXSUP}vmovsd [eax], xmm0;                              {$ELSE}db $C5,$FB,$11,$00;{$ENDIF} 
      add eax, 8;
      add mt2, 8;

      @NextLine:
      // dec(mt2, Width2);
      // inc(PByte(mt1), LineWidth1);
      // inc(PByte(dest), destOffset);
      //mov ebx, bytesWidth2;
      //sub dword ptr [mt2], ebx;
      mov edx, bytesWidth2;
      sub mt2, edx;

      add eax, destOffset;
      add ecx, LineWidth1;

   // end for y := 0 to height1 - 1
   dec height1;
   jnz @@foryloop;

   // epilog
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 

   pop esi;
   pop edi;
   pop ebx;
end;


// ###########################################
// #### Special multiplication routines (for now only used in QR Decomposition)
// ###########################################

// note the result is stored in mt1 again!
// mt1 = mt1*mt2; where mt2 is an upper triangular matrix
procedure AVXMtxMultTria2Store1(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  width1, height1, width2, height2 : NativeInt);
var wm1 : NativeInt;
    iter : NativeInt;
    aLineWidth1 : NativeInt;
// eax = mt1, edx = LineWidth1, ecx = mt2
asm
   push ebx;
   push edi;
   push esi;
   // init

   mov aLineWidth1, edx;

   //wm1 := width2 - 1;
   mov ebx, width2;
   dec ebx;
   mov wm1, ebx;

   // iter := -width1*sizeof(double);
   mov edi, width1;
   imul edi, -8;
   mov iter, edi;

   // inc(mt2, width2 - 1);
   imul ebx, 8;
   add ecx, ebx;

   mov edx, LineWidth2;

   // for x := 0 to width2 - 1 do
   @@forxloop:
      mov edi, height1;

      push eax;
      sub eax, iter;

      // for y := 0 to height1 - 1
      @@foryloop:
         // tmp := 0;
         {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                      {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 

         // mt2
         push ecx;

         // for idx := 0 to width1 - x - 1
         mov esi, iter;

         // check if we have enough iterations:
         test esi, esi;
         jz @@foridxloopend;

         @@foridxloop:
            {$IFDEF AVXSUP}vmovsd xmm1, [ecx];                        {$ELSE}db $C5,$FB,$10,$09;{$ENDIF} 
            {$IFDEF AVXSUP}vmovsd xmm2, [eax + esi]                   {$ELSE}db $C5,$FB,$10,$14,$30;{$ENDIF} 

            add ecx, edx;  // + linewidth2

            {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                   {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                   {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 

         add esi, 8;
         jnz @@foridxloop;

         @@foridxloopend:

         // PConstDoubleArr(pmt1)^[width2 - 1 - x] := tmp;
         mov ecx, eax;
         add ecx, iter;
         mov esi, width2;
         dec esi;
         {$IFDEF AVXSUP}vmovsd [ecx + 8*esi], xmm0;                   {$ELSE}db $C5,$FB,$11,$04,$F1;{$ENDIF} 

         // restore mt2
         pop ecx;

         // inc(PByte(pmT1), LineWidth1);
         add eax, aLineWidth1;

      dec edi;
      jnz @@foryloop;

      // reduce for idx loop
      add iter, 8;
      pop eax;

      // dec(mt2);
      sub ecx, 8;

   dec width2;
   jnz @@forxloop;

   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 

   // cleanup stack
   pop esi;
   pop edi;
   pop ebx;
end;

procedure AVXMtxMultTria2T1StoreT1(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  width1, height1, width2, height2 : NativeInt);
var iter : NativeInt;
    testExitLoopVal : NativeInt;
asm
   // prolog: stack
   push ebx;
   push edi;
   push esi;

   //iter := -width1*sizeof(double);
   mov esi, width1;
   imul esi, -8;
   mov iter, esi;

   // testExitLoopVal := height2*sizeof(double) + iter;
   mov edi, height2;
   shl edi, 3; //*8
   add edi, esi;
   mov testExitLoopVal, edi;

   // eax := mt1
   sub eax, esi;  // mt1 - iter

   // for y loop
   @@foryloop:
      mov esi, iter;
      push ecx;
      sub ecx, esi;

      @@forxloop:
         {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                      {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} // temp := 0

         mov edi, esi;  // loop counter x;

         // test if height2 > width1 and loop counter > width1
         test edi, edi;
         jge @@foriloopend;

         // in case x is odd -> handle the first element separately
         test edi, $E;
         jz @@foriloopAVX;

         // single element handling
         {$IFDEF AVXSUP}vmovsd xmm1, [eax + edi];                     {$ELSE}db $C5,$FB,$10,$0C,$38;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd xmm2, [ecx + edi];                     {$ELSE}db $C5,$FB,$10,$14,$39;{$ENDIF} 
         {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                      {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
         {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                      {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
         add edi, 8;

         @@foriloopAVX:
            // 4 elements at a time
            add edi, 32;
            jg @@foriloopAVXend;

            {$IFDEF AVXSUP}vmovupd ymm1, [eax + edi - 32];            {$ELSE}db $C5,$FD,$10,$4C,$38,$E0;{$ENDIF} 
            {$IFDEF AVXSUP}vmovupd ymm2, [ecx + edi - 32];            {$ELSE}db $C5,$FD,$10,$54,$39,$E0;{$ENDIF} 
            {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm2;                   {$ELSE}db $C5,$F5,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                   {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 

         jmp @@foriloopAVX;

         @@foriloopAVXend:

         {$IFDEF AVXSUP}vextractf128 xmm2, ymm0, 1;                   {$ELSE}db $C4,$E3,$7D,$19,$C2,$01;{$ENDIF} 
         {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm2;                     {$ELSE}db $C5,$F9,$7C,$C2;{$ENDIF} 

         sub edi, 32;
         jz @@foriloopend;

         // for i := x to width1 - 1
         @@foriloop:
            // two elements at a time:
            {$IFDEF AVXSUP}vmovupd xmm1, [eax + edi];                 {$ELSE}db $C5,$F9,$10,$0C,$38;{$ENDIF} 
            {$IFDEF AVXSUP}vmovupd xmm2, [ecx + edi];                 {$ELSE}db $C5,$F9,$10,$14,$39;{$ENDIF} 
            {$IFDEF AVXSUP}vmulpd xmm1, xmm1, xmm2;                   {$ELSE}db $C5,$F1,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm1;                   {$ELSE}db $C5,$F9,$58,$C1;{$ENDIF} 

            add edi, 16;
         jnz @@foriloop;

         @@foriloopend:

         // final result
         {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                     {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd [eax + esi], xmm0;                     {$ELSE}db $C5,$FB,$11,$04,$30;{$ENDIF} 

         add ecx, LineWidth2;
         add esi, 8;

      cmp esi, testExitLoopVal;
      jne @@forxloop;

      // restore mt2
      pop ecx;

      add eax, edx;
   dec height1;
   jnz @@foryloop;

   // epilog
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 

   pop esi;
   pop edi;
   pop ebx;
end;

procedure AVXMtxMultTria2TUpperUnit(dest : PDouble; LineWidthDest : NativeInt; mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  width1, height1, width2, height2 : NativeInt);
var iter, testExitLoopVal : NativeInt;
asm
   // prolog: stack
   push ebx;
   push edi;
   push esi;

   // init

   //iter := -width1*sizeof(double);
   mov ebx, width1;
   imul ebx, -8;
   mov iter, ebx;

   sub mt2, ebx;

   // ecx := mt1
   sub eax, ebx;
   sub ecx, ebx;  // mt1 - iter

   // testExitLoopVal := height2*sizeof(double) + iter;
   mov edi, height2;
   shl edi, 3; //*8
   add edi, ebx;
   mov testExitLoopVal, edi;

   // for y loop
   @@foryloop:
      mov ebx, mt2;
      //sub ebx, iter;
      mov esi, iter;

      @@forxloop:
         {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                      {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} // temp := 0

         mov edi, esi;  // loop counter x;

         // test if height2 > width1 and loop counter > width1
         test edi, edi;
         jge @@foriloopend;

         // in case x is odd -> handle the first element separately
         //and esi, $E;
         test edi, $E;
         jz @@foriloopinit;

         // single element handling -> mt1 first element is assumed unit!
         {$IFDEF AVXSUP}vmovsd xmm0, [ecx + edi];                     {$ELSE}db $C5,$FB,$10,$04,$39;{$ENDIF} 
         add edi, 8;

         jmp @@AfterLoopInit;

         @@foriloopinit:

         test edi, edi;
         jz @@foriloopend;

         // two elements init at a time:
         {$IFDEF AVXSUP}vmovsd xmm0, [ecx + edi];                     {$ELSE}db $C5,$FB,$10,$04,$39;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd xmm1, [ecx + edi + 8];                 {$ELSE}db $C5,$FB,$10,$4C,$39,$08;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd xmm2, [ebx + edi + 8];                 {$ELSE}db $C5,$FB,$10,$54,$3B,$08;{$ENDIF} 
         {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                      {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
         {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                      {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 

         add edi, 16;

         @@AfterLoopInit:

         // in case the last single x element was handled we do not need further looping
         test edi, edi;
         jz @@finalizeloop;

         // for i := x to width1 - 1
         @@foriloop:
             add edi, 32;

             jg @@foriloopend;

             // 4 elements at a time:
             {$IFDEF AVXSUP}vmovupd ymm1, [ecx + edi - 32];           {$ELSE}db $C5,$FD,$10,$4C,$39,$E0;{$ENDIF} 
             {$IFDEF AVXSUP}vmovupd ymm2, [ebx + edi - 32];           {$ELSE}db $C5,$FD,$10,$54,$3B,$E0;{$ENDIF} 
             {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm2;                  {$ELSE}db $C5,$F5,$59,$CA;{$ENDIF} 
             {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                  {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
         jmp @@foriloop;

         @@foriloopend:
         {$IFDEF AVXSUP}vextractf128 xmm1, ymm0, 1;                   {$ELSE}db $C4,$E3,$7D,$19,$C1,$01;{$ENDIF} 
         {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm1;                     {$ELSE}db $C5,$F9,$7C,$C1;{$ENDIF} 
         sub edi, 32;

         // test if we missed 2 elements
         jz @@finalizeloop;

         // need to process two more elements:
         {$IFDEF AVXSUP}vmovupd xmm1, [ecx + edi];                    {$ELSE}db $C5,$F9,$10,$0C,$39;{$ENDIF} 
         {$IFDEF AVXSUP}vmovupd xmm2, [ebx + edi];                    {$ELSE}db $C5,$F9,$10,$14,$3B;{$ENDIF} 
         {$IFDEF AVXSUP}vmulpd xmm1, xmm1, xmm2;                      {$ELSE}db $C5,$F1,$59,$CA;{$ENDIF} 
         {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm1;                      {$ELSE}db $C5,$F9,$58,$C1;{$ENDIF} 

         @@finalizeloop:

         // final result
         {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                     {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd [eax + esi], xmm0;                     {$ELSE}db $C5,$FB,$11,$04,$30;{$ENDIF} 

         add ebx, LineWidth2;
         add esi, 8;

      cmp esi, testExitLoopVal;
      jne @@forxloop;

      add ecx, LineWidth1;
      add eax, edx;
   dec height1;
   jnz @@foryloop;

   // epilog
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 

   pop esi;
   pop edi;
   pop ebx;
end;

// note the result is stored in mt2 again!
// dest = mt1'*mt2; where mt2 is a lower triangular matrix and the operation is transposition
// the function assumes a unit diagonal (does not touch the real middle elements)
// width and height values are assumed to be the "original" (non transposed) ones
procedure AVXMtxMultTria2T1(dest : PDouble; LineWidthDest : NativeInt; mt1 : PDouble; LineWidth1 : NativeInt;
  mt2 : PDouble; LineWidth2 : NativeInt;
  width1, height1, width2, height2 : NativeInt);
var pMt2 : PDouble;
    width2D2 : NativeInt;
    aLineWidthDest : NativeInt;
asm
   // Prolog
   push ebx;
   push esi;
   push edi;

   mov aLineWidthDest, edx;
   // width2D2 := width2 div 2;
   mov ebx, width2;
   shr ebx, 1;
   mov width2D2, ebx;

   // for x := 0 to width1 - 1 do
   @@forxloop:

      // pMT2 := mt2;
      // pDest := dest;
      push eax;        // eax is pDest

      mov ebx, mt2;
      mov pMT2, ebx;

      // for y := 0 to width2D2 - 1 do
      mov edx, width2D2;
      test edx, edx;
      jz @@foryloopend;

      xor edx, edx;
      @@foryloop:
           // valCounter1 := PConstDoubleArr(mt1);
           // inc(PByte(valCounter1), 2*y*LineWidth1);
           mov esi, mt1;
           mov ebx, edx;
           add ebx, ebx;
           imul ebx, LineWidth1;
           add esi, ebx;

           // valCounter2 := PConstDoubleArr(pMT2);
           // inc(PByte(valCounter2), (2*y + 1)*LineWidth2);
           mov edi, pMt2;
           mov ebx, edx;
           add ebx, ebx;
           imul ebx, LineWidth2;
           add ebx, LineWidth2;
           add edi, ebx;

           // tmp[0] := valCounter1^[0];
           // inc(PByte(valCounter1), LineWidth1);
           {$IFDEF AVXSUP}vmovsd xmm0, [esi];                         {$ELSE}db $C5,$FB,$10,$06;{$ENDIF} 
           add esi, LineWidth1;

           // if height2 - 2*y - 1 > 0 then
           mov ebx, edx;
           add ebx, ebx;
           inc ebx;

           cmp ebx, height2;
           jnl @@PreInnerLoop;
               // tmp[0] := tmp[0] + valCounter1^[0]*valCounter2^[0];
               // tmp[1] := valCounter1^[0];
               {$IFDEF AVXSUP}vmovsd xmm1, [esi];                     {$ELSE}db $C5,$FB,$10,$0E;{$ENDIF} 
               {$IFDEF AVXSUP}vmovlhps xmm0, xmm0, xmm1;              {$ELSE}db $C5,$F8,$16,$C1;{$ENDIF} 

               {$IFDEF AVXSUP}vmulsd xmm1, xmm1, [edi];               {$ELSE}db $C5,$F3,$59,$0F;{$ENDIF} 
               {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 

               //inc(PByte(valCounter1), LineWidth1);
               //inc(PByte(valCounter2), LineWidth2);

               add esi, LineWidth1;
               add edi, LineWidth2;

           @@PreInnerLoop:

           // rest is a double column!

           // prepare loop
           mov ebx, height2;
           sub ebx, edx;
           sub ebx, edx;
           sub ebx, 2;

           test ebx, ebx;
           jle @@InnerLoopEnd;

           @@InnerLoop:
               // tmp[0] := tmp[0] + valCounter1^[0]*valCounter2^[0];
               // tmp[1] := tmp[1] + valCounter1^[0]*valCounter2^[1];
               {$IFDEF AVXSUP}vmovddup xmm1, [esi];                   {$ELSE}db $C5,$FB,$12,$0E;{$ENDIF} 
               {$IFDEF AVXSUP}vmovupd xmm2, [edi];                    {$ELSE}db $C5,$F9,$10,$17;{$ENDIF} 

               {$IFDEF AVXSUP}vmulpd xmm2, xmm2, xmm1;                {$ELSE}db $C5,$E9,$59,$D1;{$ENDIF} 
               {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm2;                {$ELSE}db $C5,$F9,$58,$C2;{$ENDIF} 

               //inc(PByte(valCounter1), LineWidth1);
               //inc(PByte(valCounter2), LineWidth2);

               add esi, LineWidth1;
               add edi, LineWidth2;

           dec ebx;
           jnz @@InnerLoop;

           @@InnerLoopEnd:


           // write back result

           // pDest^ := tmp[0];
           // PDouble(NativeUint(pDest) + sizeof(double))^ := tmp[1];

           {$IFDEF AVXSUP}vmovupd [eax], xmm0;                        {$ELSE}db $C5,$F9,$11,$00;{$ENDIF} 

           // inc(pDest, 2);
           // inc(pMT2, 2);
           add pMT2, 16;
           add eax, 16;

      // end foryloop
      inc edx;
      cmp edx, width2D2;
      jne @@foryloop;

      @@foryloopend:


      //if (width2 and $01) = 1 then
      mov edx, width2;
      and edx, 1;

      jz @@ifend1;

      // special handling of last column (just copy the value)

      // valCounter1 := PConstDoubleArr(mt1);
      mov edx, ecx;

      //inc(PByte(valCounter1), LineWidth1*(height1 - 1));
      mov ebx, height1;
      dec ebx;
      imul ebx, LineWidth1;

      // pDest^ := valCounter1^[0];
      {$IFDEF AVXSUP}vmovsd xmm0, [edx + ebx];                        {$ELSE}db $C5,$FB,$10,$04,$1A;{$ENDIF} 
      {$IFDEF AVXSUP}vmovsd [eax], xmm0;                              {$ELSE}db $C5,$FB,$11,$00;{$ENDIF} 
      @@ifend1:

      //inc(mt1);
      //inc(PByte(dest), LineWidthDest);
      pop eax;

      add ecx, 8;
      add eax, aLineWidthDest;

   // end for loop
   dec Width1;
   jnz @@forxloop;

   // epilog
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 

   pop edi;
   pop esi;
   pop ebx;
end;

// calculates mt1 = mt1*mt2', mt2 = lower triangular matrix. diagonal elements are assumed to be 1!
procedure AVXMtxMultLowTria2T2Store1(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  width1, height1, width2, height2 : NativeInt);
var aLineWidth1 : NativeInt;
    aMt1 : PDouble;
// eax = mt1, edx = LineWidth1, ecx = mt2
asm
   push ebx;
   push edi;
   push esi;

   // init
   mov aMt1, eax;
   mov aLineWidth1, edx;

   // iter := -(width2 - 1)*sizeof(double);
   mov edx, width2;
   dec edx;
   imul edx, -8;

   // start from bottom
   // ebx: mt2
   // inc(PByte(mt2),(height2 - 1)*LineWidth2);
   mov esi, height2;
   dec esi;
   imul esi, LineWidth2;
   add ecx, esi;
   sub ecx, edx;

   // for x := 0 to width2 - 2
   dec width2;
   jz @@endproc;
   @@forxloop:
      mov eax, aMt1;
      sub eax, edx;

      // for y := 0 to height1 - 1
      mov esi, height1;
      @@foryloop:
         {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                      {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
         // for idx := 0 to width2 - x - 2
         mov edi, edx;
         test edi, edi;
         jz @@foridxloopend;

         // unrolled loop 4x2
         add edi, 64;
         jg @@foridxloopSSE;
         @@foridxlongloop:
            {$IFDEF AVXSUP}vmovupd ymm1, [eax + edi - 64];            {$ELSE}db $C5,$FD,$10,$4C,$38,$C0;{$ENDIF} 
            {$IFDEF AVXSUP}vmovupd ymm2, [ecx + edi - 64];            {$ELSE}db $C5,$FD,$10,$54,$39,$C0;{$ENDIF} 
            {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm2;                   {$ELSE}db $C5,$F5,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                   {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 

            {$IFDEF AVXSUP}vmovupd ymm1, [eax + edi - 32];            {$ELSE}db $C5,$FD,$10,$4C,$38,$E0;{$ENDIF} 
            {$IFDEF AVXSUP}vmovupd ymm2, [ecx + edi - 32];            {$ELSE}db $C5,$FD,$10,$54,$39,$E0;{$ENDIF} 
            {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm2;                   {$ELSE}db $C5,$F5,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                   {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
         add edi, 64;
         jl @@foridxlongloop;

         {$IFDEF AVXSUP}vextractf128 xmm1, ymm0, 1;                   {$ELSE}db $C4,$E3,$7D,$19,$C1,$01;{$ENDIF} 
         {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm1;                     {$ELSE}db $C5,$F9,$7C,$C1;{$ENDIF} 

         // sse part
         @@foridxloopSSE:
         sub edi, 48;
         jg @@foridxloopstart;

         @@foridxSSEloop:
            {$IFDEF AVXSUP}vmovupd xmm1, [eax + edi - 16];            {$ELSE}db $C5,$F9,$10,$4C,$38,$F0;{$ENDIF} 
            {$IFDEF AVXSUP}vmovupd xmm2, [ecx + edi - 16];            {$ELSE}db $C5,$F9,$10,$54,$39,$F0;{$ENDIF} 
            {$IFDEF AVXSUP}vmulpd xmm1, xmm1, xmm2;                   {$ELSE}db $C5,$F1,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm1;                   {$ELSE}db $C5,$F9,$58,$C1;{$ENDIF} 
         add edi, 16;
         jl @@foridxSSEloop;

         @@foridxloopStart:
         {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                     {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 
         sub edi, 16;
         jz @@foridxloopend;

         @@foridxloop:
            {$IFDEF AVXSUP}vmovsd xmm1, [eax + edi];                  {$ELSE}db $C5,$FB,$10,$0C,$38;{$ENDIF} 
            {$IFDEF AVXSUP}vmovsd xmm2, [ecx + edi];                  {$ELSE}db $C5,$FB,$10,$14,$39;{$ENDIF} 
            {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                   {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                   {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
         add edi, 8;
         jnz @@foridxloop;

         @@foridxloopend:

         // last element is unit:
         {$IFDEF AVXSUP}vmovsd xmm1, [eax];                           {$ELSE}db $C5,$FB,$10,$08;{$ENDIF} 
         {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                      {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 

         // write back
         // PConstDoubleArr(pMt1)^[width2 - x - 1] := tmp + valCounter1^[width2 - x - 1];
         {$IFDEF AVXSUP}vmovsd [eax], xmm0;                           {$ELSE}db $C5,$FB,$11,$00;{$ENDIF} 
         add eax, aLineWidth1;
      dec esi;
      jnz @@foryloop;

      // dec(PByte(mt2), LineWidth2);
      sub ecx, LineWidth2;
      sub ecx, 8;

      // adjust iterator to the next x value for the idxloop
      add edx, 8;
   dec width2;
   jnz @@forxloop;

   @@endproc:

   // epilog: stack fixing
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
   pop esi;
   pop edi;
   pop ebx;
end;

procedure AVXMtxMultTria2Store1Unit(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  width1, height1, width2, height2 : NativeInt);
var iter : NativeInt;
    aMT1 : PDouble;
asm
   push ebx;
   push edi;
   push esi;

   mov aMT1, eax;

   // init
   // iter := -(width1-1)*sizeof(double);
   mov ebx, width1;
   dec ebx;
   imul ebx, -8;
   mov iter, ebx;

   // inc(mt2, width2 - 1);
   mov ebx, width2;
   dec ebx;
   imul ebx, 8; //sizeof(double)
   add ecx, ebx;

   mov ebx, width2;
   dec ebx;
   mov width2, ebx;

   mov ebx, LineWidth2;

   // for x := 0 to width2 - 2 do
   @@forxloop:
      mov edi, height1;

      mov eax, aMT1;
      sub eax, iter;

      // for y := 0 to height1 - 1
      @@foryloop:
         // tmp := 0;
         {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                      {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 

         // ecx, mt2
         push ecx;

         // for idx := 0 to width1 - x - 2
         mov esi, iter;

         // check if we have enough iterations:
         cmp esi, 0;
         jge @@foridxloopend;

         @@foridxloop:
            {$IFDEF AVXSUP}vmovsd xmm1, [ecx];                        {$ELSE}db $C5,$FB,$10,$09;{$ENDIF} 
            {$IFDEF AVXSUP}vmovsd xmm2, [eax + esi];                  {$ELSE}db $C5,$FB,$10,$14,$30;{$ENDIF} 

            add ecx, ebx;  // + linewidth2

            {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                   {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                   {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 

         add esi, 8;
         jnz @@foridxloop;

         @@foridxloopend:

         // last element is unit
         {$IFDEF AVXSUP}vaddsd xmm0, xmm0, [eax];                     {$ELSE}db $C5,$FB,$58,$00;{$ENDIF} 

         // PConstDoubleArr(pmt1)^[width2 - 1 - x] := tmp;
         mov ecx, eax;
         add ecx, iter;
         mov esi, width2;
         //dec esi;
         {$IFDEF AVXSUP}vmovsd [ecx + 8*esi], xmm0;                   {$ELSE}db $C5,$FB,$11,$04,$F1;{$ENDIF} 

         pop ecx;

         // inc(PByte(pmT1), LineWidth1);
         add eax, edx;

      dec edi;
      jnz @@foryloop;

      // reduce for idx loop
      add iter, 8;
      // dec(mt2);
      sub ecx, 8;

   dec width2;
   jnz @@forxloop;

   @@endproc:

   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 

   // cleanup stack
   pop esi;
   pop edi;
   pop ebx;
end;

procedure AVXSymRank2UpdateUpperUnaligned( C : PDouble; LineWidthC : NativeInt; A : PDouble; LineWidthA : NativeInt;
  B : PDouble; LineWidthB : NativeInt; N : NativeInt; k : NativeInt );
// eax = c; edx = LineWidthC; ecx : A;
var i, j : integer;
    lC : Cardinal;
asm
   // save register
   push ebx;
   push edi;
   push esi;

   // switch register
   mov lC, edx;

   // eax -> pointer to C
   // ecx -> ponter to pA1
   // esi -> pointer to pB1
   mov esi, B;

   mov edi, k;
   imul edi, -8;
   mov k, edi;

   sub ecx, edi;
   sub esi, edi;

   mov edi, N;
   shl edi, 3;
   add eax, edi;


   // for j := 0 to N - 1 do
   //
   neg edi;
   mov j, edi;
   @@forNLoop:
       mov edx, j;
       mov i, edx;

       // ###########################################
       // #### Init A2 and B2
       // pA2
       mov ebx, ecx;
       // pB2
       mov edi, esi;


       @@forjNLoop:
            {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                   {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 

            // ###########################################
            // #### Init loop
            mov edx, k;

            // ymm path
            @@forlLoop2:
               add edx, 32;
               jg @@forlLoop2End;

               {$IFDEF AVXSUP}vmovupd ymm1, [ecx + edx - 32];         {$ELSE}db $C5,$FD,$10,$4C,$11,$E0;{$ENDIF} // pA1;
               {$IFDEF AVXSUP}vmovupd ymm2, [edi + edx - 32];         {$ELSE}db $C5,$FD,$10,$54,$17,$E0;{$ENDIF} // pB2
               {$IFDEF AVXSUP}vmovupd ymm3, [esi + edx - 32];         {$ELSE}db $C5,$FD,$10,$5C,$16,$E0;{$ENDIF} // pB1;
               {$IFDEF AVXSUP}vmovupd ymm4, [ebx + edx - 32];         {$ELSE}db $C5,$FD,$10,$64,$13,$E0;{$ENDIF} // pA2;

               {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm2;                {$ELSE}db $C5,$F5,$59,$CA;{$ENDIF} 
               {$IFDEF AVXSUP}vaddpd ymm0, ymm1, ymm0;                {$ELSE}db $C5,$F5,$58,$C0;{$ENDIF} 
               {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm4;                {$ELSE}db $C5,$E5,$59,$DC;{$ENDIF} 
               {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm3;                {$ELSE}db $C5,$FD,$58,$C3;{$ENDIF} 

            jmp @@forlLoop2;

            @@forlLoop2End:

            {$IFDEF AVXSUP}vextractf128 xmm1, ymm0, 1;                {$ELSE}db $C4,$E3,$7D,$19,$C1,$01;{$ENDIF} 
            {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm1;                   {$ELSE}db $C5,$F9,$58,$C1;{$ENDIF} 

            sub edx, 32;
            cmp edx, 32;
            je @@NextN;

            // accumulate
            @@forlLoop:
                add edx, 16;
                jg @@forlLoopEnd;

                {$IFDEF AVXSUP}vmovupd xmm1, [ecx + edx - 16];        {$ELSE}db $C5,$F9,$10,$4C,$11,$F0;{$ENDIF} // pA1;
                {$IFDEF AVXSUP}vmovupd xmm2, [edi + edx - 16];        {$ELSE}db $C5,$F9,$10,$54,$17,$F0;{$ENDIF} // pB2
                {$IFDEF AVXSUP}vmovupd xmm3, [esi + edx - 16];        {$ELSE}db $C5,$F9,$10,$5C,$16,$F0;{$ENDIF} // pB1;
                {$IFDEF AVXSUP}vmovupd xmm4, [ebx + edx - 16];        {$ELSE}db $C5,$F9,$10,$64,$13,$F0;{$ENDIF} // pA2;

                {$IFDEF AVXSUP}vmulpd xmm1, xmm1, xmm2;               {$ELSE}db $C5,$F1,$59,$CA;{$ENDIF} 
                {$IFDEF AVXSUP}vaddpd xmm0, xmm1, xmm0;               {$ELSE}db $C5,$F1,$58,$C0;{$ENDIF} 
                {$IFDEF AVXSUP}vmulpd xmm3, xmm3, xmm4;               {$ELSE}db $C5,$E1,$59,$DC;{$ENDIF} 
                {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm3;               {$ELSE}db $C5,$F9,$58,$C3;{$ENDIF} 
            jmp @@forlLoop;

            @@forlLoopEnd:

            // is iterator actualy zero? (aka even k)
            cmp edx, 16;
            je @@NextN;

            // last element
            {$IFDEF AVXSUP}vmovsd xmm1, [ecx - 8];                    {$ELSE}db $C5,$FB,$10,$49,$F8;{$ENDIF} // pA1;
            {$IFDEF AVXSUP}vmovsd xmm2, [edi - 8];                    {$ELSE}db $C5,$FB,$10,$57,$F8;{$ENDIF} // pB2
            {$IFDEF AVXSUP}vmovsd xmm3, [esi - 8];                    {$ELSE}db $C5,$FB,$10,$5E,$F8;{$ENDIF} // pB1;
            {$IFDEF AVXSUP}vmovsd xmm4, [ebx - 8];                    {$ELSE}db $C5,$FB,$10,$63,$F8;{$ENDIF} // pA2;

            {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                   {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                   {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
            {$IFDEF AVXSUP}vmulsd xmm3, xmm3, xmm4;                   {$ELSE}db $C5,$E3,$59,$DC;{$ENDIF} 
            {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm3;                   {$ELSE}db $C5,$FB,$58,$C3;{$ENDIF} 

            @@NextN:

            // ###########################################
            // #### pC^[i] := pC^[i] - xmm0
            mov edx, i;
            {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                  {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 
            {$IFDEF AVXSUP}vmovsd xmm1, [eax + edx];                  {$ELSE}db $C5,$FB,$10,$0C,$10;{$ENDIF} 

            {$IFDEF AVXSUP}vsubsd xmm1, xmm1, xmm0;                   {$ELSE}db $C5,$F3,$5C,$C8;{$ENDIF} 
            {$IFDEF AVXSUP}vmovsd [eax + edx], xmm1;                  {$ELSE}db $C5,$FB,$11,$0C,$10;{$ENDIF} 

            add ebx, LineWidthA;  // increment pA2
            add edi, LineWidthB;  // increment pB2

       add i, 8;
       jnz @@forjNLoop;

       // next line
       add eax, lC;
       add ecx, LineWidthA;
       add esi, LineWidthB;
   add j, 8;
   jnz @@forNLoop;

   // ###########################################
   // #### Finalize stack
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 

   pop esi;
   pop edi;
   pop ebx;
end;

{$ENDIF}

end.
