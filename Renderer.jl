module Renderer

export update!, start!, Vector2, Vector2Int, FRAMERATE, project


using GLMakie
using DataStructures

mutable struct Vector2Int
    x::Int
    y::Int
end
mutable struct Vector2
    x
    y
end
mutable struct Edge
    a::Vector
    b::Vector
end
mutable struct Camera
    position::Vector
    eulers::Vector
    nearplane
    fov
    dims::Vector2Int
end

const FRAMERATE = 160
const NEARPLANE = 1
const FOV = 60
const RED = RGBf(1, 0, 0)
const GREEN = RGBf(0, 1, 0)
const BLUE = RGBf(0, 0, 1)

function project(p::Vector, camera::Camera)#eye::Vector, θe::Vector, dims::Vector2Int, n, fov)
    eye = camera.position
    θe = camera.eulers
    dims = camera.dims
    n = camera.nearplane
    fov = camera.fov

    _r = tan((fov/2) * (π/180)) * 2*n

    r = [_r, (_r*dims.y)/dims.x]
    s = [dims.x/2, dims.y/2]
    θ = θe * (π/180)
    
    rela = [
        1 0          0
        0 cos(θ[1])  sin(θ[1])
        0 -sin(θ[1]) cos(θ[1])
    ]
    relb = [
        cos(θ[2]) 0 -sin(θ[2])
        0         1  0
        sin(θ[2]) 0  cos(θ[2])
    ]
    relc = [
        cos(θ[3]) sin(θ[3]) 0
       -sin(θ[3]) cos(θ[3]) 0
        0         0         1
    ]

    #The relative position of the point-to-project to the camera / eye
    d = rela * relb * relc * (p - eye)

    [
        (d[1] * s[1])/(d[3] * r[1]) * n + dims.x/2,
        (d[2] * s[2])/(d[3] * r[2]) * n + dims.y/2
    ]
end

function loop!(fig::Figure, dims::Vector2Int, _buf)   #Called every frame the window is open
    println("Started v1...")

    r_speed = 120    #Angular speed
    speed = 100      #Linear speed
    ϕ = 0           #Rotation across the X axis
    θ = 0           #Rotation across the Y axis
    eye = [0, 0, 0] #Camera / eye position (x, y, z)
    buf = _buf[]

    edges = cube([0, 0, 32], 32)

    _mouse = mouseposition_px(fig.scene)

    while events(fig).window_open[]
        fill!(buf, RGBf(0, 0, 0))                               #Reset buffer with zeros

        Δmouse = _mouse - mouseposition_px(fig.scene)

        if ispressed(fig.scene, Keyboard.left_alt & Keyboard.f2)
            GLMakie.closeall();
        end

        Δtθ = r_speed / FRAMERATE
        Δt = speed / FRAMERATE

        if ispressed(fig.scene, Keyboard.left)
            θ -= Δtθ
        end
        if ispressed(fig.scene, Keyboard.right)
            θ += Δtθ
        end
        if ispressed(fig.scene, Keyboard.down)
            ϕ += Δtθ
        end
        if ispressed(fig.scene, Keyboard.up)
            ϕ -= Δtθ
        end

        fwd = [
            cos(ϕ * (π/180))*sin(θ * (π/180)),
            sin(-ϕ * (π/180)), 
            cos(ϕ * (π/180))*cos(θ * (π/180))
        ]
        up = [
            0,
            fwd[3],
            -fwd[2]
        ]
        wup = [0, 1, 0]
        right = [
            fwd[3],
            0,
            -fwd[1]
        ]

        if ispressed(fig.scene, Keyboard.a)
            eye -= Δt * right
        end
        if ispressed(fig.scene, Keyboard.d)
            eye += Δt * right
        end
        if ispressed(fig.scene, Keyboard.s)
            eye -= Δt * fwd
        end
        if ispressed(fig.scene, Keyboard.w)
            eye += Δt * fwd
        end
        if ispressed(fig.scene, Keyboard.left_control)
            eye -= Δt * wup
        end
        if ispressed(fig.scene, Keyboard.space)
            eye += Δt * wup
        end

        rθ = round(Int, θ)
        rϕ = round(Int, ϕ)

        cam = Camera(eye, [rϕ, rθ, 0], NEARPLANE, FOV, dims)

        # drawline!(RGBf(0, 1, 0), Vector2Int(1, 1), Vector2Int(rx, ry), buf)
        # foreach(verts) do v
        #     vp = project(v, cam)
        # end

        # drawcube!(GREEN, cam, [0, 0, 64], 32, buf)
        drawcube!(GREEN, edges, cam, buf)

        buf[round(Int, dims.x/2), round(Int, dims.y/2)] = RED

        _mouse = mouseposition_px(fig.scene)

        _buf[] = buf
        notify(_buf)

        sleep(1/FRAMERATE)
    end
end
function drawline2d!(color::RGBf, a::Vector, b::Vector, dims::Vector2Int, buf)
    pts = bressenham(round.(Int, a), round.(Int, b))
    foreach(pts) do p
        drawpoint2d!(color, [p[1], p[2]], dims, buf)
    end
end
function drawpoint2d!(color::RGBf, vp::Vector, dims::Vector2Int, buf)
    if !((round(Int, vp[1]) < 1 || round(Int, vp[1]) > dims.x) || (round(Int, vp[2]) < 1 || round(Int, vp[2]) > dims.y)) #Make sure that point Vp is within screen bounds
        buf[round(Int, vp[1]), round(Int, vp[2])] = color
    end
end
function drawcube!(color::RGBf, edges::Vector{Edge}, camera, buf)
    foreach(edges) do edge
        # drawpoint2d!(color, project(edge.a, camera), camera.dims, buf)
        drawline2d!(color, project(edge.a, camera), project(edge.b, camera), camera.dims, buf)
    end
end
function bressenham(a::Vector, b::Vector)
    pts = Vector{Vector}()

    x0 = a[1]
    y0 = a[2]
    x1 = b[1]
    y1 = b[2]

    function plotLineLow!(x0, y0, x1, y1, ps)
        dx = x1 - x0
        dy = y1 - y0
        yi = 1
        if dy < 0
            yi = -1
            dy = -dy
        end
        D = (2 * dy) - dx
        y = y0

        for x in x0 : x1
            push!(ps, [x, y])
            if D > 0
                y = y + yi
                D = D + (2 * (dy - dx))
            else
                D = D + 2*dy
            end
        end
    end
    function plotLineHigh!(x0, y0, x1, y1, ps)
        dx = x1 - x0
        dy = y1 - y0
        xi = 1
        if dx < 0
            xi = -1
            dx = -dx
        end
        D = (2 * dx) - dy
        x = x0

        for y in y0 : y1
            push!(ps, [x, y])
            if D > 0
                x = x + xi
                D = D + (2 * (dx - dy))
            else
                D = D + 2*dx
            end
        end
    end

    if abs(y1 - y0) < abs(x1 - x0)
        if x0 > x1
            plotLineLow!(x1, y1, x0, y0, pts)
        else
            plotLineLow!(x0, y0, x1, y1, pts)
        end
    else
        if y0 > y1
            plotLineHigh!(x1, y1, x0, y0, pts)
        else
            plotLineHigh!(x0, y0, x1, y1, pts)
        end
    end

    pts
end
function cube(pos::Vector, scale)
    rscale = scale/2

    a = [-rscale, -rscale, rscale] + pos
    b = [-rscale, rscale, rscale] + pos
    c = [rscale, rscale, rscale] + pos
    d = [rscale, -rscale, rscale] + pos

    e = [-rscale, -rscale, -rscale] + pos
    f = [-rscale, rscale, -rscale] + pos
    g = [rscale, rscale, -rscale] + pos
    h = [rscale, -rscale, -rscale] + pos


    [
        #a to b to c to d to a = square edges
        Edge(a, b),
        Edge(b, c),
        Edge(c, d),
        Edge(d, a),

        #e to f to g to h to e = square edges
        Edge(e, f),
        Edge(f, g),
        Edge(g, h),
        Edge(h, e),
        
        # a to e; b to f; c to g; d to h; = connecting edges
        Edge(a, e),
        Edge(b, f),
        Edge(c, g),
        Edge(d, h)
    ]
end
# function start!(fig::Figure, dims::Vector2Int, buf)    #Called when figure is first displayed
#     # buf[][x, y] = RGBf(x/dims.x, y/dims.y, 0.5)
#     println("Started...")
# end

end