; RUN: circt-translate -parse-fir --mlir-print-debuginfo %s | circt-translate -emit-verilog -verify-diagnostics | FileCheck %s --strict-whitespace

; Some day this should filecheck:
; RUN: circt-translate -parse-fir --mlir-print-debuginfo %s | circt-opt -pass-pipeline='firrtl.circuit(lower-firrtl-to-rtl)' | circt-translate -emit-verilog -verify-diagnostics

circuit Xorr :

  module inputs_only :
    input a: UInt<1>
    input b: UInt<1>

; CHECK-LABEL: module inputs_only(
; CHECK-NEXT:    input a, b);
; CHECK-EMPTY:
; CHECK-NEXT:  endmodule


  module no_ports :
    wire x : UInt<4>
    skip

; CHECK-LABEL: module no_ports();
; CHECK-NEXT:    wire [3:0] x;
; CHECK-EMPTY:
; CHECK-NEXT:  endmodule

  module Expressions :
    input in4: UInt<4>
    input clock: Clock
    output out1: UInt<1>
    output out4: UInt<4>
    out1 <= xorr(in4)
    out1 <= andr(in4)
    out1 <= orr(in4)
    out1 <= not(in4)
    out4 <= rem(in4, UInt<4>("h1"))
    out1 <= asUInt(clock)
    out1 <= asUInt(asClock(UInt<1>("h1")))
    node x1 = bits(in4, 1, 0)
    node x2 = or(shr(in4, 2), shl(bits(in4, 2, 2), 1))
    node x3 = dshr(in4, in4)
    node x4 = dshr(asSInt(in4), in4)
    node x5 = cat(cat(in4, asUInt(clock)), cat(asUInt(clock), in4))
    node x6 = cvt(asUInt(cat(in4, in4)))
    node x7 = mux(asUInt(clock),
                  mux(asUInt(clock), UInt<4>("h1"), UInt<4>("h2")),
                  UInt<4>("h3"))
    node x8 = mux(asUInt(clock),
                  UInt<4>("h1"),
                  mux(asUInt(clock), UInt<4>("h2"), UInt<4>("h3")))
    node x9 = or(head(in4, 2), tail(in4, 2))
    node x10 = validif(asUInt(clock), in4)
    node x11 = xor(xor(pad(in4, 6), asUInt(pad(asSInt(in4), 6))),
                   asUInt(pad(asSInt(clock), 6)))
    node x12 = shl(in4, 0)

; CHECK-LABEL: module Expressions(
; CHECK-NEXT:     input  [3:0] in4,
; CHECK-NEXT:     input        clock,
; CHECK-NEXT:     output       out1,
; CHECK-NEXT:     output [3:0] out4);
; CHECK-EMPTY:
; CHECK-NEXT:     wire [1:0] x1;
; CHECK-NEXT:     wire [1:0] x2;
; CHECK-NEXT:     wire [3:0] x3;
; CHECK-NEXT:     wire [3:0] x4;
; CHECK-NEXT:     wire [9:0] x5;
; CHECK-NEXT:     wire [8:0] x6;
; CHECK-NEXT:     wire [3:0] x7;
; CHECK-NEXT:     wire [3:0] x8;
; CHECK-NEXT:     wire [1:0] x9;
; CHECK-NEXT:     wire [3:0] x10;
; CHECK-NEXT:     wire [5:0] x11;
; CHECK-NEXT:     wire [3:0] x12;
; CHECK-EMPTY:
; CHECK-NEXT:     assign out1 = ^in4;
; CHECK-NEXT:     assign out1 = &in4;
; CHECK-NEXT:     assign out1 = |in4;
; CHECK-NEXT:     assign out1 = ~in4;
; CHECK-NEXT:     assign out4 = in4 % 4'h1;
; CHECK-NEXT:     assign out1 = clock;
; CHECK-NEXT:     assign out1 = 1'h1;
; CHECK-NEXT:     assign x1 = in4[1:0];
; CHECK-NEXT:     assign x2 = in4[3:2] | {in4[2], 1'h0};
; CHECK-NEXT:     assign x3 = in4 >>> in4;
; CHECK-NEXT:     assign x4 = $signed(in4) >>> in4;
; CHECK-NEXT:     assign x5 = {in4, clock, clock, in4};
; CHECK-NEXT:     assign x6 = {1'b0, in4, in4};
; CHECK-NEXT:     assign x7 = clock ? (clock ? 4'h1 : 4'h2) : 4'h3;
; CHECK-NEXT:     assign x8 = clock ? 4'h1 : clock ? 4'h2 : 4'h3;
; CHECK-NEXT:     assign x9 = in4[3:2] | in4[1:0];
; CHECK-NEXT:     assign x10 = in4;
; CHECK-NEXT:     assign x11 = {{\{\{}}2'd0}, in4} ^ {{\{\{}}2{in4[3]}}, in4} ^ {6{clock}};
; CHECK-NEXT:     assign x12 = in4;
; CHECK-NEXT:  endmodule


  module Precedence :
    input a: UInt<4>
    input b: UInt<4>
    input c: UInt<4>
    output out1: UInt<1>
    output out: UInt<4>
    out <= add(a, add(b, c))
    out <= sub(add(a, b), c)
    out <= sub(a, add(b, c))
    out <= add(a, mul(b, c))
    out <= add(mul(a, b), c)
    out <= mul(add(a, b), c)
    out <= mul(a, add(b, c))
    out <= mul(add(a, b), add(b, c))
    out1 <= xorr(add(b, c))
    out1 <= or(lt(b, c), gt(b, c))
    out1 <= and(xor(b, c), or(out1, out1))
    out1 <= shr(out, 2)
    out1 <= lt(out, a)

; CHECK-LABEL: module Precedence(
; CHECK-NEXT:     input  [3:0] a, b, c,
; CHECK-NEXT:     output       out1,
; CHECK-NEXT:     output [3:0] out);
; CHECK-EMPTY:

; CHECK-NEXT:     assign out = a + b + c;
; CHECK-NEXT:     assign out = a + b - c;
; CHECK-NEXT:     assign out = a - (b + c);
; CHECK-NEXT:     assign out = a + b * c;
; CHECK-NEXT:     assign out = a * b + c;
; CHECK-NEXT:     assign out = (a + b) * c;
; CHECK-NEXT:     assign out = a * (b + c);
; CHECK-NEXT:     assign out = (a + b) * (b + c);
; CHECK-NEXT:     assign out1 = ^(b + c);
; CHECK-NEXT:     assign out1 = b < c | b > c;
; CHECK-NEXT:     assign out1 = (b ^ c) & (out1 | out1);
; CHECK-NEXT:     assign out1 = out[3:2];
; CHECK-NEXT:     assign out1 = out < a;
; CHECK-NEXT:  endmodule


  module Sign :
    input a: UInt<4>
    input b: UInt<4>
    input c: SInt<4>
    input d: SInt<4>
    output out: UInt<1>
    out <= lt(a, b)
    out <= lt(c, d)
    out <= lt(asSInt(a), asSInt(b))
    out <= eq(asSInt(a), asSInt(b))

; CHECK-LABEL: module Sign(
; CHECK-NEXT:     input  [3:0] a, b, c, d,
; CHECK-NEXT:     output       out);
; CHECK-EMPTY:
; CHECK-NEXT:     assign out = a < b;
; CHECK-NEXT:     assign out = $signed(c) < $signed(d);
; CHECK-NEXT:     assign out = $signed(a) < $signed(b);
; CHECK-NEXT:     assign out = a == b;
; CHECK-NEXT:  endmodule


; CHECK-LABEL: module MultiUseExpr(
; CHECK-NEXT:    input  [3:0] a,
; CHECK-NEXT:    output       b);
; CHECK-EMPTY:
  module MultiUseExpr :
    input a: UInt<4>
    output b: UInt<1>
    ;; These node decls disappear in MLIR because of the _T name.  The verilog
    ;; emitter needs to reintroduce it as an 'assign' to a local.

    node _T_42 = andr(xorr(a)) ; CHECK-NEXT:    wire _T = &^a;
    node _T_99 = add(a, a)     ; CHECK-NEXT:    wire [4:0] _T_0 = a + a;

    b <= andr(_T_42)           ; CHECK-NEXT:    assign b = &_T;
    b <= xorr(_T_42)           ; CHECK-NEXT:    assign b = ^_T;
    b <= andr(_T_99)           ; CHECK-NEXT:    assign b = &_T_0;
    b <= xorr(_T_99)           ; CHECK-NEXT:    assign b = ^_T_0;

    ; This expression is multiply used but should still be emitted inline.
    ; CHECK-NEXT: assign b = ^(4'sh3 | 4'sh3);
    node _T_100 = asUInt(SInt<4>("h3"))
    b <= xorr(or(_T_100, _T_100))

    ; This expression isn't multiply used but needs to be emitted separately
    ; because Verilog bit select expressions don't compose generally.
    ; CHECK-NEXT: wire [3:0] _T_1 = ~a;
    ; CHECK-NEXT: assign b = _T_1[3:2];
    b <= shr(not(a), 2)

    ; CHECK-NEXT:  endmodule


  ; extmodules do not get emitted as anything, but are referenced from
  ; instances.
  extmodule MyExtModule :
    input in: UInt<8>
    output out: UInt<1>
    defname = FooExtModule

  extmodule MyParameterizedExtModule : 
    input in: UInt<8>
    output out: UInt<1>
    parameter FORMAT = "xyz_timeout=%d\n"
    parameter DEFAULT = 0
    parameter WIDTH = 32
    parameter DEPTH = 3.5

  ; CHECK-LABEL: module UseInstances(
  ; CHECK-NEXT:    input  [7:0] a_in,
  ; CHECK-NEXT:    output       a_out);
  ; CHECK-EMPTY:
  ; CHECK-NEXT:     wire [7:0] xyz_in;
  ; CHECK-NEXT:     wire       xyz_out;
  ; CHECK-NEXT:     wire [7:0] xyz2_in;
  ; CHECK-NEXT:     wire       xyz2_out;
  ; CHECK-EMPTY:
  ; CHECK-NEXT:     FooExtModule xyz ({{.*}}// There.scala:11711
  ; CHECK-NEXT:       .in(xyz_in),
  ; CHECK-NEXT:       .out(xyz_out)
  ; CHECK-NEXT:     );
  ; CHECK-NEXT:     assign xyz_in = a_in;{{.*}}// Here.scala:119
  ; CHECK-NEXT:     assign a_out = xyz_out;
  ; CHECK-NEXT:     MyParameterizedExtModule #(.DEFAULT(0), .DEPTH(3.5{{.*}}), .FORMAT("xyz_timeout=%d\n"), .WIDTH(32)) xyz2 (
  ; CHECK-NEXT:       .in(xyz2_in),
  ; CHECK-NEXT:       .out(xyz2_out)
  ; CHECK-NEXT:     );
  ; CHECK-NEXT:     assign xyz2_in = a_in;
  ; CHECK-NEXT:     assign a_out = xyz2_out;
  ; CHECK-NEXT:  endmodule

  module UseInstances :
    input a_in: UInt<8>
    output a_out: UInt<1>

    inst xyz of MyExtModule  @[There.scala 11711]
    xyz.in <= a_in @[Here.scala 119]
    a_out <= xyz.out

    inst xyz2 of MyParameterizedExtModule
    xyz2.in <= a_in
    a_out <= xyz2.out

  ; CHECK-LABEL: module Stop(
  ; CHECK-NEXT:    input clock, reset);
  ; CHECK-EMPTY:
  ; CHECK-EMPTY:
  ; CHECK-NEXT:    always @(posedge clock) begin
  ; CHECK-NEXT:      `ifndef SYNTHESIS
  ; CHECK-NEXT:        if (`STOP_COND_ && reset) $fatal;
  ; CHECK-NEXT:      `endif
  ; CHECK-NEXT:    end // always @(posedge)
  ; CHECK-NEXT:  endmodule
  module Stop :
    input clock: Clock
    input reset: UInt<1>
    stop(clock, reset, 42)

  ; CHECK-LABEL: module Stop2(
  ; CHECK-NEXT:    input clock, reset);
  ; CHECK-EMPTY:
  ; CHECK-EMPTY:
  ; CHECK-NEXT:    always @(posedge clock) begin
  ; CHECK-NEXT:      `ifndef SYNTHESIS
  ; CHECK-NEXT:        if (`STOP_COND_ && reset) begin
  ; CHECK-NEXT:          $fatal;
  ; CHECK-NEXT:          $finish;
  ; CHECK-NEXT:        end
  ; CHECK-NEXT:      `endif // !SYNTHESIS
  ; CHECK-NEXT:    end // always @(posedge)
  ; CHECK-NEXT:  endmodule
  module Stop2 :
    input clock: Clock
    input reset: UInt<1>
    stop(clock, reset, 42)
    stop(clock, reset, 0)

  ; CHECK-LABEL: module Stop3(
  ; CHECK-NEXT:    input clock1, clock2, reset);
  ; CHECK-EMPTY:
  ; CHECK-EMPTY:
  ; CHECK-NEXT:    always @(posedge clock1) begin
  ; CHECK-NEXT:      `ifndef SYNTHESIS
  ; CHECK-NEXT:        if (`STOP_COND_ && reset) $fatal;
  ; CHECK-NEXT:      `endif
  ; CHECK-NEXT:    end // always @(posedge)
  ; CHECK-NEXT:    always @(posedge clock2) begin
  ; CHECK-NEXT:      `ifndef SYNTHESIS
  ; CHECK-NEXT:        if (`STOP_COND_ && reset) $finish;
  ; CHECK-NEXT:      `endif
  ; CHECK-NEXT:    end // always @(posedge)
  ; CHECK-NEXT:  endmodule
  module Stop3 :
    input clock1: Clock
    input clock2: Clock
    input reset: UInt<1>
    stop(clock1, reset, 42)
    stop(clock2, reset, 0)

  ; CHECK-LABEL: module Print(
  ; CHECK-NEXT:    input       clock, reset,
  ; CHECK-NEXT:    input [3:0] a, b);
  ; CHECK-EMPTY:
  ; CHECK-EMPTY:
  ; CHECK-NEXT:    always @(posedge clock) begin
  ; CHECK-NEXT:      `ifndef SYNTHESIS
  ; CHECK-NEXT:        if (`PRINTF_COND_ && reset) $fwrite(32'h80000002, "Hi %x %x\n", a + a, b);
  ; CHECK-NEXT:      `endif
  ; CHECK-NEXT:    end // always @(posedge)
  ; CHECK-NEXT:  endmodule

  module Print :
    input clock: Clock
    input reset: UInt<1>
    input a: UInt<4>
    input b: UInt<4>
    printf(clock, reset, "Hi %x %x\n", add(a, a), b)

  ; CHECK-LABEL: module UninitReg1(
  ; CHECK-NEXT:    input       clock, reset, cond,
  ; CHECK-NEXT:    input [1:0] value);
  ; CHECK-EMPTY:
  ; CHECK-NEXT:    reg  [1:0] count;{{.*}}// RationalCrossing.scala:119:22
  ; CHECK-NEXT:    wire [1:0] x;
  ; CHECK-EMPTY:
  ; CHECK-NEXT:    assign x = count;
  ; CHECK-EMPTY:
  ; CHECK-NEXT:    `ifndef SYNTHESIS
  ; CHECK-NEXT:    initial begin
  ; CHECK-NEXT:      `INIT_RANDOM_PROLOG_
  ; CHECK-NEXT:      `ifdef RANDOMIZE_REG_INIT
  ; CHECK-NEXT:        count = `RANDOM;{{.*}}// RationalCrossing.scala:119:22
  ; CHECK-NEXT:      `endif
  ; CHECK-NEXT:    end // initial
  ; CHECK-NEXT:    `endif // SYNTHESIS
  ; CHECK-EMPTY:
  ; CHECK-NEXT:   always @(posedge clock) begin
  ; CHECK-NEXT:     count <= reset ? 2'h0 : cond ? value : count;
  ; CHECK-NEXT:   end
  ; CHECK-NEXT: endmodule
  module UninitReg1 :
    input clock: Clock
    input reset : UInt<1>
    input cond: UInt<1>
    input value: UInt<2>
    reg count : UInt<2>, clock with :
      reset => (UInt<1>("h0"), count) @[RationalCrossing.scala 119:22]
    node x = count

   node _GEN_0 = mux(cond, value, count)
   count <= mux(reset, UInt<2>("h0"), _GEN_0)

; CHECK-LABEL: module InitReg1(
; CHECK-NEXT:   input         clock, reset,
; CHECK-NEXT:   input  [31:0] io_d,
; CHECK-NEXT:   output [31:0] io_q,
; CHECK-NEXT:   input         io_en);
; CHECK-EMPTY:
; CHECK-NEXT:   reg [31:0] reg_0;
; CHECK-EMPTY:
; CHECK-NEXT:   assign io_q = reg_0;
; CHECK-EMPTY:
; CHECK-NEXT:   `ifndef SYNTHESIS
; CHECK-NEXT:   initial begin
; CHECK-NEXT:     `INIT_RANDOM_PROLOG_
; CHECK-NEXT:     if (reset) reg_0 = 32'h0;
; CHECK-NEXT:     `ifdef RANDOMIZE_REG_INIT
; CHECK-NEXT:       if (~reset) reg_0 = `RANDOM;
; CHECK-NEXT:     `endif
; CHECK-NEXT:   end // initial
; CHECK-NEXT:   `endif // SYNTHESIS
; CHECK-EMPTY:
; CHECK-NEXT:   always @(posedge clock or posedge reset) begin
; CHECK-NEXT:     reg_0 <= io_en ? io_d : reg_0;
; CHECK-NEXT:   end
; CHECK-NEXT: endmodule

  module InitReg1 :
    input clock : Clock
    input reset : UInt<1>
    input io_d : UInt<32>
    output io_q : UInt<32>
    input io_en : UInt<1>

    node _T = asAsyncReset(reset)
    reg reg : UInt<32>, clock with :
      reset => (_T, UInt<32>("h0"))
    io_q <= reg
    reg <= mux(io_en, io_d, reg)

  ; CHECK-LABEL: module Analog(
  ; CHECK-NEXT:   output [4:0] io_pins_asrcn3v3);
  module Analog :
    output io_pins_asrcn3v3 : Analog<5>

  ; CHECK-LABEL: module MemSimple(
  ; CHECK-NEXT:   input         clock1, clock2, inpred,
  ; CHECK-NEXT:   input  [41:0] indata,
  ; CHECK-NEXT:   output [41:0] result);
  module MemSimple :
    input clock1  : Clock
    input clock2  : Clock
    input inpred  : UInt<1>
    input indata  : SInt<42>
    output result : SInt<42>

    ; CHECK:  wire [2:0]  _M_read_addr;
    ; CHECK:  wire        _M_read_en;
    ; CHECK:  wire        _M_read_clk;
    ; CHECK:  wire [41:0] _M_read_data;
    ; CHECK:  wire [2:0]  _M_write_addr;
    ; CHECK:  wire        _M_write_en;
    ; CHECK:  wire        _M_write_clk;
    ; CHECK:  wire [41:0] _M_write_data;
    ; CHECK:  wire        _M_write_mask;
    ; CHECK:  reg  [41:0] _M[7:0];
    mem _M : @[Decoupled.scala 209:27]
          data-type => SInt<42>
          depth => 8
          read-latency => 0
          write-latency => 1
          reader => read
          writer => write
          read-under-write => undefined

    ; CHECK: assign _M_read_data = _M[_M_read_addr];	// Decoupled.scala:209:27
    ; CHECK-NEXT: assign result = _M_read_data;
    result <= _M.read.data

    ; CHECK: assign _M_read_addr = 1'h0;
    _M.read.addr <= UInt<1>("h0")
    ; CHECK: assign _M_read_en = 1'h1;
    _M.read.en <= UInt<1>("h1")
    ; CHECK: assign _M_read_clk = clock1;
    _M.read.clk <= clock1
    ; CHECK: assign _M_write_addr = 3'h0;
    _M.write.addr <= validif(inpred, UInt<3>("h0"))
    ; CHECK: assign _M_write_en = inpred ? 1'h1 : 1'h0;
    _M.write.en <= mux(inpred, UInt<1>("h1"), UInt<1>("h0"))
    ; CHECK: assign _M_write_clk = clock2;
    _M.write.clk <= validif(inpred, clock2)
    ; CHECK: assign _M_write_data = indata;
    _M.write.data <= validif(inpred, indata)
    ; CHECK: assign _M_write_mask = 1'h1;
    _M.write.mask <= validif(inpred, UInt<1>("h1"))

; CHECK:       `ifndef SYNTHESIS
; CHECK-NEXT:  initial begin
; CHECK-NEXT:    `INIT_RANDOM_PROLOG_
; CHECK-NEXT:    `ifdef RANDOMIZE_MEM_INIT
; CHECK-NEXT:      integer initvar;
; CHECK-NEXT:      for (initvar = 0; initvar < 8; initvar = initvar+1)
; CHECK-NEXT:        _M[initvar] = `RANDOM;{{.*}}// Decoupled.scala:209:27
; CHECK-NEXT:    `endif // RANDOMIZE_MEM_INIT
; CHECK-NEXT:  end // initial
; CHECK-NEXT:  `endif // SYNTHESIS

; CHECK:       always @(posedge _M_write_clk) begin
; CHECK-NEXT:    if (_M_write_en & _M_write_mask) _M[_M_write_addr] <= _M_write_data;	// Decoupled.scala:209:27
; CHECK-NEXT:  end // always @(posedge)


  ; CHECK-LABEL: module MemAggregate(
  ; CHECK-NEXT:   input clock1, clock2);
  module MemAggregate :
    input clock1 : Clock
    input clock2 : Clock

    ; CHECK:        reg  [3:0] _M_id[19:0];
    ; CHECK-NEXT:   reg  [7:0] _M_other[19:0];
    mem _M : @[Decoupled.scala 209:24]
          data-type => { id : Analog<4>, other: SInt<8> }
          depth => 20
          read-latency => 0
          write-latency => 1
          reader => read
          writer => write
          read-under-write => undefined

    ; CHECK: `ifndef RANDOMIZE_GARBAGE_ASSIGN
    ; CHECK-NEXT: assign _M_read_data_id = _M_id[_M_read_addr];	// Decoupled.scala:209:24
    ; CHECK-NEXT: assign _M_read_data_other = _M_other[_M_read_addr];	// Decoupled.scala:209:24
    ; CHECK-NEXT: `else
    ; CHECK-NEXT: assign _M_read_data_id = _M_read_addr < 20 ? _M_id[_M_read_addr] : `RANDOM;
    ; CHECK-NEXT: assign _M_read_data_other = _M_read_addr < 20 ? _M_other[_M_read_addr] : `RANDOM;
    ; CHECK-NEXT: `endif // RANDOMIZE_GARBAGE_ASSIGN

; CHECK:        `ifndef SYNTHESIS
; CHECK-NEXT:    initial begin
; CHECK-NEXT:      `INIT_RANDOM_PROLOG_
; CHECK-NEXT:      `ifdef RANDOMIZE_MEM_INIT
; CHECK-NEXT:        integer initvar;
; CHECK-NEXT:        for (initvar = 0; initvar < 20; initvar = initvar+1) begin
; CHECK-NEXT:          _M_id[initvar] = `RANDOM;
; CHECK-NEXT:          _M_other[initvar] = `RANDOM;
; CHECK-NEXT:        end	// Decoupled.scala:209:24
; CHECK-NEXT:      `endif // RANDOMIZE_MEM_INIT
; CHECK-NEXT:    end // initial
; CHECK-NEXT:    `endif // SYNTHESIS

; CHECK:  always @(posedge _M_write_clk) begin
; CHECK-NEXT:    if (_M_write_en & _M_write_mask) begin
; CHECK-NEXT:      _M_id[_M_write_addr] <= _M_write_data_id;	// Decoupled.scala:209:24
; CHECK-NEXT:      _M_other[_M_write_addr] <= _M_write_data_other;	// Decoupled.scala:209:24
; CHECK-NEXT:    end
; CHECK-NEXT:  end // always @(posedge)

  ; CHECK-LABEL: module MemEmpty();
  module MemEmpty :
    mem Empty :
      data-type => UInt<32>
      depth => 16
      read-latency => 0
      write-latency => 1
      read-under-write => undefined

 ; CHECK-LABEL: module MemOne();
  module MemOne :
    mem _M : @[Decoupled.scala 209:24]
          data-type => { id : Analog<4>, other: SInt<8> }
          depth => 1
          read-latency => 0
          write-latency => 1
          reader => read
          writer => write
          read-under-write => undefined
; CHECK:        `ifndef SYNTHESIS
; CHECK-NEXT:    initial begin
; CHECK-NEXT:      `INIT_RANDOM_PROLOG_
; CHECK-NEXT:      `ifdef RANDOMIZE_MEM_INIT
; CHECK-NEXT:        _M_id[0] = `RANDOM;
; CHECK-NEXT:        _M_other[0] = `RANDOM;
; CHECK-NEXT:      `endif // RANDOMIZE_MEM_INIT
; CHECK-NEXT:    end // initial
; CHECK-NEXT:    `endif // SYNTHESIS

  ; CHECK-LABEL: module Attach(
  ; CHECK-NEXT:    input a, b, c);
  module Attach :
    input a: Analog<1>
    input b: Analog<1>
    input c: Analog<1>
    attach(a, b, c)  @[Place.scala 101]

; CHECK:       `ifndef SYNTHESIS
; CHECK-NEXT:    alias a = b = c;{{.*}}// Place.scala:101
; CHECK-NEXT:  `endif
; CHECK-NEXT:  `ifdef SYNTHESIS
; CHECK-NEXT:    assign a = b;{{.*}}// Place.scala:101
; CHECK-NEXT:    assign a = c;{{.*}}// Place.scala:101
; CHECK-NEXT:    assign b = a;{{.*}}// Place.scala:101
; CHECK-NEXT:    assign b = c;{{.*}}// Place.scala:101
; CHECK-NEXT:    assign c = a;{{.*}}// Place.scala:101
; CHECK-NEXT:    assign c = b;{{.*}}// Place.scala:101
; CHECK-NEXT:  `endif // SYNTHESIS

  ; CHECK-LABEL: module IsInvalid(
  ; CHECK-NEXT:    output a);
  module IsInvalid :
    output a: Analog<1>
    a is invalid  @[Place.scala 101]


  ; CHECK-LABEL: module Locations(
  module Locations :
    input a: UInt<4>
    output b: UInt<4>
    node _T_1 = add(a, a)                 @[Place.scala 101:13]
    node _T_2 = add(_T_1, UInt<4>("h3"))  @[Other.scala 51:15]
    b <= xor(_T_2, UInt<4>("h11"))        @[Place.scala 101:15]

    node _T_3 = mul(a, a)                 @[A.scala 11:13]
    node _T_4 = mul(_T_3, UInt<4>("h2"))  @[A.scala 51:15]
    b <= xor(_T_4, UInt<4>("h10"))        @[A.scala 101:15]


; CHECK: assign b = a + a + 4'h3 ^ 4'h1;
; CHECK: // Other.scala:51:15, Place.scala:101:{13,15}

; CHECK: assign b = a * a * 4'h2 ^ 4'h0;
; CHECK: // A.scala:11:13, :51:15, :101:15
