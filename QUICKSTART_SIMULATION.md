# PicoClaw-Ebo Simulation Quick Start

This quick start provides a practical path to start developing PicoClaw-Ebo without physical hardware.

It follows the architecture in:
- `docs/picoclaw_ebo_development_simulation.md`
- `docs/picoclaw_ebo_architecture.md`

## Documentation Rule

All setup and validation actions performed during this simulation effort must be recorded in this file.

For each action, log:
- Date and time
- Command or change applied
- Result
- Next action

## Git Tracking Decision

Current repository policy:
- Track simulation documentation and scripts.
- Do not track heavyweight emulation sources or generated disk images.

Tracked:
- `QUICKSTART_SIMULATION.md`
- `workspace/emulation/scripts/`

Ignored:
- `workspace/emulation/buildroot/`
- `workspace/emulation/riscv64/`

## Execution Log

### 2026-02-20

- Action: Verified local availability of `qemu-system-riscv64` and `qemu-user-static`.
- Result: Not found in current environment.
- Next action: Install `qemu-system-misc` and `qemu-user-static`, then re-check with `qemu-system-riscv64 --version`.
- Action: Verified QEMU installation on host with `qemu-system-riscv64 --version`.
- Result: `QEMU emulator version 8.2.2 (Debian 1:8.2.2+ds-0ubuntu1.12)`.
- Next action: Prepare `workspace/emulation/riscv64/` with `Image` and `rootfs.ext4` to boot the first 256MB mini Linux instance.
- Action: Added a Buildroot fast path to generate `Image` and `rootfs` for QEMU system emulation.
- Result: This quickstart now includes direct commands for artifact generation and placement.
- Next action: Execute section `4.1.1` commands and confirm files under `workspace/emulation/riscv64/`.
- Action: Attempted to execute section `4.1.1` commands in this environment.
- Result: Failed at `git clone https://github.com/buildroot/buildroot.git` with `Could not resolve host: github.com`.
- Next action: Run section `4.1.1` on a host with internet access, then continue with section `4.2`.
- Action: Re-ran emulation validation without reinstalling packages.
- Result: Confirmed boot on QEMU to `buildroot login`, and validated file injection into rootfs with `debugfs` + in-guest readback.
- Next action: Use `workspace/emulation/scripts/*.sh` for repeatable boot and artifact injection.
- Action: Installed Go toolchain and built `build/picoclaw-linux-riscv64`.
- Result: Build succeeded using Go `1.25.7` after fixing `go:generate` to avoid copying heavy emulation artifacts.
- Next action: Inject binary into guest rootfs and validate execution in emulated Linux.
- Action: Injected `build/picoclaw-linux-riscv64` into `/root/picoclaw` and booted guest.
- Result: Binary executed successfully in guest; command usage output confirmed (`picoclaw <command>` list printed).
- Next action: Continue feature validation with `picoclaw version`, `status`, and agent flows in guest.
- Action: Revised repository policy to official scope only.
- Result: Kept docs/scripts in Git and excluded heavy emulation assets (`buildroot`, `riscv64` artifacts).
- Next action: Keep Buildroot source and images local, regenerate as needed.

## Validated Status (2026-02-20)

Validated in this repository/environment:
- `qemu-system-riscv64` available (`8.2.2`).
- `qemu-riscv64-static` available (`8.2.2`).
- Artifacts present in `workspace/emulation/riscv64/`: `Image`, `rootfs.ext2`, `rootfs.ext4`.
- Full boot works with `./workspace/emulation/scripts/boot-riscv64.sh` up to `buildroot login`.
- Host-to-guest file transfer works with `./workspace/emulation/scripts/inject-rootfs.sh` + in-guest readback.

Observed constraints in this environment:
- `hostfwd` for QEMU user networking can be blocked.
- Default Buildroot `qemu_riscv64_virt_defconfig` here does not enable SSH server (`dropbear`/`openssh`), so `scp` may fail unless enabled explicitly.

## 1. Prerequisites

Use an Ubuntu 22.04/24.04 host (or equivalent Linux environment) with:

- `git`
- `docker` and `docker compose`
- `qemu-user-static`
- `qemu-system-riscv64`
- `python3` and `pip`
- `cmake`, `build-essential`

Optional but recommended:
- MuJoCo for high-fidelity physics
- PyBullet for fast prototyping

## 2. Clone and Enter the Repository

```bash
git clone https://github.com/albertovalverde/picoclaw.git
cd picoclaw
git checkout dev
```

## 3. Prepare a RISC-V Build/Test Path

Install static emulation support:

```bash
sudo apt update
sudo apt install -y qemu-user-static qemu-system-misc
```

Build the project:

```bash
make deps
make build-all
```

The riscv64 binary expected later is:

```text
build/picoclaw-linux-riscv64
```

If you already have a riscv64 binary, you can run fast logic checks with `qemu-user-static` (without full system boot), e.g. with an explicit sysroot:

```bash
qemu-riscv64-static -L workspace/emulation/buildroot/output/target <riscv64-binary> --help
```

## 4. Full-System Emulation with Mini Linux (QEMU System)

Use this when you want to validate full boot behavior with a Buildroot/Debian-style image, close to LicheeRV Nano constraints.

Target runtime profile:
- Architecture: `rv64`
- RAM: `256MB`
- Boot mode: full system emulation with `qemu-system-riscv64`

### 4.1 Prepare a Minimal RISC-V Image

Use one of these options:

1. Buildroot-based image (lightweight, fast boot)
2. Debian Sid riscv64 image (closer user-space tooling)

Expected artifacts:
- `Image` (kernel)
- `rootfs.ext2` (or `rootfs.ext4`)
- `fw_jump.bin` / `fw_jump.elf` (OpenSBI)

Store files under:

```text
workspace/emulation/riscv64/
```

### 4.1.1 Fast Path: Buildroot for QEMU `virt` (recommended)

Install build dependencies:

```bash
sudo apt update
sudo apt install -y build-essential git cpio file rsync bc bison flex libssl-dev wget
```

Build a RISC-V image for QEMU:

```bash
mkdir -p workspace/emulation
cd workspace/emulation
git clone https://github.com/buildroot/buildroot.git
cd buildroot
make qemu_riscv64_virt_defconfig
make -j"$(nproc)"
```

Expected Buildroot outputs:
- `output/images/Image`
- `output/images/rootfs.ext2`
- `output/images/fw_jump.elf` (if enabled by config)

Copy artifacts to this guide's canonical path:

```bash
cd /home/kdfa/projects/picoclaw
mkdir -p workspace/emulation/riscv64
cp workspace/emulation/buildroot/output/images/Image workspace/emulation/riscv64/
cp workspace/emulation/buildroot/output/images/rootfs.ext2 workspace/emulation/riscv64/
```

If your root filesystem is `ext2`, you can keep it as-is and use it in QEMU.

### 4.1.2 Optional: ext2 to ext4 filename alignment

If you want to keep the boot command unchanged (`rootfs.ext4`), copy/rename:

```bash
cp workspace/emulation/riscv64/rootfs.ext2 workspace/emulation/riscv64/rootfs.ext4
```

### 4.2 Boot with QEMU (`qemu-system-riscv64`)

Recommended script (virt machine, 256MB RAM):

```bash
./workspace/emulation/scripts/boot-riscv64.sh
```

Equivalent direct command:

```bash
qemu-system-riscv64 \
  -machine virt \
  -cpu rv64 \
  -m 256M \
  -smp 1 \
  -nographic \
  -bios workspace/emulation/buildroot/output/images/fw_jump.bin \
  -kernel workspace/emulation/riscv64/Image \
  -append "root=/dev/vda rw console=ttyS0" \
  -drive file=workspace/emulation/riscv64/rootfs.ext2,format=raw,if=virtio \
  -netdev user,id=net0 \
  -device virtio-net-device,netdev=net0
```

Notes:
- Keep `-m 256M` to match real board memory pressure.
- `hostfwd` may be blocked in restricted environments; boot without SSH forwarding is enough for validation.
- If your image uses `vmlinuz` or `zImage`, set it in `-kernel` accordingly.

### 4.3 Copy and Run PicoClaw in the Guest

Inside the guest Linux shell:

1. Create app directory and config.
2. Inject the PicoClaw binary into `rootfs.ext2` from host (no SSH required).
3. Boot guest and run it.

Host-side inject example:

```bash
./workspace/emulation/scripts/inject-rootfs.sh \
  workspace/emulation/riscv64/rootfs.ext2 \
  build/picoclaw-linux-riscv64 \
  /root/picoclaw
```

Guest-side validation example:

```bash
chmod +x /root/picoclaw
/root/picoclaw agent -m "health check"
free -m
top
```

Optional SSH path:
- If you explicitly enable `dropbear`/`openssh` in Buildroot and expose `hostfwd`, you can use `scp`.

Goal:
- Verify stable boot and runtime behavior within 256MB.
- Validate that `config.json` and startup flow behave as expected.

## 5. Create a Local Simulation Environment

Create and activate a Python virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
```

Install simulation dependencies:

```bash
pip install mujoco pybullet pyzmq websockets opencv-python
```

Notes:
- Use MuJoCo for main validation loops.
- Use PyBullet for rapid path-planning iterations.

## 6. Define the Robot Digital Twin

Create a URDF model for Enabot Ebo Air 2 with:

- Dimensions: `95mm x 95mm x 89.2mm`
- Mass: `282g`
- Drive: differential (two velocity-controlled wheels)
- Tuned inertia for tumbler/self-righting behavior

Store this model in your simulation workspace, for example:

```text
workspace/sim/ebo_air2.urdf
```

## 7. Start the Simulator

Run either MuJoCo or PyBullet with a control socket that accepts:

- `linear_x`
- `angular_z`

Recommended transport:
- ZeroMQ for low-overhead control loop
- WebSocket when browser tooling or remote dashboards are needed

## 8. Connect PicoClaw to the Simulator (HiL-style Loop)

Run the PicoClaw agent and route motion commands to the simulator bridge:

1. Agent publishes command intents (`linear_x`, `angular_z`).
2. Bridge translates intents to simulator motor commands.
3. Simulator returns telemetry (pose, velocity, obstacle status).
4. Optional: simulator camera frames are published back for vision tests.

For virtual camera workflows on Linux, use `v4l2loopback` and stream simulator frames into the virtual device.

## 9. Validate End-to-End Behavior

Start with these checks:

1. Command latency under nominal load.
2. Stop command preemption over normal motion queue.
3. Person-following loop remains stable when cloud LLM calls are delayed.
4. Brownout and thermal guard logic can be exercised with simulated faults.

## 10. Suggested Iteration Flow

1. Develop and unit-test logic on host.
2. Run riscv64 checks through `qemu-user-static`.
3. Validate behavior in MuJoCo/PyBullet.
4. Move validated modules to real LicheeRV Nano hardware.

## 11. Next Documents

- Detailed architecture: `docs/picoclaw_ebo_architecture.md`
- Full simulation strategy: `docs/picoclaw_ebo_development_simulation.md`
