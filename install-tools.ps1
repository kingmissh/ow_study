# Windows 开发工具安装脚本
# 用于安装 GitHub CLI 和其他必要工具

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Windows 开发工具安装向导" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  警告: 建议以管理员身份运行此脚本" -ForegroundColor Yellow
    Write-Host "右键点击 PowerShell，选择 '以管理员身份运行'" -ForegroundColor Yellow
    Write-Host ""
}

# 检查 Git
Write-Host "检查 Git..." -ForegroundColor Yellow
try {
    $gitVersion = git --version
    Write-Host "✅ Git 已安装: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git 未安装" -ForegroundColor Red
    Write-Host "请访问 https://git-scm.com/download/win 下载安装" -ForegroundColor Yellow
}

Write-Host ""

# 检查 GitHub CLI
Write-Host "检查 GitHub CLI..." -ForegroundColor Yellow
try {
    $ghVersion = gh --version
    Write-Host "✅ GitHub CLI 已安装: $ghVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ GitHub CLI 未安装" -ForegroundColor Red
    Write-Host ""
    Write-Host "选择安装方法:" -ForegroundColor Cyan
    Write-Host "1. 使用 Scoop (推荐)" -ForegroundColor White
    Write-Host "2. 使用 Chocolatey" -ForegroundColor White
    Write-Host "3. 手动下载安装" -ForegroundColor White
    Write-Host "4. 跳过" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "请选择 (1-4)"
    
    switch ($choice) {
        "1" {
            Write-Host ""
            Write-Host "使用 Scoop 安装..." -ForegroundColor Green
            
            # 检查 Scoop 是否已安装
            try {
                scoop --version | Out-Null
                Write-Host "✅ Scoop 已安装" -ForegroundColor Green
            } catch {
                Write-Host "正在安装 Scoop..." -ForegroundColor Yellow
                Write-Host "执行命令: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Gray
                Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
                
                Write-Host "下载并安装 Scoop..." -ForegroundColor Yellow
                Invoke-RestMethod get.scoop.sh | Invoke-Expression
            }
            
            Write-Host "正在安装 GitHub CLI..." -ForegroundColor Yellow
            scoop install gh
        }
        "2" {
            Write-Host ""
            Write-Host "使用 Chocolatey 安装..." -ForegroundColor Green
            
            # 检查 Chocolatey 是否已安装
            try {
                choco --version | Out-Null
                Write-Host "✅ Chocolatey 已安装" -ForegroundColor Green
            } catch {
                Write-Host "正在安装 Chocolatey..." -ForegroundColor Yellow
                Write-Host "需要管理员权限" -ForegroundColor Red
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            }
            
            Write-Host "正在安装 GitHub CLI..." -ForegroundColor Yellow
            choco install gh -y
        }
        "3" {
            Write-Host ""
            Write-Host "手动下载安装:" -ForegroundColor Green
            Write-Host "1. 访问: https://github.com/cli/cli/releases/latest" -ForegroundColor White
            Write-Host "2. 下载 gh_*_windows_amd64.msi" -ForegroundColor White
            Write-Host "3. 运行安装程序" -ForegroundColor White
            Write-Host "4. 重新打开 PowerShell" -ForegroundColor White
            Write-Host ""
            Write-Host "按任意键打开下载页面..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            Start-Process "https://github.com/cli/cli/releases/latest"
        }
        "4" {
            Write-Host "跳过 GitHub CLI 安装" -ForegroundColor Yellow
        }
        default {
            Write-Host "无效选择" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  安装完成" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步:" -ForegroundColor Yellow
Write-Host "1. 重新打开 PowerShell（如果刚安装了工具）" -ForegroundColor White
Write-Host "2. 运行: gh auth login" -ForegroundColor White
Write-Host "3. 运行: .\push-to-github.ps1 YOUR_USERNAME" -ForegroundColor White
Write-Host ""
