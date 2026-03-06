# Draft: Godot 4.6 3D转2D像素化边缘描边Shader

## 需求（已确认）

### 使用场景
- **3D 对象 → 摄像机 → 2D 精灵（Sprite2D/TextureRect）**
- 可能通过 ViewportTexture 捕获 3D 场景
- Shader 应用于 CanvasItem（2D 精灵）

### 像素化效果
- **带颜色限制的像素化**
- 减少颜色数量，模拟复古游戏机调色板效果
- 颜色量化：每通道减少到特定位数

### 边缘描边
- **白色描边，可调透明度**
- 描边通过 alpha 参数调节

## 技术要点

### 待研究
- Godot 4.6 CanvasItemShader 语法
- 像素化算法（UV 坐标离散化）
- 颜色量化算法
- 2D 精灵边缘检测方法（alpha 通道）
- Shader 参数定义

## 实现策略

### Shader 类型
- `shader_type canvas_item`（用于 2D 精灵/TextureRect）

### 核心功能模块
1. **像素化**：UV 采样离散化到指定网格大小
2. **颜色量化**：将 RGB 每个通道减少到特定位数
3. **边缘检测**：基于 alpha 通道或颜色差异检测边缘
4. **描边叠加**：在边缘叠加白色，应用透明度

### 可调参数
- `pixel_size`：像素化程度（默认 4.0）
- `color_levels`：颜色级别（每通道位深，默认 4）
- `outline_width`：描边宽度（默认 1.0）
- `outline_alpha`：描边透明度（默认 0.8）

## 输出
- 文件路径：`img/pixel_outline.gdshader`
