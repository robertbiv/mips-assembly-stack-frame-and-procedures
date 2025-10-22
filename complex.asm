# complex.asm
# complex number struct and operations

.data
prompt_real1:   .asciiz "Enter real part of complex #1: "
prompt_imag1:   .asciiz "Enter imaginary part of complex #1: "
prompt_real2:   .asciiz "Enter real part of complex #2: "
prompt_imag2:   .asciiz "Enter imaginary part of complex #2: "
label_sum:      .asciiz "Sum: "
label_diff:     .asciiz "Difference: "
fmt_lparen:     .asciiz "("
fmt_comma:      .asciiz ", "
fmt_rparen:     .asciiz ")\n"

.text
.globl main

# allocate 16 bytes for a complex number
alloc_complex:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    li    $v0, 9           
    li    $a0, 16          
    syscall
    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    jr    $ra

# add two complex numbers
addComplex:
    addiu $sp, $sp, -32
    sw    $ra, 28($sp)
    sw    $a0, 24($sp)
    sw    $a1, 20($sp)

    jal   alloc_complex
    move  $t0, $v0         

    lw    $a0, 24($sp)
    lw    $a1, 20($sp)

    # add real parts
    ldc1  $f0, 0($a0)      
    ldc1  $f2, 0($a1)      
    add.d $f4, $f0, $f2    

    sdc1  $f4, 0($t0)

    # add imaginary parts
    ldc1  $f6, 8($a0)      
    ldc1  $f8, 8($a1)      
    add.d $f10, $f6, $f8   

    sdc1  $f10, 8($t0)

    move  $v0, $t0

    lw    $ra, 28($sp)
    addiu $sp, $sp, 32
    jr    $ra

# subtract two complex numbers
subComplex:
    addiu $sp, $sp, -32
    sw    $ra, 28($sp)
    sw    $a0, 24($sp)
    sw    $a1, 20($sp)

    # allocate result
    jal   alloc_complex
    move  $t0, $v0

    lw    $a0, 24($sp)
    lw    $a1, 20($sp)

    # real part
    ldc1  $f0, 0($a0)
    ldc1  $f2, 0($a1)
    sub.d $f4, $f0, $f2

    sdc1  $f4, 0($t0)

    # imaginary part
    ldc1  $f6, 8($a0)
    ldc1  $f8, 8($a1)
    sub.d $f10, $f6, $f8

    sdc1  $f10, 8($t0)

    move  $v0, $t0

    lw    $ra, 28($sp)
    addiu $sp, $sp, 32
    jr    $ra

# print complex number as (a, b)
printComplex:
    addiu $sp, $sp, -24
    sw    $ra, 20($sp)
    sw    $a0, 16($sp)

    li    $v0, 4
    la    $a0, fmt_lparen
    syscall

    lw    $a0, 16($sp)
    ldc1  $f12, 0($a0)
    li    $v0, 3
    syscall

    li    $v0, 4
    la    $a0, fmt_comma
    syscall

    lw    $a0, 16($sp)
    ldc1  $f12, 8($a0)
    li    $v0, 3
    syscall

    li    $v0, 4
    la    $a0, fmt_rparen
    syscall

    lw    $ra, 20($sp)
    addiu $sp, $sp, 24
    jr    $ra

main:
    # allocate two complex numbers
    jal   alloc_complex
    move  $s0, $v0
    jal   alloc_complex
    move  $s1, $v0

    # read A.real
    li    $v0, 4
    la    $a0, prompt_real1
    syscall
    li    $v0, 7
    syscall
    sdc1  $f0, 0($s0)

    # read A.imag
    li    $v0, 4
    la    $a0, prompt_imag1
    syscall
    li    $v0, 7
    syscall
    sdc1  $f0, 8($s0)

    # read B.real
    li    $v0, 4
    la    $a0, prompt_real2
    syscall
    li    $v0, 7
    syscall
    sdc1  $f0, 0($s1)

    # read B.imag
    li    $v0, 4
    la    $a0, prompt_imag2
    syscall
    li    $v0, 7
    syscall
    sdc1  $f0, 8($s1)

    # print sum
    li    $v0, 4
    la    $a0, label_sum
    syscall
    move  $a0, $s0
    move  $a1, $s1
    jal   addComplex
    move  $a0, $v0
    jal   printComplex

    # print difference
    li    $v0, 4
    la    $a0, label_diff
    syscall
    move  $a0, $s0
    move  $a1, $s1
    jal   subComplex
    move  $a0, $v0
    jal   printComplex

    li    $v0, 10
    syscall
