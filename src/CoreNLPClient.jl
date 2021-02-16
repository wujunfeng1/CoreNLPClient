module CoreNLPClient

using HTTP

function parseStringProperty(input::SubString{String})::Tuple{String,String,Int}
    result = ("","",0)
    stringPropertyMatch = match(r"^[ \t]*\"(.)+\"[ \t]*:[ \t]*\"(.)*\"", input)
    if stringPropertyMatch !== nothing
        key = split(split(stringPropertyMatch.match, ":")[1], "\"")[2]
        value = split(split(stringPropertyMatch.match, ":")[2], "\"")[2]
        result = (key,value,1)
    end
    result
end

function parseFloatProperty(input::SubString{String})::Tuple{String,Float64,Int}
    result = ("",0,0)
    floatPropertyMatch = match(r"^[ \t]*\"(.)+\"[ \t]*:[ \t]*(\d)*\.(\d)+", input)
    if floatPropertyMatch !== nothing
        key = split(split(floatPropertyMatch.match, ":")[1], "\"")[2]
        value = parse(Float64,split(floatPropertyMatch.match, ":")[2])
        result = (key,value,1)
    end
    result 
end

function parseIntProperty(input::SubString{String})::Tuple{String,Int,Int}
    result = ("",0,0)
    intPropertyMatch = match(r"^[ \t]*\"(.)+\"[ \t]*:[ \t]*(\d)+", input)
    if intPropertyMatch !== nothing
        key = split(split(intPropertyMatch.match, ":")[1], "\"")[2]
        value = parse(Int,split(intPropertyMatch.match, ":")[2])
        result = (key,value,1)
    end
    result 
end

function parseVectorProperty(input::Vector{SubString{String}})::Tuple{String,Vector{Any},Int}
    result = []
    vectorPropertyMatch = match(r"^[ \t]*\"(.)+\"[ \t]*:[ \t]*\[", input[1])
    if vectorPropertyMatch !== nothing
        myKey = split(split(vectorPropertyMatch.match, ":")[1], "\"")[2]
        n = length(input)
        i = 2
        while i <= n
            key,value,numLinesOfValue = parseDict(input[i:n])
            if numLinesOfValue > 0
                @assert key == ""
                push!(result,value)
                i += numLinesOfValue
            else
                closeMatch = match(r"^[ \t]*\]", input[i])
                i += 1
                if closeMatch !== nothing
                    break 
                end    
            end
        end
        
        (myKey,result,i-1)
    else
        ("",[],0)
    end 
end

function parseDict(input::Vector{SubString{String}})::Tuple{String,Dict{String,Any},Int}
    myKey = ""
    result = Dict{String,Any}()
    
    openMatch = match(r"^[ \t]*{", input[1])
    if openMatch === nothing
        openMatch = match(r"^[ \t]*\"(.)+\"[ \t]*:[ \t]*{", input[1])
        if openMatch !== nothing
            myKey = split(split(openMatch.match, ":")[1], "\"")[2]
        end 
    end
    if openMatch === nothing
        return ("",Dict{String,Any}(), 0) 
    end

    n = length(input)
    i = 2
    closeMatch = nothing
    while i <= n
        key,value,numLinesOfValue = parseStringProperty(input[i])
        if numLinesOfValue > 0
            result[key] = value
            i += numLinesOfValue
            continue 
        end
        key,value,numLinesOfValue = parseFloatProperty(input[i])
        if numLinesOfValue > 0
            result[key] = value
            i += numLinesOfValue
            continue 
        end
        key,value,numLinesOfValue = parseIntProperty(input[i])
        if numLinesOfValue > 0
            result[key] = value
            i += numLinesOfValue
            continue 
        end
        key,value,numLinesOfValue = parseVectorProperty(input[i:n])
        if numLinesOfValue > 0
            result[key] = value
            i += numLinesOfValue
            continue 
        end
        key,value,numLinesOfValue = parseDict(input[i:n])
        if numLinesOfValue > 0
            result[key] = value
            i += numLinesOfValue
            continue 
        end
        closeMatch = match(r"^[ \t]*}", input[i])
        i += 1
        if closeMatch !== nothing
            break 
        end
    end
    @assert closeMatch !== nothing
    (myKey,result,i-1)
end

function coreNLP(serverURL::String, input::String)::Dict{String,Any}
    res=HTTP.post(serverURL, [], input)
    body = "{"*split(String(res), "\n{")[end]
    annotations = split(body, "\n")
    key,value,numLinesOfValue = parseDict(annotations)
    @assert key == "" && numLinesOfValue > 0
    value
end

end # module
