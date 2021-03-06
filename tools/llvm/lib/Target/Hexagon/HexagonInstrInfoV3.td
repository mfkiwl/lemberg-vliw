//=- HexagonInstrInfoV3.td - Target Desc. for Hexagon Target -*- tablegen -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the Hexagon V3 instructions in TableGen format.
//
//===----------------------------------------------------------------------===//


//===----------------------------------------------------------------------===//
// J +
//===----------------------------------------------------------------------===//
// Call subroutine.
let isCall = 1, neverHasSideEffects = 1,
  Defs = [D0, D1, D2, D3, D4, D5, D6, D7, R28, R31,
                P0, P1, P2, P3, LC0, LC1, SA0, SA1] in {
  def CALLv3 : JInst<(outs), (ins calltarget:$dst, variable_ops),
             "call $dst", []>, Requires<[HasV3T]>;
}

//===----------------------------------------------------------------------===//
// J -
//===----------------------------------------------------------------------===//


//===----------------------------------------------------------------------===//
// JR +
//===----------------------------------------------------------------------===//
// Call subroutine from register.
let isCall = 1, neverHasSideEffects = 1,
  Defs = [D0, D1, D2, D3, D4, D5, D6, D7, R28, R31,
                P0, P1, P2, P3, LC0, LC1, SA0, SA1] in {
  def CALLRv3 : JRInst<(outs), (ins IntRegs:$dst, variable_ops),
              "callr $dst",
              []>, Requires<[HasV3TOnly]>;
 }


// if(p?.new) jumpr:t r?
let isReturn = 1, isTerminator = 1, isBarrier = 1,
  Defs = [PC], Uses = [R31] in {
  def JMPR_cPnewt: JRInst<(outs), (ins PredRegs:$src1, IntRegs:$src2),
                       "if ($src1.new) jumpr:t $src2",
                       []>, Requires<[HasV3T]>;
}

// if (!p?.new) jumpr:t r?
let isReturn = 1, isTerminator = 1, isBarrier = 1,
  Defs = [PC], Uses = [R31] in {
  def JMPR_cNotPnewt: JRInst<(outs), (ins PredRegs:$src1, IntRegs:$src2),
                       "if (!$src1.new) jumpr:t $src2",
                       []>, Requires<[HasV3T]>;
}

// Not taken.
// if(p?.new) jumpr:nt r?
let isReturn = 1, isTerminator = 1, isBarrier = 1,
  Defs = [PC], Uses = [R31] in {
  def JMPR_cPnewNt: JRInst<(outs), (ins PredRegs:$src1, IntRegs:$src2),
                       "if ($src1.new) jumpr:nt $src2",
                       []>, Requires<[HasV3T]>;
}

// if (!p?.new) jumpr:nt r?
let isReturn = 1, isTerminator = 1, isBarrier = 1,
  Defs = [PC], Uses = [R31] in {
  def JMPR_cNotPnewNt: JRInst<(outs), (ins PredRegs:$src1, IntRegs:$src2),
                       "if (!$src1.new) jumpr:nt $src2",
                       []>, Requires<[HasV3T]>;
}

//===----------------------------------------------------------------------===//
// JR -
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// ALU64/ALU +
//===----------------------------------------------------------------------===//

let AddedComplexity = 200 in
def MAXw_dd : ALU64_rr<(outs DoubleRegs:$dst), (ins DoubleRegs:$src1,
                                                    DoubleRegs:$src2),
              "$dst = max($src2, $src1)",
              [(set DoubleRegs:$dst, (select (i1 (setlt DoubleRegs:$src2,
                                                        DoubleRegs:$src1)),
                                             DoubleRegs:$src1,
                                             DoubleRegs:$src2))]>,
Requires<[HasV3T]>;

let AddedComplexity = 200 in
def MINw_dd : ALU64_rr<(outs DoubleRegs:$dst), (ins DoubleRegs:$src1,
                                                    DoubleRegs:$src2),
              "$dst = min($src2, $src1)",
              [(set DoubleRegs:$dst, (select (i1 (setgt DoubleRegs:$src2,
                                                        DoubleRegs:$src1)),
                                             DoubleRegs:$src1,
                                             DoubleRegs:$src2))]>,
Requires<[HasV3T]>;

//===----------------------------------------------------------------------===//
// ALU64/ALU -
//===----------------------------------------------------------------------===//




//def : Pat <(brcond (i1 (seteq IntRegs:$src1, 0)), bb:$offset),
//      (JMP_RegEzt IntRegs:$src1, bb:$offset)>, Requires<[HasV3T]>;

//def : Pat <(brcond (i1 (setne IntRegs:$src1, 0)), bb:$offset),
//      (JMP_RegNzt IntRegs:$src1, bb:$offset)>, Requires<[HasV3T]>;

//def : Pat <(brcond (i1 (setle IntRegs:$src1, 0)), bb:$offset),
//      (JMP_RegLezt IntRegs:$src1, bb:$offset)>, Requires<[HasV3T]>;

//def : Pat <(brcond (i1 (setge IntRegs:$src1, 0)), bb:$offset),
//      (JMP_RegGezt IntRegs:$src1, bb:$offset)>, Requires<[HasV3T]>;

//def : Pat <(brcond (i1 (setgt IntRegs:$src1, -1)), bb:$offset),
//      (JMP_RegGezt IntRegs:$src1, bb:$offset)>, Requires<[HasV3T]>;


// Map call instruction
def : Pat<(call IntRegs:$dst),
      (CALLRv3 IntRegs:$dst)>, Requires<[HasV3T]>;
def : Pat<(call tglobaladdr:$dst),
      (CALLv3 tglobaladdr:$dst)>, Requires<[HasV3T]>;
def : Pat<(call texternalsym:$dst),
      (CALLv3 texternalsym:$dst)>, Requires<[HasV3T]>;
