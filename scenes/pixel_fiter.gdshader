shader_type canvas_item;

// 像素块大小（纹素单位）
uniform int block_size = 2;
// 颜色量化级数（每个通道）
uniform int color_levels = 8;
// 边缘检测阈值（曼哈顿距离，建议 0.2~0.6）
uniform float edge_threshold = 0.3;
// 轮廓颜色（可调整 RGB 和 Alpha，此处仅 RGB 生效，Alpha 使用原图透明度）
uniform vec4 outline_color : source_color = vec4(1.0);

void fragment() {
    ivec2 tex_size = textureSize(TEXTURE, 0);
    vec2 uv = UV;

    // 当前纹素坐标
    ivec2 texel = ivec2(uv * vec2(tex_size));

    // 当前像素块的左上角纹素
    ivec2 block_tl = texel / block_size * block_size;

    // 采样当前块颜色（取块左上角纹素）
    vec4 col = texelFetch(TEXTURE, block_tl, 0);
    vec3 quantized = floor(col.rgb * float(color_levels) + 0.5) / float(color_levels);

    // 相邻块偏移量（水平/垂直）
    ivec2 offset = ivec2(block_size, 0);

    // 左邻居
    ivec2 left_tl = clamp(block_tl - offset, ivec2(0), tex_size - 1);
    vec4 left_col = texelFetch(TEXTURE, left_tl, 0);
    vec3 left_quant = floor(left_col.rgb * float(color_levels) + 0.5) / float(color_levels);

    // 右邻居
    ivec2 right_tl = clamp(block_tl + offset, ivec2(0), tex_size - 1);
    vec4 right_col = texelFetch(TEXTURE, right_tl, 0);
    vec3 right_quant = floor(right_col.rgb * float(color_levels) + 0.5) / float(color_levels);

    // 上邻居
    ivec2 up_tl = clamp(block_tl - offset.yx, ivec2(0), tex_size - 1);
    vec4 up_col = texelFetch(TEXTURE, up_tl, 0);
    vec3 up_quant = floor(up_col.rgb * float(color_levels) + 0.5) / float(color_levels);

    // 下邻居
    ivec2 down_tl = clamp(block_tl + offset.yx, ivec2(0), tex_size - 1);
    vec4 down_col = texelFetch(TEXTURE, down_tl, 0);
    vec3 down_quant = floor(down_col.rgb * float(color_levels) + 0.5) / float(color_levels);

    // 计算曼哈顿距离
    float diff_left   = abs(quantized.r - left_quant.r)   + abs(quantized.g - left_quant.g)   + abs(quantized.b - left_quant.b);
    float diff_right  = abs(quantized.r - right_quant.r)  + abs(quantized.g - right_quant.g)  + abs(quantized.b - right_quant.b);
    float diff_up     = abs(quantized.r - up_quant.r)     + abs(quantized.g - up_quant.g)     + abs(quantized.b - up_quant.b);
    float diff_down   = abs(quantized.r - down_quant.r)   + abs(quantized.g - down_quant.g)   + abs(quantized.b - down_quant.b);

    float max_diff = max(max(max(diff_left, diff_right), diff_up), diff_down);

    vec3 final_color;
    if (max_diff > edge_threshold) {
        final_color = outline_color.rgb;  // 使用可调节的轮廓颜色
    } else {
        final_color = quantized;
    }

    COLOR = vec4(final_color, col.a);
}