// DVD Bouncing Logo Screensaver - Paytient Edition
// Bounces the Paytient logo around the screen, changing color on each bounce

// Catppuccin Mocha accent colors for bounce color changes
const vec3 COLORS[8] = vec3[8](
    vec3(0.796, 0.651, 0.969),  // mauve #cba6f7
    vec3(0.961, 0.761, 0.906),  // pink #f5c2e7
    vec3(0.949, 0.545, 0.659),  // red #f38ba8
    vec3(0.980, 0.702, 0.529),  // peach #fab387
    vec3(0.976, 0.886, 0.686),  // yellow #f9e2af
    vec3(0.651, 0.890, 0.631),  // green #a6e3a1
    vec3(0.596, 0.894, 0.843),  // teal #94e2d5
    vec3(0.537, 0.706, 0.980)   // blue #89b4fa
);

// Logo size and movement speed
const float LOGO_SCALE = 0.045;
const float SPEED = 0.12;

// SDF primitives
float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

// The Paytient "P" icon - orange shape with notch
float paytientIcon(vec2 p) {
    // Main rounded rectangle body
    float outer = sdRoundedBox(p - vec2(0.0, 0.0), vec2(0.8, 1.0), 0.35);
    
    // Cut out the bottom-right to make the P shape
    // This creates the "notch" that makes it look like a P
    float cutout = sdRoundedBox(p - vec2(0.45, -0.55), vec2(0.55, 0.55), 0.25);
    
    // Inner cutout for the P hole (top right area)
    float innerHole = sdRoundedBox(p - vec2(0.15, 0.35), vec2(0.35, 0.35), 0.2);
    
    float d = max(outer, -cutout);
    d = max(d, -innerHole);
    
    return d;
}

// Letter p (lowercase)
float letterP_lower(vec2 p) {
    // Vertical stem with descender
    float stem = sdBox(p - vec2(-0.15, -0.1), vec2(0.08, 0.5));
    // Bowl
    float bowlOuter = sdRoundedBox(p - vec2(0.05, 0.15), vec2(0.25, 0.25), 0.15);
    float bowlInner = sdRoundedBox(p - vec2(0.08, 0.15), vec2(0.12, 0.12), 0.08);
    float bowl = max(bowlOuter, -bowlInner);
    return min(stem, bowl);
}

// Letter a (lowercase)
float letterA_lower(vec2 p) {
    // Bowl
    float bowlOuter = sdRoundedBox(p, vec2(0.22, 0.22), 0.12);
    float bowlInner = sdRoundedBox(p - vec2(-0.02, 0.02), vec2(0.1, 0.1), 0.06);
    float bowl = max(bowlOuter, -bowlInner);
    // Right stem
    float stem = sdBox(p - vec2(0.14, 0.0), vec2(0.08, 0.22));
    return min(bowl, stem);
}

// Letter y (lowercase)  
float letterY_lower(vec2 p) {
    // Left diagonal going down
    float left = sdBox(p - vec2(-0.08, 0.08), vec2(0.08, 0.18));
    // Right stem going all the way down
    float right = sdBox(p - vec2(0.08, -0.08), vec2(0.08, 0.34));
    // Descender curve
    float desc = sdRoundedBox(p - vec2(-0.05, -0.35), vec2(0.18, 0.1), 0.08);
    return min(min(left, right), desc);
}

// Letter t (lowercase)
float letterT_lower(vec2 p) {
    // Vertical stem
    float stem = sdBox(p - vec2(0.0, 0.05), vec2(0.07, 0.32));
    // Crossbar
    float cross = sdBox(p - vec2(0.0, 0.22), vec2(0.15, 0.06));
    return min(stem, cross);
}

// Letter i (lowercase)
float letterI_lower(vec2 p) {
    // Stem
    float stem = sdBox(p - vec2(0.0, 0.0), vec2(0.07, 0.22));
    // Dot
    float dot = sdCircle(p - vec2(0.0, 0.38), 0.08);
    return min(stem, dot);
}

// Letter e (lowercase)
float letterE_lower(vec2 p) {
    // Outer bowl
    float outer = sdRoundedBox(p, vec2(0.22, 0.22), 0.14);
    // Inner cutout
    float inner = sdRoundedBox(p - vec2(0.02, 0.02), vec2(0.1, 0.1), 0.06);
    // Middle bar
    float bar = sdBox(p - vec2(-0.02, 0.02), vec2(0.18, 0.05));
    // Opening on right
    float opening = sdBox(p - vec2(0.15, -0.08), vec2(0.12, 0.08));
    
    float d = max(outer, -inner);
    d = min(d, max(outer, bar));
    d = max(d, -opening);
    return d;
}

// Letter n (lowercase)
float letterN_lower(vec2 p) {
    // Left stem
    float left = sdBox(p - vec2(-0.12, 0.0), vec2(0.07, 0.22));
    // Right stem
    float right = sdBox(p - vec2(0.12, 0.0), vec2(0.07, 0.22));
    // Arch
    float arch = sdRoundedBox(p - vec2(0.0, 0.12), vec2(0.19, 0.12), 0.1);
    float archInner = sdRoundedBox(p - vec2(0.0, 0.08), vec2(0.08, 0.08), 0.05);
    float archShape = max(arch, -archInner);
    
    return min(min(left, right), archShape);
}

// Draw "paytient" text (lowercase)
float drawText(vec2 p) {
    float d = 1e10;
    float spacing = 0.52;
    float x = -3.5 * spacing;
    
    // p
    d = min(d, letterP_lower(p - vec2(x, 0.0)));
    x += spacing;
    
    // a
    d = min(d, letterA_lower(p - vec2(x, 0.0)));
    x += spacing;
    
    // y
    d = min(d, letterY_lower(p - vec2(x, 0.05)));
    x += spacing;
    
    // t
    d = min(d, letterT_lower(p - vec2(x, 0.0)));
    x += spacing;
    
    // i
    d = min(d, letterI_lower(p - vec2(x, 0.0)));
    x += spacing;
    
    // e
    d = min(d, letterE_lower(p - vec2(x, 0.0)));
    x += spacing;
    
    // n
    d = min(d, letterN_lower(p - vec2(x, 0.0)));
    x += spacing;
    
    // t
    d = min(d, letterT_lower(p - vec2(x, 0.0)));
    
    return d;
}

// Draw the complete Paytient logo (icon + text)
void drawLogo(vec2 p, vec3 color, out vec3 outColor, out float outAlpha) {
    outColor = vec3(0.0);
    outAlpha = 0.0;
    
    // Icon on the left (scaled up relative to text)
    vec2 iconPos = p - vec2(-3.2, 0.15);
    float iconScale = 0.4;
    float icon = paytientIcon(iconPos / iconScale) * iconScale;
    float iconMask = smoothstep(0.02, 0.0, icon);
    
    // Text on the right
    float text = drawText(p - vec2(0.8, 0.0));
    float textMask = smoothstep(0.05, 0.0, text);
    
    // Combine
    outAlpha = max(iconMask, textMask);
    outColor = color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Get the original terminal content
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    
    vec2 uv = fragCoord.xy / iResolution.xy;
    float aspect = iResolution.x / iResolution.y;
    
    // Adjust UV for aspect ratio
    vec2 uvAspect = vec2(uv.x * aspect, uv.y);
    
    // Logo dimensions (approximate)
    float logoWidth = 5.5 * LOGO_SCALE;
    float logoHeight = LOGO_SCALE * 1.2;
    
    // Calculate bounce boundaries
    float minX = logoWidth / 2.0 + 0.08;
    float maxX = aspect - logoWidth / 2.0 - 0.08;
    float minY = logoHeight / 2.0 + 0.08;
    float maxY = 1.0 - logoHeight / 2.0 - 0.08;
    
    // Calculate position using ping-pong (triangle wave) for bouncing
    float rangeX = maxX - minX;
    float rangeY = maxY - minY;
    
    // Different speeds for X and Y to create interesting patterns
    float timeX = iTime * SPEED * 1.1;
    float timeY = iTime * SPEED * 0.8;
    
    // Triangle wave for smooth bouncing (ping-pong)
    float pingPongX = abs(mod(timeX, 2.0 * rangeX) - rangeX);
    float pingPongY = abs(mod(timeY, 2.0 * rangeY) - rangeY);
    
    vec2 logoCenter = vec2(minX + pingPongX, minY + pingPongY);
    
    // Count bounces to determine color
    int bouncesX = int(timeX / rangeX);
    int bouncesY = int(timeY / rangeY);
    int totalBounces = bouncesX + bouncesY;
    int colorIndex = totalBounces % 8;
    
    vec3 logoColor = COLORS[colorIndex];
    
    // Transform to logo space
    vec2 logoUV = (uvAspect - logoCenter) / LOGO_SCALE;
    
    // Draw the logo
    vec3 color;
    float alpha;
    drawLogo(logoUV, logoColor, color, alpha);
    
    // Composite onto the terminal
    vec3 finalColor = mix(fragColor.rgb, color, alpha * 0.95);
    
    fragColor = vec4(finalColor, fragColor.a);
}
