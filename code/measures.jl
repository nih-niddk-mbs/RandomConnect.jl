
# measures.jl


"""
phase_indices(phase,Nphases,u,l)

Assign index on domain 1 to Nphases to phase on domain l to u

"""
phase_indices(phases,Nphases,lower=-pi,upper=pi) = max.(ceil.(Int,(phases .- lower)./(upper-lower)*Nphases),1)


"""
rho(phases::Matrix,Nphases)
rho(phases::Vector,Nphases)



"""

function compute_rho(phases::Matrix,Nphases,domain=2pi)
    rho = zeros(Nphases,size(phases,2))
    compute_rho!(rho,phases,Nphases)
    return rho*Nphases/domain
end

function compute_rho(phases::Vector,Nphases,domain=2pi)
    rho = zeros(Nphases)
    compute_rho!(rho,phases,Nphases)
    return rho*Nphases/domain
end
"""
rho!(rho,phases,Nphases)

Find mean phase density
averaged over network and time

- `phase': matrix of phases where rows = neurons, cols = time

"""
function compute_rho!(rho::Matrix,phases,Nphases)
    dN = 1/size(phases,1)
    for t in 1:size(phases,2)
        phase_idx = phase_indices(phases[:,t],Nphases)
        for i in phase_idx
            rho[i,t] += dN
        end
    end
end
function compute_rho!(rho::Vector,phases,Nphases)
    phase_idx = phase_indices(phases,Nphases)
    dN = 1/length(phases)
    for i in phase_idx
        rho[i] += dN
    end
end



"""
covariance(x,y,lags)

Find cross-covariance function of matrices x and y over time lags
covariance is taken over neurons, while function is averaged over time
- `x`,`y`: are matrices where rows are neuron indices and columns are time indices

"""
function covariance(x,y,lags)
    T = size(x,2) -lags[end]
    c = zeros(length(lags))
    for t in 1:T
        for (i,lag) in enumerate(lags)
            c[i] += cov(x[t,:],y[t+lag,:])
        end
    end
    c/T
end


"""
c11(u,lags)

Find covariance function of synaptic input

- `u`: matrix of inputs, rows = neurons, cols = time
"""
compute_c11(u,lags) = covariance(u,u,lags)

"""
m13(phases,u,Nphases)

"""
function compute_m13(phases::Vector,u::Vector,Nphases)
    m = zeros(Nphases)
    phase_idx = phase_indices(phases,Nphases)
    for (i,p) in enumerate(phase_idx)
        m[p] += u[i]
    end
    m/Nphases
end
"""
    c13(phases,u,Nphases)

c13(phases,u,Nphases)

"""
compute_c13(phases,u,Nphases) = compute_m13(phases,u,Nphases) - mean(u)*compute_rho(phases,Nphases)

function compute_c13(phases,u,lags,Nphases,domain=2pi)
    T = size(phases,2) -lags[end]
    c = zeros(Nphases,length(lags))
    a1 = mean(u,dims=1)
    for t in 1:T
        rho = compute_rho(phases[:,t],Nphases)
        for (ind, lag) in enumerate(lags)
            c[:,ind] .+= compute_m13(phases[:,t],u[:,t+lag],Nphases) - rho*a1[t+lag]
        end
    end
    c/T*Nphases/domain
end

"""
m33(phases,u,Nphases)

"""
function m33(idx1,idx2,Nphases)
    c = zeros(Nphases,Nphases)
    dN =1/length(idx1)
    for i in 1:Nphases
        c[idx1[i],idx2[i]] += dN
    end
    c
end
"""
C33(phases,u,lags,Nphases)


"""

function c33(phases,lags,Nphases,domain=2pi)
    T = size(phases,1) -lags[end]
    c = zeros(Nphases,Nphases,length(lags))
    rho = a3(phases,Nphases)
    phase_idx= phase_indices(phases,Nphases)
    for t in 1:T
        for (ind, lag) in enumerate(lags)
            c[:,:,ind] .+= M33(phase_idx[:,t],phase_idx[:,t+lag],Nphases) .- rho[:,t]*rho[:,t+lag]'
        end
    end
    c/T*Nphases/domain
end