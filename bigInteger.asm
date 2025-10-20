# bigInteger.asm
# Problem 3: Big Integer (up to 40 digits) in MIPS (MARS/QtSPIM)
# Structure:
#   sign   (word)   1 for positive or zero, -1 for negative
#   len    (word)   number of digits used (0..40)
#   digits (40 bytes) ASCII digits '0'..'9' stored most-significant first or least? We choose least-significant first (little-endian by position) for easier arithmetic.
#   We will store digits as bytes, LSD at index 0.
# Total size: 4 + 4 + 40 = 48 bytes
# API:
#   - alloc_bigint() -> $v0 ptr
#   - zero_bigint($a0=ptr)
#   - normalize($a0=ptr) trims leading zeros, sets sign=1 if zero
#   - cmp($a0, $a1) -> $v0 {-1 if a<b, 0 if equal, 1 if a>b} considering sign
#   - addBig($a0, $a1) -> $v0 ptr result
#   - subBig($a0, $a1) -> $v0 ptr result (computes a-b)
#   - eq/ne/ge/geq/le/leq wrappers around cmp, returning 0/1 in $v0
#   - printBig($a0) prints optional '-' then digits MSB..LSB and newline; prints 0 for zero
# Input:
#   Read digits one at a time in a sentinel-controlled loop; we accept a sequence of chars: optional '-', digits; stop on non-digit (e.g., newline) or when 40 digits reached; For this assignment, we'll prompt repeatedly and accept -1 as sentinel per spec, but reading characters is cleaner. We'll implement per prompt: one digit per iteration, user enters -1 to end.

.data
prompt_a:    .asciiz "Enter digits for BigInt #1 (one per line, -1 to finish, optional first '-' for negative):\n"
prompt_b:    .asciiz "Enter digits for BigInt #2 (one per line, -1 to finish, optional first '-' for negative):\n"
prompt_digit:.asciiz "Digit (0-9 or -1 to end): "
prompt_sign: .asciiz "Sign (0 for +, 1 for -) or just enter digits starting with -: "
label_add:   .asciiz "A + B = "
label_sub:   .asciiz "A - B = "
label_eq:    .asciiz "A == B: "
label_ne:    .asciiz "A != B: "
label_ge:    .asciiz "A >  B: "
label_geq:   .asciiz "A >= B: "
label_le:    .asciiz "A <  B: "
label_leq:   .asciiz "A <= B: "
true_str:    .asciiz "true\n"
false_str:   .asciiz "false\n"
minus_char:  .byte 45
newline:     .byte 10

.text
.globl main

# alloc_bigint -> $v0 ptr 48 bytes
alloc_bigint:
    li  $v0, 9
    li  $a0, 48
    syscall
    jr  $ra

# zero_bigint($a0)
zero_bigint:
    sw  $zero, 0($a0)   # sign = 0, later normalize will make 1
    sw  $zero, 4($a0)   # len = 0
    addiu $t2, $a0, 8   # base of digits
    li  $t0, 0
    li  $t1, 40
zb_loop:
    beq $t0, $t1, zb_done
    addu $t3, $t2, $t0
    sb  $zero, 0($t3)
    addiu $t0, $t0, 1
    j   zb_loop
zb_done:
    jr  $ra

# normalize($a0)
# ensure 0 represented as len=1, digit[0]=0, sign=1; otherwise trim length to highest non-zero digit and sign!=0
normalize:
    lw  $t0, 4($a0)      # len
    blez $t0, norm_zero
    addiu $t0, $t0, -1   # t0 = len-1 index of highest position
norm_trim_loop:
    bltz $t0, norm_zero
    lb  $t1, 8($a0)($t0)
    bne $t1, $zero, norm_set_sign
    addiu $t0, $t0, -1
    j   norm_trim_loop
norm_set_sign:
    addiu $t0, $t0, 1
    sw  $t0, 4($a0)      # new len
    lw  $t2, 0($a0)
    beq $t2, $zero, norm_sign_pos
    j   norm_done
norm_sign_pos:
    li  $t2, 1
    sw  $t2, 0($a0)
    j   norm_done
norm_zero:
    li  $t3, 1
    sw  $t3, 4($a0)      # len=1
    sb  $zero, 8($a0)    # digit0=0
    li  $t3, 1
    sw  $t3, 0($a0)      # sign=+1
norm_done:
    jr  $ra

# compare magnitudes |a| vs |b|; $a0 ptr a, $a1 ptr b; returns $v0 -1/0/1
cmp_abs:
    lw  $t0, 4($a0)
    lw  $t1, 4($a1)
    blt $t0, $t1, ca_less
    bgt $t0, $t1, ca_greater
    # same length, compare digits from high to low
    addiu $t2, $t0, -1
    addiu $t5, $a0, 8    # base a
    addiu $t6, $a1, 8    # base b
ca_loop:
    bltz $t2, ca_equal
    addu $t7, $t5, $t2
    lb   $t3, 0($t7)
    addu $t7, $t6, $t2
    lb   $t4, 0($t7)
    blt  $t3, $t4, ca_less
    bgt  $t3, $t4, ca_greater
    addiu $t2, $t2, -1
    j    ca_loop
ca_equal:
    li   $v0, 0
    jr   $ra
ca_less:
    li   $v0, -1
    jr   $ra
ca_greater:
    li   $v0, 1
    jr   $ra

# cmp signed: $v0 -1/0/1
cmp:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    lw    $t0, 0($a0)   # sign a
    lw    $t1, 0($a1)   # sign b
    bne   $t0, $t1, cmp_sign
    # same sign -> compare abs; if negative, reverse result
    move  $t2, $a0
    move  $t3, $a1
    jal   cmp_abs
    move  $t4, $v0
    beq   $t0, $zero, cmp_same_sign_pos  # sign 0 treated as pos
    bgtz  $t0, cmp_same_sign_pos         # +1
    # negative: invert result
    sub   $v0, $zero, $t4
    j     cmp_done
cmp_same_sign_pos:
    move  $v0, $t4
    j     cmp_done
cmp_sign:
    # signs differ: treat zero as positive
    bltz  $t0, cmp_a_neg
    # a is positive or zero
    li    $v0, 1
    j     cmp_done
cmp_a_pos:
    li    $v0, 1
    j     cmp_done
cmp_a_neg:
    li    $v0, -1
cmp_done:
    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    jr    $ra

# add magnitudes |a|+|b| into result; $a0 ptr a, $a1 ptr b; $v0 ptr new bigint, sign not set
add_abs:
    addiu $sp, $sp, -24
    sw    $ra, 20($sp)
    sw    $a0, 16($sp)
    sw    $a1, 12($sp)

    jal   alloc_bigint
    move  $t0, $v0        # res ptr
    li    $t6, 0          # carry

    # reload a,b
    lw    $t2, 16($sp)
    lw    $t3, 12($sp)
    lw    $t4, 4($t2)     # len a
    lw    $t5, 4($t3)     # len b
    addiu $t10, $t2, 8    # base a
    addiu $t11, $t3, 8    # base b
    addiu $t12, $t0, 8    # base res
    move  $t7, $zero      # i

add_abs_loop:
    # done if i>=len a and i>=len b and carry==0
    slt   $t8, $t7, $t4   # i < len a
    slt   $t9, $t7, $t5   # i < len b
    or    $t13, $t8, $t9  # any digits left?
    bne   $t13, $zero, add_abs_calc
    beq   $t6, $zero, add_abs_done

add_abs_calc:
    # da
    beq   $t8, $zero, add_abs_da_zero
    addu  $t14, $t10, $t7
    lb    $t15, 0($t14)
    j     add_abs_da_got
add_abs_da_zero:
    move  $t15, $zero
add_abs_da_got:
    # db
    beq   $t9, $zero, add_abs_db_zero
    addu  $t14, $t11, $t7
    lb    $t16, 0($t14)
    j     add_abs_db_got
add_abs_db_zero:
    move  $t16, $zero
add_abs_db_got:
    addu  $t17, $t15, $t16   # da+db
    addu  $t17, $t17, $t6    # +carry
    li    $t18, 10
    div   $t17, $t18
    mfhi  $t19               # remainder = digit
    mflo  $t6                # carry = quotient
    addu  $t14, $t12, $t7
    sb    $t19, 0($t14)
    addiu $t7, $t7, 1
    j     add_abs_loop

add_abs_done:
    sw    $t7, 4($t0)        # len
    move  $v0, $t0

    lw    $ra, 20($sp)
    addiu $sp, $sp, 24
    jr    $ra

# subtract magnitudes |a|-|b| assuming |a|>=|b|, result non-negative
sub_abs:
    addiu $sp, $sp, -24
    sw    $ra, 20($sp)
    sw    $a0, 16($sp)
    sw    $a1, 12($sp)

    jal   alloc_bigint
    move  $t0, $v0        # res

    # reload
    lw    $t2, 16($sp)
    lw    $t3, 12($sp)
    lw    $t4, 4($t2)
    lw    $t5, 4($t3)
    addiu $t10, $t2, 8    # base a
    addiu $t11, $t3, 8    # base b
    addiu $t12, $t0, 8    # base res
    move  $t7, $zero      # i
    li    $t6, 0          # borrow

sub_abs_loop:
    # if i>=len a and i>=len b -> done
    slt   $t8, $t7, $t4   # i < len a
    slt   $t9, $t7, $t5   # i < len b
    or    $t13, $t8, $t9
    beq   $t13, $zero, sub_abs_done

    # da
    beq   $t8, $zero, sub_abs_da_zero
    addu  $t14, $t10, $t7
    lb    $t8, 0($t14)
    j     sub_abs_da_got
sub_abs_da_zero:
    move  $t8, $zero
sub_abs_da_got:
    # db
    beq   $t9, $zero, sub_abs_db_zero
    addu  $t14, $t11, $t7
    lb    $t9, 0($t14)
    j     sub_abs_db_got
sub_abs_db_zero:
    move  $t9, $zero
sub_abs_db_got:
    subu  $t8, $t8, $t6   # da - borrow
    bltz  $t8, sub_abs_fix
sub_abs_after_borrow:
    subu  $t8, $t8, $t9
    bltz  $t8, sub_abs_borrow
    move  $t6, $zero
    j     sub_abs_store
sub_abs_borrow:
    addu  $t8, $t8, 10
    subu  $t8, $t8, $t9
    li    $t6, 1
sub_abs_store:
    addu  $t14, $t12, $t7
    sb    $t8, 0($t14)
    addiu $t7, $t7, 1
    j     sub_abs_loop
sub_abs_fix:
    addu  $t8, $t8, 10
    li    $t6, 1
    j     sub_abs_after_borrow

sub_abs_done:
    # set length to highest non-zero digit
    addiu $t7, $t7, -1
    bltz  $t7, sub_abs_zero
sub_abs_trim:
    bltz  $t7, sub_abs_zero
    addu  $t14, $t12, $t7
    lb    $t8, 0($t14)
    bne   $t8, $zero, sub_abs_setlen
    addiu $t7, $t7, -1
    j     sub_abs_trim
sub_abs_zero:
    li    $t7, 1
    sb    $zero, 8($t0)
sub_abs_setlen:
    addiu $t7, $t7, 1
    sw    $t7, 4($t0)
    move  $v0, $t0

    lw    $ra, 20($sp)
    addiu $sp, $sp, 24
    jr    $ra

# addBig: handle signs
addBig:
    addiu $sp, $sp, -24
    sw    $ra, 20($sp)
    sw    $a0, 16($sp)
    sw    $a1, 12($sp)

    lw    $t0, 0($a0)
    lw    $t1, 0($a1)
    beq   $t0, $t1, add_same_sign
    # different signs -> subtract magnitudes
    # If |a|>=|b| result sign = sign(a) else sign=sign(b)
    jal   cmp_abs
    move  $t2, $v0
    bltz  $t2, add_diff_sign_b_greater
    # |a|>=|b|
    lw    $a0, 16($sp)
    lw    $a1, 12($sp)
    jal   sub_abs
    move  $t3, $v0
    lw    $t4, 16($sp)
    lw    $t5, 0($t4)
    sw    $t5, 0($t3)
    move  $v0, $t3
    j     add_end
add_diff_sign_b_greater:
    lw    $a0, 12($sp)
    lw    $a1, 16($sp)
    jal   sub_abs
    move  $t3, $v0
    lw    $t4, 12($sp)
    lw    $t5, 0($t4)
    sw    $t5, 0($t3)
    move  $v0, $t3
    j     add_end
add_same_sign:
    lw    $a0, 16($sp)
    lw    $a1, 12($sp)
    jal   add_abs
    move  $t3, $v0
    lw    $t4, 16($sp)
    lw    $t5, 0($t4)
    beq   $t5, $zero, add_sign_pos
    sw    $t5, 0($t3)
    j     add_norm
add_sign_pos:
    li    $t6, 1
    sw    $t6, 0($t3)
add_norm:
    move  $a0, $t3
    jal   normalize
    move  $v0, $t3
add_end:
    # Ensure normalize for diff-sign path too
    move  $a0, $v0
    jal   normalize
    lw    $ra, 20($sp)
    addiu $sp, $sp, 24
    jr    $ra

# subBig: compute a - b = a + (-b)
subBig:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    # allocate temp copy of b with flipped sign
    jal   alloc_bigint
    move  $t0, $v0
    # copy b
    move  $t1, $a1
    lw    $t2, 0($t1)
    lw    $t3, 4($t1)
    sw    $t2, 0($t0)
    sw    $t3, 4($t0)
    li    $t4, 0
    addiu $t6, $t1, 8     # base b
    addiu $t7, $t0, 8     # base tmp
sub_copy_loop:
    beq   $t4, $t3, sub_copy_done
    addu  $t8, $t6, $t4
    lb    $t5, 0($t8)
    addu  $t9, $t7, $t4
    sb    $t5, 0($t9)
    addiu $t4, $t4, 1
    j     sub_copy_loop
sub_copy_done:
    # flip sign
    lw    $t2, 0($t0)
    beq   $t2, $zero, sub_sign_pos
    subu  $t2, $zero, $t2
    sw    $t2, 0($t0)
    j     sub_call
sub_sign_pos:
    li    $t2, -1
    sw    $t2, 0($t0)
sub_call:
    move  $a1, $t0
    jal   addBig
    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    jr    $ra

# predicates using cmp; return 1 true, 0 false
pred_eq:
    jal  cmp
    seq  $v0, $v0, $zero
    jr   $ra
pred_ne:
    jal  cmp
    sne  $v0, $v0, $zero
    jr   $ra
pred_ge:
    jal  cmp
    sgt  $v0, $v0, $zero
    jr   $ra
pred_geq:
    jal  cmp
    sge  $v0, $v0, $zero
    jr   $ra
pred_le:
    jal  cmp
    slt  $v0, $v0, $zero
    jr   $ra
pred_leq:
    jal  cmp
    sle  $v0, $v0, $zero
    jr   $ra

# Assignment-specified API wrappers
Add:
    jal addBig
    jr  $ra
Subtract:
    jal subBig
    jr  $ra
Eq:
    jal pred_eq
    jr  $ra
Ne:
    jal pred_ne
    jr  $ra
Ge:
    jal pred_ge
    jr  $ra
Geq:
    jal pred_geq
    jr  $ra
Le:
    jal pred_le
    jr  $ra
Leq:
    jal pred_leq
    jr  $ra

# printBig($a0)
printBig:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    lw    $t0, 0($a0)
    lw    $t1, 4($a0)
    # zero?
    beq   $t1, $zero, pb_print_zero
    # sign
    bltz  $t0, pb_minus
    bgtz  $t0, pb_digits
    # sign==0 treat as +
    j     pb_digits
pb_minus:
    li    $v0, 11
    li    $a0, 45
    syscall
pb_digits:
    addiu $t2, $t1, -1
    addiu $t5, $a0, 8
pb_loop:
    bltz  $t2, pb_nl
    addu  $t6, $t5, $t2
    lb    $t3, 0($t6)
    addiu $t3, $t3, 48
    li    $v0, 11
    move  $a0, $t3
    syscall
    addiu $t2, $t2, -1
    j     pb_loop
pb_nl:
    li    $v0, 11
    li    $a0, 10
    syscall
    j     pb_done
pb_print_zero:
    li    $v0, 11
    li    $a0, 48
    syscall
    li    $v0, 11
    li    $a0, 10
    syscall
pb_done:
    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    jr    $ra

# readBigInteractive($a0=ptr) reads digits with sentinel -1; first input may be - (ASCII '-')
readBigInteractive:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    move  $t0, $a0
    jal   zero_bigint
    move  $a0, $t0
    # ask for sign 0=+, 1=-
    li    $v0, 4
    la    $a0, prompt_sign
    syscall
    li    $v0, 5
    syscall
    beq   $v0, $zero, rbi_sign_pos
    li    $t1, -1
    sw    $t1, 0($t0)
    j     rbi_sign_set
rbi_sign_pos:
    li    $t1, 1
    sw    $t1, 0($t0)
rbi_sign_set:
    li    $t2, 0          # len
    addiu $t20, $t0, 8    # base digits

rbi_loop:
    # prompt digit
    li    $v0, 4
    la    $a0, prompt_digit
    syscall

    li    $v0, 5          # read_int
    syscall
    move  $t3, $v0
    li    $t4, -1
    beq   $t3, $t4, rbi_end
    # if t3 between 0 and 9
    bltz  $t3, rbi_loop
    li    $t4, 9
    bgt   $t3, $t4, rbi_loop
    # accept if capacity
    li    $t4, 40
    bge   $t2, $t4, rbi_end
    # shift existing digits up by one to keep MSD-first input -> LSD-first storage
    addiu $t5, $t2, -1
rbi_shift_loop:
    bltz  $t5, rbi_place
    addu  $t6, $t20, $t5
    lb    $t7, 0($t6)
    addiu $t6, $t6, 1
    sb    $t7, 0($t6)
    addiu $t5, $t5, -1
    j     rbi_shift_loop
rbi_place:
    sb    $t3, 0($t20)    # place at index 0
    addiu $t2, $t2, 1
    j     rbi_loop

rbi_end:
    sw    $t2, 4($t0)
    move  $a0, $t0
    jal   normalize
    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    jr    $ra

# setSignFromFirstChar($a0=ptr, $a1=int) if $a1 is '-', set sign=-1
setSignFromFirstChar:
    beq  $a1, $zero, ssfc_done
    li   $t0, 45
    bne  $a1, $t0, ssfc_done
    li   $t1, -1
    sw   $t1, 0($a0)
ssfc_done:
    jr   $ra

main:
    # allocate A and B
    jal   alloc_bigint
    move  $s0, $v0
    jal   alloc_bigint
    move  $s1, $v0

    # Prompt and read A
    li   $v0, 4
    la   $a0, prompt_a
    syscall
    move $a0, $s0
    jal  readBigInteractive

    # Prompt and read B
    li   $v0, 4
    la   $a0, prompt_b
    syscall
    move $a0, $s1
    jal  readBigInteractive

    # A + B
    li   $v0, 4
    la   $a0, label_add
    syscall
    move $a0, $s0
    move $a1, $s1
    jal  addBig
    move $a0, $v0
    jal  printBig

    # A - B
    li   $v0, 4
    la   $a0, label_sub
    syscall
    move $a0, $s0
    move $a1, $s1
    jal  subBig
    move $a0, $v0
    jal  printBig

    # eq
    li   $v0, 4
    la   $a0, label_eq
    syscall
    move $a0, $s0
    move $a1, $s1
    jal  pred_eq
    beq  $v0, $zero, print_false_eq
    li   $v0, 4
    la   $a0, true_str
    syscall
    j    after_eq
print_false_eq:
    li   $v0, 4
    la   $a0, false_str
    syscall
after_eq:

    # ne
    li   $v0, 4
    la   $a0, label_ne
    syscall
    move $a0, $s0
    move $a1, $s1
    jal  pred_ne
    beq  $v0, $zero, print_false_ne
    li   $v0, 4
    la   $a0, true_str
    syscall
    j    after_ne
print_false_ne:
    li   $v0, 4
    la   $a0, false_str
    syscall
after_ne:

    # ge
    li   $v0, 4
    la   $a0, label_ge
    syscall
    move $a0, $s0
    move $a1, $s1
    # Ge is strictly greater-than per spec
    jal  pred_ge
    beq  $v0, $zero, print_false_ge
    li   $v0, 4
    la   $a0, true_str
    syscall
    j    after_ge
print_false_ge:
    li   $v0, 4
    la   $a0, false_str
    syscall
after_ge:

    # geq
    li   $v0, 4
    la   $a0, label_geq
    syscall
    move $a0, $s0
    move $a1, $s1
    jal  pred_geq
    beq  $v0, $zero, print_false_geq
    li   $v0, 4
    la   $a0, true_str
    syscall
    j    after_geq
print_false_geq:
    li   $v0, 4
    la   $a0, false_str
    syscall
after_geq:

    # le
    li   $v0, 4
    la   $a0, label_le
    syscall
    move $a0, $s0
    move $a1, $s1
    jal  pred_le
    beq  $v0, $zero, print_false_le
    li   $v0, 4
    la   $a0, true_str
    syscall
    j    after_le
print_false_le:
    li   $v0, 4
    la   $a0, false_str
    syscall
after_le:

    # leq
    li   $v0, 4
    la   $a0, label_leq
    syscall
    move $a0, $s0
    move $a1, $s1
    jal  pred_leq
    beq  $v0, $zero, print_false_leq
    li   $v0, 4
    la   $a0, true_str
    syscall
    j    after_leq
print_false_leq:
    li   $v0, 4
    la   $a0, false_str
    syscall
after_leq:

    # Exit
    li   $v0, 10
    syscall
