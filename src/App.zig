const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;

// Globally unique name of our module
pub const name = .app;

pub const Mod = mach.Mod(@This());

pub const events = .{
    .deinit = .{ .handler = deinit },
    .init = .{ .handler = init },
    .tick = .{ .handler = tick },
};

pipeline: *gpu.RenderPipeline,

fn deinit(core: *mach.Core.Mod) void {
    core.send(.deinit, .{});
}

fn init(app: *Mod, core: *mach.Core.Mod) !void {
    // Create our shader module
    const shader_module = mach.core.device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
    defer shader_module.release();

    // Blend state describes how rendered colors get blended
    const blend = gpu.BlendState{};

    // Color target describes e.g. the pixel format of the window we are rendering to.
    const color_target = gpu.ColorTargetState{
        .format = mach.core.descriptor.format,
        .blend = &blend,
    };

    // Fragment state describes which shader and entrypoint to use for rendering fragments.
    const fragment = gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });

    // Create our render pipeline that will ultimately get pixels onto the screen.
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .vertex = gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertex_main",
        },
    };
    const pipeline = mach.core.device.createRenderPipeline(&pipeline_descriptor);

    // Store our render pipeline in our module's state, so we can access it later on.
    app.init(.{
        .pipeline = pipeline,
    });

    core.send(.start, .{});
}

pub fn tick(
    core: *mach.Core.Mod,
    app: *Mod,
) !void {
    // Poll for input events
    var iter = mach.core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .close => core.send(.exit, .{}), // tell mach.Core to exit the app
            else => {},
        }
    }

    // Grab the back buffer of the swapchain
    const back_buffer_view = mach.core.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Create a command encoder
    const encoder = mach.core.device.createCommandEncoder(null);
    defer encoder.release();

    const sky_blue = gpu.Color{ .r = 0.776, .g = 0.988, .b = 1, .a = 1 };
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .clear_value = sky_blue,
        .load_op = .clear,
        .store_op = .store,
    };
    const render_pass_info = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{color_attachment},
    });
    const pass = encoder.beginRenderPass(&render_pass_info);
    defer pass.release();
    pass.setPipeline(app.state().pipeline);
    pass.draw(3, 1, 0, 0);
    pass.end();

    // Submit our encoded commands to the GPU queue
    var command = encoder.finish(null);
    defer command.release();
    mach.core.queue.submit(&[_]*gpu.CommandBuffer{command});

    // Present the frame
    core.send(.present_frame, .{});
}
