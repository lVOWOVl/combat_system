# Plan: Godot 4.6 像素化边缘描边 Shader

## 任务概述
为 Godot 4.6 创建一个 3D 转 2D 的像素化 shader，支持颜色限制和可调透明度的白色边缘描边，输出到 `img/` 目录。

## 用户需求（已确认）
- **使用场景**：3D 对象 → 摄像机捕获 → 2D 精灵（Sprite2D/TextureRect）显示
- **像素化效果**：带颜色限制的像素化（减少颜色数量，模拟复古游戏机调色板）
- **边缘描边**：白色描边，可调节透明度

## 技术方案

### Shader 类型
- `shader_type canvas_item;`（用于 2D 精灵）

### 核心功能模块

#### 1. 像素化（Pixelation）
- 算法：UV 坐标离散化
- 代码：`floor(UV / grid_size) * grid_size`
- 参数：`pixel_size`（1.0-64.0，默认 4.0）

#### 2. 颜色量化（Color Quantization）
- 算法：减少每 RGB 通道的颜色级别
- 代码：`floor(color * f + 0.5) / f`
- 参数：`color_levels`（2-256，默认 8）

#### 3. 边缘检测（Edge Detection）
- 算法：基于 alpha 通道的 Sobel 算子
- 采样 4 个相邻像素（左、右、上、下）
- 参数：`outline_width`（0.5-10.0，默认 1.5）
- 参数：`outline_threshold`（0.0-1.0，默认 0.15）

#### 4. 描边叠加（Outline Overlay）
- 算法：在边缘像素上混合白色
- 代码：`mix(base_color.rgb, outline_color.rgb, outline_alpha)`
- 参数：`outline_alpha`（0.0-1.0，默认 0.8）

## 文件操作

### 创建文件
- **路径**：`img/pixel_outline.gdshader`
- **内容**：完整的 Godot 4.6 CanvasItemShader 代码

### Shader 结构

```glsl
shader_type canvas_item;
render_mode blend_mix;

// Uniform 参数定义（所有参数在 Inspector 中可调）
uniform float pixel_size : hint_range(1.0, 64.0, 0.1) = 4.0;
uniform bool enable_pixelation = true;

uniform int color_levels : hint_range(2, 256, 1) = 8;
uniform bool enable_quantization = true;

uniform bool enable_outline = true;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.5, 10.0, 0.1) = 1.5;
uniform float outline_alpha : hint_range(0.0, 1.0, 0.01) = 0.8;
uniform float outline_threshold : hint_range(0.0, 1.0, 0.01) = 0.15;

// Helper 函数：像素化
vec2 pixelate_uv(vec2 uv, float size) { ... }

// Helper 函数：颜色量化
vec3 quantize_color(vec3 color, int levels) { ... }

// Helper 函数：边缘检测
float detect_edge(vec2 uv, vec2 texel_size) { ... }

// 主 fragment 函数
void fragment() {
    // 1. 像素化
    // 2. 颜色量化
    // 3. 边缘检测 + 描边叠加
    // 4. 输出 COLOR
}
```

## 执行步骤

### Step 1: 验证目标目录
- 检查 `img/` 目录是否存在
- 如果不存在则创建

### Step 2: 创建 shader 文件
- 创建 `img/pixel_outline.gdshader`
- 写入完整的 shader 代码

### Step 3: 验证结果
- 确认文件创建成功
- 检查文件内容完整

## 完整 Shader 代码

```glsl
shader_type canvas_item;
render_mode blend_mix;

// ============================================
// 像素化参数
// ============================================
uniform float pixel_size : hint_range(1.0, 64.0, 0.1) = 4.0;
uniform bool enable_pixelation = true;

// ============================================
// 颜色量化参数
// ============================================
uniform int color_levels : hint_range(2, 256, 1) = 8;
uniform bool enable_quantization = true;

// ============================================
// 描边参数
// ============================================
uniform bool enable_outline = true;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.5, 10.0, 0.1) = 1.5;
uniform float outline_alpha : hint_range(0.0, 1.0, 0.01) = 0.8;
uniform float outline_threshold : hint_range(0.0, 1.0, 0.01) = 0.15;

// ============================================
// Helper 函数：像素化 UV 坐标
// ============================================
vec2 pixelate_uv(vec2 uv, float size) {
    vec2 texel_size = TEXTURE_PIXEL_SIZE;
    vec2 grid_size = texel_size * size;
    return floor(uv / grid_size) * grid_size;
}

// ============================================
// Helper 函数：颜色量化
// 减少颜色级别，模拟复古游戏机调色板
// ============================================
vec3 quantize_color(vec3 color, int levels) {
    float f = float(levels - 1);
    return floor(color * f + 0.5) / f;
}

// ============================================
// Helper 函数：边缘检测
// 基于 alpha 通道的 Sobel 算子
// ============================================
float detect_edge(vec2 uv, vec2 texel_size) {
    vec4 center = texture(TEXTURE, uv);

    // 跳过完全透明的像素
    if (center.a < 0.01) {
        return 0.0;
    }

    // 采样相邻像素的 alpha 值
    float left = texture(TEXTURE, uv + vec2(-texel_size.x, 0.0)).a;
    float right = texture(TEXTURE, uv + vec2(texel_size.x, 0.0)).a;
    float top = texture(TEXTURE, uv + vec2(0.0, -texel_size.y)).a;
    float bottom = texture(TEXTURE, uv + vec2(0.0, texel_size.y)).a;

    // Sobel 边缘检测算子
    float sobel_h = abs(left - right);
    float sobel_v = abs(top - bottom);
    float edge = sqrt(sobel_h * sobel_h + sobel_v * sobel_v);

    return edge;
}

// ============================================
// 主 fragment 函数
// ============================================
void fragment() {
    vec2 texel_size = TEXTURE_PIXEL_SIZE;

    // 步骤 1: 像素化
    vec2 uv = UV;
    if (enable_pixelation) {
        uv = pixelate_uv(UV, pixel_size);
    }

    // 获取基础颜色
    vec4 base_color = texture(TEXTURE, uv);

    // 步骤 2: 颜色量化
    if (enable_quantization) {
        base_color.rgb = quantize_color(base_color.rgb, color_levels);
    }

    // 步骤 3: 边缘检测与描边
    if (enable_outline) {
        // 使用像素化后的 texel_size 进行边缘检测
        vec2 edge_texel_size = texel_size * outline_width;
        float edge = detect_edge(UV, edge_texel_size);

        // 应用阈值
        if (edge > outline_threshold) {
            // 根据描边 alpha 混合白色
            vec3 final_outline = mix(base_color.rgb, outline_color.rgb, outline_alpha);
            base_color.rgb = final_outline;
        }
    }

    // 输出最终颜色
    COLOR = base_color;
}
```

## 使用说明

### 在 Godot 中使用

1. **创建 ShaderMaterial**
   - 选择 Sprite2D 或 TextureRect 节点
   - 在 Inspector 中点击 Material 属性
   - 选择 "New ShaderMaterial"

2. **加载 Shader**
   - 在 ShaderMaterial 中点击 Shader 属性
   - 选择 "New Shader" 或 "Load"
   - 浏览并选择 `img/pixel_outline.gdshader`

3. **调整参数**
   - `pixel_size`：调整像素化程度（值越大，像素块越大）
   - `color_levels`：调整颜色级别（值越小，颜色越少，越复古）
   - `outline_width`：调整描边宽度
   - `outline_alpha`：调整描边透明度
   - `outline_threshold`：调整边缘检测灵敏度

### 3D 转 2D 工作流

1. 创建 Camera3D 或 Camera2D 捕获 3D 对象
2. 使用 Viewport 节点将摄像机输出渲染为纹理
3. 使用 ViewportTexture 作为 Sprite2D 的纹理
4. 应用本 shader 到 Sprite2D 获得像素化 + 描边效果

## 验证标准

- ✅ 文件创建于 `img/pixel_outline.gdshader`
- ✅ shader 语法正确（符合 Godot 4.6 CanvasItemShader 规范）
- ✅ 包含所有必需的 uniform 参数
- ✅ 包含三个核心函数：pixelate_uv, quantize_color, detect_edge
- ✅ fragment 函数正确实现像素化、颜色量化和描边叠加
