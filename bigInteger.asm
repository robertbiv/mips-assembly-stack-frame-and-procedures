# bigInteger.asm
# big integer operations (up to 40 digits)

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

j main

# allocate 48 bytes
alloc_bigint:
    li  $v0, 9
    li  $a0, 48
    syscall
    jr  $ra

# set to zero
zero_bigint:
    sw  $zero, 0($a0)   
    sw  $zero, 4($a0)   
    addiu $t2, $a0, 8   
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

# trim leading zeros
normalize:
    lw  $t0, 4($a0)
    blez $t0, norm_zero
    addiu $t0, $t0, -1
    addiu $t9, $a0, 8
norm_trim_loop:
    bltz $t0, norm_zero
    addu $t8, $t9, $t0
    lb  $t1, 0($t8)
    bne $t1, $zero, norm_set_sign
    addiu $t0, $t0, -1
    j   norm_trim_loop
norm_set_sign:
    addiu $t0, $t0, 1
    sw  $t0, 4($a0)
    lw  $t2, 0($a0)
    beq $t2, $zero, norm_sign_pos
    j   norm_done
norm_sign_pos:
    li  $t2, 1
    sw  $t2, 0($a0)
    j   norm_done
norm_zero:
    li  $t3, 1
    sw  $t3, 4($a0)
    sb  $zero, 8($a0)
    li  $t3, 1
    sw  $t3, 0($a0)
norm_done:
    jr  $ra

# compare abs values
cmp_abs:
    lw  $t0, 4($a0)
    lw  $t1, 4($a1)
    slt $t8, $t0, $t1
    bne $t8, $zero, ca_less
    slt $t8, $t1, $t0
    bne $t8, $zero, ca_greater
    addiu $t2, $t0, -1
    addiu $t5, $a0, 8
    addiu $t6, $a1, 8
ca_loop:
    bltz $t2, ca_equal
    addu $t7, $t5, $t2
    lb   $t3, 0($t7)
    addu $t7, $t6, $t2
    lb   $t4, 0($t7)
    slt  $t8, $t3, $t4
    bne  $t8, $zero, ca_less
    slt  $t8, $t4, $t3
    bne  $t8, $zero, ca_greater
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

# compare signed
cmp:
    addiu $sp, $sp, -20
    sw    $ra, 16($sp)
    sw    $a0, 12($sp)
    sw    $a1, 8($sp)
    
    lw    $a0, 12($sp)
    lw    $a1, 8($sp)
    lw    $t0, 0($a0)
    lw    $t1, 0($a1)
    bne   $t0, $t1, cmp_sign
    
    lw    $a0, 12($sp)
    lw    $a1, 8($sp)
    jal   cmp_abs
    move  $t4, $v0
    
    lw    $a0, 12($sp)
    lw    $t0, 0($a0)
    beq   $t0, $zero, cmp_same_sign_pos
    bgtz  $t0, cmp_same_sign_pos
    subu  $v0, $zero, $t4
    j     cmp_done
cmp_same_sign_pos:
    move  $v0, $t4
    j     cmp_done
cmp_sign:
    bltz  $t0, cmp_a_neg
    li    $v0, 1
    j     cmp_done
cmp_a_neg:
    li    $v0, -1
cmp_done:
    lw    $ra, 16($sp)
    addiu $sp, $sp, 20
    jr    $ra

add_abs:
    addiu $sp, $sp, -48
    sw    $ra, 44($sp)
    sw    $s1, 40($sp)
    sw    $s2, 36($sp)
    sw    $s3, 32($sp)
    sw    $s4, 28($sp)
    sw    $s5, 24($sp)
    sw    $s6, 20($sp)
    sw    $s7, 16($sp)
    sw    $a0, 12($sp)
    sw    $a1, 8($sp)

    jal   alloc_bigint
    sw    $v0, 4($sp)
    li    $t6, 0

    lw    $a0, 12($sp)
    lw    $a1, 8($sp)
    lw    $t4, 4($a0)
    lw    $t5, 4($a1)
    addiu $s2, $a0, 8
    addiu $s3, $a1, 8
    lw    $t0, 4($sp)
    addiu $s4, $t0, 8
    move  $t7, $zero

add_abs_loop:
    slt   $t8, $t7, $t4
    slt   $t9, $t7, $t5
    or    $s1, $t8, $t9
    bne   $s1, $zero, add_abs_calc
    beq   $t6, $zero, add_abs_done

add_abs_calc:
    beq   $t8, $zero, add_abs_da_zero
    addu  $t1, $s2, $t7
    lb    $t2, 0($t1)
    j     add_abs_da_got
add_abs_da_zero:
    move  $t2, $zero
add_abs_da_got:
    beq   $t9, $zero, add_abs_db_zero
    addu  $t1, $s3, $t7
    lb    $t3, 0($t1)
    j     add_abs_db_got
add_abs_db_zero:
    move  $t3, $zero
add_abs_db_got:
    addu  $s5, $t2, $t3
    addu  $s5, $s5, $t6
    li    $s6, 10
    div   $s5, $s6
    mfhi  $s7
    mflo  $t6
    addu  $t1, $s4, $t7
    sb    $s7, 0($t1)
    addiu $t7, $t7, 1
    j     add_abs_loop

add_abs_done:
    lw    $t0, 4($sp)
    sw    $t7, 4($t0)
    move  $v0, $t0

    lw    $s7, 16($sp)
    lw    $s6, 20($sp)
    lw    $s5, 24($sp)
    lw    $s4, 28($sp)
    lw    $s3, 32($sp)
    lw    $s2, 36($sp)
    lw    $s1, 40($sp)
    lw    $ra, 44($sp)
    addiu $sp, $sp, 48
    jr    $ra

sub_abs:
    addiu $sp, $sp, -44
    sw    $ra, 40($sp)
    sw    $s1, 36($sp)
    sw    $s2, 32($sp)
    sw    $s3, 28($sp)
    sw    $s4, 24($sp)
    sw    $a0, 20($sp)
    sw    $a1, 16($sp)

    jal   alloc_bigint
    sw    $v0, 12($sp)

    lw    $a0, 20($sp)
    lw    $a1, 16($sp)
    lw    $t4, 4($a0)
    lw    $t5, 4($a1)
    addiu $s2, $a0, 8
    addiu $s3, $a1, 8
    lw    $t0, 12($sp)
    addiu $s4, $t0, 8
    move  $t7, $zero
    li    $t6, 0

sub_abs_loop:
    slt   $t8, $t7, $t4
    slt   $t9, $t7, $t5
    or    $s1, $t8, $t9
    beq   $s1, $zero, sub_abs_done

    beq   $t8, $zero, sub_abs_da_zero
    addu  $t1, $s2, $t7
    lb    $t8, 0($t1)
    j     sub_abs_da_got
sub_abs_da_zero:
    move  $t8, $zero
sub_abs_da_got:
    beq   $t9, $zero, sub_abs_db_zero
    addu  $t1, $s3, $t7
    lb    $t9, 0($t1)
    j     sub_abs_db_got
sub_abs_db_zero:
    move  $t9, $zero
sub_abs_db_got:
    subu  $t8, $t8, $t6
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
    addu  $t1, $s4, $t7
    sb    $t8, 0($t1)
    addiu $t7, $t7, 1
    j     sub_abs_loop
sub_abs_fix:
    addu  $t8, $t8, 10
    li    $t6, 1
    j     sub_abs_after_borrow

sub_abs_done:
    addiu $t7, $t7, -1
    bltz  $t7, sub_abs_zero
    lw    $t0, 12($sp)
    addiu $s4, $t0, 8
sub_abs_trim:
    bltz  $t7, sub_abs_zero
    addu  $t1, $s4, $t7
    lb    $t8, 0($t1)
    bne   $t8, $zero, sub_abs_setlen
    addiu $t7, $t7, -1
    j     sub_abs_trim
sub_abs_zero:
    li    $t7, 1
    lw    $t0, 12($sp)
    sb    $zero, 8($t0)
sub_abs_setlen:
    addiu $t7, $t7, 1
    lw    $t0, 12($sp)
    sw    $t7, 4($t0)
    move  $v0, $t0

    lw    $s4, 24($sp)
    lw    $s3, 28($sp)
    lw    $s2, 32($sp)
    lw    $s1, 36($sp)
    lw    $ra, 40($sp)
    addiu $sp, $sp, 44
    jr    $ra

addBig:
    addiu $sp, $sp, -24
    sw    $ra, 20($sp)
    sw    $a0, 16($sp)
    sw    $a1, 12($sp)

    lw    $t0, 0($a0)
    lw    $t1, 0($a1)
    beq   $t0, $t1, add_same_sign
    lw    $a0, 16($sp)
    lw    $a1, 12($sp)
    jal   cmp_abs
    move  $t2, $v0
    bltz  $t2, add_diff_sign_b_greater
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
    move  $a0, $v0
    jal   normalize
    lw    $ra, 20($sp)
    addiu $sp, $sp, 24
    jr    $ra

subBig:
    addiu $sp, $sp, -20
    sw    $ra, 16($sp)
    sw    $a0, 12($sp)
    sw    $a1, 8($sp)
    
    jal   alloc_bigint
    sw    $v0, 4($sp)
    
    lw    $a1, 8($sp)
    lw    $t2, 0($a1)
    lw    $t3, 4($a1)
    lw    $t0, 4($sp)
    sw    $t2, 0($t0)
    sw    $t3, 4($t0)
    
    li    $t4, 0
    addiu $t6, $a1, 8
    addiu $t7, $t0, 8
sub_copy_loop:
    beq   $t4, $t3, sub_copy_done
    addu  $t8, $t6, $t4
    lb    $t5, 0($t8)
    addu  $t9, $t7, $t4
    sb    $t5, 0($t9)
    addiu $t4, $t4, 1
    j     sub_copy_loop
sub_copy_done:
    lw    $t0, 4($sp)
    lw    $t2, 0($t0)
    beq   $t2, $zero, sub_sign_pos
    subu  $t2, $zero, $t2
    sw    $t2, 0($t0)
    j     sub_call
sub_sign_pos:
    li    $t2, -1
    sw    $t2, 0($t0)
sub_call:
    lw    $a0, 12($sp)
    lw    $a1, 4($sp)
    jal   addBig
    
    lw    $ra, 16($sp)
    addiu $sp, $sp, 20
    jr    $ra

pred_eq:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    sw    $a0, 8($sp)
    sw    $a1, 4($sp)
    jal   cmp
    lw    $a1, 4($sp)
    lw    $a0, 8($sp)
    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    beq   $v0, $zero, peq_true
    move  $v0, $zero
    jr    $ra
peq_true:
    li    $v0, 1
    jr    $ra

pred_ne:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    sw    $a0, 8($sp)
    sw    $a1, 4($sp)
    jal   cmp
    lw    $a1, 4($sp)
    lw    $a0, 8($sp)
    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    bne   $v0, $zero, pne_true
    move  $v0, $zero
    jr    $ra
pne_true:
    li    $v0, 1
    jr    $ra

pred_ge:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    sw    $a0, 8($sp)
    sw    $a1, 4($sp)
    jal   cmp
    lw    $a1, 4($sp)
    lw    $a0, 8($sp)
    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    bgtz  $v0, pge_true
    move  $v0, $zero
    jr    $ra
pge_true:
    li    $v0, 1
    jr    $ra

pred_geq:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    sw    $a0, 8($sp)
    sw    $a1, 4($sp)
    jal   cmp
    lw    $a1, 4($sp)
    lw    $a0, 8($sp)
    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    bgez  $v0, pgeq_true
    move  $v0, $zero
    jr    $ra
pgeq_true:
    li    $v0, 1
    jr    $ra

pred_le:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    sw    $a0, 8($sp)
    sw    $a1, 4($sp)
    jal   cmp
    lw    $a1, 4($sp)
    lw    $a0, 8($sp)
    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    bltz  $v0, ple_true
    move  $v0, $zero
    jr    $ra
ple_true:
    li    $v0, 1
    jr    $ra

pred_leq:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    sw    $a0, 8($sp)
    sw    $a1, 4($sp)
    jal   cmp
    lw    $a1, 4($sp)
    lw    $a0, 8($sp)
    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    blez  $v0, pleq_true
    move  $v0, $zero
    jr    $ra
pleq_true:
    li    $v0, 1
    jr    $ra

# wrappers for assignment spec
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

# print big integer
printBig:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    sw    $a0, 8($sp)
    
    lw    $a0, 8($sp)
    lw    $t0, 0($a0)
    lw    $t1, 4($a0)
    beq   $t1, $zero, pb_print_zero
    bltz  $t0, pb_minus
    bgtz  $t0, pb_digits
    j     pb_digits
pb_minus:
    li    $v0, 11
    li    $a0, 45
    syscall
pb_digits:
    lw    $a0, 8($sp)
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

readBigInteractive:
    addiu $sp, $sp, -20
    sw    $ra, 16($sp)
    sw    $s0, 12($sp)
    sw    $s1, 8($sp)
    
    move  $s0, $a0
    jal   zero_bigint
    
    li    $v0, 4
    la    $a0, prompt_sign
    syscall
    li    $v0, 5
    syscall
    move  $t0, $v0
    beq   $t0, $zero, rbi_sign_pos
    li    $t2, 1
    bne   $t0, $t2, rbi_sign_pos
    li    $t1, -1
    sw    $t1, 0($s0)
    j     rbi_sign_set
rbi_sign_pos:
    li    $t1, 1
    sw    $t1, 0($s0)
rbi_sign_set:
    li    $s1, 0
    addiu $t8, $s0, 8
    sw    $t8, 4($sp)

rbi_loop:
    li    $v0, 4
    la    $a0, prompt_digit
    syscall

    li    $v0, 5
    syscall
    move  $t3, $v0
    li    $t4, -1
    beq   $t3, $t4, rbi_end
    bltz  $t3, rbi_loop
    li    $t4, 9
    slt   $t8, $t4, $t3
    bne   $t8, $zero, rbi_loop
    li    $t4, 40
    slt   $t8, $t4, $s1
    beq   $t8, $zero, rbi_cont
    j     rbi_end
rbi_cont:
    
    addiu $t5, $s1, -1
    lw    $t8, 4($sp)
rbi_shift_loop:
    bltz  $t5, rbi_place
    addu  $t6, $t8, $t5
    lb    $t7, 0($t6)
    addiu $t6, $t6, 1
    sb    $t7, 0($t6)
    addiu $t5, $t5, -1
    j     rbi_shift_loop
rbi_place:
    lw    $t8, 4($sp)
    sb    $t3, 0($t8)
    addiu $s1, $s1, 1
    j     rbi_loop

rbi_end:
    sw    $s1, 4($s0)
    move  $a0, $s0
    jal   normalize
    
    lw    $s1, 8($sp)
    lw    $s0, 12($sp)
    lw    $ra, 16($sp)
    addiu $sp, $sp, 20
    jr    $ra

# not used but included for completeness
setSignFromFirstChar:
    beq  $a1, $zero, ssfc_done
    li   $t0, 45
    bne  $a1, $t0, ssfc_done
    li   $t1, -1
    sw   $t1, 0($a0)
ssfc_done:
    jr   $ra

main:
    jal   alloc_bigint
    move  $s0, $v0
    jal   alloc_bigint
    move  $s1, $v0

    li   $v0, 4
    la   $a0, prompt_a
    syscall
    move $a0, $s0
    jal  readBigInteractive

    li   $v0, 4
    la   $a0, prompt_b
    syscall
    move $a0, $s1
    jal  readBigInteractive
    li   $v0, 4
    la   $a0, label_add
    syscall
    move $a0, $s0
    move $a1, $s1
    jal  addBig
    move $a0, $v0
    jal  printBig

    li   $v0, 4
    la   $a0, label_sub
    syscall
    move $a0, $s0
    move $a1, $s1
    jal  subBig
    move $a0, $v0
    jal  printBig

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

    # exit
    li   $v0, 10
    syscall
