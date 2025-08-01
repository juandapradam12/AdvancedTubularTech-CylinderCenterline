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


unit AVXMatrixMultOperationsx64;

interface

{$I 'mrMath_CPU.inc'}

{$IFDEF x64}

uses MatrixConst;

// full matrix operations
procedure AVXMatrixMultAligned(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
procedure AVXMatrixMultUnAligned(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

// some special types of multiplications used e.g. in QR Decomposition
// dest = mt1'*mt2; where mt2 is a lower triangular matrix and the operation is transposition
// the function assumes a unit diagonal (does not touch the real middle elements)
// width and height values are assumed to be the "original" (non transposed) ones
procedure AVXMtxMultTria2T1(dest : PDouble; LineWidthDest : NativeInt; mt1 : PDouble; LineWidth1 : NativeInt;
         {$ifdef UNIX}unixMT2{$ELSE}mt2{$endif} : PDouble; {$ifdef UNIX}unixLineWidth2{$ELSE}LineWidth2{$endif} : NativeInt;
         width1, height1, width2, height2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
// mt1 = mt1*mt2'; where mt2 is an upper triangular matrix
procedure AVXMtxMultTria2T1StoreT1(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

// W = C1*V1*T -> V1 is an upper triangular matrix with assumed unit diagonal entries. Operation on V1 transposition
procedure AVXMtxMultTria2TUpperUnit(dest : PDouble; LineWidthDest : NativeInt; mt1 : PDouble; LineWidth1 : NativeInt;
          {$ifdef UNIX}unixMT2{$ELSE}mt2{$endif} : PDouble; {$ifdef UNIX}unixLineWidth2{$ELSE}LineWidth2{$endif} : NativeInt;
          width1, height1, width2, height2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

// mt1 = mt1*mt2; where mt2 is an upper triangular matrix
procedure AVXMtxMultTria2Store1(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

// calculates mt1 = mt1*mt2', mt2 = lower triangular matrix. diagonal elements are assumed to be 1!
procedure AVXMtxMultLowTria2T2Store1(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}

// mt1 = mt1*mt2; where mt2 is an upper triangular matrix - diagonal elements are unit
procedure AVXMtxMultTria2Store1Unit(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}


// performs a rank2 update in the form
// C = C - A*B' - B*A'
// N...order of C (N x N matrix)
// k... number of columns of A and B
// the lower triangle of C is not referenced
procedure AVXSymRank2UpdateUpperUnaligned( C : PDouble; LineWidthC : NativeInt; A : PDouble; LineWidthA : NativeInt;
  {$IFDEF UNIX}unixB {$ELSE} B {$ENDIF}: PDouble;
  {$IFDEF UNIX}unixLineWidthB {$ELSE} LineWidthB {$ENDIF} : NativeInt; N : NativeInt; k : NativeInt ); {$IFDEF FPC}assembler;{$ENDIF}


{$ENDIF}

implementation

{$IFDEF x64}

procedure AVXMatrixMultAligned(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
   // prolog - simulate stack
   mov iRBX, rbx;
   mov iRSI, rsi;
   mov iRDI, rdi;
   mov iR12, r12;
   mov iR13, r13;
   mov iR14, r14;
   mov iR15, r15;

   sub rsp, $30;
   {$IFDEF AVXSUP}vmovupd [rsp + $00], xmm4;                          {$ELSE}db $C5,$F9,$11,$24,$24;{$ENDIF} 
   {$IFDEF AVXSUP}vmovupd [rsp + $10], xmm5;                          {$ELSE}db $C5,$F9,$11,$6C,$24,$10;{$ENDIF} 
   {$IFDEF AVXSUP}vmovupd [rsp + $20], xmm6;                          {$ELSE}db $C5,$F9,$11,$74,$24,$20;{$ENDIF} 

   mov rdi, LineWidth1;

   mov r10, width1;
   imul r10, -8;
   sub r8, r10;

   mov r11, LineWidth2;
   mov r12, width2;

   //destOffset := destLineWidth - Width2*sizeof(double);
   mov rbx, Width2;
   shl rbx, 3;
   mov r15, rdx;
   sub r15, rbx;

   //bytesWidth2 := width2*sizeof(double);
   mov r14, rbx;

   mov rsi, height1;
   // for y := 0 to height1 - 1 do
   @@foryloop:

      // r12 -> counter to width2
      mov r13, r12;
      sub r13, 2;
      jl @LastXColumn;

      @@forxloop:
      // for x := 0 to width2 div 2 - 1
          // r8: mt1 - width1*sizeof(double)
          // r9: mt2
          mov rbx, r9;
          mov rax, r10;

          {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                     {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
          {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                     {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

          cmp rax, -32;
          jg @@Innerloop2Begin;

          // for z := 0 to width1 - 1do
          // AVX part:
          @@InnerLoop1:
             // 4x4 block
             {$IFDEF AVXSUP}vmovapd xmm2, [rbx];                      {$ELSE}db $C5,$F9,$28,$13;{$ENDIF} 
             add rbx, r11;
             {$IFDEF AVXSUP}vmovapd xmm4, xmm2;                       {$ELSE}db $C5,$F9,$29,$D4;{$ENDIF} 

             {$IFDEF AVXSUP}vmovapd xmm3, [rbx];                      {$ELSE}db $C5,$F9,$28,$1B;{$ENDIF} 
             add rbx, r11;

             // shuffle so we can multiply

             // swap such that we can immediately multiply
             {$IFDEF AVXSUP}vmovlhps xmm2, xmm2, xmm3;                {$ELSE}db $C5,$E8,$16,$D3;{$ENDIF} 
             {$IFDEF AVXSUP}vmovhlps xmm3, xmm3, xmm4;                {$ELSE}db $C5,$E0,$12,$DC;{$ENDIF} 

             // next 4 elements
             {$IFDEF AVXSUP}vmovapd xmm4, [rbx];                      {$ELSE}db $C5,$F9,$28,$23;{$ENDIF} 
             add rbx, r11;
             {$IFDEF AVXSUP}vmovapd xmm6, xmm4;                       {$ELSE}db $C5,$F9,$29,$E6;{$ENDIF} 

             {$IFDEF AVXSUP}vmovapd xmm5, [rbx];                      {$ELSE}db $C5,$F9,$28,$2B;{$ENDIF} 
             add rbx, r11;

             {$IFDEF AVXSUP}vmovapd ymm7, [r8 + rax]                  {$ELSE}db $C4,$C1,$7D,$28,$3C,$00;{$ENDIF} 

             {$IFDEF AVXSUP}vmovlhps xmm4, xmm4, xmm5;                {$ELSE}db $C5,$D8,$16,$E5;{$ENDIF} 
             {$IFDEF AVXSUP}vmovhlps xmm5, xmm5, xmm6;                {$ELSE}db $C5,$D0,$12,$EE;{$ENDIF} 

             {$IFDEF AVXSUP}vinsertf128 ymm2, ymm2, xmm4, 1;          {$ELSE}db $C4,$E3,$6D,$18,$D4,$01;{$ENDIF} 
             {$IFDEF AVXSUP}vinsertf128 ymm3, ymm3, xmm5, 1;          {$ELSE}db $C4,$E3,$65,$18,$DD,$01;{$ENDIF} 

             // now multiply and add
             {$IFDEF AVXSUP}vmulpd ymm2, ymm2, ymm7;                  {$ELSE}db $C5,$ED,$59,$D7;{$ENDIF} 
             {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm7;                  {$ELSE}db $C5,$E5,$59,$DF;{$ENDIF} 

             {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm2;                  {$ELSE}db $C5,$FD,$58,$C2;{$ENDIF} 
             {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm3;                  {$ELSE}db $C5,$F5,$58,$CB;{$ENDIF} 
          add rax, 32;
          jl @@InnerLoop1;

          {$IFDEF AVXSUP}vextractf128 xmm2, ymm0, 1;                  {$ELSE}db $C4,$E3,$7D,$19,$C2,$01;{$ENDIF} 
          {$IFDEF AVXSUP}vextractf128 xmm3, ymm1, 1;                  {$ELSE}db $C4,$E3,$7D,$19,$CB,$01;{$ENDIF} 

          {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm2;                    {$ELSE}db $C5,$F9,$7C,$C2;{$ENDIF} 
          {$IFDEF AVXSUP}vhaddpd xmm1, xmm1, xmm3;                    {$ELSE}db $C5,$F1,$7C,$CB;{$ENDIF} 

          test rax, rax;
          jz @@InnerLoopEnd2;

          @@Innerloop2Begin:

          // rest in single elements
          @@InnerLoop2:
             {$IFDEF AVXSUP}vmovapd xmm2, [rbx];                      {$ELSE}db $C5,$F9,$28,$13;{$ENDIF} 
             add rbx, r11;

             {$IFDEF AVXSUP}vmovddup xmm3, [r8 + rax];                {$ELSE}db $C4,$C1,$7B,$12,$1C,$00;{$ENDIF} 

             {$IFDEF AVXSUP}vmulpd xmm2, xmm2, xmm3;                  {$ELSE}db $C5,$E9,$59,$D3;{$ENDIF} 
             {$IFDEF AVXSUP}vmovhlps xmm4, xmm4, xmm2;                {$ELSE}db $C5,$D8,$12,$E2;{$ENDIF} 

             {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm2;                  {$ELSE}db $C5,$FB,$58,$C2;{$ENDIF} 
             {$IFDEF AVXSUP}vaddsd xmm1, xmm1, xmm4;                  {$ELSE}db $C5,$F3,$58,$CC;{$ENDIF} 
          add rax, 8;
          jnz @@InnerLoop2;

          @@InnerLoopEnd2:

          // finall horizontal addition
          {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm1;                    {$ELSE}db $C5,$F9,$7C,$C1;{$ENDIF} 

          {$IFDEF AVXSUP}vmovapd [rcx], xmm0;                         {$ELSE}db $C5,$F9,$29,$01;{$ENDIF} 

          // increment the pointers
          // inc(mt2), inc(dest);
          //add dword ptr [mt2], 8;
          add r9, 16;
          add rcx, 16;

      // end for x := 0 to width2 div 2 - 1
      sub r13, 2;
      jge @@forxloop;

      @LastXColumn:

      cmp r13, -1;
      jne @NextLine;

      // last column of mt2
      mov rax, r10;
      mov rbx, r9;

      {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                         {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 

      @InnerLoop2:
         {$IFDEF AVXSUP}vmovsd xmm1, [r8 + rax];                      {$ELSE}db $C4,$C1,$7B,$10,$0C,$00;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd xmm2, [rbx];                           {$ELSE}db $C5,$FB,$10,$13;{$ENDIF} 

         {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                      {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
         {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                      {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 

         add rbx, r11;
      add rax, 8;
      jnz @InnerLoop2;

      {$IFDEF AVXSUP}vmovsd [rcx], xmm0;                              {$ELSE}db $C5,$FB,$11,$01;{$ENDIF} 
      add rcx, 8;
      add r9, 8;

      @NextLine:
      // dec(mt2, Width2);
      // inc(PByte(mt1), LineWidth1);
      // inc(PByte(dest), destOffset);
      //mov ebx, bytesWidth2;
      //sub dword ptr [mt2], ebx;
      sub r9, r14;
      add r8, rdi;
      add rcx, r15;

   // end for y := 0 to height1 - 1
   //dec eax;
   dec rsi;
   jnz @@foryloop;

   // epilog
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;

   {$IFDEF AVXSUP}vmovupd xmm4, [rsp + $00];                          {$ELSE}db $C5,$F9,$10,$24,$24;{$ENDIF} 
   {$IFDEF AVXSUP}vmovupd xmm5, [rsp + $10];                          {$ELSE}db $C5,$F9,$10,$6C,$24,$10;{$ENDIF} 
   {$IFDEF AVXSUP}vmovupd xmm6, [rsp + $20];                          {$ELSE}db $C5,$F9,$10,$74,$24,$20;{$ENDIF} 
   add rsp, $30;

   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

procedure AVXMatrixMultUnAligned(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}

asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

    // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
    // prolog - simulate stack
    mov iRBX, rbx;
    mov iRSI, rsi;
    mov iRDI, rdi;
    mov iR12, r12;
    mov iR13, r13;
    mov iR14, r14;
    mov iR15, r15;

    sub rsp, $30;
    {$IFDEF AVXSUP}vmovupd [rsp + $00], xmm4;                         {$ELSE}db $C5,$F9,$11,$24,$24;{$ENDIF} 
    {$IFDEF AVXSUP}vmovupd [rsp + $10], xmm5;                         {$ELSE}db $C5,$F9,$11,$6C,$24,$10;{$ENDIF} 
    {$IFDEF AVXSUP}vmovupd [rsp + $20], xmm6;                         {$ELSE}db $C5,$F9,$11,$74,$24,$20;{$ENDIF} 

    mov rdi, LineWidth1;

    mov r10, width1;
    imul r10, -8;
    sub r8, r10;

    mov r11, LineWidth2;
    mov r12, width2;

    //destOffset := destLineWidth - Width2*sizeof(double);
    mov rbx, Width2;
    shl rbx, 3;
    mov r15, rdx;
    sub r15, rbx;

    //bytesWidth2 := width2*sizeof(double);
    mov r14, rbx;

    mov rsi, height1;
    // for y := 0 to height1 - 1 do
    @@foryloop:

       // r12 -> counter to width2
       mov r13, r12;
       sub r13, 2;
       jl @LastXColumn;

       @@forxloop:
       // for x := 0 to width2 div 2 - 1
           // r8: mt1 - width1*sizeof(double)
           // r9: mt2
           mov rbx, r9;
           mov rax, r10;

           {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                    {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
           {$IFDEF AVXSUP}vxorpd ymm1, ymm1, ymm1;                    {$ELSE}db $C5,$F5,$57,$C9;{$ENDIF} 

           cmp rax, -32;
           jg @@Innerloop2Begin;

           // for z := 0 to width1 - 1do
           // AVX part:
           @@InnerLoop1:
              // 4x4 block
              {$IFDEF AVXSUP}vmovupd xmm2, [rbx];                     {$ELSE}db $C5,$F9,$10,$13;{$ENDIF} 
              add rbx, r11;
              {$IFDEF AVXSUP}vmovapd xmm4, xmm2;                      {$ELSE}db $C5,$F9,$29,$D4;{$ENDIF} 

              {$IFDEF AVXSUP}vmovupd xmm3, [rbx];                     {$ELSE}db $C5,$F9,$10,$1B;{$ENDIF} 
              add rbx, r11;

              // shuffle so we can multiply

              // swap such that we can immediately multiply
              {$IFDEF AVXSUP}vmovlhps xmm2, xmm2, xmm3;               {$ELSE}db $C5,$E8,$16,$D3;{$ENDIF} 
              {$IFDEF AVXSUP}vmovhlps xmm3, xmm3, xmm4;               {$ELSE}db $C5,$E0,$12,$DC;{$ENDIF} 

              // next 4 elements
              {$IFDEF AVXSUP}vmovupd xmm4, [rbx];                     {$ELSE}db $C5,$F9,$10,$23;{$ENDIF} 
              add rbx, r11;
              {$IFDEF AVXSUP}vmovupd xmm6, xmm4;                      {$ELSE}db $C5,$F9,$11,$E6;{$ENDIF} 

              {$IFDEF AVXSUP}vmovupd xmm5, [rbx];                     {$ELSE}db $C5,$F9,$10,$2B;{$ENDIF} 
              add rbx, r11;

              {$IFDEF AVXSUP}vmovupd ymm7, [r8 + rax]                 {$ELSE}db $C4,$C1,$7D,$10,$3C,$00;{$ENDIF} 

              {$IFDEF AVXSUP}vmovlhps xmm4, xmm4, xmm5;               {$ELSE}db $C5,$D8,$16,$E5;{$ENDIF} 
              {$IFDEF AVXSUP}vmovhlps xmm5, xmm5, xmm6;               {$ELSE}db $C5,$D0,$12,$EE;{$ENDIF} 

              {$IFDEF AVXSUP}vinsertf128 ymm2, ymm2, xmm4, 1;         {$ELSE}db $C4,$E3,$6D,$18,$D4,$01;{$ENDIF} 
              {$IFDEF AVXSUP}vinsertf128 ymm3, ymm3, xmm5, 1;         {$ELSE}db $C4,$E3,$65,$18,$DD,$01;{$ENDIF} 

              // now multiply and add
              {$IFDEF AVXSUP}vmulpd ymm2, ymm2, ymm7;                 {$ELSE}db $C5,$ED,$59,$D7;{$ENDIF} 
              {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm7;                 {$ELSE}db $C5,$E5,$59,$DF;{$ENDIF} 

              {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm2;                 {$ELSE}db $C5,$FD,$58,$C2;{$ENDIF} 
              {$IFDEF AVXSUP}vaddpd ymm1, ymm1, ymm3;                 {$ELSE}db $C5,$F5,$58,$CB;{$ENDIF} 
           add rax, 32;
           jl @@InnerLoop1;

           {$IFDEF AVXSUP}vextractf128 xmm2, ymm0, 1;                 {$ELSE}db $C4,$E3,$7D,$19,$C2,$01;{$ENDIF} 
           {$IFDEF AVXSUP}vextractf128 xmm3, ymm1, 1;                 {$ELSE}db $C4,$E3,$7D,$19,$CB,$01;{$ENDIF} 

           {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm2;                   {$ELSE}db $C5,$F9,$7C,$C2;{$ENDIF} 
           {$IFDEF AVXSUP}vhaddpd xmm1, xmm1, xmm3;                   {$ELSE}db $C5,$F1,$7C,$CB;{$ENDIF} 

           test rax, rax;
           jz @@InnerLoopEnd2;

           @@Innerloop2Begin:

           // rest in single elements
           @@InnerLoop2:
              {$IFDEF AVXSUP}vmovupd xmm2, [rbx];                     {$ELSE}db $C5,$F9,$10,$13;{$ENDIF} 
              add rbx, r11;

              {$IFDEF AVXSUP}vmovddup xmm3, [r8 + rax];               {$ELSE}db $C4,$C1,$7B,$12,$1C,$00;{$ENDIF} 

              {$IFDEF AVXSUP}vmulpd xmm2, xmm2, xmm3;                 {$ELSE}db $C5,$E9,$59,$D3;{$ENDIF} 
              {$IFDEF AVXSUP}vmovhlps xmm4, xmm4, xmm2;               {$ELSE}db $C5,$D8,$12,$E2;{$ENDIF} 

              {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm2;                 {$ELSE}db $C5,$FB,$58,$C2;{$ENDIF} 
              {$IFDEF AVXSUP}vaddsd xmm1, xmm1, xmm4;                 {$ELSE}db $C5,$F3,$58,$CC;{$ENDIF} 
           add rax, 8;
           jnz @@InnerLoop2;

           @@InnerLoopEnd2:

           // finall horizontal addition
           {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm1;                   {$ELSE}db $C5,$F9,$7C,$C1;{$ENDIF} 

           {$IFDEF AVXSUP}vmovupd [rcx], xmm0;                        {$ELSE}db $C5,$F9,$11,$01;{$ENDIF} 

           // increment the pointers
           // inc(mt2), inc(dest);
           //add dword ptr [mt2], 8;
           add r9, 16;
           add rcx, 16;

       // end for x := 0 to width2 div 2 - 1
       sub r13, 2;
       jge @@forxloop;

       @LastXColumn:

       cmp r13, -1;
       jne @NextLine;

       // last column of mt2
       mov rax, r10;
       mov rbx, r9;

       {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                        {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 

       @InnerLoop2:
          {$IFDEF AVXSUP}vmovsd xmm1, [r8 + rax];                     {$ELSE}db $C4,$C1,$7B,$10,$0C,$00;{$ENDIF} 
          {$IFDEF AVXSUP}vmovsd xmm2, [rbx];                          {$ELSE}db $C5,$FB,$10,$13;{$ENDIF} 

          {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                     {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
          {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                     {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 

          add rbx, r11;
       add rax, 8;
       jnz @InnerLoop2;

       {$IFDEF AVXSUP}vmovsd [rcx], xmm0;                             {$ELSE}db $C5,$FB,$11,$01;{$ENDIF} 
       add rcx, 8;
       add r9, 8;

       @NextLine:
       // dec(mt2, Width2);
       // inc(PByte(mt1), LineWidth1);
       // inc(PByte(dest), destOffset);
       //mov ebx, bytesWidth2;
       //sub dword ptr [mt2], ebx;
       sub r9, r14;
       add r8, rdi;
       add rcx, r15;

    // end for y := 0 to height1 - 1
    //dec eax;
    dec rsi;
    jnz @@foryloop;

    // epilog
    mov rbx, iRBX;
    mov rsi, iRSI;
    mov rdi, iRDI;
    mov r12, iR12;
    mov r13, iR13;
    mov r14, iR14;
    mov r15, iR15;

    {$IFDEF AVXSUP}vmovupd xmm4, [rsp + $00];                         {$ELSE}db $C5,$F9,$10,$24,$24;{$ENDIF} 
    {$IFDEF AVXSUP}vmovupd xmm5, [rsp + $10];                         {$ELSE}db $C5,$F9,$10,$6C,$24,$10;{$ENDIF} 
    {$IFDEF AVXSUP}vmovupd xmm6, [rsp + $20];                         {$ELSE}db $C5,$F9,$10,$74,$24,$20;{$ENDIF} 
    add rsp, $30;

    {$IFDEF AVXSUP}vzeroupper;                                        {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;


// ###########################################
// #### Special multiplication routines (for now only used in QR Decomposition)
// ###########################################

procedure AVXMtxMultTria2T1StoreT1(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var iRBX, iRDI, iRSI : NativeInt;
    {$IFDEF UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
// rcx = mt1, rdx = LineWidth1, r8 = mt2, r9 = LineWidth2
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // prolog: stack
   mov iRBX, rbx;
   mov iRDI, rdi;
   mov iRSI, rsi;

   //iter := -width1*sizeof(double);
   mov r10, width1;
   imul r10, -8;

   // testExitLoopVal := height2*sizeof(double) + iter;
   mov r11, height2;
   shl r11, 3; //*8
   add r11, r10;

   // rcx := mt1
   sub rcx, r10;  // mt1 - iter

   // for y loop
   @@foryloop:
      mov rbx, r8;
      sub rbx, r10;
      mov rsi, r10;

      @@forxloop:
         {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                      {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} // temp := 0

         mov rax, rsi;  // loop counter x;

         // test if height2 > width1 and loop counter > width1
         mov rdi, rax;
         test rdi, rdi;
         jge @@foriloopend;

         // in case x is odd -> handle the first element separately
         and rdi, $E;
         jz @@foriloopAVX;

         // single element handling
         {$IFDEF AVXSUP}vmovsd xmm1, [rcx + rax];                     {$ELSE}db $C5,$FB,$10,$0C,$01;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd xmm2, [rbx + rax];                     {$ELSE}db $C5,$FB,$10,$14,$03;{$ENDIF} 
         {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                      {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
         {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                      {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
         add rax, 8;

         @@foriloopAVX:
            // 4 elements at a time
            add rax, 32;
            jg @@foriloopAVXend;

            {$IFDEF AVXSUP}vmovupd ymm1, [rcx + rax - 32];            {$ELSE}db $C5,$FD,$10,$4C,$01,$E0;{$ENDIF} 
            {$IFDEF AVXSUP}vmovupd ymm2, [rbx + rax - 32];            {$ELSE}db $C5,$FD,$10,$54,$03,$E0;{$ENDIF} 
            {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm2;                   {$ELSE}db $C5,$F5,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                   {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 

         jmp @@foriloopAVX;

         @@foriloopAVXend:

         {$IFDEF AVXSUP}vextractf128 xmm2, ymm0, 1;                   {$ELSE}db $C4,$E3,$7D,$19,$C2,$01;{$ENDIF} 
         {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm2;                     {$ELSE}db $C5,$F9,$7C,$C2;{$ENDIF} 

         sub rax, 32;
         jz @@foriloopend;

         // for i := x to width1 - 1
         @@foriloop:
            // two elements at a time:
            {$IFDEF AVXSUP}vmovupd xmm1, [rcx + rax];                 {$ELSE}db $C5,$F9,$10,$0C,$01;{$ENDIF} 
            {$IFDEF AVXSUP}vmovupd xmm2, [rbx + rax];                 {$ELSE}db $C5,$F9,$10,$14,$03;{$ENDIF} 
            {$IFDEF AVXSUP}vmulpd xmm1, xmm1, xmm2;                   {$ELSE}db $C5,$F1,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm1;                   {$ELSE}db $C5,$F9,$58,$C1;{$ENDIF} 

            add rax, 16;
         jnz @@foriloop;

         @@foriloopend:

         // final result
         {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                     {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd [rcx + rsi], xmm0;                     {$ELSE}db $C5,$FB,$11,$04,$31;{$ENDIF} 

         add rbx, r9;
         add rsi, 8;

         mov rax, r11;
      cmp rsi, rax;
      jne @@forxloop;

      add rcx, rdx;
   dec height1;
   jnz @@foryloop;

   // epilog
   mov rbx, iRBX;
   mov rdi, iRDI;
   mov rsi, iRSI;

   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

procedure AVXMtxMultTria2TUpperUnit(dest : PDouble; LineWidthDest : NativeInt; mt1 : PDouble; LineWidth1 : NativeInt;
  {$ifdef UNIX}unixMT2{$ELSE}mt2{$endif} : PDouble; {$ifdef UNIX}unixLineWidth2{$ELSE}LineWidth2{$endif} : NativeInt;
  width1, height1, width2, height2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var iRBX, iRDI, iRSI, iR12, iR13 : NativeInt;
    {$IFDEF UNIX}
    mt2 : PDouble;
    LineWidth2 : NativeInt;
    {$ENDIF}
// rcx = dest, rdx = LineWidthDest, r8 = mt1, r9 = LineWidth1
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov mt2, r8;
   mov LineWidth2, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // prolog: stack
   mov iRBX, rbx;
   mov iRDI, rdi;
   mov iRSI, rsi;
   mov iR12, r12;
   mov iR13, r13;

   // r12: mt2
   mov r12, mt2;
   // r13: LineWidth2
   mov r13, LineWidth2;

   //iter := -width1*sizeof(double);
   mov r10, width1;
   imul r10, -8;

   // testExitLoopVal := height2*sizeof(double) + iter;
   mov r11, height2;
   shl r11, 3; //*8
   add r11, r10;

   // r8 := mt1
   sub r8, r10;  // mt1 - iter
   sub rcx, r10;

   // for y loop
   @@foryloop:
      mov rbx, r12;
      sub rbx, r10;
      mov rsi, r10;

      @@forxloop:
         {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                      {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} // temp := 0

         mov rax, rsi;  // loop counter x;

         // test if height2 > width1 and loop counter > width1
         mov rdi, rax;
         test rdi, rdi;
         jge @@foriloopend;

         // in case x is odd -> handle the first element separately
         and rdi, $E;
         jz @@foriloopinit;

         // single element handling -> mt1 first element is assumed unit!
         {$IFDEF AVXSUP}vmovsd xmm0, [r8 + rax];                      {$ELSE}db $C4,$C1,$7B,$10,$04,$00;{$ENDIF} 
         add rax, 8;

         jmp @@AfterLoopInit;

         @@foriloopinit:

         test rax, rax;
         jz @@foriloopend;

         // two elements init at a time:
         {$IFDEF AVXSUP}vmovsd xmm0, [r8 + rax];                      {$ELSE}db $C4,$C1,$7B,$10,$04,$00;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd xmm1, [r8 + rax + 8];                  {$ELSE}db $C4,$C1,$7B,$10,$4C,$00,$08;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd xmm2, [rbx + rax + 8];                 {$ELSE}db $C5,$FB,$10,$54,$03,$08;{$ENDIF} 
         {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                      {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
         {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                      {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 

         add rax, 16;

         @@AfterLoopInit:

         // in case the last single x element was handled we do not need further looping
         test rax, rax;
         jz @@finalizeloop;

         // for i := x to width1 - 1
         @@foriloop:
             add rax, 32;

             jg @@foriloopend;

             // two elements at a time:
             {$IFDEF AVXSUP}vmovupd ymm1, [r8 + rax - 32];            {$ELSE}db $C4,$C1,$7D,$10,$4C,$00,$E0;{$ENDIF} 
             {$IFDEF AVXSUP}vmovupd ymm2, [rbx + rax - 32];           {$ELSE}db $C5,$FD,$10,$54,$03,$E0;{$ENDIF} 
             {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm2;                  {$ELSE}db $C5,$F5,$59,$CA;{$ENDIF} 
             {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                  {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
         jmp @@foriloop;

         @@foriloopend:
         {$IFDEF AVXSUP}vextractf128 xmm1, ymm0, 1;                   {$ELSE}db $C4,$E3,$7D,$19,$C1,$01;{$ENDIF} 
         {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm1;                     {$ELSE}db $C5,$F9,$7C,$C1;{$ENDIF} 
         sub rax, 32;

         // test if we missed 2 elements
         jz @@finalizeloop;

         // need to process two more elements:
         {$IFDEF AVXSUP}vmovupd xmm1, [r8 + rax];                     {$ELSE}db $C4,$C1,$79,$10,$0C,$00;{$ENDIF} 
         {$IFDEF AVXSUP}vmovupd xmm2, [rbx + rax];                    {$ELSE}db $C5,$F9,$10,$14,$03;{$ENDIF} 
         {$IFDEF AVXSUP}vmulpd xmm1, xmm1, xmm2;                      {$ELSE}db $C5,$F1,$59,$CA;{$ENDIF} 
         {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm1;                      {$ELSE}db $C5,$F9,$58,$C1;{$ENDIF} 

         @@finalizeloop:

         // final result
         {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                     {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd [rcx + rsi], xmm0;                     {$ELSE}db $C5,$FB,$11,$04,$31;{$ENDIF} 

         add rbx, r13;
         add rsi, 8;

      mov rax, r11;
      cmp rsi, rax;
      jne @@forxloop;

      add r8, r9;
      add rcx, rdx;
   dec height1;
   jnz @@foryloop;

   // epilog
   mov rbx, iRBX;
   mov rdi, iRDI;
   mov rsi, iRSI;
   mov r12, iR12;
   mov r13, iR13;

   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

// note the result is stored in mt2 again!
// dest = mt1'*mt2; where mt2 is a lower triangular matrix and the operation is transposition
// the function assumes a unit diagonal (does not touch the real middle elements)
// width and height values are assumed to be the "original" (non transposed) ones
procedure AVXMtxMultTria2T1(dest : PDouble; LineWidthDest : NativeInt; mt1 : PDouble; LineWidth1 : NativeInt;
  {$ifdef UNIX}unixMT2{$ELSE}mt2{$endif} : PDouble; {$ifdef UNIX}unixLineWidth2{$ELSE}LineWidth2{$endif} : NativeInt;
  width1, height1, width2, height2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var pMt2 : PDouble;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
    {$IFDEF UNIX}
    mt2 : PDouble;
    LineWidth2 : NativeInt;
    {$ENDIF}
// note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = LineWidth1
// prolog - simulate stack
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov mt2, r8;
   mov LineWidth2, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   mov iR12, r12;
   mov iR13, r13;
   mov iR14, r14;
   mov iR15, r15;
   mov iRSI, rsi;
   mov iRDI, rdi;
   mov iRBX, rbx;

   mov r15, LineWidth2;   // Linewidth2 is on the stack -> use it in local register

   // width2D2 := width2 div 2;
   mov r14, width2;
   shr r14, 1;

   // for x := 0 to width1 - 1 do
   mov rax, width1;

   @@forxloop:

     // pMT2 := mt2;
     // pDest := dest;

     mov rbx, mt2;
     mov pMT2, rbx;

     mov r13, rcx;   // r13 is pDest


     // for y := 0 to width2D2 - 1 do
     mov r12, r14;
     test r12, r12;
     jz @@foryloopend;

     xor r12, r12;
     @@foryloop:

          // valCounter1 := PConstDoubleArr(mt1);
          // inc(PByte(valCounter1), 2*y*LineWidth1);
          mov rsi, r8;
          mov rbx, r12;
          add rbx, rbx;
          imul rbx, r9;
          add rsi, rbx;

          // valCounter2 := PConstDoubleArr(pMT2);
          // inc(PByte(valCounter2), (2*y + 1)*LineWidth2);
          mov rdi, pMt2;
          mov rbx, r12;
          add rbx, rbx;
          imul rbx, r15;
          add rbx, r15;
          add rdi, rbx;

          // tmp[0] := valCounter1^[0];
          // inc(PByte(valCounter1), LineWidth1);
          {$IFDEF AVXSUP}vmovsd xmm0, [rsi];                          {$ELSE}db $C5,$FB,$10,$06;{$ENDIF} 
          add rsi, r9;

          // if height2 - 2*y - 1 > 0 then
          mov rbx, r12;
          add rbx, rbx;
          inc rbx;

          cmp rbx, height2;
          jnl @@PreInnerLoop;
              // tmp[0] := tmp[0] + valCounter1^[0]*valCounter2^[0];
              // tmp[1] := valCounter1^[0];
              {$IFDEF AVXSUP}vmovsd xmm1, [rsi];                      {$ELSE}db $C5,$FB,$10,$0E;{$ENDIF} 
              {$IFDEF AVXSUP}vmovlhps xmm0, xmm0, xmm1;               {$ELSE}db $C5,$F8,$16,$C1;{$ENDIF} 

              {$IFDEF AVXSUP}vmulsd xmm1, xmm1, [rdi];                {$ELSE}db $C5,$F3,$59,$0F;{$ENDIF} 
              {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                 {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 

              //inc(PByte(valCounter1), LineWidth1);
              //inc(PByte(valCounter2), LineWidth2);

              add rsi, r9;
              add rdi, r15;

          @@PreInnerLoop:

          // rest is a double column!

          // prepare loop
          mov rbx, height2;
          sub rbx, r12;
          sub rbx, r12;
          sub rbx, 2;

          test rbx, rbx;
          jle @@InnerLoopEnd;

          @@InnerLoop:
             // tmp[0] := tmp[0] + valCounter1^[0]*valCounter2^[0];
             // tmp[1] := tmp[1] + valCounter1^[0]*valCounter2^[1];
             {$IFDEF AVXSUP}vmovddup xmm1, [rsi];                     {$ELSE}db $C5,$FB,$12,$0E;{$ENDIF} 
             {$IFDEF AVXSUP}vmovupd xmm2, [rdi];                      {$ELSE}db $C5,$F9,$10,$17;{$ENDIF} 

             {$IFDEF AVXSUP}vmulpd xmm2, xmm2, xmm1;                  {$ELSE}db $C5,$E9,$59,$D1;{$ENDIF} 
             {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm2;                  {$ELSE}db $C5,$F9,$58,$C2;{$ENDIF} 

             //inc(PByte(valCounter1), LineWidth1);
             //inc(PByte(valCounter2), LineWidth2);

             add rsi, r9;
             add rdi, r15;

          dec rbx;
          jnz @@InnerLoop;

          @@InnerLoopEnd:


          // write back result

          // pDest^ := tmp[0];
          // PDouble(NativeUint(pDest) + sizeof(double))^ := tmp[1];

          {$IFDEF AVXSUP}vmovupd [r13], xmm0;                         {$ELSE}db $C4,$C1,$79,$11,$45,$00;{$ENDIF} 

          // inc(pDest, 2);
          // inc(pMT2, 2);
          add r13, 16;
          add pMT2, 16;

     // end foryloop
     inc r12;
     cmp r12, r14;
     jne @@foryloop;

     @@foryloopend:


     //if (width2 and $01) = 1 then
     mov r12, width2;
     and r12, 1;

     jz @@ifend1;

       // special handling of last column (just copy the value)

       // valCounter1 := PConstDoubleArr(mt1);
       mov r12, r8;

       //inc(PByte(valCounter1), LineWidth1*(height1 - 1));
       mov rbx, height1;
       dec rbx;
       imul rbx, r9;

       // pDest^ := valCounter1^[0];
       {$IFDEF AVXSUP}vmovsd xmm0, [r12 + rbx];                       {$ELSE}db $C4,$C1,$7B,$10,$04,$1C;{$ENDIF} 
       {$IFDEF AVXSUP}vmovsd [r13], xmm0;                             {$ELSE}db $C4,$C1,$7B,$11,$45,$00;{$ENDIF} 
     @@ifend1:


     //inc(mt1);
     //inc(PByte(dest), LineWidthDest);
     add r8, 8;
     add rcx, rdx;    // note: this can be done since dest is rcx

   // end for loop
   dec rax;
   jnz @@forxloop;

   // epilog
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov rbx, iRBX;

   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

// calculates mt1 = mt1*mt2', mt2 = lower triangular matrix. diagonal elements are assumed to be 1!
procedure AVXMtxMultLowTria2T2Store1(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var iRBX, iRDI, iRSI : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
// rcx: mt1, rdx: LineWidth1, r8 : mt2, r9 : LineWidth2
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // prolog - stack
   mov iRBX, rbx;
   mov iRDI, rdi;
   mov iRSI, rsi;
   // r11 : height1
   mov r11, height1;
   // r10 = iter := -(width2 - 1)*sizeof(double);
   mov r10, width2;
   dec r10;
   imul r10, -8;

   // start from bottom
   // r8: mt2
   // inc(PByte(mt2),(height2 - 1)*LineWidth2);
   mov rax, height2;
   dec rax;
   imul rax, r9;
   add r8, rax;
   sub r8, r10;
   // for x := 0 to width2 - 2
   mov rbx, width2;
   dec rbx;
   jz @@endproc;
   @@forxloop:
      mov rax, rcx;
      sub rax, r10;
           // for y := 0 to height1 - 1
      mov rsi, r11;
      @@foryloop:
         {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                      {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 
         // for idx := 0 to width2 - x - 2
         mov rdi, r10;
         test rdi, rdi;
         jz @@foridxloopend;

         // unrolled loop 2x2
         add rdi, 64;
         jg @@foridxloopSSE;
         @@foridxlongloop:
            {$IFDEF AVXSUP}vmovupd ymm1, [rax + rdi - 64];            {$ELSE}db $C5,$FD,$10,$4C,$38,$C0;{$ENDIF} 
            {$IFDEF AVXSUP}vmovupd ymm2, [r8 + rdi - 64];             {$ELSE}db $C4,$C1,$7D,$10,$54,$38,$C0;{$ENDIF} 
            {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm2;                   {$ELSE}db $C5,$F5,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                   {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 

            {$IFDEF AVXSUP}vmovupd ymm1, [rax + rdi - 32];            {$ELSE}db $C5,$FD,$10,$4C,$38,$E0;{$ENDIF} 
            {$IFDEF AVXSUP}vmovupd ymm2, [r8 + rdi - 32];             {$ELSE}db $C4,$C1,$7D,$10,$54,$38,$E0;{$ENDIF} 
            {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm2;                   {$ELSE}db $C5,$F5,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm1;                   {$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
         add rdi, 64;
         jl @@foridxlongloop;

         {$IFDEF AVXSUP}vextractf128 xmm1, ymm0, 1;                   {$ELSE}db $C4,$E3,$7D,$19,$C1,$01;{$ENDIF} 
         {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm1;                     {$ELSE}db $C5,$F9,$7C,$C1;{$ENDIF} 
              // sse part
         @@foridxloopSSE:
         sub rdi, 64 - 16;
         jg @@foridxloopstart;

         @@foridxSSEloop:
            {$IFDEF AVXSUP}vmovupd xmm1, [rax + rdi - 16];            {$ELSE}db $C5,$F9,$10,$4C,$38,$F0;{$ENDIF} 
            {$IFDEF AVXSUP}vmovupd xmm2, [r8 + rdi - 16];             {$ELSE}db $C4,$C1,$79,$10,$54,$38,$F0;{$ENDIF} 
            {$IFDEF AVXSUP}vmulpd xmm1, xmm1, xmm2;                   {$ELSE}db $C5,$F1,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm1;                   {$ELSE}db $C5,$F9,$58,$C1;{$ENDIF} 
         add rdi, 16;
         jl @@foridxSSEloop;

         @@foridxloopStart:
         {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                     {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 
         sub rdi, 16;
         jz @@foridxloopend;

         @@foridxloop:
            {$IFDEF AVXSUP}vmovsd xmm1, [rax + rdi];                  {$ELSE}db $C5,$FB,$10,$0C,$38;{$ENDIF} 
            {$IFDEF AVXSUP}vmovsd xmm2, [r8 + rdi];                   {$ELSE}db $C4,$C1,$7B,$10,$14,$38;{$ENDIF} 
            {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                   {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                   {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
         add rdi, 8;
         jnz @@foridxloop;

         @@foridxloopend:

         // last element is unit:
         {$IFDEF AVXSUP}vmovsd xmm1, [rax];                           {$ELSE}db $C5,$FB,$10,$08;{$ENDIF} 
         {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                      {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 

         // write back
         // PConstDoubleArr(pMt1)^[width2 - x - 1] := tmp + valCounter1^[width2 - x - 1];
         {$IFDEF AVXSUP}vmovsd [rax], xmm0;                           {$ELSE}db $C5,$FB,$11,$00;{$ENDIF} 
         add rax, rdx;
      dec rsi;
      jnz @@foryloop;

      // dec(PByte(mt2), LineWidth2);
      sub r8, r9;
      sub r8, 8;
      // adjust iterator to the next x value for the idxloop
      add r10, 8;
   dec rbx;
   jnz @@forxloop;

   @@endproc:

   // epilog: stack fixing
   mov rbx, iRBX;
   mov rdi, iRDI;
   mov rsi, iRSI;
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;


// note the result is stored in mt1 again!
// mt1 = mt1*mt2; where mt2 is an upper triangular matrix
procedure AVXMtxMultTria2Store1(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var iRBX, iRDI, iRSI, iR12, iR13 : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
// prolog init stack
// rcx = mt1, rdx = LineWidth1, r8 = mt2, r9 = LineWidth2
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // prolog: stack
   mov iRBX, rbx;
   mov iRDI, rdi;
   mov iRSI, rsi;
   mov iR12, r12;
   mov iR13, r13;

   // r13 = height1
   mov r13, height1;

   // wm1: r11
   mov r11, width2;
   dec r11;

   // iter: r10
   mov r10, width1;
   imul r10, -8;
   // init

   // inc(mt2, width2 - 1);
   mov rax, r11;
   shl rax, 3; //sizeof(double)
   add r8, rax;


   // for x := 0 to width2 - 1 do
   mov r12, width2;
   @@forxloop:
      mov rdi, r13;  // height1

      mov rax, rcx;
      sub rax, r10;

      // for y := 0 to height1 - 1
      @@foryloop:
         // tmp := 0;
         {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                      {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 

         // r8, mt2
         mov rbx, r8;

         // for idx := 0 to width1 - x - 1
         mov rsi, r10;

         // check if we have enough iterations:
         test rsi, rsi;
      jz @@foridxloopend;

      @@foridxloop:
         {$IFDEF AVXSUP}vmovsd xmm1, [rbx];                           {$ELSE}db $C5,$FB,$10,$0B;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd xmm2, [rax + rsi];                     {$ELSE}db $C5,$FB,$10,$14,$30;{$ENDIF} 

         add rbx, r9;  // + linewidth2

         {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                      {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
         {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                      {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 

         add rsi, 8;
      jnz @@foridxloop;

      @@foridxloopend:

      // PConstDoubleArr(pmt1)^[width2 - 1 - x] := tmp;
      mov rbx, rax;
      add rbx, r10;
      mov rsi, r12; // r12 = width2
      dec rsi;
      {$IFDEF AVXSUP}vmovsd [rbx + 8*rsi], xmm0;                      {$ELSE}db $C5,$FB,$11,$04,$F3;{$ENDIF} 

      // inc(PByte(pmT1), LineWidth1);
      add rax, rdx;

      dec rdi;
      jnz @@foryloop;

      // reduce for idx loop
      add r10, 8;
      // dec(mt2);
      sub r8, 8;

   // dec width2
   dec r12;
   jnz @@forxloop;

   // cleanup stack
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 

   mov rbx, iRBX;
   mov rdi, iRDI;
   mov rsi, iRSI;
   mov r12, iR12;
   mov r13, iR13;
end;


// no avx optimization yet...
procedure AVXMtxMultTria2Store1Unit(mt1 : PDouble; LineWidth1 : NativeInt; mt2 : PDouble; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt); {$IFDEF FPC}assembler;{$ENDIF}
var iRBX, iRDI, iRSI, iR12 : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
// rcx : mt1, rdx : LineWidth1, r8 : mt2, r9: LineWidth2
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // prolog - stack
   mov iRBX, rbx;
   mov iRDI, rdi;
   mov iRSI, rsi;
   mov iR12, r12;
   // init

   // r12: height1
   mov r12, height1;

   // r10 : iter := -(width1-1)*sizeof(double);
   mov r10, width1;
   dec r10;
   imul r10, -8;

   // inc(mt2, width2 - 1);
   mov rax, width2;
   dec rax;
   shl rax, 3; //sizeof(double)
   add r8, rax;

   // r11: width2
   mov r11, width2;
   dec r11;

   // for x := 0 to width2 - 2 do
   @@forxloop:
       mov rdi, r12;

       mov rax, rcx;
       sub rax, r10;

       // for y := 0 to height1 - 1
       @@foryloop:
           // tmp := 0;
           {$IFDEF AVXSUP}vxorpd xmm0, xmm0, xmm0;                    {$ELSE}db $C5,$F9,$57,$C0;{$ENDIF} 

           // r8, mt2
           mov rbx, r8;

           // for idx := 0 to width1 - x - 2
           mov rsi, r10;

           // check if we have enough r10ations:
           cmp rsi, 0;
           jge @@foridxloopend;

           @@foridxloop:
               {$IFDEF AVXSUP}vmovsd xmm1, [rbx];                     {$ELSE}db $C5,$FB,$10,$0B;{$ENDIF} 
               {$IFDEF AVXSUP}vmovsd xmm2, [rax + rsi]                {$ELSE}db $C5,$FB,$10,$14,$30;{$ENDIF} 

               add rbx, r9;  // + linewidth2

               {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
               {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 

           add rsi, 8;
           jnz @@foridxloop;

           @@foridxloopend:

           // last element is unit
           {$IFDEF AVXSUP}vaddsd xmm0, xmm0, [rax];                   {$ELSE}db $C5,$FB,$58,$00;{$ENDIF} 

           // PConstDoubleArr(pmt1)^[width2 - 1 - x] := tmp;
           mov rbx, rax;
           add rbx, r10;
           mov rsi, r11;
           {$IFDEF AVXSUP}vmovsd [rbx + 8*rsi], xmm0;                 {$ELSE}db $C5,$FB,$11,$04,$F3;{$ENDIF} 

           // inc(PByte(pmT1), LineWidth1);
           add rax, rdx;

       dec rdi;
       jnz @@foryloop;

       // reduce for idx loop
       add r10, 8;
       // dec(mt2);
       sub r8, 8;

   dec r11;
   jnz @@forxloop;

   @@endproc:

   // cleanup stack
   mov rbx, iRBX;
   mov rdi, iRDI;
   mov rsi, iRSI;
   mov r12, iR12;
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;


procedure AVXSymRank2UpdateUpperUnaligned( C : PDouble; LineWidthC : NativeInt; A : PDouble; LineWidthA : NativeInt;
  {$IFDEF UNIX}unixB {$ELSE} B {$ENDIF}: PDouble;
  {$IFDEF UNIX}unixLineWidthB {$ELSE} LineWidthB {$ENDIF} : NativeInt; N : NativeInt; k : NativeInt );
// rcx = C, rdx = LineWidthC, r8 = A, r9 = LineWidthA
// unix has B and LineWidthB also in registers
var i, j : NativeInt;
    iRBX, iRDI, iRSI : NativeInt;
    dXMM4 : TXMMArr;
    {$IFDEF UNIX}
    B : PDouble; LineWidthB : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov B, unixB;
   mov LineWidthB, unixLineWidthB;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // save register
   mov iRBX, rbx;
   mov iRDI, rdi;
   mov iRSI, rsi;
   {$IFDEF AVXSUP}vmovupd dXMM4, xmm4;                                {$ELSE}db $C5,$F9,$11,$65,$C8;{$ENDIF} 

   // rcx -> pointer to C
   // r8 -> ponter to pA1
   // rsi -> pointer to pB1
   mov rsi, B;

   mov rdi, k;
   imul rdi, -8;
   mov k, rdi;

   sub r8, rdi;
   sub rsi, rdi;

   mov rdi, N;
   shl rdi, 3;
   add rcx, rdi;


   // for j := 0 to N - 1 do
   //
   neg rdi;
   mov j, rdi;
   @@forNLoop:
       mov r10, j;
       mov i, r10;

       // ###########################################
       // #### Init A2 and B2
       // pA2
       mov rbx, r8;
       // pB2
       mov rdi, rsi;

       @@forjNLoop:
            {$IFDEF AVXSUP}vxorpd ymm0, ymm0, ymm0;                   {$ELSE}db $C5,$FD,$57,$C0;{$ENDIF} 

            // ###########################################
            // #### Init loop
            mov r10, k;

            // ymm path
            @@forlLoop2:
               add r10, 32;
               jg @@forlLoop2End;

               {$IFDEF AVXSUP}vmovupd ymm1, [r8 + r10 - 32];          {$ELSE}db $C4,$81,$7D,$10,$4C,$10,$E0;{$ENDIF} // pA1;
               {$IFDEF AVXSUP}vmovupd ymm2, [rdi + r10 - 32];         {$ELSE}db $C4,$A1,$7D,$10,$54,$17,$E0;{$ENDIF} // pB2
               {$IFDEF AVXSUP}vmovupd ymm3, [rsi + r10 - 32];         {$ELSE}db $C4,$A1,$7D,$10,$5C,$16,$E0;{$ENDIF} // pB1;
               {$IFDEF AVXSUP}vmovupd ymm4, [rbx + r10 - 32];         {$ELSE}db $C4,$A1,$7D,$10,$64,$13,$E0;{$ENDIF} // pA2;

               {$IFDEF AVXSUP}vmulpd ymm1, ymm1, ymm2;                {$ELSE}db $C5,$F5,$59,$CA;{$ENDIF} 
               {$IFDEF AVXSUP}vaddpd ymm0, ymm1, ymm0;                {$ELSE}db $C5,$F5,$58,$C0;{$ENDIF} 
               {$IFDEF AVXSUP}vmulpd ymm3, ymm3, ymm4;                {$ELSE}db $C5,$E5,$59,$DC;{$ENDIF} 
               {$IFDEF AVXSUP}vaddpd ymm0, ymm0, ymm3;                {$ELSE}db $C5,$FD,$58,$C3;{$ENDIF} 

            jmp @@forlLoop2;

            @@forlLoop2End:

            {$IFDEF AVXSUP}vextractf128 xmm1, ymm0, 1;                {$ELSE}db $C4,$E3,$7D,$19,$C1,$01;{$ENDIF} 
            {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm1;                   {$ELSE}db $C5,$F9,$58,$C1;{$ENDIF} 

            sub r10, 32;
            cmp r10, 32;
            je @@NextN;

            // accumulate
            @@forlLoop:
                add r10, 16;
                jg @@forlLoopEnd;

                {$IFDEF AVXSUP}vmovupd xmm1, [r8 + r10 - 16];         {$ELSE}db $C4,$81,$79,$10,$4C,$10,$F0;{$ENDIF} // pA1;
                {$IFDEF AVXSUP}vmovupd xmm2, [rdi + r10 - 16];        {$ELSE}db $C4,$A1,$79,$10,$54,$17,$F0;{$ENDIF} // pB2
                {$IFDEF AVXSUP}vmovupd xmm3, [rsi + r10 - 16];        {$ELSE}db $C4,$A1,$79,$10,$5C,$16,$F0;{$ENDIF} // pB1;
                {$IFDEF AVXSUP}vmovupd xmm4, [rbx + r10 - 16];        {$ELSE}db $C4,$A1,$79,$10,$64,$13,$F0;{$ENDIF} // pA2;

                {$IFDEF AVXSUP}vmulpd xmm1, xmm1, xmm2;               {$ELSE}db $C5,$F1,$59,$CA;{$ENDIF} 
                {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm1;               {$ELSE}db $C5,$F9,$58,$C1;{$ENDIF} 
                {$IFDEF AVXSUP}vmulpd xmm3, xmm3, xmm4;               {$ELSE}db $C5,$E1,$59,$DC;{$ENDIF} 
                {$IFDEF AVXSUP}vaddpd xmm0, xmm0, xmm3;               {$ELSE}db $C5,$F9,$58,$C3;{$ENDIF} 
            jmp @@forlLoop;

            @@forlLoopEnd:

            // is iterator actualy 16? (aka even k)
            cmp r10, 16;
            je @@NextN;

            // last element
            {$IFDEF AVXSUP}vmovsd xmm1, [r8 - 8];                     {$ELSE}db $C4,$C1,$7B,$10,$48,$F8;{$ENDIF} // pA1;
            {$IFDEF AVXSUP}vmovsd xmm2, [rdi - 8];                    {$ELSE}db $C5,$FB,$10,$57,$F8;{$ENDIF} // pB2
            {$IFDEF AVXSUP}vmovsd xmm3, [rsi - 8];                    {$ELSE}db $C5,$FB,$10,$5E,$F8;{$ENDIF} // pB1;
            {$IFDEF AVXSUP}vmovsd xmm4, [rbx - 8];                    {$ELSE}db $C5,$FB,$10,$63,$F8;{$ENDIF} // pA2;

            {$IFDEF AVXSUP}vmulsd xmm1, xmm1, xmm2;                   {$ELSE}db $C5,$F3,$59,$CA;{$ENDIF} 
            {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm1;                   {$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
            {$IFDEF AVXSUP}vmulsd xmm3, xmm3, xmm4;                   {$ELSE}db $C5,$E3,$59,$DC;{$ENDIF} 
            {$IFDEF AVXSUP}vaddsd xmm0, xmm0, xmm3;                   {$ELSE}db $C5,$FB,$58,$C3;{$ENDIF} 

            @@NextN:

            // ###########################################
            // #### pC^[i] := pC^[i] - xmm0
            mov r10, i;
            {$IFDEF AVXSUP}vhaddpd xmm0, xmm0, xmm0;                  {$ELSE}db $C5,$F9,$7C,$C0;{$ENDIF} 
            {$IFDEF AVXSUP}vmovsd xmm1, [rcx + r10];                  {$ELSE}db $C4,$A1,$7B,$10,$0C,$11;{$ENDIF} 

            {$IFDEF AVXSUP}vsubsd xmm1, xmm1, xmm0;                   {$ELSE}db $C5,$F3,$5C,$C8;{$ENDIF} 
            {$IFDEF AVXSUP}vmovsd [rcx + r10], xmm1;                  {$ELSE}db $C4,$A1,$7B,$11,$0C,$11;{$ENDIF} 

            add rbx, r9;          // increment pA2
            add rdi, LineWidthB;  // increment pB2

       add i, 8;
       jnz @@forjNLoop;

       // next line
       add rcx, rdx;
       add r8, r9;
       add rsi, LineWidthB;
   add j, 8;
   jnz @@forNLoop;

   // ###########################################
   // #### Finalize stack
   {$IFDEF AVXSUP}vmovupd dXMM4, xmm4;                                {$ELSE}db $C5,$F9,$11,$65,$C8;{$ENDIF} 
   mov rbx, iRBX;
   mov rdi, iRDI;
   mov rsi, iRSI;

   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;


{$ENDIF}

end.
