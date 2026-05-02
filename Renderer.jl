module Renderer

export update!, start!, Vector2, Vector2Int, FRAMERATE, project


using GLMakie
using DataStructures

struct Vector2Int
    x::Int
    y::Int
end
struct Vector2
    x::Float64
    y::Float64
end

const FRAMERATE = 160
const FARPLANE = 1000
const NEARPLANE = 0.1
const FOV = 60
const RED = RGBf(1, 0, 0)
const GREEN = RGBf(0, 1, 0)
const BLUE = RGBf(0, 0, 1)

function project(p::Matrix, f, n, fov)
    f1 = -f/(f-n)
    S = 1/tan((fov/2) * (π/180))
    transform = [
        S 0 0    0
        0 S 0    0
        0 0 f1   -1
        0 0 f1*n 0
    ]
    viewport = [
        0   0   0 0
        0   0   0 0
        0   0   0 0
        0 -10 -20 0
    ]

    [p 1] * viewport * transform
end

function loop!(fig::Figure, dims::Vector2Int, _buf)   #Called every frame the window is open
    println("Started v1...")

    verts = [
        [-16, -16, 16],
        [16, -16, 16],
        [-16, 16, 16],
        [16, 16, 16],
        [-16, -16, 64],
        [16, -16, 64],
        [-16, 16, 64],
        [16, 16, 64]
    ]

    speed = 32
    x = dims.x/2
    y = dims.y/2
    buf = _buf[]

    while events(fig).window_open[]
        fill!(buf, RGBf(0, 0, 0))                               #Reset buffer with zeros

        if ispressed(fig.scene, Keyboard.left_alt & Keyboard.f2)
            GLMakie.closeall();
        end

        a = speed / FRAMERATE

        if ispressed(fig.scene, Keyboard.a)
            x -= a
        end
        if ispressed(fig.scene, Keyboard.d)
            x += a
        end
        if ispressed(fig.scene, Keyboard.s)
            y -= a
        end
        if ispressed(fig.scene, Keyboard.w)
            y += a
        end

        rx = round(Int, x)
        ry = round(Int, y)

        # drawline!(RGBf(0, 1, 0), Vector2Int(1, 1), Vector2Int(rx, ry), buf)
        foreach(verts) do v
            vp = project([v[1] v[2] v[3]], FARPLANE, NEARPLANE, FOV)
            buf[round(Int, vp[1] + dims.x/2), round(Int, vp[2] + dims.y/2)] = GREEN
        end

        buf[rx, ry] = RED

        _buf[] = buf
        notify(_buf)

        sleep(1/FRAMERATE)
    end
end
function drawline!(color::RGBf, a::Vector2Int, b::Vector2Int, buf)
    pts = bressenham(a, b)
    foreach(pts) do p
        buf[p.x, p.y] = color
    end
end
function bressenham(a, b)
    pts = Vector{Vector2Int}()

    x0 = a.x
    y0 = a.y
    x1 = b.x
    y1 = b.y

    dx = abs(x1 - x0)
    sx = x0 < x1 ? 1 : -1
    dy = -abs(y1 - y0)
    sy = y0 < y1 ? 1 : -1
    error = dx + dy

    if x0 == x1         #Vertical line
        for i in y0:y1
            push!(pts, Vector2Int(round(Int, x0), round(Int, i)))
        end
    elseif y0 == y1     #Horizontal line
        for i in x0:x1
            push!(pts, Vector2Int(round(Int, i), round(Int, y0)))
        end
    else
        while true
            push!(pts, Vector2Int(round(Int, x0), round(Int, y0)))
            e2 = 2 * error

            if e2 >= dy
                if x0 == x1 
                    break
                end
                error = error + dy
                x0 += sx
            end
            if e2 <= dx
                if y0 == y1 
                    break
                end
                error = error + dx
                y0 += sy
            end
        end
    end
    pts
end
# function start!(fig::Figure, dims::Vector2Int, buf)    #Called when figure is first displayed
#     # buf[][x, y] = RGBf(x/dims.x, y/dims.y, 0.5)
#     println("Started...")
# end

end