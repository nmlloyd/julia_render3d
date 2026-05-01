module RendererInterface

using GLMakie, DataStructures, Revise

push!(LOAD_PATH, ".")

using Renderer

GLMakie.activate!()

#Start rendering to GLMakie window
function run(w, h)
    fig = Figure()

    buf = Observable(zeros(RGBf, w, h))

    image(fig[1,1], buf, interpolate = false, axis = (aspect = DataAspect(), yreversed = false))
    display(fig)

    render_loop!(fig, Vector2Int(w, h), buf)
end
function render_loop!(fig::Figure, dims::Vector2Int, buf)
    Renderer.loop!(fig, dims, buf)
end

end
#image(buf, colormap = cmap_8bit, colorrange = (0, 255), interpolate = false, axis = (aspect = DataAspect(), yreversed = true))