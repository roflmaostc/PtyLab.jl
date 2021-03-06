"""
    circ(shape, xi, radius)

Returns an `Array{Bool}`.
A entry is 1 if that positions lies within the `radius`.
The entry are assumed to be in the interval [-xi, ..., xi].


 ## Examples
```julia-repl
julia> PtyLab.circ((1,5), 2, 1.01)
1×5 BitMatrix:
 0  1  1  1  0

julia> PtyLab.circ((1,5), 2, 0.5)
1×5 BitMatrix:
 0  0  1  0  0
```
"""
function circ(shape, xi, radius)
    rr2 = IndexFunArrays.rr2(shape, scale=ScaMid, offset=CtrMid) .* xi[end]^2
    return rr2 .< radius^2
end


"""
    circ(x::T, y::T, D::T) where T

Return true if `x^2 + <^2 < (D/2)^2`.
"""
function circ(x::T, y::T, D::T) where T
    circle = (x^2 + y^2) < (D * T(0.5)) ^2
    return circle
end

"""
    randpermPositions(arr::AbstractArray{T, 2}) where T

Random shuffle the columns of a matrix.


 # Examples
```julia-repl
julia> randpermPositions(([1 2 3 4 5; 1 2 3 4 5]))
2×5 Matrix{Int64}:
 5  4  2  1  3
 5  4  2  1  3

julia> randpermPositions(([1 2 3 4 5; 1 2 3 4 5]))
2×5 Matrix{Int64}:
 2  5  1  4  3
 2  5  1  4  3
```
"""
function randpermPositions(arr::AbstractArray{T, 2}) where T
    out = similar(arr) 
    
    # random permutation of the numbers
    rperm = randperm(size(arr, 2))
    for (i_new, i_rand) in enumerate(rperm)
        # no copy with view
        out[:, i_new] .= view(arr, :, i_rand)
    end
    return out, rperm 
end


"""
    getMaybeFftshifts(b)

If `b` is true, the `getMaybeFftshifts` returns two functions which shift an array.

 ## Example
```julia-repl
julia> maybe_fftshift, maybe_ifftshift = PtyLab.getMaybeFftshifts(true)
(PtyLab.var"#43#45"(), PtyLab.var"#44#46"())

julia> maybe_fftshift([1,2,3,4])
4-element Vector{Int64}:
 3
 4
 1
 2

julia> maybe_ifftshift([1,2,3,4])
4-element Vector{Int64}:
 3
 4
 1
 2

julia>  maybe_fftshift, maybe_ifftshift = PtyLab.getMaybeFftshifts(false)
(identity, identity)

julia> maybe_fftshift([1,2,3,4])
4-element Vector{Int64}:
 1
 2
 3
 4

julia> maybe_ifftshift([1,2,3,4])
4-element Vector{Int64}:
 1
 2
 3
 4
```
"""
function getMaybeFftshifts(b)

    maybe_fftshift = let
        if b 
            x -> fftshift(x, (1,2))
        else
            identity 
        end
    end

    maybe_ifftshift = let
        if b 
            x -> ifftshift(x, (1,2))
        else
            identity 
        end
    end
    return maybe_fftshift, maybe_ifftshift
end
