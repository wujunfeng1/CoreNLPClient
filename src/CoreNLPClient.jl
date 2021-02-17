module CoreNLPClient

using HTTP

export CoreNLP, TNLPAnnotation, getNLPAnnotations 

# ===========================================================================================
# function parseStringProperty
# brief description: This is a utility function for the main function CoreNLP(). In CoreNLP(),
#                    annotations of the input text are retrieved from the Stanford CoreNLP
#                    server, and this utility function is used for parsing the string properties
#                    in the annotations.
# input:
#   input: A substring in the annotations in format of property_name:"property_value".
# output:
#   (property_name, property_value, number_of_lines_parsed)  
function parseStringProperty(input::SubString{String})::Tuple{String,String,Int}
    result = ("","",0)
    stringPropertyMatch = match(r"^[ \t]*\"(.)+\"[ \t]*:[ \t]*\"(.|[:])*\"", input)
    if stringPropertyMatch !== nothing
        splits = split(stringPropertyMatch.match, ":")
        key = split(splits[1], "\"")[2]
        value = splits[2]
        for i = 3:length(splits)
            value = value * ":" * splits[i]
        end
        value = split(value, "\"")[2]
        result = (key,value,1)
    end
    result
end

# ===========================================================================================
# function parseFloatProperty
# brief description: This is a utility function for the main function CoreNLP(). In CoreNLP(),
#                    annotations of the input text are retrieved from the Stanford CoreNLP
#                    server, and this utility function is used for parsing the float properties
#                    in the annotations.
# input:
#   input: A substring in the annotations in format of property_name:property_value, where the
#          property_value is a float number.
# output:
#   (property_name, property_value, number_of_lines_parsed)
# note:
#   The parsing should use the function before parseIntProperty, otherwise the result will be 
#   wrong.   
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

# ===========================================================================================
# function parseIntIntervalProperty
# brief description: This is a utility function for the main function CoreNLP(). In CoreNLP(),
#                    annotations of the input text are retrieved from the Stanford CoreNLP
#                    server, and this utility function is used for parsing the int interval 
#                    properties in the annotations.
# input:
#   input: A substring in the annotations in format of property_name:property_value, where the
#          property_value is an int interval in form of [i1, i2].
# output:
#   (property_name, property_value, number_of_lines_parsed)  
function parseIntIntervalProperty(input::SubString{String})::Tuple{String,Vector{Int},Int}
    result = ("",[0,0],0)
    IntIntervalPropertyMatch = match(r"^[ \t]*\"(.)+\"[ \t]*:[ \t]*\[[ \t]*(-)?(\d)+[ \t]*,[ \t]*(-)?(\d)+[ \t]*\]", input)
    if IntIntervalPropertyMatch !== nothing
        splits = split(IntIntervalPropertyMatch.match, ":")
        key = split(splits[1], "\"")[2]
        values = Int[]
        matches = eachmatch(r"(-)?(\d)+", splits[2])
        for m in matches
            push!(values, parse(Int, m.match))
        end
        @assert length(values) == 2
        result = (key,values,1)
    end
    result
end

# ===========================================================================================
# function parseIntProperty
# brief description: This is a utility function for the main function CoreNLP(). In CoreNLP(),
#                    annotations of the input text are retrieved from the Stanford CoreNLP
#                    server, and this utility function is used for parsing the int properties 
#                    in the annotations.
# input:
#   input: A substring in the annotations in format of property_name:property_value, where the
#          property_value is an int.
# output:
#   (property_name, property_value, number_of_lines_parsed)  
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

# ===========================================================================================
# function parseVectorProperty
# brief description: This is a utility function for the main function CoreNLP(). In CoreNLP(),
#                    annotations of the input text are retrieved from the Stanford CoreNLP
#                    server, and this utility function is used for parsing the vector properties 
#                    in the annotations.
# input:
#   input: A substring in the annotations in format of property_name:property_value, where the
#          property_value is in form of [{item 1}, {item 2}, ..., {item k}].
# output:
#   (property_name, property_value, number_of_lines_parsed)
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

# ===========================================================================================
# function parseDictProperty
# brief description: This is a utility function for the main function CoreNLP(). In CoreNLP(),
#                    annotations of the input text are retrieved from the Stanford CoreNLP
#                    server, and this utility function is used for parsing the dict properties 
#                    in the annotations.
# input:
#   input: A substring in the annotations in format of property_name:property_value, where the
#          property_value is in form of {prop1:value1, prop2:value2, ..., propK:valueK}.
# output:
#   (property_name, property_value, number_of_lines_parsed)
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
    #println("Dict $(input[1]) starts:")

    n = length(input)
    i = 2
    closeMatch = nothing
    while i <= n
        #println(input[i])
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
        key,value,numLinesOfValue = parseIntIntervalProperty(input[i])
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
    #println("Dict $(input[1]) ends.")
    @assert closeMatch !== nothing
    (myKey,result,i-1)
end

# ===========================================================================================
# function CoreNLP 
# brief description: This is the main function of this package. It is used for querying the 
#                    Stanford CoreNLP server for the annotations of an input text.
# input:
#   serverURL: The URL of the CoreNLP server.
#   input:  The input text.
# output:
#   A dictionary of the result retrieved from the CoreNLP server.
# note:
#   A CoreNLP server is needed for using the package. Stanford CoreNLP can be downloaded from:
#   https://stanfordnlp.github.io/CoreNLP/
#   The server must be started whenever the package is used. The detail of starting the server 
#   could be found on webpage:
#   https://stanfordnlp.github.io/CoreNLP/corenlp-server.html
function CoreNLP(serverURL::String, input::String)::Dict{String,Any}
    url = serverURL
    if !startswith(url, "http://")
        url = "http://" * url 
    end
    splits = split(url, ":")
    @assert length(splits) <= 3
    if length(splits) < 3
        url = url * ":9000"
    end

    res=HTTP.post(url, [], input)
    body = "{"*split(String(res), "\n{")[end]
    annotations = split(body, "\n")
    key,value,numLinesOfValue = parseDict(annotations)
    @assert key == "" && numLinesOfValue > 0
    value
end

# ===========================================================================================
# function CoreNLP 
# brief description: This is the shorthand function for the full-argument function above.
function CoreNLP(input::String)::Dict{String,Any}
    CoreNLP("http://localhost:9000", input)
end

# ===========================================================================================
# struct TNLPAnnotation
# brief description: This struct is used as a node type for an annotation graph extracted 
#                    using the Stanford CoreNLP toolkit.
# fields:
#   token: A text input to CoreNLP is partitioned into words and punctuations. A token is 
#          either a word or a punctuation.
#   POS: Part of Speech. Please visit https://sites.google.com/site/partofspeechhelp/ for 
#        more details of POS.
#   governors: CoreNLP analyzes dependencies among tokens. The dependencies are represented 
#              with a directed graph. The nodes of this graph are tokens. Every directed edge
#              is pointed from its governor to its dependent. This field is a vector of the
#              indices of the governors. If an index is 0, the governor is ROOT of the 
#              dependency tree. Otherwise, the index must be a positive integer to indicate 
#              the governor's location in a sentence.
#   dependents: The nodes connected by this node through the dependencies as explained in the 
#               description of governors. This field is a vector of the indices of the
#               dependents in a sentence.
#   depLabels: One label for each dependent to describe the type of dependency.
struct TNLPAnnotation
    token::String 
    POS::String 
    governors::Vector{Int}
    dependents::Vector{Int}
    depLabels::Vector{String}  
end

# ===========================================================================================
# function getNLPAnnotations
# brief description: Annotate text using Stanford CoreNLP toolkit.
# input:
#   text: The text to annotate.
# output:
#   An annotated document with the input text. The document is represented by a vector of 
#   sentences. Each sentence is represented by a vector of TNLPAnnotation.
# note:
#   (1) By default, we use localhost:9000 as the URL of CoreNLP. If a customized URL needs to
#       be set, we could use the "CORENLP_URL" environment variable to specify the URL.  
function getNLPAnnotations(text::String)::Vector{Vector{TNLPAnnotation}}
    # ---------------------------------------------------------------------------------------
    # step 1: Fetch CoreNLP server URL from environment variables.
    coreNLPUrl = ""
    if "CORENLP_URL" in keys(ENV)
        coreNLPUrl = ENV[CORENLP_URL]
    end

    # ---------------------------------------------------------------------------------------
    # step 2: Get an annotated result from CoreNLP. 
    nlpResult = if coreNLPUrl == ""
        CoreNLP(text)
    else
        CoreNLP(coreNLPUrl, text)
    end

    # ---------------------------------------------------------------------------------------
    # step 3: Iterate through the annotated result to fill the output sentence by sentence.
    output = Vector{TNLPAnnotation}[]
    for sentence in nlpResult["sentences"]
        # (3.1) create a vector for the annotations of a sentence
        annotationOfSentence = TNLPAnnotation[]

        # (3.2) get tokens and dependencies from the CoreNLP annotations of this sentence 
        tokens = sentence["tokens"]
        deps = sentence["enhancedPlusPlusDependencies"]

        # (3.3) add the tokens to the vector of annotations 
        for token in tokens 
            annotationOfToken = TNLPAnnotation(token["word"], token["pos"], Int[], Int[], String[])
            push!(annotationOfSentence, annotationOfToken)
        end

        # (3.4) set the dependencies in the vector of annotations 
        for dep in deps 
            governor = dep["governor"]
            dependent = dep["dependent"]
            label = dep["dep"]
            depNode = annotationOfSentence[dependent]
            push!(depNode.governors, governor)
            if governor > 0
                govNode = annotationOfSentence[governor]
                push!(govNode.dependents, dependent)
                push!(govNode.depLabels, label)
            end
        end

        # (3.5) insert this vector of annotations into the output
        push!(output, annotationOfSentence)
    end

    # ---------------------------------------------------------------------------------------
    # step 4: return the output 
    output
end

end # module
