#include "main.h"

/* =======================
 * Low-level MMIO helpers
 * ======================= */
static inline void mmio_write(uint64_t addr, uint32_t value) {
    volatile uint32_t *ptr = (volatile uint32_t *)addr;
    *ptr = value;
}

static inline uint32_t mmio_read(uint64_t addr) {
    volatile uint32_t *ptr = (volatile uint32_t *)addr;
    return *ptr;
}

/* =======================
 * GPU Reset
 * ======================= */
void gpu_reset(void) {
    mmio_write(GPU_CTRL_BASE + GPU_CTRL_RESET, 1);
    for (volatile int i = 0; i < 10000; i++);
    mmio_write(GPU_CTRL_BASE + GPU_CTRL_RESET, 0);
}

/* =======================
 * MMU Initialization
 * ======================= */
void gpu_mmu_init(uint64_t pgtable) {
    mmio_write(GPU_MMU_BASE + GPU_MMU_PGTABLE_BASE, (uint32_t)pgtable);
    mmio_write(GPU_MMU_BASE + GPU_MMU_ENABLE, 1);
    mmio_write(GPU_MMU_BASE + GPU_MMU_FLUSH, 1);
}

/* =======================
 * L2 Cache Initialization
 * ======================= */
void gpu_l2_init(void) {
    mmio_write(GPU_L2_BASE + GPU_L2_ENABLE, 1);
    mmio_write(GPU_L2_BASE + GPU_L2_FLUSH, 1);
}

/* =======================
 * Global GPU Init
 * ======================= */
void gpu_init(void) {
    gpu_reset();
    gpu_mmu_init(0x90000000);   // Dummy page table base
    gpu_l2_init();
    mmio_write(GPU_SM_BASE + GPU_SM_ENABLE, 1);
}

/* =======================
 * DMA Transfers
 * ======================= */
void gpu_memcpy_to_device(void *dst_gpu, void *src_cpu, size_t size) {
    mmio_write(GPU_DMA_BASE + GPU_DMA_SRC, (uint32_t)src_cpu);
    mmio_write(GPU_DMA_BASE + GPU_DMA_DST, (uint32_t)dst_gpu);
    mmio_write(GPU_DMA_BASE + GPU_DMA_LEN, size);
    mmio_write(GPU_DMA_BASE + GPU_DMA_START, 1);
    while (!mmio_read(GPU_DMA_BASE + GPU_DMA_DONE));
}

void gpu_memcpy_from_device(void *dst_cpu, void *src_gpu, size_t size) {
    mmio_write(GPU_DMA_BASE + GPU_DMA_SRC, (uint32_t)src_gpu);
    mmio_write(GPU_DMA_BASE + GPU_DMA_DST, (uint32_t)dst_cpu);
    mmio_write(GPU_DMA_BASE + GPU_DMA_LEN, size);
    mmio_write(GPU_DMA_BASE + GPU_DMA_START, 1);
    while (!mmio_read(GPU_DMA_BASE + GPU_DMA_DONE));
}

/* =======================
 * Kernel Upload
 * ======================= */
void gpu_load_kernel(void *kernel_bin, size_t size, uint64_t gpu_addr) {
    gpu_memcpy_to_device((void *)gpu_addr, kernel_bin, size);
}

/* =======================
 * Kernel Launch
 * ======================= */
void gpu_launch_kernel(gpu_kernel_desc_t *kdesc) {
    mmio_write(GPU_SM_BASE + GPU_SM_KERNEL_ADDR, (uint32_t)kdesc->entry_point);
    mmio_write(GPU_SM_BASE + GPU_SM_ARG_ADDR, (uint32_t)kdesc->arg_ptr);
    mmio_write(GPU_SM_BASE + GPU_SM_GRID_DIM, kdesc->grid_x);
    mmio_write(GPU_SM_BASE + GPU_SM_BLOCK_DIM, kdesc->block_x);
    mmio_write(GPU_SM_BASE + GPU_SM_START, 1);
}

/* =======================
 * Kernel Completion Wait
 * ======================= */
void gpu_wait(void) {
    while (!mmio_read(GPU_SM_BASE + GPU_SM_DONE));
}

/* =======================
 * Example Main
 * ======================= */
int main(void) {

    gpu_init();

    /* Dummy kernel + data */
    static uint32_t kernel_binary[256];
    static uint32_t input[256];
    static uint32_t output[256];

    for (int i = 0; i < 256; i++)
        input[i] = i;

    /* Load kernel */
    gpu_load_kernel(kernel_binary, sizeof(kernel_binary), 0xA0000000);

    /* Copy input data */
    gpu_memcpy_to_device((void *)0xA1000000, input, sizeof(input));

    /* Kernel descriptor */
    gpu_kernel_desc_t kdesc;
    kdesc.entry_point = 0xA0000000;
    kdesc.arg_ptr     = 0xA1000000;
    kdesc.grid_x      = 4;
    kdesc.block_x     = 64;

    gpu_launch_kernel(&kdesc);
    gpu_wait();

    /* Read back results */
    gpu_memcpy_from_device(output, (void *)0xA2000000, sizeof(output));

    while (1);  // Done
    return 0;
}

