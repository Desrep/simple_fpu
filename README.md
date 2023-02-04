# simple_fpu
Fpu RTL for the IEEE 754 single precision standard, it includes addition, multiplication, division, square root and fp compare. It has some exception management. It's a very simple implementation using recursive subtraction algorithms for the division and square root units, the multiplication unit uses a parallel shift and addition of 6 terms, the rest of terms are added sequentially. The number of pipeline stages for the division and square root can be controlled with the STAGES parameter.
## FPU.v
This file is actually only used for instantiation of the units mostly for testing purposes but it still works as the top module, this code can be easily modified or replaced as you wish.
## fp_add.v
This file contains the addition (and subtraction) RTL, it doesn't require any other file, to compute subtraction you would need to modify the operands first, for example to perform 3-5 you would need to convert it to 3+(-5).
## fp_mul.v
This file performs the fp multiplication, the mulxbit.v file does the fixed point multiplication.
##fp_div.v
Floating point division unit, the fixed point division file divide_r.v uses subtraction based iterations to perform the fixed point division with a restoring algorithm.
+ divide_r.v 
       In this file you can use the STAGES parameter to modify the number of registerin stages of the algorithm, if you make it 3, for example, the result would be an
       architecture like.
* COMBINATIONAL/register/ COMBINATIONAL/register/ COMBINATIONAL

so the number of registers would be STAGES-1 and every combinational part would carry out a third of the total number of iterations.
You could use this to try and fix hold violations primarily, or setup violations, but the delay won't be modified considerably, this would be just a way to make         the error messages go away.
                              
## fp_sqr.v
Very similar to the division file, the sqrt.v code uses an iterative non restoring algorithm to calculate the fraction square root in fixed point, the number of stages can also be controlled in a similar way to the division file.
#fp_compare.v 
A regular part-by-part comparison of floating point numbers.
    
