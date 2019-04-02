using Knet: @diff, Param, value, grad, params
using Knet: sigm, tanh, softmax


const memory_size = 5



mutable struct Layer

    wri::Param
    wrs::Param
    wrm::Param

    wwi::Param
    wws::Param
    wwm::Param

    wki::Param
    wks::Param
    wkm::Param

    wfi::Param
    wfs::Param
    wfm::Param

    wii::Param
    wis::Param
    wim::Param

    wsi::Param
    wss::Param
    wsm::Param

    w::Param

end


Layer(in_size,layer_size) =
begin

    # read
    wri = Param(randn(in_size, memory_size))
    wrs = Param(randn(layer_size, memory_size))
    wrm = Param(randn(memory_size, memory_size))

    # write
    wwi = Param(randn(in_size, memory_size))
    wws = Param(randn(layer_size, memory_size))
    wwm = Param(randn(memory_size, memory_size))

    # keep
    wki = Param(randn(in_size, layer_size))
    wks = Param(randn(layer_size, layer_size))
    wkm = Param(randn(memory_size, layer_size))

    # forget
    wfi = Param(randn(in_size, layer_size))
    wfs = Param(randn(layer_size, layer_size))
    wfm = Param(randn(memory_size, layer_size))

    # intermediate
    wii = Param(randn(in_size, layer_size))
    wis = Param(randn(layer_size, layer_size))
    wim = Param(randn(memory_size, layer_size))

    # show
    wsi = Param(randn(in_size, layer_size))
    wss = Param(randn(layer_size, layer_size))
    wsm = Param(randn(memory_size, layer_size))

    # intermediate memory
    w = Param(randn(layer_size, memory_size))

Layer(wri,wrs,wrm,wwi,wws,wwm,wki,wks,wkm,wfi,wfs,wfm,wii,wis,wim,wsi,wss,wsm,w)
end


(layer::Layer)(in, state, memory) =
begin

    read   = softmax(in * layer.wri + state * layer.wrs + memory * layer.wrm)
    write  = softmax(in * layer.wwi + state * layer.wws + memory * layer.wwm)
    attn_m = read .* memory

    keep   = sigm.(in * layer.wki + state * layer.wks + attn_m * layer.wkm)
    forget = sigm.(in * layer.wfi + state * layer.wfs + attn_m * layer.wfm)
    interm = tanh.(in * layer.wii + state * layer.wis + attn_m * layer.wim)
    show   = sigm.(in * layer.wsi + state * layer.wss + attn_m * layer.wsm)

    interm_m = tanh.(interm * layer.w)
    state    = forget .* state + keep .* interm
    out      = show .* state

    memory += write .* interm_m

(out, state, memory)
end



immutable struct Enc
    layers
end

Enc(in_size, hiddens, out_size) =
begin
    hm_layers = length(hiddens)+1
    layers = []
    for i in 1:hm_layers
        if     i == 1         i, o = in_size, hiddens[1]
        elseif i == hm_layers i, o = hiddens[end], out_size
        else                  i, o = hiddens[i-1], hiddens[i]
        end
        push!(layers, Layer(i,o))
    end

Enc(layers)
end

(enc::Enc)(input, state, memory) =
begin
    results = []
    for layer in enc.layers
        r = layer(input, state, memory)
        input, state, memory = r
        push!(results, r)
    end

results
end



immutable struct Dec
    layers
end

Dec(in_size, hiddens, out_size) =
begin
    hm_layers = length(hiddens)+1
    layers = []
    for i in 1:hm_layers
        if     i == 1         i, o = in_size, hiddens[1]
        elseif i == hm_layers i, o = hiddens[end], out_size
        else                  i, o = hiddens[i-1], hiddens[i]
        end
        push!(layers, Layer(i,o))
    end

Enc(layers)
end

(dec::Enc)(input, state, memory, enc_outs) =
begin
    for layer in enc.layers



        input, state, memory = layer(input, state, memory)
    end
end




prop(enc, dec, enc_state, dec_state, memory) =
begin
    
end
