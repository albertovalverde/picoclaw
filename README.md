# PicoClaw-Ebo

Project PicoClaw-Ebo is a hybrid AI and mobile robotics integration that combines the PicoClaw autonomous agent with the Enabot Ebo Air 2 chassis. The system embeds a LicheeRV Nano development board (SOPHGO SG2002 SoC) to deliver low-latency, on-device vision while delegating higher-level reasoning and conversation to cloud LLMs. The result is a robot that remains reactive and safe locally, while still being capable of rich cognitive interaction.

## System Summary

- Local intelligence: SG2002 NPU for real-time YOLO inference and safety-critical perception.
- Cloud intelligence: LLMs for semantic reasoning, identity verification, and conversation.
- Ultra-lightweight core: PicoClaw in Go, under 10MB RAM, sub-second boot.
- Control bridge: Python BLE emulation layer to command the Ebo motors.
- Low-latency media: WebRTC for 2-way audio and video streaming.
- Shared memory IPC: Zero-copy coordination between inference and control loops.

## Hardware Integration

The Ebo Air 2 chassis is compact and thermally constrained. The LicheeRV Nano is integrated with careful attention to power stability, thermal limits, and battery safety. A dedicated MT3608 boost converter lifts the 3.0V to 4.2V battery range to a stable 5.0V rail for the SG2002.

Key hardware notes:
- Chassis size and weight require tight internal load balancing.
- PC+ABS shell traps heat, so thermal monitoring is mandatory.
- Power tap must occur after the battery management system (BMS).
- Motor-induced voltage sags are mitigated with input bulk capacitance.

## Control Bridge

The Ebo Air 2 is proprietary, so motor control is implemented via a Python gateway that emulates the original BLE protocol. The gateway translates high-level commands into low-level GATT writes and prioritizes safety-critical actions (e.g., STOP) through a fast command queue.

## Edge AI Pipeline

The SG2002 NPU provides the local perception layer with INT8-quantized YOLO models for real-time tracking. Shared-memory IPC enables zero-copy transfer of detection data between the C++ inference engine and the Python gateway, preventing memory pressure on the 256MB LicheeRV Nano.

## Connectivity

WebRTC is used for full-duplex, low-latency audio and video streaming. WebSocket or similar TCP channels are reserved for control commands and state updates where delivery guarantees matter more than latency.

## Documentation

- Architecture approach: `docs/picoclaw_ebo_architecture.md`
