# rational.asm
# rational number operations

.data
prompt_a_num: .asciiz "Enter numerator of rational #1: "
prompt_a_den: .asciiz "Enter denominator of rational #1: "
prompt_b_num: .asciiz "Enter numerator of rational #2: "
prompt_b_den: .asciiz "Enter denominator of rational #2: "
label_add:    .asciiz "A + B = "
label_sub:    .asciiz "A - B = "
label_mul:    .asciiz "A * B = "
label_div:    .asciiz "A / B = "
err_zero_den: .asciiz "Error: denominator cannot be 0. Exiting.\n"

.text
.globl main

# allocate 8 bytes for rational
alloc_rational:
    li   $v0, 9
    li   $a0, 8
    syscall
    jr   $ra

# gcd using Euclid's algorithm
_gcd:
    move $t0, $a0          
    move $t1, $a1          
    # make positive
    bltz $t0, _gcd_abs_a
_gcd_abs_a_done:
    bltz $t1, _gcd_abs_b
_gcd_abs_b_done:
_gcd_loop:
    beq  $t1, $zero, _gcd_done
    div  $t0, $t1
    mfhi $t2               
    move $t0, $t1
    move $t1, $t2
    j    _gcd_loop
_gcd_done:
    move $v0, $t0
    jr   $ra
_gcd_abs_a:
    sub  $t0, $zero, $t0
    j    _gcd_abs_a_done
_gcd_abs_b:
    sub  $t1, $zero, $t1
    j    _gcd_abs_b_done

# reduce fraction
reduceRational:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    sw    $a0, 8($sp)

    lw    $t0, 0($a0)
    lw    $t1, 4($a0)

    beq   $t1, $zero, _reduce_done

    bltz  $t1, _reduce_flip
_reduce_flip_done:

    move  $a0, $t0
    move  $a1, $t1
    jal   _gcd
    move  $t2, $v0
    beq   $t2, $zero, _reduce_done

    div   $t0, $t2
    mflo  $t0
    div   $t1, $t2
    mflo  $t1

    lw    $t3, 8($sp)
    sw    $t0, 0($t3)
    sw    $t1, 4($t3)

_reduce_done:
    lw    $v0, 8($sp)
    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    jr    $ra
_reduce_flip:
    sub   $t1, $zero, $t1
    sub   $t0, $zero, $t0
    j     _reduce_flip_done

# create new rational
makeRational:
    addiu $sp, $sp, -24
    sw    $ra, 20($sp)
    sw    $a0, 16($sp)
    sw    $a1, 12($sp)

    jal   alloc_rational
    move  $t0, $v0
    lw    $t1, 16($sp)
    lw    $t2, 12($sp)
    sw    $t1, 0($t0)
    sw    $t2, 4($t0)
    move  $a0, $t0
    jal   reduceRational
    move  $v0, $a0

    lw    $ra, 20($sp)
    addiu $sp, $sp, 24
    jr    $ra

# add two rationals
addRational:
    addiu $sp, $sp, -24
    sw    $ra, 20($sp)

    lw    $t0, 0($a0)
    lw    $t1, 4($a0)
    lw    $t2, 0($a1)
    lw    $t3, 4($a1)

    mult $t0, $t3
    mflo $t4
    mult $t2, $t1
    mflo $t5
    addu $t6, $t4, $t5

    mult $t1, $t3
    mflo $t7

    move $a0, $t6
    move $a1, $t7
    jal  makeRational

    lw    $ra, 20($sp)
    addiu $sp, $sp, 24
    jr    $ra

# subtract two rationals
subRational:
    addiu $sp, $sp, -24
    sw    $ra, 20($sp)

    lw    $t0, 0($a0)
    lw    $t1, 4($a0)
    lw    $t2, 0($a1)
    lw    $t3, 4($a1)

    mult $t0, $t3
    mflo $t4
    mult $t2, $t1
    mflo $t5
    subu $t6, $t4, $t5

    mult $t1, $t3
    mflo $t7

    move $a0, $t6
    move $a1, $t7
    jal  makeRational

    lw    $ra, 20($sp)
    addiu $sp, $sp, 24
    jr    $ra

# multiply two rationals
mulRational:
    addiu $sp, $sp, -24
    sw    $ra, 20($sp)

    lw    $t0, 0($a0)   # a
    lw    $t1, 4($a0)   # b
    lw    $t2, 0($a1)   # c
    lw    $t3, 4($a1)   # d

    mult $t0, $t2
    mflo $t4
    mult $t1, $t3
    mflo $t5

    move $a0, $t4
    move $a1, $t5
    jal  makeRational

    lw    $ra, 20($sp)
    addiu $sp, $sp, 24
    jr    $ra

# divide two rationals
divRational:
    addiu $sp, $sp, -24
    sw    $ra, 20($sp)

    lw    $t0, 0($a0)   # a
    lw    $t1, 4($a0)   # b
    lw    $t2, 0($a1)   # c
    lw    $t3, 4($a1)   # d

    # num = a*d
    mult $t0, $t3
    mflo $t4
    # den = b*c
    mult $t1, $t2
    mflo $t5

    move $a0, $t4
    move $a1, $t5
    jal  makeRational

    lw    $ra, 20($sp)
    addiu $sp, $sp, 24
    jr    $ra

# print rational as A/B
printRational:
    lw   $t0, 0($a0)
    lw   $t1, 4($a0)
    li   $v0, 1
    move $a0, $t0
    syscall
    li   $v0, 11
    li   $a0, 47
    syscall
    li   $v0, 1
    move $a0, $t1
    syscall
    li   $v0, 11
    li   $a0, 10
    syscall
    jr   $ra

printRationalFloat:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)

    lw    $t0, 0($a0)
    lw    $t1, 4($a0)

    mtc1  $t0, $f0
    cvt.d.w $f0, $f0
    mtc1  $t1, $f2
    cvt.d.w $f2, $f2
    div.d $f12, $f0, $f2

    li    $v0, 3
    syscall

    li    $v0, 11
    li    $a0, 10
    syscall

    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    jr    $ra

main:
    # allocate two rationals
    jal  alloc_rational
    move $s0, $v0
    jal  alloc_rational
    move $s1, $v0

    # read first rational
    li   $v0, 4
    la   $a0, prompt_a_num
    syscall
    li   $v0, 5
    syscall
    sw   $v0, 0($s0)

    li   $v0, 4
    la   $a0, prompt_a_den
    syscall
    li   $v0, 5
    syscall
    beq  $v0, $zero, _err_zero
    sw   $v0, 4($s0)
    move $a0, $s0
    jal  reduceRational

    # read second rational
    li   $v0, 4
    la   $a0, prompt_b_num
    syscall
    li   $v0, 5
    syscall
    sw   $v0, 0($s1)

    li   $v0, 4
    la   $a0, prompt_b_den
    syscall
    li   $v0, 5
    syscall
    beq  $v0, $zero, _err_zero
    sw   $v0, 4($s1)
    move $a0, $s1
    jal  reduceRational

    # add
    li   $v0, 4
    la   $a0, label_add
    syscall
    move $a0, $s0
    move $a1, $s1
    jal  addRational
    move $s2, $v0
    move $a0, $s2
    jal  printRational
    move $a0, $s2
    jal  printRationalFloat

    # subtract
    li   $v0, 4
    la   $a0, label_sub
    syscall
    move $a0, $s0
    move $a1, $s1
    jal  subRational
    move $s2, $v0
    move $a0, $s2
    jal  printRational
    move $a0, $s2
    jal  printRationalFloat

    # multiply
    li   $v0, 4
    la   $a0, label_mul
    syscall
    move $a0, $s0
    move $a1, $s1
    jal  mulRational
    move $s2, $v0
    move $a0, $s2
    jal  printRational
    move $a0, $s2
    jal  printRationalFloat

    # divide
    li   $v0, 4
    la   $a0, label_div
    syscall
    move $a0, $s0
    move $a1, $s1
    jal  divRational
    move $s2, $v0
    move $a0, $s2
    jal  printRational
    move $a0, $s2
    jal  printRationalFloat

    # exit
    li   $v0, 10
    syscall

_err_zero:
    li   $v0, 4
    la   $a0, err_zero_den
    syscall
    li   $v0, 10
    syscall
