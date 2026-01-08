#ifndef BLACKWELL_GPU_MAIN_H
#define BLACKWELL_GPU_MAIN_H

#include <stdint.h>
#include <stddef.h>

/* =======================
 * Memory-Mapped Base Addresses
 * ======================= */
#define GPU_BASE_ADDR          0x80000000UL
#define GPU_CTRL_BASE          (GPU_BASE_ADDR + 0x0000)
#define GPU_MMU_BASE           (GPU_BASE_ADDR + 0x1000)
#define GPU_L2_BASE            (GPU_BASE_ADDR + 0x2000)
#define GPU_SM_BASE            (GPU_BASE_ADDR + 0x4000)
#define GPU_DMA_BASE           (GPU_BASE_ADDR + 0x8000)
#define GPU_INT_BASE           (GPU_BASE_ADDR + 0xA000)

/* =======================
 * GPU Control Registers
 * ======================= */
#define GPU_CTRL_RESET         0x00
#define GPU_CTRL_STATUS        0x04
#define GPU_CTRL_START         0x08
#define GPU_CTRL_DONE          0x0C

/* =======================
 * MMU / TLB Registers
 * ======================= */
#define GPU_MMU_ENABLE         0x00
#define GPU_MMU_PGTABLE_BASE   0x04
#define GPU_MMU_FLUSH          0x08

/* =======================
 * L2 Cache Registers
 * ======================= */
#define GPU_L2_ENABLE          0x00
#define GPU_L2_FLUSH           0x04

/* =======================
 * SM Control Registers
 * ======================= */
#define GPU_SM_ENABLE          0x00
#define GPU_SM_WARP_CFG        0x04
#define GPU_SM_LAUNCH_CFG      0x08
#define GPU_SM_KERNEL_ADDR    0x0C
#define GPU_SM_ARG_ADDR       0x10
#define GPU_SM_GRID_DIM       0x14
#define GPU_SM_BLOCK_DIM      0x18
#define GPU_SM_START          0x1C
#define GPU_SM_DONE           0x20

/* =======================
 * DMA Registers
 * ======================= */
#define GPU_DMA_SRC            0x00
#define GPU_DMA_DST            0x04
#define GPU_DMA_LEN            0x08
#define GPU_DMA_START          0x0C
#define GPU_DMA_DONE           0x10

/* =======================
 * Interrupt Registers
 * ======================= */
#define GPU_INT_STATUS         0x00
#define GPU_INT_CLEAR          0x04

/* =======================
 * Kernel Descriptor
 * ======================= */
typedef struct {
    uint64_t entry_point;
    uint64_t arg_ptr;
    uint32_t grid_x;
    uint32_t block_x;
} gpu_kernel_desc_t;

/* =======================
 * Function Prototypes
 * ======================= */
void gpu_reset(void);
void gpu_init(void);
void gpu_mmu_init(uint64_t pgtable);
void gpu_l2_init(void);
void gpu_load_kernel(void *kernel_bin, size_t size, uint64_t gpu_addr);
void gpu_launch_kernel(gpu_kernel_desc_t *kdesc);
void gpu_wait(void);
void gpu_memcpy_to_device(void *dst_gpu, void *src_cpu, size_t size);
void gpu_memcpy_from_device(void *dst_cpu, void *src_gpu, size_t size);

#endif

