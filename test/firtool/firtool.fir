; RUN: firtool %s --format=fir -mlir    | circt-opt | FileCheck %s --check-prefix=MLIR
; RUN: firtool %s --format=fir -verilog |           FileCheck %s --check-prefix=VERILOG
; RUN: firtool %s --format=fir -mlir -lower-to-rtl | circt-opt | FileCheck %s --check-prefix=MLIRLOWER

circuit fir_test :
  module test_mod :
    input a: UInt<1>
    output b: UInt<1>
    b <= a

; MLIR: firrtl.circuit "fir_test" {

; MLIR-LABEL: firrtl.module @test_mod(%a: !firrtl.uint<1>, %b: !firrtl.flip<uint<1>>) {
; MLIR-NEXT:    firrtl.connect %b, %a : !firrtl.flip<uint<1>>, !firrtl.uint<1>
; MLIR-NEXT:  }

; VERILOG-LABEL: module test_mod(
; VERILOG-NEXT :   input  a,
; VERILOG-NEXT :   output b);
; VERILOG-NEXT :   assign b = a;
; VERILOG-NEXT : endmodule

; MLIRLOWER: firrtl.circuit "fir_test" {
; MLIRLOWER:   firrtl.module @test_mod(%a: !firrtl.uint<1>, %b: !firrtl.flip<uint<1>>) {
; MLIRLOWER:     %0 = firrtl.stdIntCast %b : (!firrtl.flip<uint<1>>) -> i1
; MLIRLOWER:     %1 = firrtl.stdIntCast %a : (!firrtl.uint<1>) -> i1
; MLIRLOWER:     rtl.connect %0, %1 : i1
; MLIRLOWER:   }
; MLIRLOWER: }
