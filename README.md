# ShadersTest

shaders test on web

### project version
`Unity 6000.2.6f2`

## [Github Pages of ShadersTest](https://nebobyeoli.github.io/ShadersTest-webbuild/)

repo for web build output: [ShadersTest-webbuild](https://github.com/nebobyeoli/ShadersTest-webbuild/)

<details>
<summary><i>Preview image</i></summary>

![screenshot.png](screenshot.png)

</details>

<br>

## Projects these shaders were created for:

### [*Buggy Ducky* (Patch-Notes game jam submission)](https://tablefortwenty.itch.io/buggy-ducky)
created shaders from team *TableForTwenty*

<details>
<summary><i>Shader reference materials:</i></summary>

- [[Youtube] Glitch Shader using Unity HDRP](https://www.youtube.com/watch?v=7L9yxVwEFsA) (video uses Amplify shader graph editor, so the one in this project is manually made with Unity default shader graph editor)

- [[Reddit] Grid Skybox Shader](https://www.reddit.com/r/Unity3D/comments/m06t1i/skybox_fun_with_shader_graph/)<br>
[[Youtube] Skybox Shader using Unity URP](https://www.youtube.com/watch?v=sXevaQ8cM2c)

</details>

<details>
<summary><i>Additional resources (unused):</i></summary>

- [[Youtube] CRT Shader using Unity URP Fullscreen](https://www.youtube.com/watch?v=lOyb0_rFA1A)

</details>

### *Run Shiba Run*
created outline shader for additional visual style

<details>
<summary><i>Shader reference materials:</i></summary>

- First I followed the [Outline shader blog post for Legacy render pipeline](https://roystan.net/articles/outline-shader/) to grasp the outline implementation,

- Then I followed the [URP Fullscreen blit guide on Unity docs](https://docs.unity3d.com/6000.2/Documentation/Manual/urp/renderer-features/how-to-fullscreen-blit.html) and compared the shader & custom render feature code difference between Legacy and URP,

- I found that I needed to use [`_CameraOpaqueTexture`](https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@7.1/manual/universalrp-asset.html) instead of `_MainTex` or `_BaseMap` for it to work on URP,

- The "default" URP implementation of `struct Attributes` and `struct Varyings` can be found in `Blit.hlsl` (search in the `Library` folder of your project directory in file explorer)

- And the Render Texture method is just something I came up with, from a method I used for a project last year, don't really remember where if I had first read about it,

  render texture asset settings:
  ```js
  size = (your screen size) // (1920 x 1080 in this case)
  color format = R16G16B16A16_SFLOAT // read somewhere that this format enables transparency for the render texture
  ```
  apply the render texture into a urp unlit material, set mode to `transparent` for the outline material, apply materials to quad objects and make the orthographic output camera render them.

  This method including the last part may seem unnecessarily complicated but it was the most convenient and familiar method I could think of at the moment

- Of course, you would need to assign the objects to the layer, and make sure the layer is added on `Main Camera` (in hierarchy)'s `Rendering > Culling Mask` layers if you're using a new layer, or else you will end up with a "transparent" object with only the outline running around

- (need to check) if I remember correctly, to exclude a layer from the outline rendering (while including the layer to the correct depth calculation), you need to:
  - have the layer added on your `Outline Camera`'s Culling Mask
  - have the layer excluded on your current `Outline Renderer.asset`("PC_Outline_Renderer.asset" or "PC_Outline_Alphablend_Renderer.asset" for this project)'s Layer Mask

</details>

<details>
<summary><i>Additional resources (unused):</i></summary>

- [[Unity docs] URP custom post processing using "low code" (shader graph) guide](https://docs.unity3d.com/6000.2/Documentation/Manual/urp/post-processing/post-processing-custom-effect-low-code.html)

- [[Medium blog] Understanding "Blit" in unity](https://divinesense.medium.com/practically-understanding-graphics-blit-in-unity-1d64f802d77a)

- [[Youtube] If you ever want to use *post processing* on *transparent* render textures](https://m.youtube.com/watch?v=Pj1bR0U5Tw4)<br>
(old video, dirty not really recommended but works if you don't plan to upgrade urp or unity or something for that specific project, heard unity 6 and onwards provides something without editing internal URP code but didn't look into it)

</details>
<br>

## Shader graph testing shenanigans

### URP Lit transparent specular type
- *Specular color* slot with Scene Color node determines the "fake alpha" of result by the saturation of specular color
- on web, "fake alpha" by Scene Color + specular in *Fragment Color* slot either gives "completely opaque" or "completely transparent" result
- on web, simulating normals via *Fragment Color* manipulation dealing with opacity doesn't seem to work

- shadows cast by transparent materials doesn't seem to work on web for some reason, and perceived depth may be flattened because of that

### Other

- adding `_` parameters makes the whole shader disappear in web for some reason

- the behavior of *Smoothness* slot seems to be inverted between simulating normals in the *Fragment Color* vs. using the actual *Normal* slot
