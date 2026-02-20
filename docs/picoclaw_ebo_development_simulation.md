# PicoClaw-Ebo Development and Simulation Framework

This document proposes a professional simulation strategy for Project PicoClaw-Ebo, combining hardware emulation of the Sipeed LicheeRV Nano with physics-based simulation of the Enabot Ebo Air 2 chassis. The goal is to enable rapid, repeatable development without requiring continuous access to physical hardware.

## 1. Executive Summary

The proposed framework establishes a high-fidelity environment to validate the PicoClaw autonomous agent by separating the system into two domains:
- Brain: RISC-V compute emulation of the SG2002 platform.
- Body: physics simulation of the mobile robot and its interaction with the environment.

This enables safe iteration, CI-friendly testing, and a clean path for sim-to-real transfer.

## 2. Computational Core Emulation (Brain)

### 2.1 System Emulation

- Target SoC: SOPHGO SG2002 (C906 core).
- Emulator: TinyEMU (patched for SG200x), with QEMU as a fallback.
- OS Image: minimal Buildroot or Debian Sid (riscv64), aligned with the Sipeed SDK.
- NPU behavior: bypassed during emulation. Inference runs on the C906 CPU or is delegated to a host-side GPU bridge for functional testing.

### 2.2 Development Workflow

- Use multi-arch Docker images to compile the Go-based PicoClaw agent.
- Use `qemu-user-static` to execute riscv64 binaries on x86_64 for unit tests and IPC validation without full system boot.

## 3. Robotic Physics Simulation (Body)

The Ebo Air 2 has no official simulator, so a digital twin will be created using open-source robotics engines.

### 3.1 MuJoCo (Primary)

MuJoCo is selected for high-quality contact dynamics and stable real-time simulation.

- Model: differential drive tumbler with low center of gravity.
- URDF: custom Ebo Air 2 description based on known dimensions and mass.
- Form factor: 95mm x 95mm x 89.2mm.
- Mass: 282g.
- Actuators: dual brushed motors, velocity-controlled (max 60 cm/s).
- Inertia: tuned to reproduce self-righting behavior.

### 3.2 PyBullet (Secondary)

PyBullet provides faster iteration for path planning and collision avoidance when integration speed is more important than high-fidelity dynamics.

## 4. Hardware-in-the-Loop (HiL) Integration

The emulated LicheeRV Nano and the physics engine are bridged through a bidirectional control and sensor pipeline:

1. Control loop: the PicoClaw agent sends motion commands (linear X, angular Z) via ZeroMQ or WebSockets.
2. Visual feedback: the simulator renders a POV stream and exposes frames via a virtual video device (`v4l2loopback`).
3. Telemetry: simulator publishes state, IMU proxies, and motor feedback back to the agent.

## 5. Proposed Stack

| Component | Software or Tool |
| --- | --- |
| Architecture | RISC-V 64-bit (C906) |
| Linux emulator | TinyEMU / QEMU |
| Robotics simulator | MuJoCo (open source) |
| Robot model | Custom URDF (PicoClaw-Ebo v1.0) |
| IPC bridge | ZeroMQ / shared memory |

## 6. Conclusion

This approach decouples development from hardware availability while preserving system realism. It enables continuous testing, rapid iteration, and a safe path to deploy code on the real LicheeRV Nano with minimal changes. The result is a robust sim-to-real workflow for the PicoClaw-Ebo platform.
