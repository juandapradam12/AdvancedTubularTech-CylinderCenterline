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

// Vector/Matrix rotation routines mainly used for the SVD

unit AVXMatrixRotations;

interface

{$I 'mrMath_CPU.inc'}

{$IFNDEF x64}


uses MatrixConst;

procedure AVXApplyPlaneRotSeqRVB(width, height : NativeInt; A : PDouble; const LineWidthA : NativeInt; C, S : PConstDoubleArr); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
procedure AVXApplyPlaneRotSeqRVF(width, height : NativeInt; A : PDouble; const LineWidthA : NativeInt; C, S : PConstDoubleArr); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
procedure AVXApplyPlaneRotSeqLVF(width, height : NativeInt; A : PDouble; const LineWidthA : NativeInt; C, S : PConstDoubleArr); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
procedure AVXApplyPlaneRotSeqLVB(width, height : NativeInt; A : PDouble; const LineWidthA : NativeInt; C, S : PConstDoubleArr); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}


procedure AVXMatrixRotate(N : NativeInt; X : PDouble; const LineWidthDX : NativeInt; Y : PDouble; LineWidthDY : NativeInt; const c, s : double);

{$ENDIF}

implementation

{$IFNDEF x64}

const cLocMinusOne : double = -1;
      cLocOne : double = 1;
      cLocMulM1Bits : Array[0..1] of Int64 = ($8000000000000000, $0);

procedure AVXApplyPlaneRotSeqLVB(width, height : NativeInt; A : PDouble; const LineWidthA : NativeInt; C, S : PConstDoubleArr);
var y2 : NativeInt;
    iter : NativeInt;
// eax = width, edx = height, ecx = A
asm
   push ebx;
   push edi;
   push esi;

   // store "is odd" flag
   mov esi, eax;
   and esi, 1;

   // if (height < 2) or (width < 1) then exit;
   cmp eax, 1;
   jl @@endproc;
   cmp edx, 2;
   jl @@endproc;

   // y2 := height - 1;
   dec edx;
   mov y2, edx;

   // iter := -(width and $FFFFFFFE)*sizeof(double);
   and eax, $FFFFFFFE;
   imul eax, -8;
   mov iter, eax;


   mov eax, c;  // point to y (aka the end)
   mov ebx, s;

   mov edi, y2;
   dec edi;
   shl edi, 3;  // y2*sizeof(double)
   add eax, edi;
   add ebx, edi;

   //mov ecx, A;     // A[y + 1][x]
   mov edi, LineWidthA;
   imul edi, y2;
   add ecx, edi;
   sub ecx, iter;

   lea edx, cLocOne;
   {$IFDEF AVXSUP}vmovsd xmm7, [edx];                                 {$ELSE}db $C5,$FB,$10,$3A;{$ENDIF} 

   mov edx, ecx;   // A[y][x]
   sub edx, LineWidthA;

   {$IFDEF AVXSUP}vxorpd xmm6, xmm6, xmm6;                            {$ELSE}db $C5,$C9,$57,$F6;{$ENDIF} // compare reference

   @@foryloop:
        {$IFDEF AVXSUP}vmovddup xmm0, [eax];                          {$ELSE}db $C5,$FB,$12,$00;{$ENDIF} // c[y]
        {$IFDEF AVXSUP}vmovddup xmm1, [ebx];                          {$ELSE}db $C5,$FB,$12,$0B;{$ENDIF} // s[y]

        // ###########################################
        // #### if (ctemp <> 1) or (stemp <> 0) then
        {$IFDEF AVXSUP}vcomisd xmm0, xmm7;                            {$ELSE}db $C5,$F9,$2F,$C7;{$ENDIF} // = 1
        jne @@beginXLoop;

        {$IFDEF AVXSUP}vcomisd xmm1, xmm6;                            {$ELSE}db $C5,$F9,$2F,$CE;{$ENDIF} // = 0
        jne @@beginXLoop;

        jmp @@nextLine; // c=1 and stemp=0 next line -> the statement


        // ###########################################
        // #### for x := 0 to width - 1 do
        @@beginXLoop:

        // init
        mov edi, iter;
        test edi, edi;
        jz @@LastElem;

        @@forxloop:
           //temp := pcAy1^[x];
           //     pcAy1^[x] := cTemp*temp - stemp*pcAy^[x];
           //     pcAy1^[x + 1] := cTemp*temp1 - stemp*pcAy1[x + 1];

           // evaluate 2 values
           {$IFDEF AVXSUP}vmovupd xmm2, [edx + edi];                  {$ELSE}db $C5,$F9,$10,$14,$3A;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd xmm3, [ecx + edi];                  {$ELSE}db $C5,$F9,$10,$1C,$39;{$ENDIF} 

           // temp store...
           {$IFDEF AVXSUP}vmovapd xmm4, xmm2                          {$ELSE}db $C5,$F9,$29,$D4;{$ENDIF} 
           {$IFDEF AVXSUP}vmovapd xmm5, xmm3;                         {$ELSE}db $C5,$F9,$29,$DD;{$ENDIF} 

           {$IFDEF AVXSUP}vmulpd xmm3, xmm3, xmm0;                    {$ELSE}db $C5,$E1,$59,$D8;{$ENDIF} // ctemp*pcay1^[x] and ctemp*a[x+1]
           {$IFDEF AVXSUP}vmulpd xmm2, xmm2, xmm1;                    {$ELSE}db $C5,$E9,$59,$D1;{$ENDIF} // stemp*pcAy^[x] and stemp*a[x+1]

           {$IFDEF AVXSUP}vsubpd xmm3, xmm3, xmm2;                    {$ELSE}db $C5,$E1,$5C,$DA;{$ENDIF} 

           //     pcAy^[x] := stemp*temp + ctemp*pcAy^[x];
           //     pcAy^[x + 1] := stemp*temp1 + ctemp*pcAy^[x + 1]
           {$IFDEF AVXSUP}vmulpd xmm4, xmm4, xmm0;                    {$ELSE}db $C5,$D9,$59,$E0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd xmm5, xmm5, xmm1;                    {$ELSE}db $C5,$D1,$59,$E9;{$ENDIF} 

           {$IFDEF AVXSUP}vaddpd xmm5, xmm5, xmm4;                    {$ELSE}db $C5,$D1,$58,$EC;{$ENDIF} 

           // write back...
           {$IFDEF AVXSUP}vmovupd [edx + edi], xmm5;                  {$ELSE}db $C5,$F9,$11,$2C,$3A;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd [ecx + edi], xmm3;                  {$ELSE}db $C5,$F9,$11,$1C,$39;{$ENDIF} 

           add edi, 16;
        jnz @@forxloop;

        @@LastElem:

        // ###########################################
        // #### Last element handling
        cmp esi, 1;
        jne @@nextLine;

        // same as above but with single elements
        {$IFDEF AVXSUP}vmovsd xmm2, [edx];                            {$ELSE}db $C5,$FB,$10,$12;{$ENDIF} 
        {$IFDEF AVXSUP}vmovsd xmm3, [ecx];                            {$ELSE}db $C5,$FB,$10,$19;{$ENDIF} 

        {$IFDEF AVXSUP}vmovapd xmm4, xmm2;                            {$ELSE}db $C5,$F9,$29,$D4;{$ENDIF} 
        {$IFDEF AVXSUP}vmovapd xmm5, xmm3;                            {$ELSE}db $C5,$F9,$29,$DD;{$ENDIF} 

        {$IFDEF AVXSUP}vmulsd xmm3, xmm3, xmm0;                       {$ELSE}db $C5,$E3,$59,$D8;{$ENDIF} 
        {$IFDEF AVXSUP}vmulsd xmm2, xmm2, xmm1;                       {$ELSE}db $C5,$EB,$59,$D1;{$ENDIF} 

        {$IFDEF AVXSUP}vsubsd xmm3, xmm3, xmm2;                       {$ELSE}db $C5,$E3,$5C,$DA;{$ENDIF} 

        {$IFDEF AVXSUP}vmulsd xmm4, xmm4, xmm0;                       {$ELSE}db $C5,$DB,$59,$E0;{$ENDIF} 
        {$IFDEF AVXSUP}vmulsd xmm5, xmm5, xmm1;                       {$ELSE}db $C5,$D3,$59,$E9;{$ENDIF} 

        {$IFDEF AVXSUP}vaddsd xmm5, xmm5, xmm4;                       {$ELSE}db $C5,$D3,$58,$EC;{$ENDIF} 

        {$IFDEF AVXSUP}vmovsd [edx], xmm5;                            {$ELSE}db $C5,$FB,$11,$2A;{$ENDIF} 
        {$IFDEF AVXSUP}vmovsd [ecx], xmm3;                            {$ELSE}db $C5,$FB,$11,$19;{$ENDIF} 

        // ###########################################
        // #### next y
        @@nextLine:

        sub ebx, 8;   // sizeof(double)
        sub eax, 8;
        sub edx, LineWidthA;
        sub ecx, LineWidthA;
   dec y2;
   jnz @@foryloop;

   // epilog
   @@endproc:

   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
   pop esi;
   pop edi;
   pop ebx;
end;


procedure AVXApplyPlaneRotSeqLVF(width, height : NativeInt; A : PDouble; const LineWidthA : NativeInt; C, S : PConstDoubleArr);
var y2 : NativeInt;
    iter : NativeInt;
asm
   push ebx;
   push edi;
   push esi;

//   if (height < 2) or (width < 1) then
//           exit;

   mov esi, eax;
   and esi, 1;

   cmp eax, 1;
   jl @@endproc;
   cmp edx, 2;
   jl @@endproc;

   //y2 := height - 1;
   //iter := -(width and $FFFFFFFE)*sizeof(double);

   dec edx;
   mov y2, edx;

   and eax, $FFFFFFFE;
   imul eax, -8;
   mov iter, eax;

   mov eax, c;
   mov ebx, s;
   sub ecx, iter;

   lea edx, cLocOne;
   {$IFDEF AVXSUP}vmovsd xmm7, [edx];                                 {$ELSE}db $C5,$FB,$10,$3A;{$ENDIF} 

   mov edx, ecx;   // A[y+1][x]
   add edx, LineWidthA;


   @@foryloop:
        {$IFDEF AVXSUP}vmovddup xmm0, [eax];                          {$ELSE}db $C5,$FB,$12,$00;{$ENDIF} // c[y]
        {$IFDEF AVXSUP}vmovddup xmm1, [ebx];                          {$ELSE}db $C5,$FB,$12,$0B;{$ENDIF} // s[y]

        // ###########################################
        // #### if (ctemp <> 1) or (stemp <> 0) then
        {$IFDEF AVXSUP}vcomisd xmm0, xmm7;                            {$ELSE}db $C5,$F9,$2F,$C7;{$ENDIF} // = 1
        jne @@beginXLoop;

        {$IFDEF AVXSUP}vcomisd xmm1, xmm6;                            {$ELSE}db $C5,$F9,$2F,$CE;{$ENDIF} // = 0
        jne @@beginXLoop;

        jmp @@nextLine; // c=1 and stemp=0 next line -> the statement


        // ###########################################
        // #### for x := 0 to width - 1 do
        @@beginXLoop:

        // init
        mov edi, iter;
        test edi, edi;
        jz @@LastElem;

        @@forxloop:
           //temp := pcAy1^[x];
           //     pcAy1^[x] := cTemp*temp - stemp*pcAy^[x];
           //     pcAy1^[x + 1] := cTemp*temp1 - stemp*pcAy1[x + 1];

           // evaluate 2 values
           {$IFDEF AVXSUP}vmovupd xmm2, [ecx + edi];                  {$ELSE}db $C5,$F9,$10,$14,$39;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd xmm3, [edx + edi];                  {$ELSE}db $C5,$F9,$10,$1C,$3A;{$ENDIF} 

           {$IFDEF AVXSUP}vmulpd xmm5, xmm3, xmm0;                    {$ELSE}db $C5,$E1,$59,$E8;{$ENDIF} // ctemp*pcay1^[x] and ctemp*a[x+1]
           {$IFDEF AVXSUP}vmulpd xmm4, xmm2, xmm1;                    {$ELSE}db $C5,$E9,$59,$E1;{$ENDIF} // stemp*pcAy^[x] and stemp*a[x+1]

           //subpd xmm3, xmm2;
           {$IFDEF AVXSUP}vsubpd xmm5, xmm5, xmm4;                    {$ELSE}db $C5,$D1,$5C,$EC;{$ENDIF} 

           //     pcAy^[x] := stemp*temp + ctemp*pcAy^[x];
           //     pcAy^[x + 1] := stemp*temp1 + ctemp*pcAy^[x + 1]
           {$IFDEF AVXSUP}vmulpd xmm2, xmm2, xmm0;                    {$ELSE}db $C5,$E9,$59,$D0;{$ENDIF} 
           {$IFDEF AVXSUP}vmulpd xmm3, xmm3, xmm1;                    {$ELSE}db $C5,$E1,$59,$D9;{$ENDIF} 

           //addpd xmm5, xmm4;
           {$IFDEF AVXSUP}vaddpd xmm3, xmm3, xmm2;                    {$ELSE}db $C5,$E1,$58,$DA;{$ENDIF} 

           // write back...
           {$IFDEF AVXSUP}vmovupd [ecx + edi], xmm3;                  {$ELSE}db $C5,$F9,$11,$1C,$39;{$ENDIF} 
           {$IFDEF AVXSUP}vmovupd [edx + edi], xmm5;                  {$ELSE}db $C5,$F9,$11,$2C,$3A;{$ENDIF} 

           add edi, 16;
        jnz @@forxloop;

        @@LastElem:

        // ###########################################
        // #### Last element handling
        cmp esi, 1;
        jne @@nextLine;

        // same as above but with single elements
        {$IFDEF AVXSUP}vmovsd xmm4, [ecx];                            {$ELSE}db $C5,$FB,$10,$21;{$ENDIF} 
        {$IFDEF AVXSUP}vmovsd xmm5, [edx];                            {$ELSE}db $C5,$FB,$10,$2A;{$ENDIF} 

        {$IFDEF AVXSUP}vmulsd xmm3, xmm5, xmm0;                       {$ELSE}db $C5,$D3,$59,$D8;{$ENDIF} 
        {$IFDEF AVXSUP}vmulsd xmm2, xmm4, xmm1;                       {$ELSE}db $C5,$DB,$59,$D1;{$ENDIF} 

        {$IFDEF AVXSUP}vsubsd xmm3, xmm3, xmm2;                       {$ELSE}db $C5,$E3,$5C,$DA;{$ENDIF} 

        {$IFDEF AVXSUP}vmulsd xmm4, xmm4, xmm0;                       {$ELSE}db $C5,$DB,$59,$E0;{$ENDIF} 
        {$IFDEF AVXSUP}vmulsd xmm5, xmm5, xmm1;                       {$ELSE}db $C5,$D3,$59,$E9;{$ENDIF} 

        {$IFDEF AVXSUP}vaddsd xmm5, xmm5, xmm4;                       {$ELSE}db $C5,$D3,$58,$EC;{$ENDIF} 

        {$IFDEF AVXSUP}vmovsd [ecx], xmm5;                            {$ELSE}db $C5,$FB,$11,$29;{$ENDIF} 
        {$IFDEF AVXSUP}vmovsd [edx], xmm3;                            {$ELSE}db $C5,$FB,$11,$1A;{$ENDIF} 

        // ###########################################
        // #### next y
        @@nextLine:

        add ebx, 8;   // sizeof(double)
        add eax, 8;
        add ecx, LineWidthA;
        add edx, LineWidthA;
   dec y2;
   jnz @@foryloop;

   @@endproc:

   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 

   pop esi;
   pop edi;
   pop ebx;
end;

procedure AVXApplyPlaneRotSeqRVB(width, height : NativeInt; A : PDouble; const LineWidthA : NativeInt; C, S : PConstDoubleArr);
// eax = width, edx = height, ecx = A
asm
   // if (height <= 0) or (width <= 1) then exit;
   cmp eax, 1;
   jle @@endProc;
   cmp edx, 0;
   jle @@endProc;

   push ebx;
   push edi;
   push esi;

   // w2 := width - 1;
   // iter := w2*sizeof(double);
   dec eax;
   imul eax, 8;

   mov esi, c;
   mov ebx, s;

   lea edi, cLocMulM1Bits;
   {$IFDEF AVXSUP}vmovupd xmm7, [edi];                                {$ELSE}db $C5,$F9,$10,$3F;{$ENDIF} 

   @@foryloop:

      mov edi, eax; //iter;
      {$IFDEF AVXSUP}vmovhpd xmm2, xmm2, [ecx + edi];                 {$ELSE}db $C5,$E9,$16,$14,$39;{$ENDIF} 

      // for x := width - 2 downto 0
      @@forxloop:
         {$IFDEF AVXSUP}vmovsd xmm4, [esi + edi - 8];                 {$ELSE}db $C5,$FB,$10,$64,$3E,$F8;{$ENDIF} // store c
         {$IFDEF AVXSUP}vmovsd xmm3, [ebx + edi - 8];                 {$ELSE}db $C5,$FB,$10,$5C,$3B,$F8;{$ENDIF} // store s

         {$IFDEF AVXSUP}vmovlpd xmm2, xmm2, [ecx + edi - 8];          {$ELSE}db $C5,$E9,$12,$54,$39,$F8;{$ENDIF} // a[x], a[x+1]

         // handle x, x+1
         // ####################################
         // #### x, x+ 1
         {$IFDEF AVXSUP}vmovlhps xmm3, xmm3, xmm4;                    {$ELSE}db $C5,$E0,$16,$DC;{$ENDIF} 
         {$IFDEF AVXSUP}vmovlhps xmm4, xmm4, xmm3;                    {$ELSE}db $C5,$D8,$16,$E3;{$ENDIF} 

         {$IFDEF AVXSUP}vxorpd xmm3, xmm3, xmm7;                      {$ELSE}db $C5,$E1,$57,$DF;{$ENDIF} // -s, c
         {$IFDEF AVXSUP}vmulpd xmm3, xmm3, xmm2;                      {$ELSE}db $C5,$E1,$59,$DA;{$ENDIF} // a[x+1)*c[x] - s[x]*a[x]
         {$IFDEF AVXSUP}vhaddpd xmm3, xmm3, xmm3;                     {$ELSE}db $C5,$E1,$7C,$DB;{$ENDIF} 

         {$IFDEF AVXSUP}vmulpd xmm4, xmm4, xmm2;                      {$ELSE}db $C5,$D9,$59,$E2;{$ENDIF} // a[x+1]*s[x] + a[x]*c[x]
         {$IFDEF AVXSUP}vhaddpd xmm4, xmm4, xmm4;                     {$ELSE}db $C5,$D9,$7C,$E4;{$ENDIF} 

         // write back first two values
         {$IFDEF AVXSUP}vmovlhps xmm2, xmm2, xmm4;                    {$ELSE}db $C5,$E8,$16,$D4;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd [ecx + edi], xmm3;                     {$ELSE}db $C5,$FB,$11,$1C,$39;{$ENDIF} 

      // next one
      sub edi, 8;
      jnz @@forxloop;

      {$IFDEF AVXSUP}vmovsd [ecx + edi], xmm4;                        {$ELSE}db $C5,$FB,$11,$24,$39;{$ENDIF} 

      add ecx, LineWidthA;

   dec edx;
   jnz @@foryloop;

   // epilog
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
   pop esi;
   pop edi;
   pop ebx;

   @@endProc:
end;

procedure AVXApplyPlaneRotSeqRVF(width, height : NativeInt; A : PDouble; const LineWidthA : NativeInt; C, S : PConstDoubleArr);
// eax = width, edx = height, ecx = A
asm
   // if (height <= 0) or (width <= 1) then exit;
   cmp eax, 1;
   jle @@endProc;
   cmp edx, 0;
   jle @@endProc;

   push ebx;
   push edi;
   push esi;

   // iter
   dec eax;
   imul eax, -8;

   mov esi, c;
   mov ebx, s;

   sub esi, eax;
   sub ebx, eax;
   sub ecx, eax;

   lea edi, cLocMulM1Bits;
   {$IFDEF AVXSUP}vmovupd xmm7, [edi];                                {$ELSE}db $C5,$F9,$10,$3F;{$ENDIF} 

   @@foryloop:

      mov edi, eax;
      movsd xmm2, [ecx + edi];

      @@forxloop:
         {$IFDEF AVXSUP}vmovsd xmm4, [esi + edi];                     {$ELSE}db $C5,$FB,$10,$24,$3E;{$ENDIF} // store c
         {$IFDEF AVXSUP}vmovhpd xmm4, xmm4, [ebx + edi];              {$ELSE}db $C5,$D9,$16,$24,$3B;{$ENDIF} // store s

         {$IFDEF AVXSUP}vshufpd xmm3, xmm4, xmm4, 1;                  {$ELSE}db $C5,$D9,$C6,$DC,$01;{$ENDIF} 
         {$IFDEF AVXSUP}vmovhpd xmm2, xmm2, [ecx + edi + 8];          {$ELSE}db $C5,$E9,$16,$54,$39,$08;{$ENDIF} // a[x], a[x+1]

         // handle x, x+1
         // ####################################
         // #### x, x+ 1

         {$IFDEF AVXSUP}vxorpd xmm3, xmm3, xmm7;                      {$ELSE}db $C5,$E1,$57,$DF;{$ENDIF} // -s, c
         {$IFDEF AVXSUP}vmulpd xmm3, xmm3, xmm2;                      {$ELSE}db $C5,$E1,$59,$DA;{$ENDIF} // a[x+1)*c[x] - s[x]*a[x]
         {$IFDEF AVXSUP}vhaddpd xmm3, xmm3, xmm3;                     {$ELSE}db $C5,$E1,$7C,$DB;{$ENDIF} 

         {$IFDEF AVXSUP}vmulpd xmm4, xmm4, xmm2;                      {$ELSE}db $C5,$D9,$59,$E2;{$ENDIF} // a[x+1]*s[x] + a[x]*c[x]
         {$IFDEF AVXSUP}vhaddpd xmm4, xmm4, xmm4;                     {$ELSE}db $C5,$D9,$7C,$E4;{$ENDIF} 

         // write back first two values
         {$IFDEF AVXSUP}vmovsd xmm2, xmm2, xmm3;                      {$ELSE}db $C5,$EB,$11,$DA;{$ENDIF} 
         {$IFDEF AVXSUP}vmovsd [ecx + edi], xmm4;                     {$ELSE}db $C5,$FB,$11,$24,$39;{$ENDIF} 

      // next one
      add edi, 8;
      jnz @@forxloop;

      {$IFDEF AVXSUP}vmovsd [ecx + edi], xmm2;                        {$ELSE}db $C5,$FB,$11,$14,$39;{$ENDIF} 

      add ecx, LineWidthA;

   dec edx;
   jnz @@foryloop;

   // epilog
   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
   pop esi;
   pop edi;
   pop ebx;

   @@endProc:
end;

// its assumed that Linewidthdx and linewidthdy = sizeof(double)
procedure AVXMatrixRotateAligned(N : NativeInt; X : PDouble;
  Y : PDouble; c, s : double); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
// eax = N; edx = X; ecx = Y
asm
   push ebx;
   push esi;
   push edi;

   lea esi, s;
   {$IFDEF AVXSUP}vmovsd xmm2, [esi];                                 {$ELSE}db $C5,$FB,$10,$16;{$ENDIF} 
   lea edi, cLocMinusOne;
   {$IFDEF AVXSUP}vmulsd xmm2, xmm2, [edi];                           {$ELSE}db $C5,$EB,$59,$17;{$ENDIF} 

   {$IFDEF AVXSUP}vmovddup xmm0, xmm2;                                {$ELSE}db $C5,$FB,$12,$C2;{$ENDIF} 
   lea edi, c;
   {$IFDEF AVXSUP}vmovddup xmm1, [edi];                               {$ELSE}db $C5,$FB,$12,$0F;{$ENDIF} 
   {$IFDEF AVXSUP}vmovddup xmm2, [esi];                               {$ELSE}db $C5,$FB,$12,$16;{$ENDIF} 

   mov edi, eax;
   //mov edx, X;
   //mov ecx, Y;

   xor esi, esi;

   shr eax, 1;
   test eax, eax;
   jz @@exitLoop;

   @@forNloop:
         // do a full load -> intermediate store in xmm5, and xmm6
         {$IFDEF AVXSUP}vmovupd xmm5, [edx + esi];                    {$ELSE}db $C5,$F9,$10,$2C,$32;{$ENDIF} // x, x+1
         {$IFDEF AVXSUP}vmovupd xmm6, [ecx + esi];                    {$ELSE}db $C5,$F9,$10,$34,$31;{$ENDIF} // y, y+1

         {$IFDEF AVXSUP}vmulpd xmm3, xmm5, xmm0;                      {$ELSE}db $C5,$D1,$59,$D8;{$ENDIF} // x, x+1 * -s
         {$IFDEF AVXSUP}vmulpd xmm5, xmm5, xmm1;                      {$ELSE}db $C5,$D1,$59,$E9;{$ENDIF} // x, x+1 * c
         {$IFDEF AVXSUP}vmulpd xmm4, xmm6, xmm1;                      {$ELSE}db $C5,$C9,$59,$E1;{$ENDIF} // y, y+1 * c
         {$IFDEF AVXSUP}vmulpd xmm6, xmm6, xmm2;                      {$ELSE}db $C5,$C9,$59,$F2;{$ENDIF} // y, y+1 * s

         {$IFDEF AVXSUP}vaddpd xmm5, xmm5, xmm6;                      {$ELSE}db $C5,$D1,$58,$EE;{$ENDIF} // c*x + s*y  , c*(x+1) + s*(y+1)
         {$IFDEF AVXSUP}vaddpd xmm3, xmm3, xmm4;                      {$ELSE}db $C5,$E1,$58,$DC;{$ENDIF} // -s*x + c*y, -s(x+1) + c*(y+1)

         // write back
         {$IFDEF AVXSUP}vmovupd [edx + esi], xmm5;                    {$ELSE}db $C5,$F9,$11,$2C,$32;{$ENDIF} 
         {$IFDEF AVXSUP}vmovupd [ecx + esi], xmm3;                    {$ELSE}db $C5,$F9,$11,$1C,$31;{$ENDIF} 

         add esi, 16;

   dec eax;
   jnz @@forNloop;

   @@exitLoop:

   // test for an odd N
   test edi, 1;
   jz @@endProc;

   // handle last element
   {$IFDEF AVXSUP}vmovsd xmm5, [edx + esi];                           {$ELSE}db $C5,$FB,$10,$2C,$32;{$ENDIF} 
   {$IFDEF AVXSUP}vmovsd xmm6, [ecx + esi];                           {$ELSE}db $C5,$FB,$10,$34,$31;{$ENDIF} 

   //dtemp := c*pX^[i] + s*pY^[i];
   //pY^[i] := - s*pX^[i] + c*pY^[i];
   //px^[i] := dtemp;

   {$IFDEF AVXSUP}vmulsd xmm3, xmm5, xmm0;                            {$ELSE}db $C5,$D3,$59,$D8;{$ENDIF} // x * -s
   {$IFDEF AVXSUP}vmulsd xmm4, xmm6, xmm1;                            {$ELSE}db $C5,$CB,$59,$E1;{$ENDIF} // y * c
   {$IFDEF AVXSUP}vmulsd xmm5, xmm5, xmm1;                            {$ELSE}db $C5,$D3,$59,$E9;{$ENDIF} // x * c
   {$IFDEF AVXSUP}vmulsd xmm6, xmm6, xmm2;                            {$ELSE}db $C5,$CB,$59,$F2;{$ENDIF} // y * s

   {$IFDEF AVXSUP}vaddsd xmm5, xmm5, xmm6;                            {$ELSE}db $C5,$D3,$58,$EE;{$ENDIF} // c*x + s*y
   {$IFDEF AVXSUP}vaddsd xmm3, xmm3, xmm4;                            {$ELSE}db $C5,$E3,$58,$DC;{$ENDIF} // -s*x + c*y

   // write back
   {$IFDEF AVXSUP}vmovsd [edx + esi], xmm5;                           {$ELSE}db $C5,$FB,$11,$2C,$32;{$ENDIF} 
   {$IFDEF AVXSUP}vmovsd [ecx + esi], xmm3;                           {$ELSE}db $C5,$FB,$11,$1C,$31;{$ENDIF} 

   @@endProc:

   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
   pop edi;
   pop esi;
   pop ebx;
end;


procedure AVXMatrixRotateUnaligned(N : NativeInt; X : PDouble; const LineWidthDX : NativeInt;
  Y : PDouble; LineWidthDY : NativeInt; c, s : double); {$IFDEF FPC} assembler; {$ELSE} register; {$ENDIF}
// eax = N, edx = X, ecx = LineWidthDX
asm
   push ebx;
   push edi;
   push esi;

   lea esi, s;
   {$IFDEF AVXSUP}vmovsd xmm2, [esi];                                 {$ELSE}db $C5,$FB,$10,$16;{$ENDIF} 
   lea edi, cLocMinusOne;
   {$IFDEF AVXSUP}vmulsd xmm2, xmm2, [edi];                           {$ELSE}db $C5,$EB,$59,$17;{$ENDIF} 

   {$IFDEF AVXSUP}vmovddup xmm0, xmm2;                                {$ELSE}db $C5,$FB,$12,$C2;{$ENDIF} 
   lea edi, c;
   {$IFDEF AVXSUP}vmovddup xmm1, [edi];                               {$ELSE}db $C5,$FB,$12,$0F;{$ENDIF} 

   {$IFDEF AVXSUP}vmovddup xmm2, [esi];                               {$ELSE}db $C5,$FB,$12,$16;{$ENDIF} 

   mov edx, X;
   mov ebx, Y;

   mov edi, LineWidthDY;

   sub eax, 2;
   jl @@exitLoop;

   @@forNloop:
      // do a full load -> intermediate store in xmm5, and xmm6
      {$IFDEF AVXSUP}vmovlpd xmm5, xmm5, [edx];                       {$ELSE}db $C5,$D1,$12,$2A;{$ENDIF} // load x, x+1
      {$IFDEF AVXSUP}vmovhpd xmm5, xmm5, [edx + ecx];                 {$ELSE}db $C5,$D1,$16,$2C,$0A;{$ENDIF} 
      {$IFDEF AVXSUP}vmovlpd xmm6, xmm6, [ebx];                       {$ELSE}db $C5,$C9,$12,$33;{$ENDIF} // load y, y+1
      {$IFDEF AVXSUP}vmovhpd xmm6, xmm6, [ebx + edi];                 {$ELSE}db $C5,$C9,$16,$34,$3B;{$ENDIF} 

      {$IFDEF AVXSUP}vmulpd xmm3, xmm5, xmm0;                         {$ELSE}db $C5,$D1,$59,$D8;{$ENDIF} // x, x+1 * -s
      {$IFDEF AVXSUP}vmulpd xmm5, xmm5, xmm1;                         {$ELSE}db $C5,$D1,$59,$E9;{$ENDIF} // x, x+1 * c
      {$IFDEF AVXSUP}vmulpd xmm4, xmm6, xmm1;                         {$ELSE}db $C5,$C9,$59,$E1;{$ENDIF} // y, y+1 * c
      {$IFDEF AVXSUP}vmulpd xmm6, xmm6, xmm2;                         {$ELSE}db $C5,$C9,$59,$F2;{$ENDIF} // y, y+1 * s

      {$IFDEF AVXSUP}vaddpd xmm5, xmm5, xmm6;                         {$ELSE}db $C5,$D1,$58,$EE;{$ENDIF} // c*x + s*y  , c*(x+1) + s*(y+1)
      {$IFDEF AVXSUP}vaddpd xmm3, xmm3, xmm4;                         {$ELSE}db $C5,$E1,$58,$DC;{$ENDIF} // -s*x + c*y, -s(x+1) + c*(y+1)

      // write back
      {$IFDEF AVXSUP}vmovlpd [edx], xmm5;                             {$ELSE}db $C5,$F9,$13,$2A;{$ENDIF} 
      {$IFDEF AVXSUP}vmovhpd [edx + ecx], xmm5;                       {$ELSE}db $C5,$F9,$17,$2C,$0A;{$ENDIF} 

      {$IFDEF AVXSUP}vmovlpd [ebx], xmm3;                             {$ELSE}db $C5,$F9,$13,$1B;{$ENDIF} 
      {$IFDEF AVXSUP}vmovhpd [ebx + edi], xmm3;                       {$ELSE}db $C5,$F9,$17,$1C,$3B;{$ENDIF} 

      add edx, ecx;
      add edx, ecx;
      add ebx, edi;
      add ebx, edi;

   sub eax, 2;
   jge @@forNloop;

   @@exitLoop:

   // test for an odd N
   add eax, 2;
   jz @@endProc;

   // handle last element
   {$IFDEF AVXSUP}vmovsd xmm5, [edx];                                 {$ELSE}db $C5,$FB,$10,$2A;{$ENDIF} 
   {$IFDEF AVXSUP}vmovsd xmm6, [ebx];                                 {$ELSE}db $C5,$FB,$10,$33;{$ENDIF} 

   //dtemp := c*pX^[i] + s*pY^[i];
   //pY^[i] := - s*pX^[i] + c*pY^[i];
   //px^[i] := dtemp;
   {$IFDEF AVXSUP}vmulsd xmm3, xmm5, xmm0;                            {$ELSE}db $C5,$D3,$59,$D8;{$ENDIF} // x * -s
   {$IFDEF AVXSUP}vmulsd xmm5, xmm5, xmm1;                            {$ELSE}db $C5,$D3,$59,$E9;{$ENDIF} // x * c
   {$IFDEF AVXSUP}vmulsd xmm4, xmm6, xmm1;                            {$ELSE}db $C5,$CB,$59,$E1;{$ENDIF} // y * c
   {$IFDEF AVXSUP}vmulsd xmm6, xmm6, xmm2;                            {$ELSE}db $C5,$CB,$59,$F2;{$ENDIF} // y * s

   {$IFDEF AVXSUP}vaddsd xmm5, xmm5, xmm6;                            {$ELSE}db $C5,$D3,$58,$EE;{$ENDIF} // c*x + s*y
   {$IFDEF AVXSUP}vaddsd xmm3, xmm3, xmm4;                            {$ELSE}db $C5,$E3,$58,$DC;{$ENDIF} // -s*x + c*y

   // write back
   {$IFDEF AVXSUP}vmovsd [edx], xmm5;                                 {$ELSE}db $C5,$FB,$11,$2A;{$ENDIF} 
   {$IFDEF AVXSUP}vmovsd [ebx], xmm3;                                 {$ELSE}db $C5,$FB,$11,$1B;{$ENDIF} 

   @@endProc:

   {$IFDEF AVXSUP}vzeroupper;                                         {$ELSE}db $C5,$F8,$77;{$ENDIF} 
   pop esi;
   pop edi;
   pop ebx;
end;

procedure AVXMatrixRotate(N : NativeInt; X : PDouble; const LineWidthDX : NativeInt; Y : PDouble; LineWidthDY : NativeInt; const c, s : double);
begin
     if N <= 0 then
        exit;

     if (LineWidthDX = sizeof(double)) and (LineWidthDY = sizeof(double))
     then
         AVXMatrixRotateAligned(N, X, Y, c, s)
     else
         AVXMatrixRotateUnAligned(N, X, LineWidthDX, Y, LineWidthDY, c, s)
end;



{$ENDIF}

end.
