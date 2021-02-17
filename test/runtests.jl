using CoreNLPClient

res1 = CoreNLP("http://localhost:9000", "I am a Julia programmer. I love Julia programming.")

res2 = CoreNLP("localhost:9000", "I am a Julia programmer. I love Julia programming.")

res3 = CoreNLP("localhost", "I am a Julia programmer. I love Julia programming.")

res4 = CoreNLP("I am a Julia programmer. I love Julia programming.")

annotations = getNLPAnnotations("I am a Julia programmer. I love Julia programming.")
