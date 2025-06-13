
# PTX ISA Reference – AGNI V1.0 GPU
**Author**: Naman Kalra  

**Project**: AGNI V1.0 – Blackwell-Inspired CUDA GPU  

**Copyright**: © 2025 IIT Tirupati

---

## Overview

This document summarizes the supported **PTX instruction set architecture** (ISA) implemented in the AGNI V1.0 GPU microarchitecture. Instructions are grouped by functional units to guide hardware decoding, dispatch, and execution unit design.

---

## Instruction Classification by Functional Unit

### 🔹 Integer Arithmetic Logic Unit (ALU)
These instructions are handled by the per-thread integer ALU.
| Instruction       | Description              |
|-------------------|--------------------------|
| `add.u32`         | Unsigned integer addition |
| `sub.u32`         | Unsigned integer subtraction |
| `mul.lo.u32`      | Low 32-bit unsigned multiply |
| `div.u32`         | Unsigned integer division |
| `and`, `or`, `xor`| Bitwise operations        |
| `shl`, `shr`      | Logical shifts            |
| `slt`, `seq`, `sne`| Comparisons (less, equal, not equal) |
| `popc`, `clz`, `brev` | Population count, count leading zeros, bit reverse |

### 🔹 Floating-Point Unit (FPU)
Handled via the custom `fpu_unit`, supports IEEE-754 arithmetic.
| Instruction       | Description              |
|-------------------|--------------------------|
| `add.f32`         | Floating-point add       |
| `sub.f32`         | Floating-point subtract  |
| `mul.f32`         | Floating-point multiply  |
| `div.f32`         | Floating-point divide    |
| `cvt.*`           | Type conversions         |

### 🔹 Load/Store Unit (LSU)
Performs memory access for global/shared/local/const spaces.
| Instruction       | Description              |
|-------------------|--------------------------|
| `ld.global.*`     | Load from global memory  |
| `st.global.*`     | Store to global memory   |
| `ld.shared.*`     | Load from shared memory  |
| `st.shared.*`     | Store to shared memory   |
| `ld.const.*`      | Load from constant memory |
| `st.local.*`      | Store to local memory    |

### 🔹 Special Function Unit (SFU)
Supports complex math functions, typically multi-cycle.
| Instruction       | Description              |
|-------------------|--------------------------|
| `sqrt`, `rsqrt`   | Square root, reciprocal sqrt |
| `rcp`             | Reciprocal               |
| `sin`, `cos`      | Trigonometric functions  |
| `lg2`, `ex2`      | Log base 2, exp base 2   |

### 🔹 Control & Branch
Handled by warp control and divergence logic (IPDOM).
| Instruction       | Description              |
|-------------------|--------------------------|
| `bra`             | Unconditional branch     |
| `call`, `ret`     | Function call/return     |
| `bar.sync`        | Barrier synchronization  |
| `vote`, `activemask` | Warp-wide control instructions |

### 🔹 MMA / Tensor Instructions (Optional)
If supported, routed to dedicated tensor units.
| Instruction       | Description              |
|-------------------|--------------------------|
| `wmma.load.*`     | Load fragment            |
| `wmma.mma.sync`   | Matrix multiply-accumulate |
| `wmma.store.*`    | Store fragment           |

---

## Decoder Signal Mapping

| Signal     | Triggered By Instructions                    |
|------------|-----------------------------------------------|
| `is_alu`   | `add.u32`, `sub.u32`, `mul.lo.u32`, etc.     |
| `is_fpu`   | `add.f32`, `div.f32`, etc.                   |
| `is_lsu`   | `ld.*`, `st.*`                               |
| `is_sfu`   | `sqrt`, `rsqrt`, `sin`, etc.                 |
| `is_ctrl`  | `bra`, `bar.sync`, `call`                    |
| `is_mma`   | `wmma.*`                                     |

---

## Notes
- Unsupported or invalid opcodes should be flagged in decode.
- Decoding logic should be pipeline-ready and consistent with `cuda_core`, `issue_unit`, `lsu_unit`, `fpu_unit`.
- Instructions are aligned with PTX ISA v1.4+ and tailored for AGNI V1.0 functional unit architecture.

---

**Document Version**: v1.0  
**Maintained by**: AGNI Compiler + Hardware Team  

