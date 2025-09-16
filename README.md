# ShadersTest

shaders test on web

### URP Lit transparent specular type
- *Specular color* slot with Scene Color node determines the "fake alpha" of result by the saturation of specular color
- on web, "fake alpha" by Scene Color + specular in *Fragment Color* slot either gives "completely opaque" or "completely transparent" result
- on web, simulating normals via *Fragment Color* manipulation dealing with opacity doesn't seem to work

- the behavior of *Smoothness* slot seems to be inverted between simulating normals in the *Fragment Color* vs. the actual *Normal* slot
- adding `_` parameters makes the whole shader disappear in web for some reason
