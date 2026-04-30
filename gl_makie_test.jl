module Renderer

using GLMakie

struct Vector2Int
    x::Int
    y::Int
end
struct Vector2
    x::Float64
    y::Float64
end

#Start rendering to GLMakie window
function plot(w, h)
    f = Figure()
    ax = Axis(f[1, 1], aspect = DataAspect())

    buf = zeros(RGBf, w, h)
    render_loop!(Vector2Int(w, h), f, buf)

    image!(ax, 0..w, 0..h, buf, interpolate=false)
    display(f)
end
function render_loop!(di::Vector2Int, f, buf)
    hotkey = Keyboard.a
    held = false;
    on(events(f).keyboardbutton) do event
        if event.action in (Keyboard.press)
            if event.key == hotkey
                held = true
            end
        elseif event.action in (Keyboard.release)
            if event.key == hotkey
                held = false
            end
        end
    end
    if held
        println("Holding...")
    end
end

end