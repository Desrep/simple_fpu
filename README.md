# simple_fpu
Fpu RTL for the IEEE 754 single precision standard, it includes addition, multiplication, division, square root and fp compare. It has some exception management. It's a very simple implementation using iterative subtraction algorithms for the division and square root units, the multiplication unit uses a parallel shift and addition of various terms, the rest of terms are added sequentially. The number of pipeline stages for the division and square root can be controlled with the STAGES parameter. The project is intended to be friendly for integration in the caravel project but ultimately the goal is to integrate it with a risc v imlementation so that the code can use hardware fp operations.

It's straightforward to use, the easiest way to understand how to use it is to check the sample testbench (included in the code but also in the link).
## FPU.v
This file is actually only used for instantiation of the units mostly for testing purposes but it still works as the top module, this code can be easily modified or replaced as you wish.
The signals do the following 


| Singal | Type | Description |
| --- | --- |---|
| in1p | input | first operand |
| in2p | input | second operand |
| rstp | input | reset signal |
| clk  | input |The clock |
| round_mp  | input | Rounding mode selector, the codes can be found in special_characters.v |
| ov | output | overflow flag output |
| un  | output | the underflow flag output |
|great  | output | ndicates if in1p is greater than in2p (if in1p > in2p then great = 1) (compare operation) |
| less  | output |indicates if in2p is less than in2p (if in2p < in2p then less = 1)  (compare operation) |
| eq  | output | indicates in1p and in2p are equal  (compare operation) |
| inexact | output |  is the flag indicating if the operation completed is inexac |
| inv | output | is the falg indicating if the operation  completed is invalid |
| div_zero | output | when division is selected this flag indicates if in2p is zero (meaning that in1p/in2p is a division by zero) |
| done | output | is a flag indicating if the current operation is finished, this is a synchronous signal |
| opcode | input | operation selection |

The opcode is the operation is encoded as follows

         00 = addition and compare
         
         01 = multiplication
         
         10 = division
         
         11 = square root

         100 = compare
         
         
For square root the operand used is only in1p

Division performs in1p/in2p

For sum if a subtraction is needed first one of the operands has to be made negative

act is no longer used, I need to remove it.

These signals are pretty much repeated in the different modules

This design can be synthesized using vendor tools and the tests indicate that the functionality is correct, but it has not been properly tested using a standard procedure (with UVM for example, or random testing).
In it's current state it should be possible to use icarus verilog for testing as well.
## fp_add.v
This file contains the addition (and subtraction) RTL, it doesn't require any other file, to compute subtraction you would need to modify the operands first, for example to perform 3-5 you would need to convert it to 3+(-5).
## fp_mul.v
This file performs the fp multiplication, the mulxbit.v file does the fixed point multiplication.
## fp_div.v
Floating point division unit, the fixed point division file divide_r.v uses subtraction based iterations to perform the fixed point division with a restoring algorithm.
+ divide_r.v 
       In this file you can use the STAGES parameter to modify the number of registerin stages of the algorithm, if you make it 3, for example, the result would be an
       architecture like.
* COMBINATIONAL/register/ COMBINATIONAL/register/ COMBINATIONAL

so the number of registers would be STAGES-1 and every combinational part would carry out a third of the total number of iterations.
You could use this to try and fix hold violations primarily, or setup violations, but the delay won't be modified considerably, this would be just a way to make         the error messages go away.
                              
## fp_sqr.v
Very similar to the division file, the sqrt.v code uses an iterative restoring algorithm to calculate the fraction square root in fixed point, the number of stages can also be controlled in a similar way to the division file.
## fp_compare.v 
A regular part-by-part comparison of floating point numbers.
## rounding modes
The rounding modes are defined in the special_characters file. Selected by round_mp in the top module (fpu.v).
Adapting (or creating from scratch) the top module shouldn't be a prolem, this top module is basically a place holder if you want to test the design right away.
## To do 
Validation using constrained random verification.

Formal validation using VCF for example.

Incorporate into a risc V implementation.
         Add interface (bus) structures
         Add FPU register structures
         others

## Simulation
This link can be used to simulate the code

(this is not up-to-date but the functionality is the same, tbd)
https://www.edaplayground.com/x/DE5Z
    
