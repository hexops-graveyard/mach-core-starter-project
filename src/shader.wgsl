// Our vertex shader program. Called once for each vertex
@vertex fn vertex_main(
    @builtin(vertex_index) VertexIndex : u32
) -> @builtin(position) vec4<f32> {
    // The goal of this function is to determine the final position of the vertex
    // which the GPU will use to rasterize into fragments.

    // Right now, our program only gets a vertex index as input - so we hard-code
    // the coordinates of a triangle and look up the position in this array based
    // on the index:
    var pos = array<vec2<f32>, 3>(
        vec2<f32>( 0.0,  0.5),
        vec2<f32>(-0.5, -0.5),
        vec2<f32>( 0.5, -0.5)
    );

    // The output of a vertex shader is a vec4 - the position of the vertex in
    // 4D homogeneous clip space. See https://machengine.org/engine/math/traversing-coordinate-systems/
    // but in general you can think of this as just a point in 3D space, and pretend W is always
    // 1.
    return vec4<f32>(pos[VertexIndex], 0.0, 1.0);
}

// Our fragment shader program. Called once for each fragment
@fragment fn frag_main() -> @location(0) vec4<f32> {
    // The goal of this function is to return which color the fragment should be,
    // we simply return a hard-coded RGBA color here.
    return vec4<f32>(0.247, 0.608, 0.043, 1.0);
}
