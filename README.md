# CoreNLPClient

### Introduction
This is a julia package for using Stanford CoreNLP. A CoreNLP server is needed for using the package. Stanford CoreNLP can be downloaded from:
https://stanfordnlp.github.io/CoreNLP/

### Quick Start
This package can be installed in julia by:
```
using Pkg;Pkg.add(PackageSpec(url="https://github.com/wujunfeng1/CoreNLPClient"))   
```

The server must be started whenever the package is used. The detail of starting the server could be found on webpage:
https://stanfordnlp.github.io/CoreNLP/corenlp-server.html

For example, suppose java is installed in /opt/jdk-11.0.10+9 and Stanford CoreNLP is extracted into /opt/stanford-corenlp-4.2.0, then to start the server, we could use the following command:
```
$/opt/jdk-11.0.10+9/bin/java -mx4g -cp "/opt/stanford-corenlp-4.2.0/*" edu.stanford.nlp.pipeline.StanfordCoreNLPServer -port 9000 -timeout 15000
```

Examples of using this package:

```
using CoreNLPClient

res1 = CoreNLP("http://localhost:9000", "I am a Julia programmer. I love Julia programming.")

res2 = CoreNLP("localhost:9000", "I am a Julia programmer. I love Julia programming.")

res3 = CoreNLP("localhost", "I am a Julia programmer. I love Julia programming.")

res4 = CoreNLP("I am a Julia programmer. I love Julia programming.")

anno1 = getNLPAnnotations(res1)

anno2 = getNLPAnnotations(res2)
```