# 313 HW4 - MIPS Assembly

This folder contains three MIPS programs targeting MARS/QtSPIM on Windows:

- `complex.asm` — Complex numbers using a struct of two doubles with add, subtract, and print.
- `rational.asm` — Rational numbers using integer numerator/denominator with add/sub/mul/div, automatic reduction (GCD), printing as `A/B` and as floating-point.
- `bigInteger.asm` — Big integers up to 40 decimal digits, supporting add, subtract, comparisons, and interactive digit-by-digit input.

## How to run (Windows, PowerShell)

You can open these files in MARS (recommended) or QtSPIM.

1. Download MARS (jar) or QtSPIM.
2. Open each `.asm` file in the tool.
3. Assemble and Run. When prompted in the Console, provide input as instructed.

Notes on input:

- `complex.asm`: enter real and imaginary parts as doubles when prompted.
- `rational.asm`: enter numerators/denominators as integers (denominators must be non-zero). Results are reduced automatically. After each operation, both the fraction and the floating-point value will print on separate lines.
- `bigInteger.asm`: you'll be prompted for sign (0 for positive, 1 for negative), then digits one per line for each big integer. Enter `-1` to finish entering digits. Enter digits in normal left-to-right order (most significant first). For example, to enter 12345, input: 1, 2, 3, 4, 5, then `-1`.

If using QtSPIM, ensure that the syscall service supports the codes used here (print_int=1, print_string=4, print_char=11, read_int=5, print_double=3, read_double=7, sbrk=9, exit=10). MARS supports these.

## File structure and conventions

- Dynamic allocations use `sbrk` to create small structs on the heap.
- Doubles use `$f0/$f12` per MARS syscall conventions.
- We follow a simple calling convention: `$ra` saved in routines that call subroutines; volatile `$t*` registers used as scratch.
- Big integer digits are stored least-significant first to simplify arithmetic.

## Troubleshooting

- If double printing shows too many decimals, that's expected for MARS. Formatting control is limited. You can post-process if needed.
- If you get "Arithmetic overflow" on `rational.asm` for extreme values, remember operations are 32-bit; the assignment doesn't require arbitrary precision for rationals.
- In `bigInteger.asm`, maximum 40 digits are retained; extra inputs after 40 are ignored/stop reading.
