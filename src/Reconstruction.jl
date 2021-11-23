export ReconstructionCPM

 # maybe move to a different file
export InitialObject, InitialObjectOnes
export InitialProbe, InitialProbeCirc

abstract type InitialObject end
abstract type InitialObjectOnes <:InitialObject end

abstract type InitialProbe end
abstract type InitialProbeCirc <: InitialProbe end


abstract type Reconstruction end

@kwdef mutable struct ReconstructionCPM{T} <: Reconstruction where T
    # copied from data
    ptychogram::Union{Nothing, Array{T, N}} where N
    numFrames::Int
    energyAtPos::Vector{T}
    maxProbePower::T
    wavelength::T
    encoder::Union{Nothing, Array{T, 2}}
    # detector sampling
    dxd::T
    xd::Vector{T}
    dxp::T
    Nd::Int
    Ld::T
    # distance to detector 
    zo::T
    # optional parameters
    entrancePupilDiameter::Union{Nothing, T}
    spectralDensity::Vector{T}
    theta::Union{Nothing, T}
    
    # new parameters
    No::Int
    # reconstruction parameters
    nlambda::Int
    nosm::Int
    npsm::Int
    nslice::Int
    shape_O::NTuple{6, Int}
    shape_P::NTuple{6, Int}
    purityProbe::T
    purityObject::T
    # optional parameters
    initialObject::Type{<:InitialObject}
    initialProbe::Type{<:InitialProbe}
    # reconstructions
    object::Union{Nothing, Array{Complex{T}, 6}}
    probe::Union{Nothing, Array{Complex{T}, 6}}
end


"""
    ReconstructionCPM(data::ExperimentalDataCPM; <kwargs>)

Fill the `ReconstructionCPM` struct with `experimentData` and some 
initial guesses.


## kwargs
* `downsampleFactor`: a downsampleFactor factor for the measured data
"""
function ReconstructionCPM(data::ExperimentalDataCPM{T}; downsampleFactor=1) where T
    d = type2dict(data)

    # adapt detector properties
    d[:dxd] *= downsampleFactor
    d[:Nd] = d[:Nd] ÷ downsampleFactor
    
    ns = min(size(d[:ptychogram], 1), size(d[:ptychogram], 2))
    # crop the size along the larger dimensions
    d[:ptychogram] = NDTools.select_region(d[:ptychogram], new_size=(ns, ns, size(d[:ptychogram], 3)))

    # do binning if downsampleFactor > 1
    if !isone(downsampleFactor)
        d[:ptychogram] = MicroscopyTools.bin(d[:ptychogram], (downsampleFactor, downsampleFactor, 1))
    end

    d[:nlambda] = 1
    d[:nosm] = 1
    d[:npsm] = 1
    d[:nslice] = 1
    

    d[:No] = calc_No(calc_Np(d[:Nd]))
    # beam and object purity
    d[:purityProbe] = T(1)
    d[:purityObject] = T(1)


    d[:dxp] = d[:wavelength] * d[:zo] / d[:Ld] 

    # if entrancePupilDiameter is not provided in the hdf5 file, set it to be one third of the probe FoV.
    d[:entrancePupilDiameter] = 
        let 
            if isnothing(d[:entrancePupilDiameter])
                calc_Lp(calc_Np(d[:Nd]), d[:dxp])
            else 
                d[:entrancePupilDiameter]
            end
        end
            
    # wrap in array if not provided
    d[:spectralDensity] = isnothing(d[:spectralDensity]) ? [d[:wavelength]] : d[:spectralDensity]

    d[:initialObject] = InitialObjectOnes
    d[:initialProbe] = InitialProbeCirc

    d[:shape_O] = (d[:No], d[:No], d[:nlambda], d[:nosm], 1, d[:nslice])
    d[:shape_P] = (calc_Np(d[:Nd]), calc_Np(d[:Nd]), d[:nlambda], 1, d[:npsm], d[:nslice])


    # initialize as nothing
    d[:object] = nothing
    d[:probe] = nothing
    return ReconstructionCPM(; d...)
end

"""
    Base.getproperty(recCPM::ReconstructionCPM, sym::Symbol) 

Overwrite the function since some parameters are dependent on the
fields. Instead of storing them, we calculate them.
That could make access slightly more expensive, but 
one can always retrieve them before a hot for loop
as a local variable.
"""
function Base.getproperty(recCPM::ReconstructionCPM, sym::Symbol)
    if hasproperty(recCPM, sym)
        return getfield(recCPM, sym)
    elseif sym === :DoF
        return calc_DoF(recCPM.lambda, recCPM.wavelength) 
    elseif sym === :NAd
        return calc_NAd(recCPM.Ld, recCPM.zo) 
    elseif sym === :Ld
        return calc_Ld(recCPM.Nd, recCPM.dxd)
    elseif sym === :xd
        return calc_xd(recCPM.Nd, recCPM.dxd)
    elseif sym === :Np
        return calc_Np(recCPM.Nd)
    elseif sym === :Lp
        return calc_Lp(recCPM.Np, recCPM.dxp)
    elseif sym === :xp
        return calc_xp(recCPM.Np, recCPM.dxp)
    elseif sym === :dxo
        return calc_dxo(recCPM.dxp) 
    elseif sym === :No
        return calc_No(recCPM.Np)
    elseif sym === :Lo
        return calc_Lo(recCPM.No, recCPM.dxo)
    elseif sym === :xo
        return calc_xo(recCPM.No, recCPM.dxo)
    elseif sym === :NAd
        return calc_NAd(recCPM.Ld, recCPM.zo) 
    elseif sym === :positions
        return calc_positions(CPM, recCPM.encoder, recCPM.dxo, recCPM.No, recCPM.Np) 
    else
        error("$(sym) is not a field or dependent field.")
    end
end


"""
    initializeObjectProbe!(recCPM::ReconstructionCPM{T}) where {T}

Initializes `recCPM.object` and `recCPM.probe` and stores it directly in `recCPM`.
"""
function initializeObjectProbe!(recCPM::ReconstructionCPM{T}) where {T}
    Np = calc_Np(recCPM.Nd)
    xp = calc_xp(recCPM.Np, recCPM.dxp) 


    # handle object
    if recCPM.initialObject === InitialObjectOnes
        recCPM.object = ones(Complex{T}, recCPM.shape_O) 
    else
        error("InitialObject = $(recCPM.initialObject) not valid")
    end

    # handle probe
    if recCPM.initialProbe === InitialProbeCirc
        # recCPM.probe = circ(recCPM.shape_P, calc_xp(calc_Np(recCPM.Nd)), recCPM.dxp) .* ones(T, recCPM.shape_O) 
        recCPM.probe = circ(recCPM.shape_P, recCPM.xp, recCPM.entrancePupilDiameter / 2) .* ones(Complex{T}, recCPM.shape_P) 
    else
        error("InitialProbe = $(recCPM.initialProbe) not valid")
    end    

    return recCPM 
end
