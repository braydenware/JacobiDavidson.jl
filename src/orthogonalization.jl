export DGKS, ClassicalGramSchmidt, ModifiedGramSchmidt
export orthogonalize_and_normalize!

abstract type OrthogonalizationMethod end
struct DGKS <: OrthogonalizationMethod end
struct ClassicalGramSchmidt <: OrthogonalizationMethod end
struct ModifiedGramSchmidt <: OrthogonalizationMethod end

# Default to MGS, good enough for solving linear systems.
@inline orthogonalize_and_normalize!(V::StridedMatrix{T}, w::StridedVector{T}, h::StridedVector{T}) where {T} = orthogonalize_and_normalize!(V, w, h, ModifiedGramSchmidt)

function orthogonalize_and_normalize!(V::StridedMatrix{T}, w::StridedVector{T}, h::StridedVector{T}, ::Type{DGKS}) where {T}
    # Orthogonalize using BLAS-2 ops
    Ac_mul_B!(h, V, w)
    BLAS.gemv!('N', -one(T), V, h, one(T), w)
    nrm = norm(w)

    # Constant used by ARPACK.
    η = one(real(T)) / √2

    projection_size = norm(h)

    # Repeat as long as the DGKS condition is satisfied
    # Typically this condition is true only once.
    while nrm < η * projection_size
        correction = Ac_mul_B(V, w)
        projection_size = norm(correction)
        # w = w - V * correction
        BLAS.gemv!('N', -one(T), V, correction, one(T), w)
        @blas! h += one(T) * correction
        nrm = norm(w)
    end

    # Normalize; note that we already have norm(w).
    scale!(w, one(T) / nrm)

    nrm
end

function orthogonalize_and_normalize!(V::StridedMatrix{T}, w::StridedVector{T}, h::StridedVector{T}, ::Type{ClassicalGramSchmidt}) where {T}
    # Orthogonalize using BLAS-2 ops
    Ac_mul_B!(h, V, w)
    BLAS.gemv!('N', -one(T), V, h, one(T), w)
    nrm = norm(w)

    # Normalize
    scale!(w, one(T) / nrm)

    nrm
end

function orthogonalize_and_normalize!(V::StridedMatrix{T}, w::StridedVector{T}, h::StridedVector{T}, ::Type{ModifiedGramSchmidt}) where {T}
    # Orthogonalize using BLAS-1 ops and column views.
    for i = 1 : size(V, 2)
        column = view(V, :, i)
        h[i] = dot(column, w)
        @blas! w -= h[i] * column
    end

    nrm = norm(w)
    scale!(w, one(T) / nrm)

    nrm
end

function just_orthogonalize!(V::StridedMatrix{T}, w::StridedVector{T}, ::Type{DGKS}) where {T}
    # Orthogonalize using BLAS-2 ops
    h = Ac_mul_B(V, w)
    BLAS.gemv!('N', -one(T), V, h, one(T), w)
    nrm = norm(w)

    # Constant used by ARPACK.
    η = one(real(T)) / √2

    projection_size = norm(h)

    # Repeat as long as the DGKS condition is satisfied
    # Typically this condition is true only once.
    while nrm < η * projection_size
        # Reuse h here.
        Ac_mul_B!(h, V, w)
        projection_size = norm(h)
        # w = w - V * h
        BLAS.gemv!('N', -one(T), V, h, one(T), w)
        nrm = norm(w)
    end

    nothing
end

function just_orthogonalize!(V::StridedMatrix{T}, w::StridedVector{T}, h::StridedVector{T}, ::Type{DGKS}) where {T}
    # Orthogonalize using BLAS-2 ops
    Ac_mul_B!(h, V, w)
    BLAS.gemv!('N', -one(T), V, h, one(T), w)
    nrm = norm(w)

    # Constant used by ARPACK.
    η = one(real(T)) / √2

    projection_size = norm(h)

    # Repeat as long as the DGKS condition is satisfied
    # Typically this condition is true only once.
    while nrm < η * projection_size
        correction = Ac_mul_B(V, w)
        projection_size = norm(correction)
        # w = w - V * correction
        BLAS.gemv!('N', -one(T), V, correction, one(T), w)
        @blas! h += one(T) * correction
        nrm = norm(w)
    end

    nrm
end