//===- LLHDCanonicalization.td - LLHD canonicalization -----*- tablegen -*-===//
//
// This file defines LLHD canonicalization patterns.
//
//===----------------------------------------------------------------------===//

#ifndef CIRCT_DIALECT_LLHD_IR_CANONICALIZATION_TD
#define CIRCT_DIALECT_LLHD_IR_CANONICALIZATION_TD

include "circt/Dialect/LLHD/IR/LLHD.td"
include "mlir/Dialect/StandardOps/IR/Ops.td"

def IndexAttrFromSignlessInteger : NativeCodeCall<
  "$_builder.getIndexAttr($0.cast<IntegerAttr>().getValue().getZExtValue())">;

//===----------------------------------------------------------------------===//
// XorOp
//===----------------------------------------------------------------------===//

def XorAllBitsSet : Pat<
  (LLHD_XorOp $lhs, (LLHD_ConstOp AttrConstraint<
    CPred<"$_self.isa<IntegerAttr>() && "
      "$_self.cast<IntegerAttr>().getValue().isAllOnesValue()">,
    "signless integer -1">)),
  (LLHD_NotOp $lhs)>;

//===----------------------------------------------------------------------===//
// NotOp
//===----------------------------------------------------------------------===//

def NotOfEq : Pat<
  (LLHD_NotOp (LLHD_EqOp $lhs, $rhs)),
  (LLHD_NeqOp $lhs, $rhs)>;

def NotOfNeq : Pat<
  (LLHD_NotOp (LLHD_NeqOp $lhs, $rhs)),
  (LLHD_EqOp $lhs, $rhs)>;

//===----------------------------------------------------------------------===//
// EqOp
//===----------------------------------------------------------------------===//

def BooleanEqToXor : Pat<
  (LLHD_EqOp I1:$lhs, I1:$rhs),
  (LLHD_NotOp (LLHD_XorOp $lhs, $rhs))>;

//===----------------------------------------------------------------------===//
// NeqOp
//===----------------------------------------------------------------------===//

def BooleanNeqToXor : Pat<
  (LLHD_NeqOp I1:$lhs, I1:$rhs),
  (LLHD_XorOp $lhs, $rhs)>;

//===----------------------------------------------------------------------===//
// DynExtractSliceOp
//===----------------------------------------------------------------------===//

def DynExtractSliceWithLLHDConstOpStart : Pat<
  (LLHD_DynExtractSliceOp $target, (LLHD_ConstOp $start)),
  (LLHD_ExtractSliceOp $target, (IndexAttrFromSignlessInteger $start))>;

def DynExtractSliceWithConstantOpStart : Pat<
  (LLHD_DynExtractSliceOp $target, (ConstantOp $start)),
  (LLHD_ExtractSliceOp $target, (IndexAttrFromSignlessInteger $start))>;

//===----------------------------------------------------------------------===//
// DynExtractElementOp
//===----------------------------------------------------------------------===//

def DynExtractElementWithLLHDConstOpIndex : Pat<
  (LLHD_DynExtractElementOp $target, (LLHD_ConstOp $index)),
  (LLHD_ExtractElementOp $target, (IndexAttrFromSignlessInteger $index))>;

def DynExtractElementWithConstantOpIndex : Pat<
  (LLHD_DynExtractElementOp $target, (ConstantOp $index)),
  (LLHD_ExtractElementOp $target, (IndexAttrFromSignlessInteger $index))>;

#endif // CIRCT_DIALECT_LLHD_IR_CANONICALIZATION_TD
