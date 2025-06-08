# Mini NVIDIA Blackwell-Style GPU RTL 🚀

## 📌 Project Overview

This project aims to replicate NVIDIA’s latest Blackwell GPU architecture in RTL, delivering a compact yet fully featured GPU design optimized for FPGA prototyping and AI inference acceleration. The design faithfully reproduces key architectural elements such as CUDA cores with warp-level SIMT execution, an advanced warp scheduler, systolic-array-based tensor cores, and a hierarchical memory subsystem to enable efficient execution of complex AI workloads.

## 🧠 Architectural Highlights

- **CUDA Cores:** Scalar ALU and floating-point pipelines with warp-aware register files supporting 32-thread warps under the SIMT execution model.  
- **Warp Scheduler:** Round-robin scheduling with scoreboard-based hazard detection ensures high throughput and data hazard management.  
- **Tensor Cores:** High-efficiency systolic arrays for mixed precision (INT8/FP16) matrix multiply-accumulate operations accelerating deep learning computations.  
- **Memory Hierarchy:** Per-core L1 caches and shared memories, complemented by multi-level TLBs and a shared L2 cache for streaming multiprocessors.  
- **Execution Controller:** FSM-driven pipeline managing instruction fetch, decode, dispatch, and retirement conforming to CUDA ISA semantics.  
- **AXI Interconnect:** High-bandwidth AXI bus interfaces and DMA engines enable efficient off-chip DRAM access and host communication.

## 📅 Development Roadmap (Deadline: June 25, 2025)

- **Week 1:**  
  Implement CUDA core pipeline including ALU, FPU, warp-aware register files, and warp scheduler with hazard logic. Perform RTL simulation and validation of pipeline correctness and warp-level execution.

- **Week 2:**  
  Develop memory subsystem with load-store units, L1 caches, shared memory, and multi-level TLBs. Design and integrate systolic array tensor cores supporting mixed-precision MMA operations. Validate memory and compute integration.

- **Week 3:**  
  Finalize AXI master interfaces and DRAM controllers to support high-throughput data transfers. Implement host interface and model loading modules enabling full AI inference execution on FPGA. Conduct comprehensive verification and benchmarking.

## 📂 Repository Structure

/src
/cuda_core
/tensor_core
/memory
/interconnect
/control
/host
/tests
/docs
README.md
LICENSE

markdown
Copy
Edit

## 🧪 Testing and Verification

- Unit and integration testbenches for core modules.  
- Cycle-accurate RTL simulations with ModelSim and on Xilinx FPGA.  
- AI kernel functional verification and performance profiling.  
- Python co-simulation for cross-validation of execution correctness.

## 🤝 Contributions

We welcome contributions from RTL designers, GPU architects, AI hardware researchers, and FPGA engineers. Please open issues or submit pull requests to collaborate.

## 📚 References

- NVIDIA Blackwell Architecture Whitepapers  
- CUDA PTX ISA and Programming Model Documentation
- Research Literature on Systolic Arrays and AI Acceleration  
- AXI Protocol Specifications
