# AABB Level Editor
> A simple level editor for axis aligned bounding boxes made in a few days during Wheel Reinvention Jam 2024. 

This is the state after the jam - a raw skeleton of the editor with simple brute force rendering and almost no features besides creating aaabb brushes and assigning textures.

## Run 
After cloning make sure to init the odin-imgui submodule via:

```shell 
git submodule init  
git submodule update
```

Then follow the build instructions in the [Odin ImGui Readme](https://gitlab.com/L-4/odin-imgui/-/blob/main/README.md) in order to build the odin-imgui dependencies for your platform.

The project was tested on windows and macos(apple silicon) but should run on linux as well.

## Wheel Reinvention Jam 2024
The goal for the Wheel Reinvention Jam 2024 was to get started with learning the odin programming language. Ideally only the odin vendor libraries will be used (except for e.g. imgui).

### Main Goals:
* Create AABB brushes 
* Edit translation and scale of the brushes
*Assign textures and texcoords to each face
* Unlit forward renderer with occlusion culling utilizing the AABBs

### Stretch Goals:
* Deform AABBs via planes (similar to boolean operation)
* Load GLTF meshes via cgltf and make them placeable in the editor
* place point lights in the editor
* Shadow mapping