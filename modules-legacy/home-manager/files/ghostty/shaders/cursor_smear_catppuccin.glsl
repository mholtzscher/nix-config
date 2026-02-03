// Catppuccin Mocha cursor smear shader
// Based on cursor_smear_rainbow.glsl from ghostty-shader-playground
// Colors from: https://catppuccin.com/palette

// Catppuccin Mocha palette
const vec3 ROSEWATER = vec3(0.961, 0.871, 0.871);  // #f5e0dc
const vec3 FLAMINGO  = vec3(0.949, 0.804, 0.804);  // #f2cdcd
const vec3 PINK      = vec3(0.961, 0.761, 0.906);  // #f5c2e7
const vec3 MAUVE     = vec3(0.796, 0.651, 0.969);  // #cba6f7
const vec3 RED       = vec3(0.949, 0.545, 0.659);  // #f38ba8
const vec3 MAROON    = vec3(0.922, 0.620, 0.678);  // #eba0ac
const vec3 PEACH     = vec3(0.980, 0.702, 0.529);  // #fab387
const vec3 YELLOW    = vec3(0.976, 0.886, 0.686);  // #f9e2af
const vec3 GREEN     = vec3(0.651, 0.890, 0.631);  // #a6e3a1
const vec3 TEAL      = vec3(0.596, 0.894, 0.843);  // #94e2d5
const vec3 SKY       = vec3(0.537, 0.863, 0.922);  // #89dceb
const vec3 SAPPHIRE  = vec3(0.455, 0.776, 0.898);  // #74c7ec
const vec3 BLUE      = vec3(0.537, 0.706, 0.980);  // #89b4fa
const vec3 LAVENDER  = vec3(0.702, 0.749, 0.945);  // #b4befe

float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Based on Inigo Quilez's 2D distance functions article: https://iquilezles.org/articles/distfunctions2d/
// Potencially optimized by eliminating conditionals and loops to enhance performance and reduce branching

float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
    float s = 1.0;
    float d = dot(p - v0, p - v0);

    d = seg(p, v0, v3, s, d);
    d = seg(p, v1, v0, s, d);
    d = seg(p, v2, v1, s, d);
    d = seg(p, v3, v2, s, d);

    return s * sqrt(d);
}

vec2 norm(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float antialising(float distance) {
    return 1. - smoothstep(0., norm(vec2(2., 2.), 0.).x, distance);
}

float determineStartVertexFactor(vec2 a, vec2 b) {
    // Conditions using step
    float condition1 = step(b.x, a.x) * step(a.y, b.y); // a.x < b.x && a.y > b.y
    float condition2 = step(a.x, b.x) * step(b.y, a.y); // a.x > b.x && a.y < b.y

    // If neither condition is met, return 1 (else case)
    return 1.0 - max(condition1, condition2);
}

vec2 getRectangleCenter(vec4 rectangle) {
    return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
}

float ease(float x) {
    return pow(1.0 - x, 3.0);
}

// Boost saturation for more vibrant colors
vec3 saturate(vec3 color, float amount) {
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), color, 1.0 + amount);
}

// Smooth interpolation between Catppuccin colors
vec3 getCatppuccinColor(float t) {
    // Cycle through accent colors: mauve -> pink -> red -> peach -> yellow -> green -> teal -> sky -> sapphire -> blue -> lavender
    float segment = mod(t, 1.0) * 11.0;
    int idx = int(floor(segment));
    float f = fract(segment);
    
    vec3 c0, c1;
    
    if (idx == 0) { c0 = MAUVE; c1 = PINK; }
    else if (idx == 1) { c0 = PINK; c1 = RED; }
    else if (idx == 2) { c0 = RED; c1 = MAROON; }
    else if (idx == 3) { c0 = MAROON; c1 = PEACH; }
    else if (idx == 4) { c0 = PEACH; c1 = YELLOW; }
    else if (idx == 5) { c0 = YELLOW; c1 = GREEN; }
    else if (idx == 6) { c0 = GREEN; c1 = TEAL; }
    else if (idx == 7) { c0 = TEAL; c1 = SKY; }
    else if (idx == 8) { c0 = SKY; c1 = SAPPHIRE; }
    else if (idx == 9) { c0 = SAPPHIRE; c1 = BLUE; }
    else { c0 = BLUE; c1 = LAVENDER; }
    
    vec3 color = mix(c0, c1, f);
    // Boost saturation by 40% for more vibrant colors
    return saturate(color, 0.4);
}

const float DURATION = 0.5; //IN SECONDS

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    // Normalization for fragCoord to a space of -1 to 1;
    vec2 vu = norm(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);

    // Catppuccin color cycling based on time and position
    // Speed multiplier: 0.3 = slow, 1.0 = medium, 2.0+ = fast
    float colorPhase = iTime * 3.0 + vu.x * 0.5 + vu.y * 0.3;
    vec3 catColor = getCatppuccinColor(colorPhase);
    vec4 color = vec4(catColor, 1.0);

    // Normalization for cursor position and size;
    // cursor xy has the postion in a space of -1 to 1;
    // zw has the width and height
    vec4 currentCursor = vec4(norm(iCurrentCursor.xy, 1.), norm(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(norm(iPreviousCursor.xy, 1.), norm(iPreviousCursor.zw, 0.));

    // When drawing a parellelogram between cursors for the trail i need to determine where to start at the top-left or top-right vertex of the cursor
    float vertexFactor = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
    float invertedVertexFactor = 1.0 - vertexFactor;

    // Set every vertex of my parellogram
    vec2 v0 = vec2(currentCursor.x + currentCursor.z * vertexFactor, currentCursor.y - currentCursor.w);
    vec2 v1 = vec2(currentCursor.x + currentCursor.z * invertedVertexFactor, currentCursor.y);
    vec2 v2 = vec2(previousCursor.x + currentCursor.z * invertedVertexFactor, previousCursor.y);
    vec2 v3 = vec2(previousCursor.x + currentCursor.z * vertexFactor, previousCursor.y - previousCursor.w);

    float sdfCurrentCursor = getSdfRectangle(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);
    float sdfTrail = getSdfParallelogram(vu, v0, v1, v2, v3);

    float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);

    float easedProgress = ease(progress);
    // Distance between cursors determine the total length of the parallelogram;
    vec2 centerCC = getRectangleCenter(currentCursor);
    vec2 centerCP = getRectangleCenter(previousCursor);
    float lineLength = distance(centerCC, centerCP);

    vec4 newColor = vec4(fragColor);
    // Compute fade factor based on distance along the trail
    float fadeFactor = 1.0 - smoothstep(lineLength, sdfCurrentCursor, easedProgress * lineLength);

    // Apply fading effect to trail color
    vec4 fadedTrailColor = color * fadeFactor;

    // Blend trail with fade effect
    newColor = mix(newColor, fadedTrailColor, antialising(sdfTrail));
    // Draw current cursor
    newColor = mix(newColor, color, antialising(sdfCurrentCursor));
    newColor = mix(newColor, fragColor, step(sdfCurrentCursor, 0.));
    fragColor = mix(fragColor, newColor, step(sdfCurrentCursor, easedProgress * lineLength));
}
