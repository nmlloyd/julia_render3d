module Renderer

export update!, start!, Vector2, Vector2Int, FRAMERATE, project


using GLMakie
using DataStructures
using LinearAlgebra
using FileIO
using MeshIO
using GeometryBasics
using MLStyle

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
@enum PrimitiveFaceOrientation Up Back Left Down Right Front

const FRAMERATE = 60
const NEARPLANE = 1
const FOV = 60
const RED = RGBf(1, 0, 0)
const GREEN = RGBf(0, 1, 0)
const BLUE = RGBf(0, 0, 1)
const VUP = [0, 1, 0]
const VRIGHT = [1, 0, 0]
const VFORWARD = [0, 0, 1]

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

    if d[3] > n
        [
            (d[1] * s[1])/(d[3] * r[1]) * n + dims.x/2,
            (d[2] * s[2])/(d[3] * r[2]) * n + dims.y/2
        ]
    else
        return nothing
    end
end

function loop!(fig::Figure, dims::Vector2Int, _buf)   #Called every frame the window is open
    println("Started v1...")

    GLMakie.GLFW.SetInputMode(GLMakie.GLFW.GetCurrentContext(), GLMakie.GLFW.CURSOR, GLMakie.GLFW.CURSOR_HIDDEN)

    r_speed = 12    #Angular speed
    speed = 100     #Linear speed
    ϕ = 0           #Rotation across the X axis (elevation)
    θ = 0           #Rotation across the Y axis (azimuth)
    eye = [0, 0, 0] #Camera / eye position (x, y, z)
    buf = _buf[]

    chunk = [
        [-1, 0, 1],
        [0, 0, 1],
        [1, 0, 1],
        [-1, 1, 1],
        [0, 1, 1],
        [1, 1, 1],
        [-1, -1, 1],
        [0, -1, 1],
        [1, -1, 1]
    ] 

    obj = decompose(Triangle, load("cube.obj").mesh)

    _mouse = mouseposition_px(fig.scene)

    while events(fig).window_open[]
        fill!(buf, RGBf(0, 0, 0))                               #Reset buffer with zeros

        Δmouse = _mouse - mouseposition_px(fig.scene)

        if ispressed(fig.scene, Keyboard.left_alt & Keyboard.f2)
            GLMakie.closeall();
        end

        Δtθ = r_speed / FRAMERATE
        Δt = speed / FRAMERATE

        θ -= (Δmouse * Δtθ)[1]
        ϕ = clamp(ϕ + (Δmouse * Δtθ)[2], -89, 89)

        # if ispressed(fig.scene, Keyboard.left)
        #     θ -= Δtθ
        # end
        # if ispressed(fig.scene, Keyboard.right)
        #     θ += Δtθ
        # end
        # if ispressed(fig.scene, Keyboard.down)
        #     ϕ += Δtθ
        # end
        # if ispressed(fig.scene, Keyboard.up)
        #     ϕ -= Δtθ
        # end

        fwd = [
            cos(ϕ * (π/180))*sin(θ * (π/180)),
            sin(-ϕ * (π/180)), 
            cos(ϕ * (π/180))*cos(θ * (π/180))
        ]
        up = normalize([
            0,
            fwd[3],
            -fwd[2]
        ])
        wup = [0, 1, 0]
        right = normalize([
            fwd[3],
            0,
            -fwd[1]
        ])

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
        # drawcube!(GREEN, edges, cam, buf)
        # drawobj!(GREEN, monkey, [0, 0, 32], 1, cam, buf)
        drawchunk!(GREEN, obj, chunk, 32, cam, buf)
        

        buf[round(Int, dims.x/2), round(Int, dims.y/2)] = RGBf(1, 1, 1)

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
function drawchunk!(color::RGBf, obj, chunk, scale, camera::Camera, buf)
    foreach(chunk) do pos
        upper = true
        lower = true
        right = true
        left = true
        front = true
        back = true

        if in(pos + VUP, chunk)        #Don't draw upper face
            upper = false
        end
        if in(pos - VUP, chunk)        #Don't draw lower face
            lower = false
        end
        if in(pos + VRIGHT, chunk)     #Don't draw right face
            right = false
        end
        if in(pos - VRIGHT, chunk)     #Don't draw left face
            left = false
        end
        if in(pos + VFORWARD, chunk)   #Don't draw back face
            back = false
        end
        if in(pos - VFORWARD, chunk)   #Don't draw front face
            front = false
        end

        if upper
            drawface!(color, obj, Up, pos * scale, 1, camera, buf)
        end
        if left
            drawface!(color, obj, Left, pos * scale, 1, camera, buf)
        end
        if right
            drawface!(color, obj, Right, pos * scale, 1, camera, buf)
        end
        if front
            drawface!(color, obj, Front, pos * scale, 1, camera, buf)
        end
        if back
            drawface!(color, obj, Back, pos * scale, 1, camera, buf)
        end
        if lower
            drawface!(color, obj, Down, pos * scale, 1, camera, buf)
        end
    end
end
function drawobj!(color::RGBf, obj, position::Vector, scale, camera::Camera, buf)
    foreach(obj) do tri 

        v1 = Vector(tri[1]) * scale + position
        v2 = Vector(tri[2]) * scale + position
        v3 = Vector(tri[3]) * scale + position

        ap = project(v1, camera)
        bp = project(v2, camera)
        cp = project(v3, camera)

        if isnothing(ap) || isnothing(bp) || isnothing(cp)
            return
        end

        if dot(cross(v2 - v1, v3 - v1), camera.position - v1) < 0
            return
        end

        drawline2d!(color, ap, bp, camera.dims, buf)
        drawline2d!(color, bp, cp, camera.dims, buf)
        drawline2d!(color, cp, ap, camera.dims, buf)
    end
end
function drawobjtest!(color::RGBf, obj, position::Vector, scale, camera::Camera, buf)
    foreach(obj) do tri 
        _color = color

        v1 = Vector(tri[1]) * scale + position
        v2 = Vector(tri[2]) * scale + position
        v3 = Vector(tri[3]) * scale + position

        ap = project(v1, camera)
        bp = project(v2, camera)
        cp = project(v3, camera)

        if isnothing(ap) || isnothing(bp) || isnothing(cp)
            return
        end

        if dot(cross(v2 - v1, v3 - v1), camera.position - v1) < 0
            _color = RGBf(1, 1, 1)
        end

        drawline2d!(_color, ap, bp, camera.dims, buf)
        drawline2d!(_color, bp, cp, camera.dims, buf)
        drawline2d!(_color, cp, ap, camera.dims, buf)
    end
end
function drawface!(color::RGBf, obj, face::PrimitiveFaceOrientation, position::Vector, scale::Number, camera::Camera, buf)
    if     face == Up
        drawobj!(color, obj[1:2], position, scale, camera, buf)
    elseif face == Back
        drawobj!(color, obj[3:4], position, scale, camera, buf)
    elseif face == Left  
        drawobj!(color, obj[5:6], position, scale, camera, buf)
    elseif face == Down
        drawobj!(color, obj[7:8], position, scale, camera, buf)
    elseif face == Right
        drawobj!(color, obj[9:10], position, scale, camera, buf)
    elseif face == Front
        drawobj!(color, obj[11:12], position, scale, camera, buf)
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