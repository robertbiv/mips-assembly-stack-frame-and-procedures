# MIPS Assembly: Stack Frames and Procedures

This repository contains implementations of advanced data structures and arithmetic operations in MIPS assembly language, demonstrating proper use of stack frames, procedure calls, and memory management.

## Overview

This project showcases three MIPS assembly programs that implement mathematical operations on different data types:
- **Big Integers** - Arbitrary precision integer arithmetic (up to 40 digits)
- **Complex Numbers** - Operations on complex numbers with real and imaginary parts
- **Rational Numbers** - Fraction arithmetic with automatic reduction

Each program demonstrates key assembly programming concepts including procedure calls, stack frame management, dynamic memory allocation, and structured data manipulation.

## Programs

### 1. bigInteger.asm
Implements arbitrary precision integer arithmetic for integers up to 40 digits.

**Features:**
- Addition and subtraction of big integers
- Comparison operations (==, !=, <, <=, >, >=)
- Sign handling for positive and negative numbers
- Leading zero normalization
- Interactive input and formatted output

**Data Structure:**
```
BigInt (48 bytes):
  - 4 bytes: sign (0 = negative, 1 = positive)
  - 4 bytes: length (number of digits)
  - 40 bytes: digit array (one digit per byte)
```

**Operations:**
- `addBig` - Add two big integers
- `subBig` - Subtract two big integers
- `pred_eq`, `pred_ne`, `pred_ge`, `pred_le` - Comparison predicates
- `printBig` - Display a big integer
- `readBigInteractive` - Interactive input with digit-by-digit entry

### 2. complex.asm
Implements complex number arithmetic with double-precision floating-point components.

**Features:**
- Addition and subtraction of complex numbers
- Double-precision floating-point arithmetic
- Formatted output: (real, imaginary)

**Data Structure:**
```
Complex (16 bytes):
  - 8 bytes: real part (double)
  - 8 bytes: imaginary part (double)
```

**Operations:**
- `addComplex` - Add two complex numbers
- `subComplex` - Subtract two complex numbers
- `printComplex` - Display in (a, b) format

### 3. rational.asm
Implements rational number (fraction) arithmetic with automatic reduction to lowest terms.

**Features:**
- Four basic arithmetic operations
- Automatic reduction using GCD
- Both fraction and decimal display
- Zero denominator error handling

**Data Structure:**
```
Rational (8 bytes):
  - 4 bytes: numerator (integer)
  - 4 bytes: denominator (integer)
```

**Operations:**
- `addRational` - Add two rational numbers
- `subRational` - Subtract two rational numbers
- `mulRational` - Multiply two rational numbers
- `divRational` - Divide two rational numbers
- `reduceRational` - Reduce to lowest terms using GCD
- `printRational` - Display as fraction (num/den)
- `printRationalFloat` - Display as decimal

## Requirements

To run these programs, you need a MIPS simulator such as:
- **MARS** (MIPS Assembler and Runtime Simulator)
- **SPIM** (MIPS32 Simulator)
- **QtSpim** (Qt-based SPIM)

## How to Run

1. **Install a MIPS Simulator**
   - Download MARS from [http://courses.missouristate.edu/KenVollmar/mars/](http://courses.missouristate.edu/KenVollmar/mars/)
   - Or install SPIM/QtSpim for your platform

2. **Load a Program**
   - Open your MIPS simulator
   - Load one of the `.asm` files (bigInteger.asm, complex.asm, or rational.asm)

3. **Assemble and Run**
   - Assemble the program (usually F3 in MARS)
   - Run the program (usually F5 in MARS)
   - Follow the interactive prompts to enter values

## Key Concepts Demonstrated

### Stack Frame Management
All procedures properly manage the stack with:
- Saving return address (`$ra`) and saved registers (`$s0-$s7`)
- Allocating space for local variables
- Preserving caller's registers
- Proper cleanup before return

### Procedure Calling Convention
- Arguments passed in `$a0-$a3`
- Return values in `$v0-$v1`
- Temporary registers (`$t0-$t9`) not preserved across calls
- Saved registers (`$s0-$s7`) preserved when used

### Dynamic Memory Allocation
Programs use `syscall` with service 9 to dynamically allocate heap memory for data structures.

### Structured Data
Demonstrates accessing multi-field structures using:
- Base address + offset calculations
- Proper alignment for different data types
- Pointer manipulation

## Example Usage

### Big Integer Example
```
Enter digits for BigInt #1:
Digit (0-9 or -1 to end): 9
Digit (0-9 or -1 to end): 8
Digit (0-9 or -1 to end): 7
Digit (0-9 or -1 to end): -1

Enter digits for BigInt #2:
Digit (0-9 or -1 to end): 1
Digit (0-9 or -1 to end): 2
Digit (0-9 or -1 to end): 3
Digit (0-9 or -1 to end): -1

A + B = 1110
A - B = 864
```

### Complex Number Example
```
Enter real part of complex #1: 3.5
Enter imaginary part of complex #1: 2.0
Enter real part of complex #2: 1.5
Enter imaginary part of complex #2: -1.0

Sum: (5.0, 1.0)
Difference: (2.0, 3.0)
```

### Rational Number Example
```
Enter numerator of rational #1: 6
Enter denominator of rational #1: 8
Enter numerator of rational #2: 3
Enter denominator of rational #2: 4

A + B = 3/2 = 1.5
A - B = 0/1 = 0.0
A * B = 9/16 = 0.5625
A / B = 1/1 = 1.0
```

## Educational Value

This repository is ideal for:
- Learning MIPS assembly programming
- Understanding procedure call conventions
- Practicing stack frame management
- Implementing data structures in assembly
- Working with different number representations
- Building complex programs from procedures

## License

This appears to be academic coursework (Homework_4.pdf included). Please follow your institution's academic integrity policies if using this code for educational purposes.