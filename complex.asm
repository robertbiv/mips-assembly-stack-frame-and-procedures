# complex.asm
# Problem 1: Complex numbers using MIPS (MARS/QtSPIM)
# Structure: two doubles (real, imag) -> 16 bytes
# API:
#  - addComplex($a0=ptr A, $a1=ptr B) -> $v0=ptr result
#  - subComplex($a0=ptr A, $a1=ptr B) -> $v0=ptr result
#  - printComplex($a0=ptr) -> prints as (a, b) and newline
# main: prompt for two complex numbers (doubles), call add/sub, print results

.data
prompt_real1:   .asciiz "Enter real part of complex #1: "
prompt_imag1:   .asciiz "Enter imaginary part of complex #1: "
prompt_real2:   .asciiz "Enter real part of complex #2: "
prompt_imag2:   .asciiz "Enter imaginary part of complex #2: "
label_sum:      .asciiz "Sum: "
label_diff:     .asciiz "Difference: "
fmt_lparen:     .asciiz "("
fmt_comma_sp:   .asciiz ", "
fmt_rparen_nl:  .asciiz ")\n"

.text
.globl main

# Allocate a Complex struct (16 bytes) and return pointer in $v0
alloc_complex:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    li    $v0, 9            # sbrk
    li    $a0, 16           # size of struct
    syscall
    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    jr    $ra

# addComplex($a0=ptr A, $a1=ptr B) -> $v0=ptr result
# result.real = A.real + B.real; result.imag = A.imag + B.imag
addComplex:
    addiu $sp, $sp, -32
    sw    $ra, 28($sp)

    # allocate result
    jal   alloc_complex
    move  $t0, $v0         # result ptr in $t0

    # load A.real and B.real
    ldc1  $f0, 0($a0)      # A.real
    ldc1  $f2, 0($a1)      # B.real
    add.d $f4, $f0, $f2    # sum real

    # store result.real
    sdc1  $f4, 0($t0)

    # load A.imag and B.imag
    ldc1  $f6, 8($a0)      # A.imag
    ldc1  $f8, 8($a1)      # B.imag
    add.d $f10, $f6, $f8   # sum imag

    # store result.imag
    sdc1  $f10, 8($t0)

    move  $v0, $t0

    lw    $ra, 28($sp)
    addiu $sp, $sp, 32
    jr    $ra

# subComplex($a0=ptr A, $a1=ptr B) -> $v0=ptr result
# result.real = A.real - B.real; result.imag = A.imag - B.imag
subComplex:
    addiu $sp, $sp, -32
    sw    $ra, 28($sp)

    # allocate result
    jal   alloc_complex
    move  $t0, $v0         # result ptr in $t0

    # load A.real and B.real
    ldc1  $f0, 0($a0)      # A.real
    ldc1  $f2, 0($a1)      # B.real
    sub.d $f4, $f0, $f2    # diff real

    # store result.real
    sdc1  $f4, 0($t0)

    # load A.imag and B.imag
    ldc1  $f6, 8($a0)      # A.imag
    ldc1  $f8, 8($a1)      # B.imag
    sub.d $f10, $f6, $f8   # diff imag

    # store result.imag
    sdc1  $f10, 8($t0)

    move  $v0, $t0

    lw    $ra, 28($sp)
    addiu $sp, $sp, 32
    jr    $ra

# printComplex($a0=ptr)
# prints: (real, imag)\n
printComplex:
    addiu $sp, $sp, -24
    sw    $ra, 20($sp)
    sw    $a0, 16($sp)     # save pointer

    # print "("
    li    $v0, 4
    la    $a0, fmt_lparen
    syscall

    # print real (double)
    lw    $t0, 16($sp)     # restore ptr
    ldc1  $f12, 0($t0)
    li    $v0, 3
    syscall

    # print ", "
    li    $v0, 4
    la    $a0, fmt_comma_sp
    syscall

    # print imag (double)
    lw    $t0, 16($sp)     # restore ptr
    ldc1  $f12, 8($t0)
    li    $v0, 3
    syscall

    # print ")\n"
    li    $v0, 4
    la    $a0, fmt_rparen_nl
    syscall

    lw    $ra, 20($sp)
    addiu $sp, $sp, 24
    jr    $ra

main:
    # Allocate two complex structs A and B
    jal   alloc_complex
    move  $s0, $v0         # A
    jal   alloc_complex
    move  $s1, $v0         # B

    # Prompt and read A.real
    li    $v0, 4
    la    $a0, prompt_real1
    syscall
    li    $v0, 7           # read_double -> $f0
    syscall
    sdc1  $f0, 0($s0)

    # Prompt and read A.imag
    li    $v0, 4
    la    $a0, prompt_imag1
    syscall
    li    $v0, 7
    syscall
    sdc1  $f0, 8($s0)

    # Prompt and read B.real
    li    $v0, 4
    la    $a0, prompt_real2
    syscall
    li    $v0, 7
    syscall
    sdc1  $f0, 0($s1)

    # Prompt and read B.imag
    li    $v0, 4
    la    $a0, prompt_imag2
    syscall
    li    $v0, 7
    syscall
    sdc1  $f0, 8($s1)

    # Print Sum
    li    $v0, 4
    la    $a0, label_sum
    syscall
    move  $a0, $s0
    move  $a1, $s1
    jal   addComplex       # $v0 = sum
    move  $a0, $v0
    jal   printComplex

    # Print Difference
    li    $v0, 4
    la    $a0, label_diff
    syscall
    move  $a0, $s0
    move  $a1, $s1
    jal   subComplex       # $v0 = diff
    move  $a0, $v0
    jal   printComplex

    # Exit
    li    $v0, 10
    syscall
