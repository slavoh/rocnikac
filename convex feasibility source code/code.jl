using PyPlot
ω=1
τ=3
iteration=10^4
N=10
M=N

# compute, to how big error step with omega size would lead
function errorOmega(x, xavr, xopt, omega)
    return norm( ((1-omega)*x + omega*xavr) - xopt )
end

# compute size of the best ω for particular point x
# starts wih interval, where to look for ω, splits it into 3 parts, throw away wrong part
# suppose, that error is unimodal function
function getBestOmega(x, xavr, xopt, lower, upper, accuracy)
    while upper-lower>accuracy
        middle1=(2*lower+upper)/3
        middle2=(lower+2*upper)/3

        if errorOmega(x, xavr, xopt, middle1) > errorOmega(x, xavr, xopt, middle2)
            lower=middle1
        else
            upper=middle2
        end
    end
    return (lower+upper)/2
end

# get a random vector of size M+1 with τ ones
function setS()
    S=zeros(M+1,1)
	for i=1:τ
		r=rand(1:M+1) # with ball
        # r=rand(1:M) # without ball
		while S[r]==1
            r=rand(1:M+1) # with ball
			# r=rand(1:M) # without ball
        end
		S[r]=1
    end
	return S
end

# compute average of projections
function projection(A, b, x)
    S=setS()
    xsum=x*0
    for coord=1:M
        if S[coord]==1
            xsum += x - A[coord,:].*(A[coord,:]'*x - b[coord])/(A[coord,:]⋅A[coord,:])
        end
    end
    if S[M+1]==1
        # project on ball
        if norm(x)>10
            xsum += 10*x/norm(x)
        else
            xsum += x
        end
    end
    return xsum/τ
end

# randomly initialize variables
A=randn(M,N)
b=randn(M)
x0=1000*rand(M)
println("norm xopt: ", norm(A\b))
println("norm x0: ", norm(x0))

# find projection to measure distances (same algorithm runned 10x longer)
xopt=x0
for t=1:10*iteration
    xproj = projection(A,b,xopt)
    xopt = (1-ω)*xopt + ω*xproj
end
print("xopt:", norm(A*xopt-b))

# run algorithm and save variables to be plotted
dist=zeros(iteration)
bestOmega=zeros(iteration)
x=x0
for t=1:iteration
    dist[t] = norm(x-xopt)
    xproj = projection(A,b,x)
    bestOmega[t] = getBestOmega(x, xproj, xopt, 0, 1000, 1/10^10)
    # x = (1-ω)*x + ω*xproj # project on ω
    x = (1-bestOmega[t])*x + bestOmega[t]*xproj # project on best omega
end

# plot variables
semilogy(dist)
v = eigvals(A'*A)
λmin = minimum(v[v.>10.0^(-13)]) # for us it is not zero, but for comp it is
rate = 1 - λmin/sum(v)
semilogy(1:iteration,dist[1]*rate.^(1:iteration))
scatter(1:iteration,bestOmega, s=0.1, color="grey", alpha=0.5)
