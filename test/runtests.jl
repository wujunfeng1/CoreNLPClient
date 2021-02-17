using CoreNLPClient

res1 = CoreNLP("http://localhost:9000", "I am a Julia programmer. I love Julia programming.")

res2 = CoreNLP("localhost:9000", "I am a Julia programmer. I love Julia programming.")

res3 = CoreNLP("localhost", "I am a Julia programmer. I love Julia programming.")

res4 = CoreNLP("I am a Julia programmer. I love Julia programming.")

anno1 = getNLPAnnotations(res1)

anno2 = getNLPAnnotations(res2)
