# CoreNLPClient

This is a julia package for using Stanford CoreNLP. A CoreNLP server is needed for using the package. Stanford CoreNLP can be downloaded from:
https://stanfordnlp.github.io/CoreNLP/

The server must be started whenever the package is used. The detail of starting the server could be found on webpage:
https://stanfordnlp.github.io/CoreNLP/corenlp-server.html

For example, suppose java is installed in /opt/jdk-11.0.10+9 and Stanford CoreNLP is extracted into /opt/stanford-corenlp-4.2.0, then to start the server, we could use the following command:
$/opt/jdk-11.0.10+9/bin/java -mx4g -cp "/opt/stanford-corenlp-4.2.0/*" edu.stanford.nlp.pipeline.StanfordCoreNLPServer -port 9000 -timeout 15000

Using this package is simple. For example:

using CoreNLPClient
corenlp("I am a Julia programmer. I love Julia programming.")