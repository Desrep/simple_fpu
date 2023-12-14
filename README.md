# simple_fpu
Fpu RTL for the IEEE 754 single precision standard, it includes addition, multiplication, division, square root and fp compare. It has some exception management. It's a very simple implementation using recursive subtraction algorithms for the division and square root units, the multiplication unit uses a parallel shift and addition of 6 terms, the rest of terms are added sequentially. The number of pipeline stages for the division and square root can be controlled with the STAGES parameter. The project is intended to be friendly for integration in the caravel project but ultimately the goal is to integrate it with a risc v imlementation so that the code can use fp operations.
## FPU.v
This file is actually only used for instantiation of the units mostly for testing purposes but it still works as the top module, this code can be easily modified or replaced as you wish.
The signals do the following 

in1p is the first operand--------input

in2p is the second operand--------input

rstp is the reset signal----------input

clk is the clock----------------input

round_mp is the rounding mode selector, the codes can be found in special_characters.v--------input

out is the output--------output

ov is the overflow flag output--------output

un is the underflow flag output--------output

great indicates if in1p is greater than in2p (if in1p > in2p then great = 1) (compare operation)--------output

less indicates if in2p is less than in2p (if in2p < in2p then less = 1)  (compare operation)--------output

eq indicates in1p and in2p are equal  (compare operation)--------output

inexact is the flag indicating if the operation completed is inexact--------output

inv is the falg indicating if the operation  completed is invalid--------output

div_zero, when division is selected this flag indicates if in2p is zero (meaning that in1p/in2p is a division by zero)--------output

done is a flag indicating if the current operation is finished, this is a synchronous signal --------output

opcode is the operation selection------input

         00 = addition and compare
         
         01 = multiplication
         
         10 = division
         
         11 = square root
         
         
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

## Simulation
This link can be used to simulate the code
(this is not up-to-date but the functionality is the same, tbd)
https://www.edaplayground.com/x/DE5Z
    
