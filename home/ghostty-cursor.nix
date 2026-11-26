# Animated cursor in Ghostty: when the cursor jumps (a search hit, a mouse click, `gg` in
# Neovim, ...), a short streak in the cursor's colour slides from the old position to the new one
# and fades out within 0.15 s. Moving one cell at a time while typing draws nothing.
#
# It is a Ghostty custom shader: a small GLSL program run on every frame, using the cursor
# position Ghostty passes in (iCurrentCursor / iPreviousCursor). To turn it off, remove this
# file from home/default.nix.
{ pkgs, ... }:

let
  cursorTrail = pkgs.writeText "cursor-trail.glsl" ''
    const float DURATION = 0.15; // seconds the streak lasts
    const float MIN_JUMP = 1.5;  // in cursor heights; shorter moves (typing) draw nothing

    // Distance from p to the line segment a-b.
    float segmentDistance(vec2 p, vec2 a, vec2 b) {
        vec2 pa = p - a;
        vec2 ba = b - a;
        float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
        return length(pa - ba * h);
    }

    // Ghostty gives the cursor as (left, top, width, height), y pointing up.
    vec2 cursorCenter(vec4 c) {
        return vec2(c.x + c.z * 0.5, c.y - c.w * 0.5);
    }

    void mainImage(out vec4 fragColor, in vec2 fragCoord) {
        fragColor = texture(iChannel0, fragCoord / iResolution.xy);

        float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
        if (progress >= 1.0 || iFocus == 0) {
            return;
        }

        vec2 current = cursorCenter(iCurrentCursor);
        vec2 previous = cursorCenter(iPreviousCursor);
        if (distance(current, previous) < MIN_JUMP * iCurrentCursor.w) {
            return;
        }

        // The tail starts at the old position and catches up with the cursor, fast at first.
        float eased = 1.0 - pow(1.0 - progress, 3.0);
        vec2 tail = mix(previous, current, eased);
        float radius = 0.5 * min(iCurrentCursor.z, iCurrentCursor.w);
        float edge = segmentDistance(fragCoord, tail, current) - radius;
        float coverage = 1.0 - smoothstep(-1.0, 1.0, edge);

        float alpha = coverage * (1.0 - progress) * 0.8;
        fragColor = mix(fragColor, vec4(iCurrentCursorColor.rgb, 1.0), alpha);
    }
  '';
in
{
  programs.ghostty.settings.custom-shader = "${cursorTrail}";
}
