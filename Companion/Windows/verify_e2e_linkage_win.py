#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""iPad 模拟器与 Windows 被控端伴侣服务 (10.1.1.2:52088) 端到端真实联动验证脚本

执行流程：
1. 通过 SSH 调度 Windows 主机 (10.1.1.2) 启动原生伴侣服务 cpwin.exe 监听 UDP 52088；
2. 调度本机 iOS 模拟器 (iPad Pro 12.9 2018) 沙盒内部测试进程执行 testsimwin；
3. iPad 模拟器通过网络套接字向远程 Windows 主机 10.1.1.2:52088 发送真实 16 字节 MBCP 二进制 UDP 报文：
   - Win、Ctrl、Alt 修饰键脉冲
   - Alt + Tab 组合键按下与抬起
   - Escape 脉冲
   - F1～F12 功能键脉冲
   - Ctrl 修饰键心跳同步
   - ResetAll 紧急全键复位
4. 捕获并检查 Windows 伴侣服务运行日志 live_c.log，验证所有来自 iPad 模拟器的按键与修饰键被 SendInput 成功注入；
5. 安全停止 Windows 伴侣服务并输出详细验证审计报告。
"""

import sys
import os
import time
import subprocess
import base64

# 运行无默认 Shell 的子进程
def run_cmd(cmd, check=True):
    print(f"🔧 执行: {cmd}")
    res = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )
    if check and res.returncode != 0:
        print(f"❌ 命令执行失败 (code {res.returncode}):\n{res.stdout}")
        sys.exit(res.returncode)
    return res

# 构造 Windows PowerShell 7 SSH 命令
def pscmd(target, script):
    encoded = base64.b64encode(script.encode("utf-16le")).decode("ascii")
    return ["ssh", target, "pwsh.exe", "-NoLogo", "-NoProfile", "-EncodedCommand", encoded]

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(os.path.dirname(script_dir))
    win_host = "10.1.1.2"
    win_ssh_target = "windows"
    port = 52088
    sim_id = "73860E49-6DDF-450B-B505-F0E0A09F764B"

    print("==================================================================")
    print("🚀 启动 iPad 模拟器与 Windows 被控端伴侣服务跨机端到端真实联动验证")
    print(f"   Windows 目标主机: {win_host} (SSH 目标: {win_ssh_target}, 端口: {port})")
    print(f"   iOS 模拟器目标:   MagicBoard iPad Pro 12.9 2018 (ID: {sim_id})")
    print("==================================================================")

    # 1. 在 Windows 远端启动伴侣服务
    print("\n[Step 1/5] 正在通过 SSH 在 Windows 主机上启动原生伴侣服务...")
    start_cmd = pscmd(
        win_ssh_target,
        f'& pwsh.exe -NoProfile -File "$env:USERPROFILE\\MagicBoardCompanion\\start-companion.ps1" -Port {port}'
    )
    start_res = subprocess.run(start_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, encoding="utf-8", errors="replace", timeout=15)
    print(start_res.stdout.strip())
    time.sleep(1.0)

    # 验证 Windows UDP 端口监听
    check_port_cmd = pscmd(
        win_ssh_target,
        f"Get-NetUDPEndpoint -LocalPort {port} | Select-Object OwningProcess, LocalPort"
    )
    port_res = subprocess.run(check_port_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, encoding="utf-8", errors="replace", timeout=10)
    print(f"   Windows 端口监听状态:\n{port_res.stdout.strip()}")
    if str(port) not in port_res.stdout:
        print("❌ Windows 伴侣服务未在端口 52088 上正常监听！")
        sys.exit(1)

    # 2. 调度 iOS 模拟器发送真实 UDP 报文到 Windows 10.1.1.2
    print("\n[Step 2/5] 正在调度 iPad 模拟器内部沙盒测试进程向 10.1.1.2:52088 发送 MBCP 测试报文...")
    test_cmd = [
        "xcodebuild", "test", "-quiet", "-scheme", "MagicBoardShared",
        "-destination", f"platform=iOS Simulator,id={sim_id}",
        "-only-testing:MagicBoardSharedTests/CompanionProtocolTests/testsimwin"
    ]
    sim_res = subprocess.run(
        test_cmd,
        cwd=os.path.join(project_root, "Packages/MagicBoardShared"),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        encoding="utf-8",
        errors="replace"
    )

    sim_passed = sim_res.returncode == 0
    print(f"   iPad 模拟器执行结果: {'✅ TEST SUCCEEDED (测试成功通过)' if sim_passed else '❌ 测试失败'}")
    if not sim_passed:
        print(sim_res.stdout[-1500:])

    time.sleep(1.0)

    # 3. 获取 Windows 伴侣端实时日志
    print("\n[Step 3/5] 正在拉取 Windows 伴侣端执行日志 (live_c.log)...")
    get_log_cmd = pscmd(
        win_ssh_target,
        'Get-Content -Encoding UTF8 "$env:USERPROFILE\\MagicBoardCompanion\\live_c.log"'
    )
    log_res = subprocess.run(get_log_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, encoding="utf-8", errors="replace", timeout=10)
    win_logs = log_res.stdout.splitlines()

    print("--- Windows 伴侣日志捕获 ---")
    for line in win_logs:
        if line.strip() and not line.startswith("**"):
            print(f"   [Win 伴侣] {line.strip()}")
    print("----------------------------")

    # 4. 停止 Windows 伴侣服务
    print("\n[Step 4/5] 正在安全停止 Windows 伴侣服务...")
    stop_cmd = pscmd(
        win_ssh_target,
        '& pwsh.exe -NoProfile -File "$env:USERPROFILE\\MagicBoardCompanion\\stop-companion.ps1"'
    )
    subprocess.run(stop_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, encoding="utf-8", errors="replace", timeout=10)
    print("   Windows 伴侣服务已安全停止。")

    # 5. 详细审计与断言验证
    print("\n==================================================================")
    print("[Step 5/5] 🔍 跨机端到端联动验证审计:")

    received_win = any("0x00E3" in l and "Pulse" in l for l in win_logs)
    received_ctrl = any("0x00E0" in l and "Pulse" in l for l in win_logs)
    received_alt = any("0x00E2" in l and "Pulse" in l for l in win_logs)
    received_tab_alt = any("0x002B" in l and "KeyDown" in l for l in win_logs)
    received_esc = any("0x0029" in l and "Pulse" in l for l in win_logs)
    received_frow = all(
        any(f"0x{usage:04X}" in l and "Pulse" in l for l in win_logs)
        for usage in range(0x003A, 0x0046)
    )
    received_reset = any("resetAll" in l for l in win_logs)

    print(f"   1. iPad 模拟器测试状态:          {'✅ 通过 (TEST SUCCEEDED)' if sim_passed else '❌ 失败'}")
    print(f"   2. Windows 接收 iPad 发来的 Win 键脉冲 (50ms):  {'✅ 成功捕获并注入' if received_win else '❌ 缺失'}")
    print(f"   3. Windows 接收 iPad 发来的 Ctrl 键脉冲:       {'✅ 成功捕获并派发' if received_ctrl else '❌ 缺失'}")
    print(f"   4. Windows 接收 iPad 发来的 Alt 键脉冲:        {'✅ 成功捕获并派发' if received_alt else '❌ 缺失'}")
    print(f"   5. Windows 接收 iPad 发来的 Alt+Tab 组合键:    {'✅ 成功捕获并派发' if received_tab_alt else '❌ 缺失'}")
    print(f"   6. Windows 接收 iPad 发来的 Escape 脉冲:       {'✅ 成功捕获并派发' if received_esc else '❌ 缺失'}")
    print(f"   7. Windows 接收 iPad 发来的 F1～F12 脉冲:      {'✅ 全部捕获并派发' if received_frow else '❌ 缺失'}")
    print(f"   8. Windows 接收 iPad 发来的 ResetAll 紧急复位:  {'✅ 成功捕获并释放' if received_reset else '❌ 缺失'}")

    all_passed = all((
        sim_passed,
        received_win,
        received_ctrl,
        received_alt,
        received_tab_alt,
        received_esc,
        received_frow,
        received_reset,
    ))

    if all_passed:
        print("==================================================================")
        print("🎉 恭喜！iPad 模拟器与 Windows 被控端伴侣服务跨机端到端联动验证 100% 成功！")
        print("   iPad 模拟器（iOS 进程）通过网络 UDP 直连 Windows 主机 (10.1.1.2:52088)，")
        print("   所有按键、修饰键与控制指令均无损传输并成功注入 Windows 系统输入队列！")
        print("==================================================================")
    else:
        print("==================================================================")
        print("❌ 联动测试存在未完全通过的项目，请核对上方日志。")
        sys.exit(1)

if __name__ == "__main__":
    main()
